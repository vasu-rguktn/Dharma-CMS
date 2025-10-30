import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

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

  // Primary Orange Color (#FC633C)
  static const Color primaryOrange = Color(0xFFFC633C);

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
        const SnackBar(
          content: Text('Please fill in all fields: case details, witness statement, and witness name.'),
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
            content: const Text('Witness preparation session complete.'),
            backgroundColor: primaryOrange,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to conduct witness preparation session: $error'),
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
                        Icon(Icons.people, color: primaryOrange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI Witness Preparation',
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
                      'Simulate a mock trial experience for a witness. The AI assistant will ask potential cross-examination questions.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Witness Name',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _witnessNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter the witness\'s full name',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryOrange, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Case Details',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _caseDetailsController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText:
                            'Provide comprehensive case details: charges, evidence, known facts, etc.',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryOrange, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Witness Statement',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _witnessStatementController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText:
                            'Enter the witness\'s statement that will be used for the mock trial.',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryOrange, width: 2),
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
                            : const Icon(Icons.play_arrow),
                        label: Text(_isLoading ? 'Preparing...' : 'Start Mock Trial'),
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
                      'Preparing mock trial session...',
                      style: TextStyle(color: primaryOrange),
                    ),
                  ],
                ),
              ),
            ],

            // Result Card
            if (_preparationResult != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.message, color: primaryOrange, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Mock Trial & Feedback',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryOrange,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Review the mock trial transcript and AI feedback for witness ${_witnessNameController.text}.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Mock Trial Transcript',
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
                        height: 300,
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryOrange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryOrange.withOpacity(0.3)),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _preparationResult!['mockTrialTranscript'] ??
                                'No transcript available',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontFamily: 'monospace',
                                  color: Colors.black87,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Potential Weaknesses',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Text(
                          _preparationResult!['potentialWeaknesses'] ??
                              'No weaknesses identified',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.red[900],
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Suggested Improvements',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Text(
                          _preparationResult!['suggestedImprovements'] ??
                              'No improvements suggested',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green[900],
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: primaryOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This is an AI simulation. Real trial conditions may vary.',
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