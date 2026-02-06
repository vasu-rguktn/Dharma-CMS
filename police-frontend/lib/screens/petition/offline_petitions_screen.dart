// lib/screens/petition/offline_petitions_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/offline_petition_provider.dart';
import 'package:Dharma/providers/police_auth_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/models/petition_update.dart';
import 'package:Dharma/utils/rank_utils.dart';
import 'package:Dharma/widgets/petition_update_timeline.dart';
import 'package:Dharma/widgets/add_petition_update_dialog.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/complaint_provider.dart';

/// Offline Petitions Screen with "Sent" and "Assigned" tabs
/// Shows different tabs based on officer rank:
/// - High-level (DGP to SP): Both "Sent" and "Assigned" tabs
/// - Low-level (below SP): Only "Assigned" tab
class OfflinePetitionsScreen extends StatefulWidget {
  const OfflinePetitionsScreen({super.key});

  @override
  State<OfflinePetitionsScreen> createState() => _OfflinePetitionsScreenState();
}

class _OfflinePetitionsScreenState extends State<OfflinePetitionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isHighLevelOfficer = false;
  String? _officerId;
  String? _officerRank;
  String? _officerName;
  String? _officerFullIdentity; // Combined name, rank, and location
  bool _isLoading = true;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOfficerData();
    });
  }

  Future<void> _initializeOfficerData() async {
    final policeAuthProvider =
        Provider.of<PoliceAuthProvider>(context, listen: false);
    final policeProfile = policeAuthProvider.policeProfile;

    if (policeProfile != null) {
      _officerId = policeProfile['uid'];
      _officerRank = policeProfile['rank'];
      _officerName = policeProfile['displayName'];

      // ✅ ROBUST HIERARCHY-AWARE IDENTITY LOGIC
      final rank = _officerRank ?? '';
      final name = _officerName ?? 'Police Officer';
      String location = '';

      if (RankUtils.normalizeRank(rank).contains('DIRECTOR GENERAL')) {
        location = 'Andhra Pradesh';
      } else if (RankUtils.isRangeLevelOfficer(rank)) {
        location = policeProfile['range'] ?? '';
      } else if (RankUtils.isDistrictLevelOfficer(rank)) {
        location = policeProfile['district'] ?? '';
      } else if (rank.toUpperCase().contains('SDPO') ||
          rank.toUpperCase().contains('DEPUTY SUPERINTENDENT')) {
        location = policeProfile['sdpo'] ?? policeProfile['district'] ?? '';
      } else if (rank.toUpperCase().contains('CIRCLE') ||
          rank.toUpperCase().contains('INSPECTOR')) {
        location =
            policeProfile['circle'] ?? policeProfile['stationName'] ?? '';
      } else {
        location = policeProfile['stationName'] ?? '';
      }

      if (rank.isNotEmpty) {
        _officerFullIdentity =
            '$name ($rank${location.isNotEmpty ? " $location" : ""})';
      } else {
        _officerFullIdentity = name;
      }

      _isHighLevelOfficer = RankUtils.isHighLevelOfficer(_officerRank);

      // Initialize tab controller based on officer level
      _tabController = TabController(
        length: _isHighLevelOfficer ? 2 : 1,
        vsync: this,
      );

      // Load initial data
      if (_isHighLevelOfficer) {
        await _loadSentPetitions();
      } else {
        await _loadAssignedPetitions();
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }

    // Fetch saved complaints to enable the "Save" feature
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      Provider.of<ComplaintProvider>(context, listen: false)
          .fetchComplaints(userId: auth.user!.uid);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSentPetitions() async {
    if (_officerId == null) return;
    final offlinePetitionProvider =
        Provider.of<OfflinePetitionProvider>(context, listen: false);
    await offlinePetitionProvider.fetchSentPetitions(_officerId!);
  }

  Future<void> _loadAssignedPetitions() async {
    if (_officerId == null) return;
    final offlinePetitionProvider =
        Provider.of<OfflinePetitionProvider>(context, listen: false);
    await offlinePetitionProvider.fetchAssignedPetitions(_officerId!);
  }

  Color _getAssignmentStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPoliceStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'received':
        return Colors.blue;
      case 'in progress':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  Widget _buildPetitionCard(Petition petition, bool isSentTab) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getPoliceStatusColor(petition.policeStatus).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPetitionDetails(petition, isSentTab),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          petition.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (petition.isEscalated)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: const Text(
                            'ESCALATED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getPoliceStatusColor(petition.policeStatus)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getPoliceStatusColor(petition.policeStatus),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          petition.policeStatus?.toUpperCase() ?? 'RECEIVED',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getPoliceStatusColor(petition.policeStatus),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      // SAVE BUTTON
                      Consumer<ComplaintProvider>(
                        builder: (context, complaintProvider, _) {
                          final isSaved =
                              complaintProvider.isPetitionSaved(petition.id);
                          return InkWell(
                            onTap: () async {
                              final auth = Provider.of<AuthProvider>(context,
                                  listen: false);
                              final userId = auth.user?.uid;
                              if (userId == null) return;

                              await complaintProvider.toggleSaveComplaint(
                                  petition.toMap(), userId);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isSaved ? Colors.orange : Colors.grey,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Petitioner info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    petition.petitionerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Assignment info
              if (isSentTab) ...[
                // Show "Assigned To" in sent tab
                Row(
                  children: [
                    Icon(Icons.arrow_forward,
                        size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'To: ${petition.assignedToName ?? petition.assignedToStation ?? petition.assignedToDistrict ?? petition.assignedToRange ?? "Unknown"}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Show "Assigned By" in assigned tab
                Row(
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'From: ${petition.assignedByName ?? "Unknown"}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),

              // Assignment date
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(petition.assignedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Assignment notes (if available)
              if (petition.assignmentNotes != null &&
                  petition.assignmentNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.amber[800]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          petition.assignmentNotes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.amber[900],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPetitionDetails(Petition petition, bool isSentTab) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  petition.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Petition Details
                        _buildDetailSection('Petition Details', [
                          _buildDetailRow('Type', petition.type.displayName),
                          _buildDetailRow(
                              'Petitioner', petition.petitionerName),
                          if (petition.phoneNumber != null)
                            _buildDetailRow(
                              'Phone',
                              petition.isAnonymous
                                  ? maskPhoneNumber(petition.phoneNumber)
                                  : petition.phoneNumber!,
                            ),
                          if (petition.district != null)
                            _buildDetailRow('District', petition.district!),
                          if (petition.stationName != null)
                            _buildDetailRow('Station', petition.stationName!),
                          _buildDetailRow(
                            'Status',
                            petition.policeStatus?.toUpperCase() ?? 'RECEIVED',
                          ),
                        ]),

                        const SizedBox(height: 20),

                        // Assignment Details
                        _buildDetailSection('Assignment Details', [
                          if (petition.assignedByName != null)
                            _buildDetailRow('Assigned By',
                                '${petition.assignedByName}${petition.assignedByRank != null ? " (${petition.assignedByRank})" : ""}'),
                          if (petition.assignedToName != null)
                            _buildDetailRow(
                                'Assigned To', petition.assignedToName!),
                          if (petition.assignedToRank != null)
                            _buildDetailRow('Rank', petition.assignedToRank!),
                          if (petition.assignedToStation != null)
                            _buildDetailRow(
                                'Station', petition.assignedToStation!),
                          if (petition.assignedToDistrict != null)
                            _buildDetailRow(
                                'District', petition.assignedToDistrict!),
                          if (petition.assignedToRange != null)
                            _buildDetailRow('Range', petition.assignedToRange!),
                          _buildDetailRow('Assigned At',
                              _formatTimestamp(petition.assignedAt)),
                          if (petition.assignmentNotes != null)
                            _buildDetailRow('Notes', petition.assignmentNotes!),
                        ]),

                        const SizedBox(height: 20),

                        // Grounds
                        if (petition.grounds.isNotEmpty)
                          _buildTextSection('Grounds', petition.grounds),

                        if (petition.prayerRelief != null &&
                            petition.prayerRelief!.isNotEmpty)
                          _buildTextSection(
                              'Prayer/Relief', petition.prayerRelief!),

                        const SizedBox(height: 20),

                        // AI GUIDELINES SECTION
                        _AiGuidelinesSection(petition: petition),

                        const SizedBox(height: 20),

                        // Timeline Section
                        _buildTimelineSection(petition),

                        const SizedBox(height: 80), // Space for action buttons
                      ],
                    ),
                  ),
                ),

                // Action Buttons (Fixed at bottom)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // AI Guidelines - Removed from here to move inline
                      const SizedBox.shrink(),

                      if (!isSentTab) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showUpdateStatusDialog(petition),
                                icon: const Icon(Icons.sync),
                                label: const Text('Update Status'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(
                                      color: Colors.deepPurple),
                                  foregroundColor: Colors.deepPurple,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showAddUpdateDialog(petition),
                                icon: const Icon(Icons.add_comment),
                                label: const Text('Add Update'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isHighLevelOfficer) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context); // Close bottom sheet
                                context.push('/submit-offline-petition',
                                    extra: petition);
                              },
                              icon: const Icon(Icons.forward),
                              label: const Text(
                                  'Forward / Assign to Sub-ordinate'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineSection(Petition petition) {
    final petitionId = petition.id!;
    debugPrint('🔍 Building timeline for petition: $petitionId');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Updates Timeline',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('petition_updates')
              .where('petitionId', isEqualTo: petitionId)
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            debugPrint(
                '📊 Timeline snapshot state: ${snapshot.connectionState}');
            debugPrint('📊 Has data: ${snapshot.hasData}');
            debugPrint('📊 Has error: ${snapshot.hasError}');

            if (snapshot.hasError) {
              debugPrint('❌ Timeline error: ${snapshot.error}');
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600], size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Error loading timeline',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              debugPrint('⏳ Timeline loading...');
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              debugPrint('📭 No updates found for petition: $petitionId');
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No updates yet. Add an update or change status to see the timeline.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final updates = snapshot.data!.docs
                .map((doc) => PetitionUpdate.fromFirestore(doc))
                .toList();

            final allUpdates = context
                .read<PetitionProvider>()
                .getUpdatesWithEscalations(petition, updates);

            return PetitionUpdateTimeline(updates: allUpdates);
          },
        ),
      ],
    );
  }

  void _showUpdateStatusDialog(Petition petition) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Petition Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusOption(
              title: 'Received',
              icon: Icons.inbox,
              color: Colors.blue,
              onTap: () {
                Navigator.pop(dialogContext);
                _updatePetitionStatus(petition, 'Received');
              },
            ),
            const SizedBox(height: 8),
            _StatusOption(
              title: 'In Progress',
              icon: Icons.pending_actions,
              color: Colors.orange,
              onTap: () {
                Navigator.pop(dialogContext);
                _updatePetitionStatus(petition, 'In Progress');
              },
            ),
            const SizedBox(height: 8),
            _StatusOption(
              title: 'Closed',
              icon: Icons.check_circle,
              color: Colors.green,
              onTap: () {
                Navigator.pop(dialogContext);
                _updatePetitionStatus(petition, 'Closed');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePetitionStatus(
      Petition petition, String newStatus) async {
    try {
      final offlinePetitionProvider =
          Provider.of<OfflinePetitionProvider>(context, listen: false);

      // Update petition status in Firestore
      await FirebaseFirestore.instance
          .collection('offlinepetitions')
          .doc(petition.id)
          .update({
        'policeStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also create a timeline entry for the status change
      await FirebaseFirestore.instance.collection('petition_updates').add({
        'petitionId': petition.id,
        'updateText': '📋 Status changed to: $newStatus',
        'addedBy': _officerFullIdentity ?? _officerName ?? 'Police Officer',
        'addedByUserId': _officerId ?? '',
        'photoUrls': [],
        'documents': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // 1. Refresh the list data first
        await _loadAssignedPetitions();
        await _loadSentPetitions();

        // 2. Close only the petition details bottom sheet
        // (The status selection dialog was already closed in its onTap)
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to: $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddUpdateDialog(Petition petition) {
    showDialog(
      context: context,
      builder: (_) => AddPetitionUpdateDialog(
        petition: petition,
        policeOfficerName:
            _officerFullIdentity ?? _officerName ?? 'Unknown Officer',
        policeOfficerUserId: _officerId ?? '',
      ),
    ).then((_) {
      // Refresh list after adding update
      if (mounted) {
        _loadAssignedPetitions();
      }
    });
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by Title, ID, or Petitioner Name...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildPetitionList(bool isSentTab) {
    return Consumer<OfflinePetitionProvider>(
      builder: (context, offlinePetitionProvider, _) {
        if (offlinePetitionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allPetitions = isSentTab
            ? offlinePetitionProvider.sentPetitions
            : offlinePetitionProvider.assignedPetitions;

        // Apply Search Filter
        final petitions = allPetitions.where((petition) {
          final query = _searchQuery.toLowerCase();
          final title = petition.title.toLowerCase();
          final id = petition.id?.toLowerCase() ?? '';
          final petitioner = petition.petitionerName.toLowerCase();

          return title.contains(query) ||
              id.contains(query) ||
              petitioner.contains(query);
        }).toList();

        return Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: petitions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSentTab
                                ? Icons.send_outlined
                                : Icons.inbox_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matching petitions found'
                                : (isSentTab
                                    ? 'No Sent Petitions'
                                    : 'No Assigned Petitions'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty)
                            Text(
                              isSentTab
                                  ? 'Petitions you assign will appear here'
                                  : 'Petitions assigned to you will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: isSentTab
                          ? _loadSentPetitions
                          : _loadAssignedPetitions,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: petitions.length,
                        itemBuilder: (context, index) {
                          return _buildPetitionCard(
                              petitions[index], isSentTab);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Offline Petitions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: _isHighLevelOfficer
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                onTap: (index) {
                  // Load data when tab is switched
                  if (index == 0) {
                    _loadSentPetitions();
                  } else {
                    _loadAssignedPetitions();
                  }
                },
                tabs: const [
                  Tab(
                    icon: Icon(Icons.send),
                    text: 'Sent',
                  ),
                  Tab(
                    icon: Icon(Icons.inbox),
                    text: 'Assigned',
                  ),
                ],
              )
            : null,
      ),
      body: _isHighLevelOfficer
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildPetitionList(true), // Sent tab
                _buildPetitionList(false), // Assigned tab
              ],
            )
          : _buildPetitionList(false), // Only assigned for low-level officers
    );
  }
}

// Helper widget for status options
class _StatusOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatusOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiGuidelinesSection extends StatefulWidget {
  final Petition petition;

  const _AiGuidelinesSection({required this.petition});

  @override
  State<_AiGuidelinesSection> createState() => _AiGuidelinesSectionState();
}

class _AiGuidelinesSectionState extends State<_AiGuidelinesSection> {
  bool _loadingAI = false;
  Map<String, dynamic>? _aiReport;
  bool _showAiGuidelines = false;
  final String _apiUrl =
      "https://fastapi-app-335340524683.asia-south1.run.app/api/ai-investigation/";

  String _buildFirDetails(Petition p) {
    return '''
Case ID: ${p.caseId ?? 'N/A'}
Petition Title: ${p.title}
Petition Type: ${p.type.displayName}

Petitioner Name: ${p.petitionerName}
Phone Number: ${p.phoneNumber ?? 'N/A'}

District: ${p.district ?? 'N/A'}
Police Station: ${p.stationName ?? 'N/A'}

Complaint / Grounds:
${p.grounds}
''';
  }

  Future<void> _generateInvestigation() async {
    if (mounted) {
      setState(() {
        _loadingAI = true;
        _aiReport = null;
      });
    }

    final firDetails = _buildFirDetails(widget.petition);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fir_id": widget.petition.caseId,
          "fir_details": firDetails,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _aiReport = data["report"];
            _loadingAI = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingAI = false);
      }
    } catch (e) {
      debugPrint('Error generating investigation: $e');
      if (mounted) setState(() => _loadingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _showAiGuidelines = !_showAiGuidelines;
              });
              if (_showAiGuidelines && _aiReport == null) {
                _generateInvestigation();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Investigation Guidelines',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showAiGuidelines ? Icons.expand_less : Icons.expand_more,
                    color: Colors.deepPurple,
                  ),
                ],
              ),
            ),
          ),
          if (_showAiGuidelines) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _loadingAI
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _aiReport == null
                      ? const Text('Click to generate investigation steps.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_aiReport!['summary'] != null) ...[
                              _buildSubSection(
                                title: 'Investigation Summary',
                                icon: Icons.summarize,
                                color: Colors.orange,
                                content: Text(
                                  _aiReport!['summary'],
                                  style: const TextStyle(
                                      fontSize: 14, height: 1.5),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_aiReport!['modus_operandi_tags'] != null) ...[
                              _buildSubSection(
                                title: 'Modus Operandi Tags',
                                icon: Icons.visibility,
                                color: Colors.indigo,
                                content: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: (_aiReport!['modus_operandi_tags']
                                          as List)
                                      .map((tag) {
                                    return Chip(
                                      label: Text(tag.toString(),
                                          style: const TextStyle(fontSize: 12)),
                                      backgroundColor: Colors.indigo.shade50,
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_aiReport!['investigation_tasks'] != null) ...[
                              _buildSubSection(
                                title: 'Investigation Tasks',
                                icon: Icons.task_alt,
                                color: Colors.blue,
                                content: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: (_aiReport!['investigation_tasks']
                                          as List)
                                      .map((task) {
                                    final priority =
                                        task['priority']?.toString() ??
                                            'Routine';
                                    final isUrgent = priority
                                        .toLowerCase()
                                        .contains('urgent');
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isUrgent
                                            ? Colors.red.shade50
                                            : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isUrgent
                                              ? Colors.red.shade200
                                              : Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            isUrgent
                                                ? Icons.warning
                                                : Icons.info_outline,
                                            size: 16,
                                            color: isUrgent
                                                ? Colors.red.shade700
                                                : Colors.blue.shade700,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              task['task']?.toString() ?? '',
                                              style:
                                                  const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_aiReport!['applicable_laws'] != null) ...[
                              _buildSubSection(
                                title: 'Applicable Laws',
                                icon: Icons.gavel,
                                color: Colors.green,
                                content: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children:
                                      (_aiReport!['applicable_laws'] as List)
                                          .map((law) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.green.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            law['section']?.toString() ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            law['justification']?.toString() ??
                                                '',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_aiReport!['forensic_suggestions'] != null) ...[
                              _buildSubSection(
                                title: 'Forensic Suggestions',
                                icon: Icons.science,
                                color: Colors.purple,
                                content: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: (_aiReport!['forensic_suggestions']
                                          as List)
                                      .map((suggestion) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.purple.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            suggestion['evidence_type']
                                                    ?.toString() ??
                                                '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.purple,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            suggestion['protocol']
                                                    ?.toString() ??
                                                '',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }
}
