# Offline Petition Permission Error - Investigation

## Issue Summary
**Error**: `[cloud_firestore/permission-denied] Missing or insufficient permissions`

## Investigation Results

### Initial Diagnosis (CORRECTED)
I initially thought there was a mismatch between the code and Firebase rules, but after checking your Firebase console, I found:

- **Firebase Console Rules**: `offlinepetitions` (no underscore) ✅
- **Local firestore.rules file**: `offline_petitions` (with underscore) ❌ (out of sync)
- **Code**: `offlinepetitions` (no underscore) ✅

**The code was CORRECT all along!** The local `firestore.rules` file was out of sync with what's deployed in Firebase.

### Fixes Applied
1. ✅ **Synced local firestore.rules** to match Firebase console (changed to `offlinepetitions`)
2. ✅ **Code remains unchanged** - already using the correct collection name

## Real Cause of Permission Error

Since the collection name was correct, the permission error is likely caused by one of these issues:

### 1. **Police Profile Not Properly Set Up**
The `isPolice()` helper function requires:
```
/police/{uid} document must exist with:
- role == 'police'
- isApproved == true
```

**Check**: Does the current user have a proper police profile?

### 2. **AssignedBy Field Mismatch**
The security rule requires:
```
request.resource.data.assignedBy == request.auth.uid
```

**Check**: Is the `assignedBy` field being set to the correct authenticated user's UID?

### 3. **User Not Authenticated**
**Check**: Is `request.auth` actually populated? Is the user logged in via Firebase Auth?

## Debugging Steps

### Step 1: Verify Police Profile
Check Firestore console for `/police/{uid}` document:
```
Collection: police
Document ID: <user's UID>
Fields:
  - uid: <user's UID>
  - role: "police"
  - isApproved: true
```

### Step 2: Check Authentication
In your app, verify:
```dart
final user = FirebaseAuth.instance.currentUser;
print('🔐 User ID: ${user?.uid}');
print('🔐 Is authenticated: ${user != null}');
```

### Step 3: Verify Data Being Submitted
Check the petition data before submission:
```dart
print('👤 Submitted by: ${petition.submittedBy}');
print('🔐 Current user: ${FirebaseAuth.instance.currentUser?.uid}');
print('✅ Match: ${petition.submittedBy == FirebaseAuth.instance.currentUser?.uid}');
```

## Firebase Security Rule (Current - Deployed)
```javascript
match /offlinepetitions/{petitionId} {
  allow create: if isPolice() &&
    request.resource.data.assignedBy == request.auth.uid;
}
```

## Next Steps
1. **Verify police profile** exists with correct fields
2. **Check authentication** status
3. **Verify assignedBy** field matches authenticated user's UID
4. **Test submission** again and review error logs
