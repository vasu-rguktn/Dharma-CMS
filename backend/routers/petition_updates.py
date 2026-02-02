"""
Petition Updates Router

Handles petition status updates from the police portal and triggers
notifications to citizens when their petition status changes.
"""

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from firebase_admin import firestore
import logging

# Import notification service
from services.notification_service import send_petition_update_notification

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/petitions",
    tags=["petitions"]
)


class PetitionStatusUpdateRequest(BaseModel):
    """Request model for updating petition status."""
    policeStatus: str = Field(..., description="New police status (Pending, In Progress, Resolved, etc.)")
    policeSubStatus: Optional[str] = Field(None, description="Detailed sub-status")
    oldPoliceStatus: Optional[str] = Field(None, description="Old police status (for detecting changes)")
    officerId: str = Field(..., description="Police officer ID making the update")
    officerName: str = Field(..., description="Police officer name")
    notes: Optional[str] = Field(None, description="Optional notes about the update")


class PetitionStatusUpdateResponse(BaseModel):
    """Response model for petition status update."""
    success: bool
    message: str
    notificationSent: bool = False


def get_firestore_client():
    """Get Firestore client instance."""
    try:
        return firestore.client()
    except Exception as e:
        logger.error(f"Failed to get Firestore client: {e}")
        return None


@router.post("/{petition_id}/update-status", response_model=PetitionStatusUpdateResponse)
async def update_petition_status(petition_id: str, request: PetitionStatusUpdateRequest):
    """
    Update petition status and send notification to the citizen.
    
    This endpoint is called by the police portal when officers update
    petition status. It updates Firestore and triggers a push notification
    to the citizen who filed the petition.
    
    Args:
        petition_id: The petition document ID
        request: Status update data
        
    Returns:
        Success response with notification status
        
    Raises:
        HTTPException: If update fails
    """
    try:
        print(f"\n========== PETITION UPDATE ENDPOINT HIT: {petition_id} ==========")
        logger.info(f"========== PETITION UPDATE ENDPOINT HIT: {petition_id} ==========")
        
        db = get_firestore_client()
        if not db:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Firestore connection failed"
            )
        
        # Get petition document
        petition_ref = db.collection('petitions').document(petition_id)
        petition_doc = petition_ref.get()
        
        if not petition_doc.exists:
            # Try offlinepetitions collection as fallback
            petition_ref = db.collection('offlinepetitions').document(petition_id)
        
        # Get current petition data to check if it exists and get user_id
        petition_data = petition_ref.get().to_dict()
        if not petition_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Petition {petition_id} not found"
            )
        
        # Get the user ID for notification
        user_id = petition_data.get('userId') or petition_data.get('uid')
        
        # 🔥 Use old status from REQUEST (passed by frontend before Firestore update)
        # Fallback to Firestore if not provided (for backwards compatibility)
        old_status = request.oldPoliceStatus if request.oldPoliceStatus else petition_data.get('policeStatus', '')
        
        print(f"\n📊 STATUS COMPARISON:")
        print(f"   Old status (from request): {request.oldPoliceStatus}")
        print(f"   Old status (from Firestore): {petition_data.get('policeStatus', '')}")
        print(f"   Using old status: {old_status}")
        print(f"   New status: {request.policeStatus}")
        
        if not user_id:
            logger.warning(f"Petition {petition_id} has no userId, cannot send notification")
        
        # Prepare update data
        update_data = {
            'policeStatus': request.policeStatus,
            'lastPoliceUpdate': firestore.SERVER_TIMESTAMP,
            'lastOfficerId': request.officerId,
            'lastOfficerName': request.officerName,
        }
        
        if request.policeSubStatus:
            update_data['policeSubStatus'] = request.policeSubStatus
        
        if request.notes:
            update_data['policeNotes'] = request.notes
        
        petition_ref.update(update_data)
        
        logger.info(f"Updated petition {petition_id}: {old_status} → {request.policeStatus}")
        
        # Send notification to citizen (if userId exists)
        notification_sent = False
        
        print(f"\n🔍 NOTIFICATION CHECK:")
        print(f"   user_id: {user_id}")
        print(f"   old_status: '{old_status}'")
        print(f"   new_status: '{request.policeStatus}'")
        print(f"   Status changed: {old_status != request.policeStatus}")
        
        logger.info(f"🔍 Notification check - user_id: {user_id}, old: '{old_status}', new: '{request.policeStatus}'")
        
        if user_id and old_status != request.policeStatus:
            petition_title = petition_data.get('complaintType') or petition_data.get('title') or 'Your Petition'
            
            print(f"\n📲 SENDING NOTIFICATION:")
            print(f"   To user: {user_id}")
            print(f"   Petition: {petition_title}")
            print(f"   Status: {old_status} → {request.policeStatus}")
            
            logger.info(f"📲 ATTEMPTING to send notification to user {user_id}")
            logger.info(f"   Petition: {petition_title}")
            logger.info(f"   Status: {old_status} → {request.policeStatus}")
            
            notification_sent = send_petition_update_notification(
                user_id=user_id,
                petition_id=petition_id,
                petition_title=petition_title,
                new_status=request.policeStatus,
                old_status=old_status
            )
            
            print(f"\n✅ NOTIFICATION RESULT: {notification_sent}\n")
            logger.info(f"✅ Notification service returned: {notification_sent}")
        else:
            if not user_id:
                print(f"\n⚠️ SKIPPING: No user_id found\n")
                logger.warning(f"⚠️ Cannot send notification: No user_id found")
            elif old_status == request.policeStatus:
                print(f"\n⚠️ SKIPPING: Status unchanged ('{old_status}')\n")
                logger.info(f"ℹ️ Skipping notification: Status unchanged ('{old_status}')")
        
        return PetitionStatusUpdateResponse(
            success=True,
            message=f"Petition status updated to {request.policeStatus}",
            notificationSent=notification_sent
        )
    
    except HTTPException:
        raise
    
    except Exception as e:
        logger.error(f"Error updating petition status: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update petition status: {str(e)}"
        )


