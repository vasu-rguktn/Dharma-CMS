// lib/screens/petitions/widgets/petition_card.dart
import 'package:flutter/material.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetitionCard extends StatelessWidget {
  final Petition petition;
  final VoidCallback onTap;
  final String Function(Timestamp) formatTimestamp;

  const PetitionCard({
    super.key,
    required this.petition,
    required this.onTap,
    required this.formatTimestamp,
  });

  Color _statusColor(PetitionStatus s) => switch (s) {
        PetitionStatus.draft => Colors.grey,
        PetitionStatus.filed => Colors.blue,
        PetitionStatus.underReview => Colors.orange,
        PetitionStatus.hearingScheduled => Colors.purple,
        PetitionStatus.granted => Colors.green,
        PetitionStatus.rejected => Colors.red,
        PetitionStatus.withdrawn => Colors.brown,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    child: Text(petition.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _statusColor(petition.status), borderRadius: BorderRadius.circular(12)),
                    child: Text(petition.status.displayName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [const Icon(Icons.person, size: 16), const SizedBox(width: 4), Expanded(child: Text(petition.petitionerName, overflow: TextOverflow.ellipsis))]),
              if (petition.phoneNumber != null) ...[
                const SizedBox(height: 4),
                Row(children: [const Icon(Icons.phone, size: 16), const SizedBox(width: 4), Text(petition.phoneNumber!)]),
              ],
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text('Created: ${formatTimestamp(petition.createdAt)}', style: const TextStyle(fontSize: 11)),
                if (petition.nextHearingDate != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.event, size: 14, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text('Next: ${petition.nextHearingDate}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }
}