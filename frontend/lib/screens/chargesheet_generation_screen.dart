// lib/screens/chargesheet_generation_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';class ChargesheetGenerationScreen extends StatefulWidget {
  const ChargesheetGenerationScreen({super.key});

  @override
  State<ChargesheetGenerationScreen> createState() => _ChargesheetGenerationScreenState();
}

class _ChargesheetGenerationScreenState extends State<ChargesheetGenerationScreen> {
  final _additionalInstructionsController = TextEditingController();
  final _dio = Dio();

  List<File> _uploadedFiles = [];
  bool _isLoading = false;
  Map<String, dynamic>? _chargeSheet;

  @override
  void dispose() {
    _additionalInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _uploadedFiles.addAll(result.paths.map((path) => File(path!)));
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.filesAdded(result.files.length)),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorPickingFiles(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) => setState(() => _uploadedFiles.removeAt(index));

  Future<void> _handleSubmit() async {
    if (_uploadedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseUploadDocument), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formData = FormData();
      for (var file in _uploadedFiles) {
        formData.files.add(MapEntry('documents', await MultipartFile.fromFile(file.path)));
      }
      if (_additionalInstructionsController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('additionalInstructions', _additionalInstructionsController.text.trim()));
      }

      final response = await _dio.post('/api/chargesheet-generation', data: formData);
      setState(() => _chargeSheet = response.data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.draftChargeSheetGenerated), backgroundColor: Colors.green),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToGenerateChargeSheet(error.toString())), backgroundColor: Colors.red),
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
            // SAME BEAUTIFUL HEADER: Orange Arrow + Title
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
                          Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title
                  Expanded(
                    child: Text(
                      localizations.chargesheetGenerator,
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
                localizations.chargesheetGeneratorDesc,
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
                    // Upload Card
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
                                Icon(Icons.file_present_rounded, color: orange, size: 28),
                                const SizedBox(width: 12),
                                Text(localizations.chargesheetGenerator, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Text(localizations.caseDocuments, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _pickFiles,
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(localizations.chooseFiles),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: orange,
                                side: BorderSide(color: orange),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),

                            if (_uploadedFiles.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: orange.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: orange.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.attach_file, color: orange),
                                        const SizedBox(width: 8),
                                        Text("Uploaded Files (${_uploadedFiles.length})", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    ..._uploadedFiles.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final file = entry.value;
                                      final fileName = file.path.split('/').last;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(fileName, style: const TextStyle(fontSize: 14))),
                                            IconButton(
                                              icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                              onPressed: () => _removeFile(index),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            Text(localizations.additionalInstructionsOptional, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _additionalInstructionsController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                hintText: localizations.chargesheetInstructionsHint,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),

                            const SizedBox(height: 28),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: (_isLoading || _uploadedFiles.isEmpty) ? null : _handleSubmit,
                                icon: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.gavel_rounded),
                                label: Text(_isLoading ? localizations.generating : localizations.generateDraftChargeSheet),
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
                            Text(localizations.generatingChargeSheetWait, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],

                    // Result
                    if (_chargeSheet != null) ...[
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
                                  Icon(Icons.description_rounded, color: orange, size: 28),
                                  const SizedBox(width: 12),
                                  Text(localizations.generatedDraftChargeSheet, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: orange.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: orange.withOpacity(0.3)),
                                ),
                                child: SelectableText(
                                  _chargeSheet!['chargeSheet'] ?? localizations.noChargeSheetGenerated,
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
                                      Expanded(child: Text(localizations.aiChargeSheetDisclaimer, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
                                    ],
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizations.draftCopied)));
                                    },
                                    icon: const Icon(Icons.copy),
                                    label: Text(localizations.copyDraft),
                                    style: OutlinedButton.styleFrom(foregroundColor: orange, side: BorderSide(color: orange)),
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