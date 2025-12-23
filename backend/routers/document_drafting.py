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






from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
import os
from dotenv import load_dotenv
import google.generativeai as genai

# ───────────────── LOAD ENV ─────────────────
load_dotenv()

# Use the investigation key as requested/verified
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY_INVESTIGATION")

if not GEMINI_API_KEY:
    # Fail fast if key is missing
    print("CRITICAL: GEMINI_API_KEY_INVESTIGATION not found in env.")
    raise RuntimeError("GEMINI_API_KEY_INVESTIGATION not found environment variables")

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("models/gemini-2.5-flash")

# ───────────────── ROUTER ─────────────────
router = APIRouter(
    prefix="/api/document-drafting",
    tags=["Document Drafting"]
)

# ───────────────── MODELS ─────────────────
# strictly matching frontend camelCase JSON keys
class DraftingRequest(BaseModel):
    caseData: str
    recipientType: str
    additionalInstructions: str | None = None
    knowledgeBaseContext: str | None = None

class DraftingResponse(BaseModel):
    draft: str

# ───────────────── ENDPOINT ─────────────────
# Use empty string to avoid trailing slash redirect (which breaks CORS preflight)
@router.post("", response_model=DraftingResponse)
async def generate_document_draft(req: DraftingRequest):
    try:
        print(f"DEBUG: Processing Document Draft Request for recipient: {req.recipientType}")

        # Validate required fields
        if not req.caseData or not req.caseData.strip():
            raise HTTPException(status_code=400, detail="Case data is required")
        
        if not req.recipientType or not req.recipientType.strip():
            raise HTTPException(status_code=400, detail="Recipient type is required")
        
        # 1. Construct the detailed prompt
        # We explicitly handle the knowledge base context if present
        kb_section = ""
        if req.knowledgeBaseContext and req.knowledgeBaseContext.strip():
            kb_section = f"""
Before drafting, strictly adhere to the following internal formatting and content rules:
<knowledge_base_context>
{req.knowledgeBaseContext}
</knowledge_base_context>
"""

        prompt = f"""You are an expert legal document drafter for the Indian Police Force.
Your task is to draft a formal, professionally formatted document based on the following case details.

{kb_section}

**Case Details:**
- **Case Data:** {req.caseData}
- **Recipient/Audience:** {req.recipientType}
- **Specific Instructions:** {req.additionalInstructions or "None"}

**Formatting Requirements:**
1. **Structure:** Use clear headings, formal salutations, and professional closing.
2. **Tone:** Authoritative, objective, and legally precise.
3. **Editable:** The output should be strictly PLAIN TEXT. Do NOT use markdown formatting (no asterisks *, no hashes #, no bold/italic symbols).
4. **Dates:** Use placeholders like [DATE] if not provided.
5. **Structure:** Use clear headings, formal salutations, and a professional closing.The section titled “The brief facts of the case are detailed below:” MUST be presented as a numbered list..
6. **Signatures:** Include placeholders for [SIGNATURE] and [RANK/NAME].

Draft the document now:
"""

        # 2. Call Gemini API
        try:
            response = model.generate_content(prompt)
        except Exception as gemini_error:
            print(f"Gemini API Error: {str(gemini_error)}")
            raise HTTPException(
                status_code=503,
                detail=f"AI service unavailable: {str(gemini_error)}"
            )
        
        # 3. Handle Empty/Error Response
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
        
        # 4. Return Success
        return DraftingResponse(draft=draft_text)

    except HTTPException:
        # Re-raise HTTP exceptions as-is
        raise
    except Exception as e:
        print(f"CRITICAL ERROR in document-drafting: {str(e)}")
        print(f"Error type: {type(e).__name__}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Draft generation failed: {str(e)}"
        )