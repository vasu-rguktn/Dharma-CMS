import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dharma_police/providers/auth_provider.dart';

// ── Auth ──
import 'package:dharma_police/screens/auth/welcome_screen.dart';
import 'package:dharma_police/screens/auth/police_login_screen.dart';
import 'package:dharma_police/screens/auth/police_registration_screen.dart';

// ── Main ──
import 'package:dharma_police/screens/dashboard/police_dashboard_screen.dart';
import 'package:dharma_police/screens/cases/cases_screen.dart';
import 'package:dharma_police/screens/cases/case_detail_screen.dart';
import 'package:dharma_police/screens/cases/new_case_screen.dart';
import 'package:dharma_police/screens/petitions/police_petitions_screen.dart';
import 'package:dharma_police/screens/ai_tools/document_drafting_screen.dart';
import 'package:dharma_police/screens/ai_tools/chargesheet_screen.dart';
import 'package:dharma_police/screens/ai_tools/chargesheet_vetting_screen.dart';
import 'package:dharma_police/screens/ai_tools/investigation_screen.dart';
import 'package:dharma_police/screens/ai_tools/media_analysis_screen.dart';
import 'package:dharma_police/screens/ai_tools/legal_chat_screen.dart';
import 'package:dharma_police/screens/settings/police_settings_screen.dart';
import 'package:dharma_police/screens/settings/profile_screen.dart';
import 'package:dharma_police/screens/settings/privacy_policy_screen.dart';

// ── Shell ──
import 'package:dharma_police/widgets/app_scaffold.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,

    redirect: (context, state) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final path = state.uri.path;

      const publicRoutes = ['/', '/login', '/register'];
      const protectedPrefixes = ['/dashboard', '/cases', '/petitions', '/document-drafting', '/chargesheet', '/investigation', '/media-analysis', '/chat', '/settings', '/profile'];

      if (auth.isLoading || auth.isProfileLoading) {
        if (publicRoutes.contains(path)) return null;
        return '/';
      }
      if (!auth.isAuthenticated && protectedPrefixes.any((r) => path.startsWith(r))) {
        return '/';
      }
      return null;
    },

    routes: [
      // ── Public ──
      GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const PoliceLoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const PoliceRegistrationScreen()),

      // ── Protected (with AppScaffold shell) ──
      ShellRoute(
        builder: (_, __, child) => AppScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const PoliceDashboardScreen()),
          GoRoute(path: '/cases', builder: (_, __) => const CasesScreen()),
          GoRoute(path: '/cases/new', builder: (_, __) => const NewCaseScreen()),
          GoRoute(path: '/cases/:id', builder: (_, state) => CaseDetailScreen(caseId: state.pathParameters['id']!)),
          GoRoute(path: '/petitions', builder: (_, __) => const PolicePetitionsScreen()),
          GoRoute(path: '/document-drafting', builder: (_, __) => const DocumentDraftingScreen()),
          GoRoute(path: '/chargesheet', builder: (_, __) => const ChargesheetScreen()),
          GoRoute(path: '/chargesheet-vetting', builder: (_, __) => const ChargesheetVettingScreen()),
          GoRoute(path: '/investigation', builder: (_, state) => InvestigationScreen(extra: state.extra as Map<String, dynamic>?)),
          GoRoute(path: '/media-analysis', builder: (_, __) => const MediaAnalysisScreen()),
          GoRoute(path: '/chat', builder: (_, __) => const LegalChatScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/privacy-policy', builder: (_, __) => const PrivacyPolicyScreen()),
        ],
      ),
    ],
  );
}
