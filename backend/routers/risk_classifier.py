# risk_classifier.py
import os
import json
import google.generativeai as genai

# Configure Gemini API
API_KEY = os.getenv("GEMINI_API_KEY")
if not API_KEY:
    raise ValueError("❌ GEMINI_API_KEY not found in environment variables")

genai.configure(api_key=API_KEY)

def load_prompt_template():
    """
    Load the base few-shot prompt template from 'risk_prompt.txt'.
    This file contains examples to guide the model.
    """
    with open("risk_prompt.txt", "r", encoding="utf-8") as f:
        return f.read()


def classify_risk_from_text(extracted_text: str) -> dict:
    """
    Classify the case risk based on extracted text using Gemini.
    Returns JSON with only `risk_level` and `reason`.
    """

    base_prompt = load_prompt_template()

    # Full prompt for model
    full_prompt = f"""
{base_prompt}

Now analyze the following extracted text:

Text: "{extracted_text}"

Return valid JSON in this format only:
{{
  "risk_level": "Low Risk | Medium Risk | High Risk",
  "reason": "Short reason for classification"
}}
"""

    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        response = model.generate_content(full_prompt)
        raw_output = (response.text or "").strip()

        # Extract JSON safely
        json_start = raw_output.find("{")
        json_end = raw_output.rfind("}") + 1
        json_str = raw_output[json_start:json_end]
        result = json.loads(json_str)

        return result

    except Exception as e:
        return {"error": f"Risk classification failed: {str(e)}"}

