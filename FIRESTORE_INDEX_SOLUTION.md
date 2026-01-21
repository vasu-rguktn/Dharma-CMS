# ✅ SOLUTION: Create Firestore Index

## 🎯 The Problem

Your console shows:
```
❌ Error fetching sent petitions: [cloud_firestore/failed-precondition] 
The query requires an index.
```

**This is the ONLY issue** preventing petitions from showing!

---

## 🔧 Quick Fix (Takes 2 minutes)

### Step 1: Click This Link

Copy and paste this URL into your browser:
```
https://console.firebase.google.com/v1/r/project/dharma-cms-5cc89/firestore/indexes?create_composite=ClJwcm9qZWN0cy9kaGFybWEtY21zLTVjYzg5L2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9wZXRpdGlvbnMvaW5kZXhlcy9fEAEaDgoKYXNzaWduZWRCeRABGhIKDnN1Ym1pc3Npb25UeXBlEAEaDgoKYXNzaWduZWRBdBACGgwKCF9fbmFtZV9fEAI
```

### Step 2: It Will Show This Screen

```
Create Index for petitions collection

Fields:
  - assignedBy (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)

[Create Index Button]
```

### Step 3: Click "Create Index"

### Step 4: Wait for Index to Build

You'll see a status like:
```
Index Status: Building...
Estimated time: 1-3 minutes
```

### Step 5: Once Complete

Status will change to:
```
Index Status: Enabled ✓
```

### Step 6: Refresh Your App

- Go back to your app
- Refresh the "Offline Petitions" page
- Petitions will now appear! 🎉

---

## 📊 What This Index Does

The index allows Firestore to efficiently query:
- **Collection**: `petitions`
- **Filters**: 
  - Where `assignedBy` = your officer UID
  - Where `submissionType` = 'offline'
- **Order**: By `assignedAt` (newest first)

Without this index, Firestore cannot perform this compound query.

---

## ⚠️ Important Notes

1. **You need to create this index ONCE**
   - After creation, it works for all officers
   - You won't need to do this again

2. **You'll likely need TWO indexes**:
   - Index 1: For "Sent" petitions (assignedBy query) ← This is the error you saw
   - Index 2: For "Assigned" petitions (assignedTo query) ← You'll get this error when switching tabs

3. **Second Index Link** (you'll need this too):
   - When you click "Assigned" tab, you'll get another error
   - Click that new link to create the second index
   - Wait for it to build
   - Both tabs will work!

---

## 🎯 Expected Result

After creating the index:

**Console will show**:
```
✅ Fetched X sent petitions
```

**"Sent" tab will display**:
- All petitions you've assigned to other officers
- Each petition card showing assignment details
- Sorted by most recent first

---

## 🐛 Bonus Fix Applied

I also fixed the `setState() during build` warning you saw. The app will run smoother now!

---

## ✅ Summary

**Single Action Required**: 
👉 Click the index creation link from your error
👉 Wait 2-3 minutes
👉 Refresh app
👉 Petitions will appear!

That's it! The petitions ARE being saved correctly to Firestore. The index just needs to be created for queries to work.
