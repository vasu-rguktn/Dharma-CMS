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

from utils.gemini_client import gemini_rotator

# Use Flash model for speed/multimodal
# genai is already configured in gemini_client

class MediaAnalysisRequest(BaseModel):
    imageDataUri: str
    userContext: str | None = None

@router.post("")
async def analyze_media(req: MediaAnalysisRequest):
    try:
        if gemini_rotator.key_count() == 0:
            raise HTTPException(status_code=500, detail="Server misconfiguration: No Gemini API Keys found")

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
            
        session_id = f"media-{int(time.time())}"
        response = gemini_rotator.generate_content(
            'gemini-2.0-flash',
            [
                {'mime_type': 'image/jpeg', 'data': image_bytes},
                prompt
            ],
            endpoint="/api/media-analysis",
            session_id=session_id
        )
        
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
