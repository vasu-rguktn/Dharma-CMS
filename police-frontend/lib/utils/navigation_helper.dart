import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';

/// Helper function to navigate to the appropriate dashboard based on user role
void navigateToDashboard(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  final dashboardRoute = authProvider.role == 'police' 
    ? '/police-dashboard' 
    : '/dashboard';
  
  context.go(dashboardRoute);
}

/// Helper to get the appropriate dashboard route for the current user
String getDashboardRoute(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  return authProvider.role == 'police' 
    ? '/police-dashboard' 
    : '/dashboard';
}
