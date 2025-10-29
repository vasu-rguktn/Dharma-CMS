# Next.js to Flutter Migration Report

**Project**: Dharma (Legal & Law Enforcement AI Assistant)  
**Migration Date**: 2025-10-22  
**Source**: Next.js 15 + React 18 + TypeScript  
**Target**: Flutter 3.x + Dart

## Executive Summary

This document outlines the complete migration from the Next.js web application to a native Flutter mobile/desktop application. The Flutter app replicates core functionality, UI patterns, routing, authentication, and data management while adapting to Flutter's widget-based architecture.

---

## ✅ Successfully Migrated Features

### 1. Authentication & User Management
- **Next.js**: Firebase Auth with `getAuth()`, `signInWithEmailAndPassword()`, `GoogleAuthProvider`
- **Flutter**: `FirebaseAuth`, `GoogleSignIn` package with identical flow
- **Status**: ✅ **Complete** - All auth methods replicated including Google Sign-In

### 2. Routing & Navigation
- **Next.js**: App Router with dynamic routes (`pages/cases/[id]`)
- **Flutter**: `go_router` with named and parameterized routes (`/cases/:id`)
- **Status**: ✅ **Complete** - All routes mapped, auth guards implemented

### 3. State Management
- **Next.js**: React hooks (`useState`, `useEffect`), Context API, TanStack Query
- **Flutter**: `Provider` for global state (`AuthProvider`, `CaseProvider`, `ComplaintProvider`)
- **Status**: ✅ **Complete** - Equivalent state management with ChangeNotifier pattern

