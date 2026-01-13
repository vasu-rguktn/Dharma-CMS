from fastapi import APIRouter, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from typing import Optional, Dict, Tuple

from datetime import datetime, timedelta

import os


import os
from dotenv import load_dotenv
import google.generativeai as genai
import re
from loguru import logger
import json
import sys

logger.remove()
logger.add(
    sys.stdout,
    level="INFO",
    enqueue=True,
    backtrace=False,
    diagnose=False,
)

router = APIRouter(prefix="/complaint", tags=["Police Complaint"])

# pradeep savara has made changes to the code

# === Env & Client ===

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    # Allow server start; LLM features will be skipped if missing
    logger.warning("GEMINI_API_KEY not found. LLM features will be disabled.")
    pass
else:
    genai.configure(api_key=GEMINI_API_KEY)

print("\n" + "="*50)
print("!!! TELUGU FIX LOADED: GEMINI 1.5 FLASH ACTIVE & NUCLEAR SANITIZATION !!!")
print("="*50 + "\n")

LLM_MODEL = "gemini-flash-latest"




# === Schemas ===

class ChatMessage(BaseModel):

    role: str # 'user' or 'assistant'

    content: str



class ChatStepRequest(BaseModel):

    """

    Payload for the dynamic chat step.

    Existing fields (Name, Address, etc.) provide context.

    chat_history contains the turn-by-turn after the initial description.

    """

    full_name: str

    address: str

    phone: str

    complaint_type: Optional[str] = ""


    initial_details: str

    language: str = "en"

    chat_history: list[ChatMessage] = []



# Forward declaration for recursive reference if needed, though here we can likely just use string forward ref or separate class.

# But for simplicity, we'll define ChatStepResponse AFTER ComplaintResponse or start with a basic one.

# Let's keep it simple: Define ComplaintResponse first, or use string forward ref? 

# Pydantic handles string forward refs.



class ChatStepResponse(BaseModel):

    """

    Response can either be:

    1. A new question to ask (status='question')

    2. A final summary/completion (status='done')

    """

    status: str # 'question' or 'done'

    message: Optional[str] = None # The question text (if status='question')

    final_response: Optional['ComplaintResponse'] = None # populated if status='done'



class ComplaintRequest(BaseModel):

    full_name: str = Field(..., min_length=1)

    address: Optional[str] = None

    phone: str = Field(..., min_length=10)

    complaint_type: Optional[str] = Field(default="General Complaint")

    details: Optional[str] = None

    incident_details: Optional[str] = None
    
    incident_address: Optional[str] = None

    language: Optional[str] = Field(default="en", description="ISO code such as en or te")



class ComplaintResponse(BaseModel):
    formal_summary: str
    classification: str
    original_classification: str  # New field
    raw_conversation: str
    timestamp: str
    localized_fields: Dict[str, str] = Field(default_factory=dict)
    incident_details: Optional[str] = None
    incident_address: Optional[str] = None
    
    # New top-level fields for user convenience
    full_name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    initial_details: Optional[str] = None



# === Helpers ===

def resolve_language(lang: Optional[str]) -> str:

    if not lang:

        return "en"

    code = lang.lower()

    if code.startswith("te"):

        return "te"

    return "en"

