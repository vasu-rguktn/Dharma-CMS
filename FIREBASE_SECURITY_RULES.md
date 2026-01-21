# Firebase Security Rules - Crime Scene Evidence

## ✅ Updated Security Rules

I've updated both **Firestore** and **Firebase Storage** security rules to support the new crime scene evidence capture and AI analysis features.

## 📋 What Was Updated

### 1. Firestore Rules (`firestore.rules`)

Added rules for three new data structures:

#### A. Crime Details Collection
```
/crimeDetails/{caseId}
```
- **Create**: Police only
- **Read**: Police + case owner (citizen)
- **Update**: Police only
- **Delete**: Police only

**Purpose**: Stores detailed crime scene information including crime type, place description, and physical evidence details.

#### B. Media Analyses Subcollection
```
/cases/{caseId}/mediaAnalyses/{analysisId}
```
- **Create**: Police only
- **Read**: Police + case owner
- **Update/Delete**: Police only

**Purpose**: Stores AI-powered media analysis results (existing feature).

#### C. Scene Analyses Subcollection (NEW)
```
/cases/{caseId}/sceneAnalyses/{analysisId}
```
- **Create**: Police only
- **Read**: Police + case owner
- **Update/Delete**: Police only

**Purpose**: Stores AI-powered crime scene analysis from Gemini API.

**Data Structure**:
```javascript
{
  analysisText: "Detailed forensic report...",
  evidenceFiles: ["path1", "path2", "path3"],
  createdAt: Timestamp,
  analyzedBy: "Gemini AI"
}
```

### 2. Firebase Storage Rules (`storage.rules`)

Created comprehensive storage rules for file uploads:

#### A. Crime Scene Evidence
**Path**: `/crime-scene-evidence/{caseId}/{filename}`

- **Upload**: Police only
- **Max Size**: 50MB
- **Allowed Types**: Images, Videos, PDFs
- **Read**: Police + case owner
- **Update/Delete**: Police only

#### B. Geo-Tagged Evidence
**Path**: `/geo-evidence/{caseId}/{filename}`

- **Upload**: Police only
- **Max Size**: 50MB
- **Allowed Types**: Images, Videos (with GPS metadata)
- **Read**: Police + case owner
- **Update/Delete**: Police only

#### C. Case Documents
**Path**: `/case-documents/{caseId}/{filename}`

- **Upload**: Police + case owner
- **Max Size**: 10MB
- **Read**: Police + case owner
- **Update/Delete**: Police + case owner

#### D. Investigation Reports
**Path**: `/investigation-reports/{caseId}/{filename}`

- **Upload**: Police only
- **Max Size**: 10MB
- **Allowed Types**: PDF only
- **Read**: Police + case owner
- **Update/Delete**: Police only

#### E. Other Paths
- **Petition Documents**: `/petition-documents/{petitionId}/{filename}`
- **Profile Pictures**: `/profile-pictures/{userId}/{filename}`
- **Complaint Attachments**: `/complaint-attachments/{complaintId}/{filename}`

## 🔒 Security Features

### 1. Role-Based Access Control

**Police Officers**:
- Must be authenticated
- Must exist in `/police/{uid}` collection
- Must have `role == 'police'`
- Must have `isApproved == true`

**Citizens**:
- Can only access their own cases
- Verified by checking `cases/{caseId}.userId == auth.uid`

### 2. File Size Limits

| File Type | Max Size | Purpose |
|-----------|----------|---------|
| Crime Scene Evidence | 50MB | Photos/Videos |
| Geo-Tagged Evidence | 50MB | GPS-tagged media |
| Case Documents | 10MB | General files |
| Investigation Reports | 10MB | PDF reports |
| Profile Pictures | 5MB | User avatars |
| Complaint Attachments | 20MB | Citizen uploads |

### 3. Content Type Validation

- **Images**: `image/*` (JPEG, PNG, etc.)
- **Videos**: `video/*` (MP4, MOV, etc.)
- **Documents**: `application/pdf`

### 4. Privacy Protection

- **Citizens** can only see evidence for their own cases
- **Police** can see all evidence (for investigation)
- **Unauthorized users** have no access

## 🚀 Deployment

### Deploy Firestore Rules

```bash
cd c:\Users\APSSDC\Desktop\main\Dharma-CMS
firebase deploy --only firestore:rules
```

### Deploy Storage Rules

```bash
firebase deploy --only storage
```

### Deploy Both

```bash
firebase deploy --only firestore:rules,storage
```

## 📝 Testing the Rules

### Test Firestore Rules

1. **As Police Officer**:
```javascript
// Should succeed
await firestore.collection('cases')
  .doc(caseId)
  .collection('sceneAnalyses')
  .add({
    analysisText: "Test analysis",
    evidenceFiles: ["file1.jpg"],
    createdAt: FieldValue.serverTimestamp(),
    analyzedBy: "Gemini AI"
  });
```

