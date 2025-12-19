# Quick Reference: Authentication Flows

## 🚓 POLICE FLOW
```
Welcome Screen
    ↓
Police Registration Screen
    ↓
Police Login Screen  
    ↓
Police Dashboard
```

**Provider**: `police_auth_provider.dart`  
**Dashboard Features**: Same as citizen dashboard

---

## 👤 CITIZEN FLOW

### Option 1: Full Registration
```
Welcome Screen
    ↓
Citizen Registration Screen
    ↓
Address Screen
    ↓
Signup Screen
    ↓
Citizen Dashboard
```

### Option 2: Email Login
```
Welcome Screen
    ↓
Citizen Login Screen
    ↓
Citizen Dashboard
```

### Option 3: Phone Login
```
Welcome Screen
    ↓
Phone Login Screen
    ↓
Citizen Dashboard
```

**Provider**: `auth_provider.dart`  
**Dashboard Features**: Same as police dashboard

---

## ✅ KEY CHANGES MADE

1. ✅ Renamed `login_screen.dart` → `citizen_login_screen.dart`
2. ✅ Renamed `LoginScreen` class → `CitizenLoginScreen`
3. ✅ Updated `police_auth_provider.dart` to store profiles in both `police` and `users` collections
4. ✅ Display name now properly fetched from Firebase for both user types
5. ✅ Menu items and dashboard features are identical for both police and citizen
6. ✅ All authentication flows clearly separated by folder structure:
   - `screens/CitizenAuth/` - All citizen screens
   - `screens/PoliceAuth/` - All police screens

---

## 📂 FILE STRUCTURE

```
screens/
├── CitizenAuth/
│   ├── citizen_login_screen.dart       ✅ RENAMED
│   ├── citizen_registration_screen.dart
│   ├── adress_form_screen.dart
│   └── signup_screen.dart
├── PoliceAuth/
│   ├── police_login_screen.dart
│   └── police_registration_screen.dart
├── phone_login_screen.dart            (Citizen only)
├── citizen_dashboard_screen.dart
├── police_dashboard_screen.dart
└── dashboard_body.dart                (Shared UI)
```

---

## 🎯 DASHBOARD FEATURES (IDENTICAL FOR BOTH)

### Police Dashboard Quick Actions:
- Document Drafting
- Chargesheet Generation
- Chargesheet Vetting
- Media Analysis
- Case Journal
- Complaints
- Petitions

### Citizen Dashboard Quick Actions:
- AI Chat
- Legal Queries
- Legal Suggestion
- My Saved Complaints
- Witness Prep
- Petitions
- Helpline

**Note**: Both use the same `DashboardBody` component with `isPolice` flag to differentiate.

---

## 🔑 AUTHENTICATION SUMMARY

| Feature | Police | Citizen |
|---------|--------|---------|
| Email/Password | ✅ | ✅ |
| Phone OTP | ❌ | ✅ |
| Google Sign-In | ❌ | ✅ |
| Registration Steps | 1 | 3 |
| Provider | `police_auth_provider` | `auth_provider` |
| Collections | `police` + `users` | `users` |
| Dashboard | `police_dashboard_screen` | `citizen_dashboard_screen` |
| Display Name | ✅ From Firebase | ✅ From Firebase |

