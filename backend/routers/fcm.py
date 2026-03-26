"""
FCM Token Registration Router

Handles registration and management of Firebase Cloud Messaging (FCM) tokens
from citizen app. Tokens are stored in Firestore and used to send push notifications.
"""

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional
from firebase_admin import firestore
import logging

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/api/fcm",
    tags=["fcm"]
)


class FCMTokenRequest(BaseModel):
    """Request model for FCM token registration."""
    userId: str = Field(..., description="User ID of the citizen")
    token: str = Field(..., description="FCM device token")
    platform: str = Field(..., description="Platform: android, web, or ios")


class FCMTokenResponse(BaseModel):
    """Response model for FCM token operations."""
    success: bool
    message: str
    tokenId: Optional[str] = None


def get_firestore_client():
    """Get Firestore client instance."""
    try:
        return firestore.client()
    except Exception as e:
        logger.error(f"Failed to get Firestore client: {e}")
        return None


@router.post("/register", response_model=FCMTokenResponse, status_code=status.HTTP_200_OK)
async def register_fcm_token(request: FCMTokenRequest):
    """
    Register or update an FCM token for a user.
    
    This endpoint is called by the citizen app when:
    - User logs in
    - FCM token is refreshed
    - User grants notification permissions
    
    The token is stored in Firestore and used to send push notifications
    when police update petition or case status.
    
    Args:
        request: FCM token registration data
        
    Returns:
        Success response with token ID
        
    Raises:
        HTTPException: If registration fails
    """
    try:
        db = get_firestore_client()
        if not db:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Firestore connection failed"
            )
        
        # Validate platform
        valid_platforms = ['android', 'web', 'ios']
        if request.platform.lower() not in valid_platforms:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid platform. Must be one of: {', '.join(valid_platforms)}"
            )
        
        # Check if this token already exists for this user
        tokens_ref = db.collection('fcm_tokens')
        existing_query = tokens_ref.where('userId', '==', request.userId).where('token', '==', request.token)
        existing_docs = list(existing_query.stream())
        
        if existing_docs:
            # Token already exists, update timestamp
            doc_ref = existing_docs[0].reference
            doc_ref.update({
                'lastUpdated': firestore.SERVER_TIMESTAMP,
                'isActive': True,
                'platform': request.platform.lower()
            })
            
            logger.info(f"Updated existing FCM token for user {request.userId}")
            
            return FCMTokenResponse(
                success=True,
                message="FCM token updated successfully",
                tokenId=doc_ref.id
            )
        
        else:
            # Create new token document
            token_data = {
                'userId': request.userId,
                'token': request.token,
                'platform': request.platform.lower(),
                'lastUpdated': firestore.SERVER_TIMESTAMP,
                'isActive': True,
                'createdAt': firestore.SERVER_TIMESTAMP
            }
            
            doc_ref = tokens_ref.add(token_data)[1]
            
            logger.info(f"Registered new FCM token for user {request.userId} on platform {request.platform}")
            
            return FCMTokenResponse(
                success=True,
                message="FCM token registered successfully",
                tokenId=doc_ref.id
            )
    
    except HTTPException:
        raise
    
    except Exception as e:
        logger.error(f"Error registering FCM token: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to register FCM token: {str(e)}"
        )


@router.delete("/unregister", response_model=FCMTokenResponse, status_code=status.HTTP_200_OK)
async def unregister_fcm_token(request: FCMTokenRequest):
    """
    Unregister (deactivate) an FCM token for a user.
    
    This endpoint is called by the citizen app when:
    - User logs out
    - User revokes notification permissions
    - App is uninstalled (cleanup)
    
    Args:
        request: FCM token to unregister
        
    Returns:
        Success response
        
    Raises:
        HTTPException: If unregistration fails
    """
    try:
        db = get_firestore_client()
        if not db:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Firestore connection failed"
            )
        
        # Find the token document
        tokens_ref = db.collection('fcm_tokens')
        query = tokens_ref.where('userId', '==', request.userId).where('token', '==', request.token)
        docs = list(query.stream())
        
        if not docs:
            # Token not found, but that's okay (maybe already deleted)
            logger.info(f"FCM token not found for user {request.userId}, nothing to unregister")
            return FCMTokenResponse(
                success=True,
                message="FCM token not found (already unregistered)"
            )
        
        # Mark token as inactive (or delete it)
        for doc in docs:
            doc.reference.update({'isActive': False, 'lastUpdated': firestore.SERVER_TIMESTAMP})
            # Alternatively, delete the document:
            # doc.reference.delete()
        
        logger.info(f"Unregistered FCM token for user {request.userId}")
        
        return FCMTokenResponse(
            success=True,
            message="FCM token unregistered successfully"
        )
    
    except HTTPException:
        raise
    
    except Exception as e:
        logger.error(f"Error unregistering FCM token: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to unregister FCM token: {str(e)}"
        )


@router.get("/tokens/{user_id}", status_code=status.HTTP_200_OK)
async def get_user_tokens(user_id: str):
    """
    Get all active FCM tokens for a user (admin/debug endpoint).
    
    Args:
        user_id: The user ID to fetch tokens for
        
    Returns:
        List of active tokens with metadata
        
    Raises:
        HTTPException: If fetch fails
    """
    try:
        db = get_firestore_client()
        if not db:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Firestore connection failed"
            )
        
        # Fetch all active tokens for the user
        tokens_ref = db.collection('fcm_tokens')
        query = tokens_ref.where('userId', '==', user_id).where('isActive', '==', True)
        docs = query.stream()
        
        tokens = []
        for doc in docs:
            data = doc.to_dict()
            tokens.append({
                'tokenId': doc.id,
                'platform': data.get('platform'),
                'lastUpdated': data.get('lastUpdated'),
                'createdAt': data.get('created At'),
                #Don't expose the actual token for security
                'tokenPreview': data.get('token', '')[:20] + '...' if data.get('token') else None
            })
        
        return {
            'success': True,
            'userId': user_id,
            'tokenCount': len(tokens),
            'tokens': tokens
        }
    
    except HTTPException:
        raise
    
    except Exception as e:
        logger.error(f"Error fetching user tokens: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch user tokens: {str(e)}"
        )
