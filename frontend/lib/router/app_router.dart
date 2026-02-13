import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/models/case_doc.dart';
import 'package:Dharma/models/petition.dart';

// ───────────────── AUTH SCREENS ─────────────────
import 'package:Dharma/screens/welcome_screen.dart';
import 'package:Dharma/screens/CitizenAuth/citizen_login_screen.dart';
import 'package:Dharma/screens/CitizenAuth/citizen_registration_screen.dart';
import 'package:Dharma/screens/CitizenAuth/adress_form_screen.dart';
import 'package:Dharma/screens/phone_login_screen.dart';
import 'package:Dharma/screens/login_details_screen.dart';
import 'package:Dharma/screens/otp_verification_screen.dart';

// ───────────────── DASHBOARDS ─────────────────
import 'package:Dharma/screens/dashboard_screen.dart';

// ───────────────── FEATURES ─────────────────
import 'package:Dharma/screens/complaints_screen.dart';
import 'package:Dharma/screens/chat_screen.dart';
import 'package:Dharma/screens/legal_queries_screen.dart';
import 'package:Dharma/screens/legal_suggestion_screen.dart';
import 'package:Dharma/screens/witness_preparation_screen.dart';
import 'package:Dharma/screens/settings_screen.dart';
import 'package:Dharma/screens/Helpline_screen.dart';
import 'package:Dharma/screens/profile_screen.dart';

// ───────────────── AI ─────────────────
import 'package:Dharma/screens/ai_legal_guider_screen.dart';
import 'package:Dharma/screens/ai_legal_chat_screen.dart';
import 'package:Dharma/screens/ai_chatbot_details_screen.dart';
import 'package:Dharma/screens/cognigible_non_cognigible_separation.dart';
import 'package:Dharma/screens/contact_officer_screen.dart';

// ───────────────── PETITIONS ─────────────────
import 'package:Dharma/screens/petition/petitions_screen.dart';
import 'package:Dharma/screens/petition/create_petition_form.dart';

// ───────────────── UI ─────────────────
import 'package:Dharma/widgets/app_scaffold.dart';

// ───────────────── ONBOARDING ─────────────────
import 'package:Dharma/screens/onboarding/onboarding_screen.dart';
import 'package:Dharma/services/onboarding_service.dart';
import 'package:Dharma/screens/consent_pdf_viewer.dart';
import 'package:Dharma/screens/privacy_policy_screen.dart';

// ───────────────── ROUTER ─────────────────

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // 🔐 CITIZEN-ONLY APP
    redirect: (context, state) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final path = state.uri.path;

      // List of public routes that don't require authentication
      final publicRoutes = [
        '/',
        '/login',
        '/phone-login',
        '/signup/citizen',
        '/address',
        '/login_details',
        '/otp_verification',
        '/onboarding',
        '/privacy',
        '/terms',
      ];

      // Citizen routes that require authentication
      final protectedCitizenRoutes = [
        '/dashboard',
        '/ai-legal-guider',
        '/ai-legal-chat',
        '/petitions',
        '/settings',
        '/profile',
        '/legal-queries',
        '/legal-suggestion',
        '/witness-preparation',
        '/helpline',
        '/complaints',
        '/chat',
        '/ai-chatbot-details',
        '/contact-officer',
        '/cognigible-non-cognigible-separation',
      ];

      // During loading, block access to protected routes
      if (auth.isLoading || auth.isProfileLoading) {
        if (publicRoutes.contains(path) ||
            publicRoutes.any((route) => path.startsWith(route))) {
          return null;
        }
        return '/phone-login';
      }

      // Redirect unauthenticated users to login
      if (!auth.isAuthenticated &&
          protectedCitizenRoutes.any((route) => path.startsWith(route))) {
        return '/phone-login';
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
        path: '/phone-login',
        builder: (context, state) => const PhoneLoginScreen(),
      ),

      GoRoute(
        path: '/signup/citizen',
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
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),

      GoRoute(
        path: '/terms',
        builder: (context, state) => const ConsentPdfViewer(
          assetPath: 'assets/Data/Dharma_Citizen_Consent.pdf',
          title: 'Terms of Service',
        ),
      ),

      // ───────────── PROTECTED ROUTES ─────────────

      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // ─── CITIZEN AI & LEGAL SCREENS (Protected, Citizen-only) ───
          GoRoute(
            path: '/ai-legal-guider',
            builder: (context, state) => const AiLegalGuiderScreen(),
          ),

          GoRoute(
            path: '/ai-legal-chat',
            builder: (context, state) => AiLegalChatScreen(
              initialDraft: state.extra as Map<String, dynamic>?,
            ),
          ),

          GoRoute(
            path: '/ai-chatbot-details',
            builder: (context, state) =>
                AiChatbotDetailsScreen.fromRouteSettings(context, state),
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

          // ─── SHARED SCREENS ───

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
            builder: (context, state) => const PetitionsScreen(),
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

          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
