import 'package:flutter/material.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/l10n/app_localizations.dart';

class PetitionDetailBottomSheet {
  static void show(BuildContext context, Petition petition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: _DetailContent(petition: petition),
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Petition petition;

  const _DetailContent({required this.petition});

  Color _getStatusColor(PetitionStatus status) {
    switch (status) {
      case PetitionStatus.draft: return Colors.grey;
      case PetitionStatus.filed: return Colors.blue;
      case PetitionStatus.underReview: return Colors.orange;
      case PetitionStatus.hearingScheduled: return Colors.purple;
      case PetitionStatus.granted: return Colors.green;
      case PetitionStatus.rejected: return Colors.red;
      case PetitionStatus.withdrawn: return Colors.brown;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                petition.title,
                style: theme.textTheme.headlineSmall?.copyWith(
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(petition.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            petition.status.displayName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 32),

        _buildDetailRow(localizations.petitioner, petition.petitionerName),
        if (petition.phoneNumber != null)
          _buildDetailRow(localizations.phone, petition.phoneNumber!),
        if (petition.address != null)
          _buildDetailRow(localizations.address, petition.address!),
        if (petition.firNumber != null)
          _buildDetailRow(localizations.firNumber, petition.firNumber!),

        const SizedBox(height: 16),
        Text(localizations.grounds, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(petition.grounds),

        if (petition.prayerRelief != null) ...[
          const SizedBox(height: 16),
          Text(localizations.prayerReliefSought, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(petition.prayerRelief!),
        ],

        if (petition.filingDate != null)
          _buildDetailRow(localizations.filingDate, petition.filingDate!),
        if (petition.nextHearingDate != null)
          _buildDetailRow(localizations.nextHearing, petition.nextHearingDate!),
        if (petition.orderDate != null)
          _buildDetailRow(localizations.orderDate, petition.orderDate!),

        if (petition.orderDetails != null) ...[
          const SizedBox(height: 16),
          Text(localizations.orderDetails, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(petition.orderDetails!),
        ],

        if (petition.extractedText != null && petition.extractedText!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(localizations.extractedTextFromDocuments, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(petition.extractedText!, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Text(localizations.extractedTextFromDocuments, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(localizations.noDocumentsUploaded, style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }
}