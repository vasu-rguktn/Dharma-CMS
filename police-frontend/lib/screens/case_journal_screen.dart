// lib/screens/case_journal_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/models/case_doc.dart';
import 'package:Dharma/models/case_journal_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Dharma/services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'dart:convert'; // For json decode
import 'package:Dharma/providers/police_auth_provider.dart';

class CaseJournalScreen extends StatefulWidget {
  const CaseJournalScreen({super.key});

  @override
  State<CaseJournalScreen> createState() => _CaseJournalScreenState();
}

class _CaseJournalScreenState extends State<CaseJournalScreen> {
  String? _selectedCaseId;
  List<CaseJournalEntry> _journalEntries = [];
  bool _isLoading = false;
  bool _hasLoaded = false;

  // Your signature orange
  static const Color orange = Color(0xFFFC633C);

  // AI Investigation Report state
  // NOTE: For Flutter web, we call the FastAPI backend explicitly via full URL.
  // In production, replace this with your deployed API base URL or an environment-based config.
  final Dio _dio = Dio();
  String? _generatedReportText;
  String? _finalPdfUrl;
  bool _isGeneratingReport = false;
  bool _isSavingFinalReport = false;
  final TextEditingController _reportController = TextEditingController();

  // Police Profile Data & Hierarchy
  String? _policeRank;
  String? _policeRange;
  String? _policeDistrict;
  String? _policeStation;

  // Filter selections
  String? _selectedRange;
  String? _selectedDistrict;
  String? _selectedStation;

  Map<String, Map<String, List<String>>> _policeHierarchy = {};
  bool _hierarchyLoading = true;

