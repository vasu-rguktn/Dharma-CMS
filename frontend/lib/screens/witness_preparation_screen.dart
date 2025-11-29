// lib/screens/witness_preparation_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

class WitnessPreparationScreen extends StatefulWidget {
  const WitnessPreparationScreen({super.key});

  @override
  State<WitnessPreparationScreen> createState() => _WitnessPreparationScreenState();
}

class _WitnessPreparationScreenState extends State<WitnessPreparationScreen> {
  final _caseDetailsController = TextEditingController();
  final _witnessStatementController = TextEditingController();
  final _witnessNameController = TextEditingController();
  final _dio = Dio();

  bool _isLoading = false;
  Map<String, dynamic>? _preparationResult;

  @override
  void dispose() {
    _caseDetailsController.dispose();
    _witnessStatementController.dispose();
    _witnessNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_caseDetailsController.text.trim().isEmpty ||
        _witnessStatementController.text.trim().isEmpty ||
        _witnessNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseFillAllWitnessFields),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _preparationResult = null;
    });

    try {
      final response = await _dio.post(
        '/api/witness-preparation',
        data: {
          'caseDetails': _caseDetailsController.text,
          'witnessStatement': _witnessStatementController.text,
          'witnessName': _witnessNameController.text,
        },
      );

      setState(() {
        _preparationResult = response.data;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.witnessPreparationComplete),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToPrepareWitness(error.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    const Color orange = Color(0xFFFC633C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // PREMIUM HEADER: Orange Arrow + Title
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: orange,
                        size: 32,
                        shadows: const [
                          Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations.aiWitnessPreparation,
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
                localizations.witnessPreparationDesc,
                style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.4),
              ),
            ),

            // MAIN CONTENT
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
                                Icon(Icons.people_alt_rounded, color: orange, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  localizations.aiWitnessPreparation,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            _buildLabel("Witness Name"),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _witnessNameController,
                              decoration: InputDecoration(
                                hintText: localizations.enterWitnessNameHint,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildLabel("Case Details"),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _caseDetailsController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: localizations.caseDetailsHint,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),

                            _buildLabel("Witness Statement"),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _witnessStatementController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: localizations.witnessStatementHint,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 32),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _handleSubmit,
                                icon: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.play_circle_fill_rounded),
                                label: Text(_isLoading ? localizations.preparing : localizations.startMockTrial),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Loading
                    if (_isLoading) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: orange),
                            const SizedBox(height: 16),
                            Text(localizations.preparingMockTrialWait, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],

                    // Result
                    if (_preparationResult != null) ...[
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
                                  Icon(Icons.record_voice_over_rounded, color: orange, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      localizations.mockTrialAndFeedback,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                localizations.reviewMockTrialFor(_witnessNameController.text),
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 24),

                              _buildResultSection(
                                icon: Icons.chat_bubble,
                                color: Colors.blue[700]!,
                                title: localizations.mockTrialTranscript,
                                content: _preparationResult!['mockTrialTranscript'] ?? localizations.noTranscriptAvailable,
                              ),
                              const SizedBox(height: 20),

                              _buildResultSection(
                                icon: Icons.warning_rounded,
                                color: Colors.red[700]!,
                                title: localizations.potentialWeaknesses,
                                content: _preparationResult!['potentialWeaknesses'] ?? localizations.noWeaknessesIdentified,
                                bgColor: Colors.red[50]!,
                                borderColor: Colors.red[200]!,
                              ),
                              const SizedBox(height: 20),

                              _buildResultSection(
                                icon: Icons.lightbulb_rounded,
                                color: Colors.green[700]!,
                                title: localizations.suggestedImprovements,
                                content: _preparationResult!['suggestedImprovements'] ?? localizations.noImprovementsSuggested,
                                bgColor: Colors.green[50]!,
                                borderColor: Colors.green[200]!,
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      localizations.aiSimulationDisclaimer,
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

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold));
  }

  Widget _buildResultSection({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
    Color? bgColor,
    Color? borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor ?? Colors.grey[300]!),
          ),
          child: SelectableText(
            content,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
        ),
      ],
    );
  }
}