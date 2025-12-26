# Backend Routes Summary

This document lists all available routes in the Dharma CMS backend API.

## Base Routes

- `GET /` - Root endpoint
- `GET /Root` - Root alias
- `GET /api/health` - Health check endpoint
- `GET /ocr/health` - OCR health check alias

## Router Prefixes and Routes

### 1. Complaint Router (`/complaint`)
- `POST /complaint/summarize` - Process and summarize complaint

### 2. OCR Router (`/api/ocr`)
- `GET /api/ocr/health` - OCR health check
- `POST /api/ocr/extract` - Extract text from image
- `POST /api/ocr/extract-case/` - Extract case information from document

### 3. Legacy OCR Routes
- `POST /extract-case/` - Legacy compatibility endpoint for case extraction

### 4. AI Investigation Router (`/api/ai-investigation`)
- `POST /api/ai-investigation/` - Generate AI investigation guidelines

### 5. Legal Chat Router (`/api/legal-chat`)
- `POST /api/legal-chat/` - Legal chat endpoint

### 6. Investigation Report Router (`/api`)
- `POST /api/generate-investigation-report` - Generate investigation report PDF

### 7. Document Drafting Router (`/api/document-drafting`)
- `POST /api/document-drafting` - Draft legal documents

### 8. Legal Suggestions Router (`/api/legal-suggestions`)
- `POST /api/legal-suggestions/` - Get legal section suggestions

### 9. Cases Router (`/api/cases`)
- `POST /api/cases/create` - Create a new case

### 10. Static Files
- `GET /static/reports/*` - Serve generated investigation report PDFs

## WebSocket Routes (Currently Disabled)

- `WS /ws/stt` - Speech-to-text WebSocket (disabled - frontend uses Flutter STT)

## Environment Variables Required

- `GEMINI_API_KEY` - Main Gemini API key
- `GEMINI_API_KEY_INVESTIGATION` - Investigation-specific Gemini API key
- `GEMINI_API_KEY_LEGAL_SUGGESTIONS` - Legal suggestions Gemini API key
- `HF_TOKEN` - Hugging Face token (optional, for complaint processing)

## Port Configuration

- Default port: `8080` (configurable via `PORT` environment variable)
- Docker Compose maps: `8080:8080`
- Health check endpoint: `http://localhost:8080/api/health`

