# Cascading Location-Based Officer Assignment

## Overview
The officer assignment feature now uses a **hierarchical cascading selection** system where higher-ranking officers select location first (Range → District → Station) before choosing an officer.

---

## 📍 Selection Flow by Rank

### DGP / Additional DGP (State Level)
```
Step 1: Select Range
   ↓
Step 2: Select District (within selected Range)
   ↓
Step 3: Select Police Station (within selected District)
   ↓
Step 4: Select Officer (from selected Station)
```

**Example:**
1. Select Range: "Eluru Range"
2. Select District: "Krishna"
3. Select Police Station: "Gudivada I Town UPS"
4. View officers at Gudivada I Town → Select SI Ravi Kumar

---

### IG / DIG (Range Level)
```
(Range is pre-selected based on their assignment)
   ↓
Step 1: Select District (within their Range)
   ↓
Step 2: Select Police Station (within selected District)
   ↓
Step 3: Select Officer (from selected Station)
```

**Example:**
- Officer's Range: "Eluru Range" (auto-selected)
1. Select District: "West Godavari"
2. Select Police Station: "Bh imavaram I Town"
3. View officers at Bhimavaram → Select ASI Prasad

---

### SP / Additional SP (District Level)
```
(Range and District are pre-selected)
   ↓
Step 1: Select Police Station (within their District)
   ↓
Step 2: Select Officer (from selected Station)
```

**Example:**
- Officer's District: "Krishna" (auto-selected)
1. Select Police Station: "Penamaluru UPS"
2. View officers at Penamaluru → Select Head Constable Suresh

---

## 🎯 Key Features

### Location-Based Filtering
- **Officers are loaded ONLY from the selected station**
- No need to manually filter through hundreds of officers
- Ensures assignment to the correct jurisdiction

### Smart Pre-Selection
- **DGP**: Free to select any Range (no pre-selection)
- **IG**: Range pre-selected (their assigned range)
- **SP**: Range + District pre-selected (their jurisdiction)

### Cascading Dropdowns
- Selecting Range → Populates Districts in that Range
- Selecting District → Populates Stations in that District
- Selecting Station → Loads Officers at that Station

### Real-Time Loading
- Officers are fetched from Firestore when station is selected
- Shows loading indicator while fetching
- Filters only eligible lower-rank officers

---

## 🔍 Search & Filter

Even after selecting a station, you can:
- **Search** by officer name or rank
- **Filter** by specific rank (SI, ASI, Head Constable, etc.)
- **View** officer details (name, rank, station, district)

---

## 📊 Technical Implementation

### Data Structure
```dart
Map<String, Map<String, List<String>>> policeHierarchy = {
  "Eluru Range": {
    "Krishna": [
      "Gudivada I Town UPS",
      "Penamaluru UPS",
      "Vuyyuru Town UPS",
      ...
    ],
    "West Godavari": [
      "Bhimavaram I Town",
      "Narasapuram Town",
      ...
    ],
  },
  "Guntur Range": {
    ...
  },
};
```

### Selection State
```dart
String? _selectedRange;    // DGP selects
String? _selectedDistrict; // DGP/IG selects
String? _selectedStation;  // All select
```

### Officer Query
```dart
FirebaseFirestore.instance
  .collection('police_users')
  .where('stationName', isEqualTo: _selectedStation)
  .where('rank', whereIn: eligibleRanks)
  .get();
```

---

## 🎨 UI Components

### 1. Location Selection Card
Shows dropdowns based on officer rank:
- DGP: Range + District + Station
- IG: District + Station (Range shown as info)
- SP: Station (Range + District shown as info)

### 2. Officer List
- Only appears AFTER station is selected
- Shows filtered officers from that station
- Real-time search and filtering
- Card-based layout with officer details

### 3. Loading States
- ⏳ "Loading hierarchy data..."
- ⏳ "Loading officers..."
- ℹ️ "Select a police station first"
- ❌ "No officers found at this station"

---

## 📋 Use Cases

### Use Case 1: DGP Assigns Across State
**Scenario**: DGP receives complaint from Guntur Range
1. Open "Submit Offline Petition"
2. Fill petition details
3. Toggle "Assign immediately"
4. Select Range: "Guntur Range"
5. Select District: "Guntur"
6. Select Station: "Mangalagiri Town"
7. Select Officer: "SI Ramesh (Mangalagiri Town)"
8. Submit

✅ Result: SI Ramesh at Mangalagiri Town sees the petition in "Assigned to Me"

---

### Use Case 2: IG Assigns Within Range
**Scenario**: IG Eluru Range assigns to station officer
1. Range: "Eluru Range" (auto-selected)
2. Select District: "Eluru"
3. Select Station: "Eluru I Town"
4. Select Officer: "ASI Kumar"
5. Submit

✅ Result: ASI Kumar sees assignment

---

### Use Case 3: SP Assigns Within District
**Scenario**: SP Krishna assigns to station officer
1. District: "Krishna" (auto-selected)
2. Select Station: "Vuyyuru Town UPS"
3. Select Officer: "Head Constable Satish"
4. Submit

✅ Result: Head Constable Satish sees assignment

---

## 🔐 Security & Validation

### Rank Hierarchy Enforcement
- Officer list only includes ranks BELOW the assigning officer
- Uses rank index comparison for validation
- Prevents assigning to same or higher rank

### Jurisdiction Validation
- Officers shown ONLY from selected station
- Pre-selection based on officer's assignment
- Firebase query filters by station name

### Data Integrity
- Station must exist in hierarchy JSON
- District must belong to selected Range
- Station must belong to selected District

---

## 📱 User Experience

### For Assigning Officer
- **Clear workflow**: Location first, officer second
- **Progressive disclosure**: Next step only after current selection
- **Visual feedback**: Dropdowns enabled/disabled based on state
- **Fast selection**: Direct hit to relevant officers

### For Assigned Officer
- Petition appears in "Assigned to Me" tab
- Shows assigning officer details
- Can accept or reject assignment
- Updates in real-time

---

## 🐛 Error Handling

### Common Scenarios
| Issue | Handling |
|-------|----------|
| No range selected | District dropdown disabled |
| No district selected | Station dropdown disabled |
| No station selected | "Select station first" message |
| No officers at station | "No officers found" with icon |
| Network error | Error snackbar with message |
| Invalid rank | Returns to dialog with error |

---

## 🔮 Future Enhancements

1. **Officer Workload Display**
   - Show current petition count per officer
   - Color-code based on workload
   - Suggest officers with lighter load

2. **Batch Assignment**
   - Assign multiple petitions to same officer
   - Bulk assignment to multiple officers

3. **Assignment History**
   - See who was previously assigned
   - Reassignment tracking
   - Assignment analytics

4. **Smart Suggestions**
   - Suggest officers based on petition type
   - ML-based assignment recommendations
   - Historical performance metrics

---

## 📝 Testing Checklist

- [ ] DGP can select any range
- [ ] IG sees only districts in their range
- [ ] SP sees only stations in their district
- [ ] Officers load correctly per station
- [ ] Search filtering works
- [ ] Rank filtering works
- [ ] Assignment creates petition correctly
- [ ] Assigned officer sees petition
- [ ] Accept/Reject workflow functions
- [ ] Real-time updates work

---

**Last Updated**: January 2026  
**Version**: 2.0  
**Feature**: Cascading Location-Based Officer Assignment
