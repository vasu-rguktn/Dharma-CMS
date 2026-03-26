"""
AI Gateway Router — proxies all AI model calls to the AI service.

The Flutter frontend calls these endpoints. This router then forwards
the request to the actual AI model application (the old backend or a
dedicated AI microservice).

This creates a clean separation:
  Flutter  →  new_backend (auth + CRUD + AI gateway)  →  AI service
"""

from __future__ import annotations

import logging
import httpx
from fastapi import APIRouter, Depends, Request, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse, Response
from typing import Optional, List

from app.core.auth import AuthUser, PoliceUser
from app.core.config import settings

logger = logging.getLogger("ai_gateway")

router = APIRouter(prefix="/ai", tags=["AI Gateway"])

# ─── AI service base URL (the old backend or a dedicated AI micro‑service) ──
_AI_BASE = settings.AI_SERVICE_URL
_MAX_UPLOAD_BYTES = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024

_client = httpx.AsyncClient(base_url=_AI_BASE, timeout=120.0)


async def shutdown_client():
    """Gracefully close the httpx client. Called from main.py lifespan."""
    await _client.aclose()


def _forward_response(resp: httpx.Response) -> Response:
    """Convert an httpx response to a FastAPI response, safely handling non-JSON."""
    content_type = resp.headers.get("content-type", "")

    # Try JSON first
    if "json" in content_type:
        try:
            return JSONResponse(content=resp.json(), status_code=resp.status_code)
        except Exception:
            pass  # fall through

    # For successful non-JSON (PDFs, images, etc.) — pass through as-is
    if 200 <= resp.status_code < 300:
        return Response(
            content=resp.content,
            status_code=resp.status_code,
            media_type=content_type or "application/octet-stream",
        )

    # For error responses that are non-JSON (HTML error pages, etc.),
    # wrap in a JSON error response so the Flutter frontend can parse it
    logger.warning("AI service returned %s with non-JSON body (%s)", resp.status_code, content_type)
    return JSONResponse(
        status_code=resp.status_code if resp.status_code >= 400 else 502,
        content={
            "detail": f"AI service error (HTTP {resp.status_code}). The AI service may be temporarily unavailable.",
            "ai_status_code": resp.status_code,
        },
    )


async def _proxy_json(method: str, path: str, user: AuthUser, json_body=None, params=None):
    """Forward a JSON request to the AI service."""
    headers = {"Content-Type": "application/json"}
    try:
        logger.info("AI proxy JSON %s %s%s", method, _AI_BASE, path)
        resp = await _client.request(method, path, json=json_body, params=params, headers=headers)
        logger.info("AI proxy response: %s %s", resp.status_code, resp.headers.get("content-type"))
        return _forward_response(resp)
    except httpx.RequestError as e:
        logger.error("AI service unreachable: %s: %s", type(e).__name__, e)
        raise HTTPException(status_code=502, detail=f"AI service unreachable: {type(e).__name__}")
    except Exception as e:
        logger.exception("AI proxy unexpected error: %s", e)
        raise HTTPException(status_code=502, detail=f"AI gateway error: {type(e).__name__}: {e}")


async def _proxy_form(path: str, user: AuthUser, data: dict, files: list[tuple] | None = None):
    """Forward a multipart/form‑data request to the AI service."""
    try:
        logger.info("AI proxy FORM POST %s%s  data_keys=%s  files=%s",
                     _AI_BASE, path, list(data.keys()), len(files) if files else 0)
        # Always send as multipart (use empty files list if None)
        resp = await _client.post(path, data=data, files=files or [], timeout=120.0)
        logger.info("AI proxy response: %s %s  body_len=%s",
                     resp.status_code, resp.headers.get("content-type"), len(resp.content))
        return _forward_response(resp)
    except httpx.RequestError as e:
        logger.error("AI service unreachable: %s: %s", type(e).__name__, e)
        raise HTTPException(status_code=502, detail=f"AI service unreachable: {type(e).__name__}")
    except Exception as e:
        logger.exception("AI proxy unexpected error: %s", e)
        raise HTTPException(status_code=502, detail=f"AI gateway error: {type(e).__name__}: {e}")


def _validate_upload_size(content: bytes, filename: str):
    """Reject uploads that exceed the configured limit."""
    if len(content) > _MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=413,
            detail=f"File '{filename}' exceeds {settings.MAX_UPLOAD_SIZE_MB} MB limit.",
        )