2. **As Citizen (Case Owner)**:
```javascript
// Should succeed (read only)
const analyses = await firestore.collection('cases')
  .doc(myCaseId)
  .collection('sceneAnalyses')
  .get();

// Should fail (no write permission)
await firestore.collection('cases')
  .doc(myCaseId)
  .collection('sceneAnalyses')
  .add({...}); // ❌ Permission denied
```

3. **As Unauthorized User**:
```javascript
// Should fail
const analyses = await firestore.collection('cases')
  .doc(otherCaseId)
  .collection('sceneAnalyses')
  .get(); // ❌ Permission denied
```

### Test Storage Rules

1. **Upload Crime Scene Evidence (Police)**:
```dart
final storageRef = FirebaseStorage.instance
  .ref()
  .child('crime-scene-evidence/$caseId/evidence_${DateTime.now().millisecondsSinceEpoch}.jpg');

await storageRef.putFile(imageFile); // ✅ Should succeed
```

2. **Upload as Citizen**:
```dart
final storageRef = FirebaseStorage.instance
  .ref()
  .child('crime-scene-evidence/$caseId/test.jpg');

await storageRef.putFile(imageFile); // ❌ Should fail
```

## ⚠️ Important Notes

### 1. Current Implementation

The current code in `case_detail_screen.dart` stores:
- **Analysis data** → Firestore (`sceneAnalyses` subcollection) ✅
- **File paths** → Local device storage

**Files are NOT uploaded to Firebase Storage yet!**

### 2. To Enable Cloud Storage

You need to modify `case_detail_screen.dart` to upload files:

```dart
Future<void> _analyzeSceneWithAI() async {
  // ... existing code ...
  
  // Upload files to Firebase Storage
  List<String> uploadedUrls = [];
  for (String filePath in _crimeSceneAttachments) {
    final file = File(filePath);
    final fileName = path.basename(filePath);
    final storageRef = FirebaseStorage.instance
      .ref()
      .child('geo-evidence/${widget.caseId}/$fileName');
    
    await storageRef.putFile(file);
    final downloadUrl = await storageRef.getDownloadURL();
    uploadedUrls.add(downloadUrl);
  }
  
  // Save to Firestore with cloud URLs
  await FirebaseFirestore.instance
    .collection('cases')
    .doc(widget.caseId)
    .collection('sceneAnalyses')
    .add({
      'analysisText': analysisText,
      'evidenceFiles': uploadedUrls, // Cloud URLs instead of local paths
      'createdAt': FieldValue.serverTimestamp(),
      'analyzedBy': 'Gemini AI',
    });
}
```

### 3. File Persistence

**Current**: Files stored locally (lost if app uninstalled)
**Recommended**: Upload to Firebase Storage (permanent, accessible from any device)

### 4. Bandwidth Considerations

- Uploading 50MB videos uses significant bandwidth
- Consider compression for large files
- Show upload progress to users
- Handle network errors gracefully

## 🔍 Rule Validation

### Check for Errors

After deploying, check Firebase Console:
1. Go to Firebase Console
2. Navigate to Firestore → Rules
3. Look for validation errors
4. Test with the Rules Playground

### Common Issues

**Issue**: `get() calls nested too deep`
**Solution**: Rules are optimized to avoid this

**Issue**: `Permission denied`
**Solution**: Verify user is authenticated and has correct role

**Issue**: `File size exceeded`
**Solution**: Check file size limits in rules

## 📊 Data Flow

### Evidence Capture Flow

```
1. Police captures photo with geo-camera
   ↓
2. File saved to local storage
   ↓
3. File path added to _crimeSceneAttachments
   ↓
4. Police taps "Analyze Scene with AI"
   ↓
5. Gemini API analyzes image
   ↓
6. Analysis saved to Firestore
   ↓
7. (Optional) Upload file to Storage
   ↓
8. Download URL saved to Firestore
```

### Access Control Flow

```
User requests access to evidence
   ↓
Check: Is user authenticated?
   ↓ Yes
Check: Is user police?
   ↓ Yes → Grant access
   ↓ No
Check: Does user own the case?
   ↓ Yes → Grant access
   ↓ No → Deny access
```

## ✅ Summary

**Firestore Rules**:
- ✅ `crimeDetails` collection
- ✅ `sceneAnalyses` subcollection
- ✅ `mediaAnalyses` subcollection
- ✅ Role-based access control
- ✅ Case ownership validation

**Storage Rules**:
- ✅ Crime scene evidence paths
- ✅ Geo-tagged evidence paths
- ✅ File size limits
- ✅ Content type validation
- ✅ Access control by role

**Next Steps**:
1. Deploy rules to Firebase
2. Test with police and citizen accounts
3. (Optional) Implement cloud storage upload
4. Monitor usage and adjust limits

The security rules are now ready to support your crime scene evidence feature! 🎉
