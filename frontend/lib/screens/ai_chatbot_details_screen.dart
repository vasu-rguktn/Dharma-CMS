import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';

class AiChatbotDetailsScreen extends StatelessWidget {
  final Map<String, String> answers;
  final String summary;
  final String classification;
  final String originalClassification;
  final List<String> evidencePaths; // New field

  const AiChatbotDetailsScreen({
    super.key,
    required this.answers,
    required this.summary,
    required this.classification,
    required this.originalClassification,
    this.evidencePaths = const [], // Default empty
  });

  static AiChatbotDetailsScreen fromRouteSettings(
      BuildContext context, GoRouterState state) {
    final q = state.extra as Map<String, dynamic>?;
    
    // Safely cast the nested map
    final rawAnswers = q?['answers'] as Map<String, dynamic>?;
    final safeAnswers = rawAnswers?.map((k, v) => MapEntry(k, v.toString())) ?? {};

    return AiChatbotDetailsScreen(
      answers: safeAnswers,
      summary: q?['summary'] as String? ?? '',
      classification: q?['classification'] as String? ?? '',
      originalClassification: q?['originalClassification'] as String? ?? '',
      evidencePaths: (q?['evidencePaths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Widget _buildSummaryRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold, // Bold Label
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 15,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             if (context.canPop()) {
               context.pop();
             } else {
               context.go('/dashboard'); // Fallback to home
             }
          },
        ),
        title: Text(
          localizations.aiChatbotDetails,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFC633C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22.0),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            // Citizen Details section removed as per user request

            Text(localizations.formalComplaintSummary,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'FORMAL COMPLAINT SUMMARY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Divider(height: 24, thickness: 1),

                  // Fields
                  _buildSummaryRow('Full Name', answers['full_name']),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Address',
                      answers['address']), // Maps to Resident Address
                  const SizedBox(height: 12),
                  _buildSummaryRow('Phone Number', answers['phone']),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Complaint Type', answers['complaint_type']),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Incident Details',
                      answers['incident_address']), // Short summary
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                      'Details', answers['incident_details']), // Full narrative
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                      'Date of Complaint', answers['date_of_complaint']),
                  if (Provider.of<PetitionProvider>(context).tempEvidence.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: _buildSummaryRow('Attached Evidence', '${Provider.of<PetitionProvider>(context).tempEvidence.length} file(s) attached'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('=== ${localizations.offenceClassification} ===',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
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
                onPressed: () {
                  print('🚀 [DEBUG] Details Screen: Navigating to Separation Screen');
                  context.push('/cognigible-non-cognigible-separation', extra: {
                  'classification': classification,
                  'originalClassification':
                      originalClassification, // Pass it on
                  'complaintData': answers,
                  'evidencePaths': evidencePaths, // FORWARD EVIDENCE
                });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC633C),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(localizations.next,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
