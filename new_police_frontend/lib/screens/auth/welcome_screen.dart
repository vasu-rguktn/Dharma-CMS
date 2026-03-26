import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dharma_police/providers/auth_provider.dart';
import 'package:dharma_police/providers/settings_provider.dart';
import 'package:dharma_police/config/languages.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {  static const Color navy = Color(0xFF1A237E);
  bool _isGoogleLoading = false;

  Future<void> _signInWithGoogle() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isGoogleLoading = true);
    try {
      final cred = await auth.signInWithGoogle();
      if (cred != null && mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final auth = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final currentLangCode = settings.locale?.languageCode ?? 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Language dropdown ──
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 12, left: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.translate, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: AppLanguages.supported.any((l) => l['code'] == currentLangCode)
                              ? currentLangCode
                              : 'en',
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                          items: AppLanguages.supported.map((lang) {
                            return DropdownMenuItem<String>(
                              value: lang['code'],
                              child: Text(
                                AppLanguages.displayName(lang['code']!),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: lang['code'] == currentLangCode ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (code) {
                            if (code != null) settings.setLanguage(code);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Hero ──
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: size.height * 0.28,
                    width: double.infinity,
                    child: SvgPicture.asset('assets/svg/login_design.svg', fit: BoxFit.fill),
                  ),
                  Positioned(
                    bottom: -55,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white,
                        border: Border.all(color: navy.withOpacity(0.6), width: 4),
                        boxShadow: [BoxShadow(color: navy.withOpacity(0.2), blurRadius: 20, spreadRadius: 8)],
                      ),
                      child: Center(child: Image.asset('assets/images/police_logo.png', width: 75, height: 75, fit: BoxFit.contain)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 72),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Text('Dharma', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Police Command Center',
                      style: TextStyle(fontSize: 16, color: navy, fontWeight: FontWeight.w600, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AP Police records, investigation tools & case management',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                    ),
                    const SizedBox(height: 40),

                    if (auth.isAuthenticated && !auth.isProfileLoading) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go('/dashboard'),
                          style: ElevatedButton.styleFrom(backgroundColor: navy, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: const Text('Go to Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(onPressed: () async => auth.signOut(), child: const Text('Sign Out', style: TextStyle(color: Colors.red, fontSize: 16))),
                    ] else if (!auth.isAuthenticated) ...[
                      // ── Email / Password ──
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.email_outlined, color: Colors.white),
                          label: const Text('Sign In with Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: navy, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Google Sign-In ──
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                          icon: _isGoogleLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                          label: const Text('Continue with Google', style: TextStyle(fontSize: 16, color: Colors.black87)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text('For authorised AP Police officers only', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ] else ...[
                      const CircularProgressIndicator(color: navy),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
