// lib/screens/complaints_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/complaint_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:Dharma/models/petition.dart';
import 'package:Dharma/screens/petition/petition_card.dart';
import 'package:Dharma/screens/petition/petition_detail_bottom_sheet.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
      if (authProvider.user != null) {
        complaintProvider.fetchComplaints(userId: authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    const Color orange = Color(0xFFFC633C);

    return WillPopScope(
      onWillPop: () async {
        // Use GoRouter's canPop to check navigation history
        if (context.canPop()) {
          context.pop();
          return false; // Prevent default exit, we handled navigation
        }
        return true; // Allow exit only if truly root
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              // HEADER: Orange Arrow + Title (tight & elegant)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
                child: Row(
                  children: [
                    // PURE ORANGE BACK ARROW — NO BACKGROUND
                    GestureDetector(
                      onTap: () {
                         final authProvider = Provider.of<AuthProvider>(context, listen: false);
                         if (authProvider.role == 'police') {
                           context.go('/police-dashboard');
                         } else {
                           context.go('/dashboard');
                         }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: orange,
                          size: 32,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8), // Super tight gap

                    // Title
                    Text(
                      localizations.mySavedComplaints,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 24, 24),
                child: Text(
                  localizations.viewAndManageComplaints,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ),

              // MAIN LIST
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: complaintProvider.complaints.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.archive_rounded,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 24),
                              Text(
                                localizations.noSavedComplaints,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localizations.savedComplaintsAppearHere,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: complaintProvider.complaints.length,
                          itemBuilder: (context, index) {
                            final complaintMap =
                                complaintProvider.complaints[index];
                            // Convert Map to Petition object
                            final petition = Petition.fromMap(
                                complaintMap, complaintMap['id']);

                            return PetitionCard(
                              petition: petition,
                              formatTimestamp: (timestamp) {
                                // Simple formatter logic or use intl if available
                                final date = timestamp.toDate();
                                return '${date.day}/${date.month}/${date.year}';
                              },
                              onTap: () {
                                PetitionDetailBottomSheet.show(
                                    context, petition);
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
