from fastapi import APIRouter, HTTPException, status, UploadFile, File, Form
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from typing import Optional, Dict, Tuple, List

from datetime import datetime, timedelta

import os


import os
from dotenv import load_dotenv
import google.generativeai as genai
import re
from loguru import logger
import json
import json
import sys
from services.legal_rag import rag_enabled, retrieve_context

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

load_dotenv(override=True)

# DEBUG: Print loaded keys to confirm switch
inv_key = os.getenv("GEMINI_API_KEY_INVESTIGATION")
main_key = os.getenv("GEMINI_API_KEY")
print(f"DEBUG: INV_KEY starts with: {inv_key[:10] if inv_key else 'None'}")
print(f"DEBUG: MAIN_KEY starts with: {main_key[:10] if main_key else 'None'}")

GEMINI_API_KEY = inv_key or main_key

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

    is_anonymous: bool = False



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
    is_anonymous: bool = False



class ComplaintResponse(BaseModel):
    formal_summary: str
    classification: str
    original_classification: str  # New field
    raw_conversation: str
    timestamp: str
    localized_fields: Dict[str, str] = Field(default_factory=dict)
    incident_details: Optional[str] = None
    incident_address: Optional[str] = None
    incident_date: Optional[str] = None  # New field for incident date
    
    # New top-level fields for user convenience
    full_name: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    initial_details: Optional[str] = None
    
    # New fields for Police Station Logic
    selected_police_station: Optional[str] = None
    police_station_reason: Optional[str] = None
    station_confidence: Optional[str] = None



# === Helpers ===

LANGUAGE_NAMES = {
    "en": "English",
    "te": "Telugu",
    "hi": "Hindi",
    "ta": "Tamil",
    "kn": "Kannada",
    "ml": "Malayalam",
    "mr": "Marathi",
    "gu": "Gujarati",
    "bn": "Bengali",
    "pa": "Punjabi",
    "ur": "Urdu",
    "or": "Odia",
    "as": "Assamese",
    "mai": "Maithili",
    "sa": "Sanskrit",
    "ne": "Nepali",
    "sd": "Sindhi",
    "ks": "Kashmiri",
    "kok": "Konkani",
    "doi": "Dogri",
    "mni": "Manipuri",
    "brx": "Bodo",
    "sat": "Santali"
}

def resolve_language(lang: Optional[str]) -> str:
    if not lang:
        return "en"
    # Handle "en-US", "hi-IN" etc.
    code = lang.lower().split('-')[0]
    
    if code in LANGUAGE_NAMES:
        return code
    
    # Fallback to English if unknown
    return "en"

def get_language_name(code: str) -> str:
    return LANGUAGE_NAMES.get(code, "English")

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
    
    # 4. Filter Control Characters only (Keep Newlines/Tabs)
    # Remove C0 control chars (00-1F) except 09 (Tab), 0A (LF), 0D (CR)
    clean_text = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', clean_text)
    return clean_text




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





