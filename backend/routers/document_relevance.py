from fastapi import APIRouter, UploadFile, File, Form
from pydantic import BaseModel
from typing import List, Optional

import os
import json
from io import BytesIO
import base64
import asyncio

import google.generativeai as genai
from google.generativeai import types as genai_types
from pypdf import PdfReader

from .ocr import _extract_text_gemini, _guess_mime_type, SUPPORTED_MIME_TYPES


router = APIRouter(
    prefix="/api/document-relevance",
    tags=["Document Relevance"],
)


GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)


class DocumentRelevanceResponse(BaseModel):
    overall_score: float
    color: str
    reason: str


def _fallback_response(message: str) -> DocumentRelevanceResponse:
    """
    Safe amber fallback if the LLM or parsing fails.
    """
    return DocumentRelevanceResponse(
        overall_score=0.5,
        color="amber",
        reason=message,
    )


async def _extract_text_gemini_generic(
    file_bytes: bytes, mime_type: str, filename: str
) -> str:
    """
    Use Gemini to extract readable text from arbitrary files (PDF, DOCX, etc.).
    Returns plain text or empty string on failure.
    """
    if not GEMINI_API_KEY or not file_bytes:
        return ""

    prompt = (
        "You are given a file related to a police case.\n"
        "Extract all readable text that would be useful for understanding the facts "
        "of the case. Return ONLY plain text, no JSON, no markdown, no commentary."
    )

    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        b64 = base64.b64encode(file_bytes).decode("utf-8")
        response = await asyncio.to_thread(
            model.generate_content,
            [
                {"inline_data": {"mime_type": mime_type, "data": b64}},
                prompt,
            ],
        )
        text = (getattr(response, "text", None) or "").strip()
        return text
    except Exception:
        return ""


async def _summarize_files(files: Optional[List[UploadFile]]) -> str:
    """
    Turn uploaded files into short text snippets using:
    - Gemini OCR for images (via existing OCR helper)
    - pypdf for text-based PDFs
    - Gemini generic extraction for scanned PDFs and Office docs
    For other formats we fall back to filename only.
    """
    if not files:
        return "No files were attached."

    summaries: List[str] = []

    for f in files:
        if not f or not f.filename:
            continue

        filename = f.filename
        lower_name = filename.lower()

        try:
            contents = await f.read()
        except Exception:
            summaries.append(f"- {filename}: (could not read file bytes)")
            continue

        if not contents:
            summaries.append(f"- {filename}: (empty file)")
            continue

        # Try image OCR first (JPEG/PNG/WebP, same as /api/ocr)
        mime_type = f.content_type or _guess_mime_type(filename)
        if mime_type in SUPPORTED_MIME_TYPES:
            try:
                text = await _extract_text_gemini(contents, mime_type)
                snippet = (text or "").strip().replace("\n", " ")
                if len(snippet) > 280:
                    snippet = snippet[:280] + "..."
                if snippet:
                    summaries.append(f"- {filename} (image text): {snippet}")
                    continue
            except Exception:
                # Fall through to other strategies if OCR fails
                pass

        # Try PDF extraction (embedded text)
        if lower_name.endswith(".pdf"):
            try:
                reader = PdfReader(BytesIO(contents))
                collected = []
                for page in reader.pages[:3]:  # first 3 pages are enough
                    txt = page.extract_text() or ""
                    if txt:
                        collected.append(txt.strip())
                full_txt = " ".join(collected).replace("\n", " ")
                snippet = full_txt[:280] + ("..." if len(full_txt) > 280 else "")
                if snippet:
                    summaries.append(f"- {filename} (PDF text): {snippet}")
                    continue
            except Exception:
                pass

        # Office documents or scanned PDFs: let Gemini read them directly
        office_exts = (".doc", ".docx", ".ppt", ".pptx", ".xls", ".xlsx")
        if lower_name.endswith(".pdf") or lower_name.endswith(office_exts):
            # Best-effort generic extraction
            generic_mime = mime_type
            if not generic_mime or generic_mime == "application/octet-stream":
                if lower_name.endswith(".pdf"):
                    generic_mime = "application/pdf"
                elif lower_name.endswith(".docx"):
                    generic_mime = (
                        "application/vnd.openxmlformats-officedocument."
                        "wordprocessingml.document"
                    )
                elif lower_name.endswith(".doc"):
                    generic_mime = "application/msword"
                elif lower_name.endswith(".xlsx"):
                    generic_mime = (
                        "application/vnd.openxmlformats-officedocument."
                        "spreadsheetml.sheet"
                    )
                elif lower_name.endswith(".xls"):
                    generic_mime = "application/vnd.ms-excel"
                elif lower_name.endswith(".pptx"):
                    generic_mime = (
                        "application/vnd.openxmlformats-officedocument."
                        "presentationml.presentation"
                    )
                elif lower_name.endswith(".ppt"):
                    generic_mime = "application/vnd.ms-powerpoint"

            try:
                text = await _extract_text_gemini_generic(
                    contents, generic_mime or "application/octet-stream", filename
                )
                snippet = (text or "").strip().replace("\n", " ")
                if len(snippet) > 280:
                    snippet = snippet[:280] + "..."
                if snippet:
                    summaries.append(f"- {filename} (AI extracted text): {snippet}")
                    continue
            except Exception:
                pass

        # Fallback: just include filename if nothing else worked
        summaries.append(f"- {filename}: (content not analyzed, using name only)")

    if not summaries:
        return "No files were attached."

    return "Uploaded evidence summaries:\n" + "\n".join(summaries)


