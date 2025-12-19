
import json
import urllib.request
import urllib.error
import time

def test_endpoint(url):
    print(f"Testing URL: {url}")
    data = {
        "caseData": "Theft of Samsung Galaxy S21",
        "recipientType": "medical officer",
        "additionalInstructions": "Urgent"
    }
    json_data = json.dumps(data).encode('utf-8')
    req = urllib.request.Request(
        url, 
        data=json_data, 
        headers={
            'Content-Type': 'application/json',
            'User-Agent': 'DebugScript',
            'Accept': 'application/json'
        }
    )
    
    try:
        start = time.time()
        with urllib.request.urlopen(req) as response:
            print(f"Status: {response.status}")
            body = response.read().decode('utf-8')
            print(f"Response: {body[:500]}") # Truncate if long
    except urllib.error.HTTPError as e:
        print(f"HTTP Error: {e.code}")
        print(f"Response: {e.read().decode('utf-8')}")
    except Exception as e:
        print(f"Error: {e}")
    print("-" * 20)

# Test BOTH to see which one works now
test_endpoint('http://127.0.0.1:8000/api/document-drafting')
test_endpoint('http://127.0.0.1:8000/api/document-drafting/')
