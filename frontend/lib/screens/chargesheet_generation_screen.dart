// lib/screens/chargesheet_generation_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
// import 'dart:html' as html show AnchorElement; // REMOVED for APK build compatibility

class ChargesheetGenerationScreen extends StatefulWidget {
  const ChargesheetGenerationScreen({super.key});

  @override
  State<ChargesheetGenerationScreen> createState() => _ChargesheetGenerationScreenState();
}

class _ChargesheetGenerationScreenState extends State<ChargesheetGenerationScreen> {
  final _incidentTextController = TextEditingController();
  final _additionalInstructionsController = TextEditingController();
  final _dio = Dio(BaseOptions(
    // baseUrl: kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000',
     baseUrl: "https://fastapi-app-335340524683.asia-south1.run.app",

    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 120), // Allow 2 mins for AI generation
  ));

  // Mode: 'file' or 'case'
  String _inputMode = 'file'; 

  // Store PlatformFile to access bytes on web
  PlatformFile? _firFile;
  PlatformFile? _incidentFile;
  
  // Case Fetching
  List<Map<String, dynamic>> _availableCases = [];
  String? _selectedCaseId;
  bool _isLoadingCases = false;

  bool _isLoading = false;
  bool _isDownloading = false;
  Map<String, dynamic>? _chargeSheet;

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  @override
  void dispose() {
    _incidentTextController.dispose();
    _additionalInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _fetchCases() async {
    setState(() => _isLoadingCases = true);
    try {
      print('Fetching cases from: ${_dio.options.baseUrl}/api/case-lookup/all');
      final response = await _dio.get('/api/case-lookup/all');
      
      print('Response status: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      
      if (response.data is List) {
        final casesList = List<Map<String, dynamic>>.from(response.data);
        print('Fetched ${casesList.length} cases');
        
        setState(() {
          _availableCases = casesList;
        });
        
        if (casesList.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cases found in database. Please add cases first.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        print('Unexpected response format: ${response.data}');
      }
    } catch (e) {
      print("Error fetching cases: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cases: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingCases = false);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload the mandatory FIR Document"), backgroundColor: Colors.red));
      return;
    }
    if (_inputMode == 'case' && _selectedCaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Case from the list"), backgroundColor: Colors.red));
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final formData = FormData();
      
      // Source
      if (_inputMode == 'file') {
        formData.files.add(MapEntry('fir_document', await _getMultipartFile(_firFile!)));
      } else {
        formData.fields.add(MapEntry('case_id', _selectedCaseId!));
      }
      
      // Incident File
      if (_incidentFile != null) {
        formData.files.add(MapEntry('incident_details_file', await _getMultipartFile(_incidentFile!)));
      }
      
      // Incident Text
      if (_incidentTextController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('incident_details_text', _incidentTextController.text.trim()));
      }

      // Additional Instructions
      if (_additionalInstructionsController.text.trim().isNotEmpty) {
        formData.fields.add(MapEntry('additional_instructions', _additionalInstructionsController.text.trim()));
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

  Future<void> _downloadChargesheet() async {
    if (_chargeSheet == null) return;
    
    setState(() => _isDownloading = true);
    
    try {
      final chargesheetText = _chargeSheet!['chargeSheet'] ?? '';
      
      if (kIsWeb) {
        // For web: Create download link (DISABLED for APK build)
        // final bytes = utf8.encode(chargesheetText);
        // final base64Data = base64Encode(bytes);
        // final anchor = html.AnchorElement(
        //   href: 'data:text/plain;charset=utf-8;base64,$base64Data',
        // )
        //   ..setAttribute('download', 'chargesheet_${DateTime.now().millisecondsSinceEpoch}.txt')
        //   ..click();
        print("Web download triggered but disabled for APK build compatibility.");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chargesheet downloaded'), backgroundColor: Colors.green),
          );
        }
      } else {
        // For mobile/desktop: Save to documents directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'chargesheet_${DateTime.now().millisecondsSinceEpoch}.txt';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(chargesheetText);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to: ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
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

  @override
  Widget build(BuildContext context) {
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

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Icon
                            Row(
                              children: [
                                Icon(Icons.file_present_rounded, color: orange, size: 28),
                                const SizedBox(width: 12),
                                const Text("Case Source", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Toggle
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text("Upload Document"),
                                    value: 'file',
                                    groupValue: _inputMode,
                                    activeColor: orange,
                                    onChanged: (val) => setState(() => _inputMode = val!),
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text("Select Existing Case"),
                                    value: 'case',
                                    groupValue: _inputMode,
                                    activeColor: orange,
                                    onChanged: (val) => setState(() => _inputMode = val!),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),

                            // Dynamic Input Area
                            if (_inputMode == 'file') ...[
                               InkWell(
                                onTap: _pickFIRFile,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.upload_file, color: _firFile != null ? Colors.green : Colors.grey),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _firFile != null ? _firFile!.name : "Upload FIR (PDF/Doc/Image)",
                                          style: TextStyle(color: _firFile != null ? Colors.black87 : Colors.grey),
                                        ),
                                      ),
                                      if (_firFile != null)
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () => setState(() => _firFile = null),
                                        ),
                                    ],
                                  ),
                                ),
                              ),


                            ] else ...[
                                if (_isLoadingCases)
                                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                                else if (_availableCases.isEmpty)
                                  const Text("No cases found in database.", style: TextStyle(color: Colors.grey))
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        isExpanded: true,
                                        hint: const Text("Select FIR Case to Analyze"),
                                        value: _selectedCaseId,
                                        items: _availableCases.map((c) {
                                          final fir = c['firNumber'] ?? 'No FIR';
                                          final title = c['title'] ?? 'No Title';
                                          return DropdownMenuItem<String>(
                                            value: c['id'].toString(),
                                            child: Text("$fir - $title", overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList(),
                                        onChanged: (val) => setState(() => _selectedCaseId = val),
                                      ),
                                    ),
                                  ),
                            ],

                            const SizedBox(height: 24),

                            // 2. Incident Details (Optional)
                            const Text("Incident Details / Evidence", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text("Upload a file (Photo/PDF) OR write details below.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 12),
                            
                            // File Upload for Incident
                            InkWell(
                              onTap: _pickIncidentFile,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.withOpacity(0.5)),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.image_search, color: _incidentFile != null ? Colors.green : Colors.grey),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _incidentFile != null ? _incidentFile!.name : "Upload Evidence (Photo/PDF)",
                                        style: TextStyle(color: _incidentFile != null ? Colors.black87 : Colors.grey),
                                      ),
                                    ),
                                    if (_incidentFile != null)
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => setState(() => _incidentFile = null),
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
                                hintText: "Or type incident details/evidence description here...",
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 3. Additional Instructions
                            Text(localizations.additionalInstructionsOptional, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _additionalInstructionsController,
                              maxLines: 3,
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

                            // Submit Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: (_isLoading || (_inputMode == 'file' && _firFile == null) || (_inputMode == 'case' && _selectedCaseId == null)) ? null : _handleSubmit,
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
                            Text(localizations.generatingChargeSheetWait, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],

                    // Result Area
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

                              // Disclaimer
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      localizations.aiChargeSheetDisclaimer,
                                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
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
                                    icon: const Icon(Icons.copy),
                                    label: Text(localizations.copyDraft),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: orange,
                                      side: BorderSide(color: orange),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _isDownloading ? null : _downloadChargesheet,
                                    icon: _isDownloading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.download),
                                    label: Text(_isDownloading ? 'Downloading...' : 'Download'),
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