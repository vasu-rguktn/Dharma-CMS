import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException
from loguru import logger
from pydantic import BaseModel, Field

import google.generativeai as genai

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    logger.warning("GEMINI_API_KEY not set. Investigation report generation will fail at runtime.")
else:
    genai.configure(api_key=GEMINI_API_KEY)

router = APIRouter(prefix="/api", tags=["investigation-report"])


class EvidenceItem(BaseModel):
    """Single piece of evidence/proof sent from the frontend."""

    description: str = Field(..., description="Short human-readable description of the document/evidence")
    url: Optional[str] = Field(
        default=None,
        description="Optional URL where the document is stored (Firebase Storage, etc.)",
    )


class GenerateInvestigationReportRequest(BaseModel):
    """
    Request payload to generate an Investigation Report.

    - fir: Arbitrary FIR / case data object (mirrors CaseDoc in Flutter).
    - case_journal_entries: List of chronological entries (mirrors CaseJournalEntry.toMap()).
    - evidence_list: Explicit list of documents/evidence available.
    - override_report_text: When provided, Gemini is skipped and this text is converted directly into a PDF.
      This allows the officer to edit the AI draft and then submit the final text for PDF generation.
    """

    fir: Dict[str, Any]
    case_journal_entries: List[Dict[str, Any]]
    evidence_list: List[EvidenceItem] = Field(default_factory=list)
    override_report_text: Optional[str] = None


class InvestigationReportMetadata(BaseModel):
    fir_number: Optional[str] = None
    police_station: Optional[str] = None
    generated_at: datetime
    used_ai: bool
    evidence_count: int


class GenerateInvestigationReportResponse(BaseModel):
    report_text: str
    pdf_url: str
    metadata: InvestigationReportMetadata


def _build_investigation_prompt(payload: GenerateInvestigationReportRequest) -> str:
    """
    Construct a strict, court-oriented prompt for Gemini.

    The model is instructed to:
    - Use only given FIR and journal data.
    - Avoid inventing facts / evidence.
    - Produce a structured investigation report suitable for Indian criminal law context.
    """

    fir_pretty = json.dumps(payload.fir, indent=2, ensure_ascii=False)
    journal_pretty = json.dumps(payload.case_journal_entries, indent=2, ensure_ascii=False)

    evidence_blocks = []
    for idx, ev in enumerate(payload.evidence_list, start=1):
        evidence_blocks.append(
            f"{idx}. Description: {ev.description}"
            + (f"\n   Storage URL: {ev.url}" if ev.url else "")
        )
    evidence_text = "\n".join(evidence_blocks) if evidence_blocks else "No evidence list was explicitly provided."

    instructions = """
You are assisting an Investigating Officer (IO) in India to prepare a court-ready INVESTIGATION REPORT under the Code of Criminal Procedure and Indian Penal Code context.

STRICT INSTRUCTIONS (MUST FOLLOW):
1. Use **formal police and court-ready language**, as typically used in charge-sheets and investigation diaries in India.
2. **Do NOT invent or assume any facts, parties, events, dates, times, or sections of law** that are not explicitly available in the FIR or case journal data.
3. If an important detail is missing, explicitly state that the information is "Not available in the provided record" instead of guessing.
4. Use ONLY the below FIR data, case journal entries, and evidence list as the factual source.
5. In the **Annexures** section, list ONLY the documents that are explicitly present in the EVIDENCE / PROOFS section below. Do not hallucinate additional documents.
6. Structure the report clearly with headings and sub-headings so that it can be directly placed before a Magistrate / Court.
7. Keep the tone neutral, objective, and fact-focused, avoiding any argumentative language.
8. DO NOT provide any legal opinion or conclusion on guilt; restrict yourself to narration of investigation steps and factual findings.

MANDATORY SECTIONS (IN ORDER):
1. Header:
   - Clearly mention: "INVESTIGATION REPORT" and the Police Station, District, FIR Number, and Year (if available).
   - Also add a visible line: "AI-generated draft – Verified by Investigating Officer" (this is a fixed label and must appear exactly once near the top).

2. Case Identification:
   - FIR No., Police Station, District, Year and Date of registration (if available).
   - Sections of law invoked (as per FIR, if provided).
   - Names and brief identifiers of complainant, victim(s), and accused persons, only if given in the data.

3. Brief Facts of the Case:
   - Concise narration of the occurrence as per FIR and available crime details / incident description.
   - Mention date, time, and place of occurrence strictly as per the data.

4. Investigation Steps Taken:
   - Use the case journal entries to narrate the chronological steps taken in investigation: scene visit, seizure of property, examination of witnesses, arrests, medical examination, forwarding of documents, etc.
   - Clearly mention the date and time (if available) and the rank/name of the officer for each important action.
   - Do not summarize beyond what is provided; stay faithful to the record.

5. Findings of Investigation:
   - Summarize what the investigation has established based only on the provided record (for example, nature of offence, manner of commission, roles of accused, injuries/damages).
   - If certain aspects are unclear or not available, clearly state that they are not borne out by the record shared.

6. Pending / Further Investigation (if any):
   - Mention any investigative steps that appear pending based on the journal (e.g., awaiting FSL report, CDR analysis, medical opinion) but DO NOT assume such steps if they are not explicitly mentioned.

7. Annexures:
   - Provide a numbered list of annexed documents ONLY from the **EVIDENCE / PROOFS** list below.
   - For each item, use the available description, and if a storage URL is provided, mark it as "(stored digitally)" without altering the URL.

Formatting:
- Use clear headings in ALL CAPS (e.g., "BRIEF FACTS OF THE CASE") and subheadings in Title Case.
- Use paragraphs and bullet points where appropriate for readability.
- Output must be in plain text only (no Markdown, no HTML).
"""

    prompt = f"""{instructions}

==================== FIR DATA (STRUCTURED) ====================
{fir_pretty}

==================== CASE JOURNAL ENTRIES (CHRONOLOGICAL) ====================
{journal_pretty}

==================== EVIDENCE / PROOFS AVAILABLE ====================
{evidence_text}

Now draft the full Investigation Report as per the mandatory sections above.
"""

    return prompt