def translate_text(text: str, target_lang_code: str) -> str:
    """
    Translate text into the target language using LLM.
    Handles romanized input if consistent with the target language context.
    """
    if not GEMINI_API_KEY or not text:
        return text

    target_lang_name = get_language_name(target_lang_code)
    if target_lang_name == "English":
        return text

    try:
        model = genai.GenerativeModel(LLM_MODEL)
        
        prompt = (
            f"Translate the following text into {target_lang_name}.\n"
            "Preserve personal names, places, and numbers exactly as provided.\n"
            "Return only the final translated text without quotes or commentary.\n\n"
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

# Backward compatibility (alias)
def translate_to_telugu(text: str) -> str:
    return translate_text(text, "te")





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


        context_block = ""
        if rag_enabled():
            try:
                # Retrieve relevant BNS context
                query = f"{complaint_type} {details}"
                context_text, _ = retrieve_context(query, top_k=3)
                if context_text:
                    context_block = f"\nRelevant New Laws (BNS/BNSS) Context:\n{context_text}\n"
            except Exception as e:
                logger.warning(f"RAG lookup failed in label generation: {e}")

        prompt = (
            "You are an expert in Indian criminal law, specifically Bharatiya Nyaya Sanhita (BNS). "
            "From the fields below, provide a concise official offence"
            " name and BNS section(s) if clearly applicable. Output exactly one short line like:\n"
            "Theft — BNS 303(2)\nAttempted murder — BNS 109\nNot applicable\n\n"
            f"{context_block}\n"
            f"Complaint Type: {complaint_type}\n"
            f"Details: {details}\n\n"
            "If unsure or not applicable, reply with 'Not applicable'. DO NOT use IPC numbers. USE BNS SECTIONS ONLY.\n"
            "Be concise and do not hallucinate BNS numbers unless clearly applicable."
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

        if re.search(r"\b(IPC|BNS|BNSS)\b", first_line, flags=re.IGNORECASE) or re.search(r"\bsection\s*\d+\b", first_line, flags=re.IGNORECASE):
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
    
    # Mask phone if anonymous (Keep first 3 digits, mask the rest)
    if req.is_anonymous and len(phone) >= 3:
        phone = phone[:3] + "x" * (len(phone) - 3)
    
    # "Incident Details" -> Short summary (1-2 lines, location/time)
    # Using 'short_incident_summary' from request if available, falling back to details
    incident_short = getattr(req, 'incident_address', None) or req.details.strip() 
    
    # "Details" -> Full detailed narrative
    narrative_full = req.incident_details.strip() if req.incident_details else incident_short

    if language != "en":
        full_name = translate_text(full_name, language)
        address = translate_text(address, language)
        incident_short = translate_text(incident_short, language)
        narrative_full = translate_text(narrative_full, language)
        # Translate the base complaint type (e.g. "Theft") to Target Language
        # But KEEP the official label (e.g. IPC 378) in English/Official format
        cleaned_type = req.complaint_type.strip()
        translated_type = translate_text(cleaned_type, language)
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

    if language != "en" and localized_fields:
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
        if language != "en" and classification:
            classification_display = translate_text(classification, language)

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


import asyncio

# ---------------- HELPER FOR TEXT-FROM-FILE ----------------
async def analyze_file_content(file: UploadFile) -> str:
    """
    Extract text or description from attached file.
    For PDF: Extract text.
    For Image: Use Gemini Vision to describe it (briefly).
    """
    try:
        # 1. Read File with Timeout safety
        content = await file.read() 
        filename = file.filename.lower()
        
        if filename.endswith(".pdf"):
            from routers.legal_chat import extract_pdf_text
            text = extract_pdf_text(content)
            return f"[ATTACHED PDF '{file.filename}']: {text[:500]}..." if text else f"[ATTACHED PDF '{file.filename}'] (Unreadable)"
            
        elif filename.endswith((".jpg", ".jpeg", ".png", ".webp")):
            # FAST MODE: Skip deep analysis as per user request to avoid latency.
            # Just acknowledge the file.
            logger.info(f"Fast Mode: Skipping vision analysis for {filename}")
            return f"[ATTACHED IMAGE '{file.filename}'] (Reference Only)"
                
        return f"[ATTACHED FILE '{file.filename}']"
    except Exception as e:
        logger.error(f"File analysis error: {e}")
        return ""

@router.post(
    "/chat-step",
    response_model=ChatStepResponse,
    status_code=status.HTTP_200_OK,
)
async def chat_step(
    # JSON Payload (Legacy/Text-only)
    payload_json: Optional[ChatStepRequest] = None,
    
    # Form Fields (New/File-support)
    # We use Optional because if JSON is sent, these won't be present
    full_name: Optional[str] = Form(None),
    address: Optional[str] = Form(None),
    phone: Optional[str] = Form(None),
    complaint_type: Optional[str] = Form(None),
    initial_details: Optional[str] = Form(None),
    language: Optional[str] = Form(None),
    is_anonymous: Optional[bool] = Form(None),
    chat_history_str: Optional[str] = Form(None, alias="chat_history"), # Client sends JSON string
    
    # Files
    files: List[UploadFile] = File([], description="Optional evidence files"),
):
    """
    Dynamic chat turn. Supports JSON body OR Multipart Form Data (for files).
    Decides whether to ask another question or finalize the complaint.
    """
    try:
        # 0. Unify Input (Form vs JSON)
        if payload_json:
            payload = payload_json
        else:
            # Construct from Form
            try:
                history_list = []
                if chat_history_str:
                    raw_hist = json.loads(chat_history_str)
                    # Convert raw dicts to ChatMessage objects
                    for item in raw_hist:
                        history_list.append(ChatMessage(**item))
                
                payload = ChatStepRequest(
                    full_name=full_name or "",
                    address=address or "",
                    phone=phone or "",
                    complaint_type=complaint_type or "",
                    initial_details=initial_details or "",
                    language=language or "en",
                    is_anonymous=is_anonymous if is_anonymous is not None else False,
                    chat_history=history_list
                )
            except Exception as e:
                logger.error(f"Form parsing error: {e}")
                raise HTTPException(status_code=400, detail="Invalid Form Data or Chat History JSON")

        logger.info(f"Chat Step Request (Form/JSON resolved). History len: {len(payload.chat_history)}")

        # 0.5 Process Files (If any) using Gemini Vision / Text Extraction
        file_context = ""
        if files:
            logger.info(f"Processing {len(files)} attached files...")
            # Parallel Processing
            results = await asyncio.gather(*[analyze_file_content(f) for f in files])
            file_context = "\n".join(results)
            
            # Inject file context into the LAST USER MESSAGE or System Context
            # Best allows the LLM to 'see' it immediately
            if file_context:
                logger.info(f"Generated File Context: {file_context[:100]}...")
                # Hack: Append to initial_details or just append to the prompt context later?
                # Let's append to the last user message in the History for this turn logic
                if payload.chat_history and payload.chat_history[-1].role == 'user':
                     payload.chat_history[-1].content += f"\n\n[SYSTEM: USER ATTACHED EVIDENCE]\n{file_context}"
                else:
                     # If essentially empty history or just starting
                     payload.initial_details += f"\n\n[SYSTEM: USER ATTACHED EVIDENCE]\n{file_context}"

        # 1. Resolve Language
        language = resolve_language(payload.language)
        # logger.info(f"Is Anonymous: {payload.is_anonymous}") # Reduced noise

        if payload.is_anonymous:
             if not payload.full_name:
                 payload.full_name = "Anonymous"
             if not payload.address:
                 payload.address = "Not Recorded (Anonymous Petition)"
            #  logger.info("Anonymous Mode: Auto-filled Name/Address.") 

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
            display_lang = get_language_name(language)



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

            # Define the Anonymous Instruction Header
            anon_header = ""
            if payload.is_anonymous:
                anon_header = (
                    "MODE: ANONYMOUS PETITION\n"
                    "CRITICAL INSTRUCTION: 'Anonymous' ONLY means you skip Name/Address. YOU MUST STILL INVESTIGATE THE CRIME FULLY.\n\n"
                    
                    "INVESTIGATION PRIORITY (FOLLOW THIS ORDER):\n"
                    "1. FIRST: Gather ALL incident details (Date, Time, Location, What happened, Suspects, Witnesses, Property/Vehicle details)\n"
                    "2. SECOND: Ask about evidence (photos, videos, documents)\n"
                    "3. THIRD: Verify Mobile Number (10 digits) is present\n"
                    "4. LAST: Output 'DONE' only when ALL above are complete\n\n"
                    
                    "STRICT RULES:\n"
                    "- Do NOT ask for Name or Address (they want to remain anonymous)\n"
                    "- Do NOT ask for phone number until you have fully investigated the incident\n"
                    "- INVESTIGATE THOROUGHLY: Ask Who, What, Where, When, How in detail\n"
                    "- Ask about Suspects, Witnesses, Property details like a real police officer\n"
                    "- Do NOT stop after just one or two questions - get the complete story first\n"
                    "- EVIDENCE is MANDATORY: You MUST ask about photos/videos/documents before finishing\n"
                    "- Only output 'DONE' when you have: Complete incident details + Evidence question answered + Phone number verified\n\n"
                )

            # Helper function to extract already-known information from conversation
            def extract_known_info(initial_details: str, chat_history: List) -> str:
                """Extract information already mentioned in the conversation to prevent repetition."""
                known_info = []
                
                # Combine all text from initial context and conversation
                all_text = initial_details.lower()
                for msg in chat_history:
                    # Handle both dict and Pydantic object
                    if hasattr(msg, 'role') and hasattr(msg, 'content'):
                        if msg.role == "user":
                            all_text += " " + msg.content.lower()
                    elif isinstance(msg, dict) and msg.get("role") == "user":
                        all_text += " " + msg.get("content", "").lower()
                
                # Check for date/time mentions
                date_patterns = ["january", "february", "march", "april", "may", "june", 
                                "july", "august", "september", "october", "november", "december",
                                "jan", "feb", "mar", "apr", "jun", "jul", "aug", "sep", "oct", "nov", "dec",
                                "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th",
                                "yesterday", "today", "last night", "this morning"]
                time_patterns = ["am", "pm", "o'clock", "morning", "afternoon", "evening", "night"]
                
                has_date = any(pattern in all_text for pattern in date_patterns)
                has_time = any(pattern in all_text for pattern in time_patterns) or any(str(i) in all_text for i in range(1, 13))
                
                if has_date or has_time:
                    known_info.append("- Date/Time: Already mentioned in conversation")
                
                # Check for location mentions
                location_keywords = ["room", "college", "university", "hostel", "market", "street", 
                                    "road", "building", "block", "floor", "house", "shop", "office"]
                if any(keyword in all_text for keyword in location_keywords):
                    known_info.append("- Location: Already mentioned in conversation")
                
                # Check for stolen items
                item_keywords = ["purse", "wallet", "phone", "mobile", "laptop", "bag", "cash", 
                                "money", "rupees", "card", "jewelry", "watch", "bike", "vehicle"]
                if any(keyword in all_text for keyword in item_keywords):
                    known_info.append("- Stolen items: Already mentioned in conversation")
                
                # Check for suspect information
                suspect_keywords = ["suspect", "person", "man", "woman", "boy", "girl", "someone", 
                                   "stranger", "friend", "neighbor", "description"]
                if any(keyword in all_text for keyword in suspect_keywords) or "no suspect" in all_text or "don't know" in all_text:
                    known_info.append("- Suspect info: Already discussed in conversation")
                
                # Check for witness information  
                witness_keywords = ["witness", "saw", "seen", "noticed", "observed"]
                if any(keyword in all_text for keyword in witness_keywords) or "no witness" in all_text or "nobody saw" in all_text:
                    known_info.append("- Witnesses: Already discussed in conversation")
                
                if known_info:
                    return "\n\nINFORMATION ALREADY KNOWN (DO NOT ASK ABOUT THESE AGAIN):\n" + "\n".join(known_info) + "\n"
                return ""

            # Extract known information from conversation
            known_facts = extract_known_info(payload.initial_details, payload.chat_history)

            # System Prompt Definition

            language_name = display_lang
            system_prompt = (
                f"{anon_header}"
                f"You are an expert Police Officer conducting an investigation in {language_name}.\n"
                "GOAL: Ask relevant questions to understand the crime (Who, What, Where, When, How).\n\n"
                
                "CRITICAL RULES:\n"
                "1. NEVER ask about information that is already KNOWN or MENTIONED in the conversation history.\n"
                "2. Check the 'INFORMATION ALREADY KNOWN' section below carefully.\n"
                "3. Ask ONE question at a time. Keep it short and direct.\n"
                "4. Do NOT ask for Name, Phone, or Address if they are already provided/recovered.\n"
                "5. Only ask mandatory case-related questions (Incident Details, Date, Time, Location).\n"
                "6. End questions with '?'.\n"
                "8. Say 'DONE' only when you have the full story + evidence status.\n"
                "GUIDELINES:\n"
                "- Use a polite, respectful, and reassuring tone.\n"
                "- Actively lead the conversation. Focus on ONE point per turn.\n"
                "- KEEP QUESTIONS SHORT (Max 20 words). Do not lecture.\n"
                "- Use Who, What, When, Where, How, and Why questions logically.\n"
                "- Briefly summarize information back to the user for confirmation before moving to the next category.\n\n"

                "INFORMATION TO GATHER (Systematically):\n"
                "1. Incident Details: Date, time, location (MUST BE SPECIFIC - if user says 'college', ask 'Which college?'; if 'market', ask 'Which market?'; if 'hostel', ask 'Which hostel?'), and detailed narration.\n"
                "2. Accused Details: Name, description, address (if known).\n"
                "3. Property/Vehicle: Description, value. (MANDATORY: If Vehicle/Mobile theft, ask for Reg No/IMEI/Model).\n"
                "4. Witnesses: Names and contact details (if any).\n"
                "5. Reason for delay in reporting (if any).\n"
                "6. Complainant Details: Name/Address/Phone is ALREADY KNOWN. DO NOT ASK FOR THIS unless the user is reporting for someone else.\n"
                "7. EVIDENCE (ABSOLUTELY MANDATORY): You MUST ask about evidence before finishing.\n\n"

                "STRICT RULES FOR FUNCTIONALITY:\n"
                "1. NO REPETITION (MOST CRITICAL - FOLLOW THIS PROCESS FOR EVERY RESPONSE):\n"
                "   STEP 1: Before formulating your question, mentally review:\n"
                "           - What did the INITIAL CONTEXT tell you? (user's first message)\n"
                "           - What information appears in the conversation history?\n"
                "   STEP 2: Make a mental list of what you ALREADY KNOW:\n"
                "           - Date/Time: [check if mentioned]\n"
                "           - Location: [check if mentioned]\n"
                "           - What was stolen: [check if mentioned]\n"
                "           - Suspect info: [check if mentioned]\n"
                "           - Witnesses: [check if mentioned]\n"
                "   STEP 3: ONLY ask about information NOT in your mental list.\n"
                "   STEP 4: If you're about to ask 'When did this happen?' but you see 'February 4th' or '11 PM' ANYWHERE in the history, SKIP that question.\n"
                "   STEP 5: If you're about to ask 'What was stolen?' but you see 'purse', 'blue leather', '10000 cash' ANYWHERE in the history, SKIP that question.\n"
                "2. LANGUAGE: Speak in {language_name}. Use natural phrasing.\n"
                "3. EVIDENCE QUESTION (CRITICAL - CANNOT BE SKIPPED):\n"
                "   - Before you output 'DONE', you MUST ask: 'Do you have any photos, videos, or documents to upload as evidence?'\n"
                "   - Check the conversation history - if you have NOT asked this exact question yet, you MUST ask it now.\n"
                "   - Only output 'DONE' if:\n"
                "     a) You have already asked about evidence in a previous turn, AND\n"
                "     b) The user has responded (Yes/No/I don't have any)\n"
                "   - If you see '[SYSTEM: USER ATTACHED EVIDENCE]' in the history, acknowledge it but still ask if they have MORE evidence.\n"
                "4. DOCUMENT AWARENESS: If you see '[SYSTEM: USER ATTACHED EVIDENCE]' or '[ATTACHED IMAGE...]', acknowledge it and use its content.\n"
                "5. TERMINATION: Output 'DONE' ONLY when:\n"
                "   - You have gathered all necessary incident details, AND\n"
                "   - You have explicitly asked about evidence, AND\n"
                "   - The user has responded to the evidence question.\n"
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
                    
                    full_prompt = f"{system_prompt}{known_facts}\n\nINITIAL CONTEXT:\n{payload.initial_details}\n\nCONVERSATION HISTORY:\n"
                    
                    # Limit history (Gemini Flash has ~1M context so we could send all, but 12 turns is safe for focus)
                    recent_history = payload.chat_history[-12:] if len(payload.chat_history) > 12 else payload.chat_history
                    
                    for msg in recent_history:
                        role = "Police" if msg.role == "assistant" else "User" # or "Model" / "User"
                        full_prompt += f"{role}: {msg.content}\n"
                    
                    logger.info(f"--- LLM Prompt Start ---\n{full_prompt}\n--- LLM Prompt End ---")

                    response = model.generate_content(
                        full_prompt,
                        generation_config=genai.types.GenerationConfig(
                            temperature=0.3,
                            max_output_tokens=2048,
                        ),
                        safety_settings=[
                            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
                            {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
                            {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"},
                            {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"},
                        ]
                    )
                    
                    raw_content = response.text or ""
                    logger.info(f"--- LLM Raw Response ---\n{raw_content}\n--- End Response ---")
                    
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
                    import traceback
                    print(f"!!! GEMINI ERROR: {e}", flush=True)
                    traceback.print_exc()
                    logger.error(f"Gemini Chat Generation Error: {e}")
                    reply = f"Could you please provide more details? (Debug: {str(e)[:50]})"


            if not reply:
                reply = "Could you please provide more details? (Debug: Empty)"

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
            # --- FINAL IDENTITY CONFIRMATION ---
            
            # 1. ANONYMOUS MODE EXCEPTIONS
            if payload.is_anonymous:
                 # In Anonymous mode, we ONLY need the phone number (for OTP verification/tracking)
                 # We DO NOT ask for Name or Address.
                 
                 final_phone_confirmed = payload.phone and validate_phone(payload.phone)
                 
                 if not final_phone_confirmed:
                    msg = SYS_MSG_PHONE_TE if language == "te" else SYS_MSG_PHONE_EN
                    return ChatStepResponse(status="question", message=msg)
                    
                 # If phone is present, we are done with identity for anonymous.
                 # Proceed to summary.

            else:
                # 2. NORMAL MODE (Self OR Other)
                # We need FULL details: Name, Address, Phone.
                # Even for "Complaint for Other", we need the REPORTER'S details (or the victim's, depending on flow, but we need *someone's* details).
                
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
            
            # --- MANDATORY SEQUENTIAL QUESTIONS END ---

            # Generate final summary using NEW prompt
            
            transcript = payload.initial_details + "\n"
            for msg in payload.chat_history:
                role_label = "User" if msg.role == "user" else "Officer"
                transcript += f"{role_label}: {msg.content}\n"

            from routers.station_data import DISTRICT_STATIONS
            # json is already imported globally
            stations_json = json.dumps(DISTRICT_STATIONS, indent=2)
                
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
5. LEGAL CLASSIFICATION (MANDATORY): At the very end of the details field, you MUST include a line exactly like this:
   "Classification: COGNIZABLE - Offence permits police action." 
   OR 
   "Classification: NON-COGNIZABLE - Offence permits magistrate order."
   (Choose the correct one based on Indian legal standards).
6. Do NOT invent dates, places, or items not explicitly mentioned by the user.
6. Extract name, address, number from the conversation.
7. Donot assume the incident location as the complainant's residential address untill they mentioned in the residential address.
8. In details field, need the detailed description/ summarization of the entire complaint incident.


# POLICE STATION SELECTION (CRITICAL RULE):
# 1. Analyze the 'short_incident_summary' or incident address from the conversation.
# 2. Identify Locality, Town/City, Mandal, and District.
# 3. CONSULT THE AVAILABLE POLICE STATIONS DATABASE BELOW.
# 4. SELECT ONE POLICE STATION from the list that best matches the location.
#    - If incident is in MUNICIPAL/TOWN limits -> Select '<TownName> Town Police Station' (if available).
#    - If multiple Town stations exist (e.g., I Town, II Town) -> Select based on landmark (e.g., Market, Bus Stand -> usually I Town). If unsure, use 'I Town'.
#    - If incident is in VILLAGE/OUTSKIRTS -> Select '<MandalName> Rural Police Station' or the specific Village station.
#    - MUST EXACTLY MATCH A STRING FROM THE DATABASE. Do not invent names.
# 5. NEVER return 'Station Unknown'. YOU MUST SELECT THE BEST MATCH FROM THE DATABASE.

AVAILABLE POLICE STATIONS DATABASE:
{stations_json}

OUTPUT FORMAT (STRICT JSON ONLY):
{{
    "full_name": "", 
    "address": "",
    "phone": "",
    "complaint_type": "",
    "initial_details": "",
    "details": "COMPREHENSIVE NARRATIVE in FIRST PERSON ('I...'). Must be a detailed formal complaint text suitable for an FIR. Include EVERY fact mentioned (Who, What, Where, When, How, Vehicle details, Suspects, etc). NOT a chat summary.",
  
    "short_incident_summary": "short 1-2 lines where it happend, Specific location and time. EXAMPLE: 'Nuzvid bus stand road on 2026-01-06 at 8 PM'. NOT 'The spot' or 'Incident location'. Extract specific place names.",
    "incident_date": "Extract the incident date in YYYY-MM-DD format if mentioned. Examples: '2026-01-06', '2025-12-25'. If not mentioned, leave empty.",

    "selected_police_station": "Name of the Station (e.g., 'Nuzvid Town Police Station')",
    "police_station_reason": "Brief reason (e.g., 'Incident location is within Nuzvid municipal limits.')",
    "station_confidence": "High/Medium/Low"
}}

INFORMATION:
{transcript}
"""         
            # Adjust prompt for language if needed
            # Adjust prompt for language if needed
            if language != 'en':
                 lang_name = get_language_name(language)
                 # summary_prompt = summary_prompt.replace("in plain English", f"in {lang_name} (translated)")
                 summary_prompt += (f"\n\nIMPORTANT {lang_name.upper()} RULES:\n"
                                    f"- Write the 'details' narrative as a FORMAL PETITION to the Station House Officer in {lang_name}.\n"
                                    f"- Use FIRST PERSON.\n"
                                    f"- NEVER start with 'You said' or 'The user said'.\n"
                                    f"- NEVER mention 'We asked questions'.\n"
                                    f"- Output must be continuous {lang_name} text describing the incident formally.\n"
                                    f"- Output the JSON values in {lang_name} where appropriate (narrative), but keep keys in English.\n"
                                    f"- Need description like full narrative of the complaint not like just description.")

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
            # DISABLED: Causing false positives (e.g., purse theft). LLM handles this via prompt rules.
            # vehicle_keywords = ["vehicle", "bike", "car", "scooter", "motorcycle", "registration number", "number plate", "license plate", "వాహనం", "బైక్", "కారు"]
            # if any(k in full_text_search for k in vehicle_keywords) and ("theft" in full_text_search or "lost" in full_text_search or "దొంగ" in full_text_search):
            #      # ... logic removed ...
            #      pass

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
            
            # Add Police Station fields to localized_fields to ensure availability in frontend
            localized_fields['selected_police_station'] = safe_utf8(n_data.get("selected_police_station"))
            localized_fields['police_station_reason'] = safe_utf8(n_data.get("police_station_reason"))
            localized_fields['station_confidence'] = safe_utf8(n_data.get("station_confidence"))
            
            # Extract incident_date from LLM response
            incident_date_str = n_data.get("incident_date", "")
            if incident_date_str:
                logger.info(f"Extracted incident_date from LLM: {incident_date_str}")
            
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
            if language != "en":
                final_classification_str = translate_text(classification, language)
            
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
                incident_date=incident_date_str if incident_date_str else None,  # Add incident date
                
                # New fields from user script logic
                full_name=final_req.full_name,
                address=final_req.address,
                phone=final_req.phone,
                initial_details=safe_utf8(initial_details_summary),
                
                # Populating Police Station Selection
                selected_police_station=safe_utf8(n_data.get("selected_police_station")),
                police_station_reason=safe_utf8(n_data.get("police_station_reason")),
                station_confidence=safe_utf8(n_data.get("station_confidence"))
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
