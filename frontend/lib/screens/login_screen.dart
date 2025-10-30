// screens/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/auth_provider.dart' as custom_auth;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  static const Color orange = Color(0xFFFC633C);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);
      final userCredential = await authProvider.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (userCredential?.user != null) {
        // SAFE CAST extra
        final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
        final role = extra?['userType'] as String? ?? 'citizen';

        await authProvider.createUserProfile(
          uid: userCredential!.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName,
          phoneNumber: userCredential.user!.phoneNumber,
          role: role,
        );
        if (mounted) context.go('/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isGoogleLoading = true);
    try {
      final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);
      final userCredential = await authProvider.signInWithGoogle();

      if (userCredential != null) {
        // SAFE CAST extra
        final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
        final role = extra?['userType'] as String? ?? 'citizen';

        await authProvider.createUserProfile(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName,
          phoneNumber: userCredential.user!.phoneNumber,
          role: role,
        );
        if (mounted) context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Transform.translate(
                    offset: const Offset(0, 0),
                    child: Image.asset(
                      'assets/police_logo.png',
                      width: 120,
                      height: 120,
                      errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // FORM
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.black),
                    ),
                    const SizedBox(height: 24),

                    // EMAIL
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration('Email', Icons.email),
                      validator: (v) => v!.isEmpty || !v.contains('@') ? 'Enter valid email' : null,
                    ),
                    const SizedBox(height: 20),

                    // PASSWORD
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: _inputDecoration('Password', Icons.lock).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off, color: Colors.black),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter password' : null,
                    ),
                    const SizedBox(height: 20),

                    // FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Forgot password clicked')),
                        ),
                        child: const Text(
                          'Forget Password?',
                          style: TextStyle(color: orange, fontSize: 14, fontWeight: FontWeight.w500),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // GOOGLE BUTTON (NOW UNCOMMENTED & WORKING)
                    
                    const SizedBox(height: 24),

                    // REGISTER + PHONE
                    Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            const Text("Don't have an account? ", style: TextStyle(fontSize: 14, color: Colors.black)),
                            GestureDetector(
                              onTap: () => context.go('/signup'),
                              child: const Text(
                                'Register',
                                style: TextStyle(fontSize: 18, color: orange, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              children: [
                                const TextSpan(text: 'Login with ', style: TextStyle(color: Colors.black)),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => context.go('/phone-login'),
                                    child: const Text(
                                      'Phone Number',
                                      style: TextStyle(
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
      labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: Colors.black),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}