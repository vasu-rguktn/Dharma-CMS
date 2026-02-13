// lib/screens/chargesheet_generation_screen.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:Dharma/utils/file_downloader/file_downloader.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/police_auth_provider.dart';
import 'package:Dharma/data/station_data_constants.dart';
import 'package:printing/printing.dart';
import 'package:Dharma/services/chargesheet_service.dart';
import 'package:Dharma/models/chargesheet_model.dart';
import 'package:Dharma/models/case_journal_entry.dart';
import 'package:Dharma/models/case_status.dart';
import 'package:Dharma/services/storage_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChargesheetGenerationScreen extends StatefulWidget {
  const ChargesheetGenerationScreen({super.key});

  @override
  State<ChargesheetGenerationScreen> createState() =>
      _ChargesheetGenerationScreenState();
}

class _ChargesheetGenerationScreenState
    extends State<ChargesheetGenerationScreen> {
  final _incidentTextController = TextEditingController();
  final _additionalInstructionsController = TextEditingController();
  final _stationSearchController = TextEditingController();
  final _chargesheetService = ChargesheetService(); // Service instance

  final _dio = Dio(BaseOptions(
    // baseUrl: kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000',
    baseUrl: "https://fastapi-app-335340524683.asia-south1.run.app",

    connectTimeout: const Duration(seconds: 10),
    receiveTimeout:
        const Duration(seconds: 120), // Allow 2 mins for AI generation
  ));

  // Mode: 'file' or 'case'
  String _inputMode = 'file';

  // Store PlatformFile to access bytes on web
  PlatformFile? _firFile;
  PlatformFile? _incidentFile;

  // Case Fetching
  String? _selectedCaseId;

  bool _isLoading = false;
  bool _isDownloading = false;
  Map<String, dynamic>? _chargeSheet;

  // Hierarchy & Filters
  Map<String, Map<String, List<String>>> _policeHierarchy = {};
  bool _hierarchyLoading = true;

  // Police Profile Data
  String? _policeRank;
  String? _policeRange;
  String? _policeDistrict;
  String? _policeStation;

  // Filter selections
  String? _selectedRange;
  String? _selectedDistrict;
  String? _selectedStation;
  String _stationSearchQuery = '';

  /* ================= RANK TIERS ================= */

  static const List<String> _stateLevelRanks = [
    'Director General of Police',
    'Additional Director General of Police',
  ];

  static const List<String> _rangeLevelRanks = [
    'Inspector General of Police',
    'Deputy Inspector General of Police',
  ];

  static const List<String> _districtLevelRanks = [
    'Superintendent of Police',
    'Additional Superintendent of Police',
  ];

  static const List<String> _stationLevelRanks = [
    'Deputy Superintendent of Police',
    'Inspector of Police',
    'Sub Inspector of Police',
    'Assistant Sub Inspector of Police',
    'Head Constable',
    'Police Constable',
  ];

  @override
  void initState() {
    super.initState();
    _loadHierarchyData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileAndFetch();
    });
  }

  @override
  void dispose() {
    _incidentTextController.dispose();
    _additionalInstructionsController.dispose();
    _stationSearchController.dispose();
    super.dispose();
  }

  void _loadHierarchyData() {
    try {
      Map<String, Map<String, List<String>>> hierarchy = {};
      final data = kPoliceHierarchyComplete;

      data.forEach((range, districts) {
        if (districts is Map) {
          Map<String, List<String>> districtMap = {};
          districts.forEach((district, stations) {
            final stationList = List<String>.from(stations ?? []);
            districtMap[district.toString()] = stationList;
          });
          hierarchy[range] = districtMap;
        }
      });
      if (mounted) {
        setState(() {
          _policeHierarchy = hierarchy;
          _hierarchyLoading = false;
        });
      }
    } catch (e) {
      print('Error loading hierarchy: $e');
    }
  }

  Future<void> _loadProfileAndFetch() async {
    final auth = context.read<AuthProvider>();
    if (auth.role == 'police') {
      final policeProvider = context.read<PoliceAuthProvider>();
      await policeProvider.loadPoliceProfileIfLoggedIn();
      final profile = policeProvider.policeProfile;

      if (profile != null && mounted) {
        setState(() {
          _policeRank = profile['rank']?.toString();
          _policeRange = profile['range']?.toString();
          _policeDistrict = profile['district']?.toString();
          _policeStation = profile['stationName']?.toString();
        });
      }
    }
    if (mounted) _fetchCases();
  }

  Future<void> _fetchCases() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final caseProvider = Provider.of<CaseProvider>(context, listen: false);

    // Determine effective filters
    String? targetDistrict;
    String? targetStation;

    if (auth.role == 'police') {
      // 1. Station Level
      if (_isStationLevel() && _policeStation != null) {
        targetStation = _policeStation;
        targetDistrict = _policeDistrict;
      }
      // 2. District Level
      else if (_districtLevelRanks.contains(_policeRank)) {
        if (_selectedStation != null) {
          targetStation = _selectedStation;
          targetDistrict = _selectedDistrict ?? _policeDistrict;
        } else {
          targetStation = null;
          targetDistrict = _policeDistrict;
        }
      }
      // 3. Range Level
      else if (_rangeLevelRanks.contains(_policeRank)) {
        if (_selectedStation != null) {
          targetStation = _selectedStation;
          targetDistrict = _selectedDistrict;
        } else if (_selectedDistrict != null) {
          targetStation = null;
          targetDistrict = _selectedDistrict;
        } else {
          targetStation = null;
          targetDistrict = null; // No default filter
        }
      }
      // 4. State Level
      else if (_stateLevelRanks.contains(_policeRank)) {
        if (_selectedStation != null) {
          targetStation = _selectedStation;
          targetDistrict = _selectedDistrict;
        } else if (_selectedDistrict != null) {
          targetStation = null;
          targetDistrict = _selectedDistrict;
        }
      } else {
        targetStation = _selectedStation;
        targetDistrict = _selectedDistrict ?? _policeDistrict;
      }
    }

    try {
      await caseProvider.fetchCases(
        userId: auth.user?.uid,
        isAdmin: auth.role == 'police',
        district: targetDistrict,
        station: targetStation,
      );
    } catch (e) {
      print("Error fetching cases: $e");
    }
  }

  /* ================= RANK VISIBILITY HELPERS ================= */

  bool _canFilterByRange() {
    if (_policeRank == null) return false;
    return _stateLevelRanks.contains(_policeRank);
  }

  bool _canFilterByDistrict() {
    if (_policeRank == null) return false;
    return _stateLevelRanks.contains(_policeRank) ||
        _rangeLevelRanks.contains(_policeRank);
  }

  bool _canFilterByStation() {
    if (_policeRank == null) return false;
    return _stateLevelRanks.contains(_policeRank) ||
        _rangeLevelRanks.contains(_policeRank) ||
        _districtLevelRanks.contains(_policeRank);
  }

  bool _isStationLevel() {
    if (_policeRank == null) return false;
    return _stationLevelRanks.contains(_policeRank);
  }

  /* ================= HIERARCHY HELPERS ================= */

  List<String> _getAvailableRanges() {
    return _policeHierarchy.keys.toList();
  }

  List<String> _getAvailableDistricts() {
    if (_selectedRange != null) {
      return _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
    }
    if (_policeRange != null) {
      return _policeHierarchy[_policeRange]?.keys.toList() ?? [];
    }
    return [];
  }

  List<String> _getAvailableStations() {
    String? targetRange;
    String? targetDistrict;

    if (_selectedDistrict != null) {
      targetDistrict = _selectedDistrict;
    } else if (_policeDistrict != null) {
      targetDistrict = _policeDistrict;
    }

    if (_selectedRange != null) {
      targetRange = _selectedRange;
    } else if (_policeRange != null) {
      targetRange = _policeRange;
    } else if (targetDistrict != null) {
      for (var range in _policeHierarchy.keys) {
        final districtMap = _policeHierarchy[range] ?? {};
        final matchedKey = districtMap.keys.firstWhere(
          (k) => k.trim().toLowerCase() == targetDistrict!.trim().toLowerCase(),
          orElse: () => '',
        );
        if (matchedKey.isNotEmpty) {
          targetRange = range;
          targetDistrict = matchedKey;
          break;
        }
      }
    }

    List<String> stations = [];
    if (targetRange != null && targetDistrict != null) {
      final districtMap = _policeHierarchy[targetRange] ?? {};
      if (districtMap.containsKey(targetDistrict)) {
        stations = List.from(districtMap[targetDistrict] ?? []);
      } else {
        final matchedKey = districtMap.keys.firstWhere(
          (k) => k.trim().toLowerCase() == targetDistrict!.trim().toLowerCase(),
          orElse: () => '',
        );
        if (matchedKey.isNotEmpty) {
          stations = List.from(districtMap[matchedKey] ?? []);
        }
      }
    }

    stations.sort();
    return stations;
  }

  /* ================= HANDLERS ================= */

  void _onRangeChanged(String? range) {
    setState(() {
      _selectedRange = range;
      _selectedDistrict = null;
      _selectedStation = null;
      _selectedCaseId = null;
    });
    _fetchCases();
  }

  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedStation = null;
      _selectedCaseId = null;
    });
    _fetchCases();
  }

  void _onStationChanged(String? station) {
    setState(() {
      _selectedStation = station;
      _selectedCaseId = null;
    });
    _fetchCases();
  }

  Future<void> _pickFIRFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
        withData: true, // Ensure bytes are loaded for web
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _firFile = result.files.single;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking file: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickIncidentFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _incidentFile = result.files.single;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking file: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<MultipartFile> _getMultipartFile(PlatformFile file) async {
    if (kIsWeb) {
      return MultipartFile.fromBytes(file.bytes!, filename: file.name);
    } else {
      return await MultipartFile.fromFile(file.path!, filename: file.name);
    }
  }

  Future<void> _handleSubmit() async {
    // Validation
    if (_inputMode == 'file' && _firFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please upload the mandatory FIR Document"),
          backgroundColor: Colors.red));
      return;
    }
    if (_inputMode == 'case' && _selectedCaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select a Case from the list"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formData = FormData();

      // Source
      if (_inputMode == 'file') {
        formData.files
            .add(MapEntry('fir_document', await _getMultipartFile(_firFile!)));
      } else {
        formData.fields.add(MapEntry('case_id', _selectedCaseId!));
      }

      // Incident File
      if (_incidentFile != null) {
        formData.files.add(MapEntry(
            'incident_details_file', await _getMultipartFile(_incidentFile!)));
      }

      // Incident Text
      if (_incidentTextController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry(
            'incident_details_text', _incidentTextController.text.trim()));
      }

      // Additional Instructions
      if (_additionalInstructionsController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('additional_instructions',
            _additionalInstructionsController.text.trim()));
      }

      final response =
          await _dio.post('/api/chargesheet-generation', data: formData);
      setState(() => _chargeSheet = response.data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.draftChargeSheetGenerated),
              backgroundColor: Colors.green),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .failedToGenerateChargeSheet(error.toString())),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _cleanMarkdown(String text) {
    // Remove Markdown formatting symbols
    return text
        .replaceAll('**', '') // Remove bold markers
        .replaceAll('__', '') // Remove alternative bold markers
        .replaceAll('### ', '') // Remove heading markers (with space)
        .replaceAll('###', '') // Remove heading markers (without space)
        .replaceAll('## ', '')
        .replaceAll('##', '')
        .replaceAll('# ', '')
        .replaceAll('#', '')
        .replaceAll('* ', '') // Remove list bullets
        .replaceAll(
            '*', '') // Remove italic markers (careful not to double remove)
        .replaceAll('_', '') // Remove alternative italic markers
        .replaceAll('`', '') // Remove code blocks
        .replaceAll('[', '') // Remove links
        .replaceAll(']', '')
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('’', "'") // Replace smart quote with ASCII apostrophe
        .replaceAll('“', '"') // Replace smart open quote
        .replaceAll('”', '"'); // Replace smart close quote
  }

  Future<Uint8List> _generateChargesheetPdf(PdfPageFormat format) async {
    final chargesheetText = _chargeSheet!['chargeSheet'] ?? '';
    final cleanedText = _cleanMarkdown(chargesheetText);

    final pdf = pw.Document();
    final paragraphs = cleanedText.split('\n');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return paragraphs.map((para) {
            final text = para.trim();
            if (text.isEmpty) {
              return pw.SizedBox(height: 10);
            }

            final upperText = text.toUpperCase();
            final isTitle = (upperText == "CHARGE SHEET" ||
                upperText == "FINAL REPORT" ||
                upperText == "CHARGE SHEET / FINAL REPORT" ||
                upperText == "(UNDER SECTION 173 CR.P.C.)" ||
                upperText.startsWith("IN THE COURT OF"));

            if (isTitle) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Center(
                  child: pw.Text(
                    text,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              );
            }

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                text,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
                textAlign: pw.TextAlign.left,
              ),
            );
          }).toList();
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _printChargesheet() async {
    if (_chargeSheet == null) return;
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async =>
          await _generateChargesheetPdf(format),
    );
  }

  Future<void> _downloadDocx() async {
    if (_chargeSheet == null) return;
    setState(() => _isDownloading = true);

    try {
      final text = _chargeSheet!['chargeSheet'] ?? '';
      // Clean the text before sending to backend for DOCX generation
      final cleanedText = _cleanMarkdown(text);

      final formData = FormData.fromMap({
        'chargesheetText': cleanedText,
      });

      final response = await _dio.post(
        '/api/chargesheet-generation/download-docx',
        data: formData,
        options: Options(responseType: ResponseType.bytes),
      );

      final fileName =
          'chargesheet_${DateTime.now().millisecondsSinceEpoch}.docx';

      final savedPath = await downloadFile(response.data, fileName);

      if (mounted) {
        // Check if savedPath is not null for success.
        // Note: Web downloadFile might return null even on success if it just triggers a browser download.
        // We assume success if no exception was thrown for now, or check kIsWeb.

        bool success = savedPath != null;
        if (kIsWeb)
          success =
              true; // On web, we can't easily get the path, so assume success if no error.

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ DOCX saved successfully!\n📂 $fileName'),
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

  Future<void> _downloadChargesheet() async {
    if (_chargeSheet == null) return;

    setState(() => _isDownloading = true);

    try {
      print('📄 Starting chargesheet PDF generation...');
      final chargesheetText = _chargeSheet!['chargeSheet'] ?? '';
      final cleanedText = _cleanMarkdown(chargesheetText);

      // Generate PDF
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
          'chargesheet_${DateTime.now().millisecondsSinceEpoch}.pdf';

      print(
          '📥 Chargesheet PDF generated (${bytes.length} bytes), calling downloadFile...');
      final savedPath = await downloadFile(bytes, fileName);
      print('📥 downloadFile returned: $savedPath');

      if (mounted) {
        // Check if savedPath is not null for success.
        // Note: Web downloadFile might return null even on success if it just triggers a browser download.
        // We assume success if no exception was thrown for now, or check kIsWeb.

        bool success = savedPath != null;
        if (kIsWeb)
          success =
              true; // On web, we can't easily get the path, so assume success if no error.

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Chargesheet saved successfully!\n📂 $fileName\n📍 Check Downloads folder'),
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
      print('❌ Error in _downloadChargesheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _saveChargesheet() async {
    if (_chargeSheet == null) return;

    final TextEditingController titleController = TextEditingController(
      text: "Chargesheet - ${DateTime.now().toString().split('.')[0]}",
    );

    // Show dialog to get title
    final String? title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Draft Chargesheet"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: "Draft Title",
            hintText: "Enter a title for this draft",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, titleController.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (title == null || title.isEmpty) return; // User cancelled

    try {
      final content = _chargeSheet!['chargeSheet'] as String;

      await _chargesheetService.saveChargesheet(
        content: content,
        caseId: _selectedCaseId,
        title: title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Draft Saved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteChargesheet(String id) async {
    try {
      await _chargesheetService.deleteChargesheet(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Chargesheet deleted'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSavedChargesheets() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true, // Allow full height if needed
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, // Fixed height
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📂 Saved Chargesheets',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<List<ChargesheetModel>>(
                  stream: _chargesheetService.getUserChargesheets(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No saved drafts found.',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    final list = snapshot.data!;
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Confirm Delete"),
                                  content: const Text(
                                      "Are you sure you want to delete this chargesheet?"),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text("Delete",
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (_) => _deleteChargesheet(item.id),
                          child: Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color(0xFFFC633C).withOpacity(0.1),
                                child: const Icon(Icons.description,
                                    color: Color(0xFFFC633C)),
                              ),
                              title: Text(item.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Created: ${item.createdAt.toString().split('.')[0]}\n${item.caseId != null ? "Case ID: ${item.caseId}" : ""}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              onTap: () {
                                // Load back into view
                                setState(() {
                                  _chargeSheet = {'chargeSheet': item.content};
                                });
                                Navigator.pop(context); // Close modal
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Draft Loaded!')),
                                );
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios,
                                    size: 16),
                                onPressed: () {
                                  setState(() {
                                    _chargeSheet = {
                                      'chargeSheet': item.content
                                    };
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                        );
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
  }

  Future<void> _copyToClipboard() async {
    if (_chargeSheet == null) return;

    try {
      await Clipboard.setData(
        ClipboardData(text: _chargeSheet!['chargeSheet'] ?? ''),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.draftCopied),
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

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          isDense: true,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text("All $label",
                  style: const TextStyle(color: Colors.grey)),
            ),
            ...items.map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 13)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... existing build method start ...
    final localizations = AppLocalizations.of(context)!;
    const Color orange = Color(0xFFFC633C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                              offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  IconButton(
                    onPressed: _showSavedChargesheets,
                    icon: const Icon(Icons.history_rounded, size: 28),
                    color: orange,
                    tooltip: 'Saved Drafts',
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Icon
                            Row(
                              children: [
                                Icon(Icons.file_present_rounded,
                                    color: orange, size: 28),
                                const SizedBox(width: 12),
                                const Text("Case Source",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Toggle - Improved for Mobile
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  RadioListTile<String>(
                                    title: const Text("Upload Document"),
                                    subtitle:
                                        const Text("Upload FIR PDF/Image"),
                                    value: 'file',
                                    groupValue: _inputMode,
                                    activeColor: orange,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12))),
                                    onChanged: (val) =>
                                        setState(() => _inputMode = val!),
                                  ),
                                  Divider(
                                      height: 1, color: Colors.grey.shade300),
                                  RadioListTile<String>(
                                    title: const Text("Select Existing Case"),
                                    subtitle:
                                        const Text("Choose from database"),
                                    value: 'case',
                                    groupValue: _inputMode,
                                    activeColor: orange,
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12))),
                                    onChanged: (val) =>
                                        setState(() => _inputMode = val!),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Dynamic Input Area
                            if (_inputMode == 'file') ...[
                              InkWell(
                                onTap: _pickFIRFile,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.upload_file,
                                          color: _firFile != null
                                              ? Colors.green
                                              : Colors.grey),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _firFile != null
                                              ? _firFile!.name
                                              : "Upload FIR (PDF/Doc/Image)",
                                          style: TextStyle(
                                              color: _firFile != null
                                                  ? Colors.black87
                                                  : Colors.grey),
                                        ),
                                      ),
                                      if (_firFile != null)
                                        IconButton(
                                          icon: const Icon(Icons.close,
                                              color: Colors.red),
                                          onPressed: () =>
                                              setState(() => _firFile = null),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              // FILTERS
                              if (Provider.of<AuthProvider>(context).role ==
                                  'police') ...[
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  if (_canFilterByRange())
                                    _buildFilterDropdown(
                                        label: "Range",
                                        value: _selectedRange,
                                        items: _getAvailableRanges(),
                                        onChanged: _onRangeChanged),
                                  if (_canFilterByDistrict())
                                    _buildFilterDropdown(
                                        label: "District",
                                        value: _selectedDistrict,
                                        items: _getAvailableDistricts(),
                                        onChanged: _onDistrictChanged),
                                  if (_canFilterByStation())
                                    LayoutBuilder(
                                        builder: (context, constraints) {
                                      return Autocomplete<String>(
                                        optionsBuilder: (TextEditingValue
                                            textEditingValue) {
                                          final options =
                                              _getAvailableStations();
                                          if (textEditingValue.text.isEmpty) {
                                            return options;
                                          }
                                          return options.where((String option) {
                                            return option
                                                .toLowerCase()
                                                .contains(textEditingValue.text
                                                    .toLowerCase());
                                          });
                                        },
                                        onSelected: (String selection) {
                                          _onStationChanged(selection);
                                        },
                                        fieldViewBuilder: (BuildContext context,
                                            TextEditingController
                                                fieldTextEditingController,
                                            FocusNode fieldFocusNode,
                                            VoidCallback onFieldSubmitted) {
                                          if (_selectedStation != null &&
                                              fieldTextEditingController
                                                  .text.isEmpty) {
                                            fieldTextEditingController.text =
                                                _selectedStation!;
                                          }
                                          return TextField(
                                            controller:
                                                fieldTextEditingController,
                                            focusNode: fieldFocusNode,
                                            decoration: InputDecoration(
                                              labelText: "Station",
                                              hintText:
                                                  "Search or Select Station",
                                              suffixIcon: const Icon(
                                                  Icons.arrow_drop_down),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                            ),
                                          );
                                        },
                                        optionsViewBuilder:
                                            (BuildContext context,
                                                AutocompleteOnSelected<String>
                                                    onSelected,
                                                Iterable<String> options) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: Material(
                                              elevation: 4.0,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: SizedBox(
                                                width: constraints.maxWidth,
                                                height: 200,
                                                child: ListView.builder(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  itemCount: options.length,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    final String option =
                                                        options
                                                            .elementAt(index);
                                                    return InkWell(
                                                      onTap: () {
                                                        onSelected(option);
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 12.0,
                                                                horizontal:
                                                                    16.0),
                                                        child: Text(option),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                ]),
                                const SizedBox(height: 16),
                              ],

                              // Case Dropdown
                              Consumer<CaseProvider>(
                                  builder: (context, caseProvider, child) {
                                if (caseProvider.isLoading) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                if (caseProvider.cases.isEmpty) {
                                  return const Text(
                                      "No cases found matching filters.",
                                      style: TextStyle(color: Colors.grey));
                                }
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      hint: const Text(
                                          "Select FIR Case to Analyze"),
                                      value: _selectedCaseId != null &&
                                              caseProvider.cases.any((c) =>
                                                  c.id == _selectedCaseId)
                                          ? _selectedCaseId
                                          : null,
                                      items: caseProvider.cases.map((c) {
                                        return DropdownMenuItem<String>(
                                          value: c.id,
                                          child: Text(
                                              "${c.firNumber} - ${c.title}",
                                              overflow: TextOverflow.ellipsis),
                                        );
                                      }).toList(),
                                      onChanged: (val) =>
                                          setState(() => _selectedCaseId = val),
                                    ),
                                  ),
                                );
                              }),
                            ],

                            const SizedBox(height: 24),

                            // 2. Incident Details (Optional)
                            // ... existing code ...
                            const Text("Incident Details / Evidence",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text(
                                "Upload a file (Photo/PDF) OR write details below.",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 12),

                            // File Upload for Incident
                            InkWell(
                              onTap: _pickIncidentFile,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.image_search,
                                        color: _incidentFile != null
                                            ? Colors.green
                                            : Colors.grey),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _incidentFile != null
                                            ? _incidentFile!.name
                                            : "Upload Evidence (Photo/PDF)",
                                        style: TextStyle(
                                            color: _incidentFile != null
                                                ? Colors.black87
                                                : Colors.grey),
                                      ),
                                    ),
                                    if (_incidentFile != null)
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.red),
                                        onPressed: () => setState(
                                            () => _incidentFile = null),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Text Input for Incident
                            TextField(
                              controller: _incidentTextController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    "Or type incident details/evidence description here...",
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 3. Additional Instructions
                            Text(localizations.additionalInstructionsOptional,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _additionalInstructionsController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    localizations.chargesheetInstructionsHint,
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

                            // Submit Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: (_isLoading ||
                                        (_inputMode == 'file' &&
                                            _firFile == null) ||
                                        (_inputMode == 'case' &&
                                            _selectedCaseId == null))
                                    ? null
                                    : _handleSubmit,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.gavel_rounded),
                                label: Text(_isLoading
                                    ? localizations.generating
                                    : localizations.generateDraftChargeSheet),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                  disabledBackgroundColor: Colors.grey[300],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Loading Indicator
                    if (_isLoading) ...[
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: orange),
                            const SizedBox(height: 16),
                            Text(localizations.generatingChargeSheetWait,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],

                    // Result Area
                    if (_chargeSheet != null) ...[
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
                                  Icon(Icons.description_rounded,
                                      color: orange, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      localizations.generatedDraftChargeSheet,
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
                                  _chargeSheet!['chargeSheet'] ??
                                      localizations.noChargeSheetGenerated,
                                  style: const TextStyle(
                                      fontSize: 15, height: 1.6),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Disclaimer
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange[700], size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      localizations.aiChargeSheetDisclaimer,
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Action Buttons
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  children: [
                                    // Row 1: Persistence (Save & Log)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _saveChargesheet,
                                            icon: const Icon(Icons.save_alt,
                                                size: 18),
                                            label: const Text("Save Draft"),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green,
                                              side: const BorderSide(
                                                  color: Colors.green),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _logToCaseJournal,
                                            icon: const Icon(Icons.menu_book,
                                                size: 18),
                                            label: const Text("Log to Journal"),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.indigo,
                                              side: const BorderSide(
                                                  color: Colors.indigo),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Row 2: Downloads (PDF & DOCX)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _isDownloading
                                                ? null
                                                : _downloadChargesheet,
                                            icon: _isDownloading
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.white),
                                                  )
                                                : const Icon(
                                                    Icons.picture_as_pdf,
                                                    size: 18),
                                            label: Text(
                                                _isDownloading ? '...' : 'PDF'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: orange,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _isDownloading
                                                ? null
                                                : _downloadDocx,
                                            icon: _isDownloading
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.white),
                                                  )
                                                : const Icon(Icons.description,
                                                    size: 18),
                                            label: Text(_isDownloading
                                                ? '...'
                                                : 'DOCX'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: orange,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Row 3: Utilities (Print & Copy)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _printChargesheet,
                                            icon: const Icon(Icons.print,
                                                size: 18),
                                            label: const Text("Print"),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: orange,
                                              side: BorderSide(color: orange),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _copyToClipboard,
                                            icon: const Icon(Icons.copy,
                                                size: 18),
                                            label:
                                                Text(localizations.copyDraft),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: orange,
                                              side: BorderSide(color: orange),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
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
  /* ================= CASE JOURNAL LOGGING ================= */

  Future<void> _logToCaseJournal() async {
    if (_chargeSheet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No chargesheet generated to log.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedCaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select a Case ID from the top dropdown to log this chargesheet.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TextEditingController summaryController = TextEditingController(
      text: "Draft Chargesheet generated via AI assistance.",
    );

    // Show dialog to get summary and activity type
    String selectedActivity = 'Chargesheet Generated';
    final TextEditingController customActivityController =
        TextEditingController();
    List<PlatformFile> attachedFiles = [];
    bool attachChargesheet = true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        String currentActivity = selectedActivity;
        bool shouldAttach = attachChargesheet;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickFiles() async {
              final result =
                  await FilePicker.platform.pickFiles(allowMultiple: true);
              if (result != null) {
                setState(() {
                  attachedFiles = result.files;
                });
              }
            }

            return AlertDialog(
              title: const Text("Log to Case Journal"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select activity type and add details.",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: currentActivity,
                      decoration: const InputDecoration(
                        labelText: "Activity Type",
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Chargesheet Generated',
                        'Investigation Update',
                        'Evidence Added',
                        'Other'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          currentActivity = newValue!;
                        });
                      },
                    ),
                    if (currentActivity == 'Other') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customActivityController,
                        decoration: const InputDecoration(
                          labelText: "Specify Activity",
                          hintText: "Enter custom activity type",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: summaryController,
                      decoration: const InputDecoration(
                        labelText: "Entry Summary",
                        hintText: "Details about this action",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text("Attach Generated Chargesheet (PDF)",
                          style: TextStyle(fontSize: 13)),
                      value: shouldAttach,
                      onChanged: (val) {
                        setState(() => shouldAttach = val ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Other Attachments: ${attachedFiles.length}",
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: pickFiles,
                          icon: const Icon(Icons.attach_file, size: 16),
                          label: const Text("Add Files",
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black,
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    if (attachedFiles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          children: attachedFiles
                              .map((f) => Text("• ${f.name}",
                                  style: const TextStyle(fontSize: 11),
                                  overflow: TextOverflow.ellipsis))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    String finalActivity = currentActivity == 'Other'
                        ? customActivityController.text.trim()
                        : currentActivity;
                    if (finalActivity.isEmpty) {
                      finalActivity = "General Entry";
                    }
                    Navigator.pop(context, {
                      'activity': finalActivity,
                      'summary': summaryController.text.trim(),
                      'attachPdf': shouldAttach,
                    });
                  },
                  child: const Text("Log Entry"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return; // User cancelled

    final String activityType = result['activity']!;
    final String summaryText = result['summary']!;
    final bool attachPdf = result['attachPdf']!;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      final policeProvider =
          Provider.of<PoliceAuthProvider>(context, listen: false);
      final caseProvider = Provider.of<CaseProvider>(context, listen: false);
      final profile = policeProvider.policeProfile;

      List<String> attachmentUrls = [];

      // 1. Upload Generated PDF if requested
      if (attachPdf) {
        final pdfBytes = await _generateChargesheetPdf(PdfPageFormat.a4);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final pdfPath =
            'case_journal/${_selectedCaseId}/entries/chargesheet_$timestamp.pdf';

        // We use a dummy PlatformFile for StorageService compatibility or just putData directly if we can't
        // But StorageService.uploadFile expects PlatformFile.
        // Let's use putData directly here since it's easier for raw bytes.
        final ref = FirebaseStorage.instance.ref().child(pdfPath);
        final metadata = SettableMetadata(contentType: 'application/pdf');
        final uploadTask = ref.putData(pdfBytes, metadata);
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        attachmentUrls.add(url);
      }

      // 2. Upload other selected files
      if (attachedFiles.isNotEmpty) {
        final folderPath = 'case_journal/${_selectedCaseId}/entries';
        final urls = await StorageService.uploadMultipleFiles(
          files: attachedFiles,
          folderPath: folderPath,
        );
        attachmentUrls.addAll(urls);
      }

      final entry = CaseJournalEntry(
        caseId: _selectedCaseId!,
        officerUid: user?.uid ?? '',
        officerName: profile?['displayName'] ?? 'Officer',
        officerRank: profile?['rank'] ?? 'Official',
        dateTime: Timestamp.now(),
        entryText: summaryText.isNotEmpty
            ? summaryText
            : "Draft Chargesheet generated via AI assistance.",
        activityType: activityType,
        attachmentUrls: attachmentUrls,
      );

      // FIX: Use the correct collection name 'caseJournalEntries'
      await FirebaseFirestore.instance
          .collection('caseJournalEntries')
          .add(entry.toMap());

      // AUTO-UPDATE CASE STATUS: If activity is Chargesheet Generated, move to Pending Trial
      if (activityType == 'Chargesheet Generated') {
        await caseProvider.updateCaseStatus(
            _selectedCaseId!, CaseStatus.pendingTrial);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logged to Case Journal successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log journal entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