@router.get("/{petition_id}/status")
async def get_petition_status(petition_id: str):
    """
    Get current petition status (for verification/testing).
    
    Args:
        petition_id: The petition document ID
        
    Returns:
        Petition status information
    """
    try:
        db = get_firestore_client()
        if not db:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Firestore connection failed"
            )
        
        # Try petitions collection first
        petition_ref = db.collection('petitions').document(petition_id)
        petition_doc = petition_ref.get()
        
        if not petition_doc.exists:
            # Try offlinepetitions collection
            petition_ref = db.collection('offlinepetitions').document(petition_id)
            petition_doc = petition_ref.get()
            
            if not petition_doc.exists:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Petition {petition_id} not found"
                )
        
        petition_data = petition_doc.to_dict()
        
        return {
            'petitionId': petition_id,
            'policeStatus': petition_data.get('policeStatus'),
            'policeSubStatus': petition_data.get('policeSubStatus'),
            'updatedAt': petition_data.get('updatedAt'),
            'updatedBy': petition_data.get('updatedByName'),
            'userId': petition_data.get('userId') or petition_data.get('uid')
        }
    
    except HTTPException:
        raise
    
    except Exception as e:
        logger.error(f"Error fetching petition status: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch petition status: {str(e)}"
        )


class CaseUpdateNotificationRequest(BaseModel):
    """Request model for case update notification."""
    userId: str = Field(..., description="Citizen user ID")
    updateText: str = Field(..., description="Text of the case update")
    addedBy: str = Field(..., description="Name of officer who added update")


@router.post("/{petition_id}/case-update-notification")
async def send_case_update_notification(petition_id: str, request: CaseUpdateNotificationRequest):
    """
    Send notification to citizen when police add a case update.
    
    Args:
        petition_id: The petition document ID
        request: Case update notification data
        
    Returns:
        Success response with notification status
    """
    try:
        print(f"\n📋 CASE UPDATE NOTIFICATION for {petition_id}")
        print(f"   User: {request.userId}")
        print(f"   Update: {request.updateText[:50]}...")
        print(f"   Added by: {request.addedBy}")
        
        # Get petition title for notification
        db = get_firestore_client()
        if db:
            petition_ref = db.collection('petitions').document(petition_id)
            petition_data = petition_ref.get().to_dict()
            petition_title = petition_data.get('complaintType') or petition_data.get('title') or 'Your Petition'
        else:
            petition_title = 'Your Petition'
        
        # Send notification using existing service
        from services.notification_service import get_user_fcm_tokens
        from firebase_admin import messaging
        from datetime import datetime
        
        tokens = get_user_fcm_tokens(request.userId)
        
        if not tokens:
            print(f"⚠️ No FCM tokens for user {request.userId}")
            return {"success": True, "notificationSent": False, "message": "No FCM tokens"}
        
        # Create notification
        notification_title = f"📝 Case Update: {request.addedBy}"
        notification_body = request.updateText[:100] + ("..." if len(request.updateText) > 100 else "")
        
        message_data = {
            'type': 'case_update',
            'petitionId': petition_id,
            'timestamp': datetime.now().isoformat()
        }
        
        # Send to each token
        success_count = 0
        for token in tokens:
            try:
                message = messaging.Message(
                    token=token,
                    notification=messaging.Notification(
                        title=notification_title,
                        body=notification_body
                    ),
                    data=message_data,
                    android=messaging.AndroidConfig(
                        priority='high',
                        notification=messaging.AndroidNotification(
                            channel_id='high_importance_channel',
                            sound='default'
                        )
                    )
                )
                messaging.send(message)
                success_count += 1
            except Exception as e:
                logger.warning(f"Failed to send case update notification to token: {e}")
        
        print(f"✅ Sent {success_count}/{len(tokens)} notifications")
        
        return {
            "success": True,
            "notificationSent": success_count > 0,
            "message": f"Sent to {success_count} devices"
        }
        
    except Exception as e:
        logger.error(f"Error sending case update notification: {e}")
        return {
            "success": False,
            "notificationSent": False,
            "message": str(e)
        }
