from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional, Dict, Tuple
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv
from openai import OpenAI
import re
from loguru import logger

router = APIRouter(prefix="/complaint", tags=["Police Complaint"])
# pradeep savara has made changes to the code
# === Env & Client ===
load_dotenv()
HF_TOKEN = os.getenv("HF_TOKEN")
if not HF_TOKEN:
    # Allow server start; LLM features will be skipped if missing
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
    language: Optional[str] = Field(default="en", description="ISO code such as en or te")

class ComplaintResponse(BaseModel):
    formal_summary: str
    classification: str
    original_classification: str  # New field
    raw_conversation: str
    timestamp: str
    localized_fields: Dict[str, str] = Field(default_factory=dict)

# === Helpers ===
def resolve_language(lang: Optional[str]) -> str:
    if not lang:
        return "en"
    code = lang.lower()
    if code.startswith("te"):
        return "te"
    return "en"


TELUGU_SCRIPT_RE = re.compile(r"[\u0C00-\u0C7F]")

ROMANIZED_TELUGU_PATTERNS = [
    re.compile(r"\bdoo?nga", re.IGNORECASE),
    re.compile(r"\bdongatan", re.IGNORECASE),
    re.compile(r"\bdongalin", re.IGNORECASE),
    re.compile(r"\bhatya", re.IGNORECASE),
    re.compile(r"\bapaharan", re.IGNORECASE),
    re.compile(r"\bhimsa", re.IGNORECASE),
]

CLASSIFICATION_HINTS = {
    "దొంగతనం": "theft",
    "దోపిడి": "robbery",
    "దాడి": "assault",
    "హత్య": "murder",
    "అపహరణ": "kidnapping",
    "ఆమ్ల దాడి": "acid attack",
    "అగ్నికి ఆహుతి": "arson",
    "dongatanam": "theft",
    "donga": "theft",
    "dongalincharu": "theft",
    "dongal": "theft",
    "hatya": "murder",
    "apaharan": "kidnapping",
    "aporadhi": "criminal",
    "acid attack": "acid attack",
    "kidnap": "kidnapping",
}


def _needs_translation(text: str) -> bool:
    if not text:
        return False
    if TELUGU_SCRIPT_RE.search(text):
        return False
    ascii_letters = re.sub(r"[^A-Za-z]", "", text)
    return bool(ascii_letters)


def _looks_romanized_telugu(text: str) -> bool:
    if not text or TELUGU_SCRIPT_RE.search(text):
        return False
    lowered = text.lower()
    for pattern in ROMANIZED_TELUGU_PATTERNS:
        if pattern.search(lowered):
            return True
    return False


def translate_to_telugu(text: str) -> str:
    """
    Convert user text into Telugu script:
      - If the text is English, translate it into natural Telugu.
      - If the text is Telugu written with English letters (romanized), transliterate it to Telugu script.
    Falls back to the original text if translation is not possible.
    """
    if not HF_TOKEN or not _needs_translation(text):
        return text
    try:
        resp = client.chat.completions.create(
            model=LLM_MODEL,
            temperature=0.2,
            max_tokens=1024,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You will receive text entered by a Telugu speaker. "
                        "Sometimes it is English sentences needing translation, other times it is Telugu words typed using English letters "
                        "(romanized Telugu such as 'ela unnaru' or 'meeru ekkada unnaru'). "
                        "Convert the input into natural Telugu script suitable for official police documentation. "
                        "If the input is romanized Telugu, transliterate it faithfully. "
                        "If the input is English, translate it into Telugu. "
                        "Preserve personal names, places, and numbers exactly as provided. "
                        "Return only the final Telugu text without quotes or commentary."
                    ),
                },
                {"role": "user", "content": text},
            ],
        )
        translated = (resp.choices[0].message.content or "").strip()
        return translated if translated else text
    except Exception as exc:
        logger.warning(f"Translation failed; using original text. Reason: {exc}")
        return text


SUMMARY_LABELS = {
    "en": {
        "header": "POLICE COMPLAINT SUMMARY",
        "full_name": "Full Name",
        "address": "Address",
        "phone": "Phone Number",
        "complaint_type": "Complaint Type",
        "details": "Details",
        "date_of_complaint": "Date of Complaint",
    },
    "te": {
        "header": "పోలీస్ ఫిర్యాదు సారాంశం",
        "full_name": "పూర్తి పేరు",
        "address": "చిరునామా",
        "phone": "ఫోన్ నంబర్",
        "complaint_type": "ఫిర్యాదు రకం",
        "details": "వివరాలు",
        "date_of_complaint": "ఫిర్యాదు తేదీ",
    },
}


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

