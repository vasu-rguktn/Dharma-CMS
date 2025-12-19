import requests

url = "http://localhost:8000/api/document-drafting-v2"
payload = {
    "caseData": "Test",
    "recipientType": "medical officer",
    "additionalInstructions": "None"
}

print(f"Checking URL: {url}")
try:
    response = requests.post(url, json=payload)
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        print("SUCCESS: Server is updated and running v2 code.")
    elif response.status_code == 404:
        print("FAILURE: Server returned 404. It is running OLD code. Needs RESTART.")
    elif response.status_code == 422:
         print("FAILURE: Server returned 422. It is validating schema (OLD code) or raw parsing failed.")
    else:
        print(f"FAILURE: Server returned {response.status_code}. Error: {response.text}")

except requests.exceptions.ConnectionError:
    print("CRITICAL FAILURE: Could not connect to localhost:8000. Is the server running?")
except Exception as e:
    print(f"Error: {e}")
