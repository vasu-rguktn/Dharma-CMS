// lib/widgets/petition_list_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/models/petition_update.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:Dharma/widgets/petition_update_timeline.dart';
import 'package:Dharma/widgets/add_petition_update_dialog.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetitionListModal extends StatefulWidget {
  final PetitionFilter filter;
  final bool isPolice;
  final String title;

  const PetitionListModal({
    super.key,
    required this.filter,
    required this.isPolice,
    required this.title,
  });

  @override
  State<PetitionListModal> createState() => _PetitionListModalState();
}

class _PetitionListModalState extends State<PetitionListModal> {
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

    // Fetch filtered petitions based on role
    if (widget.isPolice) {
      final stationName = authProvider.userProfile?.stationName;
      if (stationName != null) {
        await petitionProvider.fetchFilteredPetitions(
          isPolice: true,
          stationName: stationName,
          filter: widget.filter,
        );
      }
    } else {
      final userId = authProvider.user?.uid;
      if (userId != null) {
        await petitionProvider.fetchFilteredPetitions(
          isPolice: false,
          userId: userId,
          filter: widget.filter,
        );
      }
    }

    setState(() {
      _filteredPetitions = petitionProvider.petitions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.filter),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(widget.filter),
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredPetitions.length,
                          itemBuilder: (context, index) {
                            final petition = _filteredPetitions[index];
                            return _buildPetitionCard(context, petition);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPetitionDetailsForPolice(BuildContext context, Petition petition) {
    final authProvider = context.read<AuthProvider>();
    final policeOfficerName =
        authProvider.userProfile?.displayName ?? 'Officer';
    final policeOfficerUserId = authProvider.user?.uid ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        builder: (_, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        petition.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),

                // Basic Info
                const SizedBox(height: 16),
                _buildInfoRow('Petitioner', petition.petitionerName),
                _buildInfoRow('Type', petition.type.displayName),
                _buildInfoRow('Status', petition.policeStatus ?? 'Pending'),
                if (petition.stationName != null)
                  _buildInfoRow('Station', petition.stationName!),

                const SizedBox(height: 24),
                const Divider(),

                // Timeline Section
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Case Updates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) => AddPetitionUpdateDialog(
                            petition: petition,
                            policeOfficerName: policeOfficerName,
                            policeOfficerUserId: policeOfficerUserId,
                          ),
                        );
                        // Refresh if update was added
                        if (result == true) {
                          // The StreamBuilder will automatically update
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Timeline with real-time updates
                StreamBuilder<List<PetitionUpdate>>(
                  stream: context
                      .read<PetitionProvider>()
                      .streamPetitionUpdates(petition.id!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Error loading updates: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final updates = snapshot.data ?? [];
                    return PetitionUpdateTimeline(updates: updates);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
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

  Widget _buildPetitionCard(BuildContext context, Petition petition) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(widget.filter).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Show petition details with timeline for police
          if (widget.isPolice) {
            _showPetitionDetailsForPolice(context, petition);
          } else {
            // For citizens, just close and navigate
            Navigator.of(context).pop();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Case ID
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
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.filter).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(widget.filter),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      petition.policeStatus ?? 'Pending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(widget.filter),
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
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    petition.type.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(petition.createdAt.toDate()),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),

              // Show petitioner name for police
              if (widget.isPolice) ...[
                const SizedBox(height: 8),
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
              ],

              // Station name for both
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_police, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      petition.stationName ?? 'N/A',
                      style: theme.textTheme.bodyMedium?.copyWith(
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
  }

  Color _getStatusColor(PetitionFilter filter) {
    switch (filter) {
      case PetitionFilter.all:
        return Colors.deepPurple;
      case PetitionFilter.received:
        return Colors.blue.shade700;
      case PetitionFilter.inProgress:
        return Colors.orange.shade700;
      case PetitionFilter.closed:
        return Colors.green.shade700;
      case PetitionFilter.escalated:
        return Colors.red.shade700;
    }
  }

  IconData _getStatusIcon(PetitionFilter filter) {
    switch (filter) {
      case PetitionFilter.all:
        return Icons.gavel;
      case PetitionFilter.received:
        return Icons.call_received;
      case PetitionFilter.inProgress:
        return Icons.sync;
      case PetitionFilter.closed:
        return Icons.task_alt;
      case PetitionFilter.escalated:
        return Icons.trending_up;
    }
  }
}
