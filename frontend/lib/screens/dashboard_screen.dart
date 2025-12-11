import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'dashboard_body.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final caseProvider = Provider.of<CaseProvider>(context);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
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
    );
  }
}
