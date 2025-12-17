// screens/CitizenAuth/citizen_login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/auth_provider.dart' as custom_auth;
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CitizenLoginScreen extends StatefulWidget {
  const CitizenLoginScreen({super.key});

  @override
  State<CitizenLoginScreen> createState() => _CitizenLoginScreenState();
}

class _CitizenLoginScreenState extends State<CitizenLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  static const Color orange = Color(0xFFFC633C);

  Future<void> _login() async {
    final localizations = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider =
          Provider.of<custom_auth.AuthProvider>(context, listen: false);
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final selectedUserType = args?['userType'] as String? ?? 'citizen';

      final userCredential = await authProvider.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final uid = userCredential!.user!.uid;

      // Check profile exists in Firestore and get user role
      // FIXED: search by 'uid' field instead of document ID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User not registered")),
          );
        }
        return;
      }

      final docSnapshot = querySnapshot.docs.first;

      // Get the user's role from the database
      final userRole = docSnapshot.data()['role'] as String? ?? 'citizen';

      // Validate that the user is logging in with the correct role
      if (userRole != selectedUserType) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "You are registered as a $userRole, but trying to login as a $selectedUserType. Please select the correct option."),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Wait for profile to fully load from Firestore
      await authProvider.loadUserProfile(uid);

      // Route based on user role
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(localizations?.loginSuccessful ?? 'Login successful')),
        );

        // Navigate based on role: police/admin goes to different screen
        if (userRole == 'police') {
          context.go('/police-dashboard');
        } else {
          // citizen or other roles go to citizen dashboard
          context.go('/ai-legal-guider');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.message ?? localizations?.loginFailed ?? 'Login failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    final localizations = AppLocalizations.of(context);
    setState(() => _isGoogleLoading = true);
    try {
      final authProvider =
          Provider.of<custom_auth.AuthProvider>(context, listen: false);
      final userCredential = await authProvider.signInWithGoogle();

      if (userCredential != null) {
        final uid = userCredential.user!.uid;
        final email = userCredential.user!.email!;
        final displayName = userCredential.user!.displayName ?? 'User';
        final phoneNumber = userCredential.user!.phoneNumber;

        // Check if profile exists
        // FIXED: search by 'uid' field instead of document ID
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          // Create profile if it doesn't exist (this creates the custom ID)
          await authProvider.createUserProfile(
            uid: uid,
            email: email,
            displayName: displayName,
            phoneNumber: phoneNumber,
            role: 'citizen',
          );
        }

        // Always load the profile (now it exists)
        await authProvider.loadUserProfile(uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(localizations?.googleLoginSuccessful ??
                    'Google login successful')),
          );
          context.go('/ai-legal-guider');
        }
      }
    } catch (e) {
      // ... error handling
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // TOP LOGO + SVG
          Container(
            height: screenHeight * 0.3,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  'assets/Frame.svg',
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: screenHeight * 0.3,
                ),
                // Back button positioned on top-left of the header SVG
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () async {
                        // Try to pop the Navigator stack first. If there's nothing to pop
                        // (for example this page was reached with a replacement navigation),
                        // fall back to navigating to a safe default route ('/').
                        final popped = await Navigator.of(context).maybePop();
                        if (!popped) {
                          // Use GoRouter to navigate to a fallback route.
                          // Adjust '/' to another route if you prefer a different fallback.
                          if (mounted) context.go('/');
                        }
                      },
                      tooltip: 'Back',
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/police_logo.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // FORM

          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // ✅ Stops extra scroll
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ), // ✅ REMOVED keyboard bottom padding
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      localizations?.login ?? 'Login',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // EMAIL
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                          localizations?.email ?? 'Email', Icons.email),
                      validator: (v) => v!.isEmpty || !v.contains('@')
                          ? localizations?.pleaseEnterValidEmail ??
                              'Enter valid email'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // PASSWORD
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: _inputDecoration(
                              localizations?.password ?? 'Password', Icons.lock)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed: () =>
                              setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                      validator: (v) => v!.isEmpty
                          ? localizations?.enterPassword ?? 'Enter password'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(localizations?.forgotPassword ??
                                  'Forgot Password?')),
                        ),
                        child: Text(
                          localizations?.forgotPassword ?? 'Forget Password?',
                          style: const TextStyle(
                            color: orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                localizations?.login ?? 'Login',
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // REGISTER + PHONE
                    Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              localizations?.dontHaveAccount ??
                                  "Don't have an account? ",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/signup'),
                              child: Text(
                                localizations?.register ?? 'Register',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w600),
                              children: [
                                const TextSpan(
                                  text: "Login with",
                                  style: TextStyle(color: Colors.black),
                                ),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => context.go('/phone-login'),
                                    child: Text(
                                      localizations?.phoneNumber ??
                                          'Phone Number',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: orange,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
          fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: Colors.black),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
