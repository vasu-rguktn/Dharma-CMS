from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import google.generativeai as genai
import uvicorn
import base64
import json
import os
from tempfile import NamedTemporaryFile
from typing import List
from dotenv import load_dotenv
import dotenv
import traceback
import time
import asyncio
import dotenv
load_dotenv()

API_KEY = os.getenv("GEMINI_API_KEY")

# Configure Gemini only if key present
if API_KEY:
    genai.configure(api_key=API_KEY)

app = FastAPI()

# Allowing the requests from Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/health")
async def health_check():
    return {"status": "ok"}

def extract_and_classify_case(image_path):
    with open(image_path, "rb") as img:
        img_bytes = img.read()

    encoded = base64.b64encode(img_bytes).decode("utf-8")

    model = genai.GenerativeModel("gemini-2.5-flash")

    prompt = """
You are a legal AI assistant.
Extract the readable text from the provided image and classify the case.

STRICT RULES:
- Answer ONLY in VALID JSON format
- NO additional sentences, disclaimers, or markdown
- JSON keys MUST include double quotes
- If any field is not found, return "Unknown"

Response format:
{
  "extracted_text": "string",
  "ipc_section": "string",
  "classification": "Cognizable or Non-Cognizable"
}
"""

    response = model.generate_content([
        prompt,
        {"inline_data": {
            "mime_type": "image/jpeg" if image_path.lower().endswith((".jpg", ".jpeg")) else "image/png",
            "data": encoded,
        }}
    ])

    raw = response.text.strip()

    # ✅ JSON Cleaning
    try:
        json_start = raw.find("{")
        json_end = raw.rfind("}") + 1
        cleaned_json = raw[json_start:json_end]
        return json.loads(cleaned_json)
    except:
        return {"error": "Invalid JSON", "raw": raw}


@app.post("/extract-case/")
async def upload_image(file: UploadFile = File(...)):
    # ✅ Save uploaded temp file
    suffix = os.path.splitext(file.filename)[1]
    with NamedTemporaryFile(delete=False, suffix=suffix) as temp:
        temp.write(await file.read())
        temp_path = temp.name

    # ✅ Process image
    result = extract_and_classify_case(temp_path)

    # ✅ Remove the temp file
    os.remove(temp_path)

    return result


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

# ============================= New OCR Endpoint (Structured) =============================

SUPPORTED_IMAGE_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}

def _guess_mime_type_from_filename(filename: str) -> str:
    lower = filename.lower()
    if lower.endswith((".jpg", ".jpeg")):
        return "image/jpeg"
    if lower.endswith(".png"):
        return "image/png"
    if lower.endswith(".webp"):
        return "image/webp"
    return "application/octet-stream"

