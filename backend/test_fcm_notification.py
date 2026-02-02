"""
Test script to send FCM push notifications to users.

Usage:
    python test_fcm_notification.py <user_id>

Example:
    python test_fcm_notification.py 1lgPtK4GNDZTHAZkgvwsVhF7A983
"""

import sys
import firebase_admin
from firebase_admin import credentials, firestore, messaging
from pathlib import Path

# Initialize Firebase Admin SDK
try:
    cred_filename = "dharma-cms-5cc89-b74e10595572.json"
    cred_path = Path(__file__).parent / cred_filename
    
    if cred_path.exists():
        cred = credentials.Certificate(str(cred_path))
        firebase_admin.initialize_app(cred)
        print(f"✅ Firebase Admin initialized with {cred_filename}")
    else:
        firebase_admin.initialize_app()
        print("✅ Firebase Admin initialized with default credentials")
except ValueError:
    print("⚠️  Firebase already initialized")

db = firestore.client()


def get_user_fcm_tokens(user_id: str):
    """Get all FCM tokens for a user from Firestore."""
    try:
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            print(f"❌ User {user_id} not found in Firestore")
            return None
        
        user_data = user_doc.to_dict()
        fcm_tokens = user_data.get('fcmTokens', {})
        
        if not fcm_tokens:
            print(f"❌ No FCM tokens found for user {user_id}")
            return None
        
        print(f"✅ Found FCM tokens for user {user_id}:")
        for platform, token_data in fcm_tokens.items():
            token = token_data.get('token', 'N/A')
            print(f"   - {platform}: {token[:20]}...")
        
        return fcm_tokens
    
    except Exception as e:
        print(f"❌ Error fetching user tokens: {e}")
        return None


def send_test_notification(user_id: str):
    """Send a test notification to all devices of a user."""
    fcm_tokens = get_user_fcm_tokens(user_id)
    
    if not fcm_tokens:
        return
    
    # Prepare notification message
    notification = messaging.Notification(
        title="🔔 Test Notification",
        body="Your FCM integration is working perfectly! 🎉",
    )
    
    # Data payload (optional)
    data = {
        'type': 'test',
        'message': 'This is a test notification from Dharma CMS',
        'timestamp': str(firestore.SERVER_TIMESTAMP)
    }
    
    success_count = 0
    fail_count = 0
    
    # Send to each platform
    for platform, token_data in fcm_tokens.items():
        token = token_data.get('token')
        
        if not token:
            print(f"⚠️  Skipping {platform} - no token")
            continue
        
        try:
            # Create message
            message = messaging.Message(
                notification=notification,
                data=data,
                token=token,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        sound='default',
                        channel_id='high_importance_channel'
                    )
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(
                            sound='default',
                            badge=1
                        )
                    )
                )
            )
            
            # Send message
            response = messaging.send(message)
            print(f"✅ Notification sent to {platform}: {response}")
            success_count += 1
            
        except Exception as e:
            print(f"❌ Failed to send to {platform}: {e}")
            fail_count += 1
    
    print(f"\n📊 Summary:")
    print(f"   ✅ Success: {success_count}")
    print(f"   ❌ Failed: {fail_count}")
    print(f"   📱 Total platforms: {len(fcm_tokens)}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("❌ Usage: python test_fcm_notification.py <user_id>")
        print("\nExample:")
        print("   python test_fcm_notification.py 1lgPtK4GNDZTHAZkgvwsVhF7A983")
        sys.exit(1)
    
    user_id = sys.argv[1]
    print(f"🚀 Sending test notification to user: {user_id}\n")
    send_test_notification(user_id)
