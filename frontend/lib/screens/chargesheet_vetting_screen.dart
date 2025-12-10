// lib/screens/chargesheet_vetting_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

class ChargesheetVettingScreen extends StatefulWidget {
  const ChargesheetVettingScreen({super.key});

  @override
  State<ChargesheetVettingScreen> createState() => _ChargesheetVettingScreenState();
}

class _ChargesheetVettingScreenState extends State<ChargesheetVettingScreen> {
  final _chargesheetContentController = TextEditingController();
  final _dio = Dio();

  bool _isLoading = false;
  Map<String, dynamic>? _suggestions;

  @override
  void dispose() {
    _chargesheetContentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        setState(() {
          _chargesheetContentController.text = content;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.fileContentLoaded(result.files.single.name)),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorReadingFile(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_chargesheetContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseUploadOrPasteChargesheet),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestions = null;
    });

    try {
      final response = await _dio.post(
        '/api/chargesheet-vetting',
        data: {'chargesheet': _chargesheetContentController.text},
      );

      setState(() {
        _suggestions = response.data;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.chargesheetVettedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToVetChargesheet(error.toString())),
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
            // SAME PREMIUM HEADER: Orange Arrow + Title
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
              child: Row(
                children: [
                  // PURE ORANGE BACK ARROW — NO CIRCLE
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
                  // Title
                  Expanded(
                    child: Text(
                      localizations.chargesheetVettingAI,
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
                localizations.chargesheetVettingDesc,
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
                                Icon(Icons.fact_check_rounded, color: orange, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  localizations.chargesheetVettingAI,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Text("Upload Chargesheet", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.upload_file_rounded),
                                  label: Text(localizations.chooseFile),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: orange,
                                    side: BorderSide(color: orange),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                if (_chargesheetContentController.text.isNotEmpty) ...[
                                  const SizedBox(width: 16),
                                  Text(
                                    "File loaded — edit below",
                                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 24),

                            Text("Or Paste Chargesheet", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _chargesheetContentController,
                              maxLines: 15,
                              decoration: InputDecoration(
                                hintText: localizations.pasteChargesheetHint,
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
                                onPressed: _isLoading ? null : _handleSubmit,
                                icon: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.verified_rounded),
                                label: Text(_isLoading ? localizations.vetting : localizations.vetChargeSheet),
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
                            Text(localizations.vettingChargesheetWait, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],

                    // Result
                    if (_suggestions != null) ...[
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
                                  Icon(Icons.lightbulb_rounded, color: orange, size: 28),
                                  const SizedBox(width: 12),
                                  Text(localizations.aiVettingSuggestions, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                                  _suggestions!['suggestions'] ?? localizations.noSuggestionsProvided,
                                  style: const TextStyle(fontSize: 15, height: 1.6),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      localizations.aiVettingDisclaimer,
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
}