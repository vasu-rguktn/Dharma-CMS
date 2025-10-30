// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';

// SCREENS
import 'package:Dharma/screens/login_screen.dart';
import 'package:Dharma/screens/phone_login_screen.dart';
import 'package:Dharma/screens/login_details_screen.dart';
import 'package:Dharma/screens/otp_verification_screen.dart';
import 'package:Dharma/screens/cases_screen.dart';
import 'package:Dharma/screens/case_detail_screen.dart';
import 'package:Dharma/screens/new_case_screen.dart';
import 'package:Dharma/screens/complaints_screen.dart';
import 'package:Dharma/screens/chat_screen.dart';
import 'package:Dharma/screens/legal_queries_screen.dart';
import 'package:Dharma/screens/settings_screen.dart';
import 'package:Dharma/screens/legal_suggestion_screen.dart';
import 'package:Dharma/screens/document_drafting_screen.dart';
import 'package:Dharma/screens/chargesheet_generation_screen.dart';
import 'package:Dharma/screens/chargesheet_vetting_screen.dart';
import 'package:Dharma/screens/witness_preparation_screen.dart';
import 'package:Dharma/screens/media_analysis_screen.dart';
import 'package:Dharma/screens/case_journal_screen.dart';
import 'package:Dharma/screens/petitions_screen.dart';
import 'package:Dharma/widgets/app_scaffold.dart';

// DASHBOARDS
import 'package:Dharma/screens/citizen_dashboard_screen.dart';
import 'package:Dharma/screens/police_dashboard_screen.dart';

// REGISTRATION FLOW
import '../screens/welcome_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/adress_form_screen.dart'; // ← Make sure this is correct

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = auth.isAuthenticated;
      final isLoading = auth.isLoading;

      if (isLoading) return null;

      if (isAuthenticated && state.uri.toString() == '/') {
        return '/dashboard';
      }
      if (!isAuthenticated && state.uri.toString().startsWith('/dashboard')) {
        return '/login';
      }
      return null;
    },
    routes: [
      // ── PUBLIC ROUTES ───────────────────────────────
      GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/phone-login', builder: (_, __) => const PhoneLoginScreen()),
      GoRoute(path: '/otp_verification', builder: (_, __) => const OtpVerificationScreen()),

      // ── REGISTRATION FLOW (STACK PRESERVED) ─────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // This keeps the 3-step form in memory
          return navigationShell;
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/signup',
                builder: (context, state) => const RegisterScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/address',
                builder: (context, state) => const AddressFormScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/login_details',
                builder: (context, state) => const LoginDetailsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── PROTECTED DASHBOARD + FEATURES ─────────────
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final Widget screen = auth.role == 'police'
                  ? const PoliceDashboardScreen()
                  : const CitizenDashboardScreen();
              return NoTransitionPage(child: screen);
            },
          ),
          GoRoute(path: '/cases', builder: (_, __) => const CasesScreen()),
          GoRoute(path: '/cases/new', builder: (_, __) => const NewCaseScreen()),
          GoRoute(
            path: '/cases/:id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return CaseDetailScreen(caseId: id);
            },
          ),
          GoRoute(path: '/complaints', builder: (_, __) => const ComplaintsScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
          GoRoute(path: '/legal-queries', builder: (_, __) => const LegalQueriesScreen()),
          GoRoute(path: '/legal-suggestion', builder: (_, __) => const LegalSuggestionScreen()),
          GoRoute(path: '/document-drafting', builder: (_, __) => const DocumentDraftingScreen()),
          GoRoute(path: '/chargesheet-generation', builder: (_, __) => const ChargesheetGenerationScreen()),
          GoRoute(path: '/chargesheet-vetting', builder: (_, __) => const ChargesheetVettingScreen()),
          GoRoute(path: '/witness-preparation', builder: (_, __) => const WitnessPreparationScreen()),
          GoRoute(path: '/media-analysis', builder: (_, __) => const MediaAnalysisScreen()),
          GoRoute(path: '/case-journal', builder: (_, __) => const CaseJournalScreen()),
          GoRoute(path: '/petitions', builder: (_, __) => const PetitionsScreen()),
          GoRoute(path: '/fir-autofill', builder: (_, __) => const Placeholder()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );
}