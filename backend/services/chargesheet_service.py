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

        # 2. Construct Prompt (Diligent Police Assistant Persona)
        prompt = f"""
You are a diligent and experienced police/prosecution assistant. Your task is to generate a complete, comprehensive **chargesheet** for submission to the magistrate, following the provided **format** and focusing on presenting a robust case against the accused(s) based on the information from the uploaded documents and any additional instructions.

The chargesheet must:
✅ **Align with the standard format** and include all mandatory sections such as details of the accused, complainant, witnesses, properties seized, final investigation findings, and relevant legal provisions.
✅ **Highlight the factual narrative** of the crime in a logical and structured manner.
✅ **Connect each piece of evidence to the corresponding accused** and explain how the evidence supports the charges.
✅ Clearly specify:
- Which legal provisions are invoked and why.
- How the investigation was conducted and what evidence was gathered.
- The roles of the complainant, witnesses, and investigating officer.
✅ **Avoid assumptions**—include only facts and evidence found within the provided documents.
✅ **Draft with clarity and professionalism** to present a persuasive case before the court.

Here are the documents provided for this case. Synthesize all information from them:

--- START FIR SOURCE ---
{primary_source}
--- END FIR SOURCE ---

--- START INCIDENT DETAILS ---
{incident_text if incident_text else "No specific incident details attached."}
--- END INCIDENT DETAILS ---

--- START ADDITIONAL INSTRUCTIONS ---
{instructions if instructions else "None."}
--- END ADDITIONAL INSTRUCTIONS ---

Now, based on ALL the information from the documents and any additional instructions, generate the chargesheet strictly following this format. If information for a specific field is not found in the provided materials, write "Not available" or leave it blank as appropriate for that field in the format.

---
**CHARGE SHEET / FINAL REPORT**
**(Under Section 173 Cr.P.C.)**

**A.P.P.M. Order No:** 480-1,480-2,481,482,487 & 609-5 (U/S 173 Cr.P.C)
**IN THE COURT OF HONOURABLE Principal Civil Judge(Jr Dv) Court**
1. District: [Extract from documents or state "Not available"]
2. Final Report / Charge Sheet No: [Extract from documents or state "Not available"]
3. FIR No: [Extract from documents or state "Not available"]
4. Date: [Date of chargesheet generation, or extract if specified in documents. Format: YYYY-MM-DD]
5. P.S: [Extract from documents or state "Not available"]
6. Acts & Sections: [Extract all relevant acts and sections from documents and summarize them. Be specific.]
7. Type of Final Report: [e.g., Charge Sheet, Final Report Referred, etc. Extract or infer from documents, or state "Charge Sheet"]
8. Name of I.O.: [Name of Investigating Officer. Extract from documents or state "Not available"]
9. Name of complainant/informant: [Extract from documents or state "Not available"]
10. Details of properties/articles/documents recovered/seized and relied upon: [List all items with descriptions. Extract from documents or state "Not available"]
11. Particulars of accused charge-sheeted:
   [For each accused, provide:
   - Name:
   - Father's name:
   - Address:
   - Occupation:
   - Date of birth/Age:
   - Caste:
   - Previous convictions (if any):
   - Date of arrest:
   - Date of forwarding to court:
   - Specific Acts & Sections charged under for this accused:
   Extract all these details from the documents for each accused. If multiple accused, list them sequentially. If any detail is missing, state "Not available" for that specific detail.]
12. Particulars of accused not charge-sheeted (if any): [Extract from documents or state "Not applicable" or "Not available"]
13. Particulars of witnesses to be examined:
   [For each witness, provide:
   - Name:
   - Father's name:
   - Address:
   - Type of evidence (e.g., eye-witness, circumstantial, medical, expert, police, etc.):
   Extract all these details from the documents for each witness. List them sequentially.]
14. Details of medical examination, chemical analysis reports, and laboratory analysis: [Summarize findings from any relevant reports found in the documents. Include report numbers and dates if available. Or state "Not available" or "Not applicable".]
15. Summary of Investigation:
   - **Detailed factual narrative of the crime**: [Synthesize from all documents a chronological and factual account of what happened.]
   - **How the investigation was conducted**: [Describe the steps taken by the IO as found in the documents.]
   - **What evidence was gathered**: [List and briefly describe all key pieces of evidence.]
   - **How the accused was identified and apprehended**: [Detail the process from the documents.]
   - **Linkage between each piece of evidence and each accused**: [Crucial: Explain how specific evidence points to the involvement of each accused person.]
   - **Analysis of witness statements and corroborating evidence**: [Summarize key witness testimonies and how they support the case or are corroborated.]
   - **Clear legal justification for each charge**: [Explain why the chosen acts and sections are applicable based on the evidence and facts.]
16. Conclusion:
   - **Summarize why the charges are substantiated**: [Provide a concise summary of the overall case against the accused.]
   - **How the evidence forms a chain of events proving the accused’s guilt**: [Explain the linkage if a clear chain exists.]
   - **Mention if any further investigation is pending**: [Extract from documents or state "Investigation complete" or "Further investigation is pending regarding..."]
17. Final recommendation and forwarding for prosecution: [State clearly: "It is therefore prayed that the accused [Name(s) of accused] may be tried for the aforementioned offenses." or similar formal statement.]

---
**CRITICAL INSTRUCTIONS FOR AI:**
- **Use clear, formal, and direct language** suitable for official court submission.
- **Be meticulous**: No missing sections from the format above. If data is unavailable, state "Not available".
- **Ensure consistency**: All details (like names, dates) must match throughout the document and be sourced from the provided materials.
- **Highlight how the investigation upholds the law and protects victims’ rights**.
- **Present the chargesheet as a strong, logical, evidence-backed case** to maximize the chance of conviction.

**Provide the final chargesheet as a structured, formatted text ready for submission to the Hon’ble Court.**
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