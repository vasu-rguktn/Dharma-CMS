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
      // TODO: Replace with your actual API endpoint
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
          const SnackBar(
            content: Text('Witness preparation session complete.'),
            backgroundColor: Colors.green,
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
    final theme = Theme.of(context);

    return SingleChildScrollView(
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
                      Icon(Icons.people, color: theme.primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI Witness Preparation',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simulate a mock trial experience for a witness. The AI assistant will ask potential cross-examination questions.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Witness Name',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _witnessNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter the witness\'s full name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Case Details',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _caseDetailsController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Provide comprehensive case details: charges, evidence, known facts, etc.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Witness Statement',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _witnessStatementController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: 'Enter the witness\'s statement that will be used for the mock trial.',
                      border: OutlineInputBorder(),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow),
                      label: Text(_isLoading ? 'Preparing...' : 'Start Mock Trial'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading) ...[
            const SizedBox(height: 24),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparing mock trial session...'),
                ],
              ),
            ),
          ],
          
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
                        Icon(Icons.message, color: theme.primaryColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Mock Trial & Feedback',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review the mock trial transcript and AI feedback for witness ${_witnessNameController.text}.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Mock Trial Transcript',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 300,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _preparationResult!['mockTrialTranscript'] ?? 'No transcript available',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Potential Weaknesses',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        _preparationResult!['potentialWeaknesses'] ?? 'No weaknesses identified',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Suggested Improvements',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        _preparationResult!['suggestedImprovements'] ?? 'No improvements suggested',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is an AI simulation. Real trial conditions may vary.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
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
    );
  }
}
