# Debugging: Offline Petitions Not Showing

## 🔍 Common Issues & Solutions

### **Issue 1: Firestore Indexes Not Created**

**Symptoms:**
- Petition submits successfully
- But doesn't appear in Sent/Assigned tabs
- Browser console shows index error

**Solution:**
1. Open browser console (F12)
2. Look for errors like: `"The query requires an index"`
3. Click the provided link to auto-create the index
4. Wait 2-3 minutes for index to build
5. Refresh the page

**Required Indexes:**

Create these composite indexes in Firestore:

**Index 1: Sent Petitions**
```
Collection: petitions
Fields:
  - assignedBy (Ascending)
  - submissionType (Ascending)  
  - assignedAt (Descending)
Query Scope: Collection
```

**Index 2: Assigned Petitions**
```
Collection: petitions
Fields:
  - assignedTo (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)
Query Scope: Collection
```

**To create manually:**
1. Go to Firestore Console
2. Click "Indexes" tab
3. Click "Create Index"
4. Select "petitions" collection
5. Add fields as shown above
6. Click "Create"

---

### **Issue 2: Petition Missing Required Fields**

**Check if petition has these fields:**

```javascript
{
  "submissionType": "offline",        // ← MUST BE 'offline'
  "assignedBy": "officer_uid",        // ← For Sent tab
  "assignedTo": "officer_uid",        // ← For Assigned tab (if assigned)
  "assignedAt": Timestamp             // ← Must exist for ordering
}
```

**How to check:**
1. Open Firestore Console
2. Click "petitions" collection
3. Find your submitted petition
4. Verify these fields exist

**If fields are missing:**
The petition might have been created with the old PetitionProvider instead of OfflinePetitionProvider.

---

### **Issue 3: Officer UID Mismatch**

**Problem:**
- Petition saves with one UID
- Query uses different UID

**Check:**
1. In Firestore, note the `assignedBy` value
2. In browser console, run:
   ```javascript
   // Check current officer UID
   console.log(firebase.auth().currentUser.uid);
   ```
3. Compare - they should match!

---

### **Issue 4: No Assignment Data**

**For Sent Tab to show petitions:**
- Petition MUST have `assignedBy` field
- `assignedBy` must equal current officer's UID
- `assignedAt` timestamp must exist

**For Assigned Tab to show petitions:**
- Petition MUST have `assignedTo` field
- `assignedTo` must equal current officer's UID
- `assignedAt` timestamp must exist

**Check:**
If you submit WITHOUT immediate assignment, the petition will NOT appear in Sent tab because there's no `assignedBy` field.

**Solution:**
Always enable "Assign to officer immediately" when submitting offline petitions.

---

### **Issue 5: Provider Not Fetching**

**Debug the provider:**

Add console logs to check if methods are being called:

```dart
// In offline_petition_provider.dart

Future<void> fetchSentPetitions(String officerId) async {
  debugPrint('🔍 [DEBUG] fetchSentPetitions called with: $officerId');
  // ... rest of code
  
  debugPrint('✅ [DEBUG] Fetched ${_sentPetitions.length} sent petitions');
  debugPrint('📊 [DEBUG] Petitions: ${_sentPetitions.map((p) => p.id).toList()}');
}
```

Check Flutter console for these debug prints.

---

## 🛠️ Step-by-Step Debugging

### **Step 1: Verify Petition is in Firestore**

1. Open Firestore Console
2. Navigate to `petitions` collection
3. Look for your petition
4. Check if it has:
   - ✅ `submissionType: 'offline'`
   - ✅ `assignedBy: 'your_officer_uid'`
   - ✅ `assignedAt: Timestamp`

### **Step 2: Check Browser Console**

1. Press F12 to open DevTools
2. Go to Console tab
3. Look for errors containing:
   - "index"
   - "query"
   - "Firestore"
4. If you see index error, click the link to create index

### **Step 3: Check Flutter Console**

1. Look for debug prints from OfflinePetitionProvider
2. Check if `fetchSentPetitions` or `fetchAssignedPetitions` is being called
3. Check if petitions count is > 0
4. If count is 0, there's a query issue

### **Step 4: Manual Firestore Query Test**

In Firestore Console:

1. Go to `petitions` collection
2. Click "Filter" button
3. Add filters:
   - `submissionType` == `offline`
   - `assignedBy` == `your_officer_uid`
4. If no results, petition doesn't have correct fields
5. If results show, index might be missing

### **Step 5: Check Officer UID**

Your submitted petition:
```javascript
{
  "assignedBy": "ABC123"  // ← This value
}
```

Your current login:
```javascript
{
  "uid": "XYZ789"  // ← This must match above!
}
```

If they don't match, you're querying with wrong UID.

---

## 🔧 Quick Fixes

### **Fix 1: Force Refresh**

```dart
// In offline_petitions_screen.dart, add this button temporarily

FloatingActionButton(
  onPressed: () async {
    final provider = context.read<OfflinePetitionProvider>();
    final authProvider = context.read<PoliceAuthProvider>();
    final uid = authProvider.policeProfile?['uid'];
    
    if (uid != null) {
      await provider.fetchSentPetitions(uid);
      await provider.fetchAssignedPetitions(uid);
      
      print('Sent: ${provider.sentPetitions.length}');
      print('Assigned: ${provider.assignedPetitions.length}');
    }
  },
  child: Icon(Icons.refresh),
)
```

### **Fix 2: Check Actual Firestore Data**

Add this debug method to OfflinePetitionProvider:

```dart
Future<void> debugCheckPetitions(String officerId) async {
  final allOffline = await _firestore
      .collection('petitions')
      .where('submissionType', isEqualTo: 'offline')
      .get();
  
  debugPrint('📊 Total offline petitions: ${allOffline.docs.length}');
  
  for (var doc in allOffline.docs) {
    final data = doc.data();
    debugPrint('Petition: ${doc.id}');
    debugPrint('  assignedBy: ${data['assignedBy']}');
    debugPrint('  assignedTo: ${data['assignedTo']}');
    debugPrint('  submissionType: ${data['submissionType']}');
  }
}
```

Call this method to see ALL offline petitions in Firestore.

---

## ✅ Checklist

Before submitting petition, ensure:
- [ ] Using OfflinePetitionProvider (not regular PetitionProvider)
- [ ] "Assign to officer immediately" is checked
- [ ] Assignment target is selected
- [ ] Officer is logged in correctly
- [ ] Firestore indexes are created

After submitting:
- [ ] Check Firestore for the petition document
- [ ] Verify `submissionType: 'offline'`
- [ ] Verify `assignedBy` matches your UID
- [ ] Check browser console for errors
- [ ] Refresh the Sent tab

---

## 🚨 Most Common Cause

**90% of the time, the issue is:**
```
MISSING FIRESTORE INDEXES
```

**Solution:**
1. Open browser console (F12)
2. Find the red error about indexes
3. Click the blue link in the error
4. Wait 2-3 minutes
5. Refresh page
6. Petitions will appear!

---

## 📞 Still Not Working?

If petitions still don't show after:
1. ✅ Creating indexes
2. ✅ Verifying Firestore data
3. ✅ Checking officer UID

Then share:
1. Screenshot of Firestore petition document
2. Screenshot of browser console errors
3. Screenshot of Flutter console debug output

This will help identify the exact issue!
