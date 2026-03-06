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
import sys
from services.legal_rag import rag_enabled, retrieve_context
from utils.gemini_client import gemini_rotator, batch_translate_fields

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

# API key management is now handled by the GeminiKeyRotator singleton.
# gemini_rotator is imported from utils.gemini_client and loads all 11 keys.
# This preserves backward-compatibility: GEMINI_API_KEY still works as fallback.
GEMINI_API_KEY = gemini_rotator.key_count() > 0  # truthy if any key is available

if not GEMINI_API_KEY:
    logger.warning("No Gemini API keys found. LLM features will be disabled.")

print("\n" + "="*50)
print(f"!!! GEMINI KEY ROTATOR ACTIVE — {gemini_rotator.key_count()} KEYS LOADED !!!")
print("="*50 + "\n")

# LLM_MODEL = "gemini-flash-latest"

LLM_MODEL = "gemini-2.5-flash"



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
    
    district: Optional[str] = "Unknown"



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
    district: Optional[str] = None

    # New fields for PDF Generation (ensure they are passed to frontend)
    accused_details: Optional[str] = None
    stolen_property: Optional[str] = None
    witnesses: Optional[str] = None
    evidence_status: Optional[str] = None



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





async def translate_text(text: str, target_lang_code: str) -> str:
    """
    Translate a single text field into the target language.
    Now delegates to batch_translate_fields internally for consistency.
    Use batch_translate_fields() directly when translating multiple fields
    to avoid multiple Gemini round-trips.
    """
    if not GEMINI_API_KEY or not text:
        return text

    target_lang_name = get_language_name(target_lang_code)
    if target_lang_name == "English":
        return text

    result = await batch_translate_fields({"text": text}, target_lang_code)
    return result.get("text", text)

# Backward compatibility (alias) — converted to async
async def translate_to_telugu(text: str) -> str:
    return await translate_text(text, "te")





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




def get_current_time_str():
    return datetime.now().strftime("%I:%M %p")

def today_date_str_formatted():
    return datetime.now().strftime("%Y-%m-%d")

def get_current_date_str():
    return datetime.now().strftime("%Y-%m-%d")



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

async def get_official_complaint_label(complaint_type: str, details: str) -> Optional[str]:

    if not GEMINI_API_KEY:
        return None

    try:
        model = genai.GenerativeModel(LLM_MODEL)  # rotator configures the key


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

        response = await gemini_rotator.generate_content_async(
            LLM_MODEL,
            prompt,
            endpoint="predicted_section",
            session_id=f"section-pred-{int(time.time())}",
            generation_config=genai.types.GenerationConfig(
                temperature=0.0,
                max_output_tokens=256,
            )
        )

        raw = (response.text or "").strip()

        if not raw:
            return None

        first_line = raw.splitlines()[0].strip()

        if re.match(r"(?i)not applicable", first_line):
            return None

        if re.search(r"\b(IPC|BNS|BNSS)\b", first_line, flags=re.IGNORECASE) or re.search(r"\bsection\s*\d+\b", first_line, flags=re.IGNORECASE):
            # FIXED: Do NOT remove parentheses as they are needed for BNS/IPC sections like 303(2)
            # cleaned = re.sub(r"[\(\[\{](.*?)[\)\]\}]", r"\1", first_line).strip()
            return first_line.strip()

        return None

    except Exception as e:
        logger.warning(f"LLM official label lookup failed: {e}")
        return None



