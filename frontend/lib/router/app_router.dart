import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';

// ───────────────── AUTH SCREENS ─────────────────
import 'package:Dharma/screens/welcome_screen.dart';
import 'package:Dharma/screens/CitizenAuth/citizen_login_screen.dart';
import 'package:Dharma/screens/PoliceAuth/police_login_screen.dart';
import 'package:Dharma/screens/CitizenAuth/citizen_registration_screen.dart';
import 'package:Dharma/screens/PoliceAuth/police_registration_screen.dart';
import 'package:Dharma/screens/CitizenAuth/adress_form_screen.dart';
import 'package:Dharma/screens/phone_login_screen.dart';
import 'package:Dharma/screens/login_details_screen.dart';
import 'package:Dharma/screens/otp_verification_screen.dart';


// ───────────────── DASHBOARDS ─────────────────
import 'package:Dharma/screens/dashboard_screen.dart';
import 'package:Dharma/screens/police_dashboard_screen.dart';


// ───────────────── FEATURES ─────────────────
import 'package:Dharma/screens/cases_screen.dart';
import 'package:Dharma/screens/case_detail_screen.dart';
import 'package:Dharma/screens/new_case_screen.dart';
import 'package:Dharma/screens/complaints_screen.dart';
import 'package:Dharma/screens/chat_screen.dart';
import 'package:Dharma/screens/legal_queries_screen.dart';
import 'package:Dharma/screens/legal_suggestion_screen.dart';
import 'package:Dharma/screens/document_drafting_screen.dart';
import 'package:Dharma/screens/chargesheet_generation_screen.dart';
import 'package:Dharma/screens/chargesheet_vetting_screen.dart';
import 'package:Dharma/screens/witness_preparation_screen.dart';
import 'package:Dharma/screens/media_analysis_screen.dart';
import 'package:Dharma/screens/case_journal_screen.dart';
import 'package:Dharma/screens/settings_screen.dart';
import 'package:Dharma/screens/Helpline_screen.dart';
import 'package:Dharma/screens/Investigation_Guidelines/AI_Investigation_Guidelines.dart';
import 'package:Dharma/screens/image_lab_screen.dart';



// ───────────────── AI ─────────────────
import 'package:Dharma/screens/ai_legal_guider_screen.dart';
import 'package:Dharma/screens/ai_legal_chat_screen.dart';
import 'package:Dharma/screens/ai_chatbot_details_screen.dart';
import 'package:Dharma/screens/cognigible_non_cognigible_separation.dart';
import 'package:Dharma/screens/contact_officer_screen.dart';



// ───────────────── PETITIONS ─────────────────
import 'package:Dharma/screens/petition/petitions_screen.dart';
import 'package:Dharma/screens/police_petitions_screen.dart';
import 'package:Dharma/screens/petition/create_petition_form.dart';



// ───────────────── UI ─────────────────
import 'package:Dharma/widgets/app_scaffold.dart';

// ───────────────── ONBOARDING ─────────────────
import 'package:Dharma/screens/onboarding/onboarding_screen.dart';
import 'package:Dharma/services/onboarding_service.dart';

