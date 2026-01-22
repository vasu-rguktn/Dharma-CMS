"""
Test script to verify Firebase connection and list all cases
Run this to debug the case fetching issue
"""

import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path
import json
import sys

# Fix encoding for Windows
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# Initialize Firebase
try:
    cred_filename = "dharma-cms-5cc89-b74e10595572.json"
    cred_path = Path(__file__).parent / cred_filename
    
    if cred_path.exists():
        cred = credentials.Certificate(str(cred_path))
        firebase_admin.initialize_app(cred)
        print(f"[OK] Firebase initialized with {cred_filename}")
    else:
        firebase_admin.initialize_app()
        print("[OK] Firebase initialized with default credentials")
except ValueError:
    print("[OK] Firebase already initialized")

# Test fetching cases
def test_fetch_cases():
    print("\n" + "="*60)
    print("TESTING CASE FETCHING FROM FIREBASE")
    print("="*60 + "\n")
    
    try:
        db = firestore.client()
        cases_ref = db.collection('cases')
        
        # First, try to get all documents without ordering
        print("[*] Fetching all cases from 'cases' collection...")
        docs = list(cases_ref.limit(50).stream())
        
        print(f"[OK] Found {len(docs)} documents in 'cases' collection\n")
        
        if len(docs) == 0:
            print("[ERROR] No documents found in 'cases' collection!")
            print("   Please check:")
            print("   1. Firebase credentials are correct")
            print("   2. 'cases' collection exists in Firestore")
            print("   3. There are documents in the collection")
            return
        
        # Process each document
        cases = []
        for i, doc in enumerate(docs, 1):
            print(f"\n--- Case {i} ---")
            print(f"Document ID: {doc.id}")
            
            try:
                data = doc.to_dict()
                
                # Show all available fields
                print(f"Available fields: {list(data.keys())}")
                
                # Extract FIR number (try multiple field names)
                fir_no = (data.get('firNumber') or 
                         data.get('fir_no') or 
                         data.get('FIRNumber') or 
                         'No FIR')
                
                # Extract title
                title = (data.get('title') or 
                        data.get('caseTitle') or 
                        data.get('incidentDetails', '')[:50] or 
                        'Untitled Case')
                
                if len(title) > 50:
                    title = title[:50] + '...'
                
                # Extract date
                date = str(data.get('createdAt', data.get('created_at', 'N/A')))
                
                case_info = {
                    "id": doc.id,
                    "firNumber": fir_no,
                    "title": title,
                    "date": date
                }
                
                cases.append(case_info)
                
                print(f"FIR Number: {fir_no}")
                print(f"Title: {title}")
                print(f"Date: {date}")
                
                # Show sample of other fields
                if 'accusedPersons' in data:
                    print(f"Accused Persons: {len(data['accusedPersons'])} person(s)")
                if 'incidentDetails' in data:
                    details = data['incidentDetails']
                    print(f"Incident Details: {details[:100]}..." if len(details) > 100 else f"Incident Details: {details}")
                
            except Exception as e:
                print(f"[ERROR] Error processing document {doc.id}: {e}")
                import traceback
                traceback.print_exc()
        
        print("\n" + "="*60)
        print("SUMMARY")
        print("="*60)
        print(f"Total cases found: {len(cases)}")
        print(f"\nJSON Response that would be sent to frontend:")
        print(json.dumps(cases, indent=2))
        
        print("\n[OK] Test completed successfully!")
        print(f"   Your API should return {len(cases)} cases to the frontend")
        
    except Exception as e:
        print(f"\n[ERROR] {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_fetch_cases()
