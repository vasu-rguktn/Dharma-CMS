# Petition Stats Click-to-View Feature

## Summary
I've successfully implemented the feature to make petition stat counts clickable on both the **Citizen Dashboard** and **Police Dashboard**. When clicked, a modal dialog opens showing all petitions filtered by that specific status.

## Changes Made

### 1. Created New Widget: `petition_list_modal.dart`
**Location:** `frontend/lib/widgets/petition_list_modal.dart`

This modal widget:
- Displays filtered petitions based on the selected status (Total, Received, In Progress, Closed)
- Fetches petitions from the backend using the existing `fetchFilteredPetitions` method
- Shows petition details including:
  - Case ID
  - Title
  - Type
  - Date
  - Police Status
  - Petitioner name (for police view)
  - Station name
- Has a color-coded header matching the status type
- Shows "No Petitions Found" message when there are no petitions for that status
- Automatically handles citizen vs police filtering

### 2. Enhanced `petition_provider.dart`
**Location:** `frontend/lib/providers/petition_provider.dart`

- Moved `fetchFilteredPetitions` method inside the `PetitionProvider` class (it was outside before)
- Added import for `PetitionFilter` enum
- The method now properly filters petitions by:
  - **Citizen**: User ID
  - **Police**: Station name
  - **Status**: Total, Received, In Progress, or Closed

### 3. Updated `dashboard_body.dart`
**Location:** `frontend/lib/screens/dashboard_body.dart`

- Made all stat cards clickable with `InkWell` wrapper
- Added `onTap` handler that shows the `PetitionListModal`
- Updated `_statCard` method to accept a `PetitionFilter` parameter
- Added necessary imports for `PetitionFilter` and `PetitionListModal`

## How It Works

### For Citizens:
1. Citizen sees their dashboard with petition stats (Total, Received, In Progress, Closed)
2. When they click on any stat card, a modal opens
3. The modal fetches and displays only their petitions filtered by that status
4. Clicking on a petition closes the modal (can be extended to navigate to petition details)

### For Police:
1. Police officer sees their dashboard with station-specific petition stats
2. When they click on any stat card, a modal opens
3. The modal fetches and displays only petitions for their station, filtered by that status
4. The modal shows additional information like petitioner name for police view

## Status Filtering Logic

- **Total**: All petitions
- **Received**: Petitions with status containing 'pending', 'received', or 'acknowledge'
- **In Progress**: Petitions with status containing 'progress' or 'investigation'
- **Closed**: Petitions with status containing 'closed', 'resolved', or 'rejected'

## UI/UX Features

- Color-coded headers matching the stat card colors:
  - Total: Deep Purple
  - Received: Blue
  - In Progress: Orange
  - Closed: Green
- Clean card-based layout for each petition
- Scrollable list for many petitions
- Empty state with icon and message when no petitions found
- Responsive design that works on different screen sizes

## Testing Recommendations

1. **Test as Citizen:**
   - Login as a citizen
   - Click on each stat card (Total, Received, In Progress, Closed)
   - Verify that only your petitions are shown
   - Verify correct filtering by status

2. **Test as Police:**
   - Login as a police officer
   - Click on each stat card
   - Verify that only petitions for your station are shown
   - Verify correct filtering by status
   - Verify that petitioner names are visible

3. **Edge Cases:**
   - Test with 0 petitions (should show "No Petitions Found")
   - Test with many petitions (should scroll)
   - Test with different statuses

## Future Enhancements (Optional)

1. **Navigation to Petition Details:**
   - Uncomment the line in `petition_list_modal.dart` line 181
   - Add proper routing for petition details page

2. **Localization:**
   - Add Telugu translation for "No Petitions Found"
   - Currently using hardcoded English text

3. **Pull-to-Refresh:**
   - Add pull-to-refresh functionality to reload petitions

4. **Search & Additional Filters:**
   - Add search functionality within the modal
   - Add date range filters
   - Add type filters

## Files Modified

1. `frontend/lib/widgets/petition_list_modal.dart` (NEW)
2. `frontend/lib/providers/petition_provider.dart`
3. `frontend/lib/screens/dashboard_body.dart`

## No Breaking Changes

- All existing functionality remains intact
- The feature is purely additive
- No changes to backend required
- Uses existing petition fetching infrastructure
