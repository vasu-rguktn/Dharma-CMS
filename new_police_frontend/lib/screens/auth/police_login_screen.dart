import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma_police/providers/auth_provider.dart';

class PoliceLoginScreen extends StatefulWidget {
  const PoliceLoginScreen({super.key});
  @override
  State<PoliceLoginScreen> createState() => _PoliceLoginScreenState();
}

class _PoliceLoginScreenState extends State<PoliceLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color navy = Color(0xFF1A237E);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        _snack('Login successful!', Colors.green);
        context.go('/dashboard');
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll(RegExp(r'\[.*?\]'), '').trim();
      _snack(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) { _snack('Enter your email first'); return; }
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.sendPasswordResetEmail(email);
      if (mounted) _snack('Password reset email sent!', Colors.green);
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final cred = await auth.signInWithGoogle();
      if (cred != null && mounted) {
        _snack('Google sign-in successful!', Colors.green);
        context.go('/dashboard');
      }
    } catch (e) {
      _snack('Google sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, [Color? bg]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Header ──
          SizedBox(
            height: h * 0.22, width: w,
            child: Stack(children: [
              SvgPicture.asset('assets/svg/Frame.svg', fit: BoxFit.fill, width: w, height: h * 0.22),
              Positioned(top: 0, left: 0, child: SafeArea(child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')))),
              Positioned(left: 0, right: 0, bottom: 10, child: Image.asset('assets/images/police_logo.png', height: 80)),
            ]),
          ),

          // ── Form ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Text('Police Sign In', style: TextStyle(fontSize: (w * 0.065).clamp(22.0, 30.0), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Enter your credentials', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    const SizedBox(height: 28),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: const Text('Forgot Password?', style: TextStyle(color: navy, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                            : const Text('Sign In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Register link
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Don't have an account?", style: TextStyle(color: Colors.grey.shade600)),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Register', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
                      ),
                    ]),

                    // ── Divider ──
                    const SizedBox(height: 16),
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500))),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),

                    // ── Google Sign-In ──
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                        label: const Text('Continue with Google', style: TextStyle(fontSize: 16, color: Colors.black87)),
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
