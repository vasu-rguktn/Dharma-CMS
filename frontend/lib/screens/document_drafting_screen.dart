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
      // TODO: Replace with your actual API endpoint
      final response = await _dio.post(
        '/api/document-drafting',
        data: {
          'caseData': _caseDataController.text,
          'recipientType': _recipientType,
          'additionalInstructions': _additionalInstructionsController.text.trim().isEmpty
              ? null
              : _additionalInstructionsController.text,
        },
      );

      setState(() {
        _draft = response.data;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document draft generated.'),
            backgroundColor: Colors.green,
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
                      Icon(Icons.edit_document, color: theme.primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'AI Document Drafter',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate document drafts based on case data for specific recipients like medical officers or forensic experts.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Case Data',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _caseDataController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: 'Paste all relevant case data: complaint transcripts, witness statements, FIR details, investigation notes, etc...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Recipient Type',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _recipientType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _additionalInstructionsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'E.g., \'Focus on injuries sustained\', \'Request specific tests for DNA analysis\', \'Keep the tone formal and urgent\'...',
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
                          : const Icon(Icons.create),
                      label: Text(_isLoading ? 'Drafting...' : 'Draft Document'),
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
                  Text('Drafting document, please wait...'),
                ],
              ),
            ),
          ],
          
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review the generated draft. You can copy and edit it as needed.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SelectableText(
                        _draft!['draft'] ?? 'No draft generated',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'AI-generated content. Verify and adapt for official use.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Copy to clipboard functionality would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Draft copied to clipboard'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
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
    );
  }
}
