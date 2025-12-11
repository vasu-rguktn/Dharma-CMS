import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';

// Screens
import 'package:Dharma/screens/login_screen.dart';
import 'package:Dharma/screens/phone_login_screen.dart';
import 'package:Dharma/screens/login_details_screen.dart';
import 'package:Dharma/screens/otp_verification_screen.dart';
import 'package:Dharma/screens/dashboard_screen.dart';
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
import 'package:Dharma/screens/petition/petitions_screen.dart';
import 'package:Dharma/screens/police_petitions_screen.dart';
import 'package:Dharma/screens/ai_legal_guider_screen.dart';
import 'package:Dharma/screens/ai_legal_chat_screen.dart';
import 'package:Dharma/screens/contact_officer_screen.dart';
import 'package:Dharma/screens/ai_chatbot_details_screen.dart';
import 'package:Dharma/screens/cognigible_non_cognigible_separation.dart';
import 'package:Dharma/widgets/app_scaffold.dart';
import 'package:Dharma/screens/petition/create_petition_form.dart';
import 'package:Dharma/screens/police_dashboard_screen.dart';
import 'package:Dharma/screens/Helpline_screen.dart';

// Relative imports
import '../screens/welcome_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/adress_form_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final isLoading = authProvider.isLoading;

      if (isLoading) return null;

      // Redirect logged-in user from welcome → dashboard
      if (isAuthenticated && state.uri.toString() == '/') {
        return '/ai-legal-guider';
      }

      // Redirect unauthenticated user from protected routes → login
      if (!isAuthenticated && state.uri.toString().startsWith('/dashboard')) {
        return '/login';
      }

      return null;
    },
    routes: [
      // ── Public Routes ──
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/phone-login',
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/address',
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: '/login_details',
        builder: (context, state) => const LoginDetailsScreen(),
      ),
      GoRoute(
        path: '/otp_verification',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: '/ai-legal-guider',
        builder: (context, state) => const AiLegalGuiderScreen(),
      ),
      GoRoute(
        path: '/ai-legal-chat',
        builder: (context, state) => const AiLegalChatScreen(),
      ),
      GoRoute(
        path: '/contact-officer',
        builder: (context, state) => const ContactOfficerScreen(),
      ),
      GoRoute(
        path: '/ai-chatbot-details',
        builder: (context, state) => AiChatbotDetailsScreen.fromRouteSettings(context, state),
      ),
      GoRoute(
        path: '/cognigible-non-cognigible-separation',
        builder: (context, state) => CognigibleNonCognigibleSeparationScreen.fromRouteSettings(context, state),
      ),

      // ── Protected Routes (inside AppScaffold) ──
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/police-dashboard',
            builder: (context, state) => const PoliceDashboardScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/cases',
            builder: (context, state) => const CasesScreen(),
          ),
          GoRoute(
            path: '/cases/new',
            builder: (context, state) => const NewCaseScreen(),
          ),
          GoRoute(
            path: '/cases/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CaseDetailScreen(caseId: id);
            },
          ),
          GoRoute(
            path: '/complaints',
            builder: (context, state) => const ComplaintsScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/legal-queries',
            builder: (context, state) => const LegalQueriesScreen(),
          ),
          GoRoute(
            path: '/legal-suggestion',
            builder: (context, state) => const LegalSuggestionScreen(),
          ),
          GoRoute(
            path: '/document-drafting',
            builder: (context, state) => const DocumentDraftingScreen(),
          ),
          GoRoute(
            path: '/chargesheet-generation',
            builder: (context, state) => const ChargesheetGenerationScreen(),
          ),
          GoRoute(
            path: '/chargesheet-vetting',
            builder: (context, state) => const ChargesheetVettingScreen(),
          ),
          GoRoute(
            path: '/witness-preparation',
            builder: (context, state) => const WitnessPreparationScreen(),
          ),
          GoRoute(
            path: '/media-analysis',
            builder: (context, state) => const MediaAnalysisScreen(),
          ),
          GoRoute(
            path: '/case-journal',
            builder: (context, state) => const CaseJournalScreen(),
          ),
          GoRoute(
            path: '/helpline',
            builder: (context, state) => const HelplineScreen(),
          ),
          GoRoute(
            path: '/petitions',
            builder: (context, state) {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (auth.role == 'police') {
                return const PolicePetitionsScreen();
              }
              return const PetitionsScreen();
            },
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final extra = state.extra;
                  Map<String, dynamic>? petitionData;
                  if (extra is Map) {
                    petitionData = Map<String, dynamic>.from(extra);
                  }
                  return CreatePetitionForm(initialData: petitionData);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/fir-autofill',
            builder: (context, state) => const Placeholder(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}