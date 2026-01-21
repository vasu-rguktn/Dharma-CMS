# Offline Petition Storage in Firestore - Complete Guide

## 📊 Firestore Collection Structure

### Main Collection: `petitions`

All petitions (both online and offline) are stored in the **`petitions`** collection in Firestore.

## 🔑 Offline Petition Document Structure

```javascript
{
  // Basic Petition Info
  "id": "Petition_JohnDoe_2026-01-21_09-30-00",
  "case_id": "case-Eluru-TownPoliceStation-20260121-1234567",
  "title": "Request for Protection",
  "type": "Writ Petition",
  "status": "Filed",
  
  // Petitioner Details
  "petitionerName": "John Doe",
  "phoneNumber": "+919876543210",
  "address": "123 Main Street, Eluru",
  "grounds": "Detailed grounds of the petition...",
  "prayerRelief": "Relief sought...",
  
  // Location/Jurisdiction
  "district": "Eluru",
  "stationName": "Town Police Station",
  "incidentAddress": "Location of incident",
  "incidentDate": Timestamp(2026, 01, 15),
  
  // Police Status
  "policeStatus": "Pending",
  "policeSubStatus": null,
  
  // ⭐ OFFLINE SUBMISSION FIELDS ⭐
  "submissionType": "offline",              // 'online' or 'offline'
  "submittedBy": "uid_of_sp_officer",       // UID of officer who submitted
  "submittedByName": "SP Ram Kumar",        // Officer name
  "submittedByRank": "Superintendent of Police",  // Officer rank
  
  // ⭐ ASSIGNMENT FIELDS ⭐
  "assignmentType": "officer",              // 'officer', 'station', 'district', 'range'
  "assignedTo": "uid_of_assigned_officer",  // Officer UID assigned to
  "assignedToName": "Inspector Sharma",     // Assigned officer name
  "assignedToRank": "Circle Inspector",     // Assigned officer rank
  "assignedToStation": "Town Police Station", // If assigned to station
  "assignedToDistrict": null,               // If assigned to district
  "assignedToRange": null,                  // If assigned to range
  "assignedBy": "uid_of_sp_officer",        // UID of officer who assigned
  "assignedByName": "SP Ram Kumar",         // Name of assigning officer
  "assignedAt": Timestamp(2026, 01, 21, 09, 30), // Assignment timestamp
  "assignmentStatus": "pending",            // 'pending', 'accepted', 'rejected'
  "assignmentNotes": "Handle with priority", // Optional notes
  
  // Documents
  "handwrittenDocumentUrl": "https://storage.../handwritten.pdf",
  "proofDocumentUrls": ["https://storage.../proof1.jpg", "..."],
  "extractedText": "OCR extracted text...",
  
  // Metadata
  "userId": "system_offline_petitions",     // Special userId for offline
  "createdAt": Timestamp(2026, 01, 21),
  "updatedAt": Timestamp(2026, 01, 21)
}
```

## 🔄 Data Flow: How Offline Petitions are Created & Assigned

### Step 1: Offline Petition Submission (by SP-level officer)
**Screen**: `SubmitOfflinePetitionScreen`

```dart
// Officer submits offline petition
final petition = Petition(
  title: "Petition Title",
  petitionerName: "Citizen Name",
  // ... other fields
  
  // Mark as offline submission
  submissionType: 'offline',
  submittedBy: currentOfficer.uid,
  submittedByName: currentOfficer.name,
  submittedByRank: currentOfficer.rank,
  
  // Assignment details
  assignedTo: selectedOfficer.uid,
  assignedToName: selectedOfficer.name,
  assignedBy: currentOfficer.uid,
  assignedByName: currentOfficer.name,
  assignedAt: Timestamp.now(),
  assignmentStatus: 'pending',
);

// Save to Firestore
await firestore.collection('petitions').doc(petitionId).set(petition.toMap());
```

**Result**: Document created in `petitions` collection with `submissionType: 'offline'`

---

### Step 2: Querying Sent Petitions (High-level officers)
**Screen**: `OfflinePetitionsScreen` - Sent Tab

```dart
// Query petitions assigned BY this officer
QuerySnapshot snapshot = await firestore
  .collection('petitions')
  .where('assignedBy', isEqualTo: currentOfficer.uid)
  .where('submissionType', isEqualTo: 'offline')
  .orderBy('assignedAt', descending: true)
  .get();
```

**Shows**: All petitions this officer has assigned to others

---

### Step 3: Querying Assigned Petitions (All officers)
**Screen**: `OfflinePetitionsScreen` - Assigned Tab

```dart
// Query petitions assigned TO this officer
QuerySnapshot snapshot = await firestore
  .collection('petitions')
  .where('assignedTo', isEqualTo: currentOfficer.uid)
  .where('submissionType', isEqualTo: 'offline')
  .orderBy('assignedAt', descending: true)
  .get();
```

**Shows**: All petitions assigned to this officer

---

### Step 4: Accepting/Rejecting Assignment

```dart
// Officer accepts or rejects the assignment
await firestore
  .collection('petitions')
  .doc(petitionId)
  .update({
    'assignmentStatus': 'accepted', // or 'rejected'
    'updatedAt': FieldValue.serverTimestamp(),
  });
```

