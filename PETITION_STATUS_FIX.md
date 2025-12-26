# Petition UI Update - Status Display Fix

## Issue Resolved
Fixed the citizen petition list screen to properly display:
1. **Police status instead of draft status** on petition cards
2. **Status tracking timeline** in the detail bottom sheet

## Solution

### Updated `petition_list_screen.dart`
The citizen petition list screen now **reuses existing components** instead of duplicating code:

#### Components Reused:
1. **`PetitionCard`** - Card display component
   - Automatically prioritizes `policeStatus` over petition status
   - Shows police status badge if available, otherwise falls back to petition status
   - Displays: title, status badge, petitioner name, phone, dates

2. **`PetitionDetailBottomSheet`** - Detail view component
   - Includes **status tracking timeline** with visual progress indicators
   - Shows police status if available, otherwise petition status
   - Displays comprehensive petition information:
     - Petition title and status badge
     - **4-step timeline**: Submitted → Received → In Progress → Closed
     - Petitioner details
     - Incident details (address, date)
     - Jurisdiction details (district, police station)
     - Grounds and prayer/relief
     - Important dates
     - Extracted text from documents

### How Status Display Works

#### On the Card (`PetitionCard`):
```dart
// Priority logic
final String displayStatus = (petition.policeStatus != null && petition.policeStatus!.isNotEmpty)
    ? petition.policeStatus!         // Show police status if available
    : petition.status.displayName;   // Otherwise show petition status
```

#### Colors for Police Status:
- **Pending**: Orange
- **Received**: Blue
- **In Progress**: Indigo
- **Closed**: Green
- **Rejected**: Red

#### Colors for Petition Status (fallback):
- **Draft**: Grey
- **Filed**: Blue
- **Under Review**: Orange
- **Hearing Scheduled**: Purple
- **Granted**: Green
- **Rejected**: Red
- **Withdrawn**: Brown

### Status Tracking Timeline

The bottom sheet shows a 4-step progress timeline:

```
○━━━○━━━○━━━○
  Submitted → Received → In Progress → Closed
```

- **Green dots with checkmark**: Completed steps
- **Grey dots**: Pending steps
- **Current position** determined by police status (if available) or petition status

#### Timeline Mapping:

**Police Status**:
- `Pending`/`Submitted` → Step 0 (Submitted)
- `Received`/`Acknowledged` → Step 1 (Received)
- `In Progress`/`Investigation` → Step 2 (In Progress)
- `Closed`/`Resolved`/`Rejected` → Step 3 (Closed)

**Petition Status** (fallback):
- `Draft`/`Filed` → Step 0 (Submitted)
- `Under Review` → Step 1 (Received)
- `Hearing Scheduled` → Step 2 (In Progress)
- `Granted`/`Rejected`/`Withdrawn` → Step 3 (Closed)

## Benefits of Code Reuse

✅ **Consistent UI** - Same design across all petition views
✅ **Single Source of Truth** - Status logic in one place
✅ **Easier Maintenance** - Fix once, works everywhere
✅ **Reduces Bugs** - Less duplicate code = fewer bugs
✅ **Smaller File Size** - Reduced from 522 lines to 133 lines

## File Changes

### Modified:
- `frontend/lib/screens/petition/petition_list_screen.dart`
  - Removed duplicate status display logic
  - Removed duplicate detail view code
  - Now imports and uses `PetitionCard` and `PetitionDetailBottomSheet`

### Unchanged (Reused):
- `frontend/lib/screens/petition/petition_card.dart`
  - Already handles police status prioritization
  - Already has proper color coding

- `frontend/lib/screens/petition/petition_detail_bottom_sheet.dart`
  - Already has status tracking timeline
  - Already handles police status prioritization
  - Already shows all petition details

## Testing Checklist

- [x] Citizen dashboard stat card click → navigates to list
- [x] Petition cards show police status (not draft)
- [x] Clicking petition opens bottom sheet
- [x] Bottom sheet shows status timeline
- [x] Timeline reflects current police status
- [x] All petition details displayed correctly
- [x] Pull to refresh works
- [x] Status badges use correct colors

## Example Flow

1. **User clicks "In Progress" on dashboard**
   - Navigates to `CitizenPetitionListScreen` with filter
   
2. **List shows petitions filtered by police status = "In Progress"**
   - Cards display with **blue "In Progress" badge** (not grey "Draft")
   
3. **User taps a petition card**
   - Bottom sheet opens with `PetitionDetailBottomSheet`
   
4. **Bottom sheet displays:**
   - Title: "Theft Complaint"
   - Status badge: Blue "In Progress"
   - **Timeline**: ✓ Submitted → ✓ Received → ● In Progress → ○ Closed
   - Petitioner details
   - Incident location and date
   - Police station assigned
   - Full complaint grounds
   - All other petition information

## Code Quality Improvements

### Before:
- Duplicate status display logic in 3 places
- 500+ lines of repetitive code
- Inconsistent status handling

### After:
- Status logic in `PetitionCard` only
- Detail logic in `PetitionDetailBottomSheet` only
- `petition_list_screen.dart` is now clean and simple
- All screens use same components = guaranteed consistency

---

**Updated**: December 26, 2025
**Status**: ✅ Fixed and Tested
