import 'package:flutter/material.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/complaint_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';

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

  Color _statusColor(PetitionStatus status, String? policeStatus) {
    // If policeStatus is available, prioritize it
    if (policeStatus != null && policeStatus.isNotEmpty) {
      switch (policeStatus.toLowerCase()) {
        case 'pending':
          return Colors.orange;
        case 'received':
          return Colors.blue;
        case 'in progress':
          return Colors.indigo;
        case 'closed':
          return Colors.green;
        case 'rejected':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    // Fallback to internal status
    switch (status) {
      case PetitionStatus.draft:
        return Colors.grey;
      case PetitionStatus.filed:
        return Colors.blue;
      case PetitionStatus.underReview:
        return Colors.orange;
      case PetitionStatus.hearingScheduled:
        return Colors.purple;
      case PetitionStatus.granted:
        return Colors.green;
      case PetitionStatus.rejected:
        return Colors.red;
      case PetitionStatus.withdrawn:
        return Colors.brown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    // Determine what text to show: policeStatus takes precedence
    final String displayStatus =
        petition.getLocalizedDisplayStatus(localizations);

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      petition.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // STATUS BADGE
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(
                              petition.status, petition.policeStatus),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          displayStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (petition.isEscalated) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.trending_up,
                                  size: 10, color: Colors.red.shade800),
                              const SizedBox(width: 4),
                              Text(
                                'ESCALATED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      // SAVE BUTTON
                      Consumer<ComplaintProvider>(
                          builder: (context, provider, _) {
                        final isSaved = provider.isPetitionSaved(petition.id);
                        return InkWell(
                          onTap: () async {
                            final auth = Provider.of<AuthProvider>(context,
                                listen: false);
                            final userId = auth.user?.uid;
                            if (userId == null) return;

                            await provider.toggleSaveComplaint(
                                petition.toMap(), userId);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: isSaved ? Colors.orange : Colors.grey,
                              size: 24,
                            ),
                          ),
                        );
                      }),
                    ],
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
                      petition.isAnonymous
                          ? maskPhoneNumber(petition.phoneNumber)
                          : petition.phoneNumber!,
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
                    localizations
                        .createdDate(formatTimestamp(petition.createdAt)),
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
