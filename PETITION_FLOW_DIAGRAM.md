# Petition Flow Diagram

## Before (Old Flow)
```
Dashboard
    ↓
Stat Card Click (e.g., "Total Petitions")
    ↓
Modal Dialog Opens (PetitionListModal)
    ├── Shows list of petitions
    └── Click petition → Close modal (no detail view)
```

## After (New Flow)

### Citizen Flow
```
Citizen Dashboard
    ↓
Stat Card Click (e.g., "Received", "In Progress", "Closed")
    ↓
Navigate to CitizenPetitionListScreen (Full Page)
    ├── Shows filtered list of user's petitions
    ├── Pull to refresh
    └── Click any petition card
            ↓
        Bottom Sheet Slides Up
            ├── Petition Title & Status Badge
            ├── Petitioner Details (name, phone, address, FIR)
            ├── Grounds (complaint details)
            ├── Prayer/Relief Sought
            ├── Important Dates (filing, hearing, order)
            ├── Extracted Text from Documents
            └── Close Button (X)
```

### Police Flow
```
Police Dashboard
    ↓
Stat Card Click (e.g., "Total Petitions", "Received", "In Progress", "Closed")
    ↓
Navigate to PolicePetitionListScreen (Full Page)
    ├── Shows filtered list of station's petitions
    ├── Pull to refresh
    └── Click any petition card
            ↓
        Bottom Sheet Slides Up
            ├── Petition Title & Case ID
            ├── Full Petition Details Section
            ├── Grounds & Prayer/Relief (in cards)
            ├── Important Dates Section
            ├── Current Police Status Display
            │
            ├── ─── ACTION SECTION ───
            │
            ├── Status Update Dropdown
            │       ├── Received
            │       ├── In Progress
            │       └── Closed
            │           └── If Closed → Sub-Status Dropdown
            │               ├── Rejected
            │               ├── FIR Registered
            │               └── Compromised/Disposed
            │
            ├── [AI Investigation Guidelines] Button
            │       └── Navigate to /ai-investigation-guidelines
            │           (with petition caseId for context)
            │
            ├── [Register FIR] Button
            │       └── Navigate to /cases/new
            │           (with petition data pre-filled)
            │
            └── [Submit Update] Button
                    └── Save status changes to Firestore
                        └── Close bottom sheet & refresh list
```

## Screen Locations

### Files Created
1. `frontend/lib/screens/petition/petition_list_screen.dart`
   - CitizenPetitionListScreen class
   - Shows citizen's petitions filtered by status
   - Includes detail bottom sheet

2. `frontend/lib/screens/petition/police_petition_list_screen.dart`
   - PolicePetitionListScreen class
   - Shows station's petitions filtered by status
   - Includes detail bottom sheet with actions

### Files Modified
1. `frontend/lib/screens/dashboard_body.dart`
   - Updated imports (removed PetitionListModal, added new screens)
   - Updated _statCard() method to use Navigator.push instead of showDialog

## Key Features

### Citizen Features
✓ View all petitions by status
✓ See petition details in bottom sheet
✓ Pull to refresh
✓ Clean, card-based UI
✓ Status badges
✓ Extracted document text display

### Police Features
✓ View all station petitions by status
✓ See full petition details
✓ Update police status (Received/In Progress/Closed)
✓ Set closure sub-status
✓ Register FIR with pre-filled data
✓ Access AI Investigation Guidelines with context
✓ Pull to refresh
✓ Police status color-coded badges
✓ Case ID display

## Color Coding

### Status Colors (Citizen)
- Draft: Grey
- Filed: Blue
- Under Review: Orange
- Hearing Scheduled: Purple
- Granted: Green
- Rejected: Red
- Withdrawn: Brown

### Police Status Colors
- Pending: Orange
- Received: Blue
- In Progress: Indigo
- Closed: Green
- Rejected: Red

### Filter Colors (Both)
- All Petitions: Deep Purple
- Received: Blue (shade 700)
- In Progress: Orange (shade 700)
- Closed: Green (shade 700)
