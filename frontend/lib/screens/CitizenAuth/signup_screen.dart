import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  bool _prefilledFromArgs = false;
  Map<String, dynamic>? _incomingPersonal;
  Map<String, dynamic>? _incomingAddress;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final credential = await authProvider.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (credential != null) {
        // Get the user type from route extra to determine role
        final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
        final userType = args?['userType'] as String? ?? 'citizen';
        
        await authProvider.createUserProfile(
          uid: credential.user!.uid,
          email: _emailController.text.trim(),
          displayName: _displayNameController.text.trim(),
          role: userType, // Set role based on registration type
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        // After signup you typically go to dashboard. We keep that behavior.
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Capture any incoming data passed via navigation `extra` so we can
    // prefill fields and forward when navigating back to previous step.
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final personal = args?['personal'] as Map<String, dynamic>?;
    final address = args?['address'] as Map<String, dynamic>?;
    
    // Always update controllers and stored extras from route data.
    // This ensures that when navigating back and forth, the latest
    // incoming data is reflected in the UI.
    if (personal != null) {
      _displayNameController.text = personal['name'] ?? '';
      _emailController.text = personal['email'] ?? '';
      _incomingPersonal = personal;
    }
    if (address != null) {
      _incomingAddress = address;
    }
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.balance, size: 64, color: Theme.of(context).primaryColor),
                      const SizedBox(height: 16),
                      Text('Create Account', style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                        validator: (v) => v == null || v.isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || !v.contains('@') ? 'Please enter a valid email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                        obscureText: true,
                        validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                try {
                                  final personalData = {
                                    'name': _displayNameController.text.trim(),
                                    'email': _emailController.text.trim(),
                                  };
                                  // forward the latest address (if any)
                                  context.go('/address', extra: {
                                    'personal': personalData,
                                    if (_incomingAddress != null) 'address': _incomingAddress,
                                  });
                                } catch (e) {
                                  // debugPrint('Navigation error: $e');
                                }
                              },
                              child: const Text('Previous'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignup,
                              child: _isLoading ? const CircularProgressIndicator() : const Text('Sign Up'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          TextButton(onPressed: () => context.go('/login'), child: const Text('Log in')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
