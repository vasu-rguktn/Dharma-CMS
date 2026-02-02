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
from routers.chargesheet import router as chargesheet_router
from routers.document_drafting import router as document_drafting_router
from routers.image_lab.image_enhancement import router as image_enhancement_router
from routers.image_lab.anpr import router as anpr_router

import firebase_admin
from firebase_admin import credentials
from routers.legal_suggestions import router as legal_suggester_router
from routers.image_lab.person_router import router as person_router
from routers.chargesheet_vetting import router as chargesheet_vetting_router
from routers.document_relevance import router as document_relevance_router


# Initialize Firebase Admin SDK
try:
    # Check for service account key file
    cred_filename = "dharma-cms-5cc89-b74e10595572.json"
    cred_path = Path(__file__).parent / cred_filename
    
    if cred_path.exists():
        cred = credentials.Certificate(str(cred_path))
        firebase_admin.initialize_app(cred)
        print(f"Firebase Admin initialized with {cred_filename}")
    else:
        # Fallback to default (env var) if file not found locally
        firebase_admin.initialize_app()
        print("Firebase Admin initialized with default credentials")
except ValueError:
    pass # Likely already initialized

app = FastAPI(
    title="Police Complaint Chatbot API",
    description="Dynamic chat → formal police summary + legal classification + investigation reports",
    version="1.1.0",
    redirect_slashes=False,  # Disable trailing slash redirects to prevent CORS preflight issues
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,  # Cache preflight requests for 1 hour
)

# Ensure static directory for generated reports exists and is mounted
reports_static_dir = Path("generated_reports") / "investigation_reports"
reports_static_dir.mkdir(parents=True, exist_ok=True)
app.mount(
    "/static/reports",
    StaticFiles(directory=str(reports_static_dir)),
    name="investigation_reports",
)

# Serve ANPR processed videos
videos_dir = Path("temp_videos")
videos_dir.mkdir(exist_ok=True)
app.mount(
    "/static/anpr_videos",
    StaticFiles(directory=str(videos_dir)),
    name="anpr_videos",
)

# Serve Detected Persons
persons_dir = Path("storage/persons")
persons_dir.mkdir(parents=True, exist_ok=True)
app.mount(
    "/static/persons",
    StaticFiles(directory=str(persons_dir)),
    name="persons",
)

app.include_router(complaint_router)
app.include_router(ocr_router)
# STT router is currently disabled to avoid NameError in production.
# When you implement/configure STT, import and include `stt_router` above.
# app.include_router(stt_router)
app.include_router(ai_investigation_router)
app.include_router(legal_chat_router)
app.include_router(investigation_report_router)
app.include_router(chargesheet_router)
app.include_router(document_drafting_router)
app.include_router(image_enhancement_router)
app.include_router(anpr_router)

app.include_router(legal_suggester_router)
app.include_router(person_router)
app.include_router(chargesheet_vetting_router)
from routers.cases import router as cases_router
app.include_router(cases_router)
app.include_router(document_relevance_router)

from routers.case_lookup import router as case_lookup_router
app.include_router(case_lookup_router)

from routers.fcm import router as fcm_router
app.include_router(fcm_router)

from routers.petition_updates import router as petition_updates_router
app.include_router(petition_updates_router)


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



#app.include_router(anpr_router)