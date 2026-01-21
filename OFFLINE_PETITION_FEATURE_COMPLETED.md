# Offline Petition Assignment Feature - Completed Implementation

## ✅ Feature Overview

Successfully implemented a comprehensive offline petition assignment system with the following capabilities:

### For High-Level Officers (DGP, ADGP, IGP, DIG, SP):
- ✅ **"Sent" Tab**: View all petitions they have assigned to other officers or units
- ✅ **"Assigned" Tab**: View all petitions assigned to them by higher authorities
- ✅ Horizontal swipeable tabs for easy navigation between Sent and Assigned petitions

### For Low-Level Officers (ASP, DSP, CI, SI, ASI, HC, PC):
- ✅ **"Assigned" Tab Only**: View petitions assigned to them
- ✅ Streamlined interface showing only relevant assignments

## 📋 Implementation Details

### 1. Rank Classification Utility (`lib/utils/rank_utils.dart`)
Created a utility class to classify police officers into high-level and low-level categories:

**High-Level Ranks (DGP to SP):**
- DGP (Director General of Police)
- ADGP (Additional Director General of Police)
- IGP (Inspector General of Police) 
- DIG (Deputy Inspector General of Police)
- SP (Superintendent of Police)

**Low-Level Ranks (Below SP):**
- ASP (Additional Superintendent of Police)
- DSP (Deputy Superintendent of Police)
- CI (Circle Inspector)
- SI (Sub-Inspector)
- ASI (Assistant Sub-Inspector)
- HC (Head Constable)
- PC (Police Constable)

### 2. Provider Enhancement (`lib/providers/petition_provider.dart`)
Added new methods to the PetitionProvider:

```dart
// Fetch petitions sent by an officer (for "Sent" tab)
Future<void> fetchSentPetitions(String officerId)

// Fetch petitions assigned to an officer (for "Assigned" tab)
Future<void> fetchAssignedPetitions(String officerId)

// Fetch petitions assigned to organizational units
Future<void> fetchAssignedPetitionsByUnit({
  String? stationName,
  String? districtName,
  String? rangeName,
})

// Get count metrics
Future<int> getSentPetitionsCount(String officerId)
Future<int> getAssignedPetitionsCount(String officerId)
```

### 3. Main Screen (`lib/screens/petition/offline_petitions_screen.dart`)
Created a comprehensive screen with:

**Features:**
- Dynamic tab bar based on officer rank
- Pull-to-refresh functionality
- Pet ition card UI showing:
  - Case title and ID
  - Assignment status (Pending, Accepted, Rejected)
  - Petitioner information
  - Assignment details (assigned to/from)
  - Assignment date and notes
- Detailed petition modal with:
  - Full petition details
  - Assignment information
  - Accept/Reject actions for pending assignments
  - Complete petition grounds and prayer/relief

**UI/UX Highlights:**
- Color-coded status indicators (Orange for pending, Green for accepted, Red for rejected)
- Swipeable horizontal tab navigation for high-level officers
- Empty state messages for no petitions
- Real-time updates with StreamBuilder integration
- Responsive card layouts

### 4. Dashboard Integration (`lib/screens/dashboard_body.dart`)
Updated the police dashboard quick actions:

**For High-Level Officers:**
- Position 0: "Submit Offline Petition" button
- Position 1: "Offline Petitions" button (purple color)

**For Low-Level Officers:**
- Position 0: "Assigned Petitions" button (purple color)

### 5. Router Configuration (`lib/router/app_router.dart`)
Added route definitions:

```dart
// Added to imports
import 'package:Dharma/screens/petition/offline_petitions_screen.dart';

// Added to protected routes list
'/offline-petitions',

// Added to police-only routes
'/offline-petitions',

// Route definition
GoRoute(
  path: '/offline-petitions',
  builder: (context, state) => const OfflinePetitionsScreen(),
),
```

## 🎨 User Experience Flow

