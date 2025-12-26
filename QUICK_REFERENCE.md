# Quick Reference Guide - Petition UI Changes

## What Changed?

### Before
Clicking on petition stat cards (Total, Received, In Progress, Closed) on the dashboard opened a **modal dialog** with a list of petitions. There was no way to view full petition details.

### After
Clicking on petition stat cards now **navigates to a full-page screen** showing filtered petitions. Tapping any petition opens a **bottom sheet** with complete details and actions.

---

## New Files Created

### 1. `petition_list_screen.dart` (Citizen)
**Location**: `frontend/lib/screens/petition/petition_list_screen.dart`

**Class**: `CitizenPetitionListScreen`

**What it does**:
- Shows citizen's petitions filtered by status
- Displays petition cards with title, status, name, phone, dates
- Tap card → bottom sheet with full details
- Pull to refresh

### 2. `police_petition_list_screen.dart` (Police)
**Location**: `frontend/lib/screens/petition/police_petition_list_screen.dart`

**Class**: `PolicePetitionListScreen`

**What it does**:
- Shows station's petitions filtered by status
- Displays petition cards with title, case ID, police status, petitioner info
- Tap card → bottom sheet with:
  - Full petition details
  - Status update dropdown
  - FIR registration button
  - AI investigation guidelines button
  - Submit update button
- Pull to refresh

---

## Modified Files

### `dashboard_body.dart`
**Location**: `frontend/lib/screens/dashboard_body.dart`

**Changes**:
1. **Imports** (lines 9-10):
   ```dart
   import 'package:Dharma/screens/petition/petition_list_screen.dart';
   import 'package:Dharma/screens/petition/police_petition_list_screen.dart';
   ```

2. **_statCard() method** (lines 166-224):
   - Replaced `showDialog()` with `Navigator.push()`
   - Uses `MaterialPageRoute` to navigate to petition list screens
   - Conditionally shows citizen or police screen based on `isPolice` flag

---

## How to Use

### For Citizens
1. Open app and navigate to citizen dashboard
2. See petition stats: Total, Received, In Progress, Closed
3. Tap any stat card
4. You'll see a full page with your filtered petitions
5. Tap any petition to see details in a bottom sheet
6. Swipe down to refresh the list

### For Police Officers
1. Open app and navigate to police dashboard
2. See petition stats for your station
3. Tap any stat card
4. You'll see a full page with filtered petitions
5. Tap any petition to see details and actions
6. In the bottom sheet:
   - Update police status
   - Register FIR (opens case registration)
   - View AI guidelines (opens AI investigation)
   - Submit changes
7. Swipe down to refresh the list

---

## Status Filters

### PetitionFilter enum values:
- `PetitionFilter.all` - All petitions
- `PetitionFilter.received` - Police status = "Received"
- `PetitionFilter.inProgress` - Police status = "In Progress"
- `PetitionFilter.closed` - Police status = "Closed"

---

## Colors

### Filter Colors
- All: Deep Purple
- Received: Blue (shade 700)
- In Progress: Orange (shade 700)
- Closed: Green (shade 700)

### Police Status Colors
- Pending: Orange
- Received: Blue
- In Progress: Indigo
- Closed: Green
- Rejected: Red

---

## Key Methods

### CitizenPetitionListScreen
- `_loadFilteredPetitions()` - Fetches petitions from provider
- `_showPetitionDetails(Petition)` - Shows bottom sheet with details
- `_getStatusColor(PetitionStatus)` - Returns color for status badge
- `_formatTimestamp(Timestamp)` - Formats date as DD/MM/YYYY

### PolicePetitionListScreen
- `_loadFilteredPetitions()` - Fetches petitions from provider
- `_showPetitionDetails(BuildContext, Petition)` - Shows bottom sheet with actions
- `_getPoliceStatusColor(String)` - Returns color for police status
- `_buildDetailRow(String, String)` - Creates label-value row

---

## Navigation Routes

When buttons are clicked in police bottom sheet:

**AI Investigation Guidelines**:
```dart
context.go('/ai-investigation-guidelines', extra: {'caseId': petition.caseId});
```

**Register FIR**:
```dart
context.go('/cases/new', extra: petitionData);
```
(petitionData includes title, petitioner name, phone, grounds, addresses, etc.)

---

## Data Flow

### Citizen
```
Dashboard → CitizenPetitionListScreen
    ↓
PetitionProvider.fetchFilteredPetitions(
  isPolice: false,
  userId: currentUser.uid,
  filter: selectedFilter
)
    ↓
Display petitions → Tap → Bottom sheet
```

### Police
```
Dashboard → PolicePetitionListScreen
    ↓
PetitionProvider.fetchFilteredPetitions(
  isPolice: true,
  stationName: officer.stationName,
  filter: selectedFilter
)
    ↓
Display petitions → Tap → Bottom sheet → Actions
    ↓
Update status → PetitionProvider.updatePetition()
    ↓
Navigate to FIR/AI screens
```

---

## Troubleshooting

### Issue: Petitions not showing
**Check**:
1. User is logged in (citizen) or police profile has stationName
2. PetitionProvider.fetchFilteredPetitions() is being called
3. Firestore has petitions matching the filter criteria

### Issue: Bottom sheet not opening
**Check**:
1. Petition has required fields (id, title, etc.)
2. showModalBottomSheet is not being blocked by other modals

### Issue: Status update not working (police)
**Check**:
1. Petition has a valid ID
2. PetitionProvider.updatePetition() has correct parameters
3. Firestore write permissions are correct

### Issue: Navigation not working
**Check**:
1. GoRouter routes are configured correctly
2. Extra data is being passed in correct format
3. Target screens handle the extra data properly

---

## Files Reference

### Related Files (Not Modified)
- `frontend/lib/models/petition.dart` - Petition model
- `frontend/lib/providers/petition_provider.dart` - Petition state management
- `frontend/lib/utils/petition_filter.dart` - Filter enum
- `frontend/lib/screens/police_petitions_screen.dart` - Main police petitions screen
- `frontend/lib/screens/petitions_screen.dart` - Main citizen petitions screen (in root)
- `frontend/lib/screens/petition/petitions_screen.dart` - Petition tabs wrapper

---

## Testing

### Quick Test Steps
1. ✅ Run the app
2. ✅ Login as citizen or police
3. ✅ Go to dashboard
4. ✅ Click any stat card
5. ✅ Verify full page opens (not a dialog)
6. ✅ Verify petitions are shown
7. ✅ Tap a petition
8. ✅ Verify bottom sheet opens
9. ✅ (Police only) Test status update
10. ✅ (Police only) Test FIR registration button
11. ✅ (Police only) Test AI guidelines button
12. ✅ Pull down to refresh

---

## Contact

If you encounter issues or need clarification:
1. Check the Firestore console for data
2. Check Flutter logs for errors
3. Verify provider state using debugPrint statements
4. Review the implementation notes (IMPLEMENTATION_NOTES.md)

---

**Version**: 1.0  
**Date**: December 26, 2025  
**Status**: ✅ Implemented and Ready for Testing