def today_date_str() -> str:
    return datetime.utcnow().strftime("%Y-%m-%d")


TELUGU_DIGITS = {
    "0": "0",
    "1": "1",
    "2": "2",
    "3": "3",
    "4": "4",
    "5": "5",
    "6": "6",
    "7": "7",
    "8": "8",
    "9": "9",
}

TELUGU_MONTHS = [
    "జనవరి",
    "ఫిబ్రవరి",
    "మార్చి",
    "ఏప్రిల్",
    "మే",
    "జూన్",
    "జూలై",
    "ఆగస్టు",
    "సెప్టెంబర్",
    "అక్టోబర్",
    "నవంబర్",
    "డిసెంబర్",
]


def _to_telugu_digits(value: str) -> str:
    return "".join(TELUGU_DIGITS.get(ch, ch) for ch in value)


def format_date_for_language(language: str, dt: datetime) -> str:
    # Keep the date format consistent (YYYY-MM-DD) regardless of locale.
    return dt.strftime("%Y-%m-%d")

# kept for compatibility (not used in final summary)
def extract_incident_datetime(text: str) -> str:
    """Heuristic extraction; returns '' if not found"""
    if not text:
        return ""
    m = re.search(r"\b(20\d{2}-\d{2}-\d{2})\b", text)
    if m:
        return m.group(1)
    m = re.search(r"\b(\d{2}[/-]\d{2}[/-]\d{4})\b", text)
    if m:
        found = m.group(1)
        sep = "-" if "-" in found else "/"
        dd, mm, yyyy = found.split(sep)
        try:
            dt = datetime(int(yyyy), int(mm), int(dd))
            return dt.strftime("%Y-%m-%d")
        except Exception:
            return found
    if re.search(r"\btoday\b", text, flags=re.IGNORECASE):
        return today_date_str()
    if re.search(r"\byesterday\b", text, flags=re.IGNORECASE):
        return (datetime.utcnow() - timedelta(days=1)).strftime("%Y-%m-%d")
    return ""

# --- IPC helper unchanged (keeps safe checks) ---
def get_official_complaint_label(complaint_type: str, details: str) -> Optional[str]:
    if not HF_TOKEN:
        return None
    try:
        prompt = (
            "You are an expert in Indian criminal law. From the fields below, provide a concise official offence"
            " name and IPC section(s) if clearly applicable. Output exactly one short line like:\n"
            "Theft — IPC 378\nAttempted murder — IPC 307\nNot applicable\n\n"
            f"Complaint Type: {complaint_type}\n"
            f"Details: {details}\n\n"
            "If unsure or not applicable, reply with 'Not applicable'. DO NOT invent IPC numbers."
        )
        resp = client.chat.completions.create(
            model=LLM_MODEL,
            temperature=0.0,
            max_tokens=40,
            messages=[
                {"role": "system", "content": "Be concise and do not hallucinate IPCs unless clearly applicable."},
                {"role": "user", "content": prompt},
            ],
        )
        raw = (resp.choices[0].message.content or "").strip()
        if not raw:
            return None
        first_line = raw.splitlines()[0].strip()
        if re.match(r"(?i)not applicable", first_line):
            return None
        if re.search(r"\bIPC\b", first_line, flags=re.IGNORECASE) or re.search(r"\bsection\s*\d{2,4}\b", first_line, flags=re.IGNORECASE):
            cleaned = re.sub(r"[\(\[\{](.*?)[\)\]\}]", r"\1", first_line).strip()
            return cleaned
        return None
    except Exception as e:
        logger.warning(f"LLM official label lookup failed: {e}")
        return None

