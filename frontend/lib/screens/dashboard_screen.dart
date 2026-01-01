import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'dashboard_body.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🟢 DashboardScreen initState');
    
    // Fetch petition stats after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🟢 DashboardScreen PostFrameCallback');
      
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final petitionProvider = Provider.of<PetitionProvider>(context, listen: false);
      
      final userId = auth.user?.uid;
      final role = auth.role;
      
      debugPrint('🟢 userId: $userId, role: $role');
      
      if (role == 'police') {
        // Police sees all petitions
        debugPrint('🟢 Fetching GLOBAL petition stats (police)');
        petitionProvider.fetchPetitionStats();
      } else if (userId != null) {
        // Citizen sees only their petitions
        debugPrint('🟢 Fetching USER petition stats for userId: $userId');
        petitionProvider.fetchPetitionStats(userId: userId);
      } else {
        debugPrint('⚠️ Cannot fetch stats - userId is NULL');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final caseProvider = Provider.of<CaseProvider>(context);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async {
        // Use GoRouter's canPop to check navigation history
        if (context.canPop()) {
          context.pop();
          return false; // Prevent default exit, we handled navigation
        }
        return true; // Allow exit only if truly root
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FE),

        // === Floating Chatbot Button with Label ===
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/ai-legal-guider'),
          backgroundColor: const Color(0xFFFC633C),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          icon: const Icon(
            Icons.chat_bubble_outline,
            size: 26,
            color: Colors.white,
          ),
          label: Text(
            localizations.newCase,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        // === Use the modular DashboardBody ===
        // This ensures we respect the role-based logic defined in DashboardBody
        body: DashboardBody(
          auth: authProvider,
          cases: caseProvider,
          theme: theme,
          isPolice: authProvider.role == 'police',
        ),
      ),
    );
  }
}