// ───────────────── ROUTER ─────────────────

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // 🔐 AUTH + ROLE BASED REDIRECT
    redirect: (context, state) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final path = state.uri.path;

      // List of public routes that don't require authentication
      final publicRoutes = [
        '/',
        '/login',
        '/police-login',
        '/phone-login',
        '/signup/citizen',
        '/signup/police',
        '/address',
        '/login_details',
        '/otp_verification',
        '/onboarding', // Onboarding screen
      ];

      // List of routes that require authentication
      final protectedRoutes = [
        '/dashboard',
        '/police-dashboard',
        '/ai-legal-guider',
        '/ai-legal-chat',
        '/cases',
        '/complaints',
        '/chat',
        '/ai-investigation-guidelines',
        '/petitions',
        '/settings',
        '/legal-queries',
        '/legal-suggestion',
        '/witness-preparation',
        '/helpline',
        '/document-drafting',
        '/chargesheet-generation',
        '/chargesheet-vetting',
        '/media-analysis',
        '/case-journal',
        '/ai-chatbot-details',
        '/contact-officer',
        '/cognigible-non-cognigible-separation',
      ];

      // During loading, block access to protected routes
      // This prevents unauthorized access while auth state is being determined
      if (auth.isLoading || auth.isProfileLoading) {
        // Allow public routes during loading
        if (publicRoutes.contains(path) ||
            publicRoutes.any((route) => path.startsWith(route))) {
          return null;
        }
        // Block all protected routes during loading - redirect to login
        return '/login';
      }

      // Logged-in users should not see welcome again
      // UNLESS they explicitly navigated to it (e.g., via back button from login screens)
      // We allow '/' to be shown to authenticated users to fix cross-role navigation issues
      // The Welcome screen itself will handle showing appropriate options
      // Note: Direct navigation to '/' is allowed, auto-redirect removed to fix back button issues

      // Redirect unauthenticated users to login
      if (!auth.isAuthenticated &&
          protectedRoutes.any((route) => path.startsWith(route))) {
        return '/login';
      }

      // ROLE-BASED ROUTE PROTECTION
      if (auth.isAuthenticated) {
        // Check if citizen needs onboarding (first-time user)
        if (auth.role == 'citizen' && path != '/onboarding') {
          // This will be checked asynchronously, so we use a FutureBuilder approach
          // For now, we'll let the dashboard handle showing onboarding
        }

        // Police should never see the citizen AI guider screen
        if (auth.role == 'police' && path == '/ai-legal-guider') {
          return '/police-dashboard';
        }

        // Police-only routes
        final policeOnlyRoutes = [
          '/police-dashboard',
          '/document-drafting',
          '/chargesheet-generation',
          '/chargesheet-vetting',
          '/media-analysis',
          '/case-journal',
          '/cases',
          '/ai-investigation-guidelines',
          '/image-lab',
        ];

        // Citizen-only routes
        final citizenOnlyRoutes = [
          '/dashboard',
          '/ai-legal-guider',
          '/ai-legal-chat',
          '/legal-queries',
          '/legal-suggestion',
          '/witness-preparation',
          '/helpline',
        ];

        // Prevent citizens from accessing police routes
        if (auth.role == 'citizen' &&
            policeOnlyRoutes.any((route) => path.startsWith(route))) {
          return '/ai-legal-chat'; // Redirect to citizen dashboard
        }

        // Prevent police from accessing citizen routes
        if (auth.role == 'police' &&
            citizenOnlyRoutes.any((route) => path.startsWith(route))) {
          return '/police-dashboard'; // Redirect to police dashboard
        }
      }

      return null;
    },

    routes: [
      // ───────────── PUBLIC ROUTES ─────────────

      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomeScreen(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const CitizenLoginScreen(), // citizen login
      ),

      GoRoute(
        path: '/police-login',
        builder: (context, state) => const PoliceLoginScreen(),
      ),

      GoRoute(
        path: '/phone-login',
        builder: (context, state) => const PhoneLoginScreen(),
      ),

      GoRoute(
        path: '/signup/citizen',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/signup/police',
        builder: (context, state) => const PoliceRegistrationScreen(),
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
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ───────────── PROTECTED ROUTES ─────────────

      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          GoRoute(
            path: '/police-dashboard',
            builder: (context, state) => const PoliceDashboardScreen(),
          ),

          // ─── CITIZEN AI & LEGAL SCREENS (Protected, Citizen-only) ───
          GoRoute(
            path: '/ai-legal-guider',
            builder: (context, state) => const AiLegalGuiderScreen(),
          ),

          GoRoute(
            path: '/ai-legal-chat',
            builder: (context, state) => const AiLegalChatScreen(),
          ),

          GoRoute(
            path: '/ai-chatbot-details',
            builder: (context, state) =>
                AiChatbotDetailsScreen.fromRouteSettings(context, state),
          ),
          GoRoute(
            path: '/ai-investigation-guidelines',
            builder: (context, state) {
              // Try to get caseId from query parameters first
              String? caseId = state.uri.queryParameters['caseId'];
              
              // If not in query params, try to get from extra data
              if (caseId == null && state.extra != null) {
                final extraData = state.extra as Map<String, dynamic>?;
                caseId = extraData?['caseId'] as String?;
              }
              
              return AiInvestigationGuidelinesScreen(caseId: caseId);
            },
          ),

          GoRoute(
            path: '/contact-officer',
            builder: (context, state) => const ContactOfficerScreen(),
          ),

          GoRoute(
            path: '/cognigible-non-cognigible-separation',
            builder: (context, state) =>
                CognigibleNonCognigibleSeparationScreen.fromRouteSettings(
                    context, state),
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
            path: '/witness-preparation',
            builder: (context, state) => const WitnessPreparationScreen(),
          ),

          GoRoute(
            path: '/helpline',
            builder: (context, state) => const HelplineScreen(),
          ),

          // ─── POLICE-ONLY SCREENS (Protected, Police-only) ───
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
            path: '/media-analysis',
            builder: (context, state) => const MediaAnalysisScreen(),
          ),

          GoRoute(
            path: '/case-journal',
            builder: (context, state) => const CaseJournalScreen(),
          ),

          GoRoute(
            path: '/image-lab',
            builder: (context, state) => const ImageLabScreen(),
          ),

          // ─── SHARED SCREENS (Both roles) ───

          GoRoute(
            path: '/cases',
            builder: (context, state) => const CasesScreen(),
          ),

          GoRoute(
            path: '/cases/new',
            builder: (context, state) => NewCaseScreen(
              initialData: state.extra as Map<String, dynamic>?,
            ),
          ),

          GoRoute(
            path: '/cases/:id',
            builder: (context, state) =>
                CaseDetailScreen(caseId: state.pathParameters['id']!),
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
            path: '/petitions',
            builder: (context, state) {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              return auth.role == 'police'
                  ? const PolicePetitionsScreen()
                  : const PetitionsScreen();
            },
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => CreatePetitionForm(
                  initialData: state.extra as Map<String, dynamic>?,
                ),
              ),
            ],
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
