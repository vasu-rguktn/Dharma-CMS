// lib/screens/legal_suggestion_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enterFirAndIncidentDetails),
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
            content: Text(AppLocalizations.of(context)!.legalSuggestionsGenerated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToGenerateSuggestions(error.toString())),
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
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    const Color orange = Color(0xFFFC633C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // SAME BEAUTIFUL HEADER: Orange Arrow + Title
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
              child: Row(
                children: [
                  // PURE ORANGE BACK ARROW — NO BACKGROUND
                  GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: orange,
                        size: 32,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Title
                  Expanded(
                    child: Text(
                      localizations.legalSectionSuggester,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 24, 24),
              child: Text(
                localizations.provideFirDetailsDesc,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),

            // MAIN SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Input Card
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.gavel, color: orange, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  localizations.legalSectionSuggester,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Text(
                              localizations.firDetails,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _firDetailsController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: localizations.enterFirDetailsHint,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              localizations.incidentDetails,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _incidentDetailsController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: localizations.describeIncidentHint,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _handleSubmit,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.send_rounded),
                                label: Text(_isLoading ? localizations.processing : localizations.getLegalSuggestions),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Loading State
                    if (_isLoading) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            const CircularProgressIndicator(color: orange),
                            const SizedBox(height: 16),
                            Text(
                              localizations.analyzingInformation,
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Result Card
                    if (_suggestion != null) ...[
                      const SizedBox(height: 32),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb, color: orange, size: 28),
                                  const SizedBox(width: 12),
                                  Text(
                                    localizations.aiLegalSuggestions,
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _buildResultBox(
                                title: localizations.suggestedSections,
                                content: _suggestion!['suggestedSections'] ?? localizations.noSectionsSuggested,
                              ),
                              const SizedBox(height: 20),

                              _buildResultBox(
                                title: localizations.reasoning,
                                content: _suggestion!['reasoning'] ?? localizations.noReasoningProvided,
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      localizations.aiDisclaimer,
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBox({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
      ],
    );
  }
}