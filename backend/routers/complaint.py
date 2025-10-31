from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
import os
from dotenv import load_dotenv
from openai import OpenAI
import re
from loguru import logger

router = APIRouter(prefix="/complaint", tags=["Police Complaint"])

# === Env & Client ===
load_dotenv()
HF_TOKEN = os.getenv("HF_TOKEN")
if not HF_TOKEN:
    # Allow server to start; endpoint will raise if missing
    pass
client = OpenAI(
    base_url="https://router.huggingface.co/v1",
    api_key=HF_TOKEN or "",
)
LLM_MODEL = "openai/gpt-oss-120b"

# === Schemas ===
class ComplaintRequest(BaseModel):
    full_name: str = Field(..., min_length=1)
    address: str = Field(..., min_length=1)
    phone: str = Field(..., min_length=10)
    complaint_type: str = Field(..., min_length=1)
    details: str = Field(..., min_length=10)

class ComplaintResponse(BaseModel):
    formal_summary: str
    classification: str
    raw_conversation: str
    timestamp: str

# === Helpers ===
def build_conversation(req: ComplaintRequest) -> str:
    lines = [
        f"What is your full name?: {req.full_name}",
        f"Where do you live (place / area)?: {req.address}",
        f"What is your phone number?: {req.phone}",
        f"What type of complaint do you want to file? (Theft, Harassment, Missing person, etc.)?: {req.complaint_type}",
        f"Complaint Details: {req.details}",
    ]
    return "\n".join(lines)

def get_timestamp() -> str:
    return datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")

# === LLM Calls ===
def generate_summary(conversation: str) -> str:
    if not HF_TOKEN:
        raise RuntimeError("HF_TOKEN is not set on the server")
    completion = client.chat.completions.create(
        model=LLM_MODEL,
        messages=[
            {
                "role": "system",
                "content": (
                    "You are a helpful and professional police assistant. "
                    "You collect and summarize citizen complaints clearly and respectfully. "
                    "Always respond in a formal tone suitable for police reports."
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Here are the citizen details:\n{conversation}\n\n"
                    "Create a formal police complaint summary."
                ),
            },
        ],
        temperature=0.2,
        max_tokens=800,
    )
    return (completion.choices[0].message.content or "").strip()

def _normalize_classification(text: str) -> str:
    """Normalize model output to: 'COGNIZABLE - <justification>' or 'NON-COGNIZABLE - <justification>'.
    Falls back to just the label if no justification is found.
    """
    raw = (text or "").strip()
    up = raw.upper()

    label: str
    if re.search(r"\bNON[-\s]?COGNIZABLE\b", up):
        label = "NON-COGNIZABLE"
    elif re.search(r"\bCOGNIZABLE\b", up):
        label = "COGNIZABLE"
    else:
        # Default to NON-COGNIZABLE if the model deviates too much
        return "NON-COGNIZABLE"

    # Extract justification after the label, handling common separators
    # Accept '-', '–', ':', or whitespace
    m = re.search(r"\b(?:COGNIZABLE|NON[-\s]?COGNIZABLE)\b\s*[\-–:]?\s*(.*)$", raw, re.IGNORECASE)
    justification = (m.group(1).strip() if m and m.group(1) else "")
    if justification:
        # Ensure single-line concise output
        justification = re.sub(r"\s+", " ", justification)
        # Use an en dash to match desired display: "LABEL – justification"
        return f"{label} – {justification}"
    return label

def classify_offence(formal_summary: str, *, complaint_type: str = "", details: str = "") -> str:
    if not HF_TOKEN:
        raise RuntimeError("HF_TOKEN is not set on the server")
    # First: simple rule-based guardrails to avoid hallucinations (e.g., 'theft' when not present)
    text = f"{complaint_type} \n {details}".lower()
    cognizable_keywords = {
        "theft", "robbery", "extortion", "house-breaking", "house breaking", "murder",
        "rape", "kidnapping", "kidnap", "dacoity", "armed robbery", "burglary",
        "acid attack", "arson", "attempt to murder", "grievous hurt"
    }
    non_cognizable_keywords = {
        "defamation", "false information", "rumor", "rumour", "slander", "libel",
        "verbal abuse", "abuse", "insult", "minor dispute", "argument", "domestic argument",
        "neighbour dispute", "neighbor dispute"
    }

    if any(k in text for k in non_cognizable_keywords):
        logger.info("Rule-based classification → NON-COGNIZABLE (matched non-cognizable keywords)")
        return "NON-COGNIZABLE - Falls under defamation/minor dispute category; magistrate order required."
    if any(k in text for k in cognizable_keywords):
        logger.info("Rule-based classification → COGNIZABLE (matched cognizable keywords)")
        return "COGNIZABLE - Offence permits police action without warrant (serious offence keywords present)."
    criteria = (
        "You are an expert in Indian criminal procedure. Decide ONLY from the provided fields. "
        "Do NOT assume missing facts, do NOT infer offences from examples in questions, and do NOT guess. "
        "If a specific offence (e.g., theft/robbery/extortion/rape/murder/kidnapping) is not explicitly present in the details, "
        "you MUST NOT classify based on that offence. When uncertain or ambiguous, prefer NON-COGNIZABLE.\n\n"
        "Output format (exactly one line):\n"
        "COGNIZABLE – <one sentence reason>  OR  NON-COGNIZABLE – <one sentence reason>."
    )
    user_payload = (
        "Decide for this complaint using ONLY the following fields.\n\n"
        f"Complaint Type: {complaint_type}\n"
        f"Details: {details}"
    )
    resp = client.chat.completions.create(
        model=LLM_MODEL,
        temperature=0.0,
        max_tokens=100,
        messages=[
            {"role": "system", "content": criteria},
            {"role": "user", "content": user_payload},
        ],
    )
    raw = (resp.choices[0].message.content or "").strip()
    result = _normalize_classification(raw)
    # Final safety check: if model mentions 'theft' but details do not, downgrade to NON-COGNIZABLE
    if "theft" in result.lower() and "theft" not in text:
        logger.warning("Model suggested theft but details do not contain theft → overriding to NON-COGNIZABLE")
        return "NON-COGNIZABLE - No explicit cognizable offence mentioned in details."
    return result

@router.post(
    "/summarize",
    response_model=ComplaintResponse,
    status_code=status.HTTP_200_OK,
)
async def process_complaint(payload: ComplaintRequest):
    try:
        conversation = build_conversation(payload)
        formal_summary = generate_summary(conversation)
        logger.info(f"Complaint input → type='{payload.complaint_type}', details='{payload.details}'")
        classification = classify_offence(
            formal_summary,
            complaint_type=payload.complaint_type,
            details=payload.details,
        )
        logger.info(f"Classification decided → {classification}")
        # Friendly one-line verdict for terminal visibility
        label_upper = ("" if classification is None else str(classification)).upper()
        if "COGNIZABLE" in label_upper and "NON-COGNIZABLE" not in label_upper:
            logger.success("Case Classification: COGNIZABLE")
        elif "NON-COGNIZABLE" in label_upper:
            logger.success("Case Classification: NON-COGNIZABLE")
        else:
            logger.warning("Case Classification: UNKNOWN (model output not recognized)")
        response = ComplaintResponse(
            formal_summary=formal_summary,
            classification=classification,
            raw_conversation=conversation,
            timestamp=get_timestamp(),
        )
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process complaint: {e}")