  /* ================= RANK TIERS ================= */
  // (Same constants as CasesScreen)
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
    if (mounted) _fetchData();
  }

  Future<void> _loadHierarchyData() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/data/ap_police_hierarchy_complete.json');
      final Map<String, dynamic> data = json.decode(jsonStr);

      Map<String, Map<String, List<String>>> hierarchy = {};
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
      if (mounted) setState(() => _hierarchyLoading = false);
    }
  }

  Future<void> _fetchData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final caseProvider = Provider.of<CaseProvider>(context, listen: false);
    
    String? targetDistrict;
    String? targetStation;

    if (auth.role == 'police') {
      // 1. Station Level: Must filter by assigned station
      if (_isStationLevel() && _policeStation != null) {
        targetStation = _policeStation;
        targetDistrict = _policeDistrict; 
      }
      // 2. District Level (SP, ASP):
      else if (_districtLevelRanks.contains(_policeRank)) {
        // If they chose a specific station, filter by it
        if (_selectedStation != null) {
          targetStation = _selectedStation;
          targetDistrict = _selectedDistrict ?? _policeDistrict;
        } 
        // Otherwise, filter by their district (SHOW ALL STATIONS IN DISTRICT)
        else {
          targetStation = null; // Important: Clear station filter
          targetDistrict = _policeDistrict;
        }
      }
      // 3. Range Level (IGP, DIG):
      else if (_rangeLevelRanks.contains(_policeRank)) {
        if (_selectedStation != null) {
          targetStation = _selectedStation;
          targetDistrict = _selectedDistrict; 
        } else if (_selectedDistrict != null) {
          targetStation = null;
          targetDistrict = _selectedDistrict;
        } else if (_policeRange != null) {
          // Fallback to no filter essentially, or filtered by range if backend supported it
          targetStation = null;
          targetDistrict = null; 
        }
      }
      // 4. State Level (DGP):
      else if (_stateLevelRanks.contains(_policeRank)) {
        if (_selectedStation != null) {
          targetStation = _selectedStation;
          targetDistrict = _selectedDistrict;
        } else if (_selectedDistrict != null) {
          targetStation = null;
          targetDistrict = _selectedDistrict;
        }
      }
      // Fallback
      else {
         targetStation = _selectedStation;
         targetDistrict = _selectedDistrict ?? _policeDistrict;
      }
    }

    print('📖 [JOURNAL] Fetching with District=$targetDistrict, Station=$targetStation');
    await caseProvider.fetchCases(
      userId: auth.user?.uid,
      isAdmin: auth.role == 'police',
      district: targetDistrict,
      station: targetStation,
    );
  }

  // --- Hierarchy Helpers ---

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

  List<String> _getAvailableRanges() => _policeHierarchy.keys.toList();

  List<String> _getAvailableDistricts() {
    if (_selectedRange != null) return _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
    if (_policeRange != null) return _policeHierarchy[_policeRange]?.keys.toList() ?? [];
    return [];
  }

  List<String> _getAvailableStations() {
    String? targetRange = _selectedRange ?? _policeRange;
    String? targetDistrict = _selectedDistrict ?? _policeDistrict;

    if (targetRange == null && targetDistrict != null) {
      for (var range in _policeHierarchy.keys) {
         if (_policeHierarchy[range]?.containsKey(targetDistrict) ?? false) {
           targetRange = range;
           break;
         }
      }
    }

    if (targetRange == null || targetDistrict == null) return [];
    return _policeHierarchy[targetRange]?[targetDistrict] ?? [];
  }

  void _onRangeChanged(String? range) {
    setState(() {
      _selectedRange = range;
      _selectedDistrict = null;
      _selectedStation = null;
      _selectedCaseId = null; // Clear selection on filter change
    });
    _fetchData();
  }

  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedStation = null;
      _selectedCaseId = null;
    });
    _fetchData();
  }

  void _onStationChanged(String? station) {
    setState(() {
      _selectedStation = station;
      _selectedCaseId = null;
    });
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Logic moved to initState
  }

  Future<void> _fetchJournalEntries(String caseId) async {
    setState(() {
      _isLoading = true;
      _selectedCaseId = caseId;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('caseJournalEntries')
          .where('caseId', isEqualTo: caseId)
          .orderBy('dateTime', descending: true)
          .get();

      setState(() {
        _journalEntries = snapshot.docs
            .map((doc) => CaseJournalEntry.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorLoadingJournal(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showEditEntryDialog(CaseJournalEntry entry) async {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Only the officer who created the entry can edit it (rules also enforce this)
    if (authProvider.user?.uid != entry.officerUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.errorAddingEntry('You can only edit your own entries')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final entryController = TextEditingController(text: entry.entryText);
    String selectedActivity = entry.activityType;
    List<PlatformFile> newFiles = [];
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickFiles() async {
            final result = await FilePicker.platform.pickFiles(allowMultiple: true);
            if (result != null) {
              setState(() {
                newFiles = result.files;
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit journal entry'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedActivity,
                    decoration: InputDecoration(
                      labelText: localizations.activityType,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      localizations.firRegistered,
                      localizations.evidenceCollected,
                      localizations.witnessExamined,
                      localizations.arrestMade,
                      localizations.medicalReportObtained,
                      localizations.sceneVisited,
                      localizations.documentSubmitted,
                      localizations.hearingAttended,
                      localizations.other,
                    ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => selectedActivity = value!,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: entryController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: localizations.entryDetails,
                      hintText: localizations.entryDetailsHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Existing attachments: ${(entry.attachmentUrls ?? []).length}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: isSubmitting ? null : pickFiles,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Add more files'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (newFiles.isNotEmpty)
                        Flexible(
                          child: Text(
                            '${newFiles.length} new file(s) selected',
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: Text(localizations.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: orange),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (entryController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(localizations.pleaseEnterEntryDetails), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        try {
                          setState(() => isSubmitting = true);

                          // Upload any newly added files and append to existing URLs
                          List<String> allUrls = List<String>.from(entry.attachmentUrls ?? []);
                          print('[DEBUG] Base URLs before merge: ${allUrls.length}');
                          
                          if (newFiles.isNotEmpty) {
                            final timestamp = DateTime.now()
                                .toString()
                                .split('.')
                                .first
                                .replaceAll(':', '-')
                                .replaceAll(' ', '_');
                            final folderPath = 'case_journal/${entry.caseId}/entries/$timestamp';
                            final newUrls = await StorageService.uploadMultipleFiles(
                              files: newFiles,
                              folderPath: folderPath,
                            );

                            if (newUrls.isEmpty) {
                               throw Exception("Upload failed: No files were successfully uploaded.");
                            }
                            
                            allUrls.addAll(newUrls);
                            print('[DEBUG] New URLs added: ${newUrls.length}');
                          }
                          
                          print('[DEBUG] Final Update URLs: ${allUrls.length}');

                          await FirebaseFirestore.instance
                              .collection('caseJournalEntries')
                              .doc(entry.id)
                              .update({
                            'entryText': entryController.text.trim(),
                            'activityType': selectedActivity,
                            'attachmentUrls': allUrls,
                            'modifiedAt': Timestamp.now(),
                          });

                          Navigator.pop(dialogContext);
                          await _fetchJournalEntries(_selectedCaseId!);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Journal entry updated'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating entry: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => isSubmitting = false);
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(localizations.save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddEntryDialog() {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final entryController = TextEditingController();
    String selectedActivity = localizations.firRegistered;
    List<PlatformFile> selectedFiles = [];
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickFiles() async {
            final result = await FilePicker.platform.pickFiles(allowMultiple: true);
            if (result != null) {
              setState(() {
                selectedFiles = result.files;
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(localizations.addJournalEntry),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedActivity,
                    decoration: InputDecoration(
                      labelText: localizations.activityType,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      localizations.firRegistered,
                      localizations.evidenceCollected,
                      localizations.witnessExamined,
                      localizations.arrestMade,
                      localizations.medicalReportObtained,
                      localizations.sceneVisited,
                      localizations.documentSubmitted,
                      localizations.hearingAttended,
                      localizations.other,
                    ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => selectedActivity = value!,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: entryController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: localizations.entryDetails,
                      hintText: localizations.entryDetailsHint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Attach documents (evidence, reports, etc.)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: isSubmitting ? null : pickFiles,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Add files'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (selectedFiles.isNotEmpty)
                        Flexible(
                          child: Text(
                            '${selectedFiles.length} file(s) selected',
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: Text(localizations.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: orange),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (entryController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(localizations.pleaseEnterEntryDetails), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        try {
                          setState(() => isSubmitting = true);

                          List<String>? attachmentUrls;
                          if (selectedFiles.isNotEmpty) {
                            final timestamp = DateTime.now()
                                .toString()
                                .split('.')
                                .first
                                .replaceAll(':', '-')
                                .replaceAll(' ', '_');
                            final folderPath = 'case_journal/$_selectedCaseId/entries/$timestamp';
                            attachmentUrls = await StorageService.uploadMultipleFiles(
                              files: selectedFiles,
                              folderPath: folderPath,
                            );

                            if (attachmentUrls.isEmpty) {
                               throw Exception("Upload failed: No files were successfully uploaded. Please check your connection or try again.");
                            }
                          }

                          final entry = CaseJournalEntry(
                            caseId: _selectedCaseId!,
                            officerUid: authProvider.user!.uid,
                            officerName: authProvider.userProfile?.displayName ?? 'Officer',
                            officerRank: authProvider.userProfile?.rank ?? 'N/A',
                            dateTime: Timestamp.now(),
                            entryText: entryController.text.trim(),
                            activityType: selectedActivity,
                            attachmentUrls: attachmentUrls,
                          );

                          await FirebaseFirestore.instance
                              .collection('caseJournalEntries')
                              .add(entry.toMap());
                          Navigator.pop(dialogContext);
                          await _fetchJournalEntries(_selectedCaseId!);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(localizations.journalEntryAddedSuccess), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(localizations.errorAddingEntry(e.toString())), backgroundColor: Colors.red),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => isSubmitting = false);
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(localizations.addEntry),
              ),
            ],
          );
        },
      ),
    );
  }

  dynamic _serializeForApi(dynamic value) {
    if (value is Timestamp) {
      return {
        '__type': 'timestamp',
        'value': value.toDate().toIso8601String(),
      };
    }
    if (value is Map<String, dynamic>) {
      return value.map((key, v) => MapEntry(key, _serializeForApi(v)));
    }
    if (value is List) {
      return value.map(_serializeForApi).toList();
    }
    return value;
  }

  Map<String, dynamic> _buildFirPayload(CaseDoc caseDoc) {
    final raw = caseDoc.toMap();
    final withId = {
      'id': caseDoc.id,
      ...raw,
    };
    return withId.map((key, value) => MapEntry(key, _serializeForApi(value)));
  }

  Map<String, dynamic> _buildJournalEntryPayload(CaseJournalEntry entry) {
    final raw = entry.toMap();
    final withId = {
      'id': entry.id,
      ...raw,
    };
    return withId.map((key, value) => MapEntry(key, _serializeForApi(value)));
  }

  List<Map<String, dynamic>> _deriveEvidenceList() {
    final List<Map<String, dynamic>> evidence = [];
    for (final entry in _journalEntries) {
      if (entry.attachmentUrls != null && entry.attachmentUrls!.isNotEmpty) {
        for (final url in entry.attachmentUrls!) {
          evidence.add({
            'description': '${entry.activityType} - attachment',
            'url': url,
          });
        }
      }
    }
    return evidence;
  }

  Future<void> _generateInvestigationReport({required bool finaliseWithOverride}) async {
    final caseProvider = Provider.of<CaseProvider>(context, listen: false);

    if (_selectedCaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a case to generate the investigation report.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedCase = caseProvider.cases.firstWhere(
      (c) => c.id == _selectedCaseId,
      orElse: () => throw Exception('Selected case not found'),
    );

    if (_journalEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No journal entries available for this case.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      if (finaliseWithOverride) {
        _isSavingFinalReport = true;
      } else {
        _isGeneratingReport = true;
        _generatedReportText = null;
        _finalPdfUrl = null;
      }
    });

    try {
      final firPayload = _buildFirPayload(selectedCase);
      final journalPayload = _journalEntries.map(_buildJournalEntryPayload).toList();
      final evidenceList = _deriveEvidenceList();

      final Map<String, dynamic> requestBody = {
        'fir': firPayload,
        'case_journal_entries': journalPayload,
        'evidence_list': evidenceList,
      };

      if (finaliseWithOverride) {
        requestBody['override_report_text'] = _reportController.text.trim();
      }

      final response = await _dio.post(
        'https://fastapi-app-335340524683.asia-south1.run.app/api/generate-investigation-report',
        data: requestBody,
      );

      final data = response.data as Map<String, dynamic>;
      final reportText = data['report_text'] as String? ?? '';
      final pdfUrl = data['pdf_url'] as String? ?? '';

      setState(() {
        _generatedReportText = reportText;
        if (!finaliseWithOverride) {
          _reportController.text = reportText;
        }
        _finalPdfUrl = pdfUrl.isNotEmpty ? pdfUrl : null;
      });

      // If this is the finalised report, persist the PDF URL onto the case document
      // so that it appears under Case Details → Final Report tab.
      if (finaliseWithOverride && pdfUrl.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('cases')
            .doc(_selectedCaseId)
            .update({
          'investigationReportPdfUrl': pdfUrl,
          'investigationReportGeneratedAt': Timestamp.now(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              finaliseWithOverride
                  ? 'Investigation report finalised and PDF attached to case.'
                  : 'AI investigation report draft generated. Please review before finalising.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate investigation report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
          _isSavingFinalReport = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // BEAUTIFUL HEADER WITH ORANGE BACK ARROW
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: orange,
                        size: 32,
                        shadows: const [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations.caseJournal,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.3),
                    ),
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 24, 24),
              child: Text(
                localizations.caseJournalDesc,
                style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.4),
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HIERARCHY FILTERS (Only for Police)
                    if (Provider.of<AuthProvider>(context).role == 'police' && !_hierarchyLoading)
                       Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.security, size: 20, color: Colors.blue.shade900),
                                const SizedBox(width: 8),
                                Text(
                                  'Jurisdiction Filter',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            if (_canFilterByRange()) ...[
                              _buildFilterDropdown(
                                label: 'Range',
                                value: _selectedRange,
                                items: _getAvailableRanges(),
                                onChanged: _onRangeChanged,
                              ),
                              const SizedBox(height: 8),
                            ],

                            if (_canFilterByDistrict()) ...[
                              _buildFilterDropdown(
                                label: 'District',
                                value: _selectedDistrict,
                                items: _getAvailableDistricts(),
                                onChanged: _onDistrictChanged,
                              ),
                              const SizedBox(height: 8),
                            ],

                            if (_canFilterByStation()) ...[
                              _buildFilterDropdown(
                                label: 'Station',
                                value: _selectedStation,
                                items: _getAvailableStations(),
                                onChanged: _onStationChanged,
                              ),
                            ],
                            
                            if (_isStationLevel() && _policeStation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Station: $_policeStation', 
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                       ),

                    // Case Selector Card
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
                                Icon(Icons.folder_open_rounded, color: orange, size: 28),
                                const SizedBox(width: 12),
                                Text(localizations.selectCase, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (caseProvider.cases.isEmpty)
                              Text(localizations.noCasesAvailable, style: TextStyle(color: Colors.grey[600]))
                            else
                              DropdownButtonFormField<String>(
                                value: _selectedCaseId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  hintText: localizations.chooseCaseToViewJournal,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                selectedItemBuilder: (BuildContext context) {
                                  return caseProvider.cases.map<Widget>((caseDoc) {
                                    return Text(
                                      '${caseDoc.firNumber} - ${caseDoc.title}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 16),
                                    );
                                  }).toList();
                                },
                                items: caseProvider.cases.map((caseDoc) {
                                  return DropdownMenuItem(
                                    value: caseDoc.id,
                                    child: Text(
                                      '${caseDoc.firNumber} - ${caseDoc.title}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) _fetchJournalEntries(value);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Journal Timeline
                    if (_selectedCaseId != null)
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title + open case icon
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      localizations.investigationDiary,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    tooltip: localizations.openCaseDetails,
                                    onPressed: () => context.go('/cases/$_selectedCaseId'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Action buttons – vertical alignment for better mobile UX
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isGeneratingReport
                                          ? null
                                          : () {
                                              _generateInvestigationReport(
                                                finaliseWithOverride: false,
                                              );
                                            },
                                      icon: _isGeneratingReport
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.description_rounded, size: 20),
                                      label: const Text('Generate Court Document'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: orange,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _showAddEntryDialog,
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        color: orange,
                                        size: 22,
                                      ),
                                      label: Text(
                                        localizations.addJournalEntryTooltip,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: orange,
                                        side: BorderSide(color: orange.withOpacity(0.5)),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (_isLoading)
                                const Center(
                                  child: CircularProgressIndicator(color: orange),
                                )
                              else if (_journalEntries.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.description_outlined,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        localizations.noJournalEntries,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        localizations.noJournalEntriesDesc,
                                        style: TextStyle(color: Colors.grey[600]),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                _buildJournalTimeline(),
                            ],
                          ),
                        ),
                      ),

                    if (_generatedReportText != null) ...[
                      const SizedBox(height: 24),
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
                                  Icon(Icons.gavel_rounded, color: orange, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Investigation Report Draft',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange[200]!),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'AI-generated draft – Verified by Investigating Officer',
                                        style: TextStyle(color: Colors.orange[800], fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Review and edit the draft before finalising and generating the court PDF.',
                                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 320,
                                child: TextField(
                                  controller: _reportController,
                                  maxLines: null,
                                  expands: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  style: const TextStyle(fontSize: 14, height: 1.4),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isSavingFinalReport
                                        ? null
                                        : () {
                                            _generateInvestigationReport(finaliseWithOverride: true);
                                          },
                                    icon: _isSavingFinalReport
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                                    label: const Text('Confirm & Generate PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (_finalPdfUrl != null)
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        // Resolve relative URLs (e.g. "/static/reports/...") against the FastAPI backend.
                                        final String resolvedUrl = _finalPdfUrl!.startsWith('http')
                                            ? _finalPdfUrl!
                                            : 'https://fastapi-app-335340524683.asia-south1.run.app$_finalPdfUrl';

                                        final url = Uri.parse(resolvedUrl);
                                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                          debugPrint('Could not open $url');
                                        }
                                      },
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Open Generated PDF'),
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

  Widget _buildJournalTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _journalEntries.length,
      itemBuilder: (context, index) {
        final entry = _journalEntries[index];
        final isLast = index == _journalEntries.length - 1;
        return _buildTimelineItem(entry, isLast);
      },
    );
  }

  Widget _buildTimelineItem(CaseJournalEntry entry, bool isLast) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot and line
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Dot vertically aligned with the heading inside the card
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: orange.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Journal entry card
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Activity type and officer rank - properly aligned vertically
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.activityType,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: orange,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                entry.officerRank,
                                style: TextStyle(
                                  color: orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(entry.entryText, style: const TextStyle(height: 1.5)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(entry.officerName, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            color: Colors.grey[700],
                            tooltip: 'Edit entry',
                            onPressed: () => _showEditEntryDialog(entry),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Created: ${_formatTimestamp(entry.dateTime)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (entry.modifiedAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.edit_calendar, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              'Edited: ${_formatTimestamp(entry.modifiedAt!)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                      if (entry.relatedDocumentId != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 6),
                            Text('Ref: ${entry.relatedDocumentId}', style: TextStyle(color: Colors.blue[700])),
                          ],
                        ),
                      ],
                      if (entry.attachmentUrls != null &&
                          entry.attachmentUrls!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (int i = 0; i < entry.attachmentUrls!.length; i++)
                              ActionChip(
                                avatar: const Icon(Icons.attach_file, size: 16),
                                label: Text('Document ${i + 1}'),
                                onPressed: () async {
                                  final url = Uri.parse(entry.attachmentUrls![i]);
                                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                    debugPrint('Could not open $url');
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    // Searchable dropdown using ModalBottomSheet
    return InkWell(
      onTap: () async {
        if (items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No $label options available')),
          );
          return;
        }

        final searchController = TextEditingController();
        List<String> filtered = List.from(items);

        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => StatefulBuilder(
            builder: (context, setModalState) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text('Select $label',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            filtered = items
                                .where((e) =>
                                    e.toLowerCase().contains(val.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return ListTile(
                              title: Text('All $label'),
                              onTap: () {
                                onChanged(null);
                                Navigator.pop(context);
                              },
                            );
                          }
                          final item = filtered[i - 1];
                          return ListTile(
                            title: Text(item),
                            selected: item == value,
                            trailing: item == value
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              onChanged(item);
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
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? 'All $label',
                style: TextStyle(
                  color: value == null ? Colors.grey.shade600 : Colors.black,
                  fontWeight: value == null ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}