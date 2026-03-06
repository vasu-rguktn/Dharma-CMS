import requests
import json

# Test the Legal Section Suggester endpoint with detailed output
url = "http://127.0.0.1:8000/api/legal-suggester/"

test_incident = """When I was returning from college, a person stole my purse at the bus stop.
The purse contained my mobile phone and ₹5000 cash."""

payload = {
    "incident_description": test_incident
}

print("🧪 TESTING Legal Section Suggester AI MODEL")
print("=" * 70)
print(f"📝 Incident Description:")
print(f"   {test_incident}")
print("=" * 70)

try:
    print("\n⏳ Sending request to backend...")
    response = requests.post(url, json=payload, timeout=45)
    
    print(f"✅ Response received!")
    print(f"📊 Status Code: {response.status_code}\n")
    
    if response.status_code == 200:
        data = response.json()
        
        print("=" * 70)
        print("📋 FULL AI RESPONSE:")
        print("=" * 70)
        print(json.dumps(data, indent=2, ensure_ascii=False))
        print("=" * 70)
        
        print("\n🔍 DETAILED ANALYSIS:")
        print("=" * 70)
        
        # Summary
        summary = data.get('summary', '')
        print(f"\n1️⃣ SUMMARY:")
        print(f"   Length: {len(summary)} characters")
        print(f"   Content: {summary[:150]}...")
        
        # Sections
        sections = data.get('applicable_sections', [])
        print(f"\n2️⃣ APPLICABLE SECTIONS:")
        print(f"   Count: {len(sections)}")
        if sections:
            for i, section in enumerate(sections, 1):
                print(f"\n   Section {i}:")
                print(f"      - Section: {section.get('section', 'N/A')}")
                print(f"      - Description: {section.get('description', 'N/A')[:80]}...")
                print(f"      - Applicability: {section.get('applicability', 'N/A')}")
        else:
            print("   ⚠️ NO SECTIONS RETURNED BY AI")
        
        # Classification
        classification = data.get('case_classification', '')
        print(f"\n3️⃣ CASE CLASSIFICATION:")
        print(f"   {classification}")
        
        # Offence Nature
        offence = data.get('offence_nature', '')
        print(f"\n4️⃣ OFFENCE NATURE:")
        print(f"   {offence}")
        
        # Next Steps
        steps = data.get('next_steps', [])
        print(f"\n5️⃣ NEXT STEPS:")
        print(f"   Count: {len(steps)}")
        for i, step in enumerate(steps, 1):
            print(f"   {i}. {step}")
        
        # Disclaimer
        disclaimer = data.get('disclaimer', '')
        print(f"\n6️⃣ DISCLAIMER:")
        print(f"   {disclaimer}")
        
        print("\n" + "=" * 70)
        print("✅ TEST COMPLETED SUCCESSFULLY")
        print("=" * 70)
        
        # Check for issues
        issues = []
        if not summary or summary == "No summary generated.":
            issues.append("⚠️ Summary is empty or default value")
        if not sections:
            issues.append("⚠️ No legal sections suggested")
        if classification in ["Classification pending", "Unable to classify", "Unable to classify - AI did not return structured data"]:
            issues.append("⚠️ Classification is placeholder value")
        if offence in ["Nature pending determination", "Unable to determine"]:
            issues.append("⚠️ Offence nature is placeholder value")
        if len(steps) <= 1 and any("consult" in str(s).lower() for s in steps):
            issues.append("⚠️ Next steps are generic/fallback")
        
        if issues:
            print("\n⚠️ POTENTIAL ISSUES DETECTED:")
            print("=" * 70)
            for issue in issues:
                print(f"   {issue}")
            print("\n💡 This suggests the AI is not returning structured JSON.")
            print("   The backend is using fallback values.")
        else:
            print("\n✅ ALL CHECKS PASSED - AI IS RETURNING PROPER STRUCTURED DATA")
        
    else:
        print(f"❌ ERROR: HTTP {response.status_code}")
        print(f"Response: {response.text}")
        
except requests.exceptions.ConnectionError:
    print("\n❌ CONNECTION ERROR")
    print("Backend server is not running or not accessible.")
    print("\nTo start the backend:")
    print("   cd backend")
    print("   python -m uvicorn main:app --reload")
    
except requests.exceptions.Timeout:
    print("\n❌ TIMEOUT ERROR")
    print("The AI is taking too long to respond (> 45 seconds)")
    print("This might be due to API rate limits or slow AI model.")
    
except Exception as e:
    print(f"\n❌ UNEXPECTED ERROR:")
    print(f"   {type(e).__name__}: {str(e)}")
    import traceback
    traceback.print_exc()
