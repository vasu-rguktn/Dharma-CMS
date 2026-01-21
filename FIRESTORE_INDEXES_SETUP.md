# Firestore Indexes Setup

## Issue
**Error**: `The query requires an index`

This happens when you query Firestore with both filtering (`.where()`) and sorting (`.orderBy()`). Firestore needs composite indexes for these queries.

## Quick Fix - Create Indexes via Console

### Method 1: Use Auto-Generated Links (EASIEST)
When you see the error, Firebase provides a direct link. Click it to auto-create the index.

**Current Required Index**:
- Collection: `offlinepetitions`
- Fields: `assignedBy` (ASC) + `assignedAt` (DESC)
- **Link**: [Create Index](https://console.firebase.google.com/v1/r/project/dharma-cms-5cc89/firestore/indexes?create_composite=Cllwcm9qZWN0cy9kaGFybWEtY21zLTVjYzg5L2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9vZmZsaW5lcGV0aXRpb25zL2luZGV4ZXMvXxABGg4KCmFzc2lnbmVkQnkQARoOCgphc3NpZ25lZEF0EAIaDAoIX19uYW1lX18QAg)

### Method 2: Deploy All Indexes at Once

I've created a `firestore.indexes.json` file with all the indexes your app needs.

**Deploy using Firebase CLI**:

```powershell
# 1. Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Initialize Firestore in your project (if not done)
firebase init firestore

# 4. Deploy indexes
firebase deploy --only firestore:indexes
```

## All Required Indexes

### 1. Offline Petitions - Sent (assignedBy + assignedAt)
```
Collection: offlinepetitions
Fields:
  - assignedBy (Ascending)
  - assignedAt (Descending)
```

### 2. Offline Petitions - Assigned (assignedTo + assignedAt)
```
Collection: offlinepetitions
Fields:
  - assignedTo (Ascending)
  - assignedAt (Descending)
```

### 3. Offline Petitions - Status Counts (assignedTo + assignmentStatus)
```
Collection: offlinepetitions
Fields:
  - assignedTo (Ascending)
  - assignmentStatus (Ascending)
```

### 4. Petitions - Station View (stationName + createdAt)
```
Collection: petitions
Fields:
  - stationName (Ascending)
  - createdAt (Descending)
```

### 5. Petitions - Station + Status Filter
```
Collection: petitions
Fields:
  - stationName (Ascending)
  - policeStatus (Ascending)
  - createdAt (Descending)
```

### 6. Petition Updates - Timeline
```
Collection: petition_updates
Fields:
  - petitionId (Ascending)
  - addedAt (Descending)
```

## Manual Creation (if needed)

If the auto-link doesn't work:

1. Go to **Firebase Console** → Your Project → **Firestore Database**
2. Click **Indexes** tab
3. Click **Create Index**
4. Enter:
   - **Collection ID**: `offlinepetitions`
   - **Fields to index**:
     - Field: `assignedBy`, Order: Ascending
     - Field: `assignedAt`, Order: Descending
5. Click **Create**
6. Wait 1-2 minutes for index to build

## Verification

After creating indexes:
1. Wait for "Building" status to change to "Enabled" (1-2 minutes)
2. Restart your Flutter app
3. Try fetching sent petitions again
4. The error should be gone ✅

## Notes

- Indexes are **one-time setup** - once created, they work forever
- Each new compound query needs its own index
- Firebase will tell you when you need a new index (with the helpful link!)
- The `firestore.indexes.json` file helps track all indexes in your codebase
