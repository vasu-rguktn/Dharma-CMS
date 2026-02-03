# Case Journal Navigation Implementation

## Summary
Added a dedicated Case Journal screen with sidebar navigation in the Case Management section.

---

## ✅ Changes Made

### 1. **Created Case Journal Screen**
**File**: `lib/screens/case_journal_screen.dart` (374 lines)

**Features**:
- 📋 **Case Selector Dropdown** - Choose from all available cases
- 📚 **Visual Timeline** - Beautiful timeline view of journal entries
- 👤 **Officer Attribution** - Shows officer name, rank, and timestamp
- 🎨 **Enhanced Cards** - Each entry in a styled card with metadata
- 🔗 **Quick Navigation** - Button to open full case details
- 📎 **Related Documents** - Shows document references when available

**Design Elements**:
- Circular timeline dots with shadow effects
- Connecting lines between entries
- Color-coded officer rank badges
- Timestamp and officer information
- Related document indicators
- Empty state for cases with no entries

---

### 2. **Updated Router**
**File**: `lib/router/app_router.dart`

**Changes**:
- Added import for `CaseJournalScreen`
- Added route: `/case-journal`
- Placed in ShellRoute for sidebar navigation

```dart
GoRoute(
  path: '/case-journal',
  builder: (context, state) => const CaseJournalScreen(),
),
```

---

### 3. **Updated Sidebar Navigation**
**File**: `lib/widgets/app_scaffold.dart`

**Changes**:
- Added "Case Journal" menu item in **Case Management** section
- Icon: 📖 `Icons.book`
- Positioned between "All Cases" and "My Saved Complaints"

**Sidebar Structure**:
```
├── Dashboard
├── AI Tools (section)
│   ├── AI Chat
│   ├── Legal Queries
│   ├── Legal Section Suggestions
│   ├── Document Drafting
│   ├── Chargesheet Gen
│   ├── Chargesheet Vetting
│   ├── Witness Prep
│   └── Media Analysis
├── Case Management (section)
│   ├── All Cases
│   ├── Case Journal ✨ NEW
│   └── My Saved Complaints
└── Settings
```

---

## 🎨 UI/UX Features

### Case Journal Screen Layout:

1. **Header Section**
   - Large book icon with title
   - Descriptive subtitle

2. **Case Selector Card**
   - Dropdown showing all cases
   - Format: "FIR Number - Case Title"
   - Empty state message if no cases

3. **Journal Timeline Card**
   - Header with "Investigation Diary" title
   - Quick link to open case details
   - Visual timeline with entries

### Timeline Entry Design:

```
┌─────────────────────────────────────────┐
│ ⚫──────────────────────────────────────│
│ │  ┌────────────────────────────────┐  │
│ │  │ Activity Type         [Rank]   │  │
│ │  │                                │  │
│ │  │ Entry text description...      │  │
│ │  │                                │  │
│ │  │ 👤 Officer Name                │  │
│ │  │ ⏰ DD/MM/YYYY HH:MM            │  │
│ │  │ 📎 Ref: Document ID (if any)   │  │
│ │  └────────────────────────────────┘  │
│ │                                      │
│ ⚫──────────────────────────────────────│
│ │  [...next entry...]                 │
└─────────────────────────────────────────┘
```

**Visual Elements**:
- ⚫ Timeline dots (24x24px, primary color, shadow effect)
- ─ Connecting lines (2px, grey)
- 🎴 Elevated cards for each entry
- 🏷️ Color-coded rank badges
- 📍 Icons for metadata (person, time, attachment)

---

## 🔄 Data Flow

```
User Action
    ↓
Select Case from Dropdown
    ↓
Fetch from Firestore
    ↓
Query: caseJournalEntries
    ↓
Filter: where caseId == selectedCase
    ↓
Sort: by dateTime descending
    ↓
Display in Timeline
```

**Loading States**:
- ⏳ Loading indicator while fetching
- 📭 Empty state if no entries
- ⚠️ Error snackbar on failure

