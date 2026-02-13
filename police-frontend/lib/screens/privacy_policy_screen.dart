import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFFFC633C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFC633C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last Updated: February 13, 2026',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Information We Collect',
              'DHARMA collects various types of information to provide and improve our Case Management services:\n\n• Personal Information: Name, phone number, email address, and physical address or location data.\n• Case-Related Content: Case descriptions, incident details, images, voice notes, documents, and other file attachments you upload.\n• Authentication Data: Login credentials managed through Firebase Authentication.\n• Automated Data: Device information, IP address, and app usage statistics.',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use the collected information to:\n\n• Provide and improve our legal assistance services.\n• Personalize your experience within the app.\n• Communicate with you regarding updates or support.\n• Ensure the security and integrity of our platform.',
            ),
            _buildSection(
              '3. Data Sharing and Access',
              'We do not sell your personal information. Data is shared only to:\n\n• Authorized Law Enforcement: Case details are accessible to authorized police personnel for investigation.\n• Service Providers: We use Google Firebase for backend services.\n• Legal Requirements: If required by law or to respond to valid legal requests.',
            ),
            _buildSection(
              '4. Data Security',
              'We implement robust security measures, including encryption in transit and at rest (via Firebase), to maintain the safety of your personal information. However, no method of transmission over the internet is 100% secure.',
            ),
            _buildSection(
              '5. AI and Automated Processing',
              'DHARMA uses AI features to assist in organizing, summarizing, and prioritizing cases. These automated processes help in efficient case management but do not replace final human judgment by authorized officials.',
            ),
            _buildSection(
              '6. Data Retention and Deletion',
              'We retain your personal data and case information for as long as necessary to fulfill legal or reporting requirements. Users may request account and data deletion by contacting us at the email provided below.',
            ),
            _buildSection(
              '7. Children\'s Privacy',
              'DHARMA is not intended for use by children under the age of 13. We do not knowingly collect personal information from children.',
            ),
            _buildSection(
              '8. Your Rights',
              'You have the right to access, correct, or delete your personal information. You can manage certain aspects of your data within the app settings or by contacting our support team.',
            ),
            _buildSection(
              '9. Changes to This Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page.',
            ),
            _buildSection(
              '10. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at Itcoreeluru@gmail.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
