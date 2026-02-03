import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/police_auth_provider.dart';

/// Widget that observes app lifecycle and updates session activity
/// This keeps the user's session alive while they're using the app
class SessionLifecycleObserver extends StatefulWidget {
  final Widget child;

  const SessionLifecycleObserver({super.key, required this.child});

  @override
  State<SessionLifecycleObserver> createState() => _SessionLifecycleObserverState();
}

class _SessionLifecycleObserverState extends State<SessionLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Update activity on app start
    _updateActivity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Update last activity when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _updateActivity();
    }
  }

  void _updateActivity() {
    // Update activity for both auth providers if user is authenticated
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final policeAuthProvider = Provider.of<PoliceAuthProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      authProvider.updateLastActivity();
    }
    
    if (policeAuthProvider.policeProfile != null) {
      policeAuthProvider.updateLastActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

