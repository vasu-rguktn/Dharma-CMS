// lib/screens/petitions/widgets/petition_details.dart
import 'package:flutter/material.dart';
import 'package:Dharma/models/petition.dart';

class PetitionDetails extends StatelessWidget {
  final Petition petition;
  const PetitionDetails({super.key, required this.petition});

  Color _statusColor(PetitionStatus s) => switch (s) {
        PetitionStatus.draft => Colors.grey,
        PetitionStatus.filed => Colors.blue,
        PetitionStatus.underReview => Colors.orange,
        PetitionStatus.hearingScheduled => Colors.purple,
        PetitionStatus.granted => Colors.green,
        PetitionStatus.rejected => Colors.red,
        PetitionStatus.withdrawn => Colors.brown,
      };

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
            Expanded(child: Text(value)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(petition.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _statusColor(petition.status), borderRadius: BorderRadius.circular(12)),
              child: Text(petition.status.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 32),
            _row('Petitioner', petition.petitionerName),
            if (petition.phoneNumber != null) _row('Phone', petition.phoneNumber!),
            if (petition.address != null) _row('Address', petition.address!),
            if (petition.firNumber != null) _row('FIR Number', petition.firNumber!),
            const SizedBox(height: 16),
            const Text('Grounds', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(petition.grounds),
            if (petition.prayerRelief != null) ...[
              const SizedBox(height: 16),
              const Text('Prayer / Relief', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(petition.prayerRelief!),
            ],
            if (petition.filingDate != null) _row('Filing Date', petition.filingDate!),
            if (petition.nextHearingDate != null) _row('Next Hearing', petition.nextHearingDate!),
            if (petition.orderDate != null) _row('Order Date', petition.orderDate!),
            if (petition.orderDetails != null) ...[
              const SizedBox(height: 16),
              const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(petition.orderDetails!),
            ],
            if (petition.extractedText?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              const Text('Extracted Text', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                child: Text(petition.extractedText!, style: const TextStyle(fontSize: 14, height: 1.4)),
              ),
            ] else ...[
              const SizedBox(height: 16),
              const Text('Extracted Text', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('No Documents Uploaded...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}