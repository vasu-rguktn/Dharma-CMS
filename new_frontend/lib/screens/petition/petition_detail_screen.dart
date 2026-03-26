import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dharma/models/petition.dart';
import 'package:dharma/providers/petition_provider.dart';
import 'package:dharma/l10n/app_localizations.dart';

class PetitionDetailScreen extends StatelessWidget {
  final String petitionId;
  const PetitionDetailScreen({super.key, required this.petitionId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = Provider.of<PetitionProvider>(context);
    final petition = provider.petitions.cast<Petition?>().firstWhere(
      (p) => p?.id == petitionId,
      orElse: () => null,
    );

    if (petition == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.petitions)),
        body: const Center(child: Text('Petition not found')),
      );
    }

    final statusColor = _statusColor(petition.policeStatus ?? petition.status.displayName);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      appBar: AppBar(
        title: Text(petition.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (petition.isEscalated)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(
                  'Escalated (Level ${petition.escalationLevel})',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 12, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    petition.policeStatus ?? petition.status.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  if (petition.petitionNumber != null)
                    Text(
                      '#${petition.petitionNumber}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Basic info card ──
            _InfoCard(
              title: 'Petition Details',
              children: [
                _InfoRow('Type', petition.type.displayName),
                _InfoRow('Title', petition.title),
                if (petition.grounds.isNotEmpty) _InfoRow('Grounds', petition.grounds),
                if (petition.prayerRelief != null) _InfoRow('Prayer/Relief', petition.prayerRelief!),
                _InfoRow('Filed', '${petition.createdAt.day}/${petition.createdAt.month}/${petition.createdAt.year}'),
              ],
            ),
            const SizedBox(height: 12),

            // ── Petitioner info ──
            _InfoCard(
              title: 'Petitioner Information',
              children: [
                _InfoRow('Name', petition.isAnonymous ? 'Anonymous' : petition.petitionerName),
                if (!petition.isAnonymous && petition.phoneNumber != null)
                  _InfoRow('Phone', maskPhoneNumber(petition.phoneNumber)),
                if (petition.address != null) _InfoRow('Address', petition.address!),
              ],
            ),
            const SizedBox(height: 12),

            // ── Incident info ──
            if (petition.incidentAddress != null || petition.incidentDate != null || petition.district != null)
              _InfoCard(
                title: 'Incident Details',
                children: [
                  if (petition.district != null) _InfoRow('District', petition.district!),
                  if (petition.stationName != null) _InfoRow('Police Station', petition.stationName!),
                  if (petition.incidentAddress != null) _InfoRow('Address', petition.incidentAddress!),
                  if (petition.incidentDate != null)
                    _InfoRow('Date', '${petition.incidentDate!.day}/${petition.incidentDate!.month}/${petition.incidentDate!.year}'),
                  if (petition.firNumber != null) _InfoRow('FIR Number', petition.firNumber!),
                ],
              ),
            const SizedBox(height: 12),

            // ── Police Status ──
            if (petition.policeStatus != null || petition.policeSubStatus != null)
              _InfoCard(
                title: 'Police Response',
                children: [
                  if (petition.policeStatus != null) _InfoRow('Status', petition.policeStatus!),
                  if (petition.policeSubStatus != null) _InfoRow('Sub-Status', petition.policeSubStatus!),
                ],
              ),
            const SizedBox(height: 12),

            // ── Additional details ──
            if (petition.accusedDetails != null ||
                petition.stolenProperty != null ||
                petition.witnesses != null ||
                petition.evidenceStatus != null)
              _InfoCard(
                title: 'Additional Information',
                children: [
                  if (petition.accusedDetails != null) _InfoRow('Accused Details', petition.accusedDetails!),
                  if (petition.stolenProperty != null) _InfoRow('Stolen Property', petition.stolenProperty!),
                  if (petition.witnesses != null) _InfoRow('Witnesses', petition.witnesses!),
                  if (petition.evidenceStatus != null) _InfoRow('Evidence Status', petition.evidenceStatus!),
                ],
              ),
            const SizedBox(height: 12),

            // ── Escalation warning ──
            if (petition.isEscalated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Petition Escalated',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _escalationMessage(petition.escalationLevel),
                      style: TextStyle(fontSize: 13, color: Colors.red[600]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ── Feedbacks ──
            if (petition.feedbacks != null && petition.feedbacks!.isNotEmpty) ...[
              const Text('Feedbacks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...petition.feedbacks!.map((fb) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    fb['rating'] != null && (fb['rating'] as num) >= 3
                        ? Icons.thumb_up
                        : Icons.thumb_down,
                    color: fb['rating'] != null && (fb['rating'] as num) >= 3
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(fb['comment'] ?? 'No comment'),
                  subtitle: fb['created_at'] != null
                      ? Text(fb['created_at'].toString().substring(0, 10))
                      : null,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  String _escalationMessage(int level) {
    switch (level) {
      case 1:
        return 'This petition has been pending for over 15 days. It has been escalated to the SP level.';
      case 2:
        return 'This petition has been pending for over 30 days. It has been escalated to the IG level.';
      case 3:
        return 'This petition has been pending for over 45 days. It has been escalated to the DGP level.';
      default:
        return 'Escalation pending.';
    }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending') || s.contains('received') || s.contains('draft')) return Colors.blue;
    if (s.contains('progress') || s.contains('investigation') || s.contains('review')) return Colors.orange;
    if (s.contains('closed') || s.contains('resolved') || s.contains('granted')) return Colors.green;
    if (s.contains('rejected') || s.contains('withdrawn')) return Colors.red;
    return Colors.grey;
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
