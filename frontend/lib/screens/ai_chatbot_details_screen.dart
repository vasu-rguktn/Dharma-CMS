import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/complaint_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart'; // for kIsWeb

class AiChatbotDetailsScreen extends StatefulWidget {
  final Map<String, String> answers;
  final String summary;
  final String classification;
  final String originalClassification;
  final List<String> evidencePaths;
  final Map<String, dynamic>? chatData; // For saving draft
  final String? draftId;

  const AiChatbotDetailsScreen({
    super.key,
    required this.answers,
    required this.summary,
    required this.classification,
    required this.originalClassification,
    this.evidencePaths = const [],
    this.chatData,
    this.draftId,
  });

  static AiChatbotDetailsScreen fromRouteSettings(
      BuildContext context, GoRouterState state) {
    final q = state.extra as Map<String, dynamic>?;

    // Safely cast the nested map
    final rawAnswers = q?['answers'] as Map<String, dynamic>?;
    final safeAnswers =
        rawAnswers?.map((k, v) => MapEntry(k, v.toString())) ?? {};

    return AiChatbotDetailsScreen(
      answers: safeAnswers,
      summary: q?['summary'] as String? ?? '',
      classification: q?['classification'] as String? ?? '',
      originalClassification: q?['originalClassification'] as String? ?? '',
      evidencePaths: (q?['evidencePaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      chatData: (q?['chatData'] as Map?)?.cast<String, dynamic>(),
      draftId: q?['draftId'] as String?,
    );
  }

  @override
  State<AiChatbotDetailsScreen> createState() => _AiChatbotDetailsScreenState();
}

class _AiChatbotDetailsScreenState extends State<AiChatbotDetailsScreen> {
  bool _isSavingDraft = false;
  bool _isGeneratingQr = false;

  Future<void> _generateQrCode() async {
    setState(() {
      _isGeneratingQr = true;
    });

    try {
      // 1. Prepare data payload
      // We need to match ChatbotSummaryRequest in backend
      final payload = {
        "answers": widget.answers,
        "summary": widget.summary,
        "classification": widget.classification,
        // "originalReportId": widget.draftId // Optional
      };

    

      // String baseUrl = "http://127.0.0.1:8000"; // Default for local web
      // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      //   // Use 10.0.2.2 for Emulator, but 10.5.40.156 for Physical Device
      //   // baseUrl = "http://10.0.2.2:8000";
      //   baseUrl = "http://10.5.40.156:8000";
      // }

      // Override if we can find a better source later.
      // But effectively, let's try to use the `dio` from `AuthProvider` if it exposes it? No.
      String baseUrl = "https://fastapi-app-335340524683.asia-south1.run.app"; // Default for local web

      final dio = Dio();
      final response = await dio.post(
        '$baseUrl/api/generate-chatbot-summary-pdf',
        data: payload,
      );

      if (response.statusCode == 200) {
        final pdfRelativeUrl = response.data['pdf_url'];
        final fullPdfUrl = '$baseUrl$pdfRelativeUrl';

        if (mounted) {
          _showQrDialog(fullPdfUrl);
        }
      } else {
        throw Exception("Failed to generate PDF: ${response.statusCode}");
      }
    } catch (e) {
      print("Error generating QR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate QR code: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingQr = false;
        });
      }
    }
  }

