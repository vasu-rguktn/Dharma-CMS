from google.cloud import firestore

db = firestore.Client()

# Get all active FCM tokens
tokens_ref = db.collection('fcm_tokens')
active_tokens_query = tokens_ref.where('isActive', '==', True)
tokens = list(active_tokens_query.stream())

print(f'✅ Total active FCM tokens: {len(tokens)}\n')

if tokens:
    for i, token_doc in enumerate(tokens[:10], 1):
        token_data = token_doc.to_dict()
        user_id = token_data.get('userId', 'UNKNOWN')
        platform = token_data.get('platform', 'unknown')
        token_preview = token_data.get('token', '')[:30] if token_data.get('token') else 'NO TOKEN'
        print(f'{i}. userId: {user_id}')
        print(f'   Platform: {platform}')
        print(f'   Token: {token_preview}...')
        print()
else:
    print('❌ NO ACTIVE FCM TOKENS FOUND!')
