import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dharma/providers/auth_provider.dart';

// ── Auth Screens ──
import 'package:dharma/screens/auth/welcome_screen.dart';
import 'package:dharma/screens/auth/phone_login_screen.dart';
import 'package:dharma/screens/auth/email_login_screen.dart';
import 'package:dharma/screens/auth/citizen_registration_screen.dart';
import 'package:dharma/screens/auth/address_form_screen.dart';
import 'package:dharma/screens/onboarding/onboarding_screen.dart';

// ── Main Screens ──
import 'package:dharma/screens/dashboard/dashboard_screen.dart';
import 'package:dharma/screens/ai_chat/ai_legal_chat_screen.dart';
import 'package:dharma/screens/petition/petitions_screen.dart';
import 'package:dharma/screens/petition/create_petition_form.dart';
import 'package:dharma/screens/complaints/complaints_screen.dart';
import 'package:dharma/screens/helpline/helpline_screen.dart';
import 'package:dharma/screens/settings/settings_screen.dart';
import 'package:dharma/screens/settings/profile_screen.dart';
import 'package:dharma/screens/petition/petition_detail_screen.dart';
import 'package:dharma/screens/settings/privacy_policy_screen.dart';

// ── Shell ──
import 'package:dharma/widgets/app_scaffold.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,

    redirect: (context, state) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final path = state.uri.path;

      const publicRoutes = ['/', '/phone-login', '/email-login', '/signup/citizen', '/address', '/onboarding'];
      const protectedRoutes = ['/dashboard', '/ai-legal-chat', '/petitions', '/settings', '/profile', '/complaints', '/helpline'];      if (auth.isLoading || auth.isProfileLoading) {
        if (publicRoutes.contains(path)) return null;
        return '/';
      }
      if (!auth.isAuthenticated && protectedRoutes.any((r) => path.startsWith(r))) {
        return '/';
      }
      return null;
    },

    routes: [
      // ── Public ──
      GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/phone-login', builder: (_, __) => const PhoneLoginScreen()),
      GoRoute(path: '/email-login', builder: (_, __) => const EmailLoginScreen()),
      GoRoute(path: '/signup/citizen', builder: (_, __) => const CitizenRegistrationScreen()),
      GoRoute(path: '/address', builder: (_, state) => AddressFormScreen(extra: state.extra as Map<String, dynamic>?)),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // ── Protected (with AppScaffold shell) ──
      ShellRoute(
        builder: (_, __, child) => AppScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(
            path: '/ai-legal-chat',
            builder: (_, state) => AiLegalChatScreen(initialDraft: state.extra as Map<String, dynamic>?),
          ),
          GoRoute(
            path: '/petitions',
            builder: (_, __) => const PetitionsScreen(),
            routes: [
              GoRoute(path: 'create', builder: (_, state) => CreatePetitionForm(initialData: state.extra as Map<String, dynamic>?)),
              GoRoute(path: ':id', builder: (_, state) => PetitionDetailScreen(petitionId: state.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: '/complaints', builder: (_, __) => const ComplaintsScreen()),
          GoRoute(path: '/helpline', builder: (_, __) => const HelplineScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyScreen()),
        ],
      ),
    ],
  );
}
