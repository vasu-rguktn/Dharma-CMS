"""
Hugging Face Token Validator
This script tests if your HF_TOKEN is valid and checks rate limits.
"""

import os
import sys
from dotenv import load_dotenv
from openai import OpenAI
import requests

# Set UTF-8 encoding for Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')


# Load environment variables
load_dotenv()

HF_TOKEN = os.getenv("HF_TOKEN")

print("=" * 60)
print("HUGGING FACE TOKEN VALIDATION")
print("=" * 60)

# Check 1: Token exists
print("\n1. Checking if HF_TOKEN is set...")
if not HF_TOKEN:
    print("❌ ERROR: HF_TOKEN is not set in .env file")
    print("   Please add: HF_TOKEN=your_token_here")
    sys.exit(1)
else:
    print(f"✅ HF_TOKEN is set (length: {len(HF_TOKEN)} characters)")
    # Show first and last 4 characters for verification
    masked_token = f"{HF_TOKEN[:4]}...{HF_TOKEN[-4:]}"
    print(f"   Token: {masked_token}")

# Check 2: Token format
print("\n2. Checking token format...")
if HF_TOKEN.startswith("hf_"):
    print("✅ Token has correct format (starts with 'hf_')")
else:
    print("⚠️  WARNING: Token doesn't start with 'hf_' - this might be invalid")

# Check 3: Validate token with Hugging Face API
print("\n3. Validating token with Hugging Face API...")
try:
    headers = {"Authorization": f"Bearer {HF_TOKEN}"}
    response = requests.get("https://huggingface.co/api/whoami", headers=headers)
    
    if response.status_code == 200:
        user_info = response.json()
        print("✅ Token is VALID!")
        print(f"   User: {user_info.get('name', 'Unknown')}")
        print(f"   Type: {user_info.get('type', 'Unknown')}")
        
        # Check if it's a read token
        if 'auth' in user_info:
            print(f"   Auth Type: {user_info['auth'].get('type', 'Unknown')}")
    elif response.status_code == 401:
        print("❌ ERROR: Token is INVALID or EXPIRED")
        print("   Please generate a new token at: https://huggingface.co/settings/tokens")
        sys.exit(1)
    else:
        print(f"⚠️  WARNING: Unexpected response (status {response.status_code})")
        print(f"   Response: {response.text}")
except Exception as e:
    print(f"❌ ERROR: Failed to validate token: {e}")
    sys.exit(1)

# Check 4: Test LLM API access
print("\n4. Testing LLM API access (Meta-Llama-3-8B-Instruct)...")
try:
    client = OpenAI(
        base_url="https://router.huggingface.co/v1",
        api_key=HF_TOKEN,
        timeout=20.0,
    )
    
    # Try a simple completion
    response = client.chat.completions.create(
        model="meta-llama/Meta-Llama-3-8B-Instruct",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Say 'Hello' in one word."}
        ],
        max_tokens=10,
        temperature=0.0,
    )
    
    reply = response.choices[0].message.content.strip()
    print("✅ LLM API is working!")
    print(f"   Test response: {reply}")
    
    # Check usage/limits if available
    if hasattr(response, 'usage'):
        print(f"   Tokens used: {response.usage.total_tokens}")
    
except Exception as e:
    error_str = str(e).lower()
    print(f"❌ ERROR: LLM API call failed")
    print(f"   Error: {e}")
    
    # Diagnose common errors
    if "rate limit" in error_str or "429" in error_str:
        print("\n   DIAGNOSIS: Rate limit exceeded")
        print("   - You've hit the API rate limit")
        print("   - Wait a few minutes and try again")
        print("   - Consider upgrading to a paid plan for higher limits")
    elif "quota" in error_str or "exceeded" in error_str:
        print("\n   DIAGNOSIS: Quota exceeded")
        print("   - Your free tier quota is exhausted")
        print("   - Upgrade to a paid plan or wait for quota reset")
    elif "unauthorized" in error_str or "401" in error_str:
        print("\n   DIAGNOSIS: Authentication failed")
        print("   - Token might be invalid or expired")
        print("   - Generate a new token at: https://huggingface.co/settings/tokens")
    elif "timeout" in error_str:
        print("\n   DIAGNOSIS: Request timeout")
        print("   - The API is slow or unresponsive")
        print("   - Try again in a few moments")
    elif "model" in error_str or "not found" in error_str:
        print("\n   DIAGNOSIS: Model access issue")
        print("   - You might not have access to Meta-Llama-3-8B-Instruct")
        print("   - Check model permissions at: https://huggingface.co/meta-llama/Meta-Llama-3-8B-Instruct")
    else:
        print("\n   DIAGNOSIS: Unknown error")
        print("   - Check Hugging Face status: https://status.huggingface.co/")
    
    sys.exit(1)

# Check 5: Test rate limits
print("\n5. Checking rate limits...")
print("   Making 3 rapid test requests to check limits...")
success_count = 0
for i in range(3):
    try:
        response = client.chat.completions.create(
            model="meta-llama/Meta-Llama-3-8B-Instruct",
            messages=[{"role": "user", "content": f"Count: {i+1}"}],
            max_tokens=5,
            temperature=0.0,
        )
        success_count += 1
        print(f"   Request {i+1}/3: ✅ Success")
    except Exception as e:
        print(f"   Request {i+1}/3: ❌ Failed - {str(e)[:50]}...")
        if "rate limit" in str(e).lower():
            print("   ⚠️  Rate limit hit!")
            break

if success_count == 3:
    print("✅ Rate limits are healthy (3/3 requests succeeded)")
elif success_count > 0:
    print(f"⚠️  Partial success ({success_count}/3 requests succeeded)")
else:
    print("❌ All requests failed - rate limit or quota issue")

# Final Summary
print("\n" + "=" * 60)
print("SUMMARY")
print("=" * 60)
print(f"Token Status: {'✅ VALID' if HF_TOKEN else '❌ MISSING'}")
print(f"API Access: {'✅ WORKING' if success_count > 0 else '❌ FAILED'}")
print(f"Rate Limits: {'✅ OK' if success_count == 3 else '⚠️  LIMITED' if success_count > 0 else '❌ EXCEEDED'}")

print("\n📝 RECOMMENDATIONS:")
if success_count == 3:
    print("   ✅ Your HF_TOKEN is working perfectly!")
    print("   ✅ The backend error is likely caused by something else.")
    print("   ✅ Check backend logs for the actual error message.")
else:
    print("   ⚠️  Your HF_TOKEN has issues:")
    if success_count == 0:
        print("   - Generate a new token at: https://huggingface.co/settings/tokens")
        print("   - Ensure you have access to Meta-Llama-3-8B-Instruct")
        print("   - Consider upgrading to a paid plan if on free tier")
    else:
        print("   - You're hitting rate limits")
        print("   - Wait a few minutes between requests")
        print("   - Consider upgrading for higher limits")

print("\n" + "=" * 60)
