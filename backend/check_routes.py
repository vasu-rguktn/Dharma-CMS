"""
Route verification script for Dharma CMS Backend
Checks if all routes are properly registered and accessible.
"""

import requests
import json
import sys
from typing import Dict, List, Tuple

# Expected routes based on main.py and router configurations
EXPECTED_ROUTES = {
    "GET": [
        "/",
        "/Root",
        "/api/health",
        "/ocr/health",
        "/api/ocr/health",
    ],
    "POST": [
        "/complaint/summarize",
        "/api/ocr/extract",
        "/api/ocr/extract-case/",
        "/extract-case/",  # Legacy
        "/api/ai-investigation/",
        "/api/legal-chat/",
        "/api/generate-investigation-report",
        "/api/document-drafting",
        "/api/legal-suggestions/",
        "/api/cases/create",
    ],
    "GET_STATIC": [
        "/static/reports/",  # Static files mount
    ]
}

def check_server(base_url: str = "http://localhost:8080") -> Tuple[bool, Dict]:
    """
    Check if server is running and fetch OpenAPI schema.
    Returns (success, schema_dict)
    """
    try:
        print(f"Fetching {base_url}/openapi.json...")
        response = requests.get(f"{base_url}/openapi.json", timeout=5)
        
        if response.status_code == 200:
            schema = response.json()
            return True, schema
        else:
            print(f"Failed to fetch schema. Status: {response.status_code}")
            return False, {}
            
    except requests.exceptions.ConnectionError:
        print(f"CRITICAL: Server is NOT running or not accessible at {base_url}.")
        print("Start the server with: docker-compose up or uvicorn main:app --reload")
        return False, {}
    except Exception as e:
        print(f"Error: {e}")
        return False, {}

def verify_routes(schema: Dict) -> Tuple[List[str], List[str]]:
    """
    Verify that expected routes exist in the schema.
    Returns (found_routes, missing_routes)
    """
    paths = schema.get("paths", {})
    found = []
    missing = []
    
    # Check GET routes
    for route in EXPECTED_ROUTES["GET"]:
        if route in paths:
            methods = paths[route].keys()
            if "get" in methods:
                found.append(f"GET {route}")
            else:
                missing.append(f"GET {route} (exists but no GET method)")
        else:
            missing.append(f"GET {route}")
    
    # Check POST routes
    for route in EXPECTED_ROUTES["POST"]:
        if route in paths:
            methods = paths[route].keys()
            if "post" in methods:
                found.append(f"POST {route}")
            else:
                missing.append(f"POST {route} (exists but no POST method)")
        else:
            missing.append(f"POST {route}")
    
    return found, missing

def print_route_summary(schema: Dict):
    """Print a summary of all available routes."""
    paths = schema.get("paths", {})
    
    print("\n" + "="*60)
    print("AVAILABLE ROUTES SUMMARY")
    print("="*60)
    
    # Group by method
    routes_by_method = {}
    for path, methods in paths.items():
        for method in methods.keys():
            if method.upper() not in routes_by_method:
                routes_by_method[method.upper()] = []
            routes_by_method[method.upper()].append(path)
    
    for method in sorted(routes_by_method.keys()):
        print(f"\n{method} Routes:")
        for route in sorted(routes_by_method[method]):
            print(f"  {route}")
    
    print("\n" + "="*60)
    print(f"Total Routes: {len(paths)}")
    print("="*60 + "\n")

def main():
    """Main verification function."""
    # Allow custom base URL via command line
    base_url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8080"
    
    print("="*60)
    print("DHARMA CMS BACKEND - ROUTE VERIFICATION")
    print("="*60)
    print(f"Checking server at: {base_url}\n")
    
    # Check if server is running
    success, schema = check_server(base_url)
    if not success:
        sys.exit(1)
    
    # Print all available routes
    print_route_summary(schema)
    
    # Verify expected routes
    print("="*60)
    print("ROUTE VERIFICATION")
    print("="*60)
    
    found, missing = verify_routes(schema)
    
    print(f"\n✓ Found Routes ({len(found)}):")
    for route in found:
        print(f"  {route}")
    
    if missing:
        print(f"\n✗ Missing Routes ({len(missing)}):")
        for route in missing:
            print(f"  {route}")
    else:
        print("\n✓ All expected routes are registered!")
    
    # Health check
    print("\n" + "="*60)
    print("HEALTH CHECK")
    print("="*60)
    try:
        health_response = requests.get(f"{base_url}/api/health", timeout=5)
        if health_response.status_code == 200:
            print(f"✓ Health check passed: {health_response.json()}")
        else:
            print(f"✗ Health check failed: Status {health_response.status_code}")
    except Exception as e:
        print(f"✗ Health check error: {e}")
    
    print("\n" + "="*60)
    if missing:
        print("⚠ Some routes are missing. Check main.py router includes.")
        sys.exit(1)
    else:
        print("✓ All routes verified successfully!")
        sys.exit(0)

if __name__ == "__main__":
    main()