  Future<void> _printPdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => response.bodyBytes,
          name: 'Chatbot_Summary.pdf',
        );
      } else {
        throw Exception(
            "Failed to fetch PDF for printing: ${response.statusCode}");
      }
    } catch (e) {
      print("Error printing PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to print PDF: $e")),
        );
      }
    }
  }

  Future<void> _generateAndPrint() async {
    setState(() {
      _isGeneratingQr = true;
    });

    try {
      final payload = {
        "answers": widget.answers,
        "summary": widget.summary,
        "classification": widget.classification,
      };

      String baseUrl = "https://fastapi-app-335340524683.asia-south1.run.app";
      // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      //   // Use 10.0.2.2 for Emulator, but 10.5.40.156 for Physical Device
      //   // Since we can't easily detect physical device, defaulting to LAN IP for now
      //   // baseUrl = "http://10.0.2.2:8000";
      //   baseUrl = "http://10.5.40.156:8000";
      // }

      final dio = Dio();
      final response = await dio.post(
        '$baseUrl/api/generate-chatbot-summary-pdf',
        data: payload,
      );

      if (response.statusCode == 200) {
        final pdfRelativeUrl = response.data['pdf_url'];
        final fullPdfUrl = '$baseUrl$pdfRelativeUrl';

        if (mounted) {
          await _printPdf(fullPdfUrl);
        }
      } else {
        throw Exception("Failed to generate PDF: ${response.statusCode}");
      }
    } catch (e) {
      print("Error generating for print: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to generate PDF for printing: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingQr = false;
        });
      }
    }
  }

  void _showQrDialog(String data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scan to Download Summary"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Scan this QR code with another device to view and download the PDF summary.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            SelectableText(
              data,
              style: const TextStyle(fontSize: 10, color: Colors.blue),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (widget.chatData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No chat data available to save.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final complaintProv =
        Provider.of<ComplaintProvider>(context, listen: false);

    if (auth.user == null) return;

    setState(() {
      _isSavingDraft = true;
    });

    // Generate a meaningful title from the answers if possible
    String title = "Completed Chat Draft";
    if (widget.answers['incident_details'] != null &&
        widget.answers['incident_details']!.isNotEmpty) {
      title = widget.answers['incident_details']!.length > 40
          ? widget.answers['incident_details']!.substring(0, 40) + "..."
          : widget.answers['incident_details']!;
    } else if (widget.answers['details'] != null &&
        widget.answers['details']!.isNotEmpty) {
      // Fallback to initial details
      title = widget.answers['details']!.length > 40
          ? widget.answers['details']!.substring(0, 40) + "..."
          : widget.answers['details']!;
    }

    final success = await complaintProv.saveChatAsDraft(
      userId: auth.user!.uid,
      title: title,
      chatData: widget.chatData!,
      draftId: widget.draftId,
    );

    setState(() {
      _isSavingDraft = false;
    });

    if (mounted) {
      final localizations = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? localizations.draftSaved
              : localizations.failedToSaveDraft),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Widget _buildSummaryRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold, // Bold Label
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 15,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard'); // Fallback to home
            }
          },
        ),
        title: Text(
          localizations.aiChatbotDetails,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFC633C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isSavingDraft
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
            tooltip: 'Save as Draft',
            onPressed: _isSavingDraft ? null : _saveDraft,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(22.0),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            // Citizen Details section removed as per user request

            Text(localizations.formalComplaintSummary,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'FORMAL COMPLAINT SUMMARY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Divider(height: 24, thickness: 1),

                  // Fields
                  _buildSummaryRow('Full Name', widget.answers['full_name']),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Address',
                      widget.answers['address']), // Maps to Resident Address
                  const SizedBox(height: 12),
                  _buildSummaryRow('Phone Number', widget.answers['phone']),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                      'Complaint Type', widget.answers['complaint_type']),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Incident Details',
                      widget.answers['incident_address']), // Short summary

                  // Police Station Selection
                  if (widget.answers['selected_police_station'] != null &&
                      widget
                          .answers['selected_police_station']!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSummaryRow('Selected Police Station',
                        widget.answers['selected_police_station']),
                  ],
                  if (widget.answers['police_station_reason'] != null &&
                      widget.answers['police_station_reason']!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                        'Reason', widget.answers['police_station_reason']),
                  ],
                  if (widget.answers['station_confidence'] != null &&
                      widget.answers['station_confidence']!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSummaryRow('Confidence Level',
                        widget.answers['station_confidence']),
                  ],
                  const SizedBox(height: 12),
                  _buildSummaryRow('Details',
                      widget.answers['incident_details']), // Full narrative
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                      'Date of Complaint', widget.answers['date_of_complaint']),
                  if (Provider.of<PetitionProvider>(context)
                      .tempEvidence
                      .isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: _buildSummaryRow('Attached Evidence',
                          '${Provider.of<PetitionProvider>(context).tempEvidence.length} file(s) attached'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('=== ${localizations.offenceClassification} ===',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!, width: 1.2),
              ),
              child: Text(widget.classification,
                  style: const TextStyle(fontSize: 15)),
            ),
            Center(
              child: _isGeneratingQr
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        TextButton.icon(
                          onPressed: _generateQrCode,
                          icon: const Icon(Icons.qr_code),
                          label: const Text("Generate QR Code for PDF"),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFC633C),
                          ),
                        ),
                        // Add Print Button if we have something to print or as a shortcut
                        // For now, let's make it easy to print the summary
                        TextButton.icon(
                          onPressed: () async {
                            // If we already have the QR dialog showing or if we want to trigger generation first
                            // Ideally we might want to cache the fullPdfUrl
                            // For now, let's just trigger generation or use a placeholder if we haven't generated yet
                            // BUT wait, let's check if fullPdfUrl is stored. It's not.
                            // Let's refactor _generateQrCode slightly to return the URL or store it.
                            _generateAndPrint();
                          },
                          icon: const Icon(Icons.print),
                          label: const Text("Print PDF Summary"),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFC633C),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print(
                      '🚀 [DEBUG] Details Screen: Navigating to Separation Screen');
                  context.push('/cognigible-non-cognigible-separation', extra: {
                    'classification': widget.classification,
                    'originalClassification':
                        widget.originalClassification, // Pass it on
                    'complaintData': widget.answers,
                    'evidencePaths': widget.evidencePaths, // FORWARD EVIDENCE
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC633C),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(localizations.next,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
