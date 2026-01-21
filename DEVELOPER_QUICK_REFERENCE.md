# Quick Reference: Offline Petition Assignment Feature

## 🎯 Quick Start for Developers

### Files Created/Modified

#### New Files:
1. `frontend/lib/utils/rank_utils.dart` - Rank classification utility
2. `frontend/lib/screens/petition/offline_petitions_screen.dart` - Main screen
3. `OFFLINE_PETITION_ASSIGNMENT_FEATURE.md` - Initial planning doc
4. `OFFLINE_PETITION_FEATURE_COMPLETED.md` - Complete documentation

#### Modified Files:
1. `frontend/lib/providers/petition_provider.dart` - Added petition fetching methods
2. `frontend/lib/screens/dashboard_body.dart` - Added dashboard button
3. `frontend/lib/router/app_router.dart` - Added route configuration

### Navigation Paths

```
High-Level Officers (DGP-SP):
Police Dashboard → "Offline Petitions" → [Sent Tab | Assigned Tab]

Low-Level Officers (below SP):
Police Dashboard → "Assigned Petitions" → [Assigned Tab only]
```

### API Methods

```dart
// In PetitionProvider

// Fetch sent petitions
await petitionProvider.fetchSentPetitions(officerId);

// Fetch assigned petitions  
await petitionProvider.fetchAssignedPetitions(officerId);

// Fetch by organizational unit
await petitionProvider.fetchAssignedPetitionsByUnit(
  stationName: 'Station Name',
  // OR districtName: 'District Name',
  // OR rangeName: 'Range Name',
);

// Get counts
int sentCount = await petitionProvider.getSentPetitionsCount(officerId);
int assignedCount = await petitionProvider.getAssignedPetitionsCount(officerId);
```

### Rank Classification

```dart
import 'package:Dharma/utils/rank_utils.dart';

// Check if high-level officer
bool isHighLevel = RankUtils.isHighLevelOfficer(officerRank);

// Check if low-level officer
bool isLowLevel = RankUtils.isLowLevelOfficer(officerRank);

// Get category name
String category = RankUtils.getRankCategory(officerRank);
```

### Route Access

```dart
// Navigate to offline petitions
context.push('/offline-petitions');

// Or using GoRouter
context.go('/offline-petitions');
```

### Firestore Queries Used

```dart
// Sent petitions query
_firestore
  .collection('petitions')
  .where('assignedBy', isEqualTo: officerId)
  .where('submissionType', isEqualTo: 'offline')
  .orderBy('assignedAt', descending: true)
  .get()

// Assigned petitions query
_firestore
  .collection('petitions')
  .where('assignedTo', isEqualTo: officerId)
  .where('submissionType', isEqualTo: 'offline')
  .orderBy('assignedAt', descending: true)
  .get()
```

### Assignment Status Values

```dart
// Possible assignmentStatus values
'pending'   // Waiting for acceptance
'accepted'  // Officer accepted the assignment
'rejected'  // Officer rejected the assignment
```

### Color Scheme

```dart
// Status colors
Colors.orange     // Pending
Colors.green      // Accepted
Colors.red        // Rejected
Colors.blue       // In Progress

// UI colors
Colors.purple.shade600  // Offline Petitions button
Colors.teal.shade600    // Submit Offline Petition button
```

## 🐛 Common Issues & Solutions

### Issue: Tabs not showing correctly
**Solution**: Verify officer rank in Firebase and ensure it matches exactly with rank patterns in `rank_utils.dart`

### Issue: Petitions not loading
**Solution**: 
1. Check Firestore indexes for composite queries
2. Verify `assignedBy` and `assignedTo` fields are populated
3. Ensure `submissionType` is set to 'offline'

### Issue: Route not found
**Solution**: Run `flutter pub get` and restart the app to reload routes

### Issue: Accept/Reject not working
**Solution**: Check petition has `id` field and `userId` is properly set

## 📋 Firestore Indexes Required

Create composite indexes in Firestore:

```
Collection: petitions
Fields:
  - assignedBy (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)

Collection: petitions
Fields:
  - assignedTo (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)

Collection: petitions
Fields:
  - assignedToStation (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)

Collection: petitions
Fields:
  - assignedToDistrict (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)

Collection: petitions
Fields:
  - assignedToRange (Ascending)
  - submissionType (Ascending)
  - assignedAt (Descending)
```

## 🔧 Configuration

No additional configuration needed. The feature uses existing:
- Firebase Authentication
- Firestore Database
- Provider state management
- GoRouter navigation

## 📞 Support

For issues or questions:
1. Check the main documentation: `OFFLINE_PETITION_FEATURE_COMPLETED.md`
2. Review the implementation plan: `OFFLINE_PETITION_ASSIGNMENT_FEATURE.md`
3. Check conversation history for context

## ✅ Verification Steps

Run these checks after deployment:

1. **Rank Detection**:
   ```dart
   print(RankUtils.isHighLevelOfficer('DGP')); // Should be true
   print(RankUtils.isHighLevelOfficer('SI'));  // Should be false
   ```

2. **Route Access**:
   - Test navigation from dashboard
   - Verify authentication required
   - Check role-based access control

3. **Data Loading**:
   - Create test assignments
   - Verify they appear in correct tabs
   - Test pull-to-refresh

4. **Actions**:
   - Test accept/reject functionality
   - Verify status updates in Firestore
   - Check UI updates after actions

## 💡 Tips

- Use the `debugPrint` statements in provider methods for debugging
- Check Flutter DevTools for navigation stack
- Use Firestore console to verify data structure
- Test with different officer ranks to see UI variations
- Clear app data if seeing cached data issues
