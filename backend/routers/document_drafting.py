# from fastapi import APIRouter, HTTPException, Request
# from pydantic import BaseModel
# import os
# from dotenv import load_dotenv
# import google.generativeai as genai

# # ───────────────── LOAD ENV ─────────────────
# load_dotenv()

# # Use the investigation key as requested/verified
# GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_INVESTIGATION")

# if not GEMINI_API_KEY:
#     # Fail fast if key is missing
#     print("CRITICAL: GEMINI_API_KEY_INVESTIGATION not found in env.")
#     raise RuntimeError("GEMINI_API_KEY_INVESTIGATION not found environment variables")

# genai.configure(api_key=GEMINI_API_KEY)
# model = genai.GenerativeModel("gemini-2.5-flash")

# # ───────────────── ROUTER ─────────────────
# router = APIRouter(
#     prefix="/api/document-drafting",
#     tags=["Document Drafting"]
# )

# # ───────────────── MODELS ─────────────────
# # strictly matching frontend camelCase JSON keys
# class DraftingRequest(BaseModel):
#     caseData: str
#     recipientType: str
#     additionalInstructions: str | None = None
#     knowledgeBaseContext: str | None = None

# class DraftingResponse(BaseModel):
#     draft: str

# # ───────────────── ENDPOINT ─────────────────
# @router.post("", response_model=DraftingResponse)
# async def generate_document_draft(req: DraftingRequest):
#     try:
#         print(f"DEBUG: Processing Document Draft Request for recipient: {req.recipientType}")
        
#         # 1. Construct the detailed prompt
#         # We explicitly handle the knowledge base context if present
#         kb_section = ""
#         if req.knowledgeBaseContext:
#             kb_section = f"""
# Before drafting, strictly adhere to the following internal formatting and content rules:
# <knowledge_base_context>
# {req.knowledgeBaseContext}
# </knowledge_base_context>
# """

#         prompt = f"""You are an expert legal document drafter for the Indian Police Force.
# Your task is to draft a formal, professionally formatted document based on the following case details.

# {kb_section}

# **Case Details:**
# - **Case Data:** {req.caseData}
# - **Recipient/Audience:** {req.recipientType}
# - **Specific Instructions:** {req.additionalInstructions or "None"}

# **Formatting Requirements:**
# 1. **Structure:** Use clear headings, formal salutations, and professional closing.
# 2. **Tone:** Authoritative, objective, and legally precise.
# 3. **Editable:** The output should be plain text suitable for insertion into a formal editor.
# 4. **Dates:** Use placeholders like [DATE] if not provided.
# 5. **Signatures:** Include placeholders for [SIGNATURE] and [RANK/NAME].

# Draft the document now:
# """

#         # 2. Call Gemini API
#         response = model.generate_content(prompt)
        
#         # 3. Handle Empty/Error Response
#         if not response.text:
#             raise ValueError("Empty response received from AI model.")
            
#         draft_text = response.text.strip()
        
#         # 4. Return Success
#         return DraftingResponse(draft=draft_text)

#     except Exception as e:
#         print(f"CRITICAL ERROR in document-drafting: {str(e)}")
#         raise HTTPException(status_code=500, detail=f"Draft generation failed: {str(e)}")






from fastapi import APIRouter, HTTPException, Request, UploadFile, File, Form
from pydantic import BaseModel
import os
from dotenv import load_dotenv
import google.generativeai as genai
import time
import asyncio
import base64
import json
import traceback

# ───────────────── LOAD ENV ─────────────────
load_dotenv()

# Use the investigation key as requested/verified
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_INVESTIGATION")

if not GEMINI_API_KEY:
    # Fail fast if key is missing
    print("CRITICAL: GEMINI_API_KEY_INVESTIGATION not found in env.")
    raise RuntimeError("GEMINI_API_KEY_INVESTIGATION not found environment variables")

genai.configure(api_key=GEMINI_API_KEY)
# We use the same model for drafting and generic OCR here
model = genai.GenerativeModel("models/gemini-2.5-flash")

# ───────────────── ROUTER ─────────────────
router = APIRouter(
    prefix="/api/document-drafting",
    tags=["Document Drafting"]
)

# ───────────────── MODELS ─────────────────
# Response model remains the same
class DraftingResponse(BaseModel):
    draft: str
    extractedText: str | None = None

