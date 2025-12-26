// lib/screens/petition/police_petition_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Police Petition List Screen
/// Shows filtered petitions for the police station and allows viewing/updating details
class PolicePetitionListScreen extends StatefulWidget {
  final PetitionFilter filter;
  final String title;

  const PolicePetitionListScreen({
    super.key,
    required this.filter,
    required this.title,
  });

  @override
  State<PolicePetitionListScreen> createState() =>
      _PolicePetitionListScreenState();
}

class _PolicePetitionListScreenState extends State<PolicePetitionListScreen> {
  bool _isLoading = true;
  List<Petition> _filteredPetitions = [];

  @override
  void initState() {
    super.initState();
    _loadFilteredPetitions();
  }

  Future<void> _loadFilteredPetitions() async {
    setState(() => _isLoading = true);

    final petitionProvider =
        Provider.of<PetitionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final stationName = authProvider.userProfile?.stationName;
    if (stationName != null) {
      await petitionProvider.fetchFilteredPetitions(
        isPolice: true,
        stationName: stationName,
        filter: widget.filter,
      );
    }

    setState(() {
      _filteredPetitions = petitionProvider.petitions;
      _isLoading = false;
    });
  }

  Color _getPoliceStatusColor(String status) {
    switch (status) {
      case 'Received':
        return Colors.blue;
      case 'In Progress':
        return Colors.indigo;
      case 'Closed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getFilterColor(PetitionFilter filter) {
    switch (filter) {
      case PetitionFilter.all:
        return Colors.deepPurple;
      case PetitionFilter.received:
        return Colors.blue.shade700;
      case PetitionFilter.inProgress:
        return Colors.orange.shade700;
      case PetitionFilter.closed:
        return Colors.green.shade700;
    }
  }

  IconData _getFilterIcon(PetitionFilter filter) {
    switch (filter) {
      case PetitionFilter.all:
        return Icons.gavel;
      case PetitionFilter.received:
        return Icons.call_received;
      case PetitionFilter.inProgress:
        return Icons.sync;
      case PetitionFilter.closed:
        return Icons.task_alt;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  void _showPetitionDetails(BuildContext context, Petition petition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        builder: (_, controller) {
          String? selectedStatus = petition.policeStatus;
          String? selectedSubStatus = petition.policeSubStatus;
          bool loading = false;

          return StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            petition.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const Divider(),

                    // Petition Details Section
                    const Text(
                      'Petition Details',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow('Petition ID', petition.id ?? '-'),
                    _buildDetailRow('Petition Type', petition.type.displayName),
                    _buildDetailRow('Status', petition.status.displayName),
                    _buildDetailRow('Petitioner Name', petition.petitionerName),
                    _buildDetailRow('Phone Number', petition.phoneNumber ?? '-'),
                    if (petition.address != null && petition.address!.isNotEmpty)
                      _buildDetailRow('Address', petition.address!),
                    if (petition.district != null &&
                        petition.district!.isNotEmpty)
                      _buildDetailRow('District', petition.district!),
                    if (petition.stationName != null &&
                        petition.stationName!.isNotEmpty)
                      _buildDetailRow('Police Station', petition.stationName!),
                    if (petition.incidentAddress != null &&
                        petition.incidentAddress!.isNotEmpty)
                      _buildDetailRow(
                          'Incident Address', petition.incidentAddress!),
                    if (petition.incidentDate != null)
                      _buildDetailRow('Incident Date',
                          _formatTimestamp(petition.incidentDate!)),
                    if (petition.caseId != null && petition.caseId!.isNotEmpty)
                      _buildDetailRow('Related Case ID', petition.caseId!),
                    if (petition.firNumber != null &&
                        petition.firNumber!.isNotEmpty)
                      _buildDetailRow('FIR Number', petition.firNumber!),

                    const SizedBox(height: 16),

                    // Grounds Section
                    if (petition.grounds.isNotEmpty) ...[
                      const Text(
                        'Grounds',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          petition.grounds,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Prayer/Relief Section
                    if (petition.prayerRelief != null &&
                        petition.prayerRelief!.isNotEmpty) ...[
                      const Text(
                        'Prayer/Relief Sought',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          petition.prayerRelief!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Dates Section
                    const Text(
                      'Important Dates',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        'Created At', _formatTimestamp(petition.createdAt)),
                    _buildDetailRow(
                        'Last Updated', _formatTimestamp(petition.updatedAt)),
                    if (petition.filingDate != null &&
                        petition.filingDate!.isNotEmpty)
                      _buildDetailRow('Filing Date', petition.filingDate!),
                    if (petition.nextHearingDate != null &&
                        petition.nextHearingDate!.isNotEmpty)
                      _buildDetailRow(
                          'Next Hearing Date', petition.nextHearingDate!),
                    if (petition.orderDate != null &&
                        petition.orderDate!.isNotEmpty)
                      _buildDetailRow('Order Date', petition.orderDate!),

                    const SizedBox(height: 16),

                    // Police Status Section
                    const Text(
                      'Police Status',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (petition.policeStatus != null)
                      _buildDetailRow('Status', petition.policeStatus!),
                    if (petition.policeSubStatus != null)
                      _buildDetailRow('Sub Status', petition.policeSubStatus!),

                    const SizedBox(height: 16),

                    const Text(
                      'Police Status Update',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: ['Received', 'In Progress', 'Closed']
                              .contains(selectedStatus)
                          ? selectedStatus
                          : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Status',
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Received', child: Text('Received')),
                        DropdownMenuItem(
                            value: 'In Progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                      ],
                      onChanged: (v) => setModal(() => selectedStatus = v),
                    ),

                    if (selectedStatus == 'Closed') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSubStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Closure Type',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Rejected', child: Text('Rejected')),
                          DropdownMenuItem(
                              value: 'FIR Registered',
                              child: Text('FIR Registered')),
                          DropdownMenuItem(
                              value: 'Compromised / Disposed',
                              child: Text('Compromised / Disposed')),
                        ],
                        onChanged: (v) => setModal(() => selectedSubStatus = v),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // AI Investigation Guidelines Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close the modal first
                          
                          // Navigate to AI Investigation Guidelines
                          if (petition.caseId != null && petition.caseId!.isNotEmpty) {
                            context.go(
                              '/ai-investigation-guidelines',
                              extra: {'caseId': petition.caseId},
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No case ID associated with this petition'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.psychology, size: 20),
                        label: const Text(
                          'AI Investigation Guidelines',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Register FIR Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close the modal first

                          // Prepare data for navigation - convert Timestamp to Map for serialization
                          final Map<String, dynamic> petitionData = {};

                          // Use case_id from petition (not petition.id)
                          if (petition.caseId != null &&
                              petition.caseId!.isNotEmpty) {
                            petitionData['caseId'] = petition.caseId;
                            debugPrint(
                                '✅ Using petition.caseId: ${petition.caseId}');
                          } else if (petition.id != null &&
                              petition.id!.isNotEmpty) {
                            // Fallback to petition.id if caseId is not available
                            petitionData['caseId'] = petition.id;
                            debugPrint(
                                '⚠️ Using petition.id as fallback: ${petition.id}');
                          }

                          // Map petition fields to FIR form fields
                          if (petition.title.isNotEmpty) {
                            petitionData['title'] = petition.title;
                          }
                          if (petition.petitionerName.isNotEmpty) {
                            petitionData['petitionerName'] =
                                petition.petitionerName;
                          }
                          if (petition.phoneNumber != null &&
                              petition.phoneNumber!.isNotEmpty) {
                            petitionData['phoneNumber'] = petition.phoneNumber;
                          }
                          // grounds maps to complaint narrative in FIR
                          if (petition.grounds.isNotEmpty) {
                            petitionData['grounds'] = petition.grounds;
                          }
                          if (petition.district != null &&
                              petition.district!.isNotEmpty) {
                            petitionData['district'] = petition.district;
                          }
                          if (petition.stationName != null &&
                              petition.stationName!.isNotEmpty) {
                            petitionData['stationName'] = petition.stationName;
                          }
                          if (petition.incidentAddress != null &&
                              petition.incidentAddress!.isNotEmpty) {
                            petitionData['incidentAddress'] =
                                petition.incidentAddress;
                          }
                          if (petition.address != null &&
                              petition.address!.isNotEmpty) {
                            petitionData['address'] = petition.address;
                          }

                          // Convert Timestamp to serializable format
                          if (petition.incidentDate != null) {
                            petitionData['incidentDate'] = {
                              'seconds': petition.incidentDate!.seconds,
                              'nanoseconds': petition.incidentDate!.nanoseconds,
                            };
                          }

                          debugPrint('🚀 Navigating to new case screen');
                          debugPrint(
                              '📦 Petition data being passed: $petitionData');

                          // Navigate to new case screen with petition data
                          context.go(
                            '/cases/new',
                            extra: petitionData,
                          );
                        },
                        icon: const Icon(Icons.gavel, size: 20),
                        label: const Text(
                          'Register FIR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                setModal(() => loading = true);

                                await context
                                    .read<PetitionProvider>()
                                    .updatePetition(
                                  petition.id!,
                                  {
                                    'policeStatus': selectedStatus,
                                    'policeSubStatus': selectedSubStatus,
                                  },
                                  petition.userId,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Status updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Refresh the list
                                  _loadFilteredPetitions();
                                }
                              },
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Submit Update'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: _getFilterColor(widget.filter),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredPetitions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Petitions Found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFilteredPetitions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPetitions.length,
                    itemBuilder: (context, index) {
                      final petition = _filteredPetitions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _getFilterColor(widget.filter)
                                .withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showPetitionDetails(context, petition),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and Police Status
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            petition.title,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[800],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Case ID: ${petition.caseId ?? "N/A"}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: Colors.grey[600],
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getPoliceStatusColor(
                                                petition.policeStatus ??
                                                    'Pending')
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getPoliceStatusColor(
                                              petition.policeStatus ??
                                                  'Pending'),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        petition.policeStatus ?? 'Pending',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: _getPoliceStatusColor(
                                              petition.policeStatus ??
                                                  'Pending'),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Type and Date
                                Row(
                                  children: [
                                    Icon(Icons.category,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      petition.type.displayName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      dateFormat.format(petition.createdAt.toDate()),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                // Petitioner name
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.person,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      petition.petitionerName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                // Station name
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.local_police,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        petition.stationName ?? 'N/A',
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
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
}