# ═══════════════════════════════════════════════════════════════════════════
#  COMPLAINT CHATBOT  (dynamic chat → formal summary)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/complaint/chat-step")
async def complaint_chat_step(
    request: Request,
    user: AuthUser,
    full_name: str = Form(""),
    address: str = Form(""),
    phone: str = Form(""),
    complaint_type: str = Form(""),
    initial_details: str = Form(""),
    language: str = Form("en"),
    is_anonymous: str = Form("false"),
    chat_history: str = Form("[]"),
    files: List[UploadFile] = File(default=[]),
):
    form_data = {
        "full_name": full_name,
        "address": address,
        "phone": phone,
        "complaint_type": complaint_type,
        "initial_details": initial_details,
        "language": language,
        "is_anonymous": is_anonymous,
        "chat_history": chat_history,
    }
    upload_files = []
    for f in files:
        content = await f.read()
        _validate_upload_size(content, f.filename or "upload")
        upload_files.append(("files", (f.filename, content, f.content_type)))

    return await _proxy_form("/complaint/chat-step", user, form_data, upload_files or None)


# ═══════════════════════════════════════════════════════════════════════════
#  LEGAL CHAT
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/legal-chat")
async def legal_chat(
    request: Request,
    user: AuthUser,
    sessionId: str = Form(""),
    message: str = Form(""),
    language: str = Form("en"),
    files: List[UploadFile] = File(default=[]),
):
    form_data = {
        "sessionId": sessionId,
        "message": message,
        "language": language,
    }
    upload_files = []
    for f in files:
        content = await f.read()
        _validate_upload_size(content, f.filename or "upload")
        upload_files.append(("files", (f.filename, content, f.content_type)))

    return await _proxy_form("/api/legal-chat/", user, form_data, upload_files or None)