def generate_summary_text(req: ComplaintRequest) -> Tuple[str, Dict[str, str]]:
    """
    Produce plain-text formatted summary WITHOUT Description_of_incident or Date/Time_of_incident.
    Complaint Type may include (official label — IPC) only if get_official_complaint_label returns it.
    """
    now = datetime.utcnow()
    language = resolve_language(getattr(req, "language", None))
    date_display = format_date_for_language(language, now)
    labels = SUMMARY_LABELS.get(language, SUMMARY_LABELS["en"])

    # Attempt to get official label with IPC
    official_label = None
    if HF_TOKEN:
        official_label = get_official_complaint_label(req.complaint_type, req.details)

    full_name = req.full_name.strip()
    address = req.address.strip()
    phone = req.phone.strip()
    complaint_type_value = req.complaint_type.strip()
    details_value = req.details.strip()

    if language == "te":
        full_name = translate_to_telugu(full_name)
        address = translate_to_telugu(address)
        complaint_type_value = translate_to_telugu(complaint_type_value)
        details_value = translate_to_telugu(details_value)

    if official_label:
        complaint_type_line = f"{complaint_type_value} ({official_label})"
    else:
        complaint_type_line = complaint_type_value

    localized_fields = {
        "full_name": full_name,
        "address": address,
        "phone": phone,
        "complaint_type": complaint_type_line,
        "details": details_value,
        "date_of_complaint": date_display,
    }

    lines = [
        labels["header"],
        f"{labels['full_name']}: {full_name}",
        f"{labels['address']}: {address}",
        f"{labels['phone']}: {phone}",
        f"{labels['complaint_type']}: {complaint_type_line}",
        f"{labels['details']}: {details_value}",
        f"{labels['date_of_complaint']}: {date_display}",
        ""  # trailing newline
    ]
    return "\n".join(lines), localized_fields

# --- New: amount extraction helper ---
def extract_amount_in_inr(text: str) -> Optional[int]:
    """
    Extract a rupee amount (approximate) from free text.
    Returns integer amount in rupees or None.
    Matches patterns like: ₹50,000  Rs. 5000  rupees 1000  5000
    """
    if not text:
        return None
    text = text.replace(",", "")
    # try explicit ₹ or Rs or rupees
    m = re.search(r"(?:₹|Rs\.?|INR|rupees?)\s*([0-9]+(?:\.[0-9]+)?)", text, flags=re.IGNORECASE)
    if m:
        try:
            return int(float(m.group(1)))
        except Exception:
            pass
    # fallback: find standalone large numbers (>=100)
    m2 = re.findall(r"\b([0-9]{3,9})\b", text)
    if m2:
        # return the largest candidate
        try:
            nums = [int(x) for x in m2]
            return max(nums)
        except Exception:
            return None
    return None

# === Improved classification rules ===
def _normalize_classification(text: str) -> str:
    raw = (text or "").strip()
    up = raw.upper()
    if re.search(r"\bNON[-\s]?COGNIZABLE\b", up):
        label = "NON-COGNIZABLE"
    elif re.search(r"\bCOGNIZABLE\b", up):
        label = "COGNIZABLE"
    else:
        return "NON-COGNIZABLE"
    m = re.search(r"\b(?:COGNIZABLE|NON[-\s]?COGNIZABLE)\b\s*[\-–:]?\s*(.*)$", raw, re.IGNORECASE)
    justification = (m.group(1).strip() if m and m.group(1) else "")
    if justification:
        justification = re.sub(r"\s+", " ", justification)
        justification = re.sub(r"[\(\[\{].*?[\)\]\}]", "", justification).strip()
        justification = justification.rstrip(" .")
        return f"{label} – {justification}."
    return label

def _build_classification_context(
    complaint_type: str,
    details: str,
    language: str,
    localized_fields: Dict[str, str],
) -> str:
    segments = [complaint_type or "", details or ""]
    if language == "te" and localized_fields:
        segments.append(localized_fields.get("complaint_type", ""))
        segments.append(localized_fields.get("details", ""))
    combined = " ".join(seg for seg in segments if seg).lower()
    hints = []
    for key, hint in CLASSIFICATION_HINTS.items():
        if key.lower() in combined:
            hints.append(hint)
    if hints:
        combined = f"{combined} {' '.join(hints)}"
    return combined


