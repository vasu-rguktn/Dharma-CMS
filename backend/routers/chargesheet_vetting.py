from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import os
from dotenv import load_dotenv
import google.generativeai as genai
from typing import Optional

# ───────────────── LOAD ENV ─────────────────
load_dotenv()

# Use the vetting-specific key, fallback to investigation key, then main key
GEMINI_API_KEY = os.getenv("GEMINI_KEY_VETTING") or os.getenv("GEMINI_API_KEY_INVESTIGATION") or os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    print("CRITICAL: GEMINI_KEY_VETTING, GEMINI_API_KEY_INVESTIGATION, or GEMINI_API_KEY not found in env.")
    raise RuntimeError("GEMINI_KEY_VETTING, GEMINI_API_KEY_INVESTIGATION, or GEMINI_API_KEY not found in environment variables")

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("models/gemini-2.5-flash")

# ───────────────── ROUTER ─────────────────
router = APIRouter(
    prefix="/api/chargesheet-vetting",
    tags=["Chargesheet Vetting"]
)

# ───────────────── MODELS ─────────────────
# Matching frontend camelCase JSON keys
class ChargesheetVettingRequest(BaseModel):
    chargesheet: str
    knowledgeBaseContext: Optional[str] = None

class ChargesheetVettingResponse(BaseModel):
    suggestions: str

# ───────────────── SYSTEM PROMPT ─────────────────
SYSTEM_PROMPT = """You are an expert legal consultant specializing in charge sheet vetting for the Indian Police Force.

Your task is to review the provided charge sheet and provide suggestions for improvement to strengthen the case and improve the chances of conviction.

CRITICAL RULES:
1. Analyze the charge sheet thoroughly for:
   - Legal accuracy and completeness
   - Missing evidence or facts
   - Weak arguments that need strengthening
   - Procedural gaps
   - Section applicability under new Indian laws (BNS, BNSS, BSA)
   - Clarity and coherence of facts

2. Provide constructive, actionable suggestions that:
   - Identify specific weaknesses
   - Recommend concrete improvements
   - Suggest additional evidence or documentation if needed
   - Enhance legal arguments
   - Ensure compliance with legal procedures

3. Format your response as clear, professional suggestions that can be directly used by legal professionals.

4. If the charge sheet is well-drafted, acknowledge strengths while still providing minor improvement suggestions.

5. Focus on practical, implementable recommendations.
"""

# ───────────────── ENDPOINT ─────────────────
@router.post("", response_model=ChargesheetVettingResponse)
async def vet_chargesheet(req: ChargesheetVettingRequest):
    try:
        # Validate required fields
        if not req.chargesheet or not req.chargesheet.strip():
            raise HTTPException(status_code=400, detail="Charge sheet content is required")

        chargesheet_content = req.chargesheet.strip()

        # If knowledge base context is provided directly (from frontend), use it
        context_block = ""
        if req.knowledgeBaseContext and req.knowledgeBaseContext.strip():
            context_block = f"""
Before formulating your response, consult the following relevant information retrieved from our internal knowledge base. This information (e.g., common charge sheet deficiencies, examples of strong arguments, relevant legal points) should be prioritized and used to ensure your vetting suggestions are thorough and insightful:
<knowledge_base_context>
{req.knowledgeBaseContext}
</knowledge_base_context>
Always critically evaluate the knowledge base context against the specific charge sheet provided.
"""

        # Construct the prompt
        prompt = f"""{SYSTEM_PROMPT}
{context_block}

**Charge Sheet to Review:**
{chargesheet_content}

Please provide your vetting suggestions now:
"""

        # Call Gemini API
        try:
            response = model.generate_content(prompt)
        except Exception as gemini_error:
            error_msg = str(gemini_error)
            print(f"Gemini API Error: {error_msg}")
            import traceback
            traceback.print_exc()
            # Return more user-friendly error message
            raise HTTPException(
                status_code=503,
                detail=f"AI service unavailable. Please check backend logs for details. Error: {error_msg[:200]}"
            )

        # Handle Empty/Error Response
        if not response or not hasattr(response, 'text') or not response.text:
            raise HTTPException(
                status_code=502,
                detail="Empty or invalid response received from AI model"
            )

        suggestions_text = response.text.strip()

        if not suggestions_text:
            raise HTTPException(
                status_code=502,
                detail="AI model returned empty content"
            )

        # Return Success
        return ChargesheetVettingResponse(suggestions=suggestions_text)

    except HTTPException:
        # Re-raise HTTP exceptions as-is
        raise
    except Exception as e:
        print(f"CRITICAL ERROR in chargesheet-vetting: {str(e)}")
        print(f"Error type: {type(e).__name__}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Charge sheet vetting failed: {str(e)}"
        )
