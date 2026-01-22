import google.generativeai as genai
import os
import pypdf
import io
import json
import time
from fastapi import UploadFile, HTTPException
from firebase_admin import firestore

class ChargesheetService:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY_INVESTIGATION") or os.getenv("GEMINI_API_KEY")
        if not self.api_key:
            print("WARNING: GEMINI_API_KEY_INVESTIGATION not found in ChargesheetService.")
            self.model = None
        else:
            try:
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel("gemini-2.5-flash")  # Corrected model name
                print("[ChargesheetService] Initialized with gemini-2.5-flash")
            except Exception as e:
                print(f"Error checking Gemini model: {e}")
                self.model = None
            
    async def extract_text_from_file(self, file: UploadFile) -> str:
        start_time = time.time()
        content = await file.read()
        filename = (file.filename or "").lower()
        print(f"[ChargesheetService] Extracting text from: {filename}")
        
        try:
            text = ""
            if filename.endswith('.pdf'):
                reader = pypdf.PdfReader(io.BytesIO(content))
                text = "\n".join([page.extract_text() for page in reader.pages if page.extract_text()])
                if not text.strip(): text = "[Empty PDF]"
            elif filename.endswith(('.txt', '.md')):
                text = content.decode('utf-8')
            elif filename.endswith(('.jpg', '.jpeg', '.png', '.webp')):
                # Use Gemini to extract text from image asynchronously
                if not self.model:
                    return "[Error: AI Model missing, cannot perform OCR on image]"
                prompt = "Extract all legible text from this image exactly as it appears."
                image_parts = [{"mime_type": file.content_type or "image/jpeg", "data": content}]
                response = await self.model.generate_content_async([prompt, image_parts[0]])
                text = response.text if response.text else "[No text found in image]"
            else:
                text = "[Unsupported file format. Please upload PDF, Text, or Image.]"
                
            print(f"[ChargesheetService] Extraction completed in {time.time() - start_time:.2f}s")
            return text
        except Exception as e:
            print(f"[ChargesheetService] Error extracting text from {filename}: {e}")
            return f"[Error extracting text: {str(e)}]"

    def fetch_fir_data_from_db(self, case_id: str) -> str:
        try:
            db = firestore.client()
            doc_ref = db.collection('cases').document(case_id)
            doc = doc_ref.get()
            if not doc.exists:
                raise ValueError("Case ID not found")
            
            data = doc.to_dict()
            return json.dumps(data, indent=2, default=str)
        except Exception as e:
            raise ValueError(f"Failed to fetch case data: {str(e)}")

    async def generate_draft(self, 
                             fir_text: str = None, 
                             case_id: str = None,
                             incident_text: str = None, 
                             instructions: str = None) -> str:
        
        start_time = time.time()
        print("[ChargesheetService] Starting Draft Generation...")

        # 1. Resolve FIR Content
        primary_source = ""
        source_type = ""
        if case_id:
            try:
                primary_source = self.fetch_fir_data_from_db(case_id)
                primary_source = f"FROM DATABASE RECORD (JSON):\n{primary_source}"
                source_type = "Database Case"
            except Exception as e:
                raise HTTPException(status_code=404, detail=str(e))
        elif fir_text:
            primary_source = f"FROM UPLOADED DOCUMENT:\n{fir_text}"
            source_type = "Uploaded FIR"
        else:
            raise HTTPException(status_code=400, detail="No FIR source provided (Upload or Case ID required)")

        print(f"[ChargesheetService] Source resolved: {source_type}")

        # 2. Construct Prompt (Reinforcing the flow logic requested)
        prompt = f"""
You are an expert AI Legal Assistant for the Indian Police Force.
Your task is to draft a comprehensive **Police Charge Sheet** (Final Report under Section 173 CrPC).

**STRICT PROCESS FLOW:**
1.  **Extract details ONLY from the FIR Source** below. Do not invent or add any information not present in the inputs.
2.  **Combine ONLY** with the provided **Incident/Evidence Details**. Use only details explicitly mentioned in these sources.
3.  **Apply ONLY** the **Additional Instructions** to refine the output. Do not draw from external knowledge or hallucinate facts.

**ANTI-HALLUCINATION RULES:**
- Base every piece of information in the charge sheet EXCLUSIVELY on the content from FIR Source, Incident Details, and Additional Instructions.
- If any required detail (e.g., name, date, address) is missing from the inputs, explicitly state "Information not available in provided sources" for that section.
- Do not assume, infer, or fabricate any facts, names, dates, locations, or legal sections beyond what is directly stated in the inputs.
- Stick to a factual, evidence-based narrative without adding unsubstantiated details.

**INPUT DATA:**

--- START FIR SOURCE ---
{primary_source}
--- END FIR SOURCE ---

--- START INCIDENT DETAILS ---
{incident_text if incident_text else "No specific incident details attached."}
--- END INCIDENT DETAILS ---

--- START ADDITIONAL INSTRUCTIONS ---
{instructions if instructions else "None."}
--- END ADDITIONAL INSTRUCTIONS ---

**OUTPUT REQUIREMENTS:**
*   Draft a formal Charge Sheet covering:
    *   **Accused Details**: Name, address, etc. (Only if present in inputs; otherwise, note as not available.)
    *   **Complainant Details**: Name, address, etc. (Only if present in inputs; otherwise, note as not available.)
    *   **Information on Crime**: Date, time, place, sections of law applicable (IPC/other acts). (Only if present in inputs; otherwise, note as not available.)
    *   **Investigation Narrative**: Brief facts of the case, investigation steps taken based ONLY on the incident details provided. (Do not add steps or facts not mentioned.)
    *   **Charge**: Specific offences aimed at the accused. (Only if present in inputs; otherwise, note as not available.)
*   **Tone**: Formal, legal, authoritative.
*   **Format**: Section-wise standard Police Charge Sheet.
*   **Return ONLY the draft charge sheet text.**
"""
        
        # 3. Generate asynchronously
        if not self.model:
            raise HTTPException(status_code=503, detail="AI Model not initialized (API Key missing or invalid).")

        try:
            response = await self.model.generate_content_async(prompt)
            print(f"[ChargesheetService] Generation completed in {time.time() - start_time:.2f}s")
            return response.text if response.text else "Failed to generate charge sheet (Empty response)."
        except Exception as e:
            print(f"[ChargesheetService] Generation Failed: {e}")
            raise HTTPException(status_code=500, detail=f"AI Generation Failed: {str(e)}")