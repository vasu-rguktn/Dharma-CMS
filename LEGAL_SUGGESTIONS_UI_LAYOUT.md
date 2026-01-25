# Legal Section Suggester Feature - UI Layout Specification

## Current Frontend UI Structure

### Screen Layout Overview

```
┌─────────────────────────────────────────────────────────────┐
│  ← Back    Legal Section Suggester                         │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐│
│  │ Describe the incident in detail...                     ││
│  │                                                         ││
│  │ (Multi-line text input - 6 lines)                      ││
│  │                                                         ││
│  │                                                         ││
│  └────────────────────────────────────────────────────────┘│
│                                                              │
│  ┌────────────────────────────────────────────────────────┐│
│  │         Get Legal Section Suggester (Button)                  ││
│  └────────────────────────────────────────────────────────┘│
│                                                              │
│  ┌────────────────────────────────────────────────────────┐│
│  │  ⚖️  Suggested Legal Sections              (Card 1)    │
│  │                                                         ││
│  │  BNS Section 303 (Theft)                               ││
│  │  BNS Section 304 (Snatching)                           ││
│  │  ...                                                    ││
│  └────────────────────────────────────────────────────────┘│
│                                                              │
│  ┌────────────────────────────────────────────────────────┐│
│  │  💡 Reasoning                              (Card 2)    │
│  │                                                         ││
│  │  The incident describes theft by snatching...          ││
│  │  This qualifies under Bharatiya Nyaya Sanhita...       ││
│  │  ...                                                    ││
│  └────────────────────────────────────────────────────────┘│
│                                                              │
│  ┌────────────────────────────────────────────────────────┐│
│  │  ⚠️  This is informational only, not legal advice.    ││
│  └────────────────────────────────────────────────────────┘│
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Widget Hierarchy

```
Scaffold
├─ SafeArea
   └─ SingleChildScrollView (vertical)
      └─ Column (padding: 16px)
         ├─ HEADER ROW
         │  ├─ IconButton (Back arrow - Orange)
         │  └─ Text ("Legal Section Suggester" - Bold, 24px)
         │
         ├─ SizedBox (height: 20)
         │
         ├─ INPUT FIELD
         │  └─ TextField
         │     ├─ maxLines: 6
         │     ├─ fillColor: White
         │     └─ border: Rounded 12px
         │
         ├─ SizedBox (height: 16)
         │
         ├─ SUBMIT BUTTON
         │  └─ ElevatedButton
         │     ├─ backgroundColor: Orange (#FC633C)
         │     ├─ full width
         │     └─ Loading indicator when _loading=true
         │
         ├─ SizedBox (height: 24)
         │
         └─ RESULTS (if _data != null)
            ├─ CARD 1: Suggested Sections
            │  └─ _infoCard()
            │     ├─ Card (elevation: 4, borderRadius: 16)
            │     └─ Padding (18px)
            │        ├─ Row
            │        │  ├─ Icon (Gavel - Orange)
            │        │  └─ Text (Title - Bold, 18px)
            │        ├─ SizedBox (height: 14)
            │        └─ Text (Content - 15px, lineHeight: 1.6)
            │
            ├─ CARD 2: Reasoning
            │  └─ _infoCard()
            │     └─ (Same structure as Card 1)
            │
            └─ DISCLAIMER BOX
               └─ Container
                  ├─ amber background
                  ├─ amber border
                  ├─ borderRadius: 12
                  └─ Row
                     ├─ Icon (Warning - Amber)
                     └─ Text (Disclaimer message)
```

## Card Component Details

### `_infoCard()` Function

```dart
Widget _infoCard(String title, IconData icon, String content) {
  return Card(
    elevation: 4,                    // ← Shadow depth
    margin: EdgeInsets.only(bottom: 16),  // ← Space between cards
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),  // ← Rounded corners
    ),
    child: Padding(
      padding: EdgeInsets.all(18),   // ← Internal spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: orange),  // ← Orange themed icon
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            content,
            style: TextStyle(fontSize: 15, height: 1.6),
          ),
        ],
      ),
    ),
  );
}
```

## Visual Characteristics

### Card 1: Suggested Legal Sections
- **Icon**: ⚖️ Icons.gavel
- **Color**: Orange (#FC633C)
- **Title**: "Suggested Legal Sections"
- **Content**: AI-generated legal sections text
- **Elevation**: 4 (raised shadow effect)
- **Border Radius**: 16px
- **Bottom Margin**: 16px

### Card 2: Reasoning
- **Icon**: 💡 Icons.lightbulb_outline
- **Color**: Orange (#FC633C)
- **Title**: "Reasoning"
- **Content**: AI-generated reasoning text
- **Elevation**: 4 (raised shadow effect)
- **Border Radius**: 16px
- **Bottom Margin**: 16px

### Disclaimer Box
- **Icon**: ⚠️ Icons.warning_amber_rounded
- **Background**: Amber (#FFF8E1 - Amber.shade50)
- **Border**: Amber color
- **Border Radius**: 12px
- **Padding**: 14px
- **Content**: "This is informational only, not legal advice."

## Color Scheme

```dart
// Primary Color
static const Color orange = Color(0xFFFC633C);