def _generate_report_text_with_gemini(payload: GenerateInvestigationReportRequest) -> str:
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY not configured. Investigation report generation disabled.")
    
    prompt = _build_investigation_prompt(payload)
    logger.info("Calling Gemini API for investigation report generation")
    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        response = model.generate_content(prompt)
        text = (response.text or "").strip()
    except Exception as exc:  # pragma: no cover - defensive
        logger.exception("Gemini generation failed")
        raise HTTPException(status_code=500, detail=f"Failed to generate investigation report: {exc}") from exc

    if not text:
        raise HTTPException(status_code=500, detail="Gemini did not return any content for the investigation report")

    return text


def _ensure_reports_dir() -> Path:
    base_dir = Path(os.environ.get("INVESTIGATION_REPORTS_DIR", "generated_reports"))
    reports_dir = base_dir / "investigation_reports"
    reports_dir.mkdir(parents=True, exist_ok=True)
    return reports_dir


def _extract_basic_metadata(payload: GenerateInvestigationReportRequest) -> InvestigationReportMetadata:
    fir = payload.fir or {}
    fir_number = fir.get("firNumber") or fir.get("fir_no") or fir.get("fir_no_1")
    police_station = fir.get("policeStation") or fir.get("ps_name")
    return InvestigationReportMetadata(
        fir_number=fir_number,
        police_station=police_station,
        generated_at=datetime.utcnow(),
        used_ai=payload.override_report_text is None,
        evidence_count=len(payload.evidence_list),
    )


