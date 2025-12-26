// lib/widgets/petition_list_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:intl/intl.dart';



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

  Widget _buildPetitionCard(BuildContext context, Petition petition) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(widget.filter).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).pop();
          // Navigate to petition details if needed
          // GoRouter.of(context).push('/petition-details/${petition.id}');
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
                        const SizedBox(height: 4),
                        Text(
                          'Case ID: ${petition.caseId ?? "N/A"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.filter).withValues(alpha: 0.1),
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
    }
  }
}
