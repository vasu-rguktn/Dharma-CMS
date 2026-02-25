import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/services/local_storage_service.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'ocr_service.dart';

class CreatePetitionForm extends StatefulWidget {
  final VoidCallback? onCreatedSuccess;
  // Add new parameter for initial data
  final Map<String, dynamic>? initialData;

  const CreatePetitionForm({
    super.key,
    this.onCreatedSuccess,
    this.initialData,
  });

  @override
  State<CreatePetitionForm> createState() => _CreatePetitionFormState();
}

class _CreatePetitionFormState extends State<CreatePetitionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _petitionerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _groundsController = TextEditingController();
  final _prayerReliefController = TextEditingController();
  final _districtController = TextEditingController();
  final _stationController = TextEditingController();

  // ADDITIONAL DETAILS
  final _accusedDetailsController = TextEditingController();
  final _stolenPropertyController = TextEditingController();
  final _witnessesController = TextEditingController();
  final _evidenceStatusController = TextEditingController();

  // STASHED AI RECOMMENDATIONS
  String? _stationReason;
  String? _stationConfidence;
  String? _aiSummary;

  // INCIDENT DETAILS
  final _incidentAddressController = TextEditingController();
  DateTime? _incidentDate;

// District & Police Station
  String? _selectedDistrict;
  String? _selectedStation;

  bool _isSubmitting = false;
  Map<String, List<String>> _districtStations = {};
  bool _dataLoading = true;

  List<PlatformFile> _pickedFiles = []; // Handwritten documents
  List<PlatformFile> _proofFiles = []; // Related proof documents

  final _ocrService = OcrService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndConsumeEvidence();
  }

  void _checkAndConsumeEvidence() {
    if (!mounted) return;
    final petitionProvider =
        Provider.of<PetitionProvider>(context, listen: false);
    if (petitionProvider.tempEvidence.isNotEmpty) {
      // debugPrint(
      // '📥 [CreatePetitionForm] Found ${petitionProvider.tempEvidence.length} stashed files');
      setState(() {
        // Avoid duplicates in case of re-entry
        final existingNames = _proofFiles.map((e) => e.name).toSet();
        final newFiles = petitionProvider.tempEvidence
            .where((e) => !existingNames.contains(e.name))
            .toList();

        if (newFiles.isNotEmpty) {
          // Validate Web Bytes to prevent silent upload failure
          if (kIsWeb && newFiles.any((f) => f.bytes == null)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_getLocalizedLabel(
                        'Error: Evidence from chat is missing data. Please attach files manually.',
                        'లోపం: చాట్ నుండి రుజువు డేటా లేదు. దయచేసి ఫైళ్లను మాన్యువల్‌గా జోడించండి.')),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            });
          } else {
            _proofFiles.addAll(newFiles);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(_getLocalizedLabel(
                          'Auto-attached ${newFiles.length} proofs from chat',
                          'చాట్ నుండి ${newFiles.length} రుజువులు జోడించబడ్డాయి'))),
                );
              }
            });
          }
        }
      });
      petitionProvider.clearTempEvidence();
    }
  }

  @override
  void initState() {
    super.initState();
    _ocrService.init();
    _loadDistrictStations();

    // Check for stashed evidence from AI Chat (on first load)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndConsumeEvidence();
    });

    final data = widget.initialData;
    if (data != null) {
      final type = data['complaintType']?.toString() ?? '';
      // Raw: "Theft BNS 3032 (COGNIZABLE - ...)" or "Theft BNS 3032 - COGNIZABLE"
      String rawClass = data['classification']?.toString() ?? '';

      // 1. Remove text inside parentheses containing COGNIZABLE keywords
      String clean = rawClass.replaceAll(
          RegExp(r'\([^)]*(COGNIZABLE|NON-COGNIZABLE)[^)]*\)',
              caseSensitive: false),
          '');

      // 2. Remove specific description pattern (- Description)
      clean = clean.replaceAll(RegExp(r'\s*\(-[^)]*\)'), '');

      // 3. Remove text after hyphen if it contains COGNIZABLE
      clean = clean.replaceAll(
          RegExp(r'-\s*(COGNIZABLE|NON-COGNIZABLE).*', caseSensitive: false),
          '');

      // 4. Cleanup remaining keywords
      clean = clean
          .replaceAll('COGNIZABLE', '')
          .replaceAll('NON-COGNIZABLE', '')
          .replaceAll(RegExp(r'\s+'), ' ') // Collpase multiple spaces
          .trim();

      _titleController.text = clean.isNotEmpty ? type : type;
      _petitionerNameController.text = data['fullName']?.toString() ?? '';
      _phoneNumberController.text =
          (data['phone']?.toString() ?? '').replaceAll(RegExp(r'\s+'), '');
      _addressController.text = data['address']?.toString() ?? '';
      // Map Narrative to Grounds
      _groundsController.text = data['incident_details']?.toString() ??
          data['details']?.toString() ??
          '';
      // Map Incident Address
      _incidentAddressController.text =
          data['incident_address']?.toString() ?? '';

      // Map Additional Details
      _accusedDetailsController.text = data['accused_details']?.toString() ??
          data['accusedDetails']?.toString() ??
          '';
      _stolenPropertyController.text = data['stolen_property']?.toString() ??
          data['stolenProperty']?.toString() ??
          '';
      _witnessesController.text = data['witnesses']?.toString() ?? '';
      _evidenceStatusController.text = data['evidence_status']?.toString() ??
          data['evidenceStatus']?.toString() ??
          '';

      // Map AI Recommendations
      _stationReason = data['police_station_reason']?.toString();
      _stationConfidence = data['station_confidence']?.toString();
      _aiSummary =
          data['ai_summary']?.toString() ?? data['summary']?.toString();

      // Map Incident Date - handle both string and Timestamp formats
      if (data['incident_date'] != null) {
        try {
          final incidentDateData = data['incident_date'];
          DateTime? parsedDate;

          // Handle string format (YYYY-MM-DD) from chatbot
          if (incidentDateData is String) {
            String dateStr = incidentDateData.trim();
            parsedDate = DateTime.tryParse(dateStr);
            // debugPrint(
            // '✅ Parsed incident date from string: $parsedDate (raw: "$dateStr")');
          }
          // Handle Timestamp object format
          else if (incidentDateData is Timestamp) {
            parsedDate = incidentDateData.toDate();
            // debugPrint('✅ Parsed incident date from Timestamp: $parsedDate');
          }
          // Handle serialized Map format
          else if (incidentDateData is Map) {
            final seconds = incidentDateData['seconds'];
            final nanoseconds = incidentDateData['nanoseconds'] ?? 0;
            if (seconds != null) {
              parsedDate =
                  Timestamp(seconds as int, nanoseconds as int).toDate();
              // debugPrint('✅ Parsed incident date from Map: $parsedDate');
            }
          }

          if (parsedDate != null) {
            _incidentDate = parsedDate;
            // debugPrint('✅ Incident date autofilled: $_incidentDate');
          }
        } catch (e) {
          // debugPrint('❌ Error parsing incident date: $e');
        }
      }
    }
  }

  Future<void> _loadDistrictStations() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/data/district_police_stations.json');

      final Map<String, dynamic> data = json.decode(jsonStr);

      setState(() {
        _districtStations = data.map((k, v) {
          final stations = List<String>.from(v);
          if (!stations.contains('Station Unknown')) {
            stations.insert(0, 'Station Unknown');
          }
          return MapEntry(k, stations);
        });
        _dataLoading = false;

        // Trigger Autofill
        _autofillJurisdiction(data);
      });
    } catch (e) {
      // debugPrint('Error loading district data: $e');
      setState(() => _dataLoading = false);
    }
  }

  void _autofillJurisdiction(Map<String, dynamic> districtsMap) {
    if (widget.initialData == null) return;

    final targetStation =
        widget.initialData!['selected_police_station']?.toString().trim();
    if (targetStation == null || targetStation.isEmpty) return;

    // debugPrint('🤖 Attempting to autofill jurisdiction for: $targetStation');

    String? foundDistrict;
    String? foundStation;

    // Search for the station in the map
    for (final entry in districtsMap.entries) {
      final district = entry.key;
      final stations = List<String>.from(entry.value);

      // Case insensitive check
      final match = stations.firstWhere(
        (s) => s.toLowerCase() == targetStation.toLowerCase(),
        orElse: () => '',
      );

      if (match.isNotEmpty) {
        foundDistrict = district;
        foundStation = match; // Use the exact casing from JSON
        break;
      }
    }

    if (foundDistrict != null) {
      // debugPrint('✅ Found District: $foundDistrict for Station: $foundStation');
      setState(() {
        _districtController.text = foundDistrict!;
        _stationController.text = foundStation!;
      });
    } else {
      // debugPrint('⚠️ Station "$targetStation" not found in district database.');
    }
  }

  Future<void> _openSearchableDropdown({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required void Function(String value) onSelected,
  }) async {
    if (items.isEmpty) return;

    final searchController = TextEditingController();
    List<String> filtered = List.from(items);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText:
                            _getLocalizedLabel('Search...', 'శోధించండి...'),
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filtered = items
                              .where((e) =>
                                  e.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(item),
                          trailing: item == selectedValue
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _picker({
    required String label,
    required String? value,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap == null ? null : () => onTap(),
      child: IgnorePointer(
        ignoring: onTap == null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.arrow_drop_down),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            value ?? 'Select $label',
            style: TextStyle(
              color: onTap == null ? Colors.grey : Colors.black,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _petitionerNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _groundsController.dispose();
    _prayerReliefController.dispose();
    _incidentAddressController.dispose();
    _districtController.dispose();
    _stationController.dispose();

    super.dispose();
  }

  Future<void> _submitPetition() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petitionProvider =
        Provider.of<PetitionProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    String? extractedText;
    if (_pickedFiles.isNotEmpty && _ocrService.result == null) {
      await _ocrService.runOcr(_pickedFiles.first);
    }
    extractedText = _ocrService.result?['text']?.trim().isNotEmpty == true
        ? _ocrService.result!['text']
        : null;

    final petition = Petition(
      title: _titleController.text,
      type: PetitionType.other,
      status: PetitionStatus.draft,
      petitionerName: _petitionerNameController.text,
      phoneNumber: _phoneNumberController.text,
      address: _addressController.text,
      grounds: _groundsController.text,

      // ✅ NEW FIELDS
      incidentAddress: _incidentAddressController.text,
      incidentDate:
          _incidentDate == null ? null : Timestamp.fromDate(_incidentDate!),
      district: _districtController.text.trim().isEmpty
          ? null
          : _districtController.text.trim(),
      stationName: _stationController.text.trim().isEmpty
          ? null
          : _stationController.text.trim(),

      prayerRelief: _prayerReliefController.text.isEmpty
          ? null
          : _prayerReliefController.text,
      accusedDetails: _accusedDetailsController.text.trim().isEmpty
          ? null
          : _accusedDetailsController.text.trim(),
      stolenProperty: _stolenPropertyController.text.trim().isEmpty
          ? null
          : _stolenPropertyController.text.trim(),
      witnesses: _witnessesController.text.trim().isEmpty
          ? null
          : _witnessesController.text.trim(),
      evidenceStatus: _evidenceStatusController.text.trim().isEmpty
          ? null
          : _evidenceStatusController.text.trim(),
      extractedText: extractedText,
      userId: authProvider.user!.uid,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    // Save files locally (optional, for offline access or caching)
    if (_pickedFiles.isNotEmpty) {
      final folder = _titleController.text.isNotEmpty
          ? _titleController.text
          : 'petition_${DateTime.now().millisecondsSinceEpoch}';
      try {
        await LocalStorageService.savePickedFiles(
            files: _pickedFiles, subfolderName: folder);
      } catch (_) {}
    }

    // Use the updated createPetition method with named arguments
    final result = await petitionProvider.createPetition(
      petition: petition,
      handwrittenFile: _pickedFiles.isNotEmpty ? _pickedFiles.first : null,
      proofFiles: _proofFiles,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result != null) {
      // Capture values before reset so QR dialog can use them
      final capturedAnswers = {
        'full_name': _petitionerNameController.text,
        'address': _addressController.text,
        'complaint_type': _titleController.text,
        'selected_police_station': _stationController.text,
        'phone': _phoneNumberController.text,
        'incident_details': _groundsController.text,
        'incident_summary': _aiSummary != null && _aiSummary!.isNotEmpty
            ? _aiSummary!
            : (_groundsController.text.length > 150
                ? '${_groundsController.text.substring(0, 150)}...'
                : _groundsController.text),
        'incident_address': _incidentAddressController.text,
        'incident_date': _incidentDate?.toIso8601String() ?? '',
        'accused_details': _accusedDetailsController.text,
        'stolen_property': _stolenPropertyController.text,
        'witnesses': _witnessesController.text,
        'evidence_status': _evidenceStatusController.text,
        'police_station_reason': _stationReason ?? '',
        'station_confidence': _stationConfidence ?? '',
        'date_of_complaint': DateTime.now().toString().split('.').first,
        'petition_number': result['petitionNumber']!,
        'case_id': result['caseId']!,
      };
      final capturedSummary = _groundsController.text;
      final capturedType = _titleController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${localizations.petitionCreatedSuccessfully} (${result['petitionNumber']})'),
            backgroundColor: Colors.green),
      );

      widget.onCreatedSuccess?.call();
      _resetForm();
      await petitionProvider.fetchPetitions(authProvider.user!.uid);
      if (!mounted) return;

      // Show QR dialog (same as ai_chatbot_details_screen)
      await _generatePetitionQr(
        answers: capturedAnswers,
        summary: capturedSummary,
        classification: capturedType,
      );

      if (!mounted) return;
      GoRouter.of(context).go('/petitions');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations.failedToCreatePetition),
            backgroundColor: Colors.red),
      );
    }
  }

  bool _isGeneratingQr = false;

  /// Same pattern as ai_chatbot_details_screen: call backend, get PDF URL, show QR dialog.
  Future<void> _generatePetitionQr({
    required Map<String, String> answers,
    required String summary,
    required String classification,
  }) async {
    setState(() => _isGeneratingQr = true);
    try {
      final payload = {
        "answers": answers,
        "summary": summary,
        "classification": classification,
      };
      const baseUrl = 'https://fastapi-app-335340524683.asia-south1.run.app';
      // const baseUrl = 'http://localhost:8000';
      final dio = Dio();
      final response = await dio.post(
        '$baseUrl/api/generate-chatbot-summary-pdf',
        data: payload,
      );
      if (response.statusCode == 200) {
        final pdfRelativeUrl = response.data['pdf_url'];
        final fullPdfUrl = '$baseUrl$pdfRelativeUrl';
        if (mounted) {
          await _showQrDialog(fullPdfUrl, answers);
        }
      } else {
        throw Exception('Failed to generate PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate QR: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingQr = false);
    }
  }

  Future<void> _showQrDialog(String pdfUrl, Map<String, String> answers) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Complaint Submitted! ✅'),
        content: SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: QrImageView(
                      data: pdfUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Scan QR to access your complaint summary PDF',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if ((answers['petition_number'] ?? '').isNotEmpty) ...[
                  _infoRow('Petition Number', answers['petition_number']!),
                ],
                if ((answers['case_id'] ?? '').isNotEmpty) ...[
                  _infoRow('Case ID', answers['case_id']!),
                ],
                if ((answers['full_name'] ?? '').isNotEmpty) ...[
                  _infoRow('Petitioner', answers['full_name']!),
                ],
                if ((answers['address'] ?? '').isNotEmpty) ...[
                  _infoRow('Address', answers['address']!),
                ],
                if ((answers['complaint_type'] ?? '').isNotEmpty) ...[
                  _infoRow('Type', answers['complaint_type']!),
                ],
                if ((answers['selected_police_station'] ?? '').isNotEmpty) ...[
                  _infoRow(
                      'Police Station', answers['selected_police_station']!),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _printPdf(pdfUrl),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => response.bodyBytes,
          name: 'Petition_Summary.pdf',
        );
      } else {
        throw Exception('Failed to fetch PDF: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print: $e')),
        );
      }
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState!.reset();

    _titleController.clear();
    _petitionerNameController.clear();
    _phoneNumberController.clear();
    _addressController.clear();
    _groundsController.clear();
    _prayerReliefController.clear();

    // ✅ NEW FIELDS RESET
    _incidentAddressController.clear();
    _accusedDetailsController.clear();
    _stolenPropertyController.clear();
    _witnessesController.clear();
    _evidenceStatusController.clear();
    _districtController.clear();
    _stationController.clear();
    _incidentDate = null;
    _selectedDistrict = null;
    _selectedStation = null;

    setState(() {
      _pickedFiles = [];
      _proofFiles = [];
      _ocrService.clearResult();
    });
  }

  Future<void> _pickAndOcr() async {
    final localizations = AppLocalizations.of(context)!;
    // open file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    // update picked files immediately so UI shows upload
    setState(() {
      _pickedFiles = [file];
    });

    try {
      // run OCR and await completion
      await _ocrService.runOcr(file);

      // when extraction completes, update UI immediately
      final r = _ocrService.result;
      if (r != null && r['text'] != null) {
        final extracted = r['text'].toString().trim();
        if (extracted.isNotEmpty) {
          setState(() {
            final current = _groundsController.text.trim();

            // If the field is empty → fill it
            if (current.isEmpty) {
              _groundsController.text = extracted;
            } else {
              // If not empty → combine existing and extracted text cleanly
              if (!current.contains(extracted)) {
                _groundsController.text = '$current $extracted'.trim();
              }
            }
          });
        }
      } else {
        // extraction returned no text
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.noTextExtracted)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.ocrFailed(e.toString()))),
        );
      }
    }
  }

  Widget _buildOcrSummary(ThemeData theme) {
    final localizations = AppLocalizations.of(context)!;
    final text = _ocrService.result?['text'] as String? ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.extractedText,
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(text, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIncidentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _incidentDate = picked;
      });
    }
  }

  /// Helper method to get localized label based on current locale
  String _getLocalizedLabel(String english, String telugu) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'te' ? telugu : english;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          title: Text(localizations.createPetition),
          // leading: IconButton(
          //   icon: const Icon(Icons.arrow_back),
          //   onPressed: () {
          //     if (context.canPop()) {
          //       context.pop();
          //     } else {
          //       context.go('/petitions'); // Fallback if no history
          //     }
          //   },
          // ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // === BASIC INFO ===
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(localizations.basicInformation,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                              labelText: localizations.petitionTypeLabel,
                              border: const OutlineInputBorder()),
                          validator: (v) => v?.isEmpty ?? true
                              ? localizations.required
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _petitionerNameController,
                          decoration: InputDecoration(
                              labelText: localizations.yourNameLabel,
                              border: const OutlineInputBorder()),
                          validator: (v) => v?.isEmpty ?? true
                              ? localizations.required
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              labelText: localizations.phoneNumberLabel,
                              border: const OutlineInputBorder()),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return localizations.required;
                            if (!RegExp(r'^\d{10}$').hasMatch(v))
                              return localizations.enterTenDigitNumber;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                              labelText: localizations.addressLabel,
                              border: const OutlineInputBorder()),
                          validator: (v) => v?.isEmpty ?? true
                              ? localizations.required
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

