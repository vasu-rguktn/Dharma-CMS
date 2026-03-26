#!/usr/bin/env python3
"""Quick test to verify Gemini API key is working"""

import os
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()

# Test the investigation key (used by chargesheet vetting)
api_key = os.getenv("GEMINI_API_KEY_INVESTIGATION") or os.getenv("GEMINI_API_KEY")

if not api_key:
    print("❌ ERROR: No API key found!")
    print("   Set GEMINI_API_KEY_INVESTIGATION or GEMINI_API_KEY in .env file")
    exit(1)

print(f"✅ API Key found (length: {len(api_key)})")
print("Testing Gemini API connection...")

try:
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel("models/gemini-2.5-flash")
    
    # Simple test
    response = model.generate_content("Say 'Hello' in one word")
    
    if response and response.text:
        print("✅ Gemini API is working!")
        print(f"   Response: {response.text.strip()}")
    else:
        print("❌ ERROR: Empty response from Gemini API")
        
except Exception as e:
    print(f"❌ ERROR: Gemini API failed!")
    print(f"   Error: {str(e)}")
    print(f"   Error type: {type(e).__name__}")
    import traceback
    traceback.print_exc()