def safe_utf8(text: Optional[str]) -> Optional[str]:
    if text is None:
        return None
    if not isinstance(text, str):
        return str(text)
    # 1. Encode with ignore to convert to bytes, dropping invalid chars
    # 2. Decode back to string
    clean_text = text.encode("utf-8", "ignore").decode("utf-8")
    # 3. Explicitly remove the Replacement Character if it somehow survived or was in source
    # 3. Explicitly remove the Replacement Character and Null bytes
    clean_text = clean_text.replace("\ufffd", "").replace("\x00", "")
    
    # 4. Nuclear Option: Remove anything that is NOT a valid printable character
    # Keep Telugu (\u0C00-\u0C7F), ASCII printable, and common symbols.
    # Strip everything else including invisible control chars.
    return re.sub(r'[^\u0C00-\u0C7F\x20-\x7E\n]', '', clean_text)




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

    if not GEMINI_API_KEY or not _needs_translation(text):
        return text

    try:
        model = genai.GenerativeModel(LLM_MODEL)
        
        prompt = (
            "You will receive text entered by a Telugu speaker.\n"
            "Sometimes it is English sentences needing translation, other times it is Telugu words typed using English letters "
            "(romanized Telugu such as 'ela unnaru' or 'meeru ekkada unnaru').\n"
            "Convert the input into natural Telugu script suitable for official police documentation.\n"
            "If the input is romanized Telugu, transliterate it faithfully.\n"
            "If the input is English, translate it into Telugu.\n"
            "Preserve personal names, places, and numbers exactly as provided.\n"
            "Return only the final Telugu text without quotes or commentary.\n\n"
            f"Input Text: {text}"
        )

        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0.2,
                max_output_tokens=2048,
            )
        )

        translated = (response.text or "").strip()
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

    if not GEMINI_API_KEY:
        return None

    try:
        model = genai.GenerativeModel(LLM_MODEL)

        prompt = (
            "You are an expert in Indian criminal law. From the fields below, provide a concise official offence"
            " name and IPC section(s) if clearly applicable. Output exactly one short line like:\n"
            "Theft — IPC 378\nAttempted murder — IPC 307\nNot applicable\n\n"
            f"Complaint Type: {complaint_type}\n"
            f"Details: {details}\n\n"
            "If unsure or not applicable, reply with 'Not applicable'. DO NOT invent IPC numbers.\n"
            "Be concise and do not hallucinate IPCs unless clearly applicable."
        )

        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0.0,
                max_output_tokens=2048,
            )
        )

        raw = (response.text or "").strip()

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

    if GEMINI_API_KEY:

        official_label = get_official_complaint_label(req.complaint_type, req.details)



    full_name = req.full_name.strip()
    address = req.address.strip()
    phone = req.phone.strip()
    
    # "Incident Details" -> Short summary (1-2 lines, location/time)
    # Using 'short_incident_summary' from request if available, falling back to details
    incident_short = getattr(req, 'incident_address', None) or req.details.strip() 
    
    # "Details" -> Full detailed narrative
    narrative_full = req.incident_details.strip() if req.incident_details else incident_short

    if language == "te":
        full_name = translate_to_telugu(full_name)
        address = translate_to_telugu(address)
        incident_short = translate_to_telugu(incident_short)
        narrative_full = translate_to_telugu(narrative_full)
        # Translate the base complaint type (e.g. "Theft") to Telugu
        # But KEEP the official label (e.g. IPC 378) in English/Official format
        cleaned_type = req.complaint_type.strip()
        translated_type = translate_to_telugu(cleaned_type)
        if official_label:
            complaint_type_line = f"{translated_type} ({official_label})"
        else:
            complaint_type_line = translated_type
    else:
        complaint_type_line = req.complaint_type.strip()
        if official_label:
            complaint_type_line = f"{complaint_type_line} ({official_label})"

    localized_fields = {
        "full_name": full_name,
        "address": address,
        "phone": phone,
        "complaint_type": complaint_type_line,
        "incident_details": narrative_full, # Map FULL narrative to 'incident_details' (for Grounds/Reasons in Petition)
        "details": narrative_full,          # Backup
        "incident_address": incident_short, # Map SHORT summary to 'incident_address' (for Incident Details/Address in Petition)
        "date_of_complaint": date_display,
    }

    # Strict Format:
    # Full Name: ...
    # Address: ...
    # Phone Number: ...
    # Incident Details: ... (1-2 lines)
    # Details: ... (Full Clarity)
    
    lines = [
        "FORMAL COMPLAINT SUMMARY",
        f"Full Name: {full_name}",
        f"Address: {address}",
        f"Phone Number: {phone}",
        f"Complaint Type: {complaint_type_line}",
        f"Incident Details: {incident_short}", # Short info
        f"Details: {narrative_full}",         # Full narrative
        f"Date of Complaint: {date_display}",
        ""
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



# === User Validation Helpers ===

def validate_name(name: str) -> bool:
    name = name.strip()
    # Allow Telugu characters (\u0C00-\u0C7F), standard ASCII letters, spaces, dots.
    if not re.fullmatch(r"[A-Za-z\u0C00-\u0C7F\s\.]+", name):
        return False
    # Relax logic: Sometimes people enter just first name. Minimum length 3 is good.
    if len(name) < 3:
        return False
    return True



def validate_address(address: str) -> bool:
    address = address.strip()

    # Minimum length
    if len(address) < 5:
        return False

    # Placeholder detection
    if any(p in address.lower() for p in ["unknown", "not provided", "n/a", "later", "don't know", "no address", "none"]):
        return False

    # Allowed characters: letters (English + Telugu), digits, space, comma, hyphen, slash, dots, parens
    # Remove Strict ASCII check
    # if not re.search(r"[A-Za-z]", address): -> REMOVED (allows pure Telugu)
    
    # Check for invalid characters? Or just permissive allowlist.
    # Allow: A-Z, a-z, 0-9, Telugu range, space, punctuation
    if not re.fullmatch(r"[A-Za-z0-9\u0C00-\u0C7F\s,\-\/\.\(\)]+", address):
        return False

    # Prevent addresses that are mostly numbers (still useful, but careful with PIN codes)
    # Count letters (English or Telugu)
    letters_count = len(re.findall(r"[A-Za-z\u0C00-\u0C7F]", address))
    digits_count = len(re.findall(r"[0-9]", address))
    
    # Relax digit check: Some addresses might be "H.No 1-2-3, Sector 5..."
    if digits_count > letters_count * 5: # relaxed from 3 to 5
        return False

    # Optional PIN code check (if present)
    pin_match = re.search(r"\b\d{6}\b", address)
    if pin_match:
        pin = pin_match.group()
        if len(set(pin)) == 1:  # 000000, 111111 etc.
            return False
    
    return True

    return True


def extract_identity_from_text(text: str):
    name = None
    phone = None
    address = None

    # Explicit self-identification only
    name_match = re.search(
        r"(my name is|i am|this is)\s+([A-Za-z]+ [A-Za-z]+)",
        text,
        re.I
    )
    if name_match:
        name = name_match.group(2).strip()

    # Indian phone
    phone_match = re.search(r"\b[6-9]\d{9}\b", text)
    if phone_match:
        phone = phone_match.group()

    # Residential address indicators ONLY
    address_match = re.search(
        r"(from|residing at|resident of)\s+([A-Za-z ,\-]+)",
        text,
        re.I
    )
    if address_match:
        address = address_match.group(2).strip()

    return {
        "full_name": name,
        "phone": phone,
        "address": address
    }



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
    # Prioritize the full investigation narrative if available
    full_narrative = localized_fields.get("incident_details", details) if localized_fields else details
    
    segments = [complaint_type or "", full_narrative or ""]

    if language == "te" and localized_fields:
        segments.append(localized_fields.get("complaint_type", ""))
        # Also include translated full narrative if available
        segments.append(localized_fields.get("incident_details", localized_fields.get("details", "")))

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
        "acid attack", "arson", "attempt to murder", "grievous hurt", "missing", 
        "missing person", "abduction", "wrongful confinement", "fraud", "cheating",
        "cyber crime", "dowry", "domestic violence"
    }



    non_cognizable_keywords = {

        "defamation", "false information", "rumor", "rumour", "slander", "libel",

        "verbal abuse", "abuse", "insult", "minor dispute", "argument", "domestic argument",

        "neighbour dispute", "neighbor dispute"

    }



    # 1) explicit non-cognizable keywords
    if any(k in text for k in non_cognizable_keywords):
        logger.info("Rule-based classification -> NON-COGNIZABLE (matched non-cognizable keywords)")
        return "NON-COGNIZABLE - Offence permits magistrate order."

    # 2) extract amount if present
    amount = extract_amount_in_inr(details)
    AMOUNT_THRESHOLD = 5000  # INR threshold for considering higher-severity theft

    # 3) exam/classroom special-case handling
    exam_keywords = {"exam", "exam hall", "exam hall.", "examination", "classroom", "in the exam", "during exam", "test"}
    if any(k in text for k in exam_keywords):
        # if amount is present and >= threshold -> treat as cognizable
        if amount is not None and amount >= AMOUNT_THRESHOLD:
            logger.info(f"Exam-context theft with amount {amount} -> treating as COGNIZABLE (over threshold)")
            return "COGNIZABLE - Offence permits police action."

        # otherwise prefer non-cognizable for exam-bag incidents
        logger.info("Exam-context theft with no/low amount -> NON-COGNIZABLE")
        return "NON-COGNIZABLE - Offence permits magistrate order."

    # 4) amount-based decision outside exam context
    if amount is not None:
        if amount >= AMOUNT_THRESHOLD:
            logger.info(f"Detected amount {amount} -> COGNIZABLE")
            return "COGNIZABLE - Offence permits police action."
        else:
            logger.info(f"Detected amount {amount} below threshold -> prefer NON-COGNIZABLE")
            # fall through to other checks but prefer non-cognizable
            # continue to check cognizable keywords next

    # 5) cognizable keywords
    if any(k in text for k in cognizable_keywords):
        logger.info("Rule-based classification -> COGNIZABLE (matched cognizable keywords)")
        return "COGNIZABLE - Offence permits police action."



    # 6) LLM fallback if available (keeps previous behavior)


    # 6) LLM fallback if available (keeps previous behavior)

    if GEMINI_API_KEY:

        try:
            model = genai.GenerativeModel(LLM_MODEL)

            criteria = (
                "You are an expert in Indian criminal procedure. Decide ONLY from the provided fields. "
                "Do NOT assume missing facts, do NOT infer offences from examples in questions, and do NOT guess. "
                "If the complaint involves 'Missing Person', 'Theft', 'Violence', 'Fraud', 'Cheating', or 'Cyber Crime', classify as COGNIZABLE.\n"
                "If a specific offence is not explicitly present in the details, prefer NON-COGNIZABLE.\n\n"
                "Output format (exactly one line):\n"
                "COGNIZABLE  OR  NON-COGNIZABLE."
            )

            user_payload = (
                f"{criteria}\n\n"
                "Decide for this complaint using ONLY the following fields.\n\n"
                f"Complaint Type: {complaint_type}\n"
                f"Details: {details}"
            )

            response = model.generate_content(
                user_payload,
                generation_config=genai.types.GenerationConfig(
                    temperature=0.0,
                    max_output_tokens=2048,
                )
            )

            raw = (response.text or "").strip()

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
            raw_conversation=f"Complaint filed via form.\nDetails: {payload.details}", # Simple string
            timestamp=get_timestamp(),
            localized_fields=localized_fields,
            full_name=payload.full_name,
            address=payload.address,
            phone=payload.phone,
            initial_details=payload.details # In form flow, details is initial
        )

        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process complaint: {e}")

