import requests
import json

try:
    print("Fetching http://localhost:8000/openapi.json...")
    response = requests.get("http://localhost:8000/openapi.json")
    
    if response.status_code == 200:
        schema = response.json()
        paths = schema.get("paths", {}).keys()
        
        print(f"Total Routes Found: {len(paths)}")
        
        # Check for our specific routes
        v1_route = "/api/document-drafting"
        v2_route = "/api/document-drafting-v2"
        
        has_v1 = v1_route in paths
        has_v2 = v2_route in paths
        
        print(f"Has OLD route ({v1_route})? {'YES' if has_v1 else 'NO'}")
        print(f"Has NEW route ({v2_route})? {'YES' if has_v2 else 'NO'}")
        
        if has_v1 and not has_v2:
            print("CONCLUSION: Server is STALE (Running old code). RESTART REQUIRED.")
        elif has_v2:
            print("CONCLUSION: Server is UPDATED (Running new code).")
        else:
            print("CONCLUSION: Server is active but neither route is present. Check main.py includes.")
            
    else:
        print(f"Failed to fetch schema. Status: {response.status_code}")
        
except requests.exceptions.ConnectionError:
    print("CRITICAL: Server is NOT running or not accessible at localhost:8000.")
except Exception as e:
    print(f"Error: {e}")
