import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AiChatbotDetailsScreen extends StatelessWidget {
  final Map<String, String> answers;
  final String summary;
  final String classification;
  const AiChatbotDetailsScreen({super.key, required this.answers, required this.summary, required this.classification});

  static AiChatbotDetailsScreen fromRouteSettings(BuildContext context, GoRouterState state) {
    final q = state.extra as Map<String, dynamic>?;
    return AiChatbotDetailsScreen(
      answers: q?['answers'] as Map<String, String>? ?? {},
      summary: q?['summary'] as String? ?? '',
      classification: q?['classification'] as String? ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      appBar: AppBar(
        title: const Text('AI Chatbot Details'),
        backgroundColor: const Color(0xFFFC633C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22.0),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            Text('Citizen Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ...answers.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_labelForKey(e.key)}:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 15))),
                ],
              ),
            ))
            .toList(),
            const SizedBox(height: 22),
            Text('Formal Complaint Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!, width: 1.2),
              ),
              child: Text(summary, style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 22),
            Text('=== Offence Classification ===', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!, width: 1.2),
              ),
              child: Text(classification, style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/cognigible-non-cognigible-separation', extra: {
                  'classification': classification,
                  'complaintData': answers, // Pass the answers map
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC633C),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Next', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

String _labelForKey(String key) {
  switch(key) {
    case 'full_name': return 'Full Name';
    case 'address': return 'Address';
    case 'phone': return 'Phone Number';
    case 'complaint_type': return 'Complaint Type';
    case 'details': return 'Details';
    default: return key;
  }
}