### 4. Firebase Integration
- **Next.js**: Firebase SDK (auth, firestore, storage)
- **Flutter**: FlutterFire packages (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`)
- **Status**: ✅ **Complete** - All Firebase services configured

### 5. Data Models & Types
- **Next.js**: TypeScript interfaces (`CaseDoc`, `UserProfile`, `SavedComplaint`, etc.)
- **Flutter**: Dart classes with factories for Firestore serialization
- **Status**: ✅ **Complete** - All TypeScript types converted to Dart models

### 6. UI Theme & Styling
- **Next.js**: Tailwind CSS with CSS variables for theming
- **Flutter**: `ThemeData` with custom color schemes matching Tailwind config
- **Status**: ✅ **Complete** - Light/dark themes replicated with PT Sans font

### 7. Screens & Pages

| Next.js Route | Flutter Route | Status |
|--------------|---------------|--------|
| `/` (redirect) | `/` (SplashScreen) | ✅ Complete |
| `/login` | `/login` | ✅ Complete |
| `/signup` | `/signup` | ✅ Complete |
| `/dashboard` | `/dashboard` | ⚠️ Placeholder (charts pending) |
| `/cases` | `/cases` | ⚠️ Placeholder |
| `/cases/[id]` | `/cases/:id` | ⚠️ Placeholder |
| `/cases/new` | `/cases/new` | ⚠️ Placeholder |
| `/complaints` | `/complaints` | ⚠️ Placeholder |
| `/chat` | `/chat` | ⚠️ Placeholder |
| `/legal-queries` | `/legal-queries` | ⚠️ Placeholder |
| `/settings` | `/settings` | ⚠️ Placeholder |

### 8. Layout & Navigation
- **Next.js**: `layout.tsx` with `SidebarNav` component
- **Flutter**: `AppScaffold` widget with `Drawer` (sidebar)
- **Status**: ✅ **Complete** - Responsive drawer navigation with icons

---

## ⚠️ Partial Implementations & Placeholders

### 1. Dashboard Charts & Analytics
- **Next.js**: Uses `recharts` library for bar/pie charts
- **Flutter**: Requires `fl_chart` package (dependency added, implementation pending)
- **Reason**: Complex chart rendering needs custom Flutter widgets
- **Recommendation**: Use `fl_chart` or `syncfusion_flutter_charts` to replicate bar, pie, and line charts

### 2. Forms & Validation
- **Next.js**: `react-hook-form` + `zod` for validation
- **Flutter**: Partially implemented with `Form` + `TextFormField`
- **Recommendation**: Use `flutter_form_builder` + `form_builder_validators` (already in pubspec.yaml)

### 3. AI Chat Interface
- **Next.js**: Custom chat UI with OpenAI/Genkit integration
- **Flutter**: Screen placeholder created
- **Recommendation**: Implement with `ListView.builder` for messages, integrate with backend API using `dio`

### 4. Media Analysis
- **Next.js**: Image upload + AI analysis via Genkit flows
- **Flutter**: Screen placeholder created
- **Recommendation**: Use `image_picker` + `file_picker` packages, call backend API for analysis

---

## ❌ Features Not Migrated / Backend-Dependent

### 1. Server-Side AI Flows (Genkit)
- **Next.js**: Server-side Genkit flows for:
  - FIR autofill (`fir-autofill.ts`)
  - Chargesheet generation (`chargesheet-generation.ts`)
  - Legal query RAG (`queryRAG.ts`)
  - Media analysis (`media-analysis-flow.ts`)
  - Text-to-speech (`generate-tts-flow.ts`)
- **Flutter**: Not directly replicated (requires backend API)
- **Reason**: Genkit is Node.js server-side framework; Flutter apps consume APIs
- **Recommendation**:
  - Keep Next.js backend as API server OR migrate to Firebase Functions/Cloud Run
  - Flutter app makes HTTP requests to these endpoints using `dio`

### 2. Server-Side Rendering (SSR) & `getServerSideProps`
- **Next.js**: Pre-fetches data on server before page load
- **Flutter**: Client-side data fetching only
- **Recommendation**: Use `FutureBuilder` or providers to load data on screen init

### 3. Next.js API Routes (`pages/api/`)
- **Next.js**: Backend API endpoints for:
  - `/api/legal-chat.ts`
  - `/api/speech-to-text.ts`
  - `/api/text-to-speech.ts`
  - `/api/upload-legal-file.ts`
- **Flutter**: Cannot host API routes (client-only app)
- **Recommendation**: Deploy these as Firebase Functions or keep Next.js backend running

### 4. OpenAI Direct Integration
- **Next.js**: Server-side OpenAI API calls
- **Flutter**: Requires backend proxy (never expose API keys client-side)
- **Recommendation**: All AI calls must go through backend API

### 5. File Upload to Firebase Storage
- **Next.js**: Direct upload via `firebase/storage`
- **Flutter**: Partially implemented via `firebase_storage` package
- **Recommendation**: Implement upload with `file_picker` + `firebase_storage.ref().putFile()`

---

## 🔧 Technical Differences & Adaptations

### 1. Component Architecture
| Aspect | Next.js | Flutter |
|--------|---------|---------|
| UI Building | React components (JSX) | Widgets (declarative) |
| Styling | CSS/Tailwind classes | Widget properties, `BoxDecoration` |
| State | Hooks (`useState`, `useEffect`) | `StatefulWidget`, `Provider` |
| Props | Function params | Constructor params |

### 2. Async Operations
- **Next.js**: Promises, `async/await`, `useEffect` for side effects
- **Flutter**: `Future`, `async/await`, `FutureBuilder`, `StreamBuilder`

### 3. Environment Variables
- **Next.js**: `.env.local` with `process.env.NEXT_PUBLIC_*`
- **Flutter**: `.env` file with `flutter_dotenv` package

### 4. Package Management
- **Next.js**: npm/yarn + `package.json`
- **Flutter**: pub + `pubspec.yaml`

---

## 📦 Dependency Mapping

| Next.js Package | Flutter Package | Purpose |
|-----------------|-----------------|---------|
| `firebase` | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` | Firebase services |
| `react-hook-form` | `flutter_form_builder`, `form_builder_validators` | Form handling |
| `zod` | Built-in validators | Schema validation |
| `next/navigation` | `go_router` | Routing |
| `recharts` | `fl_chart` | Charts |
| `lucide-react` | `lucide_icons_flutter` | Icons |
| `date-fns` | `intl` | Date formatting |
| `class-variance-authority` | Custom theme system | Styling variants |
| `tailwindcss` | `ThemeData`, custom widgets | Theming |
| `@tanstack/react-query` | `Provider` pattern | State management |
| `axios` / `fetch` | `dio`, `http` | HTTP requests |

---

## 🎨 UI/UX Parity

### Matched Elements
- ✅ Color scheme (primary: #3F51B5, accent: #5C6BC0, background: #F5F5F5)
- ✅ PT Sans font family
- ✅ Border radius (8px rounded corners)
- ✅ Button styles (elevated, outlined)
- ✅ Input field styling
- ✅ Sidebar navigation with icons
- ✅ AppBar with user menu

### Differences
- ⚠️ **Animations**: Next.js uses `tailwindcss-animate` for accordion, fade-in effects. Flutter requires explicit `AnimatedContainer`, `AnimatedOpacity`, or `animations` package.
- ⚠️ **Shadows**: Tailwind box-shadow vs Flutter `BoxShadow` (slight visual differences)
- ⚠️ **Responsive Layout**: Tailwind breakpoints (`sm:`, `md:`, `lg:`) vs Flutter `LayoutBuilder` or `MediaQuery`

---

## 🧪 Testing

### Next.js Testing
- No explicit tests in provided codebase
- Would use Jest, React Testing Library

### Flutter Testing
- ✅ Basic widget tests created in `test/` folder
- ✅ Tests for: AuthProvider, router navigation, login screen
- **Recommendation**: Add integration tests for critical user flows (login → dashboard → create case)

---

## 🚀 Deployment Considerations

### Web (Next.js)
- Deployed to Vercel, Firebase Hosting, or similar
- Environment variables via platform dashboard

### Flutter App
- **Android**: APK/AAB to Google Play Store
- **iOS**: IPA to Apple App Store
- **Web**: `flutter build web` → host on Firebase Hosting
- **Desktop**: Windows/macOS/Linux executables

### Backend API
- **Option 1**: Keep Next.js backend running on Vercel/Cloud Run
- **Option 2**: Migrate API routes to Firebase Functions
- **Option 3**: Use Cloud Run for containerized backend

---

## 🔐 Security Notes

### Secrets Management
- ✅ `.env` file for Firebase config (NOT committed to repo)
- ✅ `.env.example` provided for reference
- ⚠️ **Never expose API keys** (OpenAI, Firebase service account) in client code
- ✅ Use Firestore security rules for data access control

### Authentication
- ✅ Firebase Auth tokens handled securely by SDK
- ✅ Google Sign-In uses standard OAuth flow
- ⚠️ Implement token refresh logic for long sessions

---

## 📋 Next Steps for Full Parity

### High Priority
1. **Implement Dashboard Charts** using `fl_chart`
   - Case status pie chart
   - Station activity bar chart
   - Officer activity bar chart

2. **Complete Case Management Screens**
   - Cases list with filtering
   - Case detail view with all FIR fields
   - New case form with multi-step wizard

3. **Backend API Integration**
   - Create API service layer (`lib/services/api_service.dart`)
   - Integrate Genkit AI flows via HTTP endpoints
   - Implement error handling and retries

4. **Media Upload & Analysis**
   - Implement image picker
   - Upload to Firebase Storage
   - Display analysis results

### Medium Priority
5. **Offline Support**
   - Use Firestore offline persistence
   - Queue uploads when offline

6. **Advanced Animations**
   - Implement accordion animations
   - Page transition animations
   - Loading state animations

7. **Localization**
   - Add `flutter_localizations`
   - Support English and Hindi (as per Next.js app context)

### Low Priority
8. **Desktop Support**
   - Test and optimize for Windows/macOS/Linux
   - Add desktop-specific navigation (persistent sidebar vs drawer)

9. **Accessibility**
   - Ensure screen reader support
   - Keyboard navigation for desktop

---

## 📸 Screenshots (To Be Added)

*Recommended: Side-by-side screenshots of Next.js vs Flutter for:*
- Login screen
- Dashboard
- Case list screen

---

## 🐛 Known Issues & Limitations

1. **Charts Not Implemented**: Dashboard shows placeholder text instead of analytics charts
2. **AI Features Require Backend**: All AI tools (legal queries, document drafting, etc.) need API integration
3. **No Offline Mode**: App requires internet connection for all features (Firestore offline persistence can be enabled)
4. **No Push Notifications**: Not yet implemented (can add with `firebase_messaging`)
5. **PDF Generation**: Document drafting output is not yet implemented (use `pdf` package)

---

## 🎯 Conclusion

This Flutter migration successfully replicates the **core architecture** and **user authentication** of the Next.js Dharma app. The foundation is production-ready for:
- ✅ User authentication (Email/Password, Google)
- ✅ Firebase integration (Auth, Firestore, Storage)
- ✅ Navigation and routing
- ✅ State management
- ✅ Theme and styling

**To achieve full feature parity**, the main tasks are:
1. Implement chart visualizations
2. Build out all screen UIs (forms, lists, details)
3. Integrate backend API for AI features
4. Add media upload and analysis

**Estimated work remaining**: 40-60 hours for a single developer to reach 100% parity with Next.js app.

---

## 📞 Contact & Support

For questions about this migration or Flutter app, contact:  
**[Your Name/Team]** - [email@example.com]

---

**End of Migration Report**
