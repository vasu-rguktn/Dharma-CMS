import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
// import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/l10n/app_localizations.dart';

import 'petition_card.dart';
import 'petition_detail_bottom_sheet.dart';

class PetitionsListTab extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final String Function(Timestamp) formatTimestamp;

  const PetitionsListTab({
    super.key,
    required this.onRefresh,
    required this.formatTimestamp,
  });

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
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.petitions.length,
            itemBuilder: (_, i) {
              final petition = provider.petitions[i];
              return PetitionCard(
                petition: petition,
                formatTimestamp: formatTimestamp,
                onTap: () => PetitionDetailBottomSheet.show(context, petition),
              );
            },
          ),
        );
      },
    );
  }
}