// Background
backgroundColor: Color(0xFFF8F9FA)  // Light gray

// Input Field
fillColor: Colors.white

// Disclaimer
background: Colors.amber.shade50
border: Colors.amber
```

## Spacing System

```dart
// Header to Input: 20px
// Input to Button: 16px
// Button to Results: 24px
// Between Cards: 16px (margin)
// Card Internal Padding: 18px
// Icon to Title: 10px
// Title to Content: 14px
```

## Typography

```dart
// Screen Title
fontSize: 24
fontWeight: FontWeight.bold

// Card Titles
fontSize: 18
fontWeight: FontWeight.bold

// Card Content
fontSize: 15
height: 1.6 (line height)

// Disclaimer Text
fontSize: 13
```

## State Management

### Loading State
```dart
bool _loading = false;

// When true:
- Submit button shows CircularProgressIndicator
- Button is disabled (onPressed: null)
- User cannot interact

// When false:
- Submit button shows "Get Legal Section Suggester" text
- Button is enabled
```

### Data State
```dart
Map<String, dynamic>? _data = null;

// When null:
- Results section is hidden (if condition fails)
- Only input and button visible

// When populated:
- Results section renders
- Shows all 3 components (2 cards + disclaimer)
```

## Separate Box Verification ✅

**Question**: "Does each section show in a separate box?"

**Answer**: YES ✅

**Evidence**:
1. **Card 1** (Suggested Sections): Rendered by `_infoCard()` - Creates individual Card widget
2. **Card 2** (Reasoning): Rendered by `_infoCard()` - Creates individual Card widget  
3. **Disclaimer**: Rendered by `Container()` - Separate container widget

Each component:
- ✅ Has its own widget instance
- ✅ Has distinct visual boundaries (elevation, borders)
- ✅ Has spacing between components (margin: 16px)
- ✅ Can be scrolled independently (within ScrollView)
- ✅ Has its own styling and colors

## Responsive Behavior

```dart
SingleChildScrollView
└─ Allows vertical scrolling if content exceeds screen height
   
TextField
└─ Full width with padding

ElevatedButton
└─ width: double.infinity (full width)

Cards
└─ Expand to fill parent width
   └─ Text wraps within card boundaries
```

## Accessibility Features

- ✅ Icons provide visual context for each section
- ✅ High contrast text on white cards
- ✅ Sufficient padding for touch targets
- ✅ Clear visual hierarchy with font sizes
- ✅ Warning icon for disclaimer
- ✅ Loading indicator for async operations

## Data Flow Through UI

```
User Input → TextField._incidentController.text
              ↓
         _submit() async
              ↓
    HTTP POST to backend
              ↓
    JSON Response → _data
              ↓
    setState(() { _data = res.data })
              ↓
    UI Rebuild triggered
              ↓
    if (_data != null) { render cards }
              ↓
    3 Separate Components Rendered:
    ├─ _infoCard("Suggested Legal Sections", ...)
    ├─ _infoCard("Reasoning", ...)
    └─ Container (Disclaimer)
```

## Backend Response Mapping

```json
Backend Response:
{
  "suggestedSections": "BNS Section 303...",
  "reasoning": "The incident describes..."
}

Flutter Mapping:
_data?['suggestedSections'] → Card 1 content
_data?['reasoning']          → Card 2 content
Hard-coded disclaimer        → Disclaimer box
```

## Error Handling in UI

### Connection Error
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text("Failed to generate Legal Section Suggester"),
    backgroundColor: Colors.red,
  ),
);
```

### Empty Input
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text("Please describe the incident"),
    backgroundColor: Colors.red,
  ),
);
```

### Null/Missing Data
```dart
_data?['suggestedSections'] ?? "No applicable sections found."
_data?['reasoning'] ?? "Reasoning not provided."
```

## Code File Location

**File**: `frontend/lib/screens/legal_suggestion_screen.dart`
**Lines**: 1-231
**Language**: Dart (Flutter)
**Dependencies**:
- `package:flutter/material.dart`
- `package:dio/dio.dart`
- `package:go_router/go_router.dart`
- `../l10n/app_localizations.dart`

## Conclusion

The Legal Section Suggester frontend implements a **clean, card-based UI** where:
1. ✅ Each section is displayed in a **separate Material Card widget**
2. ✅ Cards have distinct visual separation (elevation, borders, spacing)
3. ✅ Icons and colors provide visual hierarchy
4. ✅ Layout is responsive and scrollable
5. ✅ Error states are handled gracefully
6. ✅ Loading states provide user feedback

**UI Pattern**: Material Design Card-based layout with vertical stacking
**Separation Method**: Individual Card widgets with margin spacing
**Visual Distinction**: Elevation shadows, rounded borders, icon + title headers
