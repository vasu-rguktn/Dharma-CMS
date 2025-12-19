from pathlib import Path

from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from routers.complaint import router as complaint_router
from routers.ocr import router as ocr_router
# from routers.stt_stream import router as stt_router  # Uncomment when STT is ready
from routers.ocr import health_check as _ocr_health
from routers.ocr import extract_case as _ocr_extract_case
from routers.ai_investigation import router as ai_investigation_router
from routers.legal_chat import router as legal_chat_router
from routers.investigation_report import router as investigation_report_router
from routers.document_drafting import router as document_drafting_router

app = FastAPI(
    title="Police Complaint Chatbot API",
    description="Dynamic chat → formal police summary + legal classification + investigation reports",
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure static directory for generated reports exists and is mounted
reports_static_dir = Path("generated_reports") / "investigation_reports"
reports_static_dir.mkdir(parents=True, exist_ok=True)
app.mount(
    "/static/reports",
    StaticFiles(directory=str(reports_static_dir)),
    name="investigation_reports",
)

app.include_router(complaint_router)
app.include_router(ocr_router)
# STT router is currently disabled to avoid NameError in production.
# When you implement/configure STT, import and include `stt_router` above.
# app.include_router(stt_router)
app.include_router(ai_investigation_router)
app.include_router(legal_chat_router)
app.include_router(investigation_report_router)
app.include_router(document_drafting_router)


@app.get("/")
def root():
    return {"message": "Police Chatbot API running"}


@app.get("/Root")
def root_alias():
    return {"message": "Police Chatbot API running"}


@app.get("/api/health")
def api_health():
    return {"status": "ok"}


@app.get("/ocr/health")
def ocr_health_alias():
    return _ocr_health()


# Legacy compatibility: POST /extract-case/
@app.post("/extract-case/")
async def legacy_extract_case(file: UploadFile = File(...)):
    return await _ocr_extract_case(file)
