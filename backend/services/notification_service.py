"""
Firebase Cloud Messaging (FCM) Notification Service

This module handles sending push notifications to citizen users when police officers
update petition or case statuses. It provides fail-safe notification delivery with
automatic token cleanup and graceful degradation.

Key Features:
- Send petition status update notifications
- Send case status update notifications
- Automatic FCM token management and cleanup
- Fail-safe error handling (never crashes update flows)
- Supports multiple devices per user
"""

import firebase_admin
from firebase_admin import firestore, messaging
from typing import List, Optional, Dict, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


def get_firestore_client():
    """Get Firestore client instance."""
    try:
        return firestore.client()
    except Exception as e:
        logger.error(f"Failed to get Firestore client: {e}")
        return None


def get_user_fcm_tokens(user_id: str) -> List[str]:
    """
    Fetch all active FCM tokens for a given user.
    
    Args:
        user_id: The unique identifier of the user
        
    Returns:
        List of FCM token strings, empty list if none found or error occurs
    """
    try:
        db = get_firestore_client()
        if not db:
            return []
        
        # Query fcm_tokens collection for active tokens belonging to this user
        tokens_ref = db.collection('fcm_tokens').where('userId', '==', user_id).where('isActive', '==', True)
        token_docs = tokens_ref.stream()
        
        tokens = []
        for doc in token_docs:
            data = doc.to_dict()
            if 'token' in data:
                tokens.append(data['token'])
        
        logger.info(f"Found {len(tokens)} active FCM token(s) for user {user_id}")
        return tokens
    
    except Exception as e:
        logger.error(f"Error fetching FCM tokens for user {user_id}: {e}")
        return []


def cleanup_invalid_token(token: str, user_id: str):
    """
    Remove an invalid or expired FCM token from Firestore.
    
    Args:
        token: The invalid FCM token to remove
        user_id: The user ID associated with the token
    """
    try:
        db = get_firestore_client()
        if not db:
            return
        
        # Find and delete the token document
        tokens_ref = db.collection('fcm_tokens').where('userId', '==', user_id).where('token', '==', token)
        docs = tokens_ref.stream()
        
        for doc in docs:
            doc.reference.delete()
            logger.info(f"Deleted invalid FCM token for user {user_id}")
    
    except Exception as e:
        logger.error(f"Error cleaning up invalid token: {e}")


def send_petition_update_notification(
    user_id: str,
    petition_id: str,
    petition_title: str,
    new_status: str,
    old_status: Optional[str] = None
) -> bool:
    """
    Send notification to citizen when police update petition status.
    
    Args:
        user_id: Citizen user ID who filed the petition
        petition_id: The petition document ID
        petition_title: Brief title/description of the petition
        new_status: New status value (e.g., "In Progress", "Resolved")
        old_status: Previous status value (optional, for logging)
        
    Returns:
        True if notification sent successfully, False otherwise
    """
    try:
        # Fetch user's FCM tokens
        tokens = get_user_fcm_tokens(user_id)
        
        if not tokens:
            logger.info(f"No FCM tokens found for user {user_id}, skipping petition notification")
            return False
        
        # Construct notification message
        notification_title = "📋 Petition Status Updated"
        notification_body = f"Your petition has been updated to: {new_status}"
        
        if petition_title:
            notification_body = f"{petition_title[:50]}... - Status: {new_status}"
        
        # Create message with data payload for deep-linking
        message_data = {
            'type': 'petition_update',
            'petitionId': petition_id,
            'newStatus': new_status,
            'timestamp': datetime.now().isoformat()
        }
        
        # Send to each token individually (send_multicast not available in this version)
        success_count = 0
        failure_count = 0
        invalid_tokens = []
        
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
                    ),
                    webpush=messaging.WebpushConfig(
                        notification=messaging.WebpushNotification(
                            title=notification_title,
                            body=notification_body,
                            icon='/icon.png'
                        )
                    )
                )
                
                # Send the message
                messaging.send(message)
                success_count += 1
                
            except Exception as send_error:
                failure_count += 1
                error_str = str(send_error)
                logger.warning(f"Failed to send to token: {error_str}")
                
                # Check if token is invalid
                if 'invalid-registration-token' in error_str or 'registration-token-not-registered' in error_str:
                    invalid_tokens.append(token)
        
        # Log results
        logger.info(f"Petition notification sent: {success_count} successful, {failure_count} failed")
        
        # Cleanup invalid tokens
        for token in invalid_tokens:
            cleanup_invalid_token(token, user_id)
        
        return success_count > 0
    
    except Exception as e:
        logger.warning(f"Failed to send petition update notification: {e}")
        return False


