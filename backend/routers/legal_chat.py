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

# ---------------- LOAD ENV ----------------
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_INVESTIGATION")

if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY_INVESTIGATION not set")

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("models/gemini-2.5-flash")

# ---------------- ROUTER ----------------
router = APIRouter(
    prefix="/api/legal-chat",
    tags=["Legal Chat"]
)

# ---------------- PROMPT ----------------
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

# ---------------- MODELS (Response Only) ----------------
# Request model is not used because we use Form/File inputs separately
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


def generate_chat_title(query: str) -> str:
    """Generate a SHORT (max 6 words) chat title"""
    try:
        title_model = genai.GenerativeModel("models/gemini-2.5-flash")
        prompt = f"Generate a short title (max 6 words) for this legal query. No quotes.\n\nQuery: {query[:200]}"
        response = title_model.generate_content(prompt)
        title = response.text.strip() if response.text else "Legal Query"
        # Limit to 6 words
        words = title.split()[:6]
        return " ".join(words) or "Legal Query"
    except Exception as e:
        print(f"Title generation error: {e}")
        return "Legal Query"


# ---------------- ENDPOINT ---------------- 
# Using "/" with redirect_slashes=False in main.py prevents redirects
@router.post("/", response_model=LegalChatResponse)
async def legal_chat(
    sessionId: str = Form(...),
    message: str = Form(...),
    files: list[UploadFile] = File(None)
):
    """
    Handles Legal Chat with optional Multiple File Uploads (PDF/Image).
    """
    clean_query = sanitize_input(message)
    file_context = ""
    # Gemini supports multiple images in content list
    gemini_content = []
    
    # 1️⃣ Process Query
    context_block = ""
    if rag_enabled():
        try:
             context_text, _ = retrieve_context(clean_query, top_k=3)
             if context_text:
                 context_block = f"\n[RAG CONTEXT FROM BNS/BNSS]:\n{context_text}\n"
        except Exception as e:
            print(f"RAG Error: {e}")

    final_text_prompt = f"{context_block}User Query: {clean_query}"
    
    # 2️⃣ Process Files
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
                    file_context += f"\n\n[ATTACHED PDF ({file.filename})]:\n[WARNING: This PDF appears to be empty or scanned. Cannot extract text. treat it as unreadable.]"
                else:
                    file_context += f"\n\n[ATTACHED PDF ({file.filename})]:\n{extracted_text[:10000]}..." 
            
            elif file.content_type.startswith("image/"):
                b64 = encode_image(file_bytes)
                print(f"DEBUG: Encoded image. Length: {len(b64)}")
                # Determine MIME type
                mime_type = file.content_type or "image/jpeg"
                # Add image using Gemini's inline_data format
                gemini_content.append({
                    "inline_data": {
                        "mime_type": mime_type,
                        "data": b64
                    }
                })
        
        if file_context:
            final_text_prompt += file_context

    # 3️⃣ Construct Gemini Content
    # Gemini uses a simpler format: system prompt + user content (text + images)
    full_prompt = SYSTEM_PROMPT + f"\n{files_info}\n\n{final_text_prompt}".strip()
    
    # Build content: if images exist, use list format; otherwise just the prompt string
    if gemini_content:
        # Images present: text first, then images
        gemini_content.insert(0, full_prompt)
        content_to_send = gemini_content
    else:
        # Text only: just send the prompt string
        content_to_send = full_prompt
    
    print(f"DEBUG: Sending to Gemini. Content type: {type(content_to_send).__name__}")

    try:
        # 4️⃣ Generate Answer with Gemini
        answer_response = model.generate_content(content_to_send)

        reply = answer_response.text.strip() if answer_response.text else "I apologize, but I couldn't generate a response. Please try again."

        # 4️⃣ Generate Title
        title = generate_chat_title(clean_query)

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
