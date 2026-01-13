// lib/screens/petition/petition_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/complaint_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import existing components
import 'petition_card.dart';
import 'petition_detail_bottom_sheet.dart';

/// Citizen Petition List Screen
/// Shows filtered petitions for the citizen and allows viewing details
class CitizenPetitionListScreen extends StatefulWidget {
  final PetitionFilter filter;
  final String title;

  const CitizenPetitionListScreen({
    super.key,
    required this.filter,
    required this.title,
  });

  @override
  State<CitizenPetitionListScreen> createState() =>
      _CitizenPetitionListScreenState();
}

class _CitizenPetitionListScreenState extends State<CitizenPetitionListScreen> {
  bool _isLoading = true;

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
    final complaintProvider =
        Provider.of<ComplaintProvider>(context, listen: false);

    final userId = authProvider.user?.uid;
    if (userId != null) {
      // Fetch petitions
      await petitionProvider.fetchFilteredPetitions(
        isPolice: false,
        userId: userId,
        filter: widget.filter,
      );
      // Fetch complaints (to know what is saved)
      await complaintProvider.fetchComplaints(userId: userId);
    }

    setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: _getFilterColor(widget.filter),
        foregroundColor: Colors.white,
      ),
      body: Consumer<PetitionProvider>(
        builder: (context, petitionProvider, _) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (petitionProvider.petitions.isEmpty) {
            return Center(
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
            );
          }

          return RefreshIndicator(
            onRefresh: _loadFilteredPetitions,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: petitionProvider.petitions.length,
              itemBuilder: (context, index) {
                final petition = petitionProvider.petitions[index];
                // Use the existing PetitionCard component
                return PetitionCard(
                  petition: petition,
                  formatTimestamp: _formatTimestamp,
                  // Use the existing PetitionDetailBottomSheet
                  onTap: () =>
                      PetitionDetailBottomSheet.show(context, petition),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
