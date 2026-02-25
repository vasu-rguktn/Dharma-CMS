import os
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional

from fastapi import APIRouter, HTTPException
from loguru import logger
from pydantic import BaseModel

router = APIRouter(prefix="/api", tags=["chatbot-summary-pdf"])


class ChatbotSummaryRequest(BaseModel):
    answers: Dict[str, str]
    summary: str
    classification: str
    originalReportId: Optional[str] = None


class ChatbotSummaryResponse(BaseModel):
    pdf_url: str


def _ensure_reports_dir() -> Path:
    base_dir = Path(os.environ.get("INVESTIGATION_REPORTS_DIR", "generated_reports"))
    reports_dir = base_dir / "investigation_reports" / "chatbot_summaries"
    reports_dir.mkdir(parents=True, exist_ok=True)
    return reports_dir


# Detect Telugu characters
def contains_telugu(text: str) -> bool:
    return bool(re.search(r'[\u0C00-\u0C7F]', text or ""))


# ✅ CORRECT FONT LOADER (NO LOGIC BUGS)
def _load_fonts(use_telugu: bool):

    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont

    backend_dir = Path(__file__).resolve().parent.parent
    fonts_dir = backend_dir / "fonts"

    # Telugu Serif
    telugu_regular = fonts_dir / "NotoSerifTelugu-Regular.ttf"
    telugu_bold = fonts_dir / "NotoSerifTelugu-Bold.ttf"

    # Universal Sans
    noto_regular = fonts_dir / "NotoSans-Regular.ttf"
    noto_bold = fonts_dir / "NotoSans-Bold.ttf"

    try:

        # ---------- TELUGU ----------
        if use_telugu and telugu_regular.exists():

            if "TeluguSerif" not in pdfmetrics.getRegisteredFontNames():
                pdfmetrics.registerFont(
                    TTFont("TeluguSerif", str(telugu_regular))
                )

            if "TeluguSerif-Bold" not in pdfmetrics.getRegisteredFontNames():
                pdfmetrics.registerFont(
                    TTFont(
                        "TeluguSerif-Bold",
                        str(telugu_bold if telugu_bold.exists() else telugu_regular),
                    )
                )

            logger.info("Using NotoSerifTelugu font")
            return "TeluguSerif", "TeluguSerif-Bold"

        # ---------- DEFAULT ----------
        if noto_regular.exists():

            if "AppSans" not in pdfmetrics.getRegisteredFontNames():
                pdfmetrics.registerFont(
                    TTFont("AppSans", str(noto_regular))
                )

            if "AppSans-Bold" not in pdfmetrics.getRegisteredFontNames():
                pdfmetrics.registerFont(
                    TTFont(
                        "AppSans-Bold",
                        str(noto_bold if noto_bold.exists() else noto_regular),
                    )
                )

            logger.info("Using NotoSans font")
            return "AppSans", "AppSans-Bold"

    except Exception as e:
        logger.warning(f"Font load failed: {e}")

    return "Helvetica", "Helvetica-Bold"


def _render_summary_pdf(payload: ChatbotSummaryRequest) -> str:

    from reportlab.lib.pagesizes import A4
    from reportlab.lib import colors
    from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
    from reportlab.lib.units import cm
    from reportlab.platypus import (
        Paragraph,
        SimpleDocTemplate,
        Spacer,
        Table,
        TableStyle,
    )

    reports_dir = _ensure_reports_dir()
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")

    safe_id = timestamp
    if payload.originalReportId:
        safe_id = f"{payload.originalReportId}_{timestamp}"

    file_name = f"summary_{safe_id}.pdf"
    pdf_path = reports_dir / file_name

    # Detect language
    all_text = payload.summary + payload.classification + " ".join(payload.answers.values())
    use_telugu = contains_telugu(all_text)

    base_font_name, bold_font_name = _load_fonts(use_telugu)

    doc = SimpleDocTemplate(
        str(pdf_path),
        pagesize=A4,
        rightMargin=2 * cm,
        leftMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )

    styles = getSampleStyleSheet()

    # HIGH LEADING (Important for Indic)
    title_style = ParagraphStyle(
        "title",
        parent=styles["Heading1"],
        fontName=bold_font_name,
        fontSize=18,
        alignment=1,
        spaceAfter=20,
        textColor=colors.HexColor("#FC633C"),
        leading=24,
        wordWrap="CJK",
    )

    heading_style = ParagraphStyle(
        "heading",
        parent=styles["Heading2"],
        fontName=bold_font_name,
        fontSize=14,
        leading=20,
        spaceBefore=15,
        spaceAfter=10,
        wordWrap="CJK",
    )

    value_style = ParagraphStyle(
        "value",
        parent=styles["Normal"],
        fontName=base_font_name,
        fontSize=11,
        leading=22,
        wordWrap="CJK",
    )

    label_style = ParagraphStyle(
        "label",
        parent=styles["Normal"],
        fontName=bold_font_name,
        fontSize=10,
        textColor=colors.grey,
        leading=18,
        wordWrap="CJK",
    )

    story = []

    story.append(Paragraph("Formal Complaint Summary", title_style))
    story.append(Spacer(1, 0.5 * cm))

    story.append(Paragraph("Citizen Details", heading_style))

    details_map = [
        ("Petition Number", "petition_number"),
        ("Case ID", "case_id"),
        ("Date of Complaint", "date_of_complaint"),
        ("Full Name", "full_name"),
        ("Address", "address"),
        ("Phone Number", "phone"),
        ("Complaint Type", "complaint_type"),
        ("Incident Date", "incident_date"),
        ("Incident Location", "incident_address"),
        ("Accused Details", "accused_details"),
        ("Stolen Property", "stolen_property"),
        ("Witnesses", "witnesses"),
        ("Evidence Status", "evidence_status"),
        ("Selected Police Station", "selected_police_station"),
        ("Reason for Station", "police_station_reason"),
        ("Confidence Level", "station_confidence"),
    ]

    table_data = []

    for label, key in details_map:
        val = payload.answers.get(key)
        if val:
            table_data.append([
                Paragraph(label, label_style),
                Paragraph(val, value_style),
            ])

    if table_data:
        t = Table(table_data, colWidths=[5 * cm, 11 * cm])
        t.setStyle(TableStyle([
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("TOPPADDING", (0, 0), (-1, -1), 10),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.lightgrey),
        ]))
        story.append(t)

    story.append(Spacer(1, 1 * cm))

    story.append(Paragraph("Full Incident Details", heading_style))
    story.append(Paragraph(
        payload.answers.get("incident_details", ""),
        value_style
    ))

    story.append(Spacer(1, 1 * cm))

    story.append(Paragraph("Offence Classification", heading_style))
    story.append(Paragraph(payload.classification, value_style))

    doc.build(story)

    return f"/static/reports/chatbot_summaries/{file_name}"


@router.post("/generate-chatbot-summary-pdf", response_model=ChatbotSummaryResponse)
async def generate_chatbot_summary_pdf(payload: ChatbotSummaryRequest):

    try:
        pdf_url = _render_summary_pdf(payload)
        return ChatbotSummaryResponse(pdf_url=pdf_url)

    except Exception as e:
        logger.exception("PDF generation failed")
        raise HTTPException(status_code=500, detail=str(e))
