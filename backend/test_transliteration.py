import requests
import json
import datetime

url = "http://127.0.0.1:8001/api/cases/create"

# Test payload with Telugu locale
payload = {
    "caseData": {
        "title": "Test Case for Transliteration",
        "district": "Hyderabad",
        "policeStation": "Banjara Hills",
        "complainantName": "Raju",
        "accusedPersons": [
            {
                "name": "Ravi",
                "fatherHusbandName": "Krishna",
                "gender": "Male",
                "address": "Hyderabad"
            }
        ],
        "status": "New",
        "dateFiled": datetime.datetime.now().isoformat(),
        "lastUpdated": datetime.datetime.now().isoformat(),
        "firNumber": "FIR-TRANS-001"
    },
    "locale": "te"  # Explicitly requesting Telugu
}

try:
    print(f"Sending POST to {url} with locale='te'...")
    response = requests.post(url, json=payload)
    
    print(f"Status Code: {response.status_code}")
    print("Response Body:")
    print(response.text)
    
except Exception as e:
    print(f"Request failed: {e}")
