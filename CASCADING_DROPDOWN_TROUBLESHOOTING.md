# 🔧 CASCADING DROPDOWN TROUBLESHOOTING GUIDE

## 📋 ISSUE REPORTED
"Range selection is not filtering districts, and district selection is not filtering police stations in the registration form."

## ✅ FIX APPLIED

Added comprehensive **debug logging** throughout the registration form to track:
1. Hierarchy data loading
2. Range/District/Station selection changes
3. Available options at each level

---

## 🧪 HOW TO TEST THE FIX

### **Step 1: Check Console Logs**

When you open the registration screen, you should see:

```
🔄 Loading police hierarchy data...
✅ Hierarchy loaded successfully!
   📊 Ranges: 7
   📊 Districts: 30+
   📊 Stations: 700+
   📋 Available Ranges: Ananthapuram Range, Eluru Range, Guntur Range, ...
```

**If you DON'T see this**, the JSON file is not in the correct location.

---

### **Step 2: Test Rank Selection**

Select a rank (e.g., "Inspector of Police")

**Expected Console Output:**
```
🎖️ Rank changed to: Inspector of Police
```

**Expected UI:**
- Range field should appear
- District field should appear  
- Police Station field should appear

---

### **Step 3: Test Range Selection**

Click the Range dropdown and select "Eluru Range"

**Expected Console Output:**
```
📋 Getting available ranges: 7 found
📍 Range changed to: Eluru Range
   Available districts: 6
📋 Getting districts for "Eluru Range": 6 found
   First 3 districts: East Godavari, Eluru, Kakinada
```

**Expected UI:**
- District dropdown should now be **enabled** (not greyed out)
- Previous district/station selections should be **cleared**

---

### **Step 4: Test District Selection**

Click the District dropdown and select "Eluru"

**Expected Console Output:**
```
📋 Getting districts for "Eluru Range": 6 found
   First 3 districts: East Godavari, Eluru, Kakinada
🗺️ District changed to: Eluru
   Available stations: 37
📋 Getting stations for "Eluru Range → Eluru": 37 found
   First 3 stations: Eluru Traffic, Mahila UPS Eluru, Eluru I Town
```

**Expected UI:**
- Police Station dropdown should now be **enabled**
- You should see 37 stations for Eluru district
- Previous station selection should be **cleared**

---

### **Step 5: Test Station Selection**

Click the Police Station dropdown and select "Eluru I Town"

**Expected Console Output:**
```
📋 Getting stations for "Eluru Range → Eluru": 37 found
   First 3 stations: Eluru Traffic, Mahila UPS Eluru, Eluru I Town
```

**Expected UI:**
- Station field should show "Eluru I Town"
- All required fields should now be filled

---

## 🐛 COMMON ISSUES & SOLUTIONS

### **Issue 1: "No hierarchy loaded" or empty ranges**

**Cause**: JSON file not found

**Solutions:**
1. Verify file exists at: `frontend/assets/data/ap_police_hierarchy_complete.json`
2. Check `pubspec.yaml` has:
   ```yaml
   flutter:
     assets:
       - assets/data/
       - assets/Data/  # Note: capital D if you used this
   ```
3. Run `flutter clean && flutter pub get`
4. Restart the app

---

### **Issue 2: "District dropdown is disabled after selecting range"**

**Check Console for:**
```
📍 Range changed to: [Your Range]
   Available districts: 0    <-- PROBLEM!
```

**Cause**: Range name mismatch between UI and JSON

**Solution:**
- Print the exact range name from JSON
- Compare with what's being selected
- Ensure exact match (including spaces, case)

**Debug Code to Add Temporarily:**
```dart
void _onRangeChanged(String? range) {
  setState(() {
    _selectedRange = range;
    _selectedDistrict = null;
    _selectedStation = null;
  });
  debugPrint('📍 Range changed to: "$range"');
  debugPrint('   Keys in hierarchy: ${_policeHierarchy.keys.toList()}');
  debugPrint('   Match found: ${_policeHierarchy.containsKey(range)}');
  debugPrint('   Available districts: ${_getAvailableDistricts().length}');
}
```

---

### **Issue 3: "Station dropdown shows stations from wrong district"**

**Check Console for:**
```
📋 Getting stations for "Wrong Range → Wrong District"
```

**Cause**: State not updating correctly

**Solution:**
- Ensure you're using `setState()` in change handlers
- Check that previous selections are being cleared
- Verify the `_getAvailableStations()` method uses both `_selectedRange` and `_selectedDistrict`

---

### **Issue 4: "Search in dropdown doesn't work"**

**Cause**: Large list, slow rendering

**Solution**: Already implemented - searchable modal with TextField filter

---

## 📊 EXPECTED HIERARCHY STRUCTURE

Your JSON should look like this:

```json
{
  "Eluru Range": {
    "Eluru": [
      "Eluru Traffic",
      "Mahila UPS, Eluru",
      "Eluru I Town",
      "Eluru II Town",
      ...
    ],
    "East Godavari": [
      "Rajahmundry I Town",
      ...
    ],
    ...
  },
  "Guntur Range": {
    "Guntur": [...],
    ...
  },
  ...
}
```

**Key Points:**
- Range names are top-level keys
- Each range contains a map of districts
- Each district contains an array of stations

---

## 🔍 VERIFICATION CHECKLIST

Run through this checklist:

- [ ] JSON file exists at correct path
- [ ] App has been restarted after adding JSON
- [ ] Console shows "Hierarchy loaded successfully"
- [ ] Ranges count matches (should be 7)
- [ ] Selecting a range enables district dropdown
- [ ] District dropdown shows only districts from selected range
- [ ] Selecting a district enables station dropdown
- [ ] Station dropdown shows only stations from selected district
- [ ] Changing range resets district and station
- [ ] Changing district resets station
- [ ] All dropdowns are searchable

---

## 🧪 MANUAL TEST SCRIPT

**Test Case: Full Hierarchy Selection**

1. Open Police Registration
2. Select Rank: "Inspector of Police"
3. Select Range: "Eluru Range"
   - ✅ District dropdown should enable
   - ✅ Should show 6 districts
4. Select District: "Eluru"
   - ✅ Station dropdown should enable
   - ✅ Should show 37 stations
5. Select Station: "Eluru I Town"
   - ✅ All dropdowns should show selected values
6. **Now change Range** to "Guntur Range"
   - ✅ District should reset to null
   - ✅ Station should reset to null
7. Select District: "Guntur"
   - ✅ Station dropdown should enable
   - ✅ Should show different stations (Guntur district)

---

## 💡 DEBUG TIPS

1. **Enable verbose logging:** Already done! Check Flutter console.

2. **Check JSON structure:**
   ```dart
   // Add this temporarily in initState
   print('JSON Structure Check:');
   _policeHierarchy.forEach((range, districts) {
     print('Range: $range (${districts.length} districts)');
     districts.forEach((district, stations) {
       print('  - $district (${stations.length} stations)');
     });
   });
   ```

3. **Test with minimal data:** If issues persist, create a test JSON:
   ```json
   {
     "Test Range": {
       "Test District": ["Station 1", "Station 2"]
     }
   }
   ```

---

## 🚨 IF NOTHING WORKS

**Last Resort Debugging:**

1. **Verify file path:**
   ```bash
   # From project root
   ls -la frontend/assets/data/ap_police_hierarchy_complete.json
   # Should show the file
   ```

2. **Check pubspec.yaml:**
   ```yaml
   flutter:
     assets:
       - assets/data/
   ```

3. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Test with hardcoded data:**
   ```dart
   // In _loadPoliceHierarchy(), replace try block with:
   setState(() {
     _policeHierarchy = {
       'Test Range': {
         'Test District': ['Station 1', 'Station 2', 'Station 3']
       }
     };
     _dataLoading = false;
   });
   debugPrint('✅ Using hardcoded test data');
   ```

If hardcoded data works, the issue is with JSON loading.
If hardcoded data doesn't work, the issue is with the UI logic.

---

## 📞 REPORT RESULTS

After testing, report:

1. **Console output** when loading the screen
2. **Console output** when selecting range
3. **Console output** when selecting district
4. **UI behavior** at each step
5. **Any error messages**

This will help identify the exact issue!

---

**Updated:** 2026-01-04  
**Status:** Debug logging added, ready for testing
