# AI Investigation Guidelines Auto-Load Fix

## Issue Resolved
When police officers clicked "AI Investigation Guidelines" from the petition detail bottom sheet, the screen would open but wouldn't automatically load the petition details - officers had to manually enter the case ID.

## Root Cause
The router was only checking for `caseId` in query parameters but the navigation from the police petition detail was passing it via the `extra` parameter.

## Solution

### Updated Router Configuration
File: `frontend/lib/router/app_router.dart`

**Before:**
```dart
GoRoute(
  path: '/ai-investigation-guidelines',
  builder: (context, state) {
    final caseId = state.uri.queryParameters['caseId'];
    return AiInvestigationGuidelinesScreen(caseId: caseId);
  },
),
```

**After:**
```dart
GoRoute(
  path: '/ai-investigation-guidelines',
  builder: (context, state) {
    // Try to get caseId from query parameters first
    String? caseId = state.uri.queryParameters['caseId'];
    
    // If not in query params, try to get from extra data
    if (caseId == null && state.extra != null) {
      final extraData = state.extra as Map<String, dynamic>?;
      caseId = extraData?['caseId'] as String?;
    }
    
    return AiInvestigationGuidelinesScreen(caseId: caseId);
  },
),
```

### How It Works

The router now supports **two ways** of passing the case ID:

#### Method 1: Query Parameters
```dart
context.go('/ai-investigation-guidelines?caseId=ABC123');
```

#### Method 2: Extra Data (Used by Police Petition Screen)
```dart
context.go('/ai-investigation-guidelines', extra: {'caseId': 'ABC123'});
```

The router checks both locations and uses whichever is available.

## User Flow (Fixed)

### Police Petition Detail → AI Investigation Guidelines

1. **Police officer views petition list** (filtered by status)
2. **Taps a petition card** → Bottom sheet opens with petition details
3. **Clicks "AI Investigation Guidelines" button**
4. Navigation occurs:
   ```dart
   context.go('/ai-investigation-guidelines', extra: {'caseId': petition.caseId});
   ```
5. **Router extracts caseId** from extra data
6. **AI Investigation screen loads** with `caseId` parameter
7. **Auto-fetches petition details** in `initState()`:
   ```dart
   if (widget.caseId != null && widget.caseId!.isNotEmpty) {
     _caseIdController.text = widget.caseId!;
     WidgetsBinding.instance.addPostFrameCallback((_) {
       _fetchPetitionDetails();
     });
   }
   ```
8. **Petition details displayed** automatically - no manual input needed!
9. **Officer clicks "Generate Investigation Guidelines"**
10. **AI report generated** with petition context

## What Gets Auto-Loaded

When the case ID is provided, the AI Investigation Guidelines screen automatically:

✅ **Pre-fills the Case ID field** with the petition's case ID
✅ **Fetches petition details** from Firestore
✅ **Displays petition information**:
   - Title
   - Type
   - Petitioner name
   - District
   - Police station
✅ **Ready to generate AI investigation** with full context

### AI Investigation Request Payload

When officer clicks "Generate Investigation Guidelines", the system sends:

```json
{
  "fir_id": "CASE_ID_123",
  "fir_details": "
    Case ID: CASE_ID_123
    Petition Title: Theft Complaint
    Petition Type: Other
    
    Petitioner Name: John Doe
    Phone Number: 9876543210
    
    District: West Godavari
    Police Station: Eluru Town
    
    Incident Address:
    123 Main Street, Eluru
    
    Incident Date:
    2025-12-20
    
    Complaint / Grounds:
    My bike was stolen from the parking lot...
  "
}
```

The AI then generates comprehensive investigation guidelines based on this complete context.

## Benefits

✅ **No manual input** - Case ID automatically populated
✅ **Faster workflow** - Officer saves time
✅ **Better context** - AI has full petition details
✅ **Fewer errors** - No typos in manual case ID entry
✅ **Seamless experience** - One-click from petition to AI guidelines

## Testing

### Test Steps:
1. ✅ Login as police officer
2. ✅ Navigate to police dashboard
3. ✅ Click any petition status card (Total/Received/In Progress/Closed)
4. ✅ List of petitions opens
5. ✅ Tap any petition → Bottom sheet opens
6. ✅ Click "AI Investigation Guidelines" button
7. ✅ Verify AI Investigation screen opens
8. ✅ **Verify Case ID is pre-filled**
9. ✅ **Verify petition details are displayed** (no manual fetch needed)
10. ✅ Click "Generate Investigation Guidelines"
11. ✅ Verify AI report generates successfully

### Edge Cases Tested:
- ✅ Petition with case ID → Auto-loads
- ✅ Petition without case ID → Shows warning
- ✅ Invalid case ID → Shows "No petition found" message
- ✅ Network error → Shows error message

## Code Locations

### Modified:
- `frontend/lib/router/app_router.dart` - Router configuration (lines 264-277)

### Unchanged (Already Working):
- `frontend/lib/screens/Investigation_Guidelines/AI_Investigation_Guidelines.dart`
  - Already accepts `caseId` parameter
  - Already auto-fetches on init if caseId provided
  
- `frontend/lib/screens/petition/police_petition_list_screen.dart`
  - Already passes caseId via extra data
  - Already checks for case ID existence before navigation

## Related Files

### Navigation Source:
`police_petition_list_screen.dart` (lines 363-379):
```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.pop(context); // Close the modal first
    
    // Navigate to AI Investigation Guidelines
    if (petition.caseId != null && petition.caseId!.isNotEmpty) {
      context.go(
        '/ai-investigation-guidelines',
        extra: {'caseId': petition.caseId},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No case ID associated with this petition'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  },
  icon: const Icon(Icons.psychology, size: 20),
  label: const Text('AI Investigation Guidelines'),
),
```

### Destination Screen:
`AI_Investigation_Guidelines.dart` (lines 40-49):
```dart
@override
void initState() {
  super.initState();

  if (widget.caseId != null && widget.caseId!.isNotEmpty) {
    _caseIdController.text = widget.caseId!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPetitionDetails();
    });
  }
}
```

---

**Updated**: December 26, 2025  
**Status**: ✅ Fixed and Tested  
**Impact**: Improved police officer workflow efficiency
