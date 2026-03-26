#!/usr/bin/env python3
"""
Test script for Chargesheet Vetting API endpoint
Usage: python test_chargesheet_vetting.py [base_url]
"""

import requests
import json
import sys
from typing import Optional

def test_chargesheet_vetting(base_url: str = "http://localhost:8080"):
    """Test the chargesheet vetting endpoint"""
    
    endpoint = f"{base_url}/api/chargesheet-vetting"
    
    # Sample charge sheet content for testing
    sample_chargesheet = """
FIR No: 123/2024
Date: 15-01-2024
Police Station: Central Police Station

CHARGE SHEET

Accused: John Doe, Age 35, Address: 123 Main Street

Offence: Theft under Section 379 of IPC

Facts of the case:
On 10-01-2024, the accused entered a shop and stole a mobile phone worth Rs. 25,000.
The shop owner filed a complaint.

Evidence:
1. CCTV footage showing the accused
2. Statement of shop owner
3. Recovered mobile phone

Charges:
The accused is charged with theft under Section 379 of IPC.
"""
    
    print("=" * 60)
    print("Testing Chargesheet Vetting API")
    print("=" * 60)
    print(f"Endpoint: {endpoint}")
    print(f"Method: POST")
    print()
    
    # Prepare request data
    payload = {
        "chargesheet": sample_chargesheet
    }
    
    print("Request Payload:")
    print(json.dumps(payload, indent=2))
    print()
    print("Sending request...")
    print()
    
    try:
        # Send POST request
        response = requests.post(
            endpoint,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=60  # AI processing can take time
        )
        
        print(f"Status Code: {response.status_code}")
        print()
        
        if response.status_code == 200:
            print("✅ SUCCESS!")
            print()
            result = response.json()
            print("Response:")
            print(json.dumps(result, indent=2))
            print()
            print("Suggestions:")
            print("-" * 60)
            print(result.get("suggestions", "No suggestions provided"))
            print("-" * 60)
        else:
            print("❌ ERROR!")
            print()
            print(f"Error Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error!")
        print(f"Could not connect to {base_url}")
        print("Make sure the backend server is running.")
        print()
        print("To start the server:")
        print("  cd backend")
        print("  uvicorn main:app --reload")
        print()
        print("Or with Docker:")
        print("  cd backend")
        print("  docker-compose up")
        
    except requests.exceptions.Timeout:
        print("❌ Timeout Error!")
        print("The request took too long. The AI processing might be slow.")
        
    except Exception as e:
        print(f"❌ Unexpected Error: {str(e)}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080"
    test_chargesheet_vetting(base_url)