def _render_pdf(report_text: str, metadata: InvestigationReportMetadata) -> str:
    """
    Render the given report_text into a PDF on disk and return its relative URL path.

    Uses reportlab for simple but robust A4 PDF generation.
    """
    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
        from reportlab.lib.units import cm
        from reportlab.pdfbase import pdfmetrics
        from reportlab.pdfbase.ttfonts import TTFont
        from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer
    except ImportError as exc:  # pragma: no cover - environment safeguard
        raise RuntimeError("reportlab is required for PDF generation. Please add it to backend/requirements.txt") from exc

    reports_dir = _ensure_reports_dir()

    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    safe_fir = (metadata.fir_number or "UNKNOWN_FIR").replace("/", "_").replace("\\", "_").replace(" ", "_")
    file_name = f"investigation_report_{safe_fir}_{timestamp}.pdf"
    pdf_path = reports_dir / file_name

    # Attempt to register a common font if available, else fall back to default
    try:
        pdfmetrics.registerFont(TTFont("DejaVuSans", "DejaVuSans.ttf"))
        base_font_name = "DejaVuSans"
    except Exception:  # pragma: no cover
        base_font_name = "Helvetica"

    doc = SimpleDocTemplate(
        str(pdf_path),
        pagesize=A4,
        rightMargin=2 * cm,
        leftMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )

    styles = getSampleStyleSheet()
    normal_style = styles["Normal"]
    normal_style.fontName = base_font_name
    normal_style.fontSize = 11
    normal_style.leading = 15

    title_style = ParagraphStyle(
        "Title",
        parent=normal_style,
        fontSize=14,
        leading=18,
        spaceAfter=12,
        alignment=1,  # center
        bold=True,
    )

    story: List[Any] = []

    # Simple heuristic split: treat "\n\n" as paragraph breaks
    paragraphs = [p.strip() for p in report_text.split("\n\n") if p.strip()]

    if paragraphs:
        # First paragraph as title-like block if it looks like a heading
        story.append(Paragraph(paragraphs[0].replace("\n", "<br/>"), title_style))
        story.append(Spacer(1, 0.5 * cm))
        for para in paragraphs[1:]:
            story.append(Paragraph(para.replace("\n", "<br/>"), normal_style))
            story.append(Spacer(1, 0.3 * cm))
    else:
        story.append(Paragraph("INVESTIGATION REPORT", title_style))
        story.append(Paragraph("No content available", normal_style))

    doc.build(story)

    # URL path where FastAPI will serve this file (mounted under /static/reports)
    relative_url = f"/static/reports/{file_name}"
    return relative_url


@router.post("/generate-investigation-report", response_model=GenerateInvestigationReportResponse)
async def generate_investigation_report(payload: GenerateInvestigationReportRequest) -> GenerateInvestigationReportResponse:
    """
    Generate a court-ready Investigation Report using Gemini and convert it to a PDF.

    - Uses GEMINI_API_KEY from environment (never exposed to the client).
    - Strictly uses provided FIR, journal, and evidence data.
    - Adds a visible label: "AI-generated draft – Verified by Investigating Officer" near the top of the report.

    Frontend usage patterns:
    1. Draft phase:
       - Send fir + case_journal_entries + evidence_list (override_report_text omitted).
       - Receive AI-generated `report_text` and a provisional PDF.
    2. Finalization phase:
       - After officer edits the draft on the frontend, send the same payload but with `override_report_text`
         set to the final edited text.
       - Endpoint will skip Gemini and generate a new PDF from the officer-approved text.
    """

    if not payload.fir:
        raise HTTPException(status_code=400, detail="FIR data is required")

    # Decide whether to use Gemini or officer-provided text
    if payload.override_report_text and payload.override_report_text.strip():
        logger.info("Using officer-provided override text for investigation report PDF generation")
        report_text = payload.override_report_text.strip()
        used_ai = False
    else:
        report_text = _generate_report_text_with_gemini(payload)
        used_ai = True

    # Ensure the mandatory visible label is present exactly once near the top.
    label = "AI-generated draft – Verified by Investigating Officer"
    if label not in report_text:
        report_text = f"{label}\n\n{report_text}"

    metadata = _extract_basic_metadata(payload)
    metadata.used_ai = used_ai

    pdf_url = _render_pdf(report_text, metadata)

    return GenerateInvestigationReportResponse(
        report_text=report_text,
        pdf_url=pdf_url,
        metadata=metadata,
    )