# ═══════════════════════════════════════════════════════════════════════════
#  LEGAL SUGGESTIONS
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/legal-suggestions")
async def legal_suggestions(request: Request, user: AuthUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/legal-suggestions/", user, json_body=body)


# ═══════════════════════════════════════════════════════════════════════════
#  OCR
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/ocr/extract")
async def ocr_extract(
    user: AuthUser,
    file: UploadFile = File(...),
):
    content = await file.read()
    _validate_upload_size(content, file.filename or "upload")
    upload_files = [("file", (file.filename, content, file.content_type))]
    return await _proxy_form("/api/ocr/extract", user, {}, upload_files)


@router.get("/ocr/health")
async def ocr_health(user: AuthUser):
    return await _proxy_json("GET", "/api/ocr/health", user)


# ═══════════════════════════════════════════════════════════════════════════
#  PDF GENERATION
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/generate-chatbot-summary-pdf")
async def generate_chatbot_summary_pdf(request: Request, user: AuthUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/generate-chatbot-summary-pdf", user, json_body=body)


# ═══════════════════════════════════════════════════════════════════════════
#  WITNESS PREPARATION
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/witness-preparation")
async def witness_preparation(request: Request, user: AuthUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/witness-preparation", user, json_body=body)


# ═══════════════════════════════════════════════════════════════════════════
#  FCM  (notifications)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/fcm/register")
async def fcm_register(request: Request, user: AuthUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/fcm/register", user, json_body=body)


@router.post("/fcm/unregister")
async def fcm_unregister(request: Request, user: AuthUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/fcm/unregister", user, json_body=body)


# ═══════════════════════════════════════════════════════════════════════════
#  CHARGESHEET GENERATION  (police-only)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/chargesheet-generation")
async def chargesheet_generation(
    request: Request,
    user: PoliceUser,
    fir_file: Optional[UploadFile] = File(None),
    incident_file: Optional[UploadFile] = File(None),
    incident_text: str = Form(""),
    additional_instructions: str = Form(""),
    station_name: str = Form(""),
    case_id: str = Form(""),
):
    form_data = {
        "incident_text": incident_text,
        "additional_instructions": additional_instructions,
        "station_name": station_name,
        "case_id": case_id,
    }
    upload_files = []
    if fir_file:
        content = await fir_file.read()
        _validate_upload_size(content, fir_file.filename or "fir")
        upload_files.append(("fir_file", (fir_file.filename, content, fir_file.content_type)))
    if incident_file:
        content = await incident_file.read()
        _validate_upload_size(content, incident_file.filename or "incident")
        upload_files.append(("incident_file", (incident_file.filename, content, incident_file.content_type)))

    return await _proxy_form("/api/chargesheet-generation", user, form_data, upload_files or None)


@router.post("/chargesheet-generation/download-docx")
async def chargesheet_download_docx(request: Request, user: PoliceUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/chargesheet-generation/download-docx", user, json_body=body)


# ═══════════════════════════════════════════════════════════════════════════
#  CHARGESHEET VETTING  (police-only)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/chargesheet-vetting")
async def chargesheet_vetting(
    request: Request,
    user: PoliceUser,
    chargesheet_file: Optional[UploadFile] = File(None),
    chargesheet_text: str = Form(""),
    additional_instructions: str = Form(""),
):
    form_data = {
        "chargesheet_text": chargesheet_text,
        "additional_instructions": additional_instructions,
    }
    upload_files = []
    if chargesheet_file:
        content = await chargesheet_file.read()
        _validate_upload_size(content, chargesheet_file.filename or "chargesheet")
        upload_files.append(("chargesheet_file", (chargesheet_file.filename, content, chargesheet_file.content_type)))

    return await _proxy_form("/api/chargesheet-vetting", user, form_data, upload_files or None)


@router.post("/chargesheet-vetting/download-docx")
async def chargesheet_vetting_download_docx(request: Request, user: PoliceUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/chargesheet-vetting/download-docx", user, json_body=body)


# ═══════════════════════════════════════════════════════════════════════════
#  DOCUMENT DRAFTING  (police-only)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/document-drafting")
async def document_drafting(
    request: Request,
    user: PoliceUser,
    case_data: str = Form(""),
    recipient_type: str = Form(""),
    additional_instructions: str = Form(""),
    file: Optional[UploadFile] = File(None),
):
    form_data = {
        "case_data": case_data,
        "recipient_type": recipient_type,
        "additional_instructions": additional_instructions,
    }
    upload_files = []
    if file:
        content = await file.read()
        _validate_upload_size(content, file.filename or "upload")
        upload_files.append(("file", (file.filename, content, file.content_type)))

    return await _proxy_form("/api/document-drafting", user, form_data, upload_files or None)


@router.post("/document-drafting/download-docx")
async def document_drafting_download_docx(request: Request, user: PoliceUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/document-drafting/download-docx", user, json_body=body)


# ═══════════════════════════════════════════════════════════════════════════
#  AI INVESTIGATION GUIDELINES  (police-only)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/ai-investigation")
async def ai_investigation(request: Request, user: PoliceUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/ai-investigation/", user, json_body=body)


# ═══════════════════════════════════════════════════════════════════════════
#  INVESTIGATION REPORT  (police-only)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/investigation-report")
async def generate_investigation_report(request: Request, user: PoliceUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/generate-investigation-report", user, json_body=body)


# ═══════════════════════════════════════════════════════════════════════════
#  MEDIA ANALYSIS  (police-only)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/media-analysis")
async def media_analysis(
    user: PoliceUser,
    file: UploadFile = File(...),
    analysis_type: str = Form("general"),
    additional_instructions: str = Form(""),
):
    content = await file.read()
    _validate_upload_size(content, file.filename or "media")
    form_data = {
        "analysis_type": analysis_type,
        "additional_instructions": additional_instructions,
    }
    upload_files = [("file", (file.filename, content, file.content_type))]
    return await _proxy_form("/api/media-analysis", user, form_data, upload_files)


# ═══════════════════════════════════════════════════════════════════════════
#  DOCUMENT RELEVANCE  (police-only)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/document-relevance")
async def document_relevance(
    user: PoliceUser,
    file: UploadFile = File(...),
    case_context: str = Form(""),
):
    content = await file.read()
    _validate_upload_size(content, file.filename or "doc")
    form_data = {"case_context": case_context}
    upload_files = [("file", (file.filename, content, file.content_type))]
    return await _proxy_form("/api/document-relevance", user, form_data, upload_files)


# ═══════════════════════════════════════════════════════════════════════════
#  AI TRANSLATION
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/translate")
async def ai_translate(request: Request, user: AuthUser):
    body = await request.json()
    return await _proxy_json("POST", "/api/ai/translate", user, json_body=body)
