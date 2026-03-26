import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AP Dharma CMS — Police Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Last updated: March 2026', style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 32),

            _section('1. Officer Data Collection',
              'We collect your official information: name, rank, badge number, station, '
              'district, email, and phone number. This data is used for authentication, '
              'case assignment, and official communication.'),

            _section('2. Case & Petition Data',
              'All case and petition data processed through this system is official police '
              'data. Access is restricted by role and jurisdiction. Unauthorized access '
              'is logged and may result in disciplinary action.'),

            _section('3. AI-Assisted Tools',
              'AI tools (chargesheet generation, legal research, investigation support) '
              'process case data locally through secure APIs. AI outputs are suggestions '
              'only and must be reviewed by authorized officers.'),

            _section('4. Data Security',
              '• All API communication uses HTTPS/TLS encryption\n'
              '• Firebase Authentication for identity verification\n'
              '• Role-based access control (RBAC) enforced at API level\n'
              '• Session tokens expire after inactivity\n'
              '• All access is logged for audit purposes'),

            _section('5. Access Control',
              'Data access is restricted by police hierarchy:\n'
              '• Station-level officers see only their station\'s data\n'
              '• SDPO/Circle officers see their jurisdiction\'s data\n'
              '• District SP sees district-wide data\n'
              '• DGP/Admin has state-level access'),

            _section('6. Audit Trail',
              'All actions (case updates, petition processing, AI tool usage) are logged '
              'with timestamps and officer identity. These logs are retained for compliance.'),

            _section('7. Contact',
              'For privacy or security concerns:\n'
              'Email: apdharmacms@gmail.com\n'
              'Subject: Police Privacy — AP Dharma CMS'),

            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2026 AP Dharma CMS — Andhra Pradesh Police',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}
