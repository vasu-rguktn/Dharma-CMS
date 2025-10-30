import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class LegalSuggestionScreen extends StatefulWidget {
  const LegalSuggestionScreen({super.key});

  @override
  State<LegalSuggestionScreen> createState() => _LegalSuggestionScreenState();
}

class _LegalSuggestionScreenState extends State<LegalSuggestionScreen> {
  final _firDetailsController = TextEditingController();
  final _incidentDetailsController = TextEditingController();
  final _dio = Dio();

  bool _isLoading = false;
  Map<String, dynamic>? _suggestion;

  // ---- NEW: Primary Orange Color (#FC633C) ----
  static const Color primaryOrange = Color(0xFFFC633C);
  // ---------------------------------------------

  @override
  void dispose() {
    _firDetailsController.dispose();
    _incidentDetailsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_firDetailsController.text.trim().isEmpty ||
        _incidentDetailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both FIR and incident details.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestion = null;
    });

    try {
      // TODO: Replace with your actual API endpoint
      final response = await _dio.post(
        '/api/legal-suggestion',
        data: {
          'firDetails': _firDetailsController.text,
          'incidentDetails': _incidentDetailsController.text,
        },
      );

      setState(() {
        _suggestion = response.data;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Legal suggestions generated.'),
            backgroundColor: primaryOrange,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate legal suggestions: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Apply orange theme globally for this screen
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryOrange,
            ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.gavel, color: primaryOrange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Legal Section Suggester',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryOrange,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Provide FIR and incident details to get AI-powered suggestions for applicable legal sections under BNS, BNSS, BSA, and other special acts.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'FIR Details',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _firDetailsController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'Enter comprehensive details from the First Information Report...',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: primaryOrange, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Incident Details',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _incidentDetailsController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText:
                            'Describe the incident in detail, including sequence of events, actions taken, etc...',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: primaryOrange, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isLoading
                            ? 'Processing...'
                            : 'Get Legal Suggestions'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading State
            if (_isLoading) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: primaryOrange),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing information and generating suggestions...',
                      style: TextStyle(color: primaryOrange),
                    ),
                  ],
                ),
              ),
            ],

            // Results Card
            if (_suggestion != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Legal Suggestions',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryOrange,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Review the suggested legal sections and reasoning. This is for informational purposes only.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Suggested Sections',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryOrange,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryOrange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryOrange.withOpacity(0.3)),
                        ),
                        child: Text(
                          _suggestion!['suggestedSections'] ??
                              'No sections suggested',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Reasoning',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryOrange,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryOrange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryOrange.withOpacity(0.3)),
                        ),
                        child: Text(
                          _suggestion!['reasoning'] ?? 'No reasoning provided',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: primaryOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI-generated content. Always consult with a legal expert for official advice.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}