// === INCIDENT DETAILS ===
// === INCIDENT & JURISDICTION DETAILS ===
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ================= INCIDENT DETAILS =================
                        Text(
                          _getLocalizedLabel(
                              'Incident Details', 'సంఘటన వివరాలు'),
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // Incident Address
                        TextFormField(
                          controller: _incidentAddressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: _getLocalizedLabel(
                                'Incident Location', 'సంఘటన జరిగిన ప్రదేశం'),
                            border: const OutlineInputBorder(),
                            hintText: 'Where did the incident occur?',
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? _getLocalizedLabel('Enter incident location',
                                  'సంఘటన జరిగిన ప్రదేశాన్ని నమోదు చేయండి')
                              : null,
                        ),
                        const SizedBox(height: 16),

                        const SizedBox(height: 16),

                        // Incident Date
                        InkWell(
                          onTap: _pickIncidentDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: _getLocalizedLabel(
                                  'Incident Date', 'సంఘటన తేదీ'),
                              border: const OutlineInputBorder(),
                            ),
                            child: Text(
                              _incidentDate == null
                                  ? _getLocalizedLabel(
                                      'Select date', 'తేదీని ఎంచుకోండి')
                                  : _incidentDate!
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Accused Details
                        TextFormField(
                          controller: _accusedDetailsController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: _getLocalizedLabel(
                                'Accused Details', 'నిందితుల వివరాలు'),
                            border: const OutlineInputBorder(),
                            hintText: _getLocalizedLabel(
                                'Name, age, description of accused',
                                'నిందితుల పేరు, వయస్సు, వివరణ'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Witnesses
                        TextFormField(
                          controller: _witnessesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText:
                                _getLocalizedLabel('Witnesses', 'సాక్షులు'),
                            border: const OutlineInputBorder(),
                            hintText: _getLocalizedLabel(
                                'Name and contact of witnesses',
                                'సాక్షుల పేరు మరియు సంప్రదింపు వివరాలు'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Stolen Property
                        TextFormField(
                          controller: _stolenPropertyController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: _getLocalizedLabel(
                                'Stolen Property', 'దొంగిలించబడిన ఆస్తి'),
                            border: const OutlineInputBorder(),
                            hintText: _getLocalizedLabel(
                                'List items and estimated value',
                                'వస్తువులు మరియు అంచనా విలువ'),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Evidence Status
                        TextFormField(
                          controller: _evidenceStatusController,
                          decoration: InputDecoration(
                            labelText: _getLocalizedLabel(
                                'Evidence Status', 'సాక్ష్యాల స్థితి'),
                            border: const OutlineInputBorder(),
                            hintText: _getLocalizedLabel(
                                'CCTV, documents, etc. available?',
                                'CCTV, పత్రాలు మొదలైనవి అందుబాటులో ఉన్నాయా?'),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ================= JURISDICTION DETAILS =================
                        Text(
                          _getLocalizedLabel(
                              'Jurisdiction for Filing Complaint',
                              'ఫిర్యాదు దాఖలు చేయడానికి అధికార పరిధి'),
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        // District
                        _picker(
                          label: _getLocalizedLabel('District', 'జిల్లా'),
                          value: _districtController.text.isEmpty
                              ? null
                              : _districtController.text,
                          onTap: () {
                            _openSearchableDropdown(
                              title: _getLocalizedLabel(
                                  'Select District', 'జిల్లాను ఎంచుకోండి'),
                              items: _districtStations.keys.toList(),
                              selectedValue: _districtController.text,
                              onSelected: (v) {
                                setState(() {
                                  _districtController.text = v;
                                  _stationController.clear();
                                });
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Police Station
                        _picker(
                          label: _getLocalizedLabel(
                              'Police Station', 'పోలీస్ స్టేషన్'),
                          value: _stationController.text.isEmpty
                              ? null
                              : _stationController.text,
                          onTap: _districtController.text.isEmpty
                              ? null
                              : () {
                                  _openSearchableDropdown(
                                    title: _getLocalizedLabel(
                                        'Select Police Station',
                                        'పోలీస్ స్టేషన్‌ను ఎంచుకోండి'),
                                    items: _districtStations[
                                            _districtController.text] ??
                                        [],
                                    selectedValue: _stationController.text,
                                    onSelected: (v) {
                                      setState(
                                          () => _stationController.text = v);
                                    },
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                ),

                // === PETITION DETAILS ===
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(localizations.petitionDetails,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _groundsController,
                          maxLines: 8,
                          decoration: InputDecoration(
                              labelText: localizations.groundsReasonsLabel,
                              border: const OutlineInputBorder()),
                          validator: (v) => v?.isEmpty ?? true
                              ? localizations.required
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // === HANDWRITTEN DOCUMENTS ===
                        Text(localizations.handwrittenDocuments,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: Text(localizations.uploadDocuments),
                              onPressed: _isSubmitting ? null : _pickAndOcr,
                            ),
                            if (_pickedFiles.isNotEmpty)
                              Text(localizations
                                  .filesCount(_pickedFiles.length)),
                            if (_ocrService.isExtracting)
                              const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                          ],
                        ),
                        if (_pickedFiles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8)),
                            child: ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _pickedFiles.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final f = _pickedFiles[i];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.insert_drive_file),
                                  title: Text(f.name,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      '${(f.size / 1024).toStringAsFixed(1)} KB'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => setState(
                                            () => _pickedFiles.removeAt(i)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        if (_ocrService.result != null) ...[
                          const SizedBox(height: 16),
                          _buildOcrSummary(theme),
                        ],

                        const SizedBox(height: 24),

                        // === RELATED DOCUMENT PROOFS ===
                        Text(
                          _getLocalizedLabel(
                              'Related Document Proofs (Optional)',
                              'సంబంధిత పత్ర రుజువులు (ఐచ్ఛికం)'),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: Text(_getLocalizedLabel('Upload Proofs',
                                  'రుజువులను అప్‌లోడ్ చేయండి')),
                              onPressed: _isSubmitting
                                  ? null
                                  : () async {
                                      final result =
                                          await FilePicker.platform.pickFiles(
                                        allowMultiple: true,
                                        withData: true,
                                        type: FileType.any,
                                      );
                                      if (result != null &&
                                          result.files.isNotEmpty) {
                                        setState(() {
                                          _proofFiles.addAll(result.files);
                                        });
                                      }
                                    },
                            ),
                            if (_proofFiles.isNotEmpty)
                              Text(_getLocalizedLabel(
                                '${_proofFiles.length} file(s) selected',
                                '${_proofFiles.length} ఫైల్(లు) ఎంచుకోబడ్డాయి',
                              )),
                          ],
                        ),
                        if (_proofFiles.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.separated(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _proofFiles.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final f = _proofFiles[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  leading: const Icon(Icons.attach_file),
                                  title: Text(f.name,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      '${(f.size / 1024).toStringAsFixed(1)} KB'),
                                  trailing: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    icon: const Icon(Icons.close),
                                    onPressed: _isSubmitting
                                        ? null
                                        : () => setState(
                                            () => _proofFiles.removeAt(index)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPetition,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(localizations.createPetition,
                          style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ));
  }
}
