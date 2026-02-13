import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Dharma/utils/file_downloader/file_downloader.dart';

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
  final _draftController = TextEditingController();

  // Use 10.0.2.2 for Android emulator, localhost for web/iOS
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://fastapi-app-335340524683.asia-south1.run.app',
    // baseUrl: kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000',
  ));
  String? _recipientType;
  bool _isLoading = false;
  bool _isDownloading = false;
  Map<String, dynamic>? _draft;

  // New state for file
  PlatformFile? _attachedFile;

  @override
  void dispose() {
    _caseDataController.dispose();
    _additionalInstructionsController.dispose();
    _draftController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _attachedFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  void _removeFile() {
    setState(() {
      _attachedFile = null;
    });
  }

  Future<void> _printDraft() async {
    if (_draft == null || _draft!['draft'] == null) return;

    // Simple clean for print as well
    String cleanText = (_draft!['draft'] as String)
        .replaceAll('**', '')
        .replaceAll('###', '')
        .replaceAll('##', '#');

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();
        final paragraphs = cleanText.split('\n');

        pdf.addPage(
          pw.MultiPage(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return paragraphs.map((para) {
                if (para.trim().isEmpty) return pw.SizedBox(height: 10);
                return pw.Paragraph(text: para);
              }).toList();
            },
          ),
        );
        return pdf.save();
      },
    );
  }

  Future<void> _downloadDocx() async {
    if (_draft == null || _draft!['draft'] == null) return;
    setState(() => _isDownloading = true);

    try {
      // Clean artifacts before sending
      final cleanText = (_draft!['draft'] as String)
          .replaceAll('**', '')
          .replaceAll('__', '')
          .replaceAll('### ', '')
          .replaceAll('###', '')
          .replaceAll('## ', '')
          .replaceAll('##', '')
          .replaceAll('# ', '')
          .replaceAll('#', '');

      final formData = FormData.fromMap({
        'draftText': cleanText,
      });

      final response = await _dio.post(
        '/api/document-drafting/download-docx',
        data: formData,
        options: Options(responseType: ResponseType.bytes),
      );

      final fileName = 'draft_${DateTime.now().millisecondsSinceEpoch}.docx';
      final savedPath = await downloadFile(response.data, fileName);

      if (mounted) {
        // Check success based on platform quirks
        bool success = savedPath != null;
        if (kIsWeb) success = true;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Draft saved successfully!\n📂 $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Download failed.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error downloading DOCX: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _downloadDraftAsPDF() async {
    if (_draft == null || _draftController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No draft available to download'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('📄 Starting PDF generation...');
      final pdf = pw.Document();

      // Split text into paragraphs to avoid page height issues
      final paragraphs = _draftController.text.split('\n');

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
          'document_draft_${DateTime.now().millisecondsSinceEpoch}.pdf';

      print(
          '📥 PDF generated (${bytes.length} bytes), calling downloadFile...');
      final savedPath = await downloadFile(bytes, fileName);
      print('📥 downloadFile returned: $savedPath');

      if (mounted) {
        if (savedPath != null && savedPath.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ PDF saved successfully!\n📂 $fileName\n📍 Check Downloads folder'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '⚠️ Download may have failed. Check logs or rebuild the app with: flutter run'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _downloadDraftAsPDF: $e');
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

  Future<void> _handleSubmit() async {
    // Validate: At least caseData OR a file must be present + recipientType
    bool hasData =
        _caseDataController.text.trim().isNotEmpty || _attachedFile != null;

    if (!hasData || _recipientType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(AppLocalizations.of(context)!.provideCaseDataAndRecipient),
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
      // Prepare FormData
      final formData = FormData.fromMap({
        'caseData': _caseDataController.text, // Backend handles empty string
        'recipientType': _recipientType,
        'additionalInstructions':
            _additionalInstructionsController.text.trim().isEmpty
                ? null
                : _additionalInstructionsController.text,
      });

      // Append file if exists
      if (_attachedFile != null) {
        // Handle bytes (Web) or path (Mobile/Desktop)
        if (_attachedFile!.bytes != null) {
          formData.files.add(MapEntry(
            'file',
            MultipartFile.fromBytes(
              _attachedFile!.bytes!,
              filename: _attachedFile!.name,
            ),
          ));
        } else if (_attachedFile!.path != null) {
          formData.files.add(MapEntry(
            'file',
            await MultipartFile.fromFile(
              _attachedFile!.path!,
              filename: _attachedFile!.name,
            ),
          ));
        }
      }

      final response = await _dio.post(
        '/api/document-drafting',
        data: formData,
      );

      setState(() {
        _draft = response.data;
        // Populate the editable controller with the generated text
        if (_draft != null && _draft!['draft'] != null) {
          _draftController.text = _draft!['draft'];
        }
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
      debugPrint("Drafting Error: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .failedToGenerateDraft(error.toString())),
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
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
              child: Row(
                children: [
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
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.edit_document,
                                    color: orange, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  localizations.aiDocumentDrafter,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(localizations.caseData,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _caseDataController,
                              maxLines: 8,
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

                            const SizedBox(height: 16),

                            // 📂 FILE UPLOAD SECTION
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _pickFile,
                                  icon: const Icon(Icons.upload_file),
                                  label:
                                      const Text('Attach Document (Optional)'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo.shade50,
                                      foregroundColor: Colors.indigo,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8))),
                                ),
                              ],
                            ),
                            if (_attachedFile != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _attachedFile!.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 20, color: Colors.grey),
                                      onPressed: _removeFile,
                                    )
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),

                            Text(localizations.recipientType,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold)),
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
                                DropdownMenuItem(
                                    value: 'medical officer',
                                    child: Text(localizations.medicalOfficer)),
                                DropdownMenuItem(
                                    value: 'forensic expert',
                                    child: Text(localizations.forensicExpert)),
                              ],
                              onChanged: (value) =>
                                  setState(() => _recipientType = value),
                            ),
                            const SizedBox(height: 20),
                            Text(localizations.additionalInstructionsOptional,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _additionalInstructionsController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText:
                                    localizations.additionalInstructionsHint,
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
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.create_rounded),
                                label: Text(_isLoading
                                    ? localizations.drafting
                                    : localizations.draftDocument),
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
                            Text(localizations.draftingWait,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],

                    // Result
                    if (_draft != null) ...[
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
                                  Icon(Icons.description,
                                      color: orange, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      localizations.generatedDocumentDraft,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // EDITABLE TEXT FIELD
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.orange[200]!),
                                ),
                                child: TextField(
                                  controller: _draftController,
                                  maxLines: null, // Grows with content
                                  minLines: 5,
                                  style: const TextStyle(
                                      fontSize: 15, height: 1.6),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(16),
                                    hintText:
                                        "Generated draft will appear here...",
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ACTIONS ROW
                              Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 8.0,
                                  runSpacing: 12.0,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: _draftController.text));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  localizations.draftCopied)),
                                        );
                                      },
                                      icon: const Icon(Icons.copy, size: 18),
                                      label: Text(localizations.copyDraft),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: orange,
                                        side: BorderSide(color: orange),
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: _printDraft,
                                      icon: const Icon(Icons.print, size: 18),
                                      label: const Text("Print"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: orange,
                                        side: BorderSide(color: orange),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _downloadDraftAsPDF,
                                      icon: const Icon(Icons.picture_as_pdf,
                                          size: 18),
                                      label: const Text('PDF'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: orange,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed:
                                          _isDownloading ? null : _downloadDocx,
                                      icon: _isDownloading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white),
                                            )
                                          : const Icon(Icons.description,
                                              size: 18),
                                      label:
                                          Text(_isDownloading ? '...' : 'DOCX'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: orange,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
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
