// screens/CitizenAuth/citizen_login_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/auth_provider.dart' as custom_auth;
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/services/onboarding_service.dart';
import 'package:Dharma/screens/consent_pdf_viewer.dart';

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
  bool _isConsentAccepted = false;
  Timer? _delayedNavigationTimer;

  static const Color orange = Color(0xFFFC633C);

  Future<void> _login() async {
    final localizations = AppLocalizations.of(context);
    if (!_isConsentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please accept the Terms & Conditions')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider =
          Provider.of<custom_auth.AuthProvider>(context, listen: false);
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      // CITIZEN-ONLY APP: Always force citizen role
      final selectedUserType = 'citizen';

      final userCredential = await authProvider.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final uid = userCredential!.user!.uid;

      // Check profile exists in Firestore
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

      // CITIZEN-ONLY APP: Skip role validation, always proceed as citizen

      // Wait for profile to fully load from Firestore
      await authProvider.loadUserProfile(uid);

      // CITIZEN-ONLY APP: Always route to citizen dashboard
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(localizations?.loginSuccessful ?? 'Login successful')),
        );

        // Go to dashboard first
        context.go('/dashboard');
        
        // Check if onboarding is needed
        final showOnboarding = await OnboardingService.shouldShowOnboarding();
        
        // Only push AI chat if onboarding is NOT needed (returning user)
        if (!showOnboarding) {
          // Wait a moment for dashboard to load, then push to AI chat
          _delayedNavigationTimer = Timer(const Duration(milliseconds: 50), () {
            if (mounted) {
              context.push('/ai-legal-chat');
            }
          });
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

  Future<void> _handleForgotPassword() async {
    final localizations = AppLocalizations.of(context);
    final resetEmailController = TextEditingController(text: _emailController.text);
    // Capture the parent context safely to use after the dialog closes
    final parentContext = context;

    await showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localizations?.forgotPassword ?? 'Forgot Password?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address to receive a password reset link.',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: localizations?.email ?? 'Email',
                hintText: 'example@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              localizations?.cancel ?? 'Cancel',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(localizations?.pleaseEnterEmail ?? 'Please enter your email'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Close the input dialog
              Navigator.pop(dialogContext);

              setState(() => _isLoading = true);
              
              try {
                // Use the parentContext for the provider, as dialogContext is now unmounted
                final authProvider =
                    Provider.of<custom_auth.AuthProvider>(parentContext, listen: false);

                // Check if the user is registered in the database first
                final userQuery = await FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: email)
                    .limit(1)
                    .get();

                if (userQuery.docs.isEmpty) {
                  if (mounted) {
                    await showDialog(
                      context: parentContext,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text(
                          'Not Registered',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          'The email $email is not registered with us.',
                          style: const TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                  color: orange, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return;
                }

                await authProvider.sendPasswordResetEmail(email);

                if (mounted) {
                   await showDialog(
                    context: parentContext,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: const Text(
                        'Email Sent',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'A password reset link has been sent to $email. Please check your inbox.',
                        style: const TextStyle(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'OK',
                            style: TextStyle(
                                color: orange, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  // Specific handling for user-not-found
                  if (e.code == 'user-not-found') {
                    await showDialog(
                      context: parentContext,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text(
                          'Not Registered',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          'The email $email is not registered with us.',
                          style: const TextStyle(fontSize: 16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                  color: orange, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Show error dialog for other auth errors
                    await showDialog(
                      context: parentContext,
                      builder: (context) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(e.message ?? 'An login error occurred'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                   // Show error dialog for generic errors
                   await showDialog(
                      context: parentContext,
                      builder: (context) => AlertDialog(
                        title: const Text('Error'),
                        content: Text('Failed to send email: $e'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                      ),
                    );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send Reset Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    resetEmailController.dispose();
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
          // Go to dashboard first
          context.go('/dashboard');
          
          // Check if onboarding is needed
          final showOnboarding = await OnboardingService.shouldShowOnboarding();
          
          // Only push AI chat if onboarding is NOT needed (returning user)
          if (!showOnboarding) {
            // Wait a moment for dashboard to load, then push to AI chat
            _delayedNavigationTimer = Timer(const Duration(milliseconds: 50), () {
              if (mounted) {
                context.push('/ai-legal-chat');
              }
            });
          }
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          // TOP LOGO + SVG
          Container(
            height: screenHeight * 0.3,
            width: screenWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: screenWidth,
                  height: screenHeight * 0.3,
                  child: SvgPicture.asset(
                    'assets/Frame.svg',
                    fit: BoxFit.fill,
                    width: screenWidth,
                    height: screenHeight * 0.3,
                  ),
                ),
                // Back button positioned on top-left of the header SVG
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          // Always navigate to Welcome screen to avoid cross-role redirections
                          context.go('/');
                        },
                        tooltip: 'Back',
                      ),
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
                        onTap: _handleForgotPassword,
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
                    // Consent Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _isConsentAccepted,
                          activeColor: const Color(0xFFFC633C),
                          onChanged: (val) {
                            setState(() => _isConsentAccepted = val ?? false);
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Open PDF Viewer
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ConsentPdfViewer(
                                    assetPath: 'assets/data/Dharma_Citizen_Consent.pdf',
                                    title: 'Terms & Conditions',
                                  ),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: const TextStyle(color: Colors.black, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: const TextStyle(
                                      color: Color(0xFFFC633C),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                              onTap: () => context.go('/signup/citizen'),
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
    _delayedNavigationTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
