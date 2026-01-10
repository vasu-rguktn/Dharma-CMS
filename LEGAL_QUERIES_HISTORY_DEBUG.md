# Legal Queries History Troubleshooting Guide

## 🔍 Issue: Chat History Not Showing in Drawer

The legal queries chat history drawer is not displaying previous chat sessions.

---

## ✅ What I've Done

### 1. **Added Debug Logging**

I've added comprehensive debug prints to both:
- **Provider** (`legal_queries_provider.dart`): 
  - Logs the userId being queried
  - Logs how many sessions are found
  - Lists all session IDs and titles
  
- **UI** (`legal_queries_screen.dart`):
  - Logs StreamBuilder state
  - Shows connection state, hasData, hasError
  - Displays session count when data arrives

### 2. **Added Error Handling**

The StreamBuilder now shows error messages if Firestore query fails.

---

## 🧪 How to Debug

### Step 1: **Run the App & Open Legal Queries**

1. Hot restart your app (full restart, not hot reload)
2. Log in as a user
3. Navigate to Legal Queries
4. Open the drawer (history icon)

### Step 2: **Check the Console Logs**

Look for these debug messages:

```
🔍 [LEGAL_QUERIES] Querying chat sessions for userId: [user-id]
📚 [LEGAL_QUERIES] Found X chat sessions
  - Session: [session-id], Title: [title]
  ...
🗂️ [LEGAL_QUERIES] History StreamBuilder state:
   - hasData: true/false
   - hasError: true/false
   - error: null or error message
   - connectionState: [state]
   - sessions count: X
```

### Step 3: **Diagnose Based on Output**

#### **Scenario A: "Found 0 chat sessions"**
**Problem**: No chat documents exist for this user in Firestore.

**Solutions**:
1. Send a message in Legal Queries to create a session
2. Check if `createNewSession()` is saving with correct `userId` field
3. Verify the user is logged in (check userId in logs)

#### **Scenario B: "hasError: true"**
**Problem**: Firestore permission error or query issue.

**Solutions**:
1. Check if you deployed the updated Firestore rules
2. Verify Firebase Console → Firestore → Rules includes legal_queries_chats rules
3. Check the error message for specific permission issues

#### **Scenario C: "hasData: false" (stuck on loading)**
**Problem**: Stream not connecting or timing out.

**Solutions**:
1. Check internet connection
2. Verify Firebase is initialized correctly
3. Check if user authentication is valid

#### **Scenario D: "Found 2 chat sessions" but still shows "No previous chats"**
**Problem**: Data mismatch or UI issue.

**Solutions**:
1. Check if sessions array is being processed correctly
2. Verify the map structure matches expected format
3. Look for JavaScript console errors if on web

---

## 🔧 Additional Checks

### Check 1: Firestore Database

1. Go to **Firebase Console** → **Firestore Database**
2. Look for `legal_queries_chats` collection
3. Check if documents exist:
   - Each document should have `userId`, `title`, `createdAt`, `lastMessageAt` fields
   - The `userId` should match your current user's UID
4. Check `messages` subcollection under each session

### Check 2: Firestore Rules

Verify these rules are deployed:

```javascript
match /legal_queries_chats/{sessionId} {
  allow read: if request.auth != null &&
    resource.data.userId == request.auth.uid;
  // ... other rules
}
```

### Check 3: User Authentication

```dart
// In your app, log the current user
final user = FirebaseAuth.instance.currentUser;
print('Current user UID: ${user?.uid}');
```

Then check if sessions in Firestore have matching `userId` field.

---

## 🐛 Common Issues & Fixes

### Issue 1: **Permission Denied**

**Error**: `[cloud_firestore/permission-denied]`

**Fix**: 
1. Deploy updated Firestore rules (from earlier fix)
2. Wait 30 seconds for rules to propagate
3. Restart the app

### Issue 2: **Sessions Created but Not Showing**

**Cause**: `userId` field mismatch

**Fix**:
```dart
// Check createNewSession() in provider
final doc = await _firestore.collection('legal_queries_chats').add({
  'userId': uid,  // ✅ This must match current user UID
  'title': 'New Chat',
  'createdAt': FieldValue.serverTimestamp(),
  'lastMessageAt': FieldValue.serverTimestamp(),
});
```

### Issue 3: **Empty Title**

**Cause**: Title not being set properly

**Fix**: Check if backend is returning `title` field and provider is updating it:
```dart
await sessionRef.update({'title': title});
```

### Issue 4: **StreamBuilder Rebuilding Constantly**

**Cause**: Provider being recreated

**Fix**: Ensure `LegalQueriesProvider` is in the app's root provider tree, not created locally.

---

## ✅ Expected Behavior

When everything works:

1. **Send first message** → Creates new session automatically
2. **Session appears in Firestore** with userId, title, timestamps
3. **Drawer opens** → Shows loading spinner briefly
4. **History displays** → Shows session with title
5. **Tap session** → Opens that conversation
6. **Send more messages** → Updates lastMessageAt timestamp
7. **Drawer refreshes** → Shows updated session order

---

## 📋 Quick Test Checklist

- [ ] Firestore rules deployed
- [ ] User is logged in
- [ ] Send a test message in Legal Queries
- [ ] Check Firestore Console for new session document
- [ ] Verify `userId` field matches current user UID
- [ ] Open history drawer
- [ ] Check console logs for debug output
- [ ] Verify session appears in drawer
- [ ] Tap session to open it
- [ ] Send another message to different session
- [ ] Check if both sessions appear in drawer

---

## 🔬 Next Steps

After running the app with debug logs:

1. **Copy all console output** related to `[LEGAL_QUERIES]`
2. **Check Firestore Console** for actual data
3. **Share the logs** if issue persists - they'll show exactly what's happening

The debug logs will reveal:
- ✅ If sessions are being created
- ✅ If the query is finding sessions
- ✅ If there are permission errors
- ✅ If the UI is receiving data
- ✅ What the data structure looks like

---

## 💡 Pro Tip

You can also manually check the stream in Flutter DevTools:
1. Open Flutter DevTools
2. Go to "Provider" tab (if you have provider_inspector)
3. Find `LegalQueriesProvider`
4. Inspect `chatSessionsStream()` output

Or use Firestore debugging:
```dart
// Add this temporarily to see raw Firestore data
FirebaseFirestore.instance
  .collection('legal_queries_chats')
  .get()
  .then((snapshot) {
    print('All sessions in database: ${snapshot.docs.length}');
    for (var doc in snapshot.docs) {
      print('Session: ${doc.id} - ${doc.data()}');
    }
  });
```
