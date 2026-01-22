from fastapi import APIRouter
from pydantic import BaseModel
import google.generativeai as genai
import os
from typing import Optional

from services.legal_rag import rag_enabled, retrieve_context

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
    # Frontend already sends this; keep it optional for backwards-compat.
    language: Optional[str] = None
    # Optional tuning knobs (safe defaults)
    top_k: Optional[int] = 4

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
    lang = (data.language or "en").strip()
    incident = data.incident_description.strip()

    # Lightweight language hint (matches how the Flutter app appends language text elsewhere).
    if lang == "te":
        incident = f"{incident} (Please reply in Telugu language)"
    elif lang and lang != "en":
        incident = f"{incident} (Please reply in {lang} language)"

    # If RAG is enabled, retrieve context from Chroma and ground the answer.
    context_block = ""
    if rag_enabled():
        try:
            top_k = int(data.top_k or 4)
            context_text, _sources = retrieve_context(incident, top_k=top_k)
            if context_text:
                context_block = f"""
Context (retrieved knowledge base excerpts):
{context_text}
"""
        except Exception:
            # If RAG fails, fall back to plain generation rather than breaking the endpoint.
            context_block = ""

    prompt = f"""{SYSTEM_PROMPT}
{context_block}

Incident Description:
{incident}
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
