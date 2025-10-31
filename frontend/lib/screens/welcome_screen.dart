import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // For animation
  double _logoScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double topImageHeight = size.height * 0.4; // covers half of the screen

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
                      // 🟧 Top half with SVG background + overlapping logo
                      Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          // Background SVG
                          SizedBox(
                            height: topImageHeight,
                            width: double.infinity,
                            child: SvgPicture.asset(
                              'assets/login_design.svg',
                              fit: BoxFit.fill,
                              alignment: Alignment.topCenter,
                            ),
                          ),

                          // Overlapping Logo
                          Positioned(
                            bottom: -80, // moves half into the lower section
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
                                    border: Border.all(
                                      color: orange.withOpacity(0.6),
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: orange.withOpacity(0.25),
                                        blurRadius: 20,
                                        spreadRadius: 8,
                                        offset: const Offset(0, 6),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 25,
                                        spreadRadius: 3,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/police_logo.png',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.error, color: Colors.red, size: 50),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 100), // space for logo overlap

                      // 🟩 Main content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            children: [
                              const Text(
                                "Dharma Portal",
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 1.2,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Digital hub for Andhra Pradesh police records, management and analytics",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 48),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _showLoginPopup(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: orange,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 8,
                                  ),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(fontSize: 18, color: Colors.black),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showRegisterPopup(context),
                                    child: const Text(
                                      "Register",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
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

  // ✅ Login Popup
  void _showLoginPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Login as",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDialogButton(
                label: "Citizen",
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login', extra: {'userType': 'citizen'});
                },
              ),
              const SizedBox(height: 12),
              _buildDialogButton(
                label: "Police",
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login', extra: {'userType': 'police'});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Register Popup
  void _showRegisterPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Register as",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDialogButton(
                label: "Citizen",
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/signup', extra: {'userType': 'citizen'});
                },
              ),
              const SizedBox(height: 12),
              _buildDialogButton(
                label: "Police",
                onPressed: null,
                backgroundColor: Colors.grey[400],
                textColor: Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Reusable button widget
  Widget _buildDialogButton({
    required String label,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? orange,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: onPressed == null ? 0 : 4,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          color: textColor ?? Colors.white,
          fontWeight: onPressed == null ? FontWeight.normal : FontWeight.w600,
        ),
      ),
    );
  }
}
