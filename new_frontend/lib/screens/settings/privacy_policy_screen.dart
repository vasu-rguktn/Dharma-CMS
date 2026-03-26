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
              'AP Dharma CMS — Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Last updated: March 2026', style: TextStyle(color: Colors.grey[600])),
            const Divider(height: 32),

            _section('1. Information We Collect',
              'We collect information you provide directly: name, email, phone number, '
              'Aadhaar number (optional), and address. When you submit a petition, we '
              'collect case details, incident information, and any documents you upload.'),

            _section('2. How We Use Your Information',
              '• To create and manage your account\n'
              '• To process petitions and track their status\n'
              '• To communicate with police authorities on your behalf\n'
              '• To provide AI-assisted legal guidance\n'
              '• To send status updates and notifications\n'
              '• To improve our services'),

            _section('3. Data Storage & Security',
              'Your data is stored securely in encrypted databases. We use Firebase '
              'Authentication for identity management and encrypted API communication. '
              'All data transmission uses HTTPS/TLS encryption.'),

            _section('4. Data Sharing',
              'We share petition information with the relevant police authorities '
              '(district police, station officers) for processing. We do NOT sell or '
              'share your personal information with third parties for commercial purposes.'),

            _section('5. Anonymous Petitions',
              'You may file anonymous petitions. When anonymous, your identity information '
              'is not shared with police authorities. However, anonymous petitions may '
              'receive limited processing.'),

            _section('6. Your Rights',
              '• Access your personal data\n'
              '• Correct inaccurate information\n'
              '• Request deletion of your account\n'
              '• Withdraw petitions\n'
              '• Opt out of non-essential communications'),

            _section('7. Data Retention',
              'Petition data is retained for the duration required by government regulations. '
              'Account data is retained until you request deletion. Deleted accounts are '
              'purged within 30 days.'),

            _section('8. Children\'s Privacy',
              'Our services are not directed at individuals under 18. If you are under 18, '
              'please submit petitions through a parent or guardian.'),

            _section('9. Changes to This Policy',
              'We may update this privacy policy periodically. Significant changes will be '
              'communicated via the app notification system.'),

            _section('10. Contact',
              'For privacy-related inquiries:\n'
              'Email: apdharmacms@gmail.com\n'
              'Subject: Privacy Inquiry — AP Dharma CMS'),

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