@router.post("/", response_model=DocumentRelevanceResponse)
async def check_document_relevance(
    petition_title: str = Form(...),
    petition_description: str = Form(...),
    petition_type: str = Form(""),
    station_name: str = Form(""),
    update_text: str = Form(""),
    files: Optional[List[UploadFile]] = File(default=None),
):
    """
    AI endpoint that checks whether uploaded evidence
    (photos/documents + text) appears related to the current petition.
    """

    if not GEMINI_API_KEY:
        # Graceful degradation when LLM is not configured.
        return _fallback_response(
            "AI key not configured; please verify evidence manually."
        )

    case_context = f"""
Case Title: {petition_title}
Case Type: {petition_type}
Station: {station_name}

Original Petition Description:
{petition_description}

Officer's Update Text:
{update_text}
"""

    files_block = await _summarize_files(files)

    prompt = f"""
You are assisting a police officer in checking whether uploaded investigation
evidence files are actually related to a specific petition/case.

CASE CONTEXT:
{case_context}

{files_block}

TASK:
1. Decide how strongly the uploaded files (as a set) appear to support or relate
   to THIS case only. Consider the case title, type, petition description,
   and the officer's update text.
2. Return:
   - overall_score: a number between 0.0 and 1.0 (1.0 = clearly related)
   - color:
       * "green"  -> clearly related / strong match (score >= 0.7)
       * "amber"  -> maybe related / partial / needs review (0.4 <= score < 0.7)
       * "red"    -> likely unrelated or wrong case (score < 0.4)
   - reason: a short explanation (1–3 sentences) in plain language.

CRITICAL:
- If there is very little information, prefer "amber" with a cautionary message.
- NEVER mention that you are an AI model in the reason.
- DO NOT include any JSON comments.

Respond with STRICT JSON ONLY in this exact shape:
{{
  "overall_score": 0.0,
  "color": "green",
  "reason": "short explanation here"
}}
"""

    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        response = model.generate_content(
            prompt,
            generation_config=genai_types.GenerationConfig(
                temperature=0.2,
                max_output_tokens=512,
                response_mime_type="application/json",
            ),
        )
        raw = (getattr(response, "text", None) or "").strip()
    except Exception:
        return _fallback_response(
            "AI check failed due to a server error; please verify evidence manually."
        )

    if not raw:
        return _fallback_response(
            "AI did not return a response; please verify evidence manually."
        )

    try:
        # Primary attempt: direct JSON
        data = json.loads(raw)
    except Exception:
        # Fallback: extract the first {...} block from the text
        start = raw.find("{")
        end = raw.rfind("}")
        if start != -1 and end != -1 and end > start:
            try:
                data = json.loads(raw[start : end + 1])
            except Exception:
                return _fallback_response(
                    "AI response could not be parsed; please verify evidence manually."
                )
        else:
            return _fallback_response(
                "AI response could not be parsed; please verify evidence manually."
            )

    try:
        score = float(data.get("overall_score", 0.5))
        color = str(data.get("color", "amber")).lower().strip()
        reason = str(data.get("reason", "")).strip() or "AI review completed."

        if color not in {"green", "amber", "red"}:
            # Map unexpected values into the nearest bucket.
            if score >= 0.7:
                color = "green"
            elif score >= 0.4:
                color = "amber"
            else:
                color = "red"

        # Clamp score to [0, 1]
        score = max(0.0, min(1.0, score))

        return DocumentRelevanceResponse(
            overall_score=score,
            color=color,
            reason=reason,
        )
    except Exception:
        return _fallback_response(
            "AI response could not be parsed; please verify evidence manually."
        )

