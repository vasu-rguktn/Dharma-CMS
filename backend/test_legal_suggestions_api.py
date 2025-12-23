"""
Test script for Legal Suggestions API endpoint
Tests the /api/legal-suggestions/ endpoint with sample incident data
"""

import requests
import json
from pprint import pprint

# Base URL for the backend
BASE_URL = "http://127.0.0.1:8000"

# Sample test incidents
test_incidents = [
    {
        "name": "Test Case 1: Simple Theft",
        "description": "When I was returning from college, a person stole my purse at the bus stop. The purse contained my mobile phone worth ₹25,000 and ₹5,000 cash."
    },
    {
        "name": "Test Case 2: Physical Assault",
        "description": "A man verbally abused me and then slapped me in public during a road rage incident."
    },
    {
        "name": "Test Case 3: Cybercrime",
        "description": "Someone hacked my Instagram account and is posting inappropriate content using my identity."
    }
]

def test_legal_suggestions(incident_description: str, test_name: str):
    """Test the legal suggestions endpoint"""
    
    print(f"\n{'='*80}")
    print(f"🧪 {test_name}")
    print(f"{'='*80}")
    print(f"\n📝 Incident Description:")
    print(f"   {incident_description}")
    print(f"\n⏳ Sending request to {BASE_URL}/api/legal-suggestions/...")
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/legal-suggestions/",
            json={"incident_description": incident_description},
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code == 200:
            print(f"\n✅ SUCCESS! Status Code: {response.status_code}")
            data = response.json()
            
            print(f"\n{'─'*80}")
            print(f"📋 RESPONSE DATA:")
            print(f"{'─'*80}")
            
            print(f"\n📜 Suggested Legal Sections:")
            print(f"   {data.get('suggestedSections', 'N/A')}")
            
            print(f"\n💡 Reasoning:")
            print(f"   {data.get('reasoning', 'N/A')}")
            
            print(f"\n{'─'*80}")
            print(f"🔍 Full JSON Response:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
            
        else:
            print(f"\n❌ FAILED! Status Code: {response.status_code}")
            print(f"Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print(f"\n❌ CONNECTION ERROR!")
        print(f"   ⚠️  Backend server is not running at {BASE_URL}")
        print(f"   💡 Start the backend with: python -m uvicorn main:app --reload")
        return False
        
    except requests.exceptions.Timeout:
        print(f"\n❌ TIMEOUT ERROR!")
        print(f"   ⚠️  Request took longer than 30 seconds")
        
    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        return False
    
    return True

def main():
    """Run all test cases"""
    print("\n" + "="*80)
    print("🚀 LEGAL SUGGESTIONS API TEST SUITE")
    print("="*80)
    print(f"\n📡 Target: {BASE_URL}/api/legal-suggestions/")
    print(f"📊 Total Test Cases: {len(test_incidents)}")
    
    # First, check if backend is running
    print(f"\n🔍 Checking if backend is running...")
    try:
        health_check = requests.get(f"{BASE_URL}/api/health", timeout=5)
        if health_check.status_code == 200:
            print(f"✅ Backend is running!")
        else:
            print(f"⚠️  Backend returned status {health_check.status_code}")
    except:
        print(f"\n❌ CANNOT CONNECT TO BACKEND!")
        print(f"\n💡 Please ensure:")
        print(f"   1. Backend server is running")
        print(f"   2. Run: cd backend && python -m uvicorn main:app --reload")
        print(f"   3. Server should be accessible at {BASE_URL}")
        print(f"   4. GEMINI_API_KEY_LEGAL_SUGGESTIONS is set in .env file")
        return
    
    # Run all test cases
    passed = 0
    failed = 0
    
    for test_case in test_incidents:
        result = test_legal_suggestions(
            test_case["description"],
            test_case["name"]
        )
        if result:
            passed += 1
        else:
            failed += 1
    
    # Summary
    print(f"\n{'='*80}")
    print(f"📊 TEST SUMMARY")
    print(f"{'='*80}")
    print(f"✅ Passed: {passed}/{len(test_incidents)}")
    print(f"❌ Failed: {failed}/{len(test_incidents)}")
    print(f"{'='*80}\n")

if __name__ == "__main__":
    main()
