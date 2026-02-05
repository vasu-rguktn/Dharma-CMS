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
      final complaintProvider =
          Provider.of<ComplaintProvider>(context, listen: false);
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

    // Split complaints into Saved and Drafts
    final savedComplaints = complaintProvider.complaints
        .where((c) => c['isDraft'] != true)
        .toList();
    final draftComplaints = complaintProvider.complaints
        .where((c) => c['isDraft'] == true)
        .toList();

    return DefaultTabController(
      length: 2,
      child: WillPopScope(
        onWillPop: () async {
          if (context.canPop()) {
            context.pop();
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Column(
              children: [
                // HEADER
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final authProvider =
                              Provider.of<AuthProvider>(context, listen: false);
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
                      const SizedBox(width: 8),
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

                // TAB BAR - Enhanced Design
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[700],
                      indicator: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      padding: const EdgeInsets.all(4),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bookmark, size: 18),
                              const SizedBox(width: 6),
                              Text(localizations.Saved ?? 'Saved'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.edit_note, size: 18),
                              const SizedBox(width: 6),
                              Text(localizations.Drafts ?? 'Drafts'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // TAB BAR VIEW
                Expanded(
                  child: TabBarView(
                    children: [
                      // SAVED TAB
                      _buildComplaintList(
                          savedComplaints, localizations, orange),
                      // DRAFTS TAB
                      _buildDraftList(draftComplaints, localizations, orange),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintList(List<Map<String, dynamic>> items,
      AppLocalizations localizations, Color orange) {
    if (items.isEmpty) {
      return _buildEmptyState(
        Icons.archive_rounded,
        localizations.noSavedComplaints,
        localizations.savedComplaintsAppearHere,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final complaintMap = items[index];
        final petition = Petition.fromMap(complaintMap, complaintMap['id']);

        return PetitionCard(
          petition: petition,
          formatTimestamp: (timestamp) {
            final date = timestamp.toDate();
            return '${date.day}/${date.month}/${date.year}';
          },
          onTap: () {
            PetitionDetailBottomSheet.show(context, petition);
          },
        );
      },
    );
  }

  Widget _buildDraftList(List<Map<String, dynamic>> items,
      AppLocalizations localizations, Color orange) {
    if (items.isEmpty) {
      return _buildEmptyState(
        Icons.note_add_outlined,
        'No active drafts',
        'Your AI Chat drafts will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final draftMap = items[index];
        final title = draftMap['title'] ?? 'Chat Draft';
        final createdAt = draftMap['createdAt'] as Timestamp?;
        final dateStr = createdAt != null
            ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
            : 'Unknown';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: orange.withOpacity(0.1),
              child: Icon(Icons.chat_outlined, color: orange),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Draft saved on $dateStr'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // DELETE BUTTON
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  tooltip: 'Delete draft',
                  onPressed: () =>
                      _showDeleteConfirmation(context, draftMap['id'], title),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              // Navigate back to AI Chat with draft data
              context.push('/ai-legal-chat', extra: draftMap);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String draftId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft'),
        content: Text(
          'Are you sure you want to delete "$title"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteDraft(context, draftId);
    }
  }

  Future<void> _deleteDraft(BuildContext context, String draftId) async {
    final complaintProvider =
        Provider.of<ComplaintProvider>(context, listen: false);

    try {
      await complaintProvider.deleteComplaint(draftId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete draft: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
