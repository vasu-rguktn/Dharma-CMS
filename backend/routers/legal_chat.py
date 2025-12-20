from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
import os
import re
import base64
import io
from dotenv import load_dotenv
from openai import OpenAI
from pypdf import PdfReader

# ---------------- LOAD ENV ----------------
load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY_Legal_queries")

if not OPENAI_API_KEY:
    raise RuntimeError("OPENAI_API_KEY_Legal_queries not set")

client = OpenAI(api_key=OPENAI_API_KEY)

# ---------------- ROUTER ----------------
router = APIRouter(
    prefix="/api/legal-chat",
    tags=["Legal Chat"]
)

# ---------------- PROMPT ----------------
SYSTEM_PROMPT = """
You are an expert Indian Legal Assistant.

Rules:
1. Analyze the user's query AND any attached documents (PDF/Images).
2. Answer ONLY legal-related questions.
3. Classify the issue (Civil, Criminal, Cyber, Family, Property).
4. Cite relevant Indian laws (IPC, CrPC, IT Act, etc.) with sections.
5. If the user uploads a document, summarize its legal key points first.
6. Use simple, clear language.
7. Disclaimer: "This is for informational purposes only, not professional legal advice."
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
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "Generate a short title (max 6 words) for this legal query. No quotes."},
                {"role": "user", "content": query[:200]} # Limit context for title
            ],
            max_tokens=20
        )
        return response.choices[0].message.content.strip() or "Legal Query"
    except:
        return "Legal Query"


# ---------------- ENDPOINT ----------------
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
    # OpenAI Vision supports multiple images in content list
    user_content = []
    
    # 1️⃣ Process Query
    final_text_prompt = f"User Query: {clean_query}"
    
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
                # Add image directly to content list
                user_content.append({
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{b64}"
                    }
                })
        
        if file_context:
            final_text_prompt += file_context

    # 2️⃣ Construct Messages
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT + f"\n{files_info}"},
    ]

    # Prepend text prompt to user content
    # Ensure text is clean
    final_text_prompt = final_text_prompt.strip()
    
    if user_content:
        # If we have images, we use the list format. Text must be FIRST.
        user_content.insert(0, {"type": "text", "text": final_text_prompt})
        messages.append({"role": "user", "content": user_content})
    else:
        # Text only
        messages.append({"role": "user", "content": final_text_prompt})
    
    print(f"DEBUG: Sending to OpenAI. Messages count: {len(messages)}")

    try:
        # 3️⃣ Generate Answer
        answer_response = client.chat.completions.create(
            model="gpt-4o-mini", 
            messages=messages,
            max_tokens=1500
        )

        reply = answer_response.choices[0].message.content

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