def validate_imei(text: str) -> bool:
    # 15 digits exactly
    match = re.search(r"\b\d{15}\b", text)
    if not match: return False
    return True

def validate_vehicle_number(text: str) -> bool:
    # Broad Indian vehicle regex: e.g. TS09AB1234
    # Pattern: State(2)-Num(1-2)-[OptionalChars]-Num(4)
    # Flexible: allow spaces/hyphens
    pattern = r"\b[A-Za-z]{2}[-\s]?[0-9]{1,2}[-\s]?[A-Za-z]{0,3}[-\s]?[0-9]{4}\b"
    return bool(re.search(pattern, text, re.IGNORECASE))

# Strict Indian Phone Validation
def validate_phone(phone: str) -> bool:
    if not phone: return False
    # cleaning
    phone = re.sub(r"[^0-9]", "", phone)
    # Check length
    if len(phone) != 10:
        return False
    # Check first digit (Indian Mobiles start with 6,7,8,9)
    if phone[0] not in "6789":
        return False
    # Check for dummy numbers (all same digits)
    if len(set(phone)) == 1:
        return False
    return True

# --- CONSTANTS FOR IDENTITY QUESTIONS ---
SYS_MSG_NAME_EN = "What is your full name?"
SYS_MSG_NAME_TE = "మీ పూర్తి పేరు ఏమిటి?"
SYS_MSG_ADDRESS_EN = "Where do you live (place / area)?"
SYS_MSG_ADDRESS_TE = "మీరు ఎక్కడ ఉంటున్నారు (ప్రాంతం / ఊరు)?"
SYS_MSG_PHONE_EN = "Please enter your valid mobile number (10 digits):"
SYS_MSG_PHONE_TE = "దయచేసి మీ 10 అంకెల ఫోన్ నంబర్‌ను టైప్ చేయండి:"

def recover_identity_from_history(history: list) -> dict:
    """
    Scans history to find valid answers to identity questions.
    Returns a dict with found fields.
    """
    found = {"full_name": None, "address": None, "phone": None}
    
    for i in range(len(history) - 1):
        msg = history[i]
        next_msg = history[i+1]
        
        if msg.role == "assistant" and next_msg.role == "user":
             content = msg.content.strip() # Exact matching requires stripping
             user_ans = next_msg.content.strip()
             
             # Name - Check against constants (English & Telugu)
             if content in [SYS_MSG_NAME_EN, SYS_MSG_NAME_TE] or "full name" in content.lower():
                 if validate_name(user_ans):
                     found["full_name"] = user_ans
             
             # Address - Check against constants (English & Telugu)
             elif content in [SYS_MSG_ADDRESS_EN, SYS_MSG_ADDRESS_TE] or "where do you live" in content.lower():
                 if validate_address(user_ans):
                     found["address"] = user_ans
             
             # Phone - Check against constants (English & Telugu)
             elif content in [SYS_MSG_PHONE_EN, SYS_MSG_PHONE_TE] or "mobile number" in content.lower():
                 if validate_phone(user_ans):
                     found["phone"] = user_ans
                     
    return found

