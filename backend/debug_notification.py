from google.cloud import firestore

db = firestore.Client()

# Get the petition
petition_id = 'Petition_Eluru_girl_2026-01-22_12-23-28'
petition = db.collection('petitions').document(petition_id).get()

if petition.exists:
    petition_data = petition.to_dict()
    user_id = petition_data.get('userId', 'NOT FOUND')
    print(f'✅ Petition found!')
    print(f'📋 Petition userId: {user_id}')
    
    # Check for FCM tokens
    tokens_ref = db.collection('fcm_tokens')
    tokens_query = tokens_ref.where('userId', '==', user_id).where('isActive', '==', True).stream()
    
    tokens = list(tokens_query)
    print(f'🔑 FCM Tokens found: {len(tokens)}')
    
    if tokens:
        for i, token_doc in enumerate(tokens, 1):
            token_data = token_doc.to_dict()
            print(f'   Token {i}: {token_data.get("token", "")[:50]}...')
            print(f'   Platform: {token_data.get("platform", "unknown")}')
            print(f'   Active: {token_data.get("isActive", False)}')
    else:
        print('❌ NO FCM TOKENS FOUND FOR THIS USER!')
        print(f'   Searching for userId: {user_id}')
else:
    print('❌ Petition not found')
