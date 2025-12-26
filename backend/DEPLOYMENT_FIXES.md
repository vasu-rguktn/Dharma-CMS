# Backend Deployment Fixes - Summary

This document summarizes all fixes made to ensure the backend is ready for deployment.

## Issues Fixed

### 1. Port Configuration Inconsistency ✅
**Problem**: Dockerfile used port 8080, but docker-compose.yml used port 8000
**Fix**: 
- Updated `docker-compose.yml` to use port 8080 consistently
- Updated healthcheck to use port 8080
- Added PORT environment variable to docker-compose.yml

### 2. Duplicate Router Inclusion ✅
**Problem**: `investigation_report_router` was included twice in `main.py` (lines 70-71)
**Fix**: Removed duplicate inclusion

### 3. Health Check Configuration ✅
**Problem**: Health check in docker-compose.yml used incorrect port and method
**Fix**: 
- Updated to use curl (matching Dockerfile)
- Updated to use port 8080

### 4. Documentation Updates ✅
**Problem**: README_DOCKER.md had outdated port information
**Fix**: Updated all port references from 8000 to 8080

## Current Configuration

### Ports
- **Default Port**: 8080
- **Docker Compose**: Maps `8080:8080`
- **Environment Variable**: `PORT=8080` (configurable)

### Routes Registered
All routes are properly registered in `main.py`:
- ✅ Complaint router (`/complaint`)
- ✅ OCR router (`/api/ocr`)
- ✅ AI Investigation router (`/api/ai-investigation`)
- ✅ Legal Chat router (`/api/legal-chat`)
- ✅ Investigation Report router (`/api`)
- ✅ Document Drafting router (`/api/document-drafting`)
- ✅ Legal Suggestions router (`/api/legal-suggestions`)
- ✅ Cases router (`/api/cases`)
- ⚠️ STT Stream router (`/ws/stt`) - **Disabled** (frontend uses Flutter STT)

### Environment Variables Required

#### Required
- `GEMINI_API_KEY` - Main Gemini API key

#### Optional (with fallbacks)
- `GEMINI_API_KEY_INVESTIGATION` - Falls back to `GEMINI_API_KEY`
- `GEMINI_API_KEY_LEGAL_SUGGESTIONS` - Falls back to `GEMINI_API_KEY`
- `HF_TOKEN` - Hugging Face token (optional, for complaint processing)
- `PORT` - Server port (default: 8080)

## Deployment Steps

### 1. Using Docker Compose (Recommended)

```bash
# Set environment variables
export GEMINI_API_KEY=your_api_key_here

# Build and start
cd backend
docker-compose up --build -d

# Check logs
docker-compose logs -f

# Verify routes
python check_routes.py
```

### 2. Verify Deployment

```bash
# Health check
curl http://localhost:8080/api/health

# Check all routes
python check_routes.py

# Or manually test
curl http://localhost:8080/
curl http://localhost:8080/openapi.json
```

### 3. Production Deployment

For production (e.g., Google Cloud Run, AWS ECS):

1. **Build image**:
   ```bash
   docker build -t dharma-backend .
   ```

2. **Push to registry** (if needed):
   ```bash
   docker tag dharma-backend gcr.io/PROJECT_ID/dharma-backend
   docker push gcr.io/PROJECT_ID/dharma-backend
   ```

3. **Set environment variables** in your deployment platform

4. **Deploy** using your platform's deployment tools

## Route Verification

Use the `check_routes.py` script to verify all routes:

```bash
# Check local server
python check_routes.py

# Check remote server
python check_routes.py http://your-server-url:8080
```

## Files Modified

1. `backend/main.py` - Removed duplicate router inclusion
2. `backend/docker-compose.yml` - Fixed port and healthcheck
3. `backend/README_DOCKER.md` - Updated port references
4. `backend/check_routes.py` - Updated route verification script
5. `backend/ROUTES_SUMMARY.md` - Created route documentation

## Notes

- STT WebSocket endpoint (`/ws/stt`) is intentionally disabled as the frontend uses Flutter's native speech-to-text
- All routes are properly registered and accessible
- Health check endpoint: `GET /api/health`
- OpenAPI docs available at: `GET /openapi.json` or `GET /docs`