@router.post(
    "/chat-step",
    response_model=ChatStepResponse,
    status_code=status.HTTP_200_OK,
)
async def chat_step(payload: ChatStepRequest):
    """
    Dynamic chat turn.
    Decides whether to ask another question or finalize the complaint.
    """
    try:
        logger.info(f"Chat Step Request: {payload}")

        # 1. Resolve Language
        language = resolve_language(payload.language)

        # --- STATE RECOVERY START ---
        # Recover identity fields from history to fix "Not Provided" bug
        # RE-ENABLED: This fixes the infinite loop by collecting answers from previous turns.
        recovered = recover_identity_from_history(payload.chat_history)
        if not payload.full_name and recovered["full_name"]:
             payload.full_name = recovered["full_name"]
             logger.info(f"Recovered Name: {payload.full_name}")
        
        # Phone validation included
        if (not payload.phone or not validate_phone(payload.phone)) and recovered["phone"]:
             if validate_phone(recovered["phone"]):
                 payload.phone = recovered["phone"]
                 logger.info(f"Recovered Phone: {payload.phone}")

        if not payload.address and recovered["address"]:
             payload.address = recovered["address"]
             logger.info(f"Recovered Address: {payload.address}")
        # --- STATE RECOVERY END ---

        extracted = {"full_name": None, "address": None, "phone": None}
        payload_phone_valid = payload.phone and validate_phone(payload.phone)
        
        # 1. If we have some identity in payload, great.
        
        # 2. Extract from initial details logic
        # DISABLED PER USER REQUEST (Force Ask even if provided initially)
        # if not payload.full_name or not payload_phone_valid or not payload.address:
        #     # We can try to extract from initial_details
        #     extracted = extract_identity_from_text(payload.initial_details)
        #     if not payload.full_name and extracted["full_name"]:
        #         payload.full_name = extracted["full_name"]
        #     if not payload.phone and not payload_phone_valid and extracted["phone"]:
        #          if validate_phone(extracted["phone"]):
        #             payload.phone = extracted["phone"]
        #     if not payload.address and extracted["address"]:
        #         payload.address = extracted["address"]


        
        # --- IDENTITY INTERCEPTION START ---
        skip_llm = False
        
        if payload.chat_history:
             last_assistant_msg = None
             last_user_msg = None
             # Actually better to take exactly the last message if user
             if payload.chat_history[-1].role == "user":
                 last_user_msg = payload.chat_history[-1].content
             
             # Check for User forcing DONE
             if last_user_msg and re.search(r"\b(done|completed|finished|that's it|no more)\b", last_user_msg, re.IGNORECASE):
                 skip_llm = True
                 logger.info("User forced DONE.")
             
             # Find last assistant message
             for m in reversed(payload.chat_history):
                 if m.role == "assistant":
                     last_assistant_msg = m.content
                     break
                 
             if last_assistant_msg and last_user_msg and not skip_llm:
                 la_lower = last_assistant_msg.lower()
                 logger.info(f"Checking Interception. Last Asst: '{last_assistant_msg}'") 

                 captured_any = False
                 
                 # 1. PHONE CHECK
                 # 1. PHONE CHECK
                 # STRICT keywords only. Do NOT use "phone" or "contact" alone.
                 phone_keywords = ["phone number", "mobile number", "contact number", "your number", "call you", "ఫోన్ నంబర్", "మొబైల్ నంబర్", "contact info", "10-digit"]
                 matched_phone = any(k in la_lower for k in phone_keywords)
                 phone_error_msg = None
                 
                 if matched_phone:
                     if validate_phone(last_user_msg):
                         logger.info(f"Intercepted VALID phone: {last_user_msg}")
                         payload.phone = last_user_msg 
                         captured_any = True
                     else:
                         phone_error_msg = "Invalid number. Please enter a valid 10-digit mobile number (starts with 6-9):"
                         if language == "te":
                             phone_error_msg = "నెంబర్ సరిగ్గా లేదు. దయచేసి సరైన 10 అంకెల మొబైల్ నంబర్‌ను ఇవ్వండి:"

                 # 2. NAME CHECK
                 # 2. NAME CHECK
                 name_keywords = ["full name", "your name", "complete name", "పూర్తి పేరు", "మీ పేరు"]
                 matched_name = any(k in la_lower for k in name_keywords)
                 name_error_msg = None
                 
                 if matched_name:
                     if validate_name(last_user_msg):
                         logger.info(f"Intercepted VALID name: {last_user_msg}")
                         payload.full_name = last_user_msg
                         captured_any = True
                     else:
                         name_error_msg = "Please provide your valid full name (at least 3 letters):"
                         if language == "te":
                             name_error_msg = "దయచేసి మీ సరైన పూర్తి పేరు చెప్పండి:"

                 # 3. ADDRESS CHECK
                 address_keywords = ["where do you live", "place / area", "residential address", "ఎక్కడ ఉంటున్నారు", "నివాస స్థలం"]
                 matched_address = any(k in la_lower for k in address_keywords)
                 address_error_msg = None
                 
                 if matched_address:
                     if validate_address(last_user_msg):
                          logger.info(f"Intercepted VALID address: {last_user_msg}")
                          payload.address = last_user_msg
                          captured_any = True
                     else:
                          address_error_msg = "Please provide a valid residential address (Place, Mandal, District):"
                          if language == "te":
                              address_error_msg = "దయచేసి సరైన నివాస చిరునామా ఇవ్వండి (ఊరు, మండలం, జిల్లా):"
                
                 # DECISION LOGIC
                 if captured_any:
                     skip_llm = True
                 elif phone_error_msg: # Prioritize Phone error if nothing else captured
                     return ChatStepResponse(status="question", message=phone_error_msg)
                 elif name_error_msg:
                     return ChatStepResponse(status="question", message=name_error_msg)
                 elif address_error_msg:
                     return ChatStepResponse(status="question", message=address_error_msg)

        # --- IDENTITY INTERCEPTION END ---
        
        reply = ""
        is_done = False

        if not skip_llm:
            # 3. Build Context for LLM
            # Use the "STRICT RULES" prompt from user
            display_lang = "Telugu" if language == "te" else "English"



            # SYSTEM_PROMPT_EN = """
            #     You are an expert Police Officer conducting an investigation in English.

            #     GOAL: Ask relevant questions to understand the crime (Who, What, Where, When, How).

            #     RULES:
            #     1. Ask short, direct questions.
            #     2. Ask ONE question at a time.
            #     3. NEVER repeat facts already mentioned.
            #     4. NEVER mix languages.
            #     5. Ask only case-related mandatory questions.
            #     6. Do NOT ask name, phone, or address.
            #     7. End questions with '?'.

            #     EXAMPLES:
            #     - Where did the incident happen?
            #     - When did it occur?
            #     - What item was stolen?
            #     - Did you notice any suspect?
            #     """

            # SYSTEM_PROMPT_TE = """
            #     మీరు పోలీస్ అధికారి. మీరు విచారణ చేస్తున్నారు.

            #     నియమాలు:
            #     1. ఒక్క ప్రశ్న మాత్రమే అడగాలి.
            #     2. ఇప్పటికే చెప్పిన విషయాలు మళ్ళీ అడగకూడదు.
            #     3. తెలుగు మాత్రమే ఉపయోగించాలి.
            #     4. పేరు, చిరునామా, ఫోన్ అడగకూడదు.
            #     5. ఘటనకు సంబంధించిన ప్రశ్నలే అడగాలి.

            #     ఉదాహరణలు:
            #     - ఘటన ఎక్కడ జరిగింది?
            #     - ఇది ఎప్పుడు జరిగింది?
            #     - ఏ వస్తువు దొంగిలించబడింది?
            #     - ఎవరికైనా అనుమానం కలిగిందా?
            #     """

            # system_prompt = SYSTEM_PROMPT_TE if language == "te" else SYSTEM_PROMPT_EN

            system_prompt = (
                f"You are an expert Police Officer conducting an investigation in {display_lang}.\n\n"

                "GOAL: Ask relevant questions to understand the crime (Who, What, Where, When, How).\n"
                "RULES:\n"
                "NOTE : - NEVER assume the incident occurred at the complainant's residential address.\n"
                "1. NEVER repeat facts the user already said. (If user said 'Stolen at market', DO NOT ask 'Where was it stolen?').\n"
                "2. ASK SHORT, DIRECT QUESTIONS. One at a time.\n"
                "3. START DIRECTLY. Do not say 'Okay', 'I understand', 'Good'. Just ask.\n"
                "4. GRAMMAR: Ensure the sentence is complete and ends with '?'.\n"
                "5. Ask only the case related question, donot ask the unnecessary questions\n"
                "6. Ask the madatory questions like : for mobile theft: IMEI / model of the phone, for vehicle theft: model/ registration number,for missing: missing person details like age, name. like that need to ask the mandatory questions for the differt cases , i just provided the example ones, as you know for what type of cases what need to be asked. \n"
                "7. Donot ask the repeated questions if they already answered.\n"
                "8. NEVER ask the user 'What action should we take?' or 'How should we find it?'. YOU are the police. YOU investigate.\n"
                "9. NEVER ask 'Were you there?' (It is offensive to victims). Assume they know the facts.\n"
                "10. Focus ONLY on the present case. Ignore details from previous unrelated cases if any exist in history.\n"
                "LANGUAGE INSTRUCTIONS:\n"
                f"1. You MUST respond in: {language} only.\n"
                "2. IF user selected 'en' (English): Speak ONLY English. Do NOT use Telugu text or script. Do not use 'Namaskaram'.\n"
                "3. IF user selected 'te' (Telugu): Speak ONLY Telugu. Use formal 'Meeru/Tamaru'. Refer to user's items as 'Mee' (Your - e.g. 'Mee chain'), NEVER 'Naa' (My).\n"
                "4. Do NOT mix languages if also the user did.\n"
                "5. PERSPECTIVE: You are the Police Officer. The User is the Victim. Ask 'Where was YOUR bike stolen?', never 'Where was MY bike stolen?'.\n"
                "6. Especially in telugu, NEVER repeat facts the user already said"
                "- USE STANDARD QUESTIONS (Below):\n\n"

                "GOLDEN EXAMPLES (Polite & Standard):\n"
                "1. Location: 'ఘటన ఎక్కడ జరిగింది?' (Where did it happen?)\n"
                "2. Time: 'ఇది ఎప్పుడు జరిగింది?' (When did it happen?)\n"
                "3. Suspect: 'ఎవరైనా అనుమానంగా కనిపించారా?' (Did anyone look suspicious?)\n"
                "4. Details: 'బైక్ నంబర్ ఏంటి?' (What is the bike number?)\n"
                "5. Description: 'దాని రంగు లేదా గుర్తు ఏమిటి?' (What color or mark?)\n\n"

                "BAD EXAMPLES (Avoid these) in their choosen languages:\n"
                "❌ 'మీరు చెప్పిన సమాచారం ప్రకారం...' (Do not summarize)\n"
                "❌ 'నేను ఒక ప్రశ్న అడుగుతాను...' (Do not announce)\n"
                "❌ 'నేను గమనించాను...' (I noted... - DO NOT SAY THIS)\n"
                "❌ 'మీరు చెప్పారు కదా...' (As you said... - DO NOT SAY THIS)\n"
                "❌ 'దయచేసి చెప్పండి...' (Too formal/begging) -> Use 'Cheppandi' (Tell me)\n"
                "❌ 'May I know...' -> Use 'What is...'\n"
                "❌ 'వాటిని ఎలా కనుగొనాలి?' (How to find it? - NEVER ASK THIS)\n"
                "❌ 'మీరు అక్కడ ఉన్నారా?' (Were you there? - NEVER ASK THIS)\n"
                "❌ Do NOT sound robotic or rude. But be authoritative.\n"
                "❌ Do NOT ask 'Where did you park?' for small items (phones/wallets/Laptops, etc). Ask 'Where did you keep it?'. 'Park' is ONLY for vehicles.\n\n"

                "CRITICAL INSTRUCTIONS:\n"
                "- NO PREAMBLE. NO CONFIRMATION. JUST ASK.\n"
                "- Do NOT say 'We have noted your details'.\n"
                "- Do NOT say 'Okay, I understand'.\n"
                "- Do NOT say 'Based on what you said...'.\n"
                "- ASK MAX 5-7 QUESTIONS. if you think the information is not sufficient ask the questions in sweeet and short.\n"
                "- IF USER PROVIDES Name/Address/Phone: OUTPUT 'DONE' IMMEDIATELY.\n"
                "- If you have Incident, Time, Place, and Item: OUTPUT 'DONE'.\n"
                "- Do NOT loop asking for 'more details'.\n"
                "- Do NOT ask for 'Phone Number' inside the chat unless user offers it. The App handles it.\n"
                "- Donot ask the repeated questions if they already answered.\n"
                "-Ask the madatory questions like : for mobile theft: IMEI / model of the phone, for vehicle theft: model/ registration number,for missing: missing person details like age, name. like that need to ask the mandatory questions for the differt cases , i just provided the example ones, as you know for what type of cases what need to be asked. \n"
                "- Donot ask the repeated questions if they already answered.\n"
                "- Donot aks unnecessary questions especially in telugu conversation."
                "- Do NOT ask for Name, Address, or Phone Number during the investigation. Focus ONLY on the incident details. We will ask them later.\n"
                "- TELUGU SPECIFIC: Use direct phrasing like 'చెప్పండి' (Tell me) instead of 'దయచేసి' (Please). Do not use 'May I know'. Just ask the question directly.\n"


                "STRICT RULES:\n"
                "1. CHECK HISTORY FIRST: If the user has already mentioned a detail (Date, Time, Location, Vehicle Number, Phone), DO NOT ASK AGAIN.\n"
                "2. ONE QUESTION ONLY: Ask exactly one question per turn.\n"
                "3. NO REPETITION: If the user says 'I already told you', apologize and move to the next topic.\n"
                "4. LANGUAGE: Speak in {language_name}. For Telugu, use direct, natural phrasing (e.g., 'మీ పేరు ఏమిటి?') and avoid excessive politeness or English transliteration.\n"
                "5. TERMINATION: If you have the Who, What, When, Where, and How, output 'DONE'.\n"
                "6. FOCUS: Do not ask for Name/Address/Phone yet. Focus on the incident details first.\n"
            )
            
            # Convert Pydantic chat history to LLM format
            messages = [{"role": "system", "content": system_prompt}]
            # Prepend initial details as context from user
            messages.append({"role": "user", "content": payload.initial_details})
            
            # Limit history to last 12 turns to prevent context overflow (Llama-3-8B has 8k limit)
            recent_history = payload.chat_history[-12:] if len(payload.chat_history) > 12 else payload.chat_history
            
            for msg in recent_history:
                messages.append({"role": msg.role, "content": msg.content})
                
            # 4. Call LLM
            if not GEMINI_API_KEY:
                 return ChatStepResponse(status="done", final_response=None)

            if len(payload.chat_history) > 25:
                 logger.info("Chat history too long, forcing DONE.")
                 reply = "DONE"
            else:
                try:
                    # Construct full History for Gemini
                    model = genai.GenerativeModel(LLM_MODEL)
                    
                    # Instead of list of dicts, Gemini often prefers a single text block or specific Content object structure.
                    # For simplicity/robustness in Migration, we can flatten to a script or use the chat session.
                    
                    full_prompt = f"{system_prompt}\n\nINITIAL CONTEXT:\n{payload.initial_details}\n\nCONVERSATION HISTORY:\n"
                    
                    # Limit history (Gemini Flash has ~1M context so we could send all, but 12 turns is safe for focus)
                    recent_history = payload.chat_history[-12:] if len(payload.chat_history) > 12 else payload.chat_history
                    
                    for msg in recent_history:
                        role = "Police" if msg.role == "assistant" else "User" # or "Model" / "User"
                        full_prompt += f"{role}: {msg.content}\n"
                    
                    full_prompt += "\nPolice (You):"

                    response = model.generate_content(
                        full_prompt,
                        generation_config=genai.types.GenerationConfig(
                            temperature=0.3,
                            max_output_tokens=2048,
                        )
                    )
                    
                    raw_content = response.text or ""
                    reply = raw_content.strip()
                    decision_upper = reply.upper().replace('"', '').replace("'", "")

                    if "DONE" in decision_upper and len(decision_upper) < 10:
                        is_done = True
                        reply = "DONE"
                    
                    # Sanitize and Log
                    reply = safe_utf8(reply)

                    # FIX-3: HARD STOP TELUGU OUTPUT WHEN ENGLISH IS SELECTED
                    if language == "en":
                        # Remove any accidental Telugu characters from LLM output
                        reply = re.sub(r"[\u0C00-\u0C7F]+", "", reply).strip()

                    
                    # Fail-Safe: If sanitization stripped everything, use fallback
                    if not reply or len(reply.strip()) < 2:
                         logger.warning("Sanitized reply was empty or too short. Using fallback.")
                         reply = "మరిన్ని వివరాలు చెప్పండి." if language == "te" else "Please provide more details."

                    # logger.info(f"LLM Reply Hex: {reply.encode('utf-8').hex()}")
                    logger.info(f"LLM Reply: {reply}")

                except Exception as e:
                    logger.error(f"Gemini Chat Generation Error: {e}")
                    reply = "Could you please provide more details?"


            if not reply:
                reply = "Could you please provide more details?"

            # SAFETY NET: Check if LLM leaked validation error
            if re.search(r"(invalid|valid)\s+(number|phone)", reply, re.IGNORECASE) and not re.search(r"\bDONE\b", reply, re.IGNORECASE):
                 logger.warning("LLM leaked validation error. Intercepting and sending System Error.")
                 msg = "Invalid number. Please enter a valid 10-digit mobile number (starts with 6-9):"
                 if language == "te":
                     msg = "నెంబర్ సరిగ్గా లేదు. దయచేసి సరైన 10 అంకెల మొబైల్ నంబర్‌ను ఇవ్వండి:"
                 return ChatStepResponse(status="question", message=msg)
            
            # 5. Check for "DONE" token anywhere in the reply
            # Updated to include Telugu "completed" synonyms
            if re.search(r"\bDONE\b|పూర్తయింది|completed", reply, re.IGNORECASE):
                logger.info("LLM indicated DONE (or Telugu equivalent). Forcing Gatekeeping.")
                is_done = True
                reply = ""  # WIPE REPLY to ensure user doesn't see "That's consistent... DONE"
        
        # Unified Logic: If skipped LLM (intercepted/user done) OR LLM said Done => Finalize
        if skip_llm or is_done:
            # --- FINAL IDENTITY CONFIRMATION (ALWAYS ASK) ---
            final_name_confirmed = payload.full_name and validate_name(payload.full_name)
            final_address_confirmed = payload.address and validate_address(payload.address)
            final_phone_confirmed = payload.phone and validate_phone(payload.phone)

            if not final_name_confirmed:
                msg = SYS_MSG_NAME_TE if language == "te" else SYS_MSG_NAME_EN
                return ChatStepResponse(status="question", message=msg)

            if not final_address_confirmed:
                msg = SYS_MSG_ADDRESS_TE if language == "te" else SYS_MSG_ADDRESS_EN
                return ChatStepResponse(status="question", message=msg)

            if not final_phone_confirmed:
                msg = SYS_MSG_PHONE_TE if language == "te" else SYS_MSG_PHONE_EN
                return ChatStepResponse(status="question", message=msg)

            
            # --- MANDATORY SEQUENTIAL QUESTIONS START ---
            # Only proceed to summary if we have ALL identity fields.
            # 1. Name
            # if not payload.full_name:
            #     logger.info("Investigation done, but Name missing. Asking Name.")
            #     msg = SYS_MSG_NAME_TE if language == "te" else SYS_MSG_NAME_EN
            #     return ChatStepResponse(status="question", message=msg)
                
            # # 2. Address
            # if not payload.address:
            #     logger.info("Investigation done, but Address missing. Asking Address.")
            #     msg = SYS_MSG_ADDRESS_TE if language == "te" else SYS_MSG_ADDRESS_EN
            #     return ChatStepResponse(status="question", message=msg)
                
            # # 3. Phone
            # # Ensure phone is valid too
            # if not payload.phone or not validate_phone(payload.phone):
            #     logger.info("Investigation done, but Phone missing/invalid. Asking Phone.")
            #     msg = SYS_MSG_PHONE_TE if language == "te" else SYS_MSG_PHONE_EN
            #     return ChatStepResponse(status="question", message=msg)
            # # --- MANDATORY SEQUENTIAL QUESTIONS END ---

            # Generate final summary using NEW prompt
            
            transcript = payload.initial_details + "\n"
            for msg in payload.chat_history:
                role_label = "User" if msg.role == "user" else "Officer"
                transcript += f"{role_label}: {msg.content}\n"
                
            summary_prompt = f"""
You are an expert police complaint writer.

You are a senior police officer recording an FIR.\n\n

- NEVER assume the incident occurred at the complainant's residential address.
- Use the residential address ONLY for identification (full_name/address/phone).
- Use an incident location ONLY if explicitly mentioned by the user (e.g. 'at the market', 'at parking').
- If the incident place is vague (e.g., "parking area"), keep it vague. Do NOT deduce it is the home address.
- If the incident place is not clearly mentioned, leave it empty/null.
- Extract name, phone, and address ONLY from the conversation.
- Do NOT ask any questions.


- NEVER invent or substitute locations.
- NEVER use placeholders.
IDENTITY RULES:\n
- Do NOT ask name, phone, or address initially.\n
- Assume they may already be present in the complaint.\n
- Ask for name/phone/address ONLY IF missing after investigation.\n\n
END RULE:\n
- When all incident + identity details are sufficient, reply ONLY with 'DONE'.

NOTE : 1.If the date or time not mentioned, in the summary donot say date not mentioned and time not mentioned. Insted of that donot say anything about them.
       2. if the date or time donot mentioned, donot assume the date or any place. just say nothing about them.
TASKS:
1. Identify the complaint type automatically.
2. Extract date, time, and place from the conversation if mentioned.
3. Describe  ONLY the incident location :where the incident happened in 1–2 lines, include the date&time if mentioned .
4. Write a clear narrative description of the incident in **FIRST PERSON PERSPECTIVE** (e.g., "I was walking...", "He beat me..."). 
   - DO NOT use "You said...", "The user said...", "Complainant stated...".
   - DO NOT summarize the chat structure ("We asked more questions..."). 
   - Write it as a Formal Petition/Complaint to the Police Station.
5. Do NOT invent dates, places, or items not explicitly mentioned by the user.
6. Extract name, address, number from the conversation.
7. Donot assume the incident location as the complainant's residential address untill they mentioned in the residential address.
8. In details field, need the detailed description/ summarization of the entire complaint incident.

OUTPUT FORMAT (STRICT JSON ONLY):
{{
    "full_name": "", 
    "address": "",
    "phone": "",
    "complaint_type": "",
    "initial_details": "",
    "details": "COMPREHENSIVE NARRATIVE in FIRST PERSON ('I...'). Must be a detailed formal complaint text suitable for an FIR. Include EVERY fact mentioned (Who, What, Where, When, How, Vehicle details, Suspects, etc). NOT a chat summary.",
  
    "short_incident_summary": "short 1-2 lines where it happend, Specific location and time. EXAMPLE: 'Nuzvid bus stand road on 2026-01-06 at 8 PM'. NOT 'The spot' or 'Incident location'. Extract specific place names."
}}

INFORMATION:
{transcript}
"""         
            # Adjust prompt for language if needed
            if language == 'te':
                 summary_prompt = summary_prompt.replace("in plain English", "in Telugu (translated)")
                 summary_prompt += ("\n\nIMPORTANT TELUGU RULES:\n"
                                    "- Write the 'details' narrative as a FORMAL PETITION to the Station House Officer.\n"
                                    "- Use FIRST PERSON ('Nenu...', 'Maaku...').\n"
                                    "- NEVER start with 'You said' ('Meeru chepparu') or 'The user said'.\n"
                                    "- NEVER mention 'We asked questions'.\n"
                                    "- Output must be continuous Telugu text describing the incident formally.\n"
                                    "- Output the JSON values in Telugu where appropriate (narrative), but keep keys in English.\n"
                                    "- Need description like full narrative of the complaint not like just description.")

            try:
                model = genai.GenerativeModel(LLM_MODEL)
                
                response = model.generate_content(
                    summary_prompt,
                    generation_config=genai.types.GenerationConfig(
                        temperature=0.2,
                        max_output_tokens=2048,
                        response_mime_type="application/json", # Use Gemini's native JSON mode
                    )
                )
                
                final_json_str = response.text.strip()
            except Exception as e:
                logger.error(f"Gemini Summary Generation Error: {e}")
                final_json_str = "{}"
            final_json_str = safe_utf8(final_json_str)
            # logger.info(f"Summary JSON: {final_json_str}")
            logger.info("Summary JSON received (length=%d)", len(final_json_str))
            
            # Parse JSON
            try:
                n_data = json.loads(final_json_str)
            except:
                logger.error("Failed to parse summary JSON")
                n_data = {}

            # Map to ComplaintResponse
            # narrative = n_data.get("details", "")
            narrative = safe_utf8(n_data.get("details", ""))

            # final_complaint_type = n_data.get("complaint_type", payload.complaint_type)
            # if not final_complaint_type or not final_complaint_type.strip():
            #     final_complaint_type = "General Complaint"

            raw_llm_type = (n_data.get("complaint_type") or "").strip()
            if not raw_llm_type:
                final_complaint_type = "General Complaint"
            else:
                final_complaint_type = raw_llm_type
            final_complaint_type = final_complaint_type.strip().title()

            initial_details_summary = n_data.get("initial_details", "")
            # short_incident = n_data.get("short_incident_summary", "")
            short_incident = safe_utf8(n_data.get("short_incident_summary", ""))

            
            # Extract collected identity if missing in payload
            extracted_name = n_data.get("full_name")
            extracted_address = n_data.get("address")
            extracted_phone = n_data.get("phone")
            
            # --- STRICT GATEKEEPING & DEBUG LOGGING ---
            logger.info(f"Gatekeeper Payload Input: Name='{payload.full_name}', Addr='{payload.address}', Phone='{payload.phone}'")
            logger.info(f"Gatekeeper LLM Extracted: Name='{extracted_name}', Addr='{extracted_address}', Phone='{extracted_phone}'")

            # 1. NAME
            final_name = payload.full_name
            # extracted_name_valid = extracted_name and validate_name(extracted_name)
            
            if not final_name or not validate_name(final_name):
                # DISABLED FALLBACK
                msg = SYS_MSG_NAME_EN
                if language == "te":
                    msg = SYS_MSG_NAME_TE
                return ChatStepResponse(status="question", message=msg)
                
            # 2. ADDRESS
            final_address = payload.address
            # extracted_address_valid = extracted_address and validate_address(extracted_address)
            
            if not final_address or not validate_address(final_address):
                # DISABLED FALLBACK
                msg = SYS_MSG_ADDRESS_EN
                if language == "te":
                    msg = SYS_MSG_ADDRESS_TE
                return ChatStepResponse(status="question", message=msg)
                
            # 3. PHONE
            final_phone = payload.phone
            
            # ONLY use extracted phone if it is STRICTLY VALID.
            # DISABLED FALLBACK: FORCE ASK
            # if extracted_phone and validate_phone(extracted_phone):
            #      final_phone = extracted_phone
            #      logger.info("Using Extracted Phone")
            
            # FORCE CHECK: If final_phone is invalid (None or False), RETURN QUESTION
            if not final_phone or not validate_phone(final_phone):
                 logger.info("Phone missing or invalid. Asking user.")
                 msg = SYS_MSG_PHONE_EN
                 if language == "te":
                     msg = SYS_MSG_PHONE_TE
                 return ChatStepResponse(status="question", message=msg)

            # --- SANITIZATION & CRITICAL FIELD CHECK ---
            # Check for IMEI if "IMEI" keyword is mentioned
            full_text_search = (narrative + " " + initial_details_summary).lower()
            
            if "imei" in full_text_search:
                # Check if a valid 15-digit IMEI exists in the extracted/input text
                # We check the narrative for the number
                if not validate_imei(narrative) and not validate_imei(initial_details_summary) and not validate_imei(payload.initial_details):
                     msg = "I noticed you mentioned an IMEI number, but it doesn't look like a valid 15-digit number. Please check and provide the correct IMEI."
                     if language == "te":
                         msg = "మీరు IMEI నంబర్ చెప్పినట్లున్నారు, కానీ అది 15 అంకెలు లేనట్లుంది. దయచేసి సరైన IMEI నంబర్ ఇవ్వండి."
                     return ChatStepResponse(status="question", message=msg)

            # Check for Vehicle Number if context suggests vehicle theft
            vehicle_keywords = ["vehicle", "bike", "car", "scooter", "motorcycle", "registration number", "number plate", "license plate", "వాహనం", "బైక్", "కారు"]
            if any(k in full_text_search for k in vehicle_keywords) and ("theft" in full_text_search or "lost" in full_text_search or "దొంగ" in full_text_search):
                 # Look for pattern in EVERYTHING (Narrative + Initial + Last User Msg + History)
                 combined_reg_search = (narrative or "") + " " + (initial_details_summary or "") + " " + (payload.initial_details or "")
                 # Add last user message for freshness
                 if payload.chat_history and payload.chat_history[-1].role == "user":
                     combined_reg_search += " " + payload.chat_history[-1].content
                 
                 # Also check previous user messages just in case
                 for m in payload.chat_history:
                     if m.role == "user":
                         combined_reg_search += " " + m.content

                 found_valid_reg = validate_vehicle_number(combined_reg_search)
                 if not found_valid_reg:
                      # If explicit mention of "number" or "registration" missing, maybe ask?
                      # But let's only block if they provided something looking like a reg but invalid?
                      # Or strict: if vehicle theft, MANDATE reg number?
                      # User asked: "Need to ask mandatory questions... for bike lost/theft : Registration Number"
                      
                      # If we haven't found a valid reg, ask for it.
                      msg = "For vehicle cases, the Registration Number is mandatory. Please provide the Vehicle Registration Number (e.g., TS09AB1234)."
                      if language == "te":
                          msg = "వాహనం విషయంలో రిజిస్ట్రేషన్ నంబర్ తప్పనిసరి. దయచేసి మీ వాహన నంబర్ చెప్పండి (ఉదాహరణకు: TS09AB1234)."
                      return ChatStepResponse(status="question", message=msg)

            # Create final object (mapping fields)
            try:
                final_req = ComplaintRequest(
                    full_name=final_name,
                    address=final_address,
                    phone=final_phone,
                    complaint_type=final_complaint_type,
                    details=payload.initial_details, 
                    incident_details=narrative,
                    incident_address=short_incident,
                    language=payload.language
                )
            except Exception as validation_error:
                 logger.error(f"ComplaintRequest validation failed: {validation_error}")
                 return ChatStepResponse(status="question", message=f"Please provide missing details: {validation_error}")
            
            # Generate the formal summary text block
            formal_summary_text, localized_fields = generate_summary_text(final_req)
            
            # --- USER FEEDBACK MAPPING FIX ---
            # 1. 'details' -> Full Summarization (Narrative)
            # 2. 'incident_details' -> Where/When incident happened (Short Incident)
            
            localized_fields["details"] = initial_details_summary
            localized_fields['incident_details'] = narrative
            localized_fields['incident_address'] = short_incident # Keep consistent
            
            # Classification
            classification_context = _build_classification_context(
                final_complaint_type,
                narrative,
                language,
                localized_fields,
            )
            classification = classify_offence(
                 formal_summary_text,
                 complaint_type=final_complaint_type,
                 details=narrative,
                 classification_text=classification_context
            )
            
            # Translation of Classification Label
            final_classification_str = classification
            if language == "te":
                final_classification_str = translate_to_telugu(classification)
            
            final_response_obj = ComplaintResponse(
                formal_summary=safe_utf8(formal_summary_text), # Standard format
                classification=safe_utf8(final_classification_str),
                original_classification=classification, # MUST BE ENGLISH "Cognizable" or "Non-Cognizable" for Logic
                raw_conversation=safe_utf8(transcript), # DIRECT TRANSCRIPT (No static Qs)
                timestamp=get_timestamp(),
                # localized_fields=localized_fields,
                localized_fields={k: safe_utf8(v) for k, v in localized_fields.items()},
                incident_details=safe_utf8(narrative),
                incident_address=None,
                
                # New fields from user script logic
                full_name=final_req.full_name,
                address=final_req.address,
                phone=final_req.phone,
                initial_details=safe_utf8(initial_details_summary)
            )
            
            # return ChatStepResponse(status="done", final_response=final_response_obj)
            return JSONResponse(
                content=ChatStepResponse(
                    status="done",
                    final_response=final_response_obj
                ).model_dump(),
                media_type="application/json; charset=utf-8"
            )
            # End of DONE block
            
            # If not done, return the question
            reply = reply.encode("utf-8", "ignore").decode("utf-8")
            return JSONResponse(
                content=ChatStepResponse(
                    status="question",
                    message=safe_utf8(reply)
                ).model_dump(),
                media_type="application/json; charset=utf-8"
            )


        else:
            return JSONResponse(
                content=ChatStepResponse(status="question", message=reply).model_dump(),
                media_type="application/json; charset=utf-8"
            )
            # return ChatStepResponse(status="question", message=reply)

    except Exception as e:
        logger.error(f"Chat step failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
