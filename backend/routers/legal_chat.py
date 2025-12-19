from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os
import re
from dotenv import load_dotenv
from openai import OpenAI

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
You are an Indian legal assistant.

Rules:
- Answer ONLY legal-related questions.
- Classify the issue (Civil, Criminal, Cyber, Family, Property).
- Mention relevant Indian laws.
- If NOT a legal question, politely refuse.
- Use simple language.
- This is general legal information, not legal advice.
"""

# ---------------- MODELS ----------------
class LegalChatRequest(BaseModel):
    sessionId: str
    message: str


class LegalChatResponse(BaseModel):
    reply: str
    title: str


# ---------------- HELPERS ----------------
def sanitize_input(text: str) -> str:
    text = re.sub(r"<.*?>", "", text)
    text = re.sub(r"[{};$]", "", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def is_valid_input(text: str) -> bool:
    if not text or len(text) > 500:
        return False
    blocked = ["<script", "eval(", "function(", "alert("]
    return not any(b in text.lower() for b in blocked)


def generate_chat_title(query: str) -> str:
    """
    Generate a SHORT (max 6 words) chat title
    """
    prompt = f"""
    Generate a short title (maximum 6 words)
    for this Indian legal query.
    Do not use quotes.

    Query:
    {query}
    """

    response = client.responses.create(
        model="gpt-4.1-mini",
        input=[
            {"role": "system", "content": "You generate short chat titles."},
            {"role": "user", "content": prompt},
        ],
    )

    title = response.output_text.strip()

    # Fallback safety
    if not title:
        title = "Legal Query"

    return title


# ---------------- ENDPOINT ----------------
@router.post("/", response_model=LegalChatResponse)
def legal_chat(req: LegalChatRequest):
    if not is_valid_input(req.message):
        raise HTTPException(status_code=400, detail="Invalid input")

    clean_query = sanitize_input(req.message)

    try:
        # 1️⃣ Generate legal answer
        answer_response = client.responses.create(
            model="gpt-4.1-mini",
            input=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": clean_query},
            ],
        )

        reply = answer_response.output_text

        # 2️⃣ Generate title
        title = generate_chat_title(clean_query)

        return {
            "reply": reply,
            "title": title
        }

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Failed to generate legal response"
        )
