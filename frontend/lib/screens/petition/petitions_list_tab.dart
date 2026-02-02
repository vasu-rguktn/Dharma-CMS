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

  const PetitionsListTab({
    super.key,
    required this.onRefresh,
    required this.formatTimestamp,
    this.initialPetitionId,
  });

  @override
  State<PetitionsListTab> createState() => _PetitionsListTabState();
}

class _PetitionsListTabState extends State<PetitionsListTab> {
  bool _hasAutoOpened = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Auto-open petition if coming from notification
    if (!_hasAutoOpened && widget.initialPetitionId != null) {
      _hasAutoOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoOpenPetition());
    }
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

        if (provider.petitions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(localizations.noPetitionsYet,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text(
                  localizations.createFirstPetition,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.petitions.length,
            itemBuilder: (_, i) {
              final petition = provider.petitions[i];
              return PetitionCard(
                petition: petition,
                formatTimestamp: widget.formatTimestamp,
                onTap: () => PetitionDetailBottomSheet.show(context, petition),
              );
            },
          ),
        );
      },
    );
  }
}