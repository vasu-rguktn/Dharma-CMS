# routers/ocr.py
from fastapi import APIRouter, UploadFile, File, HTTPException, status
from fastapi.responses import JSONResponse
import base64
import json
import os
import asyncio
import time
import traceback
from typing import Set
from io import BytesIO
from dotenv import load_dotenv
import google.generativeai as genai
from loguru import logger

# === Load env & configure Gemini ===
load_dotenv()
API_KEY = os.getenv("GEMINI_API_KEY")
if not API_KEY:
    logger.warning("GEMINI_API_KEY not set. OCR will fail.")
else:
    genai.configure(api_key=API_KEY)

router = APIRouter(prefix="/api/ocr", tags=["OCR"])

# === Supported types & limits ===
SUPPORTED_MIME_TYPES: Set[str] = {"image/jpeg", "image/png", "image/webp"}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5 MB


def _guess_mime_type(filename: str) -> str:
    ext = filename.lower().split(".")[-1]
    return {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
    }.get(ext, "application/octet-stream")


async def _extract_text_gemini(image_bytes: bytes, mime_type: str) -> str:
    if not API_KEY:
        raise ValueError("GEMINI_API_KEY not configured")

    encoded = base64.b64encode(image_bytes).decode("utf-8")
    model = genai.GenerativeModel("gemini-2.5-flash")

    prompt_json = (
        "Extract all readable text from the provided image. "
        "Return ONLY valid JSON exactly in the form: {\"text\": \"<EXTRACTED_TEXT>\"}."
    )

    # Attempt 1: Ask for strict JSON
    try:
        start_ts = time.time()
        logger.info(f"[OCR GEMINI] JSON attempt (mime={mime_type}, bytes={len(image_bytes)})")
        response = await asyncio.wait_for(
            asyncio.to_thread(
                model.generate_content,
                [
                    {"inline_data": {"mime_type": mime_type, "data": encoded}},
                    prompt_json,
                ],
            ),
            timeout=30.0,
        )
        logger.info(f"[OCR GEMINI] JSON attempt completed in {time.time() - start_ts:.2f}s")
    except Exception as e:
        logger.error("[OCR ERROR] Gemini call failed on JSON attempt")
        logger.error(f"{type(e).__name__}: {e}")
        logger.error(traceback.format_exc())
        raise

    raw = (getattr(response, "text", None) or "").strip()
    if raw:
        try:
            data = json.loads(raw)
            if isinstance(data, dict) and "text" in data:
                txt = data.get("text") or ""
                if txt.strip():
                    return txt
        except Exception:
            pass

    # Fallback 1: Plain text
    try:
        logger.info("[OCR GEMINI] Plain-text fallback attempt")
        retry_resp = await asyncio.wait_for(
            asyncio.to_thread(
                model.generate_content,
                [
                    {"inline_data": {"mime_type": mime_type, "data": encoded}},
                    "Extract all readable text only. Respond with plain text and nothing else.",
                ],
            ),
            timeout=30.0,
        )
        retry_text = (getattr(retry_resp, "text", None) or "").strip()
        if retry_text:
            return retry_text
    except Exception as e:
        logger.error("[OCR ERROR] Plain-text fallback failed")
        logger.error(f"{type(e).__name__}: {e}")
        logger.error(traceback.format_exc())

    # Fallback 2: look through candidate parts
    try:
        logger.info("[OCR GEMINI] Candidate parts fallback attempt")
        for cand in getattr(response, "candidates", []) or []:
            content = getattr(cand, "content", None)
            for part in getattr(content, "parts", []) or []:
                if isinstance(part, dict) and "text" in part and str(part.get("text")).strip():
                    return str(part.get("text")).strip()
                if isinstance(part, str) and part.strip():
                    return part.strip()
    except Exception as e:
        logger.error("[OCR ERROR] Candidate parsing failed")
        logger.error(f"{type(e).__name__}: {e}")
        logger.error(traceback.format_exc())

    return raw or ""


@router.get("/health")
async def health_check():
    return {
        "status": "ok",
        "provider": "gemini-1.5-flash",
        "api_key_configured": bool(API_KEY)
    }


@router.post("/extract")
async def ocr_extract(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded")

    content_type = file.content_type or _guess_mime_type(file.filename)
    logger.info(f"[OCR REQUEST] filename={file.filename} content_type={content_type}")
    if content_type not in SUPPORTED_MIME_TYPES:
        logger.error(f"[OCR ERROR] Unsupported media type: {content_type}")
        raise HTTPException(status_code=400, detail=f"Unsupported file type: {content_type}. Use JPEG, PNG, or WebP.")

    try:
        contents = await file.read(MAX_FILE_SIZE + 1)
    except Exception:
        raise HTTPException(status_code=400, detail="Failed to read file")

    logger.info(f"[OCR REQUEST] bytes_received={len(contents) if contents else 0}")
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail="File too large (max 5MB)")
    if len(contents) == 0:
        raise HTTPException(status_code=400, detail="Empty file")

    try:
        text = await _extract_text_gemini(contents, content_type)
    except Exception as e:
        logger.error("[OCR ERROR] Unhandled exception in ocr_extract")
        logger.error(f"{type(e).__name__}: {e}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail="OCR processing failed")

    preview = (text or "").strip()
    if not preview:
        return JSONResponse(status_code=200, content={"text": "", "warning": "No text detected in image"})
    if len(preview) > 1000:
        logger.info("[OCR EXTRACTED TEXT] " + preview[:1000])
    else:
        logger.info("[OCR EXTRACTED TEXT] " + preview)
    return {"text": text}


@router.post("/extract-case/")
async def extract_case(file: UploadFile = File(...)):
    """Legacy compatibility endpoint"""
    return await ocr_extract(file)