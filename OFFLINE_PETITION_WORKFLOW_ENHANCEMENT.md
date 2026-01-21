# Offline Petition Workflow Enhancement

## Overview
Enhanced offline petition workflow with timeline view and status updates.

## Workflow

### **Sent Section** (High-level officers like SP, DSP)
✅ View petitions assigned to lower-level officers  
✅ See current status of each petition  
✅ View timeline of all updates made by assigned officers  
✅ View remarks added by assigned officers  
❌ **NO accept/reject buttons** - just monitoring  

### **Assigned Section** (Station officers)
✅ View petitions assigned to their station  
✅ Update petition status (Received → In Progress → Closed)  
✅ Add timeline updates with remarks  
✅ All updates are visible to the assigning officer  

## Implementation Plan

### 1. **Remove Accept/Reject Buttons**
- Remove lines 380-414 from `_showPetitionDetails`
- These are no longer needed in the workflow

### 2. **Add Petition Updates Integration**
- Integrate with existing `petition_updates` collection
- Show timeline in petition details modal
- Reuse `PetitionTimelineWidget` if it exists, or create new

### 3. **Add Status Update Dialog** (Assigned Tab Only)
- Show button to update status in assigned tab
- Options: Received, In Progress, Closed
- Add optional remarks field

### 4. **Add Update/Remarks Dialog** (Assigned Tab Only)
- Button to add new update with:
  - Update text/remarks
  - Optional photos
  - Timestamp
- Saves to `petition_updates` collection

### 5. **Timeline View in Details Modal**
- Show all updates chronologically
- Display:
  - Status changes
  - Updates/remarks
  - Photos (if any)
  - Officer name & timestamp

## Files to Modify
1. `offline_petitions_screen.dart` - Main UI updates
2. `offline_petition_provider.dart` - Add update methods if needed
3. Reuse `petition_updates` collection (already exists)

## Next Steps
Ready to implement? Shall I proceed with the code changes?