async def extract_text_from_image_bytes(image_bytes: bytes, mime_type: str) -> dict:
    if not API_KEY:
        print("[OCR ERROR] Missing GEMINI_API_KEY in environment", flush=True)
        return {"error": "GEMINI_API_KEY is not set on the server"}

    encoded = base64.b64encode(image_bytes).decode("utf-8")

    model = genai.GenerativeModel("gemini-2.5-flash")

    # Attempt 1: Ask for JSON with {"text": "..."}
    prompt_json = (
        "Extract all readable text from the provided image. "
        "Return ONLY valid JSON exactly in the form: {\"text\": \"<EXTRACTED_TEXT>\"}."
    )

    try:
        start_ts = time.time()
        print(f"[OCR GEMINI] JSON attempt (mime={mime_type}, bytes={len(image_bytes)})", flush=True)
        # Add timeout to Gemini call
        response = await asyncio.wait_for(
            asyncio.to_thread(
                model.generate_content,
                [
                    {"inline_data": {"mime_type": mime_type, "data": encoded}},
                    prompt_json,
                ]
            ),
            timeout=30.0  # 30 second timeout
        )
        print(f"[OCR GEMINI] JSON attempt completed in {time.time() - start_ts:.2f}s", flush=True)
    except Exception as e:
        print("[OCR ERROR] Gemini call failed on JSON attempt", flush=True)
        print(type(e).__name__, str(e), flush=True)
        print(traceback.format_exc(), flush=True)
        return {"error": f"Gemini call failed: {e}"}

    raw = (getattr(response, "text", None) or "").strip()
    if raw:
        try:
            data = json.loads(raw)
            if isinstance(data, dict) and "text" in data:
                txt = data.get("text") or ""
                if txt.strip():
                    return {"text": txt}
        except Exception:
            # Not valid JSON; keep going
            pass

    # Fallback 1: Ask for plain text only
    try:
        print("[OCR GEMINI] Plain-text fallback attempt", flush=True)
        retry_resp = await asyncio.wait_for(
            asyncio.to_thread(
                model.generate_content,
                [
                    {"inline_data": {"mime_type": mime_type, "data": encoded}},
                    "Extract all readable text only. Respond with plain text and nothing else.",
                ]
            ),
            timeout=30.0  # 30 second timeout
        )
        retry_text = (getattr(retry_resp, "text", None) or "").strip()
        if retry_text:
            return {"text": retry_text}
    except Exception as e:
        print("[OCR ERROR] Plain-text fallback failed", flush=True)
        print(type(e).__name__, str(e), flush=True)
        print(traceback.format_exc(), flush=True)

    # Fallback 2: collect any text parts from candidates
    try:
        print("[OCR GEMINI] Candidate parts fallback attempt", flush=True)
        for cand in getattr(response, "candidates", []) or []:
            for part in getattr(getattr(cand, "content", None), "parts", []) or []:
                if isinstance(part, dict) and "text" in part and str(part.get("text")).strip():
                    return {"text": str(part.get("text")).strip()}
                if isinstance(part, str) and part.strip():
                    return {"text": part.strip()}
    except Exception as e:
        print("[OCR ERROR] Candidate parsing failed", flush=True)
        print(type(e).__name__, str(e), flush=True)
        print(traceback.format_exc(), flush=True)

    # Final fallback
    if not raw:
        print("[OCR WARNING] Empty response text from Gemini", flush=True)
    return {"text": raw}


@app.post("/api/ocr/extract")
async def ocr_extract(file: UploadFile = File(...)):
    # Validate mime
    content_type = file.content_type or _guess_mime_type_from_filename(file.filename)
    print(f"[OCR REQUEST] filename={file.filename} content_type={content_type}", flush=True)
    if content_type not in SUPPORTED_IMAGE_MIME_TYPES:
        err = {
            "error": f"Unsupported media type: {content_type}",
            "supported": sorted(list(SUPPORTED_IMAGE_MIME_TYPES)),
        }
        print(f"[OCR ERROR] {err}", flush=True)
        return err

    # Read bytes (no persistence needed)
    data = await file.read()
    print(f"[OCR REQUEST] bytes_received={len(data) if data else 0}", flush=True)
    if not data:
        print("[OCR ERROR] Empty file upload", flush=True)
        return {"error": "Empty file upload"}

    # Extract
    try:
        result = await extract_text_from_image_bytes(data, content_type)
    except Exception as e:
        print("[OCR ERROR] Unhandled exception in ocr_extract", flush=True)
        print(type(e).__name__, str(e), flush=True)
        print(traceback.format_exc(), flush=True)
        return {"error": f"OCR processing failed: {e}"}

    # Log the extracted text (truncate to avoid huge logs)
    try:
        if isinstance(result, dict):
            if "error" in result:
                print(f"[OCR RESULT ERROR] {result['error']}", flush=True)
            preview = str(result.get("text", ""))
            if preview.strip():
                print("[OCR EXTRACTED TEXT]", preview[:1000], flush=True)
            else:
                print("[OCR EXTRACTED TEXT] <empty>", flush=True)
    except Exception as e:
        print(f"[OCR LOGGING ERROR] {e}", flush=True)

    if isinstance(result, dict):
        if result.get("error"):
            return {"error": result.get("error")}
        if "text" in result:
            return {"text": result.get("text", "")}
    return {"error": "Unexpected OCR result format"}
