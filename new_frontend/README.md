# Dharma CMS — New Frontend (Flutter)

> **Clean, Firebase Auth-only Flutter app** that talks to `new_backend/` (FastAPI + PostgreSQL) for all data.  
> **Zero Firestore dependency** — Firebase is used ONLY for login/OTP.

---

## Architecture

```
┌────────────────────┐     HTTP + Bearer Token     ┌──────────────────────┐     HTTP proxy     ┌─────────────────┐
│   Flutter App      │ ──────────────────────────▶  │  FastAPI Backend     │ ─────────────────▶ │  AI Service     │
│   (new_frontend/)  │                              │  (new_backend/)      │                    │  (old backend)  │
│                    │     Firebase Auth only        │  :8000               │                    │  Cloud Run      │
│   - Provider state │ ◀────────────────────────── │  - Auth verification │                    │  - Gemini AI    │
│   - GoRouter nav   │     JSON responses           │  - PostgreSQL CRUD   │                    │  - OCR / TTS    │
│   - Dio HTTP       │                              │  - AI gateway proxy  │                    │  - PDF gen      │
└────────────────────┘                              └──────────────────────┘                    └─────────────────┘
```

**Key principles:**
1. **Firebase Auth ONLY** — No `cloud_firestore` package. All data via API.
2. **Single URL source** — `lib/config/api_config.dart` is the only place the backend URL is defined.
3. **Auto auth injection** — Every Dio request gets `Authorization: Bearer <token>` via interceptor.
4. **Clean folder structure** — Feature-based screen organization.

---

## Project Structure

```
new_frontend/
├── pubspec.yaml                         # Dependencies (NO cloud_firestore)
├── web/index.html                       # Firebase JS SDKs for web OTP
├── assets/
│   ├── images/                          # police_logo.png, avatar2.png, CM.png, etc.
│   ├── svg/                             # login_design.svg, Frame.svg, DashboardFrame.svg
│   └── data/                            # Dharma_Citizen_Consent.pdf
│
└── lib/
    ├── main.dart                        # App entry: Firebase init, providers, MaterialApp.router
    ├── firebase_options.dart            # Firebase project config (run flutterfire configure)
    │
    ├── config/
    │   ├── api_config.dart              # Single source of truth: backend URL
    │   └── theme.dart                   # Light/dark themes, orange brand color (#FC633C)
    │
    ├── core/
    │   └── api_service.dart             # Centralized Dio client + Firebase Auth interceptor
    │
    ├── models/                          # Plain Dart models (NO Firestore Timestamp)
    │   ├── user_profile.dart            # UserProfile (DateTime, fromJson/toJson/copyWith)
    │   ├── petition.dart                # Petition + PetitionType/PetitionStatus enums
    │   ├── petition_update.dart         # Timeline update model
    │   └── chat_message.dart            # Simple sender/text/timestamp model
    │
    ├── providers/                       # State management (ChangeNotifier + Provider)
    │   ├── auth_provider.dart           # Firebase Auth (OTP, email, Google) + session (3hr)
    │   ├── petition_provider.dart       # Petition CRUD via PetitionsApi
    │   ├── complaint_provider.dart      # Saved complaints + drafts via ComplaintDraftsApi
    │   ├── legal_queries_provider.dart  # AI legal chat sessions
    │   ├── settings_provider.dart       # App language + chat language (SharedPreferences)
    │   └── activity_provider.dart       # Recent activity tracking (SharedPreferences)
    │
    ├── services/api/                    # Backend API layer (all use ApiService.dio)
    │   ├── accounts_api.dart            # /accounts/me, citizen-profile, device-tokens
    │   ├── petitions_api.dart           # /accounts/{uid}/petitions + sub-collections
    │   ├── complaint_drafts_api.dart    # /accounts/{uid}/complaint-drafts + messages
    │   ├── legal_queries_api.dart       # /accounts/{uid}/legal-threads + messages
    │   └── ai_gateway_api.dart          # /ai/* — complaint chat, legal chat, OCR, PDF, FCM
    │
    ├── router/
    │   └── app_router.dart              # GoRouter: public + protected routes with ShellRoute
    │
    ├── screens/
    │   ├── auth/                        # Welcome, Phone Login, Registration, Address
    │   ├── onboarding/                  # 3-page intro with SmoothPageIndicator
    │   ├── dashboard/                   # Stats grid, quick actions, recent activity
    │   ├── ai_chat/                     # Complaint chatbot (5 Qs → dynamic AI chat)
    │   ├── petition/                    # List + Create petition forms
    │   ├── complaints/                  # Saved complaints/drafts
    │   ├── helpline/                    # Emergency numbers (112, 100, etc.)
    │   └── settings/                    # Settings + Edit Profile
    │
    ├── widgets/
    │   └── app_scaffold.dart            # Shell with AppBar, Drawer sidebar, user menu
    │
    ├── utils/
    │   ├── validators.dart              # Email, phone, name, pincode, DOB validation
    │   └── petition_filter.dart         # PetitionFilter enum
    │
    └── l10n/                            # 13 Indian languages + English (14 files)
```

---

## Routing

| Path | Screen | Auth |
|------|--------|:----:|
| `/` | Welcome | ❌ |
| `/phone-login` | Phone OTP Login | ❌ |
| `/signup/citizen` | Registration | ❌ |
| `/address` | Address Form | ❌ |
| `/onboarding` | Onboarding | ❌ |
| `/dashboard` | Dashboard | ✅ |
| `/ai-legal-chat` | AI Chatbot | ✅ |
| `/petitions` | Petitions List | ✅ |
| `/petitions/create` | Create Petition | ✅ |
| `/complaints` | Saved Complaints | ✅ |
| `/helpline` | Helplines | ✅ |
| `/settings` | Settings | ✅ |
| `/profile` | Edit Profile | ✅ |

---

## Data Flow

```
User action → Provider → API Service → ApiService.dio (+ Bearer token)
    → HTTP to new_backend:8000 → FastAPI verifies token → PostgreSQL CRUD
    → JSON response → Provider updates state → UI rebuilds
```

---

## Quick Start

### Prerequisites
- Flutter SDK ≥ 3.11.1
- Chrome browser (for web)
- `new_backend/` running at `http://localhost:8000`

### 1. Install dependencies
```bash
cd new_frontend
flutter pub get
```

### 2. Configure Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=dharma-cms-5cc89
```

### 3. Run
```bash
flutter run -d chrome --web-port 5555
```

---

## Localization

13 Indian languages + English: en, te, hi, ta, kn, ml, mr, gu, bn, pa, ur, or, as

---

## Old vs New Frontend

| Aspect | Old | New |
|--------|-----|-----|
| Data source | Direct Firestore | Backend API (Dio → FastAPI) |
| Backend URLs | Hardcoded in 19+ files | Single `ApiConfig.baseUrl` |
| AI calls | Direct from UI | Proxied through `/ai/*` |
| Firestore dep | `cloud_firestore` | **NONE** |
| Models | Firestore `Timestamp` | Plain `DateTime` + `fromJson` |
| Structure | Flat | Feature-based |
