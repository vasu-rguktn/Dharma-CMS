import os
import time
from dotenv import load_dotenv

load_dotenv()

from utils.gemini_client import gemini_rotator
import google.generativeai as genai


class GeminiService:
    def __init__(self):
        # Validate that at least one key exists via rotator
        if gemini_rotator.key_count() == 0:
            print("[GeminiService] WARNING: No Gemini API keys found. Service unavailable.")
            self.model = None
        else:
            # Expose a reference model for callers that check `self.model`
            # Actual API calls go through the rotator
            self.model = True  # truthy sentinel — real calls use rotator
            print(f"[GeminiService] Ready — {gemini_rotator.key_count()} key(s) available via rotator.")

    async def translate_petition(
        self,
        title: str,
        grounds: str,
        prayer: str,
        incident_address: str,
        address: str,
        petition_type: str,
        petitioner_name: str,
        district: str,
        station_name: str,
        target_lang: str,
    ) -> str:
        if not self.model:
            raise Exception("AI Model not initialized (no API keys configured).")

        start_time = time.time()

        prompt = f"""
        Translate the following petition details to {target_lang}.
        
        Input:
        Title: {title}
        Type: {petition_type}
        Petitioner Name: {petitioner_name}
        District: {district}
        Station: {station_name}
        Grounds: {grounds}
        Prayer/Relief: {prayer}
        Incident Address: {incident_address}
        Petitioner Address: {address}
        
        Instructions:
        1. Return ONLY a valid JSON object.
        2. The JSON keys MUST be exactly: "title", "grounds", "prayerRelief", "incidentAddress", "address", "petitionType", "petitionerName", "district", "stationName".
        3. If any field is missing or empty in input, translate it as an empty string or "Not available".
        4. Ensure the translation is accurate and uses appropriate legal/formal terminology for {target_lang}.
        5. Do not include markdown code blocks (like ```json). Just the raw JSON string.
        """

        try:
            session_id = f"petition-trans-{petitioner_name or 'anon'}"
            response = await gemini_rotator.generate_content_async(
                "gemini-2.0-flash",
                prompt,
                endpoint="petition_translation",
                session_id=session_id
            )

            text = response.text.strip()
            # Clean possible markdown
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]

            return text.strip()
        except Exception as e:
            print(f"[GeminiService] Translation Failed: {e}")
            raise Exception(f"AI Generation Failed: {str(e)}")
