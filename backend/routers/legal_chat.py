from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
import os
import re
import base64
import io
from dotenv import load_dotenv
import google.generativeai as genai
from pypdf import PdfReader
from services.legal_rag import rag_enabled, retrieve_context
from utils.gemini_client import gemini_rotator

# ---------------- LOAD ENV ----------------
load_dotenv()
from loguru import logger

# Key management is handled by gemini_rotator — no manual genai.configure() needed.
_model_ready = gemini_rotator.key_count() > 0

if not _model_ready:
    logger.warning("[legal_chat] No Gemini API keys available. Legal Chat will fail at runtime.")

# ---------------- ROUTER ----------------
router = APIRouter(
    prefix="/api/legal-chat",
    tags=["Legal Chat"]
)

# ---------------- LANGUAGE MAP ----------------
LANGUAGE_NAMES = {
    "en": "English", "te": "Telugu", "hi": "Hindi", "ta": "Tamil",
    "kn": "Kannada", "ml": "Malayalam", "mr": "Marathi", "gu": "Gujarati",
    "bn": "Bengali", "pa": "Punjabi", "ur": "Urdu", "or": "Odia",
    "as": "Assamese",
}

def get_language_name(code: str) -> str:
    return LANGUAGE_NAMES.get(code.split('-')[0].lower(), "English")

# ---------------- SYSTEM PROMPT ----------------
SYSTEM_PROMPT = """
You are an expert Indian Legal Assistant specializing in the new criminal laws (BNS, BNSS, BSA).

Rules:
1. Analyze the user's query AND any attached documents (PDF/Images).
2. Answer ONLY legal-related questions.
3. Classify the issue (Civil, Criminal, Cyber, Family, Property).
4. Cite relevant Indian laws using Bharatiya Nyaya Sanhita (BNS), Bharatiya Nagarik Suraksha Sanhita (BNSS), and Bharatiya Sakshya Adhiniyam (BSA). Specify sections clearly.
5. Avoid citing IPC/CrPC unless explicitly asked or for historical comparison. Prioritize BNS/BNSS.
6. If the user uploads a document, summarize its legal key points first.
7. Use simple, clear language.
8. Disclaimer: "This is for informational purposes only, not professional legal advice."
"""

# ---------------- RESPONSE MODEL ----------------
class LegalChatResponse(BaseModel):
    reply: str
    title: str


# ---------------- HELPERS ----------------
def sanitize_input(text: str) -> str:
    text = re.sub(r"<.*?>", "", text)
    text = re.sub(r"[{};$]", "", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def extract_pdf_text(file_bytes: bytes) -> str:
    try:
        reader = PdfReader(io.BytesIO(file_bytes))
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        return text.strip()
    except Exception as e:
        print(f"PDF Extraction Error: {e}")
        return ""


def encode_image(file_bytes: bytes) -> str:
    return base64.b64encode(file_bytes).decode('utf-8')


# ---------------- ENDPOINT ----------------
@router.post("/", response_model=LegalChatResponse)
async def legal_chat(
    sessionId: str = Form(...),
    message: str = Form(...),
    language: str = Form("en"),
    files: list[UploadFile] = File(None)
):
    """
    Handles Legal Chat with optional Multiple File Uploads (PDF/Image).
    Title generation is merged into the main Gemini call (saves one round-trip).
    """
    if not _model_ready:
        raise HTTPException(status_code=500, detail="Gemini model not initialized. Check API keys.")

    clean_query = sanitize_input(message)
    target_lang = get_language_name(language)

    file_context = ""
    gemini_content = []

    # 1️⃣ RAG context
    context_block = ""
    if rag_enabled():
        try:
            context_text, _ = retrieve_context(clean_query, top_k=3)
            if context_text:
                context_block = f"\n[RAG CONTEXT FROM BNS/BNSS]:\n{context_text}\n"
        except Exception as e:
            print(f"RAG Error: {e}")

    final_text_prompt = f"{context_block}User Query: {clean_query}\nAnswer in {target_lang}."

    # 2️⃣ Process files
    files_info = ""
    if files:
        print(f"DEBUG: Received {len(files)} files.")
        files_info = f"[SYSTEM: User attached {len(files)} file(s). Analyze them.]"

        for file in files:
            print(f"DEBUG: Processing file {file.filename} ({file.content_type})")
            file_bytes = await file.read()

            if file.content_type == "application/pdf":
                extracted_text = extract_pdf_text(file_bytes)
                print(f"DEBUG: Extracted PDF text length: {len(extracted_text)}")
                if len(extracted_text.strip()) < 50:
                    file_context += f"\n\n[ATTACHED PDF ({file.filename})]:\n[WARNING: This PDF appears to be empty or scanned. Cannot extract text.]"
                else:
                    file_context += f"\n\n[ATTACHED PDF ({file.filename})]:\n{extracted_text[:10000]}..."

            elif file.content_type.startswith("image/"):
                b64 = encode_image(file_bytes)
                print(f"DEBUG: Encoded image. Length: {len(b64)}")
                mime_type = file.content_type or "image/jpeg"
                gemini_content.append({
                    "inline_data": {
                        "mime_type": mime_type,
                        "data": b64
                    }
                })

        if file_context:
            final_text_prompt += file_context

    # 3️⃣ Construct prompt — title generation merged into main call to save one round-trip
    full_prompt = (
        SYSTEM_PROMPT
        + f"\n[INSTRUCTION]: You MUST answer in {target_lang}.\n"
        + "OUTPUT FORMAT (MANDATORY — strictly follow this):\n"
        + "TITLE: [A short title for this query, max 6 words, in English]\n"
        + "THOUGHTS: [Your internal reasoning]\n"
        + "RESPONSE: [Your final message to the user]\n"
        + f"\n{files_info}\n\n{final_text_prompt}".strip()
    )

    if gemini_content:
        gemini_content.insert(0, full_prompt)
        content_to_send = gemini_content
    else:
        content_to_send = full_prompt

    print(f"DEBUG: Sending to Gemini. Content type: {type(content_to_send).__name__}")

    import time
    start_time = time.time()
    try:
        # 4️⃣ Single Gemini call — answer + title in one response
        session_id = f"legal-chat-{int(time.time())}"
        response = await gemini_rotator.generate_content_async(
            "models/gemini-1.5-flash",
            content_to_send,
            endpoint="/api/legal-chat",
            session_id=session_id
        )

        raw = response.text.strip() if response.text else ""

        # Parse RESPONSE: block
        reply = raw
        if "RESPONSE:" in raw:
            reply = raw.split("RESPONSE:", 1)[1].strip()
        else:
            reply = re.sub(r"^\*?Word count:.*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
            reply = re.sub(r"^Let's check.*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
            reply = re.sub(r"^Thinking Process:.*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
            reply = re.sub(r"^Internal Log:.*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
            reply = re.sub(r"^Note:.*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
            reply = re.sub(r"^Analysis:.*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
            reply = reply.strip()

        # Extract TITLE: from the merged output
        title = "Legal Query"
        title_match = re.search(r"^TITLE:\s*(.+)$", raw, re.MULTILINE | re.IGNORECASE)
        if title_match:
            title_text = title_match.group(1).strip()
            # Limit to 6 words
            words = title_text.split()[:6]
            title = " ".join(words) if words else "Legal Query"

        return {
            "reply": reply,
            "title": title
        }

    except Exception as e:
        print(f"Legal Chat Error: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to process request: {str(e)}"
        )
