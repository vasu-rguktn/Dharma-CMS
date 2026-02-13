from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from services.gemini_service import GeminiService
import json

router = APIRouter(
    prefix="/api/ai",
    tags=["AI Utilities"]
)

# Singleton service instance
_gemini_service = GeminiService()

class TranslatePetitionRequest(BaseModel):
    title: str
    grounds: str
    prayerRelief: str
    incidentAddress: str | None = None
    address: str | None = None
    petitionType: str | None = None
    petitionerName: str | None = None
    district: str | None = None
    stationName: str | None = None
    targetLanguage: str

@router.post("/translate/petition")
async def translate_petition(request: TranslatePetitionRequest):
    """
    Translate petition details (title, grounds, prayer, addresses, and other metadata) to the target language.
    """
    try:
        if not _gemini_service.model:
             raise HTTPException(status_code=503, detail="AI Service unavailable (Check API Key configuration).")

        result_json_str = await _gemini_service.translate_petition(
            title=request.title,
            grounds=request.grounds,
            prayer=request.prayerRelief,
            incident_address=request.incidentAddress or "",
            address=request.address or "",
            petition_type=request.petitionType or "",
            petitioner_name=request.petitionerName or "",
            district=request.district or "",
            station_name=request.stationName or "",
            target_lang=request.targetLanguage
        )
        
        # Parse the JSON string from AI to ensure it's valid JSON for the response
        try:
            parsed_result = json.loads(result_json_str)
            return parsed_result
        except json.JSONDecodeError:
             # Fallback if AI returned malformed JSON but maybe still understandable text
             # We'll try to wrap it or return error
             print(f"Malfored JSON from AI: {result_json_str}")
             raise HTTPException(status_code=500, detail="AI returned invalid JSON format.")
             
    except Exception as e:
        print(f"Translation Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
