# Organizational Assignment System - Implementation Summary

## ✅ COMPLETED

### 1. Assignment Dialog Redesigned
**File**: `assign_petition_dialog.dart`

**New Features**:
- Radio button selection for assignment type
- DGP: Can assign to Range, District, or Station
- IG: Can assign to District or Station (within their range)
- SP: Can assign to Station (within their district)
- Returns `Map<String, dynamic>` with assignment data

**Return Data Structure**:
```dart
{
  'assignmentType': 'range' | 'district' | 'station',
  'assignedToRange': String?,
  'assignedToRangeName': String?,
  'assignedToDistrict': String?,
  'assignedToDistrictName': String?,
  'assignedToStation': String?,
  'assignedToStationName': String?,
}
```

### 2. Petition Model Updated
**File**: `petition.dart`

**New Fields Added**:
- `assignmentType`: 'range', 'district', or 'station'
- `assignedToRange`: Range name
- `assignedToDistrict`: District name
- `assignedToStation`: Station name (already existed, comment updated)

---

## 🔧 TODO: Model Updates

### Step 1: Add to Constructor
In `petition.dart` constructor (around line 195), add:
```dart
Petition({
  // ... existing fields ...
  
  // Assignment fields
  this.assignmentType,
  this.assignedTo,
  this.assignedToName,
  this.assignedToRank,
  this.assignedToRange,
  this.assignedToDistrict,
  this.assignedToStation,
  this.assignedBy,
  this.assignedByName,
  this.assignedAt,
  this.assignmentStatus,
  this.assignmentNotes,
  
  // ... rest of fields ...
});
```

### Step 2: Add to fromFirestore
In `fromFirestore` factory (around line 240), add:
```dart
factory Petition.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return Petition(
    // ... existing fields ...
    
    // Assignment fields
    assignmentType: data['assignmentType'],
    assignedTo: data['assignedTo'],
    assignedToName: data['assignedToName'],
    assignedToRank: data['assignedToRank'],
    assignedToRange: data['assignedToRange'],
    assignedToDistrict: data['assignedToDistrict'],
    assignedToStation: data['assignedToStation'],
    assignedBy: data['assignedBy'],
    assignedByName: data['assignedByName'],
    assignedAt: data['assignedAt'],
    assignmentStatus: data['assignmentStatus'],
    assignmentNotes: data['assignmentNotes'],
    
    // ... rest of fields ...
  );
}
```

### Step 3: Add to toMap
In `toMap` method (around line 285), add:
```dart
Map<String, dynamic> toMap() {
  return {
    // ... existing fields ...
    
    // Assignment fields
    if (assignmentType != null) 'assignmentType': assignmentType,
    if (assignedTo != null) 'assignedTo': assignedTo,
    if (assignedToName != null) 'assignedToName': assignedToName,
    if (assignedToRank != null) 'assignedToRank': assignedToRank,
    if (assignedToRange != null) 'assignedToRange': assignedToRange,
    if (assignedToDistrict != null) 'assignedToDistrict': assignedToDistrict,
    if (assignedToStation != null) 'assignedToStation': assignedToStation,
    if (assignedBy != null) 'assignedBy': assignedBy,
    if (assignedByName != null) 'assignedByName': assignedByName,
    if (assignedAt != null) 'assignedAt': assignedAt,
    if (assignmentStatus != null) 'assignmentStatus': assignmentStatus,
    if (assignmentNotes != null) 'assignmentNotes': assignmentNotes,
    
    // ... rest of fields ...
  };
}
```

---

## 🔧 TODO: Submit Screen Updates

### Update submit_offline_petition_screen.dart

**Change Line 42-44**:
```dart
// OLD
bool _assignImmediately = false;
Map<String, dynamic>? _selectedOfficer;

// NEW
bool _assignImmediately = false;
Map<String, dynamic>? _assignmentData;
```

**Change Lines 165-174** (Assignment fields):
```dart
// OLD
assignedTo: _selectedOfficer?['uid'],
assignedToName: _selectedOfficer?['displayName'],
assignedToRank: _selectedOfficer?['rank'],
assignedToStation: _selectedOfficer?['stationName'],

// NEW
assignmentType: _assignmentData?['assignmentType'],
assignedToRange: _assignmentData?['assignedToRange'],
assignedToDistrict: _assignmentData?['assignedToDistrict'],
assignedToStation: _assignmentData?['assignedToStation'],
```

