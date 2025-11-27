import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.provideCaseDataAndRecipient),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.documentDraftGenerated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToGenerateDraft(error.toString())),
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
                          localizations.aiDocumentDrafter,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.documentDraftingDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    localizations.caseData,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _caseDataController,
                    maxLines: 10,
                    decoration: InputDecoration(
                      hintText: localizations.pasteCaseDataHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    localizations.recipientType,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _recipientType,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: localizations.selectRecipientType,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'medical officer',
                        child: Text(localizations.medicalOfficer),
                      ),
                      DropdownMenuItem(
                        value: 'forensic expert',
                        child: Text(localizations.forensicExpert),
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
                    localizations.additionalInstructionsOptional,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _additionalInstructionsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: localizations.additionalInstructionsHint,
                      border: const OutlineInputBorder(),
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
                      label: Text(_isLoading ? localizations.drafting : localizations.draftDocument),
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
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(localizations.draftingWait),
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
                      localizations.generatedDocumentDraft,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.reviewDraftDesc,
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
                        _draft!['draft'] ?? localizations.noDraftGenerated,
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
                              localizations.aiDraftDisclaimer,
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
                              SnackBar(
                                content: Text(localizations.draftCopied),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: Text(localizations.copyDraft),
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
