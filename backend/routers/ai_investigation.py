from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os
import re
from dotenv import load_dotenv
import google.generativeai as genai

# ───────────────── LOAD ENV ─────────────────
load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_INVESTIGATION")

if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY_INVESTIGATION not set")

genai.configure(api_key=GEMINI_API_KEY)

# ✅ IMPORTANT: Supported model
# model = genai.GenerativeModel("gemini-pro")
# ✅ MUST USE FULL MODEL NAME
model = genai.GenerativeModel("models/gemini-pro")

# ───────────────── ROUTER ─────────────────
router = APIRouter(
    prefix="/api/ai-investigation",
    tags=["AI Investigation"]
)

# ───────────────── SYSTEM PROMPT ─────────────────
SYSTEM_PROMPT = """
You are NyayaSahayak, an AI guide for Crime Scene Investigation in India.

Rules:
- Act like a senior investigating officer.
- Guide the investigation step-by-step.
- Ask ONLY ONE clear question at a time.
- Follow this strict order:
  1. Arrival & Initial Observations
  2. Scene Description
  3. Crime Specifics
  4. Physical Evidence
  5. Victims / Suspects
  6. Witnesses
  7. Sketch / Measurements
  8. Other Observations
- Do NOT jump steps.
- Use simple professional police language.
- This is assistance, not a final legal opinion.
"""

# ───────────────── MODELS ─────────────────
class InvestigationRequest(BaseModel):
    fir_number: str
    message: str
    chat_history: str = ""
    language: str = "English"
    petition_title: str = ""
    petition_details: str = ""


class InvestigationResponse(BaseModel):
    fir_number: str
    reply: str


# ───────────────── HELPERS ─────────────────
def sanitize_input(text: str) -> str:
    text = re.sub(r"<.*?>", "", text)
    text = re.sub(r"[{};$]", "", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def is_valid_input(text: str) -> bool:
    if not text or len(text) > 800:
        return False
    blocked = ["<script", "eval(", "function(", "alert("]
    return not any(b in text.lower() for b in blocked)


# ───────────────── ENDPOINT ─────────────────
@router.post("/", response_model=InvestigationResponse)
def ai_investigation(req: InvestigationRequest):

    if not req.fir_number:
        raise HTTPException(status_code=400, detail="FIR number is required")

    if not is_valid_input(req.message):
        raise HTTPException(status_code=400, detail="Invalid input")

    clean_message = sanitize_input(req.message)

    # Build case context
    case_context = ""
    if req.petition_title or req.petition_details:
        case_context = f"""
Case Information:
- Title: {req.petition_title or 'N/A'}
- Details:
{req.petition_details or 'N/A'}
"""

    full_prompt = f"""
{SYSTEM_PROMPT}

FIR Number: {req.fir_number}
Language: {req.language}

{case_context}

Previous Investigation Notes:
{req.chat_history}

Officer's Latest Input:
{clean_message}

Ask ONLY the NEXT logical investigation question.
"""

    try:
        response = model.generate_content(full_prompt)

        reply = response.text.strip() if response.text else ""

        if not reply:
            reply = "Please provide details regarding your arrival at the scene."

        return InvestigationResponse(
            fir_number=req.fir_number,
            reply=reply
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"AI Investigation failed: {str(e)}"
        )
