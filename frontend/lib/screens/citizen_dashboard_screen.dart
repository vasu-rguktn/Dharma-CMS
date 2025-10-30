// lib/screens/citizen_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'dashboard_body.dart';

class CitizenDashboardScreen extends StatelessWidget {
  const CitizenDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cases = Provider.of<CaseProvider>(context);
    final theme = Theme.of(context);

    return DashboardBody(
      auth: auth,
      cases: cases,
      theme: theme,
      isPolice: false,
    );
  }
}