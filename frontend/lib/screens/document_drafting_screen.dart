import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class DocumentDraftingScreen extends StatefulWidget {
  const DocumentDraftingScreen({super.key});

  @override
  State<DocumentDraftingScreen> createState() => _DocumentDraftingScreenState();
}

class _DocumentDraftingScreenState extends State<DocumentDraftingScreen> {
  final _caseDataController = TextEditingController();
  final _additionalInstructionsController = TextEditingController();
  final _dio = Dio();

  String? _recipientType;
  bool _isLoading = false;
  Map<String, dynamic>? _draft;

  // Primary Orange Color (#FC633C)
  static const Color primaryOrange = Color(0xFFFC633C);

  @override
  void dispose() {
    _caseDataController.dispose();
    _additionalInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_caseDataController.text.trim().isEmpty || _recipientType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide case data and select a recipient type.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _draft = null;
    });

    try {
      final response = await _dio.post(
        '/api/document-drafting',
        data: {
          'caseData': _caseDataController.text,
          'recipientType': _recipientType,
          'additionalInstructions':
              _additionalInstructionsController.text.trim().isEmpty
                  ? null
                  : _additionalInstructionsController.text,
        },
      );

      setState(() {
        _draft = response.data;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Document draft generated.'),
            backgroundColor: primaryOrange,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate document draft: $error'),
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
                        Icon(Icons.edit_document, color: primaryOrange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI Document Drafter',
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
                      'Generate document drafts based on case data for specific recipients like medical officers or forensic experts.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Case Data',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _caseDataController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        hintText:
                            'Paste all relevant case data: complaint transcripts, witness statements, FIR details, investigation notes, etc...',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: primaryOrange, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Recipient Type',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _recipientType,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: primaryOrange, width: 2),
                        ),
                        hintText: 'Select recipient type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'medical officer',
                          child: Text('Medical Officer'),
                        ),
                        DropdownMenuItem(
                          value: 'forensic expert',
                          child: Text('Forensic Expert'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _recipientType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Additional Instructions (Optional)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _additionalInstructionsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'E.g., \'Focus on injuries sustained\', \'Request specific tests for DNA analysis\', \'Keep the tone formal and urgent\'...',
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
                            : const Icon(Icons.create),
                        label: Text(_isLoading ? 'Drafting...' : 'Draft Document'),
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
                      'Drafting document, please wait...',
                      style: TextStyle(color: primaryOrange),
                    ),
                  ],
                ),
              ),
            ],

            // Result Card
            if (_draft != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generated Document Draft',
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
                        'Review the generated draft. You can copy and edit it as needed.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryOrange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: primaryOrange.withOpacity(0.3)),
                        ),
                        child: SelectableText(
                          _draft!['draft'] ?? 'No draft generated',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  color: primaryOrange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'AI-generated content. Verify and adapt for official use.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement clipboard copy
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Draft copied to clipboard'),
                                  backgroundColor: primaryOrange,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryOrange,
                              side: BorderSide(color: primaryOrange),
                            ),
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy Draft'),
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