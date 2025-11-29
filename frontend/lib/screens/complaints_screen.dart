// lib/screens/complaints_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/complaint_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class ComplaintsScreen extends StatelessWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    const Color orange = Color(0xFFFC633C);

    return Scaffold(
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
                    onTap: () => context.go('/dashboard'),
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
                          final complaint = complaintProvider.complaints[index];

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: orange,
                                child: const Icon(Icons.description, color: Colors.white, size: 24),
                              ),
                              title: Text(
                                complaint['title'] ?? localizations.untitledComplaint,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  complaint['status'] ?? localizations.draft,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_rounded, color: Colors.red[600]),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(localizations.deleteComplaint),
                                      content: Text(localizations.deleteComplaintConfirmation),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text(localizations.cancel),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('complaints')
                                                  .doc(complaint['id'])
                                                  .delete();
                                              complaintProvider.fetchComplaints();
                                              if (context.mounted) Navigator.pop(context);
                                            } catch (e) {
                                              debugPrint('Error deleting complaint: $e');
                                            }
                                          },
                                          child: Text(
                                            localizations.delete,
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}