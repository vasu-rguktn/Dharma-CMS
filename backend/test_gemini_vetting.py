#!/usr/bin/env python3
"""Test Gemini API with vetting key"""

import os
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()

# Get the key (same logic as chargesheet_vetting.py)
api_key = os.getenv("GEMINI_KEY_VETTING") or os.getenv("GEMINI_API_KEY_INVESTIGATION") or os.getenv("GEMINI_API_KEY")

if not api_key:
    print("❌ ERROR: No API key found!")
    exit(1)

print(f"✅ Using API key (length: {len(api_key)})")
print("Testing Gemini API...")
print()

try:
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel("models/gemini-2.5-flash")
    
    # Test with a simple prompt
    test_prompt = "Say 'Hello' in one word"
    print(f"Test prompt: {test_prompt}")
    response = model.generate_content(test_prompt)
    
    if response and response.text:
        print(f"✅ SUCCESS! Response: {response.text.strip()}")
        print()
        print("The API key is working correctly.")
    else:
        print("❌ ERROR: Empty response from Gemini API")
        
except Exception as e:
    print(f"❌ ERROR: Gemini API failed!")
    print(f"   Error type: {type(e).__name__}")
    print(f"   Error message: {str(e)}")
    print()
    import traceback
    traceback.print_exc()