**Change Lines 569-575** (Display selected assignment):
```dart
// OLD
title: Text(_selectedOfficer == null
    ? 'Select Officer'
    : '${_selectedOfficer!['displayName']} (${_selectedOfficer!['rank']})'),
subtitle: _selectedOfficer == null
    ? const Text('Tap to select an officer')
    : Text(_selectedOfficer!['stationName'] ?? 'No station'),

// NEW
title: Text(_assignmentData == null
    ? 'Select Assignment Target'
    : _getAssignmentDisplayText()),
subtitle: _assignmentData == null
    ? const Text('Tap to select Range, District, or Station')
    : Text(_getAssignmentSubtitle()),
```

**Add Helper Methods**:
```dart
String _getAssignmentDisplayText() {
  if (_assignmentData == null) return 'Not selected';
  final type = _assignmentData!['assignmentType'];
  if (type == 'range') {
    return 'Range: ${_assignmentData!['assignedToRange']}';
  } else if (type == 'district') {
    return 'District: ${_assignmentData!['assignedToDistrict']}';
  } else if (type == 'station') {
    return 'Station: ${_assignmentData!['assignedToStation']}';
  }
  return 'Unknown';
}

String _getAssignmentSubtitle() {
  if (_assignmentData == null) return '';
  final type = _assignmentData!['assignmentType'];
  if (type == 'range') {
    return 'Will be assigned to IG/DIG of this range';
  } else if (type == 'district') {
    return 'Will be assigned to SP of this district';
  } else if (type == 'station') {
    return 'Will be assigned to officers at this station';
  }
  return '';
}
```

**Change Lines 586-590** (Dialog result handling):
```dart
// OLD
if (officer != null) {
  setState(() {
    _selectedOfficer = officer;
  });
}

// NEW
if (assignmentData != null) {
  setState(() {
    _assignmentData = assignmentData;
  });
}
```

---

## 📋 How It Works Now

### DGP Assignment Flow:
1. Click "Assign immediately"
2. See three radio options:
   - **Assign to Range** → Select any range
   - **Assign to District** → Select range, then district
   - **Assign to Station** → Select range, district, then station
3. Select one option, fill dropdown(s)
4. Click "Assign Petition"

### IG Assignment Flow:
1. Click "Assign immediately"
2. Range is pre-selected (their range)
3. See two radio options:
   - **Assign to District** → Select district in their range
   - **Assign to Station** → Select district, then station
4. Select one option, fill dropdown(s)
5. Click "Assign Petition"

### SP Assignment Flow:
1. Click "Assign immediately"
2. Range and District are pre-selected
3. See one option:
   - **Assign to Station** → Select station in their district
4. Select station
5. Click "Assign Petition"

---

## 🎯 Database Structure

### Petition Document (Firestore):
```javascript
{
  // ... existing fields ...
  
  // Organizational Assignment
  assignmentType: "station",  // or "district" or "range"
  assignedToRange: "Eluru Range",
  assignedToDistrict: "Krishna",
  assignedToStation: "Gudivada I Town UPS",
  assignedBy: "dgp-uid-123",
  assignedByName: "DGP Ram Prasad",
  assignedAt: Timestamp,
  assignmentStatus: "pending",
  
  // ... other fields ...
}
```

---

## 🔍 Petition Filtering (For Officers to View)

### Range-Level Officers (IG/DIG):
```dart
// Show petitions assigned to their range
query.where('assignedToRange', isEqualTo: officerRange)
```

### District-Level Officers (SP):
```dart
// Show petitions assigned to their district OR their range
query.where('assignedToDistrict', isEqualTo: officerDistrict)
// OR
query.where('assignedToRange', isEqualTo: officerRange)
```

### Station-Level Officers (SI, ASI, HC, PC):
```dart
// Show petitions assigned to their station
query.where('assignedToStation', isEqualTo: officerStation)
```

---

## ✅ Benefits of This Approach

1. **Realistic Workflow** - Matches how police actually assign work (by jurisdiction)
2. **Flexible Assignment** - Can assign broadly (range) or specifically (station)
3. **Clear Responsibility** - Officers know if petition is for their range/district/station
4. **Easy Filtering** - Simple queries to show relevant petitions
5. **Scalable** - Works for entire state hierarchy

---

## 📝 Next Steps

1. **Update petition.dart** - Add new fields to constructor, fromFirestore, toMap
2. **Update submit_offline_petition_screen.dart** - Change from officer selection to assignment data
3. **Update police_petitions_screen.dart** - Add filtering for organizational assignments
4. **Test the flow** - Login as DGP/IG/SP and test assignment

Would you like me to complete these updates automatically?