---

## 🎯 Key Distinguishing Fields

### To Identify Offline Petitions:
```dart
submissionType == 'offline'
```

### To Track Assignment Chain:
- **`assignedBy`**: Who assigned it
- **`assignedTo`**: Who received it
- **`assignedAt`**: When it was assigned
- **`assignmentStatus`**: Current status (pending/accepted/rejected)

### To Support Organizational Assignments:
- **`assignmentType`**: 'officer', 'station', 'district', or 'range'
- **`assignedToStation`**: Station name if assigned to a station
- **`assignedToDistrict`**: District name if assigned to a district
- **`assignedToRange`**: Range name if assigned to a range

---

## 📊 Firestore Indexes Required

For efficient queries, create these composite indexes:

### Index 1: Sent Petitions Query
```
Collection: petitions
Fields:
  - assignedBy (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)
```

### Index 2: Assigned Petitions Query
```
Collection: petitions
Fields:
  - assignedTo (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)
```

### Index 3: Station Assignments Query
```
Collection: petitions
Fields:
  - assignedToStation (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)
```

### Index 4: District Assignments Query
```
Collection: petitions
Fields:
  - assignedToDistrict (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)
```

### Index 5: Range Assignments Query
```
Collection: petitions
Fields:
  - assignedToRange (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)
```

**Note**: Firebase will prompt you to create these indexes automatically when you run queries. Just click the provided link!

---

## 🔍 Example Queries in Action

### 1. Get All Offline Petitions
```dart
final allOffline = await firestore
  .collection('petitions')
  .where('submissionType', isEqualTo: 'offline')
  .get();
```

### 2. Get Pending Assignments for an Officer
```dart
final pending = await firestore
  .collection('petitions')
  .where('assignedTo', isEqualTo: officerId)
  .where('assignmentStatus', isEqualTo: 'pending')
  .where('submissionType', isEqualTo: 'offline')
  .get();
```

### 3. Get All Petitions Assigned by DGP
```dart
final dgpAssignments = await firestore
  .collection('petitions')
  .where('assignedBy', isEqualTo: dgpUid)
  .where('submissionType', isEqualTo: 'offline')
  .orderBy('assignedAt', descending: true)
  .get();
```

### 4. Get Accepted Assignments
```dart
final accepted = await firestore
  .collection('petitions')
  .where('assignedTo', isEqualTo: officerId)
  .where('assignmentStatus', isEqualTo: 'accepted')
  .where('submissionType', isEqualTo: 'offline')
  .get();
```

---

## 📝 Related Collection: `petition_updates`

Each petition can have multiple updates tracked in a separate collection:

```javascript
// Collection: petition_updates
{
  "petitionId": "Petition_JohnDoe_2026-01-21",
  "updateText": "Investigation started",
  "photoUrls": ["url1", "url2"],
  "documents": [
    {"name": "report.pdf", "url": "storage_url"}
  ],
  "addedBy": "Inspector Sharma",
  "addedByUserId": "uid_inspector",
  "createdAt": Timestamp(2026, 01, 21)
}
```

---

## 🔐 Security Rules Recommendations

Add these Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Petitions collection
    match /petitions/{petitionId} {
      // Police can read all petitions
      allow read: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'police';
      
      // Only SP-level and above can create offline petitions
      allow create: if request.auth != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'police' &&
                       isHighLevelOfficer(request.auth.uid) &&
                       request.resource.data.submissionType == 'offline';
      
      // Assigned officers can update assignment status
      allow update: if request.auth != null && 
                       resource.data.assignedTo == request.auth.uid &&
                       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['assignmentStatus', 'updatedAt']);
    }
    
    // Helper function
    function isHighLevelOfficer(uid) {
      let rank = get(/databases/$(database)/documents/users/$(uid)).data.rank;
      return rank in ['DGP', 'ADGP', 'IGP', 'DIG', 'SP', 
                      'Superintendent of Police',
                      'Inspector General of Police'];
    }
  }
}
```

---

## 📊 Summary

### **Storage Location**: 
- Main Collection: `petitions`
- Updates Collection: `petition_updates`

### **Key Identifier**:
- `submissionType: 'offline'`

### **Assignment Tracking**:
- `assignedBy` + `assignedTo` + `assignedAt` + `assignmentStatus`

### **Query Patterns**:
1. **Sent Petitions**: Filter by `assignedBy == currentOfficer`
2. **Assigned Petitions**: Filter by `assignedTo == currentOfficer`
3. **Both**: Must include `submissionType == 'offline'`

### **Access Control**:
- Submission: SP-level and above only
- Viewing: All police officers
- Updating: Assigned officer can accept/reject

---

## 🎯 Benefits of This Structure

1. ✅ **No separate collection needed** - Uses existing `petitions` collection
2. ✅ **Complete audit trail** - Track who submitted, who assigned, who accepted
3. ✅ **Flexible querying** - Can query by submitter, assignee, or status
4. ✅ **Scalable** - Works with millions of petitions
5. ✅ **Integrated** - Works seamlessly with existing petition features
6. ✅ **Secure** - Role-based access control through Firestore rules

---

This structure ensures efficient storage, quick retrieval, and complete traceability of all offline petition assignments! 🚀
