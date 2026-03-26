"""
Backend Endpoint Tester
Tests the /complaint/chat-step endpoint to diagnose issues
"""

import os
import sys
import requests
import json
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Backend URL
BACKEND_URL = "https://fastapi-app-335340524683.asia-south1.run.app"

print("=" * 60)
print("BACKEND ENDPOINT TESTER")
print("=" * 60)

# Test payload (simulating the frontend request)
test_payload = {
    "full_name": "",
    "address": "",
    "phone": "",
    "complaint_type": "",
    "initial_details": "yah group off persons for power playing cards with a bitting in a public place causing public nuisance the act is illegal and punishable under gaming glass gambling glass a group of persons were called playing cards with betting in a public place causing news sense the active illegal and punishable under gambling laws",
    "language": "en",
    "chat_history": []
}

print(f"\n📡 Testing endpoint: {BACKEND_URL}/complaint/chat-step")
print(f"📦 Payload:")
print(json.dumps(test_payload, indent=2))

print("\n🔄 Sending request...")

try:
    response = requests.post(
        f"{BACKEND_URL}/complaint/chat-step",
        json=test_payload,
        headers={"Content-Type": "application/json"},
        timeout=30
    )
    
    print(f"\n📊 Response Status: {response.status_code}")
    print(f"📊 Response Headers:")
    for key, value in response.headers.items():
        if key.lower() in ['content-type', 'x-request-id', 'x-cloud-trace-context']:
            print(f"   {key}: {value}")
    
    print(f"\n📄 Response Body:")
    try:
        response_json = response.json()
        print(json.dumps(response_json, indent=2))
        
        # Analyze response
        print("\n" + "=" * 60)
        print("ANALYSIS")
        print("=" * 60)
        
        if response.status_code == 200:
            print("✅ Request succeeded!")
            
            if 'status' in response_json:
                status = response_json['status']
                print(f"   Status: {status}")
                
                if status == 'question':
                    print(f"   ✅ AI asked a question: {response_json.get('message', 'N/A')}")
                elif status == 'done':
                    print(f"   ✅ AI completed the flow")
                    if response_json.get('final_response'):
                        print(f"   ✅ Final response generated")
                    else:
                        print(f"   ⚠️  No final response (might be HF_TOKEN issue)")
            else:
                print("   ⚠️  Unexpected response format")
        else:
            print(f"❌ Request failed with status {response.status_code}")
            
            if response.status_code == 500:
                print("   DIAGNOSIS: Internal Server Error")
                if 'detail' in response_json:
                    error_detail = str(response_json['detail']).lower()
                    print(f"   Error: {response_json['detail']}")
                    
                    # Diagnose specific errors
                    if 'hf_token' in error_detail or 'token' in error_detail:
                        print("\n   🔍 LIKELY CAUSE: HF_TOKEN issue")
                        print("   - Token might be invalid or expired")
                        print("   - Run: python test_hf_token.py to validate")
                    elif 'rate limit' in error_detail or '429' in error_detail:
                        print("\n   🔍 LIKELY CAUSE: Rate limit exceeded")
                        print("   - Too many API requests")
                        print("   - Wait a few minutes and try again")
                    elif 'timeout' in error_detail:
                        print("\n   🔍 LIKELY CAUSE: LLM API timeout")
                        print("   - Hugging Face API is slow")
                        print("   - Try again in a few moments")
                    elif 'unauthorized' in error_detail or 'authentication' in error_detail:
                        print("\n   🔍 LIKELY CAUSE: Authentication failed")
                        print("   - HF_TOKEN is invalid")
                        print("   - Generate new token at: https://huggingface.co/settings/tokens")
                    else:
                        print("\n   🔍 Check backend logs for more details")
            elif response.status_code == 422:
                print("   DIAGNOSIS: Validation Error")
                print("   - Request payload is invalid")
                print(f"   - Details: {response_json}")
            elif response.status_code == 404:
                print("   DIAGNOSIS: Endpoint not found")
                print("   - Check if backend is deployed correctly")
            
    except json.JSONDecodeError:
        print("⚠️  Response is not JSON:")
        print(response.text[:500])
        
except requests.exceptions.Timeout:
    print("❌ ERROR: Request timed out (30 seconds)")
    print("   DIAGNOSIS: Backend is slow or unresponsive")
    print("   - Check Cloud Run logs")
    print("   - LLM API might be timing out")
    
except requests.exceptions.ConnectionError as e:
    print(f"❌ ERROR: Connection failed")
    print(f"   {e}")
    print("   DIAGNOSIS: Cannot reach backend")
    print("   - Check if backend is deployed and running")
    print("   - Verify URL: {BACKEND_URL}")
    
except Exception as e:
    print(f"❌ ERROR: Unexpected error")
    print(f"   {e}")

# Additional diagnostics
print("\n" + "=" * 60)
print("ADDITIONAL DIAGNOSTICS")
print("=" * 60)

# Check health endpoint
print("\n1. Checking backend health...")
try:
    health_response = requests.get(f"{BACKEND_URL}/api/health", timeout=10)
    if health_response.status_code == 200:
        print("   ✅ Backend is healthy")
    else:
        print(f"   ⚠️  Health check returned {health_response.status_code}")
except Exception as e:
    print(f"   ❌ Health check failed: {e}")

# Check if HF_TOKEN is set in environment
print("\n2. Checking local HF_TOKEN...")
local_token = os.getenv("HF_TOKEN")
if local_token:
    print(f"   ✅ HF_TOKEN is set locally (length: {len(local_token)})")
    print(f"   Token: {local_token[:4]}...{local_token[-4:]}")
    print("   ⚠️  NOTE: Cloud Run might have a different token!")
else:
    print("   ⚠️  HF_TOKEN not found in local .env")

print("\n" + "=" * 60)
print("RECOMMENDATIONS")
print("=" * 60)
print("\n1. Run token validation:")
print("   python test_hf_token.py")
print("\n2. Check Cloud Run logs:")
print("   gcloud run services logs read fastapi-app-335340524683 \\")
print("     --region=asia-south1 --limit=50")
print("\n3. Verify HF_TOKEN in Cloud Run:")
print("   gcloud run services describe fastapi-app-335340524683 \\")
print("     --region=asia-south1 \\")
print("     --format='value(spec.template.spec.containers[0].env)'")
print("\n" + "=" * 60)
