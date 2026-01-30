import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/providers/settings_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/widgets/language_selection_dialog.dart';
import 'package:Dharma/services/onboarding_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  // Make orange accessible to bottom sheet
  static const Color orange = Color(0xFFFC633C);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  double _logoScale = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.locale == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const LanguageSelectionDialog(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final double topImageHeight = size.height * 0.4;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            height: topImageHeight,
                            width: double.infinity,
                            child: SvgPicture.asset(
                              'assets/login_design.svg',
                              fit: BoxFit.fill,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                          Positioned(
                            bottom: -80,
                            child: GestureDetector(
                              onTapDown: (_) => setState(() => _logoScale = 0.95),
                              onTapUp: (_) => setState(() => _logoScale = 1.0),
                              onTapCancel: () => setState(() => _logoScale = 1.0),
                              child: AnimatedScale(
                                scale: _logoScale,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: WelcomeScreen.orange.withOpacity(0.6), width: 4),
                                    boxShadow: [
                                      BoxShadow(color: WelcomeScreen.orange.withOpacity(0.25), blurRadius: 20, spreadRadius: 8, offset: const Offset(0, 6)),
                                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 25, spreadRadius: 3, offset: const Offset(0, 10)),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/police_logo.png',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.error, color: Colors.red, size: 50),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 100),

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            children: [
                              Text(
                                localizations?.dharmaPortal ?? "Dharma Portal",
                                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.2, height: 1.1),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              
                              // Leadership Images Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildLeaderItem('assets/CM.png', 'CM'),
                                  _buildLeaderItem('assets/DyCM.png', 'DyCM'),
                                  _buildLeaderItem('assets/HomeMinister.jpg', 'HM'),
                                  _buildLeaderItem('assets/DGP.jpg', 'DGP'),
                                ],
                              ),

                              const SizedBox(height: 24),
                              Text(
                                localizations?.welcomeDescription ?? "Digital hub for Andhra Pradesh police records, management and analytics",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 17, color: Colors.black87, height: 1.5),
                              ),
                              const SizedBox(height: 48),
                              
                              // Show different buttons based on authentication state
                              if (authProvider.isAuthenticated) ...[
                                if (authProvider.isProfileLoading) ...[
                                   const Padding(
                                     padding: EdgeInsets.symmetric(vertical: 20.0),
                                     child: CircularProgressIndicator(color: WelcomeScreen.orange),
                                   ),
                                   Text(
                                     "Loading Profile...",
                                     style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                   ),
                                ] else ...[
                                  // User is logged in & profile loaded - show "Go to Dashboard" button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (authProvider.role == 'police') {
                                          context.go('/police-dashboard');
                                        } else {
                                          // Go to dashboard first
                                          context.go('/dashboard');
                                          
                                          // Check if onboarding is needed
                                          OnboardingService.shouldShowOnboarding().then((showOnboarding) {
                                            if (!showOnboarding && context.mounted) {
                                              // Only push AI chat if onboarding is NOT needed (returning user)
                                              Future.delayed(const Duration(milliseconds: 50), () {
                                                if (context.mounted) {
                                                  context.push('/ai-legal-chat');
                                                }
                                              });
                                            }
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: WelcomeScreen.orange,
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 8,
                                      ),
                                      child: Text(
                                        localizations?.goToDashboard ?? "Go to Dashboard",
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                // Show logout option
                                TextButton(
                                  onPressed: () async {
                                    await authProvider.signOut();
                                    // Stay on welcome screen after logout
                                  },
                                  child: Text(
                                    localizations?.signOut ?? "Sign Out",
                                    style: const TextStyle(fontSize: 18, color: WelcomeScreen.orange, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ] else ...[
                                // User is not logged in - show login/register options
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => context.go('/phone-login'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: WelcomeScreen.orange,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      elevation: 8,
                                    ),
                                    child: Text(
                                      localizations?.login ?? "Login",
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      localizations?.dontHaveAccount ?? "Don't have an account? ",
                                      style: const TextStyle(fontSize: 18, color: Colors.black),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.go('/signup/citizen'),
                                      child: Text(
                                        localizations?.register ?? "Register",
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: WelcomeScreen.orange),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 20),
                              TextButton.icon(
                                onPressed: () {
                                  showDialog(context: context, builder: (_) => const LanguageSelectionDialog());
                                },
                                icon: const Icon(Icons.language, color: WelcomeScreen.orange),
                                label: Text(
                                  localizations?.language ?? "Language / భాష",
                                  style: const TextStyle(fontSize: 18, color: WelcomeScreen.orange, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],

                            
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Removed role selection - app is citizen-only
  // Login flows directly to phone login for citizens

  Widget _buildLeaderItem(String assetPath, String role) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: WelcomeScreen.orange.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          role,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
// Bottom sheet classes removed - app is citizen-only, no role selection needed