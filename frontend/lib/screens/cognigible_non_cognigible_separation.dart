import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CognigibleNonCognigibleSeparationScreen extends StatefulWidget {
  final String classification;
  final String originalClassification;
  final Map<String, dynamic>? complaintData;
  final List<String> evidencePaths;

  const CognigibleNonCognigibleSeparationScreen({
    super.key,
    required this.classification,
    required this.originalClassification,
    this.complaintData,
    this.evidencePaths = const [],
  });

  static CognigibleNonCognigibleSeparationScreen fromRouteSettings(
      BuildContext context, GoRouterState state) {
    final q = state.extra as Map<String, dynamic>?;
    return CognigibleNonCognigibleSeparationScreen(
      classification: q?['classification'] as String? ?? '',
      originalClassification: q?['originalClassification'] as String? ?? '',
      complaintData: q?['complaintData'] as Map<String, dynamic>?,
      evidencePaths:
          (q?['evidencePaths'] as List?)?.map((e) => e.toString()).toList() ??
              [],
    );
  }

  @override
  State<CognigibleNonCognigibleSeparationScreen> createState() =>
      _CognigibleNonCognigibleSeparationScreenState();
}

class _CognigibleNonCognigibleSeparationScreenState
    extends State<CognigibleNonCognigibleSeparationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // LOGIC CHECK: Use the original English string OR fallback to Telugu keywords
    final String logicUpper = (widget.originalClassification.isNotEmpty
            ? widget.originalClassification
            : widget.classification)
        .toUpperCase();

    final bool isNonCognizable = logicUpper.contains('NON-COGNIZABLE') ||
        logicUpper.contains('నాన్-కాగ్నిజబుల్');
    final bool isCognizable = !isNonCognizable &&
        (logicUpper.contains('COGNIZABLE') ||
            logicUpper.contains('కాగ్నిజబుల్'));

    // Theme Colors
    final Color primaryColor = isCognizable
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828); // Green vs Red
    final Color accentColor =
        isCognizable ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final IconData statusIcon =
        isCognizable ? LucideIcons.shieldCheck : LucideIcons.shieldAlert;

    // Prepare Data for Navigation
    final petitionData = {
      'complaintType': widget.complaintData?['complaintType'] ??
          widget.complaintData?['complaint_type'] ??
          '',
      'fullName': widget.complaintData?['fullName'] ??
          widget.complaintData?['full_name'] ??
          widget.complaintData?['name'] ??
          '',
      'phone': widget.complaintData?['phone'] ??
          widget.complaintData?['phoneNumber'] ??
          widget.complaintData?['phone_number'] ??
          '',
      'address': widget.complaintData?['address'] ??
          widget.complaintData?['addr'] ??
          widget.complaintData?['location'] ??
          '',
      'details': widget.complaintData?['details'] ??
          widget.complaintData?['summary'] ??
          widget.complaintData?['complaint'] ??
          '',
      // New Fields for Auto-fill
      'incident_address': widget.complaintData?['incident_address'] ?? '',
      'incident_details': widget.complaintData?['incident_details'] ?? '',
      'incident_date': widget.complaintData?['incident_date'] ??
          widget.complaintData?['date_of_complaint'] ??
          '',
      'selected_police_station':
          widget.complaintData?['selected_police_station'] ?? '',
      'evidencePaths': widget.evidencePaths,
      'classification': widget.classification, // Pass BNS Section info
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      appBar: AppBar(
        title: Text(
          localizations.offenceClassification,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),

              // --- Animated Icon ---
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      statusIcon,
                      size: 60,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // --- Classification Text ---
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Text(
                        localizations.thisCaseIsClassifiedAs,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isCognizable
                            ? localizations.cognizable
                            : localizations.nonCognizable,
                        style: TextStyle(
                          fontSize: 32,
                          color: primaryColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // --- Action Buttons ---
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    if (isCognizable)
                      _buildPrimaryButton(
                        context,
                        label: localizations.fileACase,
                        icon: LucideIcons.fileText,
                        color: const Color(0xFFFC633C), // App Orange
                        onPressed: () {
                          print(
                              '🚀 [DEBUG] Separation Screen: Navigating to Petition Create');
                          context.go('/petitions/create', extra: petitionData);
                        },
                      )
                    else ...[
                      _buildPrimaryButton(
                        context,
                        label: localizations.goToDashboard,
                        icon: LucideIcons.layoutDashboard,
                        color: Colors.grey[800]!,
                        onPressed: () => context.go('/dashboard'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Need to Contact the OFFICER",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFC633C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context,
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
