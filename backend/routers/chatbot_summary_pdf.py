import os
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException
from loguru import logger
from pydantic import BaseModel, Field

# Determine base URL for QR codes (where the PDF will be hosted)
# In production, this should be the actual domain.
# For local dev, we might need a way to find the IP, but usually the client knows the base URL.
# We will return a relative URL, and let the client prepend the base URL.

router = APIRouter(prefix="/api", tags=["chatbot-summary-pdf"])

class ChatbotSummaryRequest(BaseModel):
    """
    Request payload to generate a Chatbot Details PDF.
    """
    answers: Dict[str, str]
    summary: str
    classification: str
    originalReportId: Optional[str] = None # Optional ID if we want to track it

class ChatbotSummaryResponse(BaseModel):
    pdf_url: str

def _ensure_reports_dir() -> Path:
    # Use the same base directory as investigation reports for consistency
    base_dir = Path(os.environ.get("INVESTIGATION_REPORTS_DIR", "generated_reports")) 
    reports_dir = base_dir / "investigation_reports" / "chatbot_summaries"
    reports_dir.mkdir(parents=True, exist_ok=True)
    return reports_dir

def _render_summary_pdf(payload: ChatbotSummaryRequest) -> str:
    """
    Render the summary into a PDF and return its relative URL.
    """
    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.lib import colors
        from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
        from reportlab.lib.units import cm
        from reportlab.pdfbase import pdfmetrics
        from reportlab.pdfbase.ttfonts import TTFont
        from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
    except ImportError as exc:
        raise RuntimeError("reportlab is required for PDF generation.") from exc

    reports_dir = _ensure_reports_dir()
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    
    # Try to find a unique identifier or just use timestamp
    safe_id = timestamp
    if payload.originalReportId:
        safe_id = f"{payload.originalReportId}_{timestamp}"
        
    file_name = f"summary_{safe_id}.pdf"
    pdf_path = reports_dir / file_name

    # Font registration (borrowed from investigation_report.py)
    try:
        # Check if font exists, otherwise use standard
        if os.path.exists("DejaVuSans.ttf"):
            pdfmetrics.registerFont(TTFont("DejaVuSans", "DejaVuSans.ttf"))
            base_font_name = "DejaVuSans"
            bold_font_name = "DejaVuSans" # fallback if no bold font
        else:
            base_font_name = "Helvetica"
            bold_font_name = "Helvetica-Bold"
    except Exception:
        base_font_name = "Helvetica"
        bold_font_name = "Helvetica-Bold"

    doc = SimpleDocTemplate(
        str(pdf_path),
        pagesize=A4,
        rightMargin=2 * cm,
        leftMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )

    styles = getSampleStyleSheet()
    
    # Custom Styles
    title_style = ParagraphStyle(
        "summary_title",
        parent=styles["Heading1"],
        fontName=bold_font_name,
        fontSize=18,
        alignment=1, # Center
        spaceAfter=20,
        textColor=colors.HexColor("#FC633C") # Match app theme orange
    )
    
    heading_style = ParagraphStyle(
        "summary_heading",
        parent=styles["Heading2"],
        fontName=bold_font_name,
        fontSize=14,
        spaceBefore=15,
        spaceAfter=10,
        textColor=colors.black
    )
    
    label_style = ParagraphStyle(
        "label",
        parent=styles["Normal"],
        fontName=bold_font_name,
        fontSize=10,
        textColor=colors.grey
    )
    
    value_style = ParagraphStyle(
        "value",
        parent=styles["Normal"],
        fontName=base_font_name,
        fontSize=11,
        textColor=colors.black
    )
    
    highlighted_value_style = ParagraphStyle(
        "highlighted_value",
        parent=styles["Normal"],
        fontName=bold_font_name,
        fontSize=11,
        textColor=colors.HexColor("#FC633C")
    )
    
    normal_style = ParagraphStyle(
        "normal_text",
        parent=styles["Normal"],
        fontName=base_font_name,
        fontSize=11,
        leading=15
    )


    story = []

    # Title
    story.append(Paragraph("Formal Complaint Summary", title_style))
    story.append(Spacer(1, 0.5 * cm))

    # Basic Details Section
    story.append(Paragraph("Citizen Details", heading_style))
    
    # Define fields to show in order
    # Mapping friendly name -> key in answers
    details_map = [
        ("Full Name", "full_name"),
        ("Address", "address"), 
        ("Phone Number", "phone"),
        ("Complaint Type", "complaint_type"),
        ("Incident Summary", "incident_address"), # Matched frontend 'Incident Details' (short) but renamed to avoid confusion
        ("Selected Police Station", "selected_police_station"),
        ("Reason for Station", "police_station_reason"),
        ("Confidence Level", "station_confidence"),
        ("Date of Complaint", "date_of_complaint"),
    ]

    table_data = []
    
    for label, key in details_map:
        val = payload.answers.get(key)
        if val:
            # Wrap text in Paragraphs to handle wrapping in table cells
            p_label = Paragraph(label, label_style)
            
            # Highlight specific fields as requested
            if label in ["Address", "Complaint Type", "Selected Police Station"]:
                 p_value = Paragraph(val, highlighted_value_style)
            else:
                 p_value = Paragraph(val, value_style)
                 
            table_data.append([p_label, p_value])

    if table_data:
        t = Table(table_data, colWidths=[5 * cm, 11 * cm])
        t.setStyle(TableStyle([
            ('VALIGN', (0,0), (-1,-1), 'TOP'),
            ('topPadding', (0,0), (-1,-1), 6),
            ('bottomPadding', (0,0), (-1,-1), 6),
            ('GRID', (0,0), (-1,-1), 0.5, colors.lightgrey),
        ]))
        story.append(t)
    else:
        story.append(Paragraph("No citizen details provided.", normal_style))
        
    story.append(Spacer(1, 1 * cm))

    # Incident Details (Full Narrative)
    story.append(Paragraph("Full Incident Details", heading_style))
    details_text = payload.answers.get("incident_details", "No details provided.")
    story.append(Paragraph(details_text.replace("\n", "<br/>"), normal_style))
    story.append(Spacer(1, 1 * cm))
    
    # Classification
    story.append(Paragraph("Offence Classification", heading_style))
    story.append(Paragraph(payload.classification, normal_style))
    
    # Footer
    story.append(Spacer(1, 2 * cm))
    story.append(Paragraph("Generated by Dharma AI Legal Assistant", 
                           ParagraphStyle("footer", parent=styles["Normal"], fontSize=8, alignment=1, textColor=colors.grey)))


    doc.build(story)

    # Return relative URL
    return f"/static/reports/chatbot_summaries/{file_name}"


@router.post("/generate-chatbot-summary-pdf", response_model=ChatbotSummaryResponse)
async def generate_chatbot_summary_pdf(payload: ChatbotSummaryRequest):
    """
    Generate a PDF for the chatbot summary details.
    """
    logger.info("Received request to generate Chatbot Summary PDF (triggered by QR or Print)")
    try:
        pdf_url = _render_summary_pdf(payload)
        logger.info(f"Successfully generated Chatbot Summary PDF at: {pdf_url}")
        return ChatbotSummaryResponse(pdf_url=pdf_url)
    except Exception as e:
        logger.exception("Failed to generate chatbot summary PDF")
        raise HTTPException(status_code=500, detail=f"PDF generation failed: {str(e)}")