def send_case_update_notification(
    user_id: str,
    case_id: str,
    case_title: str,
    new_status: str,
    old_status: Optional[str] = None
) -> bool:
    """
    Send notification to citizen when police update case status.
    
    Args:
        user_id: Citizen user ID associated with the case
        case_id: The case document ID
        case_title: Brief title/description of the case
        new_status: New status value (e.g., "Under Investigation", "Closed")
        old_status: Previous status value (optional, for logging)
        
    Returns:
        True if notification sent successfully, False otherwise
    """
    try:
        # Fetch user's FCM tokens
        tokens = get_user_fcm_tokens(user_id)
        
        if not tokens:
            logger.info(f"No FCM tokens found for user {user_id}, skipping case notification")
            return False
        
        # Construct notification message
        notification_title = "⚖️ Case Status Updated"
        notification_body = f"Your case has been updated to: {new_status}"
        
        if case_title:
            notification_body = f"{case_title[:50]}... - Status: {new_status}"
        
        # Create message with data payload for deep-linking
        message_data = {
            'type': 'case_update',
            'caseId': case_id,
            'newStatus': new_status,
            'timestamp': datetime.now().isoformat()
        }
        
        # Send multicast message to all user's devices
        multicast_message = messaging.MulticastMessage(
            tokens=tokens,
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
            ),
            webpush=messaging.WebpushConfig(
                notification=messaging.WebpushNotification(
                    title=notification_title,
                    body=notification_body,
                    icon='/icon.png'
                )
            )
        )
        
        # Send the message
        response = messaging.send_multicast(multicast_message)
        
        # Log results
        logger.info(f"Case notification sent: {response.success_count} successful, {response.failure_count} failed")
        
        # Cleanup invalid tokens
        if response.failure_count > 0:
            for idx, send_response in enumerate(response.responses):
                if not send_response.success:
                    error_code = send_response.exception.code if send_response.exception else 'unknown'
                    if error_code in ['invalid-registration-token', 'registration-token-not-registered']:
                        cleanup_invalid_token(tokens[idx], user_id)
        
        return response.success_count > 0
    
    except Exception as e:
        logger.warning(f"Failed to send case update notification: {e}")
        return False


def send_custom_notification(
    user_id: str,
    title: str,
    body: str,
    data: Optional[Dict[str, str]] = None
) -> bool:
    """
    Send a custom notification to a user.
    
    Args:
        user_id: The user ID to send notification to
        title: Notification title
        body: Notification body text
        data: Optional custom data payload for the notification
        
    Returns:
        True if notification sent successfully, False otherwise
    """
    try:
        tokens = get_user_fcm_tokens(user_id)
        
        if not tokens:
            logger.info(f"No FCM tokens found for user {user_id}, skipping custom notification")
            return False
        
        message_data = data or {}
        message_data['timestamp'] = datetime.now().isoformat()
        
        multicast_message = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(title=title, body=body),
            data=message_data
        )
        
        response = messaging.send_multicast(multicast_message)
        logger.info(f"Custom notification sent: {response.success_count} successful")
        
        return response.success_count > 0
    
    except Exception as e:
        logger.warning(f"Failed to send custom notification: {e}")
        return False
