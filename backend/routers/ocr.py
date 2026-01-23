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
SUPPORTED_MIME_TYPES: Set[str] = {
    "image/jpeg", 
    "image/png", 
    "image/webp",
    "application/pdf",
    "application/msword",  # .doc
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",  # .docx
}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB (increased for documents)


def _guess_mime_type(filename: str) -> str:
    ext = filename.lower().split(".")[-1]
    return {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
        "pdf": "application/pdf",
        "doc": "application/msword",
        "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
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


async def _extract_document_text(file_bytes: bytes, content_type: str, filename: str) -> str:
    """Extract text from documents (PDF, DOC, DOCX) or images using Gemini LLM"""
    
    if not API_KEY:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured")
    
    encoded = base64.b64encode(file_bytes).decode("utf-8")
    model = genai.GenerativeModel("gemini-2.5-flash")
    
    # Handle PDF files - use Gemini LLM to extract text
    if content_type == "application/pdf":
        prompt = "Extract all text content from this PDF document. Return ONLY the extracted text, nothing else. Preserve the structure and formatting as much as possible."
        mime_type = "application/pdf"
        
    # Handle DOC/DOCX files - use Gemini LLM to extract text
    elif content_type in ["application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]:
        prompt = "Extract all text content from this Word document. Return ONLY the extracted text, nothing else. Preserve the structure and formatting as much as possible."
        mime_type = content_type
        
    # Handle images - use Gemini for OCR
    elif content_type in ["image/jpeg", "image/png", "image/webp"]:
        return await _extract_text_gemini(file_bytes, content_type)
    
    else:
        raise HTTPException(status_code=400, detail=f"Unsupported file type: {content_type}")
    
    # Use Gemini LLM for document extraction
    try:
        logger.info(f"[DOCUMENT EXTRACTION] Using Gemini LLM for {content_type}: {filename} ({len(file_bytes)} bytes)")
        response = await asyncio.wait_for(
            asyncio.to_thread(
                model.generate_content,
                [
                    {
                        "inline_data": {
                            "mime_type": mime_type,
                            "data": encoded
                        }
                    },
                    prompt
                ]
            ),
            timeout=60.0,
        )
        
        text = (getattr(response, "text", None) or "").strip()
        if text:
            logger.info(f"[DOCUMENT EXTRACTION] Successfully extracted {len(text)} characters")
            return text
        else:
            raise ValueError("No text extracted from document")
            
    except Exception as e:
        logger.error(f"[DOCUMENT EXTRACTION ERROR] {type(e).__name__}: {e}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Document extraction failed: {str(e)}")


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
        raise HTTPException(
            status_code=400, 
            detail=f"Unsupported file type: {content_type}. Supported: JPEG, PNG, WebP, PDF, DOC, DOCX."
        )

    try:
        contents = await file.read(MAX_FILE_SIZE + 1)
    except Exception:
        raise HTTPException(status_code=400, detail="Failed to read file")

    logger.info(f"[OCR REQUEST] bytes_received={len(contents) if contents else 0}")
    if len(contents) > MAX_FILE_SIZE:
        raise HTTPException(status_code=400, detail=f"File too large (max {MAX_FILE_SIZE // (1024*1024)}MB)")
    if len(contents) == 0:
        raise HTTPException(status_code=400, detail="Empty file")

    try:
        text = await _extract_document_text(contents, content_type, file.filename or "unknown")
    except HTTPException:
        # Re-raise HTTP exceptions as-is
        raise
    except Exception as e:
        logger.error("[OCR ERROR] Unhandled exception in ocr_extract")
        logger.error(f"{type(e).__name__}: {e}")
        logger.error(traceback.format_exc())
        raise HTTPException(status_code=500, detail=f"Document processing failed: {str(e)}")

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