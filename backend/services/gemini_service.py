import google.generativeai as genai
import os
import time

class GeminiService:
    def __init__(self):
        # Prefer the generic key, fallback to investigation key if needed
        self.api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GEMINI_API_KEY_INVESTIGATION")
        if not self.api_key:
            print("[GeminiService] WARNING: GEMINI_API_KEY not found.")
            self.model = None
        else:
            try:
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel("gemini-2.0-flash")
                print("[GeminiService] Initialized with gemini-2.0-flash")
            except Exception as e:
                print(f"[GeminiService] Error initializing model: {e}")
                self.model = None

    async def translate_petition(self, title: str, grounds: str, prayer: str, incident_address: str, address: str, petition_type: str, petitioner_name: str, district: str, station_name: str, target_lang: str) -> str:
        if not self.model:
            raise Exception("AI Model not initialized (API Key missing or invalid).")
        
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
            response = await self.model.generate_content_async(prompt)
            print(f"[GeminiService] Translation completed in {time.time() - start_time:.2f}s")
            
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
