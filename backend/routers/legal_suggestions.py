from fastapi import APIRouter
from pydantic import BaseModel
import google.generativeai as genai
import os

# ===================== ROUTER =====================
router = APIRouter(
    prefix="/api/legal-suggestions",
    tags=["AI Legal Section Suggester"]
)

# ===================== GEMINI API KEY =====================
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_LEGAL_SUGGESTIONS")
if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY_LEGAL_SUGGESTIONS not set")

genai.configure(api_key=GEMINI_API_KEY)

# ===================== MODEL (UNCHANGED) =====================
model = genai.GenerativeModel("gemini-2.5-flash")

# ===================== REQUEST SCHEMA =====================
class LegalSuggestionRequest(BaseModel):
    incident_description: str

# ===================== RESPONSE SCHEMA =====================
class LegalSuggestionResponse(BaseModel):
    suggestedSections: str
    reasoning: str

# ===================== SYSTEM PROMPT (UNCHANGED) =====================
SYSTEM_PROMPT = """
You are an expert Indian legal AI assistant.

CRITICAL RULES:
1. Suggest sections ONLY from:
   - Bharatiya Nyaya Sanhita (BNS)
   - Bharatiya Nagarik Suraksha Sanhita (BNSS)
   - Bharatiya Sakshya Adhiniyam (BSA)
   - Current special acts (IT Act, POCSO, NDPS, etc.)

2. DO NOT mention IPC, CrPC, or Indian Evidence Act.
3. DO NOT infer facts not provided.
4. Output ONLY:
   - Suggested legal sections
   - Reasoning
5. If no section applies, clearly say so.

FORMAT STRICTLY AS:

Suggested Sections:
Each section MUST be written in this exact format:
Bharatiya Nyaya Sanhita (BNS) Section XXX (Meaning of the section)

Examples:
Bharatiya Nyaya Sanhita (BNS) Section 302 (Definition of Robbery)
Bharatiya Nyaya Sanhita (BNS) Section 303 (Punishment for Robbery)

Reasoning:
<text>

"""

# ===================== ENDPOINT =====================
@router.post("/", response_model=LegalSuggestionResponse)
def suggest_legal_sections(data: LegalSuggestionRequest):

    prompt = f"""{SYSTEM_PROMPT}

Incident Description:
{data.incident_description}
"""

    try:
        response = model.generate_content(prompt)
        output = response.text.strip()
    except Exception:
        return LegalSuggestionResponse(
            suggestedSections="Unable to generate legal sections.",
            reasoning="AI model error occurred while processing the incident."
        )

    if "Suggested Sections:" not in output:
        return LegalSuggestionResponse(
            suggestedSections="No applicable sections found under the new laws based on the provided details.",
            reasoning="The incident description does not clearly satisfy the ingredients of any offence under the new Indian criminal laws."
        )

    parts = output.split("Reasoning:")
    sections = parts[0].replace("Suggested Sections:", "").strip()
    reasoning = parts[1].strip() if len(parts) > 1 else "Reasoning not provided."

    return LegalSuggestionResponse(
        suggestedSections=sections,
        reasoning=reasoning
    )
