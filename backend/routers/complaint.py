from fastapi import APIRouter, HTTPException, status

from pydantic import BaseModel, Field

from typing import Optional, Dict, Tuple

from datetime import datetime, timedelta

import os

from dotenv import load_dotenv

from openai import OpenAI

import re

from loguru import logger
import json



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
    timeout=20.0,
)

LLM_MODEL = "meta-llama/Meta-Llama-3-8B-Instruct"



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

    complaint_type: str

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

    address: str = Field(..., min_length=1)

    phone: str = Field(..., min_length=10)

    complaint_type: str = Field(..., min_length=1)

    details: str = Field(..., min_length=10)

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
    if not re.fullmatch(r"[A-Za-z ]+", name):
        return False
    parts = name.split()
    if len(parts) < 2:
        return False
    if len(name) < 3:
        return False
    return True


def validate_phone(phone: str) -> bool:
    phone = phone.strip()
    if not phone.isdigit():
        return False
    if len(phone) != 10:
        return False
    if phone[0] not in "6789":
        return False
    if len(set(phone)) == 1:  # all digits same
        return False
    return True


def validate_address(address: str) -> bool:
    address = address.strip()

    # Minimum length
    if len(address) < 5:
        return False

    # Must contain at least one alphabet (real place name)
    if not re.search(r"[A-Za-z]", address):
        return False

    # Allowed characters: letters, digits, space, comma, hyphen, slash
    if not re.fullmatch(r"[A-Za-z0-9 ,\-\/]+", address):
        return False

    # Prevent addresses that are mostly numbers
    letters_count = len(re.findall(r"[A-Za-z]", address))
    digits_count = len(re.findall(r"[0-9]", address))
    if digits_count > letters_count * 3:
        return False

    # Optional PIN code check (if present)
    pin_match = re.search(r"\b\d{6}\b", address)
    if pin_match:
        pin = pin_match.group()
        if len(set(pin)) == 1:  # 000000, 111111 etc.
            return False

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

    if HF_TOKEN:

        try:

            criteria = (

                "You are an expert in Indian criminal procedure. Decide ONLY from the provided fields. "

                "Do NOT assume missing facts, do NOT infer offences from examples in questions, and do NOT guess. "

                "If the complaint involves 'Missing Person', 'Theft', 'Violence', 'Fraud', 'Cheating', or 'Cyber Crime', classify as COGNIZABLE.\n"

                "If a specific offence is not explicitly present in the details, prefer NON-COGNIZABLE.\n\n"

                "Output format (exactly one line):\n"

                "COGNIZABLE  OR  NON-COGNIZABLE."
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

        # 2. Extract identity from initial details if missing
        # Treat invalid phone in payload as missing
        payload_phone_valid = payload.phone and validate_phone(payload.phone)
        
        if not payload.full_name or not payload_phone_valid or not payload.address:
            # We can try to extract from initial_details
            extracted = extract_identity_from_text(payload.initial_details)
            if not payload.full_name and extracted["full_name"]:
                payload.full_name = extracted["full_name"]
            if not payload_phone_valid and extracted["phone"]:
                payload.phone = extracted["phone"]
            if not payload.address and extracted["address"]:
                payload.address = extracted["address"]
        
        # 3. Build Context for LLM
        # Use the "STRICT RULES" prompt from user
        system_prompt = (
            "You are a police officer collecting details and drafting a formal complaint.\n\n"

            "STRICT RULES:\n"
            "Ask only essential questions one by one to clearly understand the incident.\n"
            "Do NOT ask about complaint type.\n"
            " Ask ONLY ONE question at a time.\n"
            "- The citizen has already submitted a complaint.\n"
            "- Do NOT ask them to repeat the complaint.\n"
            "- Do not consider the incidnet location as the address of the citizen.\n"


            "FLOW RULES:\n"
            "Ask name/phone/address ONLY AFTER investigation if not mentioned "
            "1. The citizen has already given a free-text complaint.\n"
            "2. FIRST, try to understand the incident from the complaint.\n"
            "3. Ask ONLY ONE question at a time.\n"
          
            "4. Ask questions in this:\n"
            "   a) Date & time of incident (if unclear)\n"
            "   b) Incident location (DO NOT assume home address)\n"
            "   c) Stolen item/ incident details\n"
            "   d) Evidence / witnesses (optional)\n"
            "5. If the incident location is unclear, explicitly ask:\n"
            "   'Where exactly did the incident occur?'\n"
            "6. Do NOT ask unnecessary or repetitive questions.\n"
            "7. Once sufficient details are collected, reply ONLY with 'DONE'."
            "8. Ask name/phone/address ONLY AFTER investigation"
            "9. If the user clearly says they do not know or do not have the information, accept it and move forward. Do NOT repeat the question."
            "10 .Never overwrite residential address with incident location, even if they look similar."
            "11 . Need to ask manadatory questions like : for mobile lost/ theft IMEI number, for bike lost/theft : Registration Number,etc..."
            "IDENTITY RULE:"
            "- NEVER ask for name, phone, or residential address during investigation."
            "- Identity details are handled separately by the system."
            "- If asked during investigation, it is a violation."
            "\n"
            f"IMPORTANT: You must respond in the language: {language} (if 'te' is Telugu, if 'en' is English).\n"
        )
        
        # Convert Pydantic chat history to LLM format
        messages = [{"role": "system", "content": system_prompt}]
        # Prepend initial details as context from user
        messages.append({"role": "user", "content": payload.initial_details})
        
        for msg in payload.chat_history:
            messages.append({"role": msg.role, "content": msg.content})
            
        # 4. Call LLM
        if not HF_TOKEN:
             # Fallback
             return ChatStepResponse(status="done", final_response=None)

        if len(payload.chat_history) > 25:
             logger.info("Chat history too long, forcing DONE.")
             reply = "DONE"
        else:
            completion = client.chat.completions.create(
                model=LLM_MODEL,
                messages=messages,
                temperature=0.3,
                max_tokens=250,
            )
            reply = completion.choices[0].message.content.strip()

        logger.info(f"LLM Reply: {reply}")

        if not reply:
            reply = "Could you please provide more details?"
        
        # 5. Check for DONE
        clean_reply = re.sub(r"[^a-zA-Z]", "", reply).upper()
        
        if clean_reply == "DONE" or "DONE" in clean_reply.split():
            # Generate final summary using NEW prompt
            
            transcript = payload.initial_details + "\n"
            for msg in payload.chat_history:
                role_label = "User" if msg.role == "user" else "Officer"
                transcript += f"{role_label}: {msg.content}\n"
                
            summary_prompt = f"""
You are an expert police complaint writer.

You are a senior police officer recording an FIR.\n\n

- NEVER assume the incident occurred at the complainant's residential address.
- Use the residential address ONLY for identification.
- Use an incident location ONLY if explicitly mentioned by the user.
- If the incident place is vague (e.g., "parking area"), keep it vague.
- If the incident place is not clearly mentioned, leave it .
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



TASKS:
1. Identify the complaint type automatically.
2. Extract date, time, and place from the conversation if mentioned.
3. Describe  ONLY the incident location :where the incident happened in 1–2 lines, include the date&time if mentioned .
4. Write a clear narrative description of the incident in plain English (no FIR format). Do NOT include FIR number, signatures, or headings.
5. Do NOT invent dates, places, or items not explicitly mentioned by the user.
6. Extract name, address, number from the conversation.


OUTPUT FORMAT (STRICT JSON ONLY):
{{
    "full_name": "", 
    "address": "",
    "phone": "",
    "complaint_type": "",
    "initial_details": "",
  "details": "",
  
    "short_incident_summary": "Short 1-2 line summary of WHERE and WHEN the incident happened (e.g. 'Incident happened  at [Place] on [Date] around [Time]')."
}}

INFORMATION:
{transcript}
"""         
            # Adjust prompt for language if needed
            if language == 'te':
                 summary_prompt = summary_prompt.replace("in plain English", "in Telugu (translated)")
                 summary_prompt += "\n\nIMPORTANT: Output the JSON values in Telugu where appropriate (narrative), but keep keys in English."

            summary_completion = client.chat.completions.create(
                model=LLM_MODEL,
                messages=[{"role": "system", "content": summary_prompt}],
                temperature=0.2, # Low temp for consistency
                max_tokens=450,
                response_format={"type": "json_object"}
            )
            
            final_json_str = summary_completion.choices[0].message.content.strip()
            logger.info(f"Summary JSON: {final_json_str}")
            
            # Parse JSON
            try:
                n_data = json.loads(final_json_str)
            except:
                logger.error("Failed to parse summary JSON")
                n_data = {}

            # Map to ComplaintResponse
            narrative = n_data.get("details", "")
            final_complaint_type = n_data.get("complaint_type", payload.complaint_type)
            initial_details_summary = n_data.get("initial_details", "")
            short_incident = n_data.get("short_incident_summary", "")
            
            # Extract collected identity if missing in payload
            extracted_name = n_data.get("full_name")
            extracted_address = n_data.get("address")
            extracted_phone = n_data.get("phone")
            
            # Helper function to check if question was already asked
            def was_question_asked(chat_history, question_keywords):
                """Check if a question containing any of the keywords was already asked"""
                for msg in chat_history:
                    if msg.role == "assistant":
                        content_lower = msg.content.lower()
                        if any(keyword in content_lower for keyword in question_keywords):
                            return True
                return False
            
            final_name = payload.full_name
            # Validate extracted name if payload name is missing
            extracted_name_valid = extracted_name and validate_name(extracted_name)
            
            if not final_name or not validate_name(final_name):
                if extracted_name_valid:
                    final_name = extracted_name
                else:
                    # Check if we already asked for name
                    name_keywords = ["పూర్తి పేరు", "full name", "your name", "మీ పేరు"]
                    if was_question_asked(payload.chat_history, name_keywords):
                        # Already asked but no valid answer - use placeholder or skip
                        logger.warning("Name question already asked but no valid answer received")
                        final_name = "Not Provided"  # Use placeholder instead of asking again
                    else:
                        # First time asking - ask for it
                        msg = "What is your full name?"
                        if language == "te":
                            msg = "మీ పూర్తి పేరు ఏమిటి?"
                        return ChatStepResponse(status="question", message=msg)
                
            final_address = payload.address
            extracted_address_valid = extracted_address and validate_address(extracted_address)
            
            if not final_address or not validate_address(final_address):
                if extracted_address_valid:
                    final_address = extracted_address
                else:
                    # Check if we already asked for address
                    address_keywords = ["నివసిస్తున్నారు", "where do you live", "your address", "మీ చిరునామా"]
                    if was_question_asked(payload.chat_history, address_keywords):
                        logger.warning("Address question already asked but no valid answer received")
                        final_address = "Not Provided"
                    else:
                        # First time asking
                        msg = "Where do you live (place / area)?"
                        if language == "te":
                            msg = "మీరు ఎక్కడ నివసిస్తున్నారు (ప్రాంతం / నగరం)?"
                        return ChatStepResponse(status="question", message=msg)
                
            final_phone = payload.phone
            if not final_phone or not validate_phone(final_phone):
                 if extracted_phone and validate_phone(extracted_phone):
                     final_phone = extracted_phone
                 else:
                     # Check if we already asked for phone
                     phone_keywords = ["ఫోన్ నంబర్", "phone number", "contact number", "మీ నంబర్"]
                     if was_question_asked(payload.chat_history, phone_keywords):
                         logger.warning("Phone question already asked but no valid answer received")
                         final_phone = "Not Provided"
                     else:
                         # First time asking
                         msg = "Enter your phone number (10 digits):"
                         if language == "te":
                             msg = "దయచేసి మీ ఫోన్ నంబర్‌ను నమోదు చేయండి (10 అంకెలు):"
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
            
            # Override "details" in localized fields with the narrative/summary
            localized_fields["details"] = initial_details_summary
            localized_fields['incident_details'] = narrative
            localized_fields['incident_address'] = short_incident
            
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
            
            final_response_obj = ComplaintResponse(
                formal_summary=formal_summary_text, # Standard format
                classification=classification,
                original_classification=classification,
                raw_conversation=transcript, # DIRECT TRANSCRIPT (No static Qs)
                timestamp=get_timestamp(),
                localized_fields=localized_fields,
                incident_details=narrative,
                incident_address=None,
                
                # New fields from user script logic
                full_name=final_req.full_name,
                address=final_req.address,
                phone=final_req.phone,
                initial_details=initial_details_summary
            )
            
            return ChatStepResponse(status="done", final_response=final_response_obj)
            
        else:
            return ChatStepResponse(status="question", message=reply)

    except Exception as e:
        logger.error(f"Chat step failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))