### Workflow for High-Level Officers:

1. **Dashboard** → Click "Offline Petitions"
2. **Offline Petitions Screen** opens with 2 tabs:
   - **Sent Tab** (default):
     - Shows petitions assigned by this officer
     - Displays "assigned to" information
     - Track delegation status
   - **Assigned Tab**:
     - Shows petitions assigned to this officer
     - Displays "assigned by" information
     - Can accept/reject pending assignments

3. **Petition Card Click** → Opens detailed modal:
   - View full petition details
   - See assignment information
   - Accept or reject pending assignments
   - View assignment notes

### Workflow for Low-Level Officers:

1. **Dashboard** → Click "Assigned Petitions"
2. **Offline Petitions Screen** opens with 1 tab:
   - **Assigned Tab Only**:
     - Shows all petitions assigned to this officer
     - Displays who assigned each petition
     - Can accept/reject pending assignments

3. **Same detailed modal** as high-level officers

## 📊 Data Model

The `Petition` model already includes all necessary fields:

```dart
// Assignment tracking fields
String? assignmentType;       // 'range', 'district', 'station', 'officer'
String? assignedTo;           // Officer UID
String? assignedToName;       // Officer name
String? assignedToRank;       // Officer rank
String? assignedToRange;      // Range name
String? assignedToDistrict;   // District name
String? assignedToStation;    // Station name
String? assignedBy;           // Assigning officer UID
String? assignedByName;       // Assigning officer name
Timestamp? assignedAt;        // Assignment timestamp
String? assignmentStatus;     // 'pending', 'accepted', 'rejected'
String? assignmentNotes;      // Optional notes
String? submissionType;       // 'online' or 'offline'
```

## 🔄 State Management

The feature uses Provider pattern for state management:
- `PetitionProvider` handles data fetching and caching
- `PoliceAuthProvider` provides officer authentication and profile
- Real-time updates through Firestore streams
- Automatic refresh on tab switches

## 🎯 Key Benefits

1. **Role-Based Access Control**: Different features for different ranks
2. **Efficient Delegation**: High-level officers can track sent assignments
3. **Clear Accountability**: All assignments tracked with timestamps and status
4. **Easy Navigation**: Swipeable tabs for quick access
5. **Status Management**: Accept/reject workflow for assignments
6. **Complete Audit Trail**: All assignment details preserved

## 🔒 Security Features

- Route protection through `app_router.dart`
- Police-only access enforcement
- Authentication required for all petition operations
- Role-based UI rendering
- Firestore security rules should restrict access accordingly

## 🚀 Future Enhancements (Optional)

1. **Filters**: Add filtering by status, date range, assigned officer
2. **Search**: Search petitions by case ID, petitioner name
3. **Bulk Actions**: Accept/reject multiple petitions at once
4. **Notifications**: Push notifications for new assignments
5. **Analytics**: Dashboard showing assignment metrics
6. **Re-assignment**: Ability to reassign petitions
7. **Assignment History**: View complete assignment timeline

## 📱 Testing Checklist

- [ ] High-level officer can see both "Sent" and "Assigned" tabs
- [ ] Low-level officer sees only "Assigned" tab
- [ ] Tab switching loads correct data
- [ ] Petition cards display all required information
- [ ] Detailed modal shows complete petition details
- [ ] Accept/reject actions work correctly
- [ ] Empty states display properly
- [ ] Pull-to-refresh works
- [ ] Colors and UI match design guidelines
- [ ] Navigation from dashboard works
- [ ] Back button behavior is correct

## 🎉 Conclusion

The offline petition assignment feature is now fully implemented and integrated into the Dharma CMS application. Officers can efficiently manage petition assignments based on their rank, with high-level officers having full visibility into both sent and received petitions, while low-level officers focus on their assigned tasks.

All code follows Flutter best practices, maintains consistency with the existing codebase, and provides a premium user experience with modern UI/UX design patterns.
