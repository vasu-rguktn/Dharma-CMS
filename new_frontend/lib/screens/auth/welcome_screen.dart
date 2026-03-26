import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dharma/providers/auth_provider.dart';
import 'package:dharma/providers/settings_provider.dart';
import 'package:dharma/config/languages.dart';
import 'package:dharma/l10n/app_localizations.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const Color orange = Color(0xFFFC633C);
  bool _isGoogleLoading = false;

  // ── Google Sign-In ──────────────────────────────────────────────────────
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
    final l = AppLocalizations.of(context);
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
              // ═══════════════════════════════════════════════════════════
              //  LANGUAGE DROPDOWN — top-right corner
              // ═══════════════════════════════════════════════════════════
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
                                  fontWeight: lang['code'] == currentLangCode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
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

              // ═══════════════════════════════════════════════════════════
              //  HERO — SVG + Logo
              // ═══════════════════════════════════════════════════════════
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: size.height * 0.30,
                    width: double.infinity,
                    child: SvgPicture.asset(
                      'assets/svg/login_design.svg',
                      fit: BoxFit.fill,
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: orange.withOpacity(0.6), width: 4),
                        boxShadow: [
                          BoxShadow(color: orange.withOpacity(0.25), blurRadius: 20, spreadRadius: 8),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/police_logo.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 76),

              // ═══════════════════════════════════════════════════════════
              //  TITLE + DESCRIPTION
              // ═══════════════════════════════════════════════════════════
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      l?.dharmaPortal ?? 'Dharma Portal',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l?.welcomeDescription ?? 'Digital hub for legal assistance',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                    ),                    const SizedBox(height: 40),

                    // ═════════════════════════════════════════════════════
                    //  AUTH BUTTONS
                    // ═════════════════════════════════════════════════════

                    // ── Already logged in → Dashboard shortcut ──
                    if (auth.isAuthenticated && !auth.isProfileLoading) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.go('/dashboard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            l?.goToDashboard ?? 'Go to Dashboard',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async => auth.signOut(),
                        child: Text(l?.signOut ?? 'Sign Out & Switch Account',
                            style: const TextStyle(color: orange, fontSize: 16)),
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                    ],

                    // ── Loading indicator (non-blocking) ──
                    if (auth.isLoading || (auth.isAuthenticated && auth.isProfileLoading)) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: orange)),
                      ),
                    ],

                    // ── Sign-in options — ALWAYS visible ──
                    // ── 1. Email / Password ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: auth.isAuthenticated
                            ? null
                            : () => context.go('/email-login'),
                        icon: const Icon(Icons.email_outlined, color: Colors.white),
                        label: const Text(
                          'Sign In with Email',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          disabledBackgroundColor: orange.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── 2. Google Sign-In ──
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: (auth.isAuthenticated || _isGoogleLoading)
                            ? null
                            : _signInWithGoogle,
                        icon: _isGoogleLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── 3. Phone OTP ──
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: auth.isAuthenticated
                            ? null
                            : () => context.go('/phone-login'),
                        icon: const Icon(Icons.phone_android, size: 22, color: Color(0xFFFC633C)),
                        label: const Text(
                          'Sign In with Phone OTP',
                          style: TextStyle(fontSize: 16, color: Color(0xFFFC633C)),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: const BorderSide(color: Color(0xFFFC633C)),
                        ),
                      ),
                    ),

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