# ───────────────── UTILS ─────────────────
async def _extract_text_gemini(image_bytes: bytes, mime_type: str) -> str:
    """
    Extracts text from an image/file using Gemini Flash.
    Duplicated locally to avoid circular dependencies with ocr router.
    """
    encoded = base64.b64encode(image_bytes).decode("utf-8")
    
    # Prompt for OCR
    prompt_ocr = "Extract all readable text from this document image. Return only the plain extracted text."

    try:
        # We can reuse the global 'model' variable initialized above
        response = await asyncio.to_thread(
            model.generate_content,
            [
                {"inline_data": {"mime_type": mime_type, "data": encoded}},
                prompt_ocr,
            ],
        )
        return (response.text or "").strip()
    except Exception as e:
        print(f"OCR Error in document drafting: {str(e)}")
        # For drafting, if OCR fails, we just warn but don't crash proper
        return f"[Error extracting text from document: {str(e)}]"

def _guess_mime_type(filename: str) -> str:
    ext = filename.lower().split(".")[-1]
    return {
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "png": "image/png",
        "webp": "image/webp",
        "pdf": "application/pdf", # Gemini supports PDF
    }.get(ext, "application/octet-stream")


# ───────────────── ENDPOINT ─────────────────
@router.post("", response_model=DraftingResponse)
async def generate_document_draft(
    caseData: str = Form(...),
    recipientType: str = Form(...),
    additionalInstructions: str | None = Form(None),
    knowledgeBaseContext: str | None = Form(None),
    file: UploadFile = File(None)
):
    try:
        print(f"DEBUG: Processing Document Draft Request for recipient: {recipientType}")
        
        extracted_text = ""
        file_context = ""

        # 1. Process File if Present
        if file:
            print(f"DEBUG: Processing uploaded file: {file.filename}")
            try:
                contents = await file.read()
                mime_type = file.content_type or _guess_mime_type(file.filename or "")
                
                # Basic size check (10MB limit)
                if len(contents) > 10 * 1024 * 1024:
                    raise HTTPException(status_code=400, detail="File too large (max 10MB)")

                extracted_text = await _extract_text_gemini(contents, mime_type)
                
                if extracted_text:
                    file_context = f"""
**Extracted Content from Uploaded Document:**
{extracted_text}
"""
            except Exception as e:
                print(f"File processing error: {e}")
                traceback.print_exc()
                # Continue without file content if it fails, but maybe appending error note
                file_context = f"**[Error processing uploaded file: {str(e)}]**"

        # 2. Construct prompt
        kb_section = ""
        if knowledgeBaseContext and knowledgeBaseContext.strip():
            kb_section = f"""
Before drafting, strictly adhere to the following internal formatting and content rules:
<knowledge_base_context>
{knowledgeBaseContext}
</knowledge_base_context>
"""

        prompt = f"""You are an expert legal document drafter for the Indian Police Force.
Your task is to draft a formal, professionally formatted document based on the following case details and provided documents.

{kb_section}

**Case Details:**
- **Case Data:** {caseData}
- **Recipient/Audience:** {recipientType}
- **Specific Instructions:** {additionalInstructions or "None"}

{file_context}

**Formatting Requirements:**
1. **Structure:** Use clear headings, formal salutations, and professional closing.
2. **Tone:** Authoritative, objective, and legally precise.
3. **Editable:** The output should be strictly PLAIN TEXT. Do NOT use markdown formatting (no asterisks *, no hashes #, no bold/italic symbols).
4. **Dates:** Use placeholders like [DATE] if not provided.
5. **Structure:** The section titled “The brief facts of the case are detailed below:” MUST be presented as a numbered list.
6. **Signatures:** Include placeholders for [SIGNATURE] and [RANK/NAME].

Draft the document now:
"""

        # 3. Call Gemini API
        try:
            response = model.generate_content(prompt)
        except Exception as gemini_error:
            print(f"Gemini API Error: {str(gemini_error)}")
            raise HTTPException(
                status_code=503,
                detail=f"AI service unavailable: {str(gemini_error)}"
            )
        
        # 4. Handle Response
        if not response or not hasattr(response, 'text') or not response.text:
            raise HTTPException(
                status_code=502,
                detail="Empty or invalid response received from AI model"
            )
            
        draft_text = response.text.strip()
        
        if not draft_text:
            raise HTTPException(
                status_code=502,
                detail="AI model returned empty content"
            )
        
        return DraftingResponse(
            draft=draft_text,
            extractedText=extracted_text if extracted_text else None
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"CRITICAL ERROR in document-drafting: {str(e)}")
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Draft generation failed: {str(e)}"
        )