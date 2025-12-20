import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/providers/settings_provider.dart';
import 'package:Dharma/widgets/language_selection_dialog.dart';

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
                              const SizedBox(height: 16),
                              Text(
                                localizations?.welcomeDescription ?? "Digital hub for Andhra Pradesh police records, management and analytics",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 17, color: Colors.black87, height: 1.5),
                              ),
                              const SizedBox(height: 48),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _showLoginBottomSheet(context),
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
                                    onTap: () => _showRegisterBottomSheet(context),
                                    child: Text(
                                      localizations?.register ?? "Register",
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: WelcomeScreen.orange),
                                    ),
                                  ),
                                ],
                              ),
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

  void _showLoginBottomSheet(BuildContext context) {
  final localizations = AppLocalizations.of(context)!;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _BottomSheetContent(
      title: localizations.loginAs ?? "Login as",
      orangeColor: WelcomeScreen.orange,
      options: [
        // ✅ Citizen → Phone Login
        _OptionItem(
          label: localizations.citizen ?? "Citizen",
          onTap: () {
            Navigator.pop(context);
            context.go('/phone-login'); // ✅ citizen phone login
          },
        ),

        // ✅ Police → Police Login
        _OptionItem(
          label: localizations.police ?? "Police",
          onTap: () {
            Navigator.pop(context);
            context.go('/police-login'); // ✅ police login
          },
        ),
      ],
    ),
  );
}


  void _showRegisterBottomSheet(BuildContext context) {
  final localizations = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _BottomSheetContent(
      title: localizations.registerAs ?? "Register as",
      orangeColor: WelcomeScreen.orange,
      options: [
        _OptionItem(
          label: localizations.citizen ?? "Citizen",
          onTap: () {
            Navigator.pop(context);
            context.go('/signup/citizen'); // ✅ CHANGED
          },
        ),
        _OptionItem(
          label: localizations.police ?? "Police",
          onTap: () {
            Navigator.pop(context);
            context.go('/signup/police'); // ✅ CHANGED
          },
        ),
      ],
    ),
  );
}
}
// Beautiful bottom sheet — only added orangeColor parameter
class _BottomSheetContent extends StatelessWidget {
  final String title;
  final List<_OptionItem> options;
  final Color orangeColor;   // ← only addition

  const _BottomSheetContent({
    required this.title,
    required this.options,
    required this.orangeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.42,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(42), topRight: Radius.circular(42)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.grey[350], borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              children: options.asMap().entries.map((e) => Padding(
                padding: EdgeInsets.only(bottom: e.key == options.length - 1 ? 0 : 18),
                child: _buildButton(e.value),
              )).toList(),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildButton(_OptionItem item) {
    return SizedBox(
      height: 68,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: item.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: item.backgroundColor ?? orangeColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: item.onTap == null ? 0 : 12,
          shadowColor: orangeColor.withOpacity(0.5),
        ),
        child: Text(item.label, style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: item.textColor ?? Colors.white)),
      ),
    );
  }
}

class _OptionItem {
  final String label;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  _OptionItem({required this.label, this.onTap, this.backgroundColor, this.textColor});
}