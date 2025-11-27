import 'package:flutter/material.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/l10n/app_localizations.dart';

class PetitionCard extends StatelessWidget {
  final Petition petition;
  final String Function(Timestamp) formatTimestamp;
  final VoidCallback onTap;


  const PetitionCard({
    super.key,
    required this.petition,
    required this.formatTimestamp,
    required this.onTap,
  });

  Color _statusColor(PetitionStatus status) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      petition.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor(petition.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      petition.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      petition.petitionerName,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (petition.phoneNumber != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      petition.phoneNumber!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    localizations.createdDate(formatTimestamp(petition.createdAt)),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[500], fontSize: 11),
                  ),
                  if (petition.nextHearingDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.event, size: 14, color: theme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      localizations.nextHearingDate(petition.nextHearingDate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}