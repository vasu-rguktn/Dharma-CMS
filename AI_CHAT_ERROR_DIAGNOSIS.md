# AI Legal Chat Backend Error - Diagnostic Report

## Problem Summary
The AI Legal Chat feature is returning an error: **"Sorry, something went wrong. Please try again later."**

Based on the screenshot and code analysis, the backend `/complaint/chat-step` endpoint is failing.

## Root Cause Analysis

### **Issue: Missing HF_TOKEN Environment Variable in Cloud Run Deployment**

The backend code requires a `HF_TOKEN` (Hugging Face API token) to access the LLM (Large Language Model) for AI-powered chat interactions.

**Evidence:**
1. **Backend Code** (`backend/routers/complaint.py` line 1264-1266):
```python
if not HF_TOKEN:
    # Fallback
    return ChatStepResponse(status="done", final_response=None)
```

2. **Environment Variable Loading** (`backend/routers/complaint.py` line 30):
```python
HF_TOKEN = os.getenv("HF_TOKEN")
```

3. **Deployment URL**: `https://fastapi-app-335340524683.asia-south1.run.app`
   - This is a Google Cloud Run deployment
   - Environment variables must be configured in Cloud Run settings

## Diagnosis: Code Issue vs Deployment Issue

**Answer: This is a DEPLOYMENT ISSUE, not a code issue.**

The code is correct and has proper error handling. However, the `HF_TOKEN` environment variable is not set in the Cloud Run deployment, causing the LLM API calls to fail.

## How the Error Occurs

1. User sends a message in the AI Legal Chat
2. Frontend calls: `POST https://fastapi-app-335340524683.asia-south1.run.app/complaint/chat-step`
3. Backend checks for `HF_TOKEN` (line 1264)
4. If `HF_TOKEN` is missing:
   - Returns early with `status="done"` and `final_response=None`
   - OR the LLM API call fails with authentication error
5. Frontend receives error response
6. Frontend catch block (line 306-328 in `ai_legal_chat_screen.dart`) displays:
   - "Sorry, something went wrong. Please try again later."

## Solution

### Option 1: Set HF_TOKEN in Cloud Run (Recommended)

1. **Get a Hugging Face API Token:**
   - Go to https://huggingface.co/settings/tokens
   - Create a new token with read access
   - Copy the token

2. **Configure Cloud Run Environment Variable:**
   ```bash
   gcloud run services update fastapi-app-335340524683 \
     --region=asia-south1 \
     --set-env-vars="HF_TOKEN=your_huggingface_token_here"
   ```

   **OR via Google Cloud Console:**
   - Go to Cloud Run → Select your service
   - Click "EDIT & DEPLOY NEW REVISION"
   - Go to "Variables & Secrets" tab
   - Add environment variable:
     - Name: `HF_TOKEN`
     - Value: `your_huggingface_token_here`
   - Click "DEPLOY"

### Option 2: Use Local Backend for Testing

If you want to test locally with the token:

1. Create a `.env` file in `backend/` directory:
```env
HF_TOKEN=your_huggingface_token_here
GEMINI_API_KEY=your_gemini_key_here
```

2. Run backend locally:
```bash
cd backend
uvicorn main:app --reload --port 8080
```

3. Update frontend to use local backend:
   - Change `baseUrl` in `ai_legal_chat_screen.dart` line 247-253 to `http://localhost:8080`

## Additional Checks

### Check if HF_TOKEN is Set in Cloud Run

Run this command to check current environment variables:
```bash
gcloud run services describe fastapi-app-335340524683 \
  --region=asia-south1 \
  --format="value(spec.template.spec.containers[0].env)"
```

### Check Backend Logs

View Cloud Run logs to see the actual error:
```bash
gcloud run services logs read fastapi-app-335340524683 \
  --region=asia-south1 \
  --limit=50
```

Look for error messages like:
- "Chat step failed: ..."
- "LLM Reply: ..."
- Authentication errors from Hugging Face API

## Expected Behavior After Fix

Once `HF_TOKEN` is properly set:

1. User sends message: "yah group off persons for power playing cards with a bitting in a public place causing public nuisance the act is illegal and punishable under gaming glass gambling glass a group of persons were called playing cards with betting in a public place causing news sense the active illegal and punishable under gambling laws"

2. Backend LLM processes the complaint and asks follow-up questions like:
   - "When did this incident occur?"
   - "Where exactly did this happen?"
   - "Do you have any evidence or witnesses?"

3. After collecting sufficient details, backend generates formal summary and classification

4. User sees proper AI responses instead of error messages

## Code Quality Assessment

✅ **Code is well-structured:**
- Proper error handling with try-catch blocks
- Fallback mechanisms when HF_TOKEN is missing
- Clear logging with `logger.info()` and `logger.error()`
- Validation for user inputs (name, phone, address)

✅ **No code changes needed** - the issue is purely deployment configuration

## Recommended Next Steps

1. **Immediate:** Set `HF_TOKEN` in Cloud Run environment variables
2. **Verify:** Test the AI chat feature after deployment
3. **Monitor:** Check Cloud Run logs to ensure LLM calls are successful
4. **Optional:** Add better error messages in frontend to distinguish between:
   - Missing API token (deployment issue)
   - LLM API failures (service issue)
   - Network errors (connectivity issue)

## Related Files

- **Backend:** `backend/routers/complaint.py` (lines 1184-1480)
- **Frontend:** `frontend/lib/screens/ai_legal_chat_screen.dart` (lines 234-329)
- **Deployment:** Cloud Run service `fastapi-app-335340524683` in `asia-south1`
- **Environment:** `backend/docker-compose.yml` (line 21)

## Summary

**Problem:** AI chat fails with generic error message  
**Root Cause:** Missing `HF_TOKEN` environment variable in Cloud Run deployment  
**Solution:** Configure `HF_TOKEN` in Cloud Run service settings  
**Type:** Deployment Issue (not code issue)  
**Priority:** High (feature is completely non-functional without the token)
