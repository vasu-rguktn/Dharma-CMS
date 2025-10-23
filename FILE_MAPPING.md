# Dharma Flutter - File Mapping

This document maps the Next.js source files to their Flutter equivalents.

## Configuration Files

| Next.js | Flutter | Notes |
|---------|---------|-------|
| `package.json` | `pubspec.yaml` | Dependencies and project metadata |
| `next.config.ts` | N/A | Next.js specific config not needed |
| `tailwind.config.ts` | `lib/config/theme.dart` | Theme converted to ThemeData |
| `tsconfig.json` | `analysis_options.yaml` | Dart analysis config |
| `.env.local` | `.env` | Environment variables |

## Core Application

| Next.js | Flutter |
|---------|---------|
| `src/app/layout.tsx` | `lib/main.dart` |
| `src/app/page.tsx` | `lib/screens/splash_screen.dart` |
| `src/app/globals.css` | `lib/config/theme.dart` |

## Authentication

| Next.js | Flutter |
|---------|---------|
| `src/app/(auth)/login/page.tsx` | `lib/screens/login_screen.dart` |
| `src/app/(auth)/signup/page.tsx` | `lib/screens/signup_screen.dart` |
| `src/contexts/AuthContext.tsx` | `lib/providers/auth_provider.dart` |
| `src/hooks/useAuth.ts` | Provider.of<AuthProvider>(context) |

## Firebase

| Next.js | Flutter |
|---------|---------|
| `src/lib/firebase.ts` | `lib/firebase_options.dart` |
| Firebase SDK imports | FlutterFire packages in pubspec.yaml |

## Models/Types

| Next.js | Flutter |
|---------|---------|
| `src/types/index.ts` (CaseStatus enum) | `lib/models/case_status.dart` |
| `src/types/index.ts` (UserProfile) | `lib/models/user_profile.dart` |
| `src/types/index.ts` (CaseDoc) | `lib/models/case_doc.dart` |
| `src/types/index.ts` (SavedComplaint) | Models embedded in ComplaintProvider |

## Screens

| Next.js | Flutter |
|---------|---------|
| `src/app/(app)/dashboard/page.tsx` | `lib/screens/dashboard_screen.dart` |
| `src/app/(app)/cases/page.tsx` | `lib/screens/cases_screen.dart` |
| `src/app/(app)/cases/[caseId]/page.tsx` | `lib/screens/case_detail_screen.dart` |
| `src/app/(app)/cases/new/page.tsx` | `lib/screens/new_case_screen.dart` |
| `src/app/(app)/complaints/page.tsx` | `lib/screens/complaints_screen.dart` |
| `src/app/(app)/chat/page.tsx` | `lib/screens/chat_screen.dart` |
| `src/app/(app)/legal-queries/page.tsx` | `lib/screens/legal_queries_screen.dart` |
| `src/app/(app)/settings/page.tsx` | `lib/screens/settings_screen.dart` |

## Layout Components

| Next.js | Flutter |
|---------|---------|
| `src/app/(app)/layout.tsx` | `lib/widgets/app_scaffold.dart` |
| `src/components/layout/SidebarNav.tsx` | Drawer in AppScaffold |
| `src/components/layout/Header.tsx` | AppBar in AppScaffold |
| `src/components/Logo.tsx` | Icon widget in AppScaffold |
| `src/components/UserNav.tsx` | PopupMenuButton in AppScaffold |
| `src/components/AuthGuard.tsx` | GoRouter redirect logic |

## UI Components (Radix UI → Flutter Widgets)

| Next.js (Radix UI) | Flutter |
|-------------------|---------|
| `src/components/ui/button.tsx` | ElevatedButton, OutlinedButton |
| `src/components/ui/input.tsx` | TextField, TextFormField |
| `src/components/ui/card.tsx` | Card widget |
| `src/components/ui/dialog.tsx` | showDialog(), AlertDialog |
| `src/components/ui/dropdown-menu.tsx` | DropdownButton, PopupMenuButton |
| `src/components/ui/form.tsx` | Form, FormField |
| `src/components/ui/label.tsx` | Text or InputDecoration.labelText |
| `src/components/ui/tabs.tsx` | TabBar, TabBarView |
| `src/components/ui/toast.tsx` | ScaffoldMessenger.showSnackBar |
| `src/components/ui/progress.tsx` | LinearProgressIndicator |
| `src/components/ui/select.tsx` | DropdownButtonFormField |
| `src/components/ui/checkbox.tsx` | Checkbox |
| `src/components/ui/switch.tsx` | Switch |
| `src/components/ui/slider.tsx` | Slider |
| `src/components/ui/separator.tsx` | Divider |
| `src/components/ui/skeleton.tsx` | shimmer package |
| `src/components/ui/scroll-area.tsx` | SingleChildScrollView, ListView |
| `src/components/ui/sidebar.tsx` | Drawer |

## State Management

| Next.js | Flutter |
|---------|---------|
| React Context API | Provider package |
| `useState` hook | StatefulWidget with setState() |
| `useEffect` hook | initState(), dispose() |
| TanStack Query | Provider with ChangeNotifier |

## Routing

| Next.js | Flutter |
|---------|---------|
| App Router (file-based) | GoRouter (declarative) |
| `useRouter()` hook | `context.go()`, `context.push()` |
| `usePathname()` | `GoRouterState.of(context).uri.path` |
| `Link` component | GestureDetector + context.go() |
| Dynamic routes `[id]` | Path parameters `:id` |

## API Integration (Server-side not migrated)

| Next.js | Flutter (Client-side only) |
|---------|----------------------------|
| `src/pages/api/legal-chat.ts` | HTTP request via dio to backend |
| `src/pages/api/speech-to-text.ts` | HTTP request to backend |
| `src/pages/api/text-to-speech.ts` | HTTP request to backend |
| `src/ai/flows/*.ts` (Genkit) | Backend API calls (not in client) |

## Utilities

| Next.js | Flutter |
|---------|---------|
| `src/lib/utils.ts` (cn function) | Custom widget composition |
| `src/hooks/use-toast.ts` | ScaffoldMessenger |
| `src/hooks/use-mobile.tsx` | MediaQuery.of(context).size.width |

## Charts

| Next.js | Flutter |
|---------|---------|
| `recharts` (BarChart, PieChart) | `fl_chart` (BarChart, PieChart) |

## Icons

| Next.js | Flutter |
|---------|---------|
| `lucide-react` | `lucide_icons_flutter` |

## Data Providers

| Next.js | Flutter |
|---------|---------|
| Firestore queries in components | CaseProvider, ComplaintProvider |
| `collection()`, `getDocs()` | Same API in cloud_firestore |

## Not Migrated (Backend-only)

- `src/ai/dev.ts` - Genkit dev server
- `src/ai/genkit.ts` - Genkit config
- `src/ai/flows/*.ts` - All AI flows (remain on backend)
- `src/ai/prompts/*.ts` - AI prompts (remain on backend)
- All API routes in `src/pages/api/`

---

**Total Files Created**: 30+ Flutter files  
**Migration Coverage**: ~70% (UI/UX and architecture complete, feature implementations pending)
