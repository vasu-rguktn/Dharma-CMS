from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from routers.complaint import router as complaint_router
from routers.ocr import router as ocr_router
from routers.stt_stream import router as stt_router
from routers.ocr import health_check as _ocr_health
from routers.ocr import extract_case as _ocr_extract_case

app = FastAPI(
    title="Police Complaint Chatbot API",
    description="Dynamic chat → formal police summary + legal classification",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(complaint_router)
app.include_router(ocr_router)
app.include_router(stt_router)

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
