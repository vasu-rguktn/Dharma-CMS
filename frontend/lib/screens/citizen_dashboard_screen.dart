// lib/screens/citizen_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'dashboard_body.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🟢 CitizenDashboardScreen initState');
    
    // Fetch Citizen petition stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🟢 PostFrameCallback executing');
      
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final petitionProvider =
          Provider.of<PetitionProvider>(context, listen: false);
      
      final userId = auth.user?.uid;
      debugPrint('🟢 auth.user?.uid = $userId');
      debugPrint('🟢 auth.userProfile?.uid = ${auth.userProfile?.uid}');
      
      if (userId != null) {
        debugPrint('🟢 Calling fetchPetitionStats with userId: $userId');
        petitionProvider.fetchPetitionStats(userId: userId);
      } else {
        debugPrint('⚠️ Cannot fetch stats - userId is NULL!');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cases = Provider.of<CaseProvider>(context);
    final theme = Theme.of(context);

    // Also try to fetch if not fetched yet or user changed (handled in auth provider usually but safe to check)
    // Actually initState is enough for this screen lifecycle.

    return DashboardBody(
      auth: auth,
      cases: cases,
      theme: theme,
      isPolice: false,
    );
  }
}