def classify_offence(
    formal_summary: str,
    *,
    complaint_type: str = "",
    details: str = "",
    classification_text: Optional[str] = None,
) -> str:
    """
    Enhanced rule-based classifier:
      - If non-cognizable keywords matched -> NON-COGNIZABLE
      - If the text mentions exam/classroom and amount < threshold (or no amount) -> NON-COGNIZABLE
      - If amount >= threshold (default 5000 INR) -> COGNIZABLE
      - If cognizable keywords matched -> COGNIZABLE
      - Otherwise -> NON-COGNIZABLE
    """
    if classification_text:
        text = classification_text.lower()
    else:
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

    # 1) explicit non-cognizable keywords
    if any(k in text for k in non_cognizable_keywords):
        logger.info("Rule-based classification → NON-COGNIZABLE (matched non-cognizable keywords)")
        return "NON-COGNIZABLE – Falls under defamation/minor dispute category; magistrate order required."

    # 2) extract amount if present
    amount = extract_amount_in_inr(details)
    AMOUNT_THRESHOLD = 5000  # INR threshold for considering higher-severity theft

    # 3) exam/classroom special-case handling
    exam_keywords = {"exam", "exam hall", "exam hall.", "examination", "classroom", "in the exam", "during exam", "test"}
    if any(k in text for k in exam_keywords):
        # if amount is present and >= threshold -> treat as cognizable
        if amount is not None and amount >= AMOUNT_THRESHOLD:
            logger.info(f"Exam-context theft with amount {amount} -> treating as COGNIZABLE (over threshold)")
            return f"COGNIZABLE – Reported theft amount ₹{amount} meets threshold for police action."
        # otherwise prefer non-cognizable for exam-bag incidents
        logger.info("Exam-context theft with no/low amount -> NON-COGNIZABLE")
        return "NON-COGNIZABLE – Reported as theft during an examination; details indicate minor/personal loss."

    # 4) amount-based decision outside exam context
    if amount is not None:
        if amount >= AMOUNT_THRESHOLD:
            logger.info(f"Detected amount ₹{amount} -> COGNIZABLE")
            return f"COGNIZABLE – Reported theft amount ₹{amount} permits police action."
        else:
            logger.info(f"Detected amount ₹{amount} below threshold -> prefer NON-COGNIZABLE")
            # fall through to other checks but prefer non-cognizable
            # continue to check cognizable keywords next

    # 5) cognizable keywords
    if any(k in text for k in cognizable_keywords):
        logger.info("Rule-based classification → COGNIZABLE (matched cognizable keywords)")
        return "COGNIZABLE – Offence permits police action without warrant."

    # 6) LLM fallback if available (keeps previous behavior)
    if HF_TOKEN:
        try:
            criteria = (
                "You are an expert in Indian criminal procedure. Decide ONLY from the provided fields. "
                "Do NOT assume missing facts, do NOT infer offences from examples in questions, and do NOT guess. "
                "If a specific offence is not explicitly present in the details, prefer NON-COGNIZABLE.\n\n"
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
            # safety: if model says theft but no theft mention -> downgrade
            if "theft" in result.lower() and "theft" not in text:
                logger.warning("Model suggested theft but details do not contain theft → overriding to NON-COGNIZABLE")
                return "NON-COGNIZABLE – No explicit cognizable offence mentioned in details."
            return result
        except Exception as e:
            logger.warning(f"LLM classification failed: {e} — falling back to NON-COGNIZABLE.")
            return "NON-COGNIZABLE – Could not determine; fallback classification."

    # default fallback
    return "NON-COGNIZABLE – Could not determine from provided fields."

@router.post(
    "/summarize",
    response_model=ComplaintResponse,
    status_code=status.HTTP_200_OK,
)
async def process_complaint(payload: ComplaintRequest):
    try:
        language = resolve_language(payload.language)
        conversation = build_conversation(payload)
        # produce the neat text summary requested by user (no description)
        formal_summary, localized_fields = generate_summary_text(payload)

        logger.info(f"Complaint input → type='{payload.complaint_type}', details='{payload.details}'")
        classification_context = _build_classification_context(
            payload.complaint_type,
            payload.details,
            language,
            localized_fields,
        )
        classification = classify_offence(
            formal_summary,
            complaint_type=payload.complaint_type,
            details=payload.details,
            classification_text=classification_context,
        )
        classification_for_logs = classification
        classification_display = classification
        if language == "te" and classification:
            classification_display = translate_to_telugu(classification)

        logger.info(f"Classification decided → {classification_display}")

        # Terminal-friendly log
        label_upper = ("" if classification_for_logs is None else str(classification_for_logs)).upper()
        if "COGNIZABLE" in label_upper and "NON-COGNIZABLE" not in label_upper:
            logger.success("Case Classification: COGNIZABLE")
        elif "NON-COGNIZABLE" in label_upper:
            logger.success("Case Classification: NON-COGNIZABLE")
        else:
            logger.warning("Case Classification: UNKNOWN (model output not recognized)")

        response = ComplaintResponse(
            formal_summary=formal_summary,
            classification=classification_display,
            original_classification=classification,  # Send the English version here
            raw_conversation=conversation,
            timestamp=get_timestamp(),
            localized_fields=localized_fields,
        )
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process complaint: {e}")