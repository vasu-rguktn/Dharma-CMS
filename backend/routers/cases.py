import re
import os
import google.generativeai as genai
import firebase_admin
from firebase_admin import firestore
from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import List, Optional, Any
from datetime import datetime
# from locale 
# import 
router = APIRouter(
    prefix="/api/cases",
    tags=["cases"]
)

# Global db variable removed to avoid import-time initialization error
# db = firestore.client()

# Initialize Gemini
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_INVESTIGATION")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    model = genai.GenerativeModel('models/gemini-2.0-flash')
else:
    print("WARNING: GEMINI_API_KEY_INVESTIGATION not found. Transliteration will fail.")
    model = None

# Pydantic Models matching CaseDoc structure
# We use a loose structure to avoid strict validation errors on minor mismatches, 
# but critical fields are defined.
class CaseCreateRequest(BaseModel):
    caseData: dict 
    locale: str = "en"

async def transliterate_fields(data: dict) -> dict:
    """
    Hybrid Transliteration/Translation for Telugu.
    - NAMES/PLACES -> Phonetic Transliteration (Sound)
    - DETAILS/STORIES -> Semantic Translation (Meaning)
    - CONTEXT AWARE -> Officer Ranks
    """
    if not model:
        print("Gemini model not initialized.")
        return data

    # Group 1: Phonetic Transliteration (Names, Places, Proper Nouns)
    phonetic_source = {
        "title": data.get("title"),
        "district": data.get("district"),
        "subDivision": data.get("subDivision"),
        "circle": data.get("circle"),
        "policeStation": data.get("policeStation"),
        "placeOfOccurrenceStreet": data.get("placeOfOccurrenceStreet"),
        "placeOfOccurrenceArea": data.get("placeOfOccurrenceArea"),
        "placeOfOccurrenceCity": data.get("placeOfOccurrenceCity"),
        "placeOfOccurrenceState": data.get("placeOfOccurrenceState"),
        "complainantName": data.get("complainantName"),
        "complainantFatherHusbandName": data.get("complainantFatherHusbandName"),
        "complainantGender": data.get("complainantGender"),
        "complainantNationality": data.get("complainantNationality"),
        "complainantCaste": data.get("complainantCaste"),
        "complainantAddress": data.get("complainantAddress"),
        "victimName": data.get("victimName"),
        "victimGender": data.get("victimGender"),
        "victimFatherName": data.get("victimFatherName"),
        "victimNationality": data.get("victimNationality"),
        "victimCaste": data.get("victimCaste"),
        "victimAddress": data.get("victimAddress"),
        "ioName": data.get("ioName"),
        "ioDistrict": data.get("ioDistrict"),
        "dispatchOfficerName": data.get("dispatchOfficerName"),
    }

    # Group 2: Semantic Translation (Sentences, Narratives, Descriptions)
    semantic_source = {
        "incidentDetails": data.get("incidentDetails"),
        "propertiesDetails": data.get("propertiesDetails"),
        "actionTaken": data.get("actionTaken"),
        "directionFromPS": data.get("directionFromPS"),
        "informationType": data.get("informationType"),
        "dayOfOccurrence": data.get("dayOfOccurrence"), # e.g. "Monday" -> "సోమవారం"
        "ioRank": data.get("ioRank"), # e.g. "Inspector" -> "ఇన్‌స్పెక్టర్"
        "dispatchOfficerRank": data.get("dispatchOfficerRank"),
        "complainantOccupation": data.get("complainantOccupation"),
        "victimOccupation": data.get("victimOccupation"),
    }

    # Clean empty fields
    phonetic_clean = {k: v for k, v in phonetic_source.items() if v and isinstance(v, str) and v.strip()}
    semantic_clean = {k: v for k, v in semantic_source.items() if v and isinstance(v, str) and v.strip()}
    
    if not phonetic_clean and not semantic_clean:
         return data

    prompt = f"""
    You are an expert English-to-Telugu translator for Police FIRs.
    
    TASK: Convert the input JSON values to Telugu script based on the section rules.
    
    SECTION A: PHONETIC TRANSLITERATION (Convert Sound Only)
    - Use for Names, Places, Streets.
    - DO NOT translate meaning. 
    - Example: "Green Park" -> "గ్రీన్ పార్క్" (NOT "పచ్చని పార్కు")
    - Example: "Raju" -> "రాజు"
    - Exception: "Circle" -> "సర్కిల్"
    
    INPUT A (Phonetic):
    {phonetic_clean}
    
    SECTION B: SEMANTIC TRANSLATION (Convert Meaning)
    - Use for Narratives, Occupations, Days, Directions.
    - Translate completely into natural, formal Telugu.
    - Example: "He ran away" -> "అతను పారిపోయాడు"
    - Example: "Monday" -> "సోమవారం"
    - Example: "Inspector" -> "ఇన్‌స్పెక్టర్"
    - Example: "North" -> "ఉత్తర దిశగా"
    
    INPUT B (Semantic):
    {semantic_clean}
    
    OUTPUT FORMAT:
    Return a SINGLE JSON object containing keys from BOTH sections with their Telugu values.
    """

    try:
        response = model.generate_content(prompt)
        # Use Regex to find the first JSON object (greedy match with DOTALL)
        match = re.search(r"\{.*\}", response.text, re.DOTALL)
        if match:
            cleaned_response = match.group(0)
        else:
            cleaned_response = response.text # Fallback
            
        import json
        transliterated_map = json.loads(cleaned_response)
        
        # Merge back to data
        for k, v in transliterated_map.items():
            if k in data:
                data[k] = v
                
        # Handle Nested Arrays (Accused Persons)
        if "accusedPersons" in data and isinstance(data["accusedPersons"], list):
            new_accused_list = []
            for accused in data["accusedPersons"]:
                # Split Accused Fields (re-setup for context of replacement)
                acc_phonetic = {
                    "name": accused.get("name"),
                    "fatherHusbandName": accused.get("fatherHusbandName"),
                    "gender": accused.get("gender"),
                    "nationality": accused.get("nationality"),
                    "caste": accused.get("caste"),
                    "address": accused.get("address"),
                }
                acc_semantic = {
                    "deformities": accused.get("deformities"),
                    "occupation": accused.get("occupation"),
                }
                
                acc_p_clean = {k: v for k, v in acc_phonetic.items() if v and isinstance(v, str)}
                acc_s_clean = {k: v for k, v in acc_semantic.items() if v and isinstance(v, str)}

                if acc_p_clean or acc_s_clean:
                    acc_prompt = f"""
                    Convert values to Telugu.
                    PHONETIC INPUT: {acc_p_clean} -> Output Transliterated values (Sound)
                    SEMANTIC INPUT: {acc_s_clean} -> Output Translated values (Meaning)
                    
                    TASK: Return a SINGLE FLATTENED JSON object with the keys and their Telugu values.
                    Example Output: {{"name": "...", "deformities": "..."}}
                    """
                    try:
                        acc_resp = model.generate_content(acc_prompt)
                        acc_match = re.search(r"\{.*\}", acc_resp.text, re.DOTALL)
                        if acc_match:
                            acc_clean_text = acc_match.group(0)
                        else:
                            acc_clean_text = acc_resp.text
                            
                        acc_trans = json.loads(acc_clean_text)
                        accused.update(acc_trans)
                    except Exception as inner_e:
                        print(f"Accused Inner Error: {inner_e}")
                        pass
                new_accused_list.append(accused)
            data["accusedPersons"] = new_accused_list

    except Exception as e:
        print(f"Transliteration error: {e}")
        data['_transliteration_error'] = str(e)
        
    return data

@router.post("/create")
async def create_case(req: CaseCreateRequest):
    data = req.caseData
    
    # Add server-side timestamps if missing, though frontend usually sends them.
    # Note: Firestore handles dates. Here we receive JSON. 
    # If using 'add', firestore client handles basic types.
    
    # 1. Check Locale for Transliteration
    if req.locale == 'te':
        print("Locale is Telugu. Initiating transliteration...")
        data = await transliterate_fields(data)

    # 1.5 Convert Date Strings back to Datetime (for Firestore Timestamp compatibility)
    timestamp_fields = ['dateFiled', 'lastUpdated', 'firFiledTimestamp', 'investigationReportGeneratedAt']
    for field in timestamp_fields:
        if field in data and isinstance(data[field], str):
            try:
                # Handle ISO format usually sent by toIso8601String()
                # Python 3.11+ supports fromisoformat for broader formats, but let's be safe
                val = data[field]
                if val:
                    data[field] = datetime.fromisoformat(val.replace('Z', '+00:00'))
            except Exception as e:
                print(f"Date conversion error for {field}: {e}")
                # If fail, leave as string (might cause frontend crash on read, but safer than crashing here)

    
    # 2. Save to Firestore
    try:
        # Initialize Firestore lazily
        db = firestore.client()
        
        # We assume 'cases' collection
        # Add 'createdAt' timestamp
        data['createdAt'] = firestore.SERVER_TIMESTAMP
        
        update_time, doc_ref = db.collection('cases').add(data)
        
        # 3. Return ID (ensure all values are JSON serializable)
        return {
            "status": "success", 
            "id": str(doc_ref.id),  # Ensure string conversion
            "message": "Case created successfully"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
