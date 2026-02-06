// lib/screens/chargesheet_vetting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/screens/petition/ocr_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:Dharma/utils/file_downloader/file_downloader.dart';

class ChargesheetVettingScreen extends StatefulWidget {
  const ChargesheetVettingScreen({super.key});

  @override
  State<ChargesheetVettingScreen> createState() =>
      _ChargesheetVettingScreenState();
}

class _ChargesheetVettingScreenState extends State<ChargesheetVettingScreen> {
  final _chargesheetContentController = TextEditingController();
  final _dio = Dio(
    BaseOptions(
      // Local backend (FastAPI) for development
      // baseUrl: "http://127.0.0.1:8080",
      baseUrl: "https://fastapi-app-335340524683.asia-south1.run.app",
      headers: {"Content-Type": "application/json"},
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout:
          const Duration(seconds: 60), // AI processing can take time
    ),
  );

  bool _isLoading = false;
  Map<String, dynamic>? _suggestions;
  final OcrService _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    _ocrService.init();
  }

  @override
  void dispose() {
    _chargesheetContentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withData: true, // Important for web support
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final fileName = file.name.toLowerCase();
        String content = '';

        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Processing ${file.name}...'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Use backend API for PDF, DOC, DOCX files
        if (fileName.endsWith('.pdf') ||
            fileName.endsWith('.doc') ||
            fileName.endsWith('.docx')) {
          try {
            await _ocrService.runOcr(file);
            final ocrResult = _ocrService.result;
            if (ocrResult != null && ocrResult['text'] != null) {
              content = ocrResult['text'].toString().trim();
            } else {
              throw Exception('No text extracted from document');
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error extracting text: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else {
          // Handle plain text files (txt) - read directly
          if (file.path != null) {
            // Mobile/Desktop: read from file path
            final fileObj = File(file.path!);
            try {
              content = await fileObj.readAsString();
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error reading file: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          } else if (file.bytes != null) {
            // Web: read from bytes
            try {
              content = String.fromCharCodes(file.bytes!);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error reading file: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unable to read file: ${file.name}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        if (content.isNotEmpty) {
          setState(() {
            _chargesheetContentController.text = content;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.fileContentLoaded(file.name)),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No content extracted from ${file.name}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.errorReadingFile(e.toString())),
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
          content: Text(
              AppLocalizations.of(context)!.pleaseUploadOrPasteChargesheet),
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
            content:
                Text(AppLocalizations.of(context)!.chargesheetVettedSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .failedToVetChargesheet(error.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _copyToClipboard() async {
    if (_suggestions == null) return;

    try {
      await Clipboard.setData(
        ClipboardData(text: _suggestions!['suggestions'] ?? ''),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestions copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error copying to clipboard'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _cleanMarkdown(String text) {
    // Remove Markdown formatting symbols
    return text
        .replaceAll('**', '') // Remove bold markers
        .replaceAll('__', '') // Remove alternative bold markers
        .replaceAll('*', '') // Remove italic markers
        .replaceAll('_', '') // Remove alternative italic markers
        .replaceAll('###', '') // Remove heading markers
        .replaceAll('##', '')
        .replaceAll('#', '');
  }

  Future<void> _downloadSuggestionsAsPDF() async {
    if (_suggestions == null) return;

    try {
      print('📄 Starting vetting suggestions PDF generation...');
      final suggestionsText =
          _suggestions!['suggestions'] ?? 'No suggestions provided';
      final cleanedText = _cleanMarkdown(suggestionsText);
      final pdf = pw.Document();

      // Split text into paragraphs to avoid page height issues
      final paragraphs = cleanedText.split('\n');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return paragraphs.map((para) {
              if (para.trim().isEmpty) {
                return pw.SizedBox(height: 10);
              }
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  para,
                  style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
                  textAlign: pw.TextAlign.left,
                ),
              );
            }).toList();
          },
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'vetting_suggestions_${DateTime.now().millisecondsSinceEpoch}.pdf';

      print(
          '📥 Vetting PDF generated (${bytes.length} bytes), calling downloadFile...');
      final savedPath = await downloadFile(bytes, fileName);
      print('📥 downloadFile returned: $savedPath');

      if (mounted) {
        if (savedPath != null && savedPath.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Vetting result saved successfully!\n📂 $fileName\n📍 Check Downloads folder'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('⚠️ Download may have failed. Rebuild app if needed.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _downloadSuggestionsAsPDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final dashboardRoute = authProvider.role == 'police'
                          ? '/police-dashboard'
                          : '/dashboard';
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
                              offset: Offset(0, 2)),
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
                style: TextStyle(
                    fontSize: 15, color: Colors.grey[700], height: 1.4),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.fact_check_rounded,
                                    color: orange, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  localizations.chargesheetVettingAI,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(localizations.uploadChargesheet,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold)),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                ),
                                if (_chargesheetContentController
                                    .text.isNotEmpty) ...[
                                  const SizedBox(width: 16),
                                  Text(
                                    "File loaded — edit below",
                                    style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(localizations.orPasteChargesheet,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _chargesheetContentController,
                              maxLines: 15,
                              decoration: InputDecoration(
                                hintText: localizations.pasteChargesheetHint,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _handleSubmit,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.verified_rounded),
                                label: Text(_isLoading
                                    ? localizations.vetting
                                    : localizations.vetChargeSheet),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
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
                            Text(localizations.vettingChargesheetWait,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],

                    // Result
                    if (_suggestions != null) ...[
                      const SizedBox(height: 32),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb_rounded,
                                      color: orange, size: 28),
                                  const SizedBox(width: 12),
                                  Text(localizations.aiVettingSuggestions,
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: orange.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: orange.withOpacity(0.3)),
                                ),
                                child: SelectableText(
                                  _suggestions!['suggestions'] ??
                                      localizations.noSuggestionsProvided,
                                  style: const TextStyle(
                                      fontSize: 15, height: 1.6),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange[700], size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      localizations.aiVettingDisclaimer,
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                          height: 1.4),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _copyToClipboard,
                                    icon: const Icon(Icons.copy, size: 18),
                                    label: const Text('Copy'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: orange,
                                      side: BorderSide(color: orange),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _downloadSuggestionsAsPDF,
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Download PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: orange,
                                      foregroundColor: Colors.white,
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