async def generate_summary_text(req: ComplaintResponse, language: str) -> tuple[str, dict]:
    """
    Generates a structured complaint summary in the target language.
    Uses batch translation to reduce 6 Gemini calls to 1.
    """
    date_display = req.date_of_complaint or "Not mentioned"

    # Attempt to get official label with BNS reference
    official_label = None
    if GEMINI_API_KEY:
        official_label = await get_official_complaint_label(req.complaint_type, req.details)

    full_name = req.full_name.strip()
    address = req.address.strip()
    phone = req.phone.strip()

    # Mask phone if anonymous (Keep first 3 digits, mask the rest)
    if req.is_anonymous and len(phone) >= 3:
        phone = phone[:3] + "x" * (len(phone) - 3)

    # "Incident Details" -> Short summary (1-2 lines, location/time)
    incident_short = getattr(req, 'incident_address', None) or req.details.strip()

    # "Details" -> Full detailed narrative
    narrative_full = req.incident_details.strip() if req.incident_details else incident_short

    cleaned_type = req.complaint_type.strip()

    if language != "en":
        # ── SINGLE BATCH TRANSLATION CALL ──────────────────────────────────────
        # Translate all fields in ONE Gemini call instead of one call per field.
        # Deduplication: if incident_short == narrative_full, only translated once.
        fields_to_translate = {
            "full_name": full_name,
            "address": address,
            "incident_short": incident_short,
            "narrative_full": narrative_full,
            "complaint_type": cleaned_type,
        }
        translated = await batch_translate_fields(fields_to_translate, language)

        full_name      = translated.get("full_name", full_name)
        address        = translated.get("address", address)
        incident_short = translated.get("incident_short", incident_short)
        narrative_full = translated.get("narrative_full", narrative_full)
        translated_type = translated.get("complaint_type", cleaned_type)
        # ───────────────────────────────────────────────────────────────────────

        if official_label:
            complaint_type_line = f"{translated_type} ({official_label})"
        else:
            complaint_type_line = translated_type
    else:
        complaint_type_line = cleaned_type
        if official_label:
            complaint_type_line = f"{complaint_type_line} ({official_label})"

    localized_fields = {
        "full_name": full_name,
        "address": address,
        "phone": phone,
        "complaint_type": complaint_type_line,
        "incident_details": narrative_full,  # Full narrative (for Grounds/Reasons in Petition)
        "details": narrative_full,           # Backup
        "incident_address": incident_short,  # Short summary (for Incident Address in Petition)
        "date_of_complaint": date_display,
    }

    lines = [
        "FORMAL COMPLAINT SUMMARY",
        f"Full Name: {full_name}",
        f"Address: {address}",
        f"Phone Number: {phone}",
        f"Complaint Type: {complaint_type_line}",
        f"Incident Details: {incident_short}",
        f"Details: {narrative_full}",
        f"Date of Complaint: {date_display}",
        "",
        "Note: Legal sections and classifications are generated by AI and should be verified by a legal professional.",
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
    # Allow ANY Unicode character that isn't a control char.
    # The previous regex `[A-Za-z\u0C00-\u0C7F\s\.]+` was too restrictive (English + Telugu only).
    # We now allow everything except obvious junk/control chars.
    # Ideally, we should use `\w` with unicode flag, but in Python re, `\w` handles many scripts.
    # However, to be safe and inclusive of all Indic scripts (Hindi, Tamil, etc.), 
    # we'll just check for minimum length and forbidden characters like digits/symbols if strictness is needed.
    # BUT for now, let's just relax it to allow any non-digit/non-symbol or just rely on length.
    
    # Simple rigorous check: Must contain at least some letters (English or Unicode)
    # \p{L} is not directly supported in Python's `re` without `regex` module.
    # So we'll iterate or use a broader range.
    
    if len(name) < 2:
        return False
        
    return True



def validate_address(address: str) -> bool:
    address = address.strip()

    # Minimum length (Relaxed to 3 to allow "Goa", "Agra", "Ooty")
    if len(address) < 3:
        return False
        
    # Disallow purely numeric addresses (e.g. "500001")
    if address.isdigit():
        return False

    # Placeholder detection
    if any(p in address.lower() for p in ["unknown", "not provided", "n/a", "later", "don't know", "no address", "none"]):
        return False
        
    return True
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
        # FIXED: Preserve parentheses for legal section consistency (e.g. 303(2))
        # justification = re.sub(r"[\(\[\{].*?[\)\]\}]", "", justification).strip()
        justification = justification.strip()

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





async def classify_offence(details: str) -> Optional[str]:

    """

    Enhanced rule-based classifier:

      - If non-cognizable keywords matched -> NON-COGNIZABLE

      - If the text mentions exam/classroom and amount < threshold (or no amount) -> NON-COGNIZABLE

      - If amount >= threshold (default 5000 INR) -> COGNIZABLE

      - If cognizable keywords matched -> COGNIZABLE

      - Otherwise -> NON-COGNIZABLE

    """

    if not GEMINI_API_KEY:
        return None

    text = details.lower()

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

    if GEMINI_API_KEY:

        try:
            # model = genai.GenerativeModel(LLM_MODEL) # Use rotator for async
            
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
                f"Details: {details}"
            )

            response = await gemini_rotator.generate_content_async( # Use await gemini_rotator.generate_content_async
                LLM_MODEL,
                user_payload,
                endpoint="is_cognizable",
                session_id=f"cog-check-{int(time.time())}",
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



@router.post("/summarize", response_model=ComplaintResponse, status_code=status.HTTP_200_OK)
async def summarize_complaint(payload: ComplaintResponse, language: str = "en"):
    """
    Summarizes the gathered facts into a formal report and classifies offence.
    All major processing steps are now async and efficient.
    """
    if language == "undefined" or not language:
        language = "en"

    try:
        # 1. Generate summary text and localized fields
        formal_summary, localized_fields = await generate_summary_text(payload, language)
        
        # 2. Classify the offence
        classification = await classify_offence(payload.details)

        classification_for_logs = classification
        classification_display = classification
        if language != "en" and classification:
            # Translate classification using batch helper (single-field fallback)
            translated_cls = await batch_translate_fields({"classification": classification}, language)
            classification_display = translated_cls.get("classification", classification)

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
        logger.exception("Failed to process complaint summary")
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
             name_keywords = ["full name", "your name", "పేరు", "नाम", "who are you"]
             if content in [SYS_MSG_NAME_EN, SYS_MSG_NAME_TE] or any(k in content.lower() for k in name_keywords):
                 if validate_name(user_ans):
                     found["full_name"] = user_ans
             
             # Address - Check against constants (English & Telugu)
             addr_keywords = [
                 "address", "live", "place", "mandal", "district", "residential",
                 "ఎక్కడ", "చిరునామా", "నివాస", # Telugu
                 "रहते", "पता", "निवासी", # Hindi
                 "முகவரி", "எங்கே", "வசிக்கிறீர்கள்", # Tamil
                 "വിലാസം", "എവിടെ", "താമസിക്കുന്നത്", # Malayalam
                 "ವಿಳಾಸ", "ಎಲ್ಲಿ", "ವಾಸಿಸುವ", # Kannada
                 "पत्ता", "कुठे",  # Marathi
                 "ঠিকানা", "কোথায়", # Bengali
                 "સરનામું", # Gujarati
                 "ਪਤਾ", # Punjabi
                 "ଠିକଣା" # Odia
             ]
             if content in [SYS_MSG_ADDRESS_EN, SYS_MSG_ADDRESS_TE] or any(k in content.lower() for k in addr_keywords):
                 if validate_address(user_ans):
                     found["address"] = user_ans
             
             # Phone - Check against constants (English & Telugu)
             phone_keywords = [
                 "mobile", "phone", "number", "contact", "call", "10 digits",
                 "ఫోన్", "నెంబర్", "సంప్రదించండి", "మొబైల్", # Telugu
                 "फ़ोन", "नंबर", "मोबाइल", "संपर्क", "संख्या", # Hindi
                 "போன்", "எண்", "தொடர்பு", # Tamil
                 "ഫോൺ", "നമ്പർ", "മൊബൈൽ", # Malayalam
                 "ಫೋನ್", "ಸಂಖ್ಯೆ", # Kannada
                 "फोन", "क्रमांक", "मोबाईल", # Marathi/Konkani
                 "ফোন", "নম্বর", # Bengali
                 "ફોન", "નંબર", # Gujarati
                 "ਫੋਨ", "ਨੰਬਰ", # Punjabi
                 "ଫୋନ୍", "ନମ୍ବର" # Odia
             ]
             if content in [SYS_MSG_PHONE_EN, SYS_MSG_PHONE_TE] or any(k in content.lower() for k in phone_keywords):
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

        # logger.info(f"--- 📥 Chat Step Request Received ---")
        # logger.info(f"    Name: {payload.full_name}, Phone: {payload.phone}, Lang: {payload.language}")
        # logger.info(f"    History Length: {len(payload.chat_history)}")
        # logger.info(f"    Is Anonymous: {payload.is_anonymous}")

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
                # logger.info(f"Generated File Context: {file_context[:100]}...")
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
        # logger.info(f"--- 🔄 State Recovery ---")
        # logger.info(f"    Recovered: {recovered}")
        
        if not payload.full_name and recovered["full_name"]:
             payload.full_name = recovered["full_name"]
            #  logger.info(f"    Set Name from recovery: {payload.full_name}")
        
        # Phone validation included
        if (not payload.phone or not validate_phone(payload.phone)) and recovered["phone"]:
             if validate_phone(recovered["phone"]):
                 payload.phone = recovered["phone"]
                #  logger.info(f"    Set Phone from recovery: {payload.phone}")

        if not payload.address and recovered["address"]:
             payload.address = recovered["address"]
            #  logger.info(f"    Set Address from recovery: {payload.address}")
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
             if last_user_msg and re.search(r"^\s*(done|completed|finished|that's it|no more|stop|exit)\.*$", last_user_msg, re.IGNORECASE):
                 skip_llm = True
                 logger.info("User forced DONE (Completion keyword detected).")
             
             # Find last assistant message
             for m in reversed(payload.chat_history):
                 if m.role == "assistant":
                     last_assistant_msg = m.content
                     break
                 
             if last_assistant_msg and last_user_msg and not skip_llm:
                 la_lower = last_assistant_msg.lower()
                #  logger.info(f"--- 🔍 Interception Check ---")
                #  logger.info(f"    Last Asst: '{last_assistant_msg[:50]}...'")
                #  logger.info(f"    Last User: '{last_user_msg[:50]}...'")

                 captured_any = False
                 # detected = None  # MOVED: We will construct 'detected' dynamically at return time
                 
                 # 1. PHONE CHECK
                 phone_keywords = [
                     # English
                     "mobile", "phone", "number", "contact", "call", "10 digits",
                     # Telugu (te)
                     "ఫోన్", "నెంబర్", "సంప్రదించండి", "మొబైల్",
                     # Hindi (hi)
                     "फ़ोन", "नंबर", "मोबाइल", "संपर्क", "संख्या",
                     # Tamil (ta)
                     "போன்", "எண்", "தொடர்பு", "தொலைபேசி", "மொபைல்",
                     # Malayalam (ml)
                     "ഫോൺ", "നമ്പർ", "മൊബൈൽ", "വിളിക്കുക",
                     # Kannada (kn)
                     "ಫೋನ್", "ಸಂಖ್ಯೆ", "ಮೊಬೈಲ್", "ಕರೆ",
                     # Marathi (mr)
                     "फोन", "क्रमांक", "मोबाईल", "संपर्क",
                     # Bengali (bn)
                     "ফোন", "নম্বর", "মোবাইল", "যোগাযোগ",
                     # Gujarati (gu)
                     "ફોન", "નંબર", "મોબાઇલ", "સંપર્ક",
                     # Punjabi (pa)
                     "ਫੋਨ", "ਨੰਬਰ", "ਮੋਬਾਈਲ", "ਸੰਪਰਕ",
                     # Odia (or) & Assamese (as)
                     "ଫୋନ୍", "ନମ୍ବର", "মোবাইল"
                 ]
                 matched_phone = any(k in la_lower for k in phone_keywords)
                 phone_error_msg = None
                 
                 if matched_phone:
                     if validate_phone(last_user_msg):
                        #  logger.info(f"Intercepted VALID phone: {last_user_msg}")
                         payload.phone = last_user_msg 
                         captured_any = True
                     else:
                         phone_error_msg = "Invalid number. Please enter a valid 10-digit mobile number (starts with 6-9):"
                         if language == "te":
                             phone_error_msg = "నెంబర్ సరిగ్గా లేదు. దయచేసి సరైన 10 అంకెల మొబైల్ నంబర్‌ను ఇవ్వండి:"
                         elif language == "hi":
                             phone_error_msg = "अमान्य नंबर। कृपया एक वैध 10-अंकीय मोबाइल नंबर दर्ज करें:"

                 # 2. NAME CHECK
                 name_keywords = [
                     "full name", "your name", "complete name", "valid full name", # Error context
                     "పూర్తి పేరు", "మీ పేరు", "సరైన పూర్తి పేరు", # Telugu Error context
                     "पूरा नाम", "आपका नाम", "शुभ नाम", "सही पूरा नाम", # Hindi Error context
                     "முழு பெயர்", "உங்கள் பெயர்"
                 ]
                 matched_name = any(k in la_lower for k in name_keywords)
                 name_error_msg = None
                 
                 if matched_name:
                     if validate_name(last_user_msg):
                        #  logger.info(f"Intercepted VALID name: {last_user_msg}")
                         payload.full_name = last_user_msg
                         captured_any = True
                     else:
                         name_error_msg = "Please provide your valid full name (at least 2 letters):"
                         if language == "te":
                             name_error_msg = "దయచేసి మీ సరైన పూర్తి పేరు చెప్పండి:"
                         elif language == "hi":
                             name_error_msg = "कृपया अपना सही पूरा नाम बताएं:"

                 # 3. ADDRESS CHECK
                 address_keywords = [
                     "where do you live", "place / area", "residential address", "your address",
                     "valid residential address", "place, mandal, district", "mandal", "district",
                     "ఎక్కడ", "చిరునామా", "నివాస", "ఊరు", "మండలం", "జిల్లా", # Telugu
                     "కहाँ रहते हैं", "आपका पता", "घर का पता", "निवासी", "वैध आवासीय पता", "स्थान", "मंडल", "जिला", # Hindi
                     "முகவரி", "எங்கே", "வசிக்கிறீர்கள்", # Tamil
                     "വിലാസം", "എവിടെ", "താമസിക്കുന്നത്", # Malayalam
                     "ವಿಳಾಸ", "ಎಲ್ಲಿ", "ವಾಸಿಸುವ", # Kannada
                     "पत्ता", "कुठे",  # Marathi
                     "ঠিকানা", "কোথায়", # Bengali
                     "સરનામું", # Gujarati
                     "ਪਤਾ", # Punjabi
                     "ଠିକଣା" # Odia
                 ]
                 matched_address = any(k in la_lower for k in address_keywords)
                 address_error_msg = None
                 
                 if matched_address:
                     if validate_address(last_user_msg):
                        #  logger.info(f"Intercepted VALID address: {last_user_msg}")
                          payload.address = last_user_msg
                          captured_any = True
                     else:
                          address_error_msg = "Please provide a valid residential address (Place, Mandal, District):"
                          if language == "te":
                               address_error_msg = "దయచేసి సరైన నివాస చిరునామా ఇవ్వండి (ఊరు, మండలం, జిల్లా):"
                          elif language == "hi":
                               address_error_msg = "कृपया वैध आवासीय पता प्रदान करें (स्थान, मंडल, जिला):"
                
                 # DECISION LOGIC
                 if captured_any:
                     # We used to set skip_llm = True here, which was a bug.
                     # We want the LLM to continue investigating even if we just captured part of the identity.
                     # The LLM will notice the identity is now 'Known' in the prompt and move to investigation.
                     pass 
                     
                     # We still need to generate the NEXT question (via code or LLM, but here we skipped LLM)
                     # Wait, if we matched, we just updated the state. We need to decide what to ask NEXT.
                     # The original logic relying on `skip_llm = True` works if the *rest* of the code handles "What next?".
                     # But `skip_llm` falls through to... where?
                     # It falls through to line 1797: `if skip_llm or is_done:` -> Final Identity Confirmation logic.
                     # This logic checks what is missing and asks the next question. Perfect.
                     
                     # We just need to ensure `detected_info` is attached to the response found later.
                     # But wait, the response is created inside the logic blocks below (line 1817+).
                     # We need to make sure `detected` is accessible there.
                     pass 

                 elif phone_error_msg: # Prioritize Phone error if nothing else captured
                     det = {"full_name": payload.full_name, "address": payload.address, "phone": payload.phone}
                     return ChatStepResponse(status="question", message=phone_error_msg, detected_info=det)
                 elif name_error_msg:
                     det = {"full_name": payload.full_name, "address": payload.address, "phone": payload.phone}
                     return ChatStepResponse(status="question", message=name_error_msg, detected_info=det)
                 elif address_error_msg:
                     det = {"full_name": payload.full_name, "address": payload.address, "phone": payload.phone}
                     return ChatStepResponse(status="question", message=address_error_msg, detected_info=det)

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
            def extract_known_info(initial_details: str, chat_history: List, payload) -> str:
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
                
                # 1. Identity Extraction (Look for matches in HISTORY if payload is empty)
                # Name
                name_val = payload.full_name
                name_patterns = ["my name is", "i am", "name is", "పేరు", "నా పేరు", "నన్ను"]
                if not name_val and any(p in all_text for p in name_patterns):
                    name_val = "[Provided in history]"
                
                # Address
                addr_val = payload.address
                addr_patterns = ["live at", "residing", "address is", "ఇల్లు", "నివాసం", "చిరునామా"]
                if not addr_val and any(p in all_text for p in addr_patterns):
                    addr_val = "[Provided in history]"

                # Phone
                phone_val = payload.phone
                if not phone_val and re.search(r"\b[6-9]\d{9}\b", all_text):
                    phone_val = "[Provided in history]"

                # District (Broad detection for PS filtering)
                dist_val = payload.district if payload.district != "Unknown" else None
                dist_patterns = [
                    "district", "జిల్లా", "మండలం", "mandal", "town", 
                    "city", "నగరం", "పట్టణం", "area", "ప్రాంతం"
                ]
                if not dist_val and any(p in all_text for p in dist_patterns):
                    # Flag that something was found if it looks like a location mention
                    dist_val = "[Provided in history]"

                if name_val: known_info.append(f"- Name: {name_val}")
                if addr_val: known_info.append(f"- Address: {addr_val}")
                if phone_val: known_info.append(f"- Phone: {phone_val}")
                if dist_val: known_info.append(f"- District: {dist_val}")

                # 2. Check for date/time mentions
                # English Patterns
                date_en = ["january", "february", "march", "april", "may", "june", "july", "august", "september", "october", "november", "december", "jan", "feb", "mar", "apr", "jun", "jul", "aug", "sep", "oct", "nov", "dec", "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "yesterday", "today", "last night", "this morning", "evening", "afternoon", "night"]
                time_en = ["am", "pm", "o'clock", "morning", "afternoon", "evening", "night", "hour", "minutes", "time", "when"]
                
                # Telugu Patterns
                date_te = ["జనవరి", "ఫిబ్రవరి", "మార్చి", "ఏప్రిల్", "మే", "జూన్", "జూలై", "ఆగస్టు", "సెప్టెంబర్", "అక్టోబర్", "నవంబర్", "డిసెంబర్", "నిన్న", "ఈరోజు", "రాత్రి", "ఉదయం", "సాయంత్రం", "మధ్యాహ్నం"]
                time_te = ["సమయం", "గంటలు", "నిమిషాలు", "ఎప్పుడు"]

                if any(p in all_text for p in date_en + date_te):
                    known_info.append("- Date: Already mentioned")
                if any(p in all_text for p in time_en + time_te):
                    known_info.append("- Time: Already mentioned")
                
                # 3. Check for location mentions
                loc_en = ["room", "college", "university", "hostel", "market", "street", "road", "building", "block", "floor", "house", "shop", "office", "parking", "bus stand", "station", "stop", "place", "where", "location", "area", "happened at", "occured at", "inside", "outside", " near ", " at ", " in ", " beside ", " opposite ", " across "]
                loc_te = ["గది", "కళాశాల", "యూనివర్సిటీ", "హాస్టల్", "మార్కెట్", "వీధి", "రోడ్డు", "భవనం", "ఇల్లు", "షాపు", "ఆఫీసు", "బస్ స్టాండ్", "స్టేషన్", "చోటు", "ఎక్కడ", "జరిగింది", "ఉంది", "వద్ద", "స్థలం", "ఖచ్చితంగా", "దగ్గర", "ముందు", "వెనుక"]
                if any(p in all_text for p in loc_en + loc_te):
                    known_info.append("- Location/Place: KNOWN (Information provided in history)")
                
                # 4. Check for stolen items
                item_en = ["purse", "wallet", "phone", "mobile", "laptop", "bag", "cash", "money", "rupees", "card", "jewelry", "watch", "bike", "vehicle", "scooter", "car", "cycle", "property", "what was"]
                item_te = ["పర్సు", "వాలెట్", "ఫోన్", "మొబైల్", "ల్యాప్‌టాప్", "బ్యాగ్", "నగదు", "డబ్బు", "రూపాయలు", "కార్డు", "నగలు", "వాచ్", "బైక్", "బండి", "కారు", "సైకిల్", "వస్తువులు", "ఏమిటి"]
                if any(p in all_text for p in item_en + item_te):
                    known_info.append("- Items/Property: Already mentioned")
                
                # 5. Check for suspect information
                sus_en = ["suspect", "person", "man", "woman", "boy", "girl", "someone", "stranger", "friend", "neighbor", "description", "wearing", "height", "look like", "who was"]
                sus_te = ["నిందితుడు", "వ్యక్తి", "మనిషి", "స్త్రీ", "అబ్బాయి", "అమ్మాయి", "ఎవరో", "తెలియని వ్యక్తి", "స్నేహితుడు", "పక్కింటి", "ఎలా ఉంటాడు", "ఎవరు"]
                if any(p in all_text for p in sus_en + sus_te) or "no suspect" in all_text or "don't know" in all_text:
                    known_info.append("- Suspect info: Already discussed")
                
                # 6. Check for witness information  
                wit_en = ["witness", "saw", "seen", "noticed", "observed", "anybody else", "someone else", "anyone see"]
                wit_te = ["సాక్షి", "చూశారు", "గమనించారు", "ఇంకెవరైనా", "ఎవరైనా చూశారా"]
                if any(p in all_text for p in wit_en + wit_te) or "no witness" in all_text or "nobody saw" in all_text:
                    known_info.append("- Witnesses: Already discussed")

                # 7. Check for Evidence mentions (Crucial for Phase 2 -> 3 transition)
                ev_en = ["photo", "video", "document", "record", "proof", "evidence", "cctv"]
                ev_te = ["ఫోటో", "వీడియో", "డాక్యుమెంట్", "ఆధారం", "సాక్ష్యం", "సీసీటీవీ"]
                if any(p in all_text for p in ev_en + ev_te):
                    known_info.append("- Evidence/Proof: Already discussed")
                
                if known_info:
                    return "\n### SUMMARY OF KNOWN FACTS (DO NOT ASK ABOUT THESE):\n" + "\n".join(known_info) + "\n### END OF KNOWN FACTS\n"
                return ""

            # Extract known information from conversation
            known_facts = extract_known_info(payload.initial_details, payload.chat_history, payload)

            # System Prompt Definition

            language_name = display_lang
            system_prompt = (
                f"{anon_header}"
                f"{known_facts}\n\n"

                f"You are an expert Police Officer conducting a crime investigation in {language_name}.\n\n"

                "YOUR ROLE:\n"
                "- Conduct a thorough investigation by asking relevant questions (Who, What, Where, When, How).\n"
                "- Use the 'SUMMARY OF KNOWN FACTS' above to see what is already discussed.\n"
                "- NEVER ask about a category (like Location or Suspects) if it is listed as 'KNOWN' or 'Already discussed' above.\n\n"

                "INVESTIGATION GUIDELINES:\n"
                "1. START: Gather the core story (Incident details, suspects, witnesses).\n"
                "2. EVIDENCE: Ask about photos, videos, or documents once the core story is clear.\n"
                "3. IDENTITY: Verify Name, Address, and Phone ONLY after the crime details are collected.\n"
                "   - IRREVERSIBLE: Once you start asking for Name, Address, or Phone, you have finished the investigation. NEVER go back to asking about the crime details (Where/When/Who).\n\n"

                "TERMINATION RULE (CRITICAL):\n"
                "- Once ALL fields (Name, Address, Phone) are in the 'SUMMARY OF KNOWN FACTS', you MUST output ONLY the word 'DONE'.\n\n"

                "STRICT NO REPETITION:\n"
                "- If a fact is listed as 'KNOWN' in the summary above, NEVER ask about it again.\n"
                "- Focus ONLY on the single next missing piece of information.\n\n"

                "CONSTRAINTS:\n"
                "- Ask exactly ONE short question (max 20 words).\n"
                "- Output ONLY the question text or 'DONE' if all phases are satisfied.\n"
                "- Never show reasoning or internal notes.\n"
                f"- Use ONLY {language_name}.\n"
            )
            
            # Convert Pydantic chat history to LLM format
            # 4. Call LLM
            if not GEMINI_API_KEY:
                 return ChatStepResponse(status="done", final_response=None)

            if len(payload.chat_history) > 25:
                 logger.info("Chat history too long, forcing DONE.")
                 reply = "DONE"
            else:
                try:
                    # Construct full History for Gemini
                    # rotator configures key before each call
                    model = genai.GenerativeModel(LLM_MODEL)

                    # Convert history to text for prompt
                    history_text = ""
                    # Increase History Cap to 15 turns for better memory
                    recent_history = payload.chat_history[-15:] if len(payload.chat_history) > 15 else payload.chat_history
                    
                    for msg in recent_history:
                        role = "Police" if msg.role == "assistant" else "User"
                        history_text += f"{role}: {msg.content}\n"
                    
                    full_prompt = f"{system_prompt}{known_facts}\n\nINITIAL CONTEXT:\n{payload.initial_details}\n\nCONVERSATION HISTORY:\n{history_text}"
                    
                    # Log more of the prompt for debugging
                    # logger.info("--- 📤 LLM Prompt Sent ---")
                    # logger.info(full_prompt)
                    # logger.info("--- End Prompt ---")

                    import time
                    session_id = f"complaint-session-{payload.phone or 'anon'}"
                    response = await gemini_rotator.generate_content_async(
                        LLM_MODEL,
                        full_prompt,
                        endpoint="/api/complaint/chat-step",
                        session_id=session_id,
                        generation_config=genai.types.GenerationConfig(
                            temperature=0.3,
                            max_output_tokens=1024,
                        ),
                        safety_settings=[
                            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_ONLY_HIGH"},
                            {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_ONLY_HIGH"},
                            {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_ONLY_HIGH"},
                            {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_ONLY_HIGH"},
                        ]
                    )
                    
                    raw_reply = response.text or ""
                    
                    # PARSE STRUCTURED OUTPUT
                    if "RESPONSE:" in raw_reply:
                        # Extract everything after RESPONSE:
                        parts = raw_reply.split("RESPONSE:", 1)
                        reply = parts[1].strip()
                    else:
                        # Fallback parsing for leakages — strip ALL known internal reasoning patterns
                        reply = raw_reply
                        # Remove labelled lines (Phase, Step, Note, Question, etc.)
                        reply = re.sub(r"^(Thinking Process|Internal [Tt]hought|Internal [Rr]easoning|Internal [Ll]og|Internal [Nn]ote|\[?Phase \d+\]?|Step \d+|Question|Note|Analysis|Reasoning|Output|Response):.*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
                        # Remove bullet/dash prefixed internal reasoning lines
                        reply = re.sub(r"^[-*•]\s*(Review|Identify|Analyze|Check|Determine|Consider|Think|Decide|I need|I will|I have|I should|My goal|My task|Let me).*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
                        # Remove common LLM self-talk lines
                        reply = re.sub(r"^(Let's|Let me|I need to|I will|I have|I think|I should|My goal|My task|Okay,|Alright,|Sure,|Now,|First,|Next,|Finally,).*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
                        reply = re.sub(r"^\*?Word count:.*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
                        reply = re.sub(r"^\*\*[A-Za-z ]+:\*\*.*$", "", reply, flags=re.MULTILINE)  # **Label:** style
                        reply = re.sub(r"^#{1,3}\s.*$", "", reply, flags=re.MULTILINE)  # Markdown headings
                        reply = re.sub(r"^KNOWN IDENTITY.*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
                        reply = re.sub(r"^(Name|Address|Phone)\s*=.*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
                        # Remove internal checklist leakage (WHO:, WHAT:, WHEN:, etc.)
                        reply = re.sub(r"^(WHO|WHAT|WHERE|WHEN|HOW|SUSPECTS|WITNESSES|EVIDENCE|PHASE)\s*[:\-→].*$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
                        # Remove checkbox/tick style checklist lines
                        reply = re.sub(r"^[-*•]?\s*(WHO|WHAT|WHERE|WHEN|HOW|SUSPECTS|WITNESSES|EVIDENCE).*[✓✗:].+$", "", reply, flags=re.MULTILINE | re.IGNORECASE)
                        # Collapse multiple blank lines into one, then strip
                        reply = re.sub(r"\n{2,}", "\n", reply).strip()

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
                    # logger.info(f"LLM Reply: {reply}")

                except Exception as e:
                    import traceback
                    print(f"!!! GEMINI ERROR: {e}", flush=True)
                    traceback.print_exc()
                    logger.error(f"Gemini Chat Generation Error: {e}")
                    # Do NOT expose error details to user
                    reply = "మరిన్ని వివరాలు చెప్పండి." if language == "te" else "Please provide more details."


            if not reply:
                reply = "మరిన్ని వివరాలు చెప్పండి." if language == "te" else "Please provide more details."

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
                # logger.info("LLM indicated DONE (or Telugu equivalent). Forcing Gatekeeping.")
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

                # --- GLOBAL SYNC: Always send what we know ---
                detected_final = {}
                if payload.full_name: detected_final["full_name"] = payload.full_name
                if payload.address: detected_final["address"] = payload.address
                if payload.phone: detected_final["phone"] = payload.phone
                
                if not final_name_confirmed:
                     msg = SYS_MSG_NAME_TE if language == "te" else SYS_MSG_NAME_EN
                     return ChatStepResponse(status="question", message=msg, detected_info=detected_final)
                
                if not final_address_confirmed:
                    msg = SYS_MSG_ADDRESS_TE if language == "te" else SYS_MSG_ADDRESS_EN
                    return ChatStepResponse(status="question", message=msg, detected_info=detected_final)

                if not final_phone_confirmed:
                    msg = SYS_MSG_PHONE_TE if language == "te" else SYS_MSG_PHONE_EN
                    return ChatStepResponse(status="question", message=msg, detected_info=detected_final)
            
            # --- MANDATORY SEQUENTIAL QUESTIONS END ---

            # Generate final summary using NEW prompt
            
            transcript = payload.initial_details + "\n"
            for msg in payload.chat_history:
                role_label = "User" if msg.role == "user" else "Officer"
                transcript += f"{role_label}: {msg.content}\n"

            from routers.station_data import DISTRICT_STATIONS
            
            # --- Robust District & Station Detection ---
            # Search address, initial details, and history for better detection
            context_for_detection = (payload.address or "") + " " + (payload.initial_details or "") + " " + transcript
            transcript_lower = context_for_detection.lower()

            reverse_station_map = {} # station_lower -> (orig_station, district)
            for d_name, s_list in DISTRICT_STATIONS.items():
                for s_name in s_list:
                    reverse_station_map[s_name.lower()] = (s_name, d_name)
                    # Create simple version: "Nuzvid Town" -> "nuzvid"
                    base_name = s_name.lower().replace(" town", "").replace(" rural", "").replace(" ps", "").replace(" ups", "").strip()
                    if base_name and base_name not in reverse_station_map:
                        reverse_station_map[base_name] = (s_name, d_name)

            detected_dist = "Unknown"
            detected_station = None
            # First, try matching stations in the transcript
            for s_key, (orig_s, d_name) in reverse_station_map.items():
                if len(s_key) > 4 and s_key in transcript_lower: # Min 5 chars to avoid noise like "area"
                    detected_dist = d_name
                    detected_station = orig_s
                    break
            
            # Second, try matching districts if station not found
            if detected_dist == "Unknown":
                for d_name in DISTRICT_STATIONS.keys():
                    if d_name.lower() in transcript_lower:
                        detected_dist = d_name
                        break
            
            # (Re-inject the reverse_station_map logic here if needed, but we'll do better below)
            
            user_district = payload.district
            if not user_district or user_district == "Unknown":
                user_district = detected_dist
            
            user_district = user_district or "Unknown"
            filtered_stations = DISTRICT_STATIONS.get(user_district, [])
            if not filtered_stations:
                stations_context = "District unknown. Full station database omitted for efficiency. AI will use general knowledge to pick a likely PS if location is mentioned."
            else:
                stations_context = f"Available Police Stations in {user_district} District:\n" + "\n".join(filtered_stations)

            unified_prompt = f"""
You are a senior police officer finalizing a formal complaint.
Based on the transcript and facts below, perform the following tasks:
1. Generate a formal incident narrative (summary) in FIRST PERSON.
2. Classify the offence as "Cognizable" or "Non-Cognizable".
3. Identify the most likely Police Station from the filtered list (or best match).
4. Provide a brief reason for the station selection.
5. Extract identity details (Name, Address, Phone) if they appear in the transcript and are missing from payload.

STRICT JSON OUTPUT FORMAT:
{{
  "narrative": "Detailed formal summary here",
  "classification": "Cognizable/Non-Cognizable",
  "complaint_type": "Theft/Lost/Harassment etc.",
  "district": "Exact District Name",
  "selected_police_station": "Station Name",
  "police_station_reason": "Brief reason based on location",
  "station_confidence": "High/Medium/Low",
  "incident_date": "YYYY-MM-DD",
  "incident_address": "Specific location of incident",
  "full_name": "Extracted name",
  "address": "Extracted address",
  "phone": "Extracted phone",
  "initial_details": "1-sentence summary of the original problem",
  "accused_details": "Name/Description",
  "stolen_property": "Items list",
  "witnesses": "Names/Count",
  "evidence_status": "Brief status"
}}

FILTERED STATIONS (DISTRICT: {user_district}):
{stations_context}

NARRATIVE DATA:
Initial Details: {payload.initial_details}
Identity So Far: {json.dumps({"name": payload.full_name, "address": payload.address, "phone": payload.phone}, ensure_ascii=False)}
Transcript: {transcript}
"""
            try:
                session_id = f"complaint-session-{payload.phone or 'anon'}"
                # One single call replaces Summary, StatsExtraction, Label generation, and Classification
                response = await gemini_rotator.generate_content_async(
                    LLM_MODEL, 
                    unified_prompt,
                    endpoint="/api/complaint/done",
                    session_id=session_id,
                    generation_config=genai.types.GenerationConfig(
                        temperature=0.1,
                        max_output_tokens=2048,
                        response_mime_type="application/json",
                    )
                )
                n_data = json.loads(response.text)
                
            except Exception as e:
                logger.error(f"Unified final processing failed: {e}")
                n_data = {}

            narrative = safe_utf8(n_data.get("narrative", "Summary generation failed."))
            classification = n_data.get("classification", "Cognizable")
            
            # THEFT BNS SECTION INJECTION (Refined as per user request)
            if "theft" in transcript.lower() or "దొంగతనం" in transcript.lower():
                # Set Classification to just the category
                if language == "te":
                    classification = "కాగ్నిజబుల్"
                    theft_legal_type = "దొంగతనం (BNS Section 303(2))"
                else:
                    classification = "Cognizable"
                    theft_legal_type = "Theft (BNS Section 303(2))"
            else:
                theft_legal_type = None
            initial_details_summary = n_data.get("initial_details", "")
            short_incident = safe_utf8(n_data.get("incident_address", ""))
            incident_date_str = n_data.get("incident_date", "")
            
            # Use extracted identity as fallback
            final_name = payload.full_name or n_data.get("full_name")
            final_address = payload.address or n_data.get("address")
            final_phone = payload.phone or n_data.get("phone")
            
            # Prioritize extracted complaint type (e.g. "Theft") over generic fallback
            extracted_type = n_data.get("complaint_type")
            final_complaint_type = payload.complaint_type
            
            # Use our specific legal type if detected
            if theft_legal_type:
                final_complaint_type = theft_legal_type
            elif not final_complaint_type or final_complaint_type in ["Unknown", "General Complaint"]:
                final_complaint_type = extracted_type or "General Complaint"

            # --- VALIDATION GATEKEEPING ---
            if not final_name or not validate_name(final_name):
                msg = SYS_MSG_NAME_EN if language != "te" else SYS_MSG_NAME_TE
                return ChatStepResponse(status="question", message=msg)
            if not final_address or not validate_address(final_address):
                msg = SYS_MSG_ADDRESS_EN if language != "te" else SYS_MSG_ADDRESS_TE
                return ChatStepResponse(status="question", message=msg)
            if not final_phone or not validate_phone(final_phone):
                msg = SYS_MSG_PHONE_EN if language != "te" else SYS_MSG_PHONE_TE
                return ChatStepResponse(status="question", message=msg)

            # Create final request object
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
            
            # --- STATION NORMALIZATION ---
            # Map LLM's selected_police_station back to our specific list names
            llm_station = n_data.get("selected_police_station", "")
            final_station_name = llm_station
            
            # Try to utilize extracted district from LLM if we are still Unknown
            extracted_llm_dist = n_data.get("district")
            if (not user_district or user_district == "Unknown") and extracted_llm_dist:
                if extracted_llm_dist in DISTRICT_STATIONS:
                    user_district = extracted_llm_dist

            # Map "Nuzvid Police Station" -> "Nuzvid Town"
            if llm_station:
                llm_station_lower = llm_station.lower()
                
                # Priority 1: Search within the detected district
                if user_district != "Unknown":
                    stations_in_dist = DISTRICT_STATIONS.get(user_district, [])
                    for s in stations_in_dist:
                        s_clean = s.lower().replace(" town", "").replace(" rural", "").strip()
                        if s_clean in llm_station_lower or llm_station_lower in s.lower():
                            final_station_name = s
                            break
                
                # Priority 2: If still not normalized, search ALL districts (Fallback)
                if final_station_name == llm_station:
                    for d, sList in DISTRICT_STATIONS.items():
                        for s in sList:
                            s_clean = s.lower().replace(" town", "").replace(" rural", "").strip()
                            if s_clean in llm_station_lower or llm_station_lower in s.lower():
                                final_station_name = s
                                if user_district == "Unknown":
                                    user_district = d # Infer district from station match!
                                break
                        if final_station_name != llm_station: break
            
            # Fallback if LLM provided generic unknown
            if (not final_station_name or "unknown" in final_station_name.lower()) and detected_station:
                final_station_name = detected_station
                if user_district == "Unknown" and detected_dist != "Unknown":
                    user_district = detected_dist

            # Localized fields prep for (only one!) batch translation
            localized_fields = {
                # UI Display Keys (Image 2)
                "full_name": final_name,
                "address": final_address,
                "phone": final_phone,
                "complaint_type": final_complaint_type,
                "incident_address": short_incident, # This maps to "Incident Details" line in UI
                "selected_police_station": final_station_name,
                "police_station_reason": n_data.get("police_station_reason", ""),
                "station_confidence": n_data.get("station_confidence", "High"),
                "incident_details": narrative,     # This maps to the final "Details" block
                "classification": classification,
                "district": user_district,
                "date_of_complaint": today_date_str_formatted(),
                
                # Internal Keys (for batch translation but not necessarily UI)
                "accused_details": n_data.get("accused_details", ""),
                "stolen_property": n_data.get("stolen_property", ""),
                "witnesses": n_data.get("witnesses", ""),
                "evidence_status": n_data.get("evidence_status", "")
            }
            
            # --- CONSOLIDATED BATCH TRANSLATION ---
            if language != "en":
                localized_fields = await batch_translate_fields(localized_fields, language)
            
            # The UI also likes these specific keys in localized_fields for its print/QR logic
            # Ensure they are fresh and translated
            final_classification_str = localized_fields.get("classification", classification)
            
            # Reconstruct formal_summary_text for display (Backup for PDF)
            formal_summary_text = (
                f"FORMAL COMPLAINT SUMMARY\n"
                f"Full Name:\n{final_name}\n\n"
                f"Address:\n{final_address}\n\n"
                f"Phone Number:\n{final_phone}\n\n"
                f"Complaint Type:\n{final_complaint_type}\n\n"
                f"Incident Details:\n{short_incident}\n\n"
                f"District:\n{localized_fields.get('district')}\n\n"
                f"Selected Police Station:\n{localized_fields.get('selected_police_station')}\n\n"
                f"Reason:\n{localized_fields.get('police_station_reason')}\n\n"
                f"Confidence Level:\n{localized_fields.get('station_confidence')}\n\n"
                f"Details:\n{narrative}\n\n"
                f"Classification: {final_classification_str}\n\n"
                f"Date of Complaint:\n{localized_fields.get('date_of_complaint')}"
            )
            
            final_response_obj = ComplaintResponse(
                formal_summary=safe_utf8(formal_summary_text), # Standard format
                classification=safe_utf8(final_classification_str),
                original_classification=classification, # MUST BE ENGLISH "Cognizable" or "Non-Cognizable" for Logic
                raw_conversation=safe_utf8(transcript), # DIRECT TRANSCRIPT (No static Qs)
                timestamp=get_timestamp(),
                # localized_fields=localized_fields,
                # Ensure all values are strings (no None)
                localized_fields={k: (safe_utf8(v) or "") for k, v in localized_fields.items()},
                incident_details=safe_utf8(narrative),
                incident_address=None,
                incident_date=incident_date_str if incident_date_str else None,  # Add incident date
                
                # New fields from user script logic
                full_name=final_req.full_name,
                address=final_req.address,
                phone=final_req.phone,
                initial_details=safe_utf8(initial_details_summary),
                
                # Populating Police Station Selection
                selected_police_station=safe_utf8(final_station_name) or "Station Unknown",
                police_station_reason=safe_utf8(n_data.get("police_station_reason")) or "Reason not provided",
                station_confidence=safe_utf8(n_data.get("station_confidence")) or "Low",
                district=safe_utf8(user_district),
                date_of_complaint=today_date_str_formatted(),
                # Mapped Missing Fields
                accused_details=safe_utf8(n_data.get("accused_details")) or "Unknown",
                stolen_property=safe_utf8(n_data.get("stolen_property")) or "N/A",
                witnesses=safe_utf8(n_data.get("witnesses")) or "None",
                evidence_status=safe_utf8(n_data.get("evidence_status")) or "None mentioned",
            )
            
            # --- COMPLAINT SESSION REPORT ---
            from utils.gemini_tracker import gemini_tracker
            session_id = f"complaint-session-{payload.phone or 'anon'}"
            report = gemini_tracker.get_session_summary(session_id)
            logger.info("\n" + report + "\n")

            return JSONResponse(
                content=ChatStepResponse(
                    status="done",
                    final_response=final_response_obj
                ).model_dump(),
                media_type="application/json; charset=utf-8"
            )

        else:
            # If not done, return the question either from LLM or intercepted
            # reply should be the extracted LLM reply or intercepted msg
            clean_reply = reply.encode("utf-8", "ignore").decode("utf-8")
            return JSONResponse(
                content=ChatStepResponse(
                    status="question",
                    message=safe_utf8(clean_reply)
                ).model_dump(),
                media_type="application/json; charset=utf-8"
            )

    except Exception as e:
        logger.error(f"Chat step failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
