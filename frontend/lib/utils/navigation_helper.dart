import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';

/// CITIZEN-ONLY APP: Always navigate to citizen dashboard
void navigateToDashboard(BuildContext context) {
  context.go('/dashboard');
}

/// CITIZEN-ONLY APP: Always return citizen dashboard route
String getDashboardRoute(BuildContext context) {
  return '/dashboard';
}
