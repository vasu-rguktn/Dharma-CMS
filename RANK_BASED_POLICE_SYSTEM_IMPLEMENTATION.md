# RANK-BASED POLICE REGISTRATION & PETITION SYSTEM

## 📋 OVERVIEW

This document outlines the complete implementation of a rank-based police registration and petition filtering system according to the **real Indian Police hierarchy**.

---

## 🏛️ INDIAN POLICE HIERARCHY & JURISDICTION

### **State Level**
- **Director General of Police (DGP)**
- **Additional Director General of Police (Addl. DGP)**
- **Jurisdiction**: Entire State
- **Fields Required**: Name, Email, Password, Rank, State (read-only)
- **NO field for**: Range, District, Police Station

### **Range Level**
- **Inspector General of Police (IGP)**
- **Deputy Inspector General of Police (DIG)**
- **Jurisdiction**: Police Range (Zone)
- **Fields Required**: Name, Email, Password, Rank, State, Range
- **NO field for**: District, Police Station

### **District Level**
- **Superintendent of Police (SP)**
- **Additional Superintendent of Police (Addl. SP)**
- **Jurisdiction**: District
- **Fields Required**: Name, Email, Password, Rank, State, Range, District
- **NO field for**: Police Station

### **Station Level**
- **Deputy Superintendent of Police (DSP)**
- **Inspector of Police**
- **Sub Inspector of Police (SI)**
- **Assistant Sub Inspector of Police (ASI)**
- **Head Constable (HC)**
- **Police Constable (PC)**
- **Jurisdiction**: Police Station
- **Fields Required**: Name, Email, Password, Rank, State, Range, District, Police Station

---

## 📁 FILES TO CREATE/MODIFY

### 1. **JSON Structure** ✅
- `assets/Data/ap_police_hierarchy.json` (Range → District → Stations)

### 2. **Provider** ✅
- `lib/providers/police_auth_provider.dart` (Add range, state fields)

### 3. **Registration Screen** ✅
- `lib/screens/PoliceAuth/police_registration_screen.dart` (Rank-based dynamic UI)

### 4. **Petitions Screen** ✅
- `lib/screens/police_petitions_screen.dart` (Rank-based filtering)

---

## 🔄 PETITION FETCHING LOGIC BY RANK

### **DGP / Additional DGP** (State Level)
1. Can view ALL petitions in the state
2. Need to select:
   - Range (optional filter) → District (optional) → Police Station (optional)

### **IGP / DIG** (Range Level)
1. Can view petitions from their assigned Range
2. Need to select:
   - District (optional filter) → Police Station (optional)

### **SP / Additional SP** (District Level)
1. Can view petitions from their assigned District
2. Need to select:
   - Police Station (optional filter from dropdown within their district)

### **DSP / Inspector / SI / ASI / HC / PC** (Station Level)
1. Can ONLY view petitions from their assigned Police Station
2. NO need to select anything (automatic filtering)

---

## 🚀 IMPLEMENTATION STATUS

✅ JSON structure created
✅ Police Auth Provider updated
✅ Police Registration Screen updated
✅ Police Petitions Screen updated
✅ Rank-based field visibility
✅ Cascading dropdown (Range → District → Station)
✅ Validation logic
✅ Searchable dropdowns

---

## 📝 TEST SCENARIOS

1. **Test DGP Registration**: Only Name, Email, Password, Rank should be required
2. **Test IGP Registration**: Range field should appear
3. **Test SP Registration**: Range + District fields should appear
4. **Test Inspector Registration**: Full hierarchy (Range → District → Station)
5. **Test Petition Fetching**: Each rank should see appropriate filters

---

## 🎯 NEXT STEPS

1. Deploy updated JSON to Firebase/Assets
2. Update Firestore security rules for rank-based access
3. Test with real police accounts
4. Monitor for edge cases

---

**Implementation Date**: 2026-01-04
**Author**: AI Assistant (Antigravity)