---

## 📱 Navigation Paths

### From Sidebar:
```
Hamburger Menu → Case Management → Case Journal
```

### From Case Journal:
```
Case Journal → [Open in new] button → Case Detail (specific tab)
```

### From Case Detail:
```
Case Detail → Investigation Tab → View Journal Timeline
```

---

## 🎯 Use Cases

### 1. **View Investigation Progress**
- Officer opens Case Journal
- Selects active investigation
- Reviews timeline of activities
- Checks what actions were taken

### 2. **Track Officer Activities**
- Supervisor accesses journal
- Filters by specific case
- Views which officers worked on case
- Reviews timestamps and activities

### 3. **Quick Case Access**
- User in Case Journal
- Finds relevant entry
- Clicks "Open in new" icon
- Jumps directly to full case details

---

## 💾 Firestore Integration

**Collection**: `caseJournalEntries`

**Query**:
```dart
FirebaseFirestore.instance
  .collection('caseJournalEntries')
  .where('caseId', isEqualTo: selectedCaseId)
  .orderBy('dateTime', descending: true)
  .get()
```

**Model**: `CaseJournalEntry`
- id (auto-generated)
- caseId
- officerUid
- officerName
- officerRank
- dateTime (Timestamp)
- entryText
- activityType
- relatedDocumentId (optional)

---

## 🎓 Key Features

### 1. **Case Selection**
- Dropdown populated from CaseProvider
- Shows FIR number and title
- Clears journal when selection changes

### 2. **Timeline Visualization**
- Beautiful visual timeline
- Chronological order (newest first)
- Officer attribution
- Activity categorization

### 3. **Entry Cards**
- Elevated card design
- Activity type as header
- Rank badge
- Full entry text
- Metadata row (officer, time)
- Document reference link

### 4. **Navigation Integration**
- Icon button to open case details
- Direct link to `/cases/{caseId}`
- Maintains context

### 5. **Empty States**
- No cases available message
- No entries yet message
- Helpful guidance text

---

## 📊 Statistics

**New Files**: 1
- `case_journal_screen.dart` (374 lines)

**Modified Files**: 2
- `app_router.dart` (+5 lines)
- `app_scaffold.dart` (+1 line)

**Total Lines Added**: 380 lines

**Compilation Status**: ✅ No errors (only minor lint warnings)

---

## 🚀 Future Enhancements

### Planned Features:
1. **Add Entry Button** ⏳
   - Form to create new journal entries
   - Rich text editor
   - Document attachment

2. **Filter & Search** ⏳
   - Filter by activity type
   - Search entry text
   - Date range selector

3. **Export Journal** ⏳
   - PDF generation
   - Print functionality
   - Email sharing

4. **Real-time Updates** ⏳
   - StreamBuilder instead of FutureBuilder
   - Live updates when entries added
   - Push notifications

5. **Entry Details** ⏳
   - Tap entry to see full details
   - View attached documents
   - Edit/delete permissions

---

## ✅ Testing Checklist

- [x] Case Journal screen created
- [x] Route added to router
- [x] Sidebar navigation updated
- [x] No compilation errors
- [x] Proper model integration
- [x] Firestore query working
- [x] Timeline displays correctly
- [x] Empty states handled
- [x] Navigation to case details
- [x] Loading states implemented

---

## 🎉 Result

✅ **Case Journal is now accessible from the sidebar!**

Users can now:
1. Open the hamburger menu
2. Navigate to **Case Management** section
3. Click on **Case Journal**
4. Select a case from dropdown
5. View the complete investigation timeline

The feature is fully integrated with:
- ✅ Sidebar navigation
- ✅ Routing system
- ✅ Firebase/Firestore
- ✅ Case provider
- ✅ Case detail screen

---

**Implementation Date**: 2025-10-23  
**Status**: ✅ Complete and Working  
**Location**: Case Management → Case Journal
