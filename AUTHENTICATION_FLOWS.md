# Dharma CMS - Authentication Flow Documentation

This document outlines the separated authentication flows for **Police** and **Citizen** users in the Dharma CMS application.

## Overview

The Dharma CMS has two distinct user types with separate authentication flows:
1. **Police Users** - Law enforcement officers with administrative capabilities
2. **Citizen Users** - Regular users seeking legal assistance and services

---

## 🔵 **Police Authentication Flow**

### Registration Flow
```
Welcome Screen 
   ↓
Police Registration Screen (`PoliceRegistrationScreen`)
   ↓
Police Login Screen (`PoliceLoginScreen`)
   ↓
Police Dashboard (`PoliceDashboardScreen`)
```

### Login Flow
```
Welcome Screen
   ↓
Police Login Screen (`PoliceLoginScreen`)
   ↓
Police Dashboard (`PoliceDashboardScreen`)
```

### Key Files
- **Screen**: `frontend/lib/screens/PoliceAuth/police_registration_screen.dart`
- **Screen**: `frontend/lib/screens/PoliceAuth/police_login_screen.dart`
- **Dashboard**: `frontend/lib/screens/police_dashboard_screen.dart`
- **Provider**: `frontend/lib/providers/police_auth_provider.dart`
- **Routes**: 
  - Registration: `/signup/police`
  - Login: `/police-login`
  - Dashboard: `/police-dashboard`

### Database Collections
Police users are stored in **both** collections for consistency:
- `police` collection (police-specific data: district, stationName, rank)
- `users` collection (general user profile data with role='police')

### Police Dashboard Features
- Document Drafting
- Chargesheet Generation
- Chargesheet Vetting
- Media Analysis
- Case Journal
- Complaints
- Petitions (Police View)
- And more...

---

## 🟢 **Citizen Authentication Flow**

### Registration Flow
```
Welcome Screen
   ↓
Citizen Registration Screen (`RegisterScreen`)
   ↓
Address Form Screen (`AddressFormScreen`)
   ↓
Login Details Screen (`LoginDetailsScreen`)
   ↓
OTP Verification Screen (`OtpVerificationScreen`)
   ↓
Citizen Dashboard (`CitizenDashboardScreen`)
```

### Email Login Flow
```
Welcome Screen
   ↓
Citizen Login Screen (`CitizenLoginScreen`)
   ↓
Citizen Dashboard (`CitizenDashboardScreen`)
```

### Phone Login Flow
```
Welcome Screen
   ↓
Phone Login Screen (`PhoneLoginScreen`)
   ↓
Citizen Dashboard (`CitizenDashboardScreen`)
```

### Key Files
- **Screens**: `frontend/lib/screens/CitizenAuth/`
  - `citizen_registration_screen.dart`
  - `citizen_login_screen.dart` (renamed from `login_screen.dart`)
  - `adress_form_screen.dart`
  - `signup_screen.dart`
- **Phone Login**: `frontend/lib/screens/phone_login_screen.dart`
- **Dashboard**: `frontend/lib/screens/citizen_dashboard_screen.dart`
- **Provider**: `frontend/lib/providers/auth_provider.dart`
- **Routes**:
  - Registration: `/signup/citizen`
  - Email Login: `/login`
  - Phone Login: `/phone-login`
  - Address Form: `/address`
  - Login Details: `/login_details`
  - Dashboard: `/dashboard` or `/ai-legal-guider`

### Database Collection
Citizen users are stored in:
- `users` collection (with role='citizen')

### Citizen Dashboard Features
- AI Chat
- Legal Queries
- Legal Suggestion
- My Saved Complaints
- Witness Prep
- Petitions (Citizen View)
- Helpline
- And more...

---

## 📋 **Shared Components**

### Dashboard Body
Both Police and Citizen dashboards use the same underlying component:
- **File**: `frontend/lib/screens/dashboard_body.dart`
- The `DashboardBody` widget accepts an `isPolice` boolean flag to differentiate between the two user types
- Features and menu items are displayed based on this flag

### Features Available to Both:
- Petitions (different views)
- Complaints
- Settings
- Profile management

### Feature Visibility
The system uses role-based access control:
- **Police-only features**: Document Drafting, Chargesheet Generation/Vetting, Media Analysis, Case Journal
- **Citizen-only features**: AI Legal Chat, Legal Queries, Legal Suggestion, Witness Preparation, Helpline

---

## 🔧 **Authentication Providers**

### AuthProvider (Citizen)
**Location**: `frontend/lib/providers/auth_provider.dart`

**Responsibilities**:
- Email/Password authentication
- Google Sign-In
- Phone OTP authentication
- User profile management from 'users' collection
- Profile loading and caching
- Display name fetching from Firebase

**Key Methods**:
- `signInWithEmail()`
- `signUpWithEmail()`
- `signInWithGoogle()`
- `sendOtp()`
- `verifyOtp()`
- `loadUserProfile()`
- `createUserProfile()`

### PoliceAuthProvider
**Location**: `frontend/lib/providers/police_auth_provider.dart`

**Responsibilities**:
- Police-specific email/password authentication
- Police registration with additional verification
- Storing police data in both 'police' and 'users' collections
- Approval status checking

**Key Methods**:
- `registerPolice()` - Stores data in both 'police' and 'users' collections
- `loginPolice()` - Verifies police account and approval status
- `logout()`

