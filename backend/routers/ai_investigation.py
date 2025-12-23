# ===================== IMPORTS =====================
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import List, Dict, Any
import os
import re
import json
import google.generativeai as genai

# ===================== ROUTER =====================
router = APIRouter(
    prefix="/api/ai-investigation",
    tags=["AI Investigation"]
)

# ===================== API KEY =====================
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_INVESTIGATION")
if not GEMINI_API_KEY:
    raise RuntimeError("GEMINI_API_KEY_INVESTIGATION not set")

genai.configure(api_key=GEMINI_API_KEY)

# ===================== MODEL =====================
model = genai.GenerativeModel("gemini-2.5-flash")

# ===================== REQUEST MODEL =====================
class FIRRequest(BaseModel):
    fir_id: str = Field(..., example="FIR-2024-ELURU-102")
    fir_details: str = Field(..., example="Complaint details of the FIR")

# ===================== RESPONSE SCHEMA (STRICT) =====================
class InvestigationTask(BaseModel):
    task: str
    priority: str
    status: str

class ApplicableLaw(BaseModel):
    section: str
    justification: str

class ForensicSuggestion(BaseModel):
    evidence_type: str
    protocol: str

class AIInvestigationReport(BaseModel):
    summary: str
    case_type_tags: List[str]
    modus_operandi_tags: List[str]
    investigation_tasks: List[InvestigationTask]
    applicable_laws: List[ApplicableLaw]
    precautions_and_protocols: List[str]
    anticipated_defence: List[str]
    prosecution_readiness: List[str]
    missing_information: List[str]
    forensic_suggestions: List[ForensicSuggestion]

# ===================== SANITIZER =====================
def sanitize_input(text: str) -> str:
    text = re.sub(r"<.*?>", "", text)
    text = re.sub(r"[{};$]", "", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()

# ===================== SYSTEM PROMPT =====================
SYSTEM_PROMPT = """
You are NyayaSahayak, a senior Indian Police Investigating Officer.

ROLE:
Generate a COMPLETE, PROFESSIONAL, COURT-READY investigation guideline.

STRICT RULES:
- DO NOT ask questions
- DO NOT chat
- DO NOT explain yourself
- DO NOT add markdown
- OUTPUT VALID JSON ONLY
- FOLLOW Indian police investigation procedure
- Assume this output will be parsed by software

OUTPUT FORMAT (JSON ONLY):

{
  "summary": "",
  "case_type_tags": [],
  "modus_operandi_tags": [],
  "investigation_tasks": [
    {
      "task": "",
      "priority": "Urgent | Routine",
      "status": "Pending | Completed"
    }
  ],
  "applicable_laws": [
    {
      "section": "",
      "justification": ""
    }
  ],
  "precautions_and_protocols": [],
  "anticipated_defence": [],
  "prosecution_readiness": [],
  "missing_information": [],
  "forensic_suggestions": [
    {
      "evidence_type": "",
      "protocol": ""
    }
  ]
}
"""

# ===================== AI CORE FUNCTION =====================
def generate_investigation_report(fir_details: str) -> Dict[str, Any]:
    clean_details = sanitize_input(fir_details)

    prompt = f"""
{SYSTEM_PROMPT}

FIR DETAILS:
{clean_details}
"""

    response = model.generate_content(prompt)

    if not response or not response.text:
        raise RuntimeError("AI returned empty response")

    try:
        parsed = json.loads(response.text)
    except json.JSONDecodeError:
        raise RuntimeError("AI returned invalid JSON")

    # Validate structure using Pydantic
    validated = AIInvestigationReport(**parsed)
    return validated.dict()

# ===================== API ENDPOINT =====================
@router.post("/", response_model=Dict[str, Any])
def ai_investigation(request: FIRRequest):
    try:
        report = generate_investigation_report(request.fir_details)

        return {
            "fir_id": request.fir_id,
            "report": report
        }

    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

    except Exception:
        raise HTTPException(
            status_code=500,
            detail="AI Investigation generation failed"
        )
