from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import os
import google.generativeai as genai
from dotenv import load_dotenv
import base64
import json
import re

load_dotenv()

router = APIRouter(
    prefix="/api/media-analysis",
    tags=["Media Analysis"]
)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_INVESTIGATION") or os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    print("CRITICAL: GEMINI_API_KEY_INVESTIGATION not found in env")
    # Don't raise here to allow app to start, but endpoint will fail
    
else:
    genai.configure(api_key=GEMINI_API_KEY)

# Use Flash model for speed/multimodal
model = genai.GenerativeModel('gemini-2.0-flash')

class MediaAnalysisRequest(BaseModel):
    imageDataUri: str
    userContext: str | None = None

@router.post("")
async def analyze_media(req: MediaAnalysisRequest):
    try:
        if not GEMINI_API_KEY:
            raise HTTPException(status_code=500, detail="Server misconfiguration: API Key missing")

        # Extract base64
        encoded = req.imageDataUri
        if "," in encoded:
            header, encoded = encoded.split(",", 1)
        
        try:
            image_bytes = base64.b64decode(encoded)
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid image data")
        
        prompt = """
        You are an expert forensic investigator. Analyze this crime scene image.
        
        Provide the output in STRICT JSON format with the following structure:
        {
            "identifiedElements": [
                {"name": "Item Name", "category": "Evidence/Context/Background", "description": "Short visual description", "count": 1}
            ],
            "sceneNarrative": "A professional, detailed forensic narrative of what is observed in the scene, noting relationships between objects and potential reconstruction.",
            "caseFileSummary": "A concise, factual summary suitable for immediate insertion into a police case file."
        }
        
        Do not include markdown code blocks. Just the raw JSON.
        """
        
        if req.userContext:
            prompt += f"\n\nAdditional Investigator Context: {req.userContext}"
            
        response = model.generate_content([
            {'mime_type': 'image/jpeg', 'data': image_bytes},
            prompt
        ])
        
        text = response.text
        # Clean potential markdown
        text = re.sub(r'```json\s*', '', text)
        text = re.sub(r'```\s*$', '', text)
        text = text.strip()
        
        return json.loads(text)
            
    except Exception as e:
        print(f"Error in media analysis: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
