from fastapi import APIRouter, HTTPException
from firebase_admin import firestore

router = APIRouter(
    prefix="/api/case-lookup",
    tags=["Case Lookup"]
)

@router.get("/all")
async def get_all_cases():
    """Fetch all cases with basic details for listing."""
    try:
        db = firestore.client()
        cases_ref = db.collection('cases')
        
        # Try to order by createdAt, but fallback to unordered if field doesn't exist
        try:
            docs = cases_ref.order_by('createdAt', direction=firestore.Query.DESCENDING).limit(50).stream()
        except Exception as order_error:
            print(f"Warning: Could not order by createdAt: {order_error}")
            # Fallback: fetch without ordering
            docs = cases_ref.limit(50).stream()
        
        cases = []
        for doc in docs:
            try:
                d = doc.to_dict()
                
                # Parse title or use FIR No as display
                fir_no = d.get('firNumber') or d.get('fir_no') or d.get('FIRNumber') or 'No FIR'
                
                # Try multiple fields for title
                title = (d.get('title') or 
                        d.get('caseTitle') or 
                        d.get('incidentDetails', '')[:50] or 
                        'Untitled Case')
                
                if len(title) > 50:
                    title = title[:50] + '...'
                
                case_data = {
                    "id": doc.id,  # This is the Firebase document ID
                    "firNumber": fir_no,
                    "title": title,
                    "date": str(d.get('createdAt', d.get('created_at', 'N/A')))
                }
                
                cases.append(case_data)
                print(f"Added case: {case_data['id']} - {case_data['firNumber']}")
                
            except Exception as doc_error:
                print(f"Error processing document {doc.id}: {doc_error}")
                continue
        
        print(f"Total cases fetched: {len(cases)}")
        return cases
        
    except Exception as e:
        print(f"Error fetching cases: {e}")
        import traceback
        traceback.print_exc()
        # Return empty list instead of crashing
        return []

@router.get("/{case_id}")
async def get_case_details(case_id: str):
    """Fetch full details of a specific case."""
    try:
        db = firestore.client()
        doc_ref = db.collection('cases').document(case_id)
        doc = doc_ref.get()
        
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Case not found")
            
        return {"id": doc.id, **doc.to_dict()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
