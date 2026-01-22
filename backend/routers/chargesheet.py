from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse
from typing import Optional
from services.chargesheet_service import ChargesheetService

router = APIRouter(
    prefix="/api/chargesheet-generation",
    tags=["Chargesheet Generation"]
)

# Initialize Service
service = ChargesheetService()

@router.post("")
async def generate_chargesheet(
    fir_document: Optional[UploadFile] = File(None),
    case_id: Optional[str] = Form(None),
    incident_details_file: Optional[UploadFile] = File(None),
    incident_details_text: Optional[str] = Form(None),
    additional_instructions: Optional[str] = Form(None)
):
    try:
        # Validate Inputs: Need either File OR Case ID
        if not fir_document and not case_id:
            raise HTTPException(status_code=400, detail="Either FIR Document upload or Case ID is required.")

        # 1. Extract content
        fir_text = None
        if fir_document:
            fir_text = await service.extract_text_from_file(fir_document)
            
        incident_text = ""
        if incident_details_file:
            incident_text += await service.extract_text_from_file(incident_details_file)
        
        if incident_details_text and incident_details_text.strip():
            if incident_text:
                incident_text += "\n\n"
            incident_text += incident_details_text.strip()
            
        # 2. Call Service
        draft = await service.generate_draft(
            fir_text=fir_text,
            case_id=case_id,
            incident_text=incident_text,
            instructions=additional_instructions
        )
        
        return JSONResponse(content={"chargeSheet": draft})
        
    except HTTPException as he:
        raise he
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
