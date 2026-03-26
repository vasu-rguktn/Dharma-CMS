#!/usr/bin/env python3
"""Comprehensive diagnostic for chargesheet vetting"""

import os
from dotenv import load_dotenv
import google.generativeai as genai

print("=" * 60)
print("Chargesheet Vetting Diagnostic")
print("=" * 60)
print()

load_dotenv()

# 1. Check API Key
print("1. Checking API Keys...")
vetting_key = os.getenv("GEMINI_KEY_VETTING")
investigation_key = os.getenv("GEMINI_API_KEY_INVESTIGATION")
main_key = os.getenv("GEMINI_API_KEY")

api_key = vetting_key or investigation_key or main_key

if vetting_key:
    print(f"   ✅ GEMINI_KEY_VETTING found (length: {len(vetting_key)})")
    key_source = "GEMINI_KEY_VETTING"
elif investigation_key:
    print(f"   ✅ GEMINI_API_KEY_INVESTIGATION found (length: {len(investigation_key)})")
    key_source = "GEMINI_API_KEY_INVESTIGATION"
elif main_key:
    print(f"   ✅ GEMINI_API_KEY found (length: {len(main_key)})")
    key_source = "GEMINI_API_KEY"
else:
    print("   ❌ No API key found!")
    exit(1)

print(f"   Using: {key_source}")
print()

# 2. Test Gemini Configuration
print("2. Testing Gemini API Configuration...")
try:
    genai.configure(api_key=api_key)
    print("   ✅ genai.configure() successful")
except Exception as e:
    print(f"   ❌ genai.configure() failed: {e}")
    exit(1)

# 3. Test Model Creation
print("3. Testing Model Creation...")
try:
    model = genai.GenerativeModel("models/gemini-2.5-flash")
    print("   ✅ Model created successfully")
except Exception as e:
    print(f"   ❌ Model creation failed: {e}")
    exit(1)

# 4. Test API Call
print("4. Testing Gemini API Call...")
try:
    test_prompt = "Say 'Hello' in one word"
    response = model.generate_content(test_prompt)
    
    if response and response.text:
        print(f"   ✅ API call successful!")
        print(f"   Response: {response.text.strip()}")
    else:
        print("   ❌ API call returned empty response")
        exit(1)
except Exception as e:
    print(f"   ❌ API call failed!")
    print(f"   Error type: {type(e).__name__}")
    print(f"   Error message: {str(e)}")
    import traceback
    traceback.print_exc()
    exit(1)

# 5. Test Router Import
print("5. Testing Router Import...")
try:
    from routers.chargesheet_vetting import router
    print("   ✅ Router imports successfully")
except Exception as e:
    print(f"   ❌ Router import failed: {e}")
    import traceback
    traceback.print_exc()
    exit(1)

print()
print("=" * 60)
print("✅ All checks passed! The setup looks good.")
print("=" * 60)
print()
print("If you're still getting 503 errors:")
print("1. Make sure the backend server was restarted after adding GEMINI_KEY_VETTING")
print("2. Check the backend terminal logs for the actual Gemini API error")
print("3. Verify your API key has proper permissions/quota")
