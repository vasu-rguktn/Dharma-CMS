// lib/screens/document_drafting_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';

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
    final localizations = AppLocalizations.of(context)!;
    const Color orange = Color(0xFFFC633C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // SAME PREMIUM HEADER: Orange Arrow + Title
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
              child: Row(
                children: [
                  // PURE ORANGE BACK ARROW — NO CIRCLE
                  GestureDetector(
                    onTap: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final dashboardRoute = authProvider.role == 'police' ? '/police-dashboard' : '/dashboard';
                      context.go(dashboardRoute);
                    },
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
                      localizations.aiDocumentDrafter,
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
                localizations.documentDraftingDesc,
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
                                Icon(Icons.edit_document, color: orange, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  localizations.aiDocumentDrafter,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Text("Case Data", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _caseDataController,
                              maxLines: 10,
                              decoration: InputDecoration(
                                hintText: localizations.pasteCaseDataHint,
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

                            Text("Recipient Type", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _recipientType,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              hint: Text(localizations.selectRecipientType),
                              items: [
                                DropdownMenuItem(value: 'medical officer', child: Text(localizations.medicalOfficer)),
                                DropdownMenuItem(value: 'forensic expert', child: Text(localizations.forensicExpert)),
                              ],
                              onChanged: (value) => setState(() => _recipientType = value),
                            ),
                            const SizedBox(height: 20),

                            Text("Additional Instructions (Optional)", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _additionalInstructionsController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: localizations.additionalInstructionsHint,
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
                            const SizedBox(height: 28),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _handleSubmit,
                                icon: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.create_rounded),
                                label: Text(_isLoading ? localizations.drafting : localizations.draftDocument),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
                            Text(localizations.draftingWait, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],

                    // Result
                    if (_draft != null) ...[
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
                                  Icon(Icons.description, color: orange, size: 28),
                                  const SizedBox(width: 12),
                                  Text(
                                    localizations.generatedDocumentDraft,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange[200]!),
                                ),
                                child: SelectableText(
                                  _draft!['draft'] ?? localizations.noDraftGenerated,
                                  style: const TextStyle(fontSize: 15, height: 1.6),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        localizations.aiDraftDisclaimer,
                                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      // Add clipboard copy here later
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(localizations.draftCopied)),
                                      );
                                    },
                                    icon: const Icon(Icons.copy),
                                    label: Text(localizations.copyDraft),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: orange,
                                      side: BorderSide(color: orange),
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
}