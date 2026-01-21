# Timeline Not Showing - Debug Guide

## Debug Steps

### Step 1: Check Console Logs
After hot reload, **open the petition details** and check the console for these logs:

```
🔍 Building timeline for petition: [petitionId]
📊 Timeline snapshot state: [state]
📊 Has data: [true/false]
📊 Has error: [true/false]
```

### Step 2: Identify the Issue

#### **Case A: If you see an ERROR in console**
```
❌ Timeline error: [cloud_firestore/failed-precondition] The query requires an index
```

**Solution**: Create the missing index
- Click the link Firebase provides in the error
- OR create manually:
  - Collection: `petition_updates`
  - Fields: `petitionId` (ASC) + `createdAt` (DESC)

---

#### **Case B: If you see "No updates yet"**
```
📭 No updates found for petition: [petitionId]
```

**This means**:
- Timeline is working correctly
- But no updates exist yet for this petition

**Solution**: Add an update!
1. Click "Update Status" → Select any status
2. **OR** Click "Add Update" → Add remarks
3. Timeline should now show the update

---

#### **Case C: If timeline section is missing entirely**

**Check**:
1. Is the petition details modal scrollable?
2. Scroll all the way down - timeline is at the bottom
3. Look for "Updates Timeline" header

---

#### **Case D: Red error box appears**

The error message will show in the UI itself. Common errors:

1. **Index required** → Create index (see Case A)
2. **Permission denied** → Check Firestore rules allow reading `petition_updates`
3. **Field mismatch** → Check petition ID is correct

---

## Quick Test

### **Test the Timeline:**

1. **Hot reload** your app
2. **Login as station officer**
3. **Open assigned petition** → Scroll to bottom
4. **You should see**: "Updates Timeline" section
5. **Initial state**: "No updates yet. Add an update or change status to see the timeline."
6. **Click "Update Status"** → Select "In Progress"
7. **Check console** for:
   ```
   🔍 Building timeline for petition: [id]
   📊 Timeline snapshot state: active
   📊 Has data: true
   📊 Has error: false
   ✅ Loaded 1 timeline updates
   ```
8. **Timeline should now show**: "📋 Status changed to: In Progress"

---

## Expected Console Output (Success)

```
🔍 Building timeline for petition: OfflinePetition_John_2024-01-21
📊 Timeline snapshot state: ConnectionState.active
📊 Has data: true
📊 Has error: false
✅ Loaded 1 timeline updates
```

---

## Expected Console Output (No Updates)

```
🔍 Building timeline for petition: OfflinePetition_John_2024-01-21
📊 Timeline snapshot state: ConnectionState.active
📊 Has data: true
📊 Has error: false
📭 No updates found for petition: OfflinePetition_John_2024-01-21
```

---

## Possible Issues & Solutions

### Issue 1: Index Required
**Error**: `The query requires an index`  
**Solution**: Create index for `petition_updates` collection

### Issue 2: Timeline at Bottom of Modal
**Symptom**: Can't see timeline  
**Solution**: Scroll down! It's below petition details

### Issue 3: No Updates Created
**Symptom**: Shows "No updates yet"  
**Solution**: This is correct! Add an update to populate timeline

### Issue 4: Wrong Petition ID
**Symptom**: Always shows "No updates yet" even after adding updates  
**Solution**: Check petition ID matches between petition and updates

---

## Next Step

**Please hot reload and check your console logs**, then tell me which case (A, B, C, or D) matches what you see!
