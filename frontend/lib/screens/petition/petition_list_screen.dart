// lib/screens/petition/petition_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/complaint_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import existing components
import 'package:Dharma/models/petition.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFilteredPetitions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      case PetitionFilter.escalated:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filterColor = _getFilterColor(widget.filter);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: filterColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<PetitionProvider>(
        builder: (context, petitionProvider, _) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter petitions based on search query
          final filteredPetitions =
              petitionProvider.petitions.where((petition) {
            final query = _searchQuery.toLowerCase();
            final title = petition.title.toLowerCase();
            final id = (petition.id ?? '').toLowerCase();
            final status = petition.status.displayName.toLowerCase();

            return title.contains(query) ||
                id.contains(query) ||
                status.contains(query);
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title, ID or status...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: filterColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),

              // Filtered List
              Expanded(
                child: filteredPetitions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No Petitions Found'
                                  : 'No results found for "$_searchQuery"',
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: filteredPetitions.length,
                          itemBuilder: (context, index) {
                            final petition = filteredPetitions[index];
                            // Use the existing PetitionCard component
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: PetitionCard(
                                petition: petition,
                                formatTimestamp: _formatTimestamp,
                                // Use the existing PetitionDetailBottomSheet
                                onTap: () => PetitionDetailBottomSheet.show(
                                    context, petition),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