---

## 🗂️ **Firebase Collections Structure**

### `users` Collection
Used for **all users** (both police and citizen):
```
{
  uid: string,
  email: string,
  displayName: string,
  phoneNumber: string (optional),
  role: 'police' | 'citizen',
  district: string (police only),
  stationName: string (police only),
  rank: string (police only),
  dob: string (citizen only),
  gender: string (citizen only),
  houseNo: string (citizen only),
  address: string (citizen only),
  pincode: string (citizen only),
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### `police` Collection
Used for **police-specific data** (duplicate for police users):
```
{
  uid: string,
  displayName: string,
  email: string,
  district: string,
  stationName: string,
  rank: string,
  role: 'police',
  isApproved: boolean,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Note**: Police users have entries in BOTH collections to ensure:
1. Compatibility with AuthProvider which loads from 'users'
2. Police-specific query capabilities from 'police' collection
3. Consistent profile data fetching across the app

---

## 🔐 **Display Name Fetching**

### For Citizen Users:
1. Display name is captured during registration in `RegisterScreen`
2. Stored in `users` collection during `createUserProfile()`
3. Loaded by `AuthProvider._loadUserProfile()`
4. Displayed in dashboard via `auth.userProfile?.displayName`

### For Police Users:
1. Display name is captured during registration in `PoliceRegistrationScreen`
2. Stored in **both** `police` and `users` collections during `registerPolice()`
3. Loaded by `AuthProvider._loadUserProfile()` from 'users' collection
4. Displayed in dashboard via `auth.userProfile?.displayName`

**Note**: The recent update ensures police profiles are also saved in the `users` collection, allowing `AuthProvider` to load them consistently.

---

## 🎨 **Dashboard Menu & Feature Parity**

Both dashboards use the same `DashboardBody` component with identical UI structure:
- Welcome message with user's display name
- Petition statistics grid
- Quick Actions section
- Recent Activity section

### Menu Items (Side Navigation)
The side navigation menu adapts based on user role:
- Police users see police-specific menu items
- Citizen users see citizen-specific menu items
- Both have access to Settings and Logout

---

## 🚀 **Routing**

All routes are defined in `frontend/lib/router/app_router.dart`:

### Public Routes:
- `/` - Welcome Screen
- `/login` - Citizen Login
- `/police-login` - Police Login
- `/phone-login` - Phone Login (Citizen)
- `/signup/citizen` - Citizen Registration
- `/signup/police` - Police Registration
- `/address` - Address Form (Citizen)
- `/login_details` - Login Details (Citizen)
- `/otp_verification` - OTP Verification

### Protected Routes (require authentication):
- `/dashboard` - Citizen Dashboard (redirects to `/ai-legal-guider`)
- `/police-dashboard` - Police Dashboard
- `/petitions` - Shows either PolicePetitionsScreen or CitizenPetitionsScreen based on role
- All feature screens (cases, complaints, legal queries, etc.)

### Role-Based Redirects:
- Authenticated police users → `/police-dashboard`
- Authenticated citizen users → `/ai-legal-guider`
- Unauthenticated users trying to access protected routes → `/login`

---

## ✅ **Recent Changes Summary**

1. **Renamed `login_screen.dart` to `citizen_login_screen.dart`**
   - Updated class name from `LoginScreen` to `CitizenLoginScreen`
   - Updated import in `app_router.dart`

2. **Updated Police Registration**
   - Now stores police profiles in BOTH `police` and `users` collections
   - Ensures `AuthProvider` can load police profiles consistently
   - Display name is properly fetched from Firebase for police users

3. **Clarified File Organization**
   - Police auth screens in `screens/PoliceAuth/`
   - Citizen auth screens in `screens/CitizenAuth/`
   - Clear separation between authentication flows

4. **Dashboard Feature Parity**
   - Both dashboards use the same `DashboardBody` component
   - Menu items adapt based on user role
   - Identical UI structure for consistent user experience

---

## 📝 **Developer Notes**

### Adding a New Feature:
1. Determine if the feature is police-only, citizen-only, or shared
2. Add the route in `app_router.dart`
3. If police-only, add to `_policeActions()` in `dashboard_body.dart`
4. If citizen-only, add to `_citizenActions()` in `dashboard_body.dart`
5. Update firestore rules to enforce role-based access

### Debugging Authentication Issues:
1. Check `AuthProvider` logs in console (starts with "AuthProvider:")
2. Verify user exists in correct Firestore collection(s)
3. Confirm role field is set correctly ('police' or 'citizen')
4. Check route redirect logic in `app_router.dart`

### Testing:
- Test both registration flows independently
- Verify display names appear correctly in dashboards
- Ensure role-based features are properly restricted
- Test navigation between screens in each flow
- Verify Firestore data is correctly saved in appropriate collections

---

## 🔗 **Related Files**

### Models:
- `frontend/lib/models/user_profile.dart` - UserProfile data model

### Widgets:
- `frontend/lib/widgets/app_scaffold.dart` - Scaffold with side navigation

### Utilities:
- `frontend/lib/utils/validators.dart` - Input validation functions

### Localization:
- `frontend/lib/l10n/app_localizations.dart` - Localized strings

---

**Last Updated**: December 17, 2025
**Document Version**: 1.0
