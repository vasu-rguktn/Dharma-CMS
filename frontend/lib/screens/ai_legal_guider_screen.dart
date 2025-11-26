// lib/screens/ai_legal_guider_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';

class AiLegalGuiderScreen extends StatelessWidget {
  const AiLegalGuiderScreen({super.key});

  static const Color orange = Color(0xFFFC633C);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final double topImageHeight = size.height * 0.4;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      body: SafeArea(
        child: Stack(
          children: [
            // ── 1. HEADER + SVG + LOGO ──
            Column(
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Curved Orange Header
                    ClipPath(
                      clipper: _CurvedHeaderClipper(),
                      child: Container(
                        width: double.infinity,
                        height: topImageHeight,
                        color: orange,
                        padding: const EdgeInsets.only(
                          top: 60,
                          left: 32,
                          right: 32,
                          bottom: 48,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          
                        ),
                      ),
                    ),

                    // SVG – Original Shape (No Zoom)
                    SizedBox(
                      height: topImageHeight,
                      width: double.infinity,
                      child: SvgPicture.asset(
                        'assets/DashboardFrame.svg',
                        fit: BoxFit.contain,           // ← PRESERVES ORIGINAL SHAPE
                        alignment: Alignment.topCenter, // ← Aligns to top
                      ),
                    ),

                    // Overlapping Police Logo
                    Positioned(
                      bottom: -80,
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
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.error,
                              color: Colors.red,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100),
                const Spacer(),
              ],
            ),

            // ── 2. BUTTONS AT BOTTOM ──
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.wantToUtiliseFeature,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF333652),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.go('/ai-legal-chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orange,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 6,
                            ),
                            child: Text(
                              localizations.utilise,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.go('/dashboard'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: orange, width: 2),
                            ),
                            child: Text(
                              localizations.skip,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFC633C),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 45);
    path.quadraticBezierTo(
      size.width * 0.30,
      size.height,
      size.width * 0.70,
      size.height - 40,
    );
    path.quadraticBezierTo(
      size.width,
      size.height - 80,
      size.width,
      size.height - 25,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}