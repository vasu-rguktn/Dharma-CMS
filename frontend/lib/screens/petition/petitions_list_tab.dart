import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
// import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/l10n/app_localizations.dart';

import 'petition_card.dart';
import 'petition_detail_bottom_sheet.dart';

class PetitionsListTab extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final String Function(Timestamp) formatTimestamp;
  final String? initialPetitionId; // For notification deep-linking
  final bool isWeb;
  final TextEditingController searchController;

  const PetitionsListTab({
    super.key,
    required this.onRefresh,
    required this.formatTimestamp,
    this.initialPetitionId,
    required this.isWeb,
    required this.searchController,
  });

  @override
  State<PetitionsListTab> createState() => _PetitionsListTabState();
}

class _PetitionsListTabState extends State<PetitionsListTab> {
  bool _hasAutoOpened = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Listen to parent controller changes
    widget.searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = widget.searchController.text.toLowerCase();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Auto-open petition if coming from notification
    if (!_hasAutoOpened && widget.initialPetitionId != null) {
      _hasAutoOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoOpenPetition());
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _autoOpenPetition() {
    final provider = Provider.of<PetitionProvider>(context, listen: false);
    final petition = provider.petitions.firstWhere(
      (p) => p.id == widget.initialPetitionId,
      orElse: () => provider.petitions.first, // Fallback to first if not found
    );

    if (petition.id != null) {
      debugPrint('[PetitionsListTab] Auto-opening petition: ${petition.id}');
      PetitionDetailBottomSheet.show(context, petition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Consumer<PetitionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final petitions = provider.petitions.where((petition) {
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
            // Only show local search bar on mobile (not web)
            if (!widget.isWeb)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  controller: widget.searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Title, ID, or Petitioner Name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              widget.searchController.clear();
                              // _onSearchChanged will trigger setState
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
                ),
              ),
            Expanded(
              child: petitions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gavel, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matching petitions found'
                                : localizations.noPetitionsYet,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty)
                            Text(
                              localizations.createFirstPetition,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: widget.onRefresh,
                      child: widget.isWeb
                          ? GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio:
                                    2.0, // Slightly improved height
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: petitions.length,
                              itemBuilder: (_, i) {
                                final petition = petitions[i];
                                return PetitionCard(
                                  petition: petition,
                                  formatTimestamp: widget.formatTimestamp,
                                  onTap: () => PetitionDetailBottomSheet.show(
                                      context, petition),
                                );
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: petitions.length,
                              itemBuilder: (_, i) {
                                final petition = petitions[i];
                                return PetitionCard(
                                  petition: petition,
                                  formatTimestamp: widget.formatTimestamp,
                                  onTap: () => PetitionDetailBottomSheet.show(
                                      context, petition),
                                );
                              },
                            ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
