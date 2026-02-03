import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/models/case_doc.dart';
import 'package:Dharma/models/case_status.dart';
import 'package:Dharma/models/case_journal_entry.dart';
import 'package:Dharma/models/crime_details.dart';
import 'package:Dharma/models/media_analysis.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/screens/geo_camera_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Dharma/services/storage_service.dart';
import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CaseJournalEntry> _journalEntries = [];
  List<MediaAnalysisRecord> _mediaAnalyses = [];
  bool _isLoadingJournal = false;
  bool _isLoadingMedia = false;
  bool _isAnalyzingScene = false;
  
  // New: Multiple Crime Scenes List
  List<CrimeDetails> _crimeScenes = [];
  bool _isLoadingScenes = true;
  bool _isLoadingPetitions = false;
  List<Petition> _linkedPetitions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchCaseJournal();
    _fetchLinkedPetitions();
    _fetchCrimeScenes();
    _fetchMediaAnalyses();
    _fetchCrimeSceneEvidence(); // NEW: Load saved evidence
    
    // Auto-fetch if first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ...
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCaseJournal() async {
    setState(() => _isLoadingJournal = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('caseJournalEntries')
          .where('caseId', isEqualTo: widget.caseId)
          .orderBy('dateTime', descending: true)
          .get();

      setState(() {
        _journalEntries = snapshot.docs
            .map((doc) => CaseJournalEntry.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error fetching journal entries: $e');
    } finally {
      setState(() => _isLoadingJournal = false);
    }
  }

  Future<void> _fetchMediaAnalyses() async {
    setState(() => _isLoadingMedia = true);
    try {
      // Fetch specifically from 'sceneAnalyses' as saved by _analyzeSceneWithAI
      final snapshot = await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('sceneAnalyses')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _mediaAnalyses = snapshot.docs.map((doc) {
          final data = doc.data();
          // Map dynamic AI analysis to structured MediaAnalysisRecord if possible, 
          // or create a generic record to display the text.
          return MediaAnalysisRecord(
            id: doc.id,
            caseId: widget.caseId,
            userId: data['analyzedBy'] ?? 'AI', // Map 'analyzedBy' to 'userId'
            imageDataUri: (data['evidenceFiles'] as List?)?.firstOrNull ?? '', // Map 'evidenceFiles' first item to 'imageDataUri'
            originalFileName: 'AI Analysis Report',
            identifiedElements: [], // Text analysis doesn't strictly follow this structure yet
            sceneNarrative: data['analysisText'] ?? '',
            caseFileSummary: 'AI Analysis',
            createdAt: data['createdAt'] ?? Timestamp.now(),
            updatedAt: data['createdAt'] ?? Timestamp.now(),
          );
        }).toList();
      });
    } catch (e) {
      print('Error fetching media analyses: $e');
    } finally {
      setState(() => _isLoadingMedia = false);
    }
  }

  // Fetch Crime Scenes from Sub-collection
  Future<void> _fetchCrimeScenes() async {
    setState(() => _isLoadingScenes = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('crimeScenes')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _crimeScenes = snapshot.docs
            .map((doc) => CrimeDetails.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error fetching crime scenes: $e');
    } finally {
      if (mounted) setState(() => _isLoadingScenes = false);
    }
  }

  Future<void> _fetchLinkedPetitions() async {
    setState(() => _isLoadingPetitions = true);
    try {
      final caseProvider = Provider.of<CaseProvider>(context, listen: false);
      final caseDoc = caseProvider.cases.firstWhere(
        (c) => c.id == widget.caseId,
        orElse: () => throw Exception('Case not found'),
      );

      final firNumber = caseDoc.firNumber;
      if (firNumber.isEmpty) {
        setState(() => _isLoadingPetitions = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('petitions')
          .where('firNumber', isEqualTo: firNumber)
          .get();

      setState(() {
        _linkedPetitions = snapshot.docs
            .map((doc) => Petition.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error fetching linked petitions: $e');
    } finally {
      setState(() => _isLoadingPetitions = false);
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Fetch saved crime scene evidence from Firestore
  Future<void> _fetchCrimeSceneEvidence() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('crimeSceneEvidence')
          .doc('evidence')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _crimeSceneAttachments = List<String>.from(data['filePaths'] ?? [])
              .where((path) => !path.startsWith('blob:'))
              .toList();
          _sceneAnalysisResult = data['latestAnalysis'];
          final latestRel = data['latestRelevanceAnalysis'];
          _latestRelevanceAnalysis =
              latestRel is Map<String, dynamic> ? latestRel : null;
        });
      }
    } catch (e) {
      print('Error fetching crime scene evidence: $e');
    }
  }

  // Save crime scene evidence to Firestore
  Future<void> _saveCrimeSceneEvidence() async {
    try {
      debugPrint('💾 [SAVING_EVIDENCE] Case: ${widget.caseId}');
      debugPrint('💾 [SAVING_EVIDENCE] Files: $_crimeSceneAttachments');
      
      final sanitizedPaths = _crimeSceneAttachments
          .where((p) => !p.startsWith('blob:'))
          .toList();

      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('crimeSceneEvidence')
          .doc('evidence')
          .set({
        'filePaths': sanitizedPaths,
        'latestAnalysis': _sceneAnalysisResult,
        'latestRelevanceAnalysis': _latestRelevanceAnalysis,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('✅ [SAVING_EVIDENCE] Success for ${widget.caseId}');
    } catch (e) {
      debugPrint('❌ [SAVING_EVIDENCE] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save evidence: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // === AI: Document relevance (FIR vs uploaded evidence) ===
  static const List<String> _backendCandidates = <String>[
    'https://fastapi-app-335340524683.asia-south1.run.app',
    'http://localhost:8080',
  ];

  Future<bool> _isBackendHealthy(String baseUrl) async {
    try {
      final resp = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 6));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> _resolveBackendBaseUrl() async {
    for (final c in _backendCandidates) {
      if (await _isBackendHealthy(c)) return c;
    }
    return _backendCandidates.first;
  }

  Color _gradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _analyzeEvidenceRelevance(List<String> urls) async {
    if (urls.isEmpty) return;
    if (_isCheckingRelevance) return;

    setState(() => _isCheckingRelevance = true);

    try {
      final baseUrl = await _resolveBackendBaseUrl();
      final endpoint =
          '$baseUrl/api/cases/${widget.caseId}/document-relevance';

      final resp = await http
          .post(
            Uri.parse(endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'document_urls': urls,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (resp.statusCode != 200) {
        throw Exception('Backend error ${resp.statusCode}: ${resp.body}');
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map) {
        throw Exception('Unexpected response from backend');
      }

      final analysis = Map<String, dynamic>.from(decoded as Map);

      setState(() => _latestRelevanceAnalysis = analysis);

      // Persist to Firestore so officers can see it later in the case.
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('crimeSceneEvidence')
          .doc('evidence')
          .set({
        'latestRelevanceAnalysis': analysis,
        'relevanceUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        _showRelevanceDialog(analysis);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI relevance check failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingRelevance = false);
    }
  }

  void _showRelevanceDialog(Map<String, dynamic> analysis) {
    final overall = (analysis['overall'] is Map)
        ? Map<String, dynamic>.from(analysis['overall'] as Map)
        : <String, dynamic>{};
    final overallColorStr = (overall['color'] ?? '').toString();
    final overallScore = (overall['score'] ?? '').toString();
    final summary = (overall['summary'] ?? '').toString();

    final docsRaw = analysis['documents'];
    final docs = (docsRaw is List)
        ? docsRaw
            .whereType<Map>()
            .map((d) => Map<String, dynamic>.from(d))
            .toList()
        : <Map<String, dynamic>>[];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified, color: Colors.blueGrey),
            const SizedBox(width: 8),
            const Expanded(child: Text('AI Document Relevance')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _gradeColor(overallColorStr).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _gradeColor(overallColorStr)),
                    ),
                    child: Text(
                      '${overallColorStr.toUpperCase()}  (Score: $overallScore)',
                      style: TextStyle(
                        color: _gradeColor(overallColorStr),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(summary),
              const SizedBox(height: 16),
              const Text(
                'Per-file feedback',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (docs.isEmpty)
                const Text('No documents returned by the analyzer.')
              else
                ...docs.map((d) {
                  final name = (d['name'] ?? d['url'] ?? 'Document').toString();
                  final colorStr = (d['color'] ?? '').toString();
                  final score = (d['score'] ?? '').toString();
                  final reason = (d['reason'] ?? '').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _gradeColor(colorStr).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _gradeColor(colorStr).withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insert_drive_file,
                                color: _gradeColor(colorStr)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$score',
                              style: TextStyle(
                                color: _gradeColor(colorStr),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(reason),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Crime Scene Evidence Handlers
  Future<void> _captureSceneEvidence(CaptureMode mode) async {
    final XFile? capturedFile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeoCameraScreen(captureMode: mode),
      ),
    );

    if (capturedFile != null && mounted) {
      String finalPath = capturedFile.path;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.uploadingCapturedEvidence),
          ),
        );
      }

      try {
        final fileName = capturedFile.name;
        final storagePath =
            'crime-scene-evidence/${widget.caseId}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        PlatformFile platformFile;
        if (kIsWeb) {
          final bytes = await capturedFile.readAsBytes();
          platformFile = PlatformFile(
            name: fileName,
            size: await capturedFile.length(),
            bytes: bytes,
          );
        } else {
          final f = File(capturedFile.path);
          platformFile = PlatformFile(
            name: fileName,
            size: await f.length(),
            path: capturedFile.path,
          );
        }

        final url =
            await StorageService.uploadFile(file: platformFile, path: storagePath);
        if (url == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(AppLocalizations.of(context)!.failedUploadEvidence),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        finalPath = url;
      } catch (e) {
        debugPrint('Error uploading capture: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading capture: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _crimeSceneAttachments.add(finalPath);
      });
      
      // Save to Firestore
      await _saveCrimeSceneEvidence();

      // AI relevance check (FIR vs uploaded evidence)
      await _analyzeEvidenceRelevance([finalPath]);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Geo-tagged ${mode == CaptureMode.image ? "photo" : "video"} captured',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _uploadSceneFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final loc = AppLocalizations.of(context)!;
      
      // Show options: Image or Video
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.uploadEvidence),
          content: Text('Choose file type to upload:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'image'),
              child: Text(loc.image),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'video'),
              child: Text(loc.video),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'file'),
              child: Text(loc.document),
            ),
          ],
        ),
      );

      if (result == null) return;

      XFile? file;
      if (result == 'image') {
        file = await picker.pickImage(source: ImageSource.gallery);
      } else if (result == 'video') {
        file = await picker.pickVideo(source: ImageSource.gallery);
      } else {
        // Use file picker for documents
        final fileResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        );
        
        if (fileResult != null && fileResult.files.isNotEmpty) {
          // Always upload documents to Firebase Storage (Web + Native) so the URL
          // can be analyzed by backend AI and viewed across devices.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.uploadingDocument),
              ),
            );
          }

          final fileIdx = fileResult.files.first;
          final storagePath =
              'crime-scene-evidence/${widget.caseId}/${DateTime.now().millisecondsSinceEpoch}_${fileIdx.name}';

          final url =
              await StorageService.uploadFile(file: fileIdx, path: storagePath);

          if (url == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(AppLocalizations.of(context)!.failedUploadDocument),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          setState(() {
            _crimeSceneAttachments.add(url);
          });

          // Save to Firestore
          await _saveCrimeSceneEvidence();

          // AI relevance check (FIR vs uploaded document)
          await _analyzeEvidenceRelevance([url]);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.documentUploaded),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        return;
      }

      if (file != null && mounted) {
        // Always upload images/videos to Firebase Storage so they can be analyzed
        // and shared across devices.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == 'image'
                    ? AppLocalizations.of(context)!.uploadingCapturedEvidence
                    : AppLocalizations.of(context)!.uploadingCapturedEvidence,
              ),
            ),
          );
        }

        final fileName = file!.name;
        final storagePath =
            'crime-scene-evidence/${widget.caseId}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        PlatformFile platformFile;
        if (kIsWeb) {
          final bytes = await file!.readAsBytes();
          platformFile = PlatformFile(
            name: fileName,
            size: bytes.length,
            bytes: bytes,
          );
        } else {
          final f = File(file!.path);
          platformFile = PlatformFile(
            name: fileName,
            size: await f.length(),
            path: file!.path,
          );
        }

        final url =
            await StorageService.uploadFile(file: platformFile, path: storagePath);

        if (url == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.failedUploadEvidence),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _crimeSceneAttachments.add(url);
        });

        // Save to Firestore
        await _saveCrimeSceneEvidence();

        // AI relevance check (FIR vs uploaded evidence)
        await _analyzeEvidenceRelevance([url]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result == "image" ? "Image" : "Video"} uploaded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeSceneWithAI() async {
    if (_crimeSceneAttachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseCapturUploadEvidenceFirst),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzingScene = true;
      _sceneAnalysisResult = null;
    });

    try {
      // Initialize Gemini AI
      if (!dotenv.isInitialized) {
        throw Exception('DotEnv is not initialized. Please ensure assets/env.txt exists and is loaded in main.dart');
      }
      
      final apiKey = dotenv.maybeGet('GEMINI_API_KEY');
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in assets/env.txt file');
      }
      
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      // Detect language
      final languageCode = Localizations.localeOf(context).languageCode;
      String languageInstruction = "Provide the response in English.";
      if (languageCode == 'te') {
        languageInstruction = "Provide the response in Telugu language (తెలుగు). Ensure technical forensic terms are explained clearly in Telugu.";
      }

      // Prepare the prompt
      final prompt = '''
Analyze this crime scene evidence image/video and provide a detailed forensic analysis including:

1. **Scene Overview**: Describe what you observe in the scene
2. **Potential Evidence**: Identify any visible evidence or items of interest
3. **Environmental Factors**: Note lighting, weather conditions, location type
4. **Forensic Observations**: Point out any blood stains, weapons, disturbances, or other forensic markers
5. **Recommendations**: Suggest what additional evidence should be collected or areas to investigate

$languageInstruction

Provide a professional, detailed analysis suitable for law enforcement documentation.
''';

      // Get the first image file
      final imagePath = _crimeSceneAttachments.firstWhere(
        (path) {
          final p = path.toLowerCase().split('?').first;
          return p.endsWith('.jpg') || p.endsWith('.jpeg') || p.endsWith('.png');
        },
        orElse: () => _crimeSceneAttachments.first,
      );

      Uint8List imageBytes;

      final isUrl =
          imagePath.startsWith('http://') || imagePath.startsWith('https://');

      if (kIsWeb && imagePath.startsWith('blob:')) {
        // Correct way to read blob bytes on web
        imageBytes = await XFile(imagePath).readAsBytes();
      } else if (isUrl || kIsWeb) {
        final Uri url = Uri.parse(imagePath);
        final response = await http.get(url);
        if (response.statusCode != 200) {
          throw Exception('Failed to download image from URL');
        }
        imageBytes = response.bodyBytes;
      } else {
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          throw Exception('Local image file not found');
        }
        imageBytes = await imageFile.readAsBytes();
      }

      // Generate analysis
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final analysisText = response.text ?? 'No analysis generated';

      setState(() {
        _sceneAnalysisResult = analysisText;
        _isAnalyzingScene = false;
      });

      // Save analysis to Firestore (sceneAnalyses collection)
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('sceneAnalyses')
          .add({
        'analysisText': analysisText,
        'evidenceFiles': _crimeSceneAttachments,
        'createdAt': FieldValue.serverTimestamp(),
        'analyzedBy': 'Gemini AI',
      });

      // Also save to crime scene evidence (for persistence)
      await _saveCrimeSceneEvidence();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sceneAnalysisComplete),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzingScene = false;
        _sceneAnalysisResult = 'Error analyzing scene: $e\n\nPlease ensure you have configured your Gemini API key.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show options dialog for evidence (Download or Analyze)
  Future<void> _showEvidenceOptions(String filePath, int index) async {
    final fileName = filePath.split('/').last;
    final isVideo = filePath.toLowerCase().endsWith('.mp4') ||
        filePath.toLowerCase().endsWith('.mov');
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Title
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Download option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.download, color: Colors.green),
                  ),
                  title: Text(AppLocalizations.of(context)!.downloadEvidence),
                  subtitle: Text('Save to device Downloads folder'),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadEvidence(filePath);
                  },
                ),
                
                // Analyze option (only for images)
                if (!isVideo)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.purple),
                    ),
                    title: Text(AppLocalizations.of(context)!.analyzeWithAI),
                    subtitle: Text(AppLocalizations.of(context)!.getForensicAnalysis),
                    onTap: () {
                      Navigator.pop(context);
                      _analyzeSingleEvidence(filePath);
                    },
                  ),
                
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // Download evidence file
  Future<void> _downloadEvidence(String filePath) async {
    try {
      if (kIsWeb) {
        // Web download: Just open the URL
        final Uri url = Uri.parse(filePath);
        // Try generic launch
        try {
          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
             // Fallback
             await launchUrl(url, mode: LaunchMode.platformDefault);
          }
        } catch (e) {
             // Last resort fallback
             await launchUrl(url, mode: LaunchMode.platformDefault);
        }
        return;
      }

      // Native download
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      // Get the file name
      final fileName = filePath.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final evidenceFileName = 'EVIDENCE_${timestamp}_$fileName';
      
      // Use app's documents directory (no special permissions needed)
      final Directory? appDocDir = await getApplicationDocumentsDirectory();
      
      if (appDocDir == null) {
        throw Exception('Could not access app storage');
      }
      
      // Create Evidence folder in app documents
      final evidenceDir = Directory('${appDocDir.path}/Evidence');
      if (!await evidenceDir.exists()) {
        await evidenceDir.create(recursive: true);
      }
      
      final newPath = '${evidenceDir.path}/$evidenceFileName';
      await file.copy(newPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evidence Downloaded!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Saved to: Evidence/$evidenceFileName',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.accessViaFileManager,
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      print('Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Analyze single evidence file with AI
  Future<void> _analyzeSingleEvidence(String filePath) async {
    setState(() {
      _isAnalyzingScene = true;
      _sceneAnalysisResult = null;
    });

    try {
      if (!dotenv.isInitialized) {
        throw Exception('DotEnv is not initialized. Please ensure assets/env.txt exists and is loaded in main.dart');
      }

      final apiKey = dotenv.maybeGet('GEMINI_API_KEY');
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in assets/env.txt file');
      }
      
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      final prompt = '''
Analyze this crime scene evidence image and provide a detailed forensic analysis including:

1. **Scene Overview**: Describe what you observe
2. **Potential Evidence**: Identify any visible evidence or items of interest
3. **Environmental Factors**: Note lighting, weather conditions, location type
4. **Forensic Observations**: Point out any blood stains, weapons, disturbances, or other forensic markers
5. **Recommendations**: Suggest what additional evidence should be collected

Provide a professional, detailed analysis suitable for law enforcement documentation.
''';

      Uint8List imageBytes;
      final isUrl = filePath.startsWith('http://') || filePath.startsWith('https://');

      if (kIsWeb && filePath.startsWith('blob:')) {
        imageBytes = await XFile(filePath).readAsBytes();
      } else if (isUrl || kIsWeb) {
        final Uri url = Uri.parse(filePath);
        final response = await http.get(url);
        if (response.statusCode != 200) {
          throw Exception('Failed to download image from URL');
        }
        imageBytes = response.bodyBytes;
      } else {
        final imageFile = File(filePath);
        if (!await imageFile.exists()) {
          throw Exception('Local image file not found');
        }
        imageBytes = await imageFile.readAsBytes();
      }

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final analysisText = response.text ?? 'No analysis generated';

      setState(() {
        _sceneAnalysisResult = analysisText;
        _isAnalyzingScene = false;
      });

      // Save individual analysis to Firestore
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('sceneAnalyses')
          .add({
        'analysisText': analysisText,
        'evidenceFile': filePath,
        'createdAt': FieldValue.serverTimestamp(),
        'analyzedBy': 'Gemini AI',
        'analysisType': 'individual',
      });

      // Also save to crime scene evidence
      await _saveCrimeSceneEvidence();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.analysisComplete),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzingScene = false;
        _sceneAnalysisResult = 'Error analyzing evidence: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Edit Crime Details
    void _showEditCrimeDetailsDialog(ThemeData theme, [CrimeDetails? existingScene]) {
    final crimeTypeController = TextEditingController(text: existingScene?.crimeType ?? '');
    final placeController = TextEditingController(text: existingScene?.placeOfOccurrenceDescription ?? '');
    final evidenceController = TextEditingController(text: existingScene?.physicalEvidenceDescription ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingScene == null ? AppLocalizations.of(context)!.addCrimeScene : AppLocalizations.of(context)!.editCrimeScene),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: crimeTypeController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.crimeType,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: TextField(
                  controller: placeController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.placeDescription,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: TextField(
                  controller: evidenceController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.physicalEvidenceDescription,
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final user = Provider.of<AuthProvider>(context, listen: false).user;
              if (user == null) return;

              final data = {
                'crimeType': crimeTypeController.text,
                'placeOfOccurrenceDescription': placeController.text,
                'physicalEvidenceDescription': evidenceController.text,
                'firNumber': existingScene?.firNumber ?? '', 
                'userId': user.uid,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              final collection = FirebaseFirestore.instance
                  .collection('cases')
                  .doc(widget.caseId)
                  .collection('crimeScenes');

              try {
                if (existingScene == null) {
                  // Add New
                  data['createdAt'] = FieldValue.serverTimestamp();
                  await collection.add(data);
                } else {
                  // Update Existing
                  await collection.doc(existingScene.id).update(data);
                }
                
                _fetchCrimeScenes();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(existingScene == null ? AppLocalizations.of(context)!.crimeSceneAdded : AppLocalizations.of(context)!.crimeSceneUpdated)),
                  );
                }
              } catch (e) {
                print('Error saving crime scene: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  // Generate and Download PDF
  Future<void> _downloadAnalysisPdf(MediaAnalysisRecord report) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.generatingPDF)),
        );
      }
      
      // Fetch Case Details
      final caseProvider = Provider.of<CaseProvider>(context, listen: false);
      final caseDoc = caseProvider.cases.firstWhere(
        (c) => c.id == widget.caseId,
        orElse: () => CaseDoc(id: widget.caseId, title: 'Case', firNumber: 'N/A', userId: '', dateFiled: Timestamp.now(), lastUpdated: Timestamp.now(), status: CaseStatus.newCase),
      );

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Crime Scene Analysis Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Case: ${caseDoc.title}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('FIR: ${caseDoc.firNumber}'),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date: ${_formatTimestamp(report.createdAt)}'),
                    pw.Text('ID: ${widget.caseId}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
                pw.SizedBox(height: 20),
              ]
            );
          },
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey)),
            );
          },
          build: (pw.Context context) {
            final List<pw.Widget> content = [
               pw.Text('Analysis Details:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
               pw.SizedBox(height: 10),
            ];

            final paragraphs = report.sceneNarrative.split('\n');
            for (final para in paragraphs) {
               if (para.trim().isNotEmpty) {
                 content.add(
                   pw.Text(
                     para.trim(),
                     style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
                     textAlign: pw.TextAlign.justify,
                   )
                 );
                 content.add(pw.SizedBox(height: 6));
               }
            }

            content.add(pw.SizedBox(height: 20));
            content.add(pw.Text('Generated by Dharma CMS', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)));
            
            return content;
          },
        ),
      );
      
      final bytes = await pdf.save();
      final fileName = 'Analysis_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Upload to Storage to get a URL (works for both Web and Native validation)
      // Path: cases/{caseId}/reports/{fileName}
       final storagePath = 'case-documents/${widget.caseId}/$fileName';
       
       // Need PlatformFile for StorageService
       final platformFile = PlatformFile(
         name: fileName,
         size: bytes.length,
         bytes: bytes,
       );
       
       final url = await StorageService.uploadFile(file: platformFile, path: storagePath);
       
       if (url != null) {
          // Launch the URL to download/view
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri) || kIsWeb) {
             // Web fallback often needs tolerant launch
             await launchUrl(uri, mode: LaunchMode.externalApplication); 
          } else {
             await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
       } else {
         throw Exception('Failed to generate download link');
       }

    } catch (e) {
      print('PDF Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Delete Analysis Report
  Future<void> _deleteAnalysisReport(MediaAnalysisRecord report) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteReport),
        content: Text(AppLocalizations.of(context)!.deleteReportConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('sceneAnalyses')
          .doc(report.id)
          .delete();

      setState(() {
        _mediaAnalyses.removeWhere((r) => r.id == report.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.reportDeleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting report: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final caseDoc = caseProvider.cases.firstWhere(
      (c) => c.id == widget.caseId,
      orElse: () => throw Exception('Case not found'),
    );

    final theme = Theme.of(context);

    print('📱 [CASE_DETAIL] Screen built for case: ${widget.caseId}');
    print('📚 [CASE_DETAIL] Can pop: ${Navigator.of(context).canPop()}');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            print('⬅️ [CASE_DETAIL] Back button pressed');
            Navigator.of(context).pop();
          },
        ),
        title: Text(caseDoc.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: AppLocalizations.of(context)!.editCase,
            onPressed: () {
               context.push('/cases/new', extra: caseDoc);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          // Align tabs starting from the very left to avoid wasted space
          tabAlignment: TabAlignment.start,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.black87,
          indicator: const BoxDecoration(), // no underline
          dividerColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          tabs: [
            Tab(
              icon: Icon(Icons.description, size: 20),
              child: Text(
                AppLocalizations.of(context)!.firDetails,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Tab(
              icon: Icon(Icons.search, size: 20),
              child: Text(
                AppLocalizations.of(context)!.crimeScene,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Tab(
              icon: Icon(Icons.book, size: 20),
              child: Text(
                AppLocalizations.of(context)!.investigation,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Tab(
              icon: Icon(Icons.archive, size: 20),
              child: Text(
                AppLocalizations.of(context)!.evidence,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Tab(
              icon: Icon(Icons.gavel, size: 20),
              child: Text(
                AppLocalizations.of(context)!.finalReport,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFIRDetailsTab(caseDoc, theme),
          _buildCrimeSceneTab(caseDoc, theme),
          _buildInvestigationTab(caseDoc, theme),
          _buildEvidenceTab(caseDoc, theme),
          _buildFinalReportTab(caseDoc, theme),
        ],
      ),
    );
  }

  Widget _buildFIRDetailsTab(CaseDoc caseDoc, ThemeData theme) {
    String _boolText(bool? value) => value == true ? AppLocalizations.of(context)!.yes : AppLocalizations.of(context)!.no;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top summary card with status + key info
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FIR No: ${caseDoc.firNumber}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              caseDoc.status.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Filed on: ${_formatTimestamp(caseDoc.dateFiled)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(caseDoc.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          caseDoc.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (caseDoc.policeStation != null || caseDoc.district != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        [
                          if (caseDoc.policeStation != null)
                            caseDoc.policeStation!,
                          if (caseDoc.district != null) caseDoc.district!,
                        ].join(' • '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Case information
          _buildSection(
            theme,
            AppLocalizations.of(context)!.caseInformation,
            [
              _buildInfoRow(AppLocalizations.of(context)!.firNumber, caseDoc.firNumber),
              if (caseDoc.year != null) _buildInfoRow(AppLocalizations.of(context)!.year, caseDoc.year!),
              if (caseDoc.originalComplaintId != null)
                _buildInfoRow(AppLocalizations.of(context)!.complaintId, caseDoc.originalComplaintId!),
              if (caseDoc.date != null)
                _buildInfoRow(AppLocalizations.of(context)!.firDate, caseDoc.date!),
              if (caseDoc.firFiledTimestamp != null)
                _buildInfoRow(
                  AppLocalizations.of(context)!.firFiledAt,
                  _formatTimestamp(caseDoc.firFiledTimestamp!),
                ),
              if (caseDoc.district != null)
                _buildInfoRow('District', caseDoc.district!),
              if (caseDoc.policeStation != null)
                _buildInfoRow(AppLocalizations.of(context)!.policeStation, caseDoc.policeStation!),
            ],
          ),

          const SizedBox(height: 16),

          // Occurrence details
          if (caseDoc.occurrenceDay != null ||
              caseDoc.occurrenceDateTimeFrom != null ||
              caseDoc.occurrenceDateTimeTo != null ||
              caseDoc.placeOfOccurrenceStreet != null ||
              caseDoc.placeOfOccurrenceCity != null)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.occurrenceOfOffence,
              [
                if (caseDoc.occurrenceDay != null)
                  _buildInfoRow(AppLocalizations.of(context)!.dayOfOccurrence, caseDoc.occurrenceDay!),
                if (caseDoc.occurrenceDateTimeFrom != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.from,
                    caseDoc.occurrenceDateTimeFrom!,
                  ),
                if (caseDoc.occurrenceDateTimeTo != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.to,
                    caseDoc.occurrenceDateTimeTo!,
                  ),
                if (caseDoc.timePeriod != null)
                  _buildInfoRow(AppLocalizations.of(context)!.timePeriod, caseDoc.timePeriod!),
                if (caseDoc.priorToDateTimeDetails != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.priorToDateTimeDetails,
                    caseDoc.priorToDateTimeDetails!,
                  ),
                if (caseDoc.beatNumber != null)
                  _buildInfoRow(AppLocalizations.of(context)!.beatNumber, caseDoc.beatNumber!),
                if (caseDoc.placeOfOccurrenceStreet != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.streetVillage,
                    caseDoc.placeOfOccurrenceStreet!,
                  ),
                if (caseDoc.placeOfOccurrenceArea != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.areaMandal,
                    caseDoc.placeOfOccurrenceArea!,
                  ),
                if (caseDoc.placeOfOccurrenceCity != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.cityDistrict,
                    caseDoc.placeOfOccurrenceCity!,
                  ),
                if (caseDoc.placeOfOccurrenceState != null)
                  _buildInfoRow(
                    'State',
                    caseDoc.placeOfOccurrenceState!,
                  ),
                if (caseDoc.placeOfOccurrencePin != null)
                  _buildInfoRow(AppLocalizations.of(context)!.pin, caseDoc.placeOfOccurrencePin!),
                if (caseDoc.placeOfOccurrenceLatitude != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.latitude,
                    caseDoc.placeOfOccurrenceLatitude!,
                  ),
                if (caseDoc.placeOfOccurrenceLongitude != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.longitude,
                    caseDoc.placeOfOccurrenceLongitude!,
                  ),
                if (caseDoc.distanceFromPS != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.distanceFromPS,
                    caseDoc.distanceFromPS!,
                  ),
                if (caseDoc.directionFromPS != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.directionFromPS,
                    caseDoc.directionFromPS!,
                  ),
                if (caseDoc.isOutsideJurisdiction != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.outsideJurisdiction,
                    _boolText(caseDoc.isOutsideJurisdiction),
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Information received
          if (caseDoc.informationReceivedDateTime != null ||
              caseDoc.generalDiaryEntryNumber != null ||
              caseDoc.informationType != null)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.informationReceivedAtPS,
              [
                if (caseDoc.informationReceivedDateTime != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.dateTimeReceived,
                    caseDoc.informationReceivedDateTime!,
                  ),
                if (caseDoc.generalDiaryEntryNumber != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.gdEntryNo,
                    caseDoc.generalDiaryEntryNumber!,
                  ),
                if (caseDoc.informationType != null)
                  _buildInfoRow(AppLocalizations.of(context)!.typeOfInformation, caseDoc.informationType!),
              ],
            ),

          const SizedBox(height: 16),

          // Complainant
          if (caseDoc.complainantName != null)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.complainantInformantDetails,
              [
                _buildInfoRow(AppLocalizations.of(context)!.name, caseDoc.complainantName!),
                if (caseDoc.complainantFatherHusbandName != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.fatherHusbandName,
                    caseDoc.complainantFatherHusbandName!,
                  ),
                if (caseDoc.complainantGender != null)
                  _buildInfoRow('Gender', caseDoc.complainantGender!),
                if (caseDoc.complainantDob != null)
                  _buildInfoRow(AppLocalizations.of(context)!.dob, caseDoc.complainantDob!),
                if (caseDoc.complainantAge != null)
                  _buildInfoRow('Age', caseDoc.complainantAge!),
                if (caseDoc.complainantNationality != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.nationality,
                    caseDoc.complainantNationality!,
                  ),
                if (caseDoc.complainantCaste != null)
                  _buildInfoRow(AppLocalizations.of(context)!.caste, caseDoc.complainantCaste!),
                if (caseDoc.complainantOccupation != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.occupation,
                    caseDoc.complainantOccupation!,
                  ),
                if (caseDoc.complainantMobileNumber != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.mobileNumber,
                    caseDoc.complainantMobileNumber!,
                  ),
                if (caseDoc.complainantAddress != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.address,
                    caseDoc.complainantAddress!,
                  ),
                if (caseDoc.complainantPassportNumber != null ||
                    caseDoc.complainantPassportPlaceOfIssue != null ||
                    caseDoc.complainantPassportDateOfIssue != null)
                  const SizedBox(height: 8),
                if (caseDoc.complainantPassportNumber != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.passportNo,
                    caseDoc.complainantPassportNumber!,
                  ),
                if (caseDoc.complainantPassportPlaceOfIssue != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.passportPlaceOfIssue,
                    caseDoc.complainantPassportPlaceOfIssue!,
                  ),
                if (caseDoc.complainantPassportDateOfIssue != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.passportDateOfIssue,
                    caseDoc.complainantPassportDateOfIssue!,
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Victim
          if (caseDoc.victimName != null ||
              caseDoc.isComplainantAlsoVictim != null)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.victimDetails,
              [
                if (caseDoc.victimName != null)
                  _buildInfoRow(AppLocalizations.of(context)!.name, caseDoc.victimName!),
                if (caseDoc.victimFatherHusbandName != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.fatherHusbandName,
                    caseDoc.victimFatherHusbandName!,
                  ),
                if (caseDoc.victimGender != null)
                  _buildInfoRow('Gender', caseDoc.victimGender!),
                if (caseDoc.victimDob != null)
                  _buildInfoRow(AppLocalizations.of(context)!.dob, caseDoc.victimDob!),
                if (caseDoc.victimAge != null)
                  _buildInfoRow('Age', caseDoc.victimAge!),
                if (caseDoc.victimNationality != null)
                  _buildInfoRow(AppLocalizations.of(context)!.nationality, caseDoc.victimNationality!),
                if (caseDoc.victimReligion != null)
                  _buildInfoRow(AppLocalizations.of(context)!.religion, caseDoc.victimReligion!),
                if (caseDoc.victimCaste != null)
                  _buildInfoRow(AppLocalizations.of(context)!.caste, caseDoc.victimCaste!),
                if (caseDoc.victimOccupation != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.occupation,
                    caseDoc.victimOccupation!,
                  ),
                if (caseDoc.victimAddress != null)
                  _buildInfoRow(AppLocalizations.of(context)!.address, caseDoc.victimAddress!),
                if (caseDoc.isComplainantAlsoVictim != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.complainantAlsoVictim,
                    _boolText(caseDoc.isComplainantAlsoVictim),
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Accused
          if (caseDoc.accusedPersons != null &&
              caseDoc.accusedPersons!.isNotEmpty)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.accusedDetails,
              [
                ...caseDoc.accusedPersons!.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final data = (entry.value as Map?) ?? {};
                  String valueOrEmpty(String key) =>
                      (data[key] as String?)?.trim().isNotEmpty == true
                          ? (data[key] as String).trim()
                          : '-';

                  // Build a readable physical-features string from the stored fields
                  final physicalParts = <String>[];
                  final build = (data['build'] as String?)?.trim();
                  final height = (data['heightCms'] as String?)?.trim();
                  final complexion = (data['complexion'] as String?)?.trim();
                  final deformities = (data['deformities'] as String?)?.trim();

                  if (build != null && build.isNotEmpty) {
                    physicalParts.add('Build: $build');
                  }
                  if (height != null && height.isNotEmpty) {
                    physicalParts.add('Height: ${height} cm');
                  }
                  if (complexion != null && complexion.isNotEmpty) {
                    physicalParts.add('Complexion: $complexion');
                  }
                  if (deformities != null && deformities.isNotEmpty) {
                    physicalParts.add('Deformities: $deformities');
                  }

                  final physicalFeatures =
                      physicalParts.isEmpty ? '-' : physicalParts.join(', ');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accused $index',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(AppLocalizations.of(context)!.name, valueOrEmpty('name')),
                        _buildInfoRow(
                          AppLocalizations.of(context)!.fatherHusbandName,
                          valueOrEmpty('fatherHusbandName'),
                        ),
                        _buildInfoRow('Gender', valueOrEmpty('gender')),
                        _buildInfoRow('Age', valueOrEmpty('age')),
                        _buildInfoRow(AppLocalizations.of(context)!.nationality, valueOrEmpty('nationality')),
                        _buildInfoRow(AppLocalizations.of(context)!.caste, valueOrEmpty('caste')),
                        _buildInfoRow(AppLocalizations.of(context)!.occupation, valueOrEmpty('occupation')),
                        _buildInfoRow('Cell No.', valueOrEmpty('cellNo')),
                        _buildInfoRow('Email', valueOrEmpty('email')),
                        _buildInfoRow(AppLocalizations.of(context)!.address, valueOrEmpty('address')),
                        _buildInfoRow(
                          'Physical Features',
                          physicalFeatures,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),

          const SizedBox(height: 16),

          // Properties / Delay / Inquest
          if (caseDoc.propertiesDetails != null ||
              caseDoc.propertiesTotalValueInr != null ||
              caseDoc.isDelayInReporting != null ||
              caseDoc.inquestReportCaseNo != null)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.propertiesDelayInquest,
              [
                if (caseDoc.propertiesDetails != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.propertiesInvolved,
                    caseDoc.propertiesDetails!,
                  ),
                if (caseDoc.propertiesTotalValueInr != null)
                  _buildInfoRow(
                    'Total Value (INR)',
                    caseDoc.propertiesTotalValueInr!,
                  ),
                if (caseDoc.isDelayInReporting != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.delayInReporting,
                    _boolText(caseDoc.isDelayInReporting),
                  ),
                if (caseDoc.inquestReportCaseNo != null)
                  _buildInfoRow(
                    'Inquest Report / U.D. Case No.',
                    caseDoc.inquestReportCaseNo!,
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Acts & Complaint / Incident
          if (caseDoc.actsAndSectionsInvolved != null ||
              caseDoc.complaintStatement != null ||
              caseDoc.incidentDetails != null)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.actsStatement,
              [
                if (caseDoc.actsAndSectionsInvolved != null) ...[
                  Text(
                    AppLocalizations.of(context)!.actsAndSectionsInvolved,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caseDoc.actsAndSectionsInvolved!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                if (caseDoc.complaintStatement != null) ...[
                  Text(
                    'Complaint / Statement of Complainant:',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caseDoc.complaintStatement!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                if (caseDoc.incidentDetails != null) ...[
                  Text(
                    AppLocalizations.of(context)!.briefIncidentDetails,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caseDoc.incidentDetails!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),

          const SizedBox(height: 16),

          // Action taken / Dispatch / Confirmation
          if (caseDoc.actionTakenDetails != null ||
              caseDoc.dispatchDateTime != null ||
              caseDoc.isFirReadOverAndAdmittedCorrect != null)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.actionTakenAndConfirmation,
              [
                if (caseDoc.actionTakenDetails != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.actionTaken,
                    caseDoc.actionTakenDetails!,
                  ),
                if (caseDoc.investigatingOfficerName != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.investigatingOfficer,
                    caseDoc.investigatingOfficerName!,
                  ),
                if (caseDoc.investigatingOfficerRank != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.rank,
                    caseDoc.investigatingOfficerRank!,
                  ),
                if (caseDoc.investigatingOfficerDistrict != null)
                  _buildInfoRow(
                    'District',
                    caseDoc.investigatingOfficerDistrict!,
                  ),
                if (caseDoc.dispatchDateTime != null)
                  _buildInfoRow(
                    'Dispatch to Court (Date & Time)',
                    caseDoc.dispatchDateTime!,
                  ),
                if (caseDoc.dispatchOfficerName != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.dispatchingOfficer,
                    caseDoc.dispatchOfficerName!,
                  ),
                if (caseDoc.dispatchOfficerRank != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.dispatchingOfficerRank,
                    caseDoc.dispatchOfficerRank!,
                  ),
                if (caseDoc.isFirReadOverAndAdmittedCorrect != null)
                  _buildInfoRow(
                    'FIR read over and admitted correct',
                    _boolText(caseDoc.isFirReadOverAndAdmittedCorrect),
                  ),
                if (caseDoc.isFirCopyGivenFreeOfCost != null)
                  _buildInfoRow(
                    'Copy of FIR given free of cost',
                    _boolText(caseDoc.isFirCopyGivenFreeOfCost),
                  ),
                if (caseDoc.isRoacRecorded != null)
                  _buildInfoRow(
                    'ROAC recorded',
                    _boolText(caseDoc.isRoacRecorded),
                  ),
                if (caseDoc.complainantSignatureNote != null)
                  _buildInfoRow(
                    AppLocalizations.of(context)!.signatureThumbImpression,
                    caseDoc.complainantSignatureNote!,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // Crime Scene Evidence State
  List<String> _crimeSceneAttachments = [];
  String? _sceneAnalysisResult;
  Map<String, dynamic>? _latestRelevanceAnalysis;
  bool _isCheckingRelevance = false;

  Widget _buildCrimeSceneTab(CaseDoc caseDoc, ThemeData theme) {
    const orange = Color(0xFFFC633C);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Multiple Crime Scenes Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Row(
                         children: [
                           const Icon(Icons.location_on, color: Colors.blue),
                           const SizedBox(width: 8),
                           Text(
                             AppLocalizations.of(context)!.crimeScenes,
                             style: theme.textTheme.titleLarge?.copyWith(
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ],
                       ),
                       IconButton(
                         icon: const Icon(Icons.add_location_alt, color: orange),
                         tooltip: AppLocalizations.of(context)!.addScene,
                         onPressed: () => _showEditCrimeDetailsDialog(theme),
                       ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isLoadingScenes)
                    const Center(child: CircularProgressIndicator())
                  else if (_crimeScenes.isEmpty)
                    Text(AppLocalizations.of(context)!.noCrimeScenesLinked)
                  else
                    ..._crimeScenes.map((scene) {
                       return Container(
                         margin: const EdgeInsets.only(bottom: 12),
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           border: Border.all(color: Colors.grey.shade300),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                 Text(
                                   scene.crimeType ?? AppLocalizations.of(context)!.unknownType,
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                 ),
                                 const Spacer(),
                                 IconButton(
                                   icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                                   onPressed: () => _showEditCrimeDetailsDialog(theme, scene),
                                   visualDensity: VisualDensity.compact,
                                 ),
                                 IconButton(
                                   icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                   onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: Text(AppLocalizations.of(context)!.deleteScene),
                                          content: Text(AppLocalizations.of(context)!.areSureDeleteScene),
                                          actions: [
                                            TextButton(onPressed: ()=>Navigator.pop(c, false), child: Text(AppLocalizations.of(context)!.cancel)),
                                            TextButton(onPressed: ()=>Navigator.pop(c, true), child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      
                                      if (confirm == true && scene.id != null) {
                                         await FirebaseFirestore.instance
                                            .collection('cases')
                                            .doc(widget.caseId)
                                            .collection('crimeScenes')
                                            .doc(scene.id)
                                            .delete();
                                         _fetchCrimeScenes();
                                      }
                                   },
                                   visualDensity: VisualDensity.compact,
                                 ),
                               ],
                             ),
                             const Divider(height: 12),
                             if (scene.placeOfOccurrenceDescription?.isNotEmpty == true)
                               _buildInfoRow(AppLocalizations.of(context)!.place, scene.placeOfOccurrenceDescription!),
                             if (scene.physicalEvidenceDescription?.isNotEmpty == true)
                               _buildInfoRow(AppLocalizations.of(context)!.physicalEvidence, scene.physicalEvidenceDescription!),
                             
                             const SizedBox(height: 4),
                             Text(
                               'Recorded: ${_formatTimestamp(scene.createdAt)}',
                               style:const TextStyle(fontSize: 10, color: Colors.grey),
                             ),
                           ],
                         ),
                       );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Evidence Capture Section
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.camera_alt, color: orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.captureCrimeSceneEvidence,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Capture Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _captureSceneEvidence(CaptureMode.image),
                          icon: const Icon(Icons.camera),
                          label: Text(AppLocalizations.of(context)!.photo),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _captureSceneEvidence(CaptureMode.video),
                          icon: const Icon(Icons.videocam),
                          label: Text(AppLocalizations.of(context)!.video),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _uploadSceneFile,
                          icon: const Icon(Icons.upload_file),
                          label: Text(AppLocalizations.of(context)!.upload),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Attachment Preview
                  if (_crimeSceneAttachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      '${_crimeSceneAttachments.length} Evidence File(s)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _crimeSceneAttachments.length,
                        itemBuilder: (context, index) {
                          final filePath = _crimeSceneAttachments[index];
                          final fpLower = filePath.toLowerCase().split('?').first;
                          final isVideo =
                              fpLower.endsWith('.mp4') || fpLower.endsWith('.mov');
                          final isUrl = filePath.startsWith('http://') ||
                              filePath.startsWith('https://');
                          
                          return GestureDetector(
                            onTap: () => _showEvidenceOptions(filePath, index),
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: orange.withOpacity(0.3), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Image/Video Preview
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: isVideo
                                        ? Container(
                                            color: Colors.black87,
                                            child: const Icon(
                                              Icons.videocam,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          )
                                        : (isUrl || kIsWeb
                                            ? Image.network(
                                                filePath,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade300,
                                                    child: const Icon(Icons.image, size: 40),
                                                  );
                                                },
                                              )
                                            : Image.file(
                                                File(filePath),
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade300,
                                                    child: const Icon(Icons.image, size: 40),
                                                  );
                                                },
                                              )),
                                  ),
                                  
                                  // Tap indicator overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Tap icon
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.touch_app,
                                        color: orange,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  
                                  // Remove button
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () async {
                                        setState(() {
                                          _crimeSceneAttachments.removeAt(index);
                                        });
                                        await _saveCrimeSceneEvidence();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(AppLocalizations.of(context)!.evidenceRemoved),
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // GEO badge
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: orange.withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'GEO',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isCheckingRelevance) ...[
                      const SizedBox(height: 6),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 10),
                    ],

                    if (_latestRelevanceAnalysis != null) ...[
                      Builder(
                        builder: (context) {
                          final overall =
                              (_latestRelevanceAnalysis!['overall'] is Map)
                                  ? Map<String, dynamic>.from(
                                      _latestRelevanceAnalysis!['overall']
                                          as Map)
                                  : <String, dynamic>{};
                          final colorStr = (overall['color'] ?? '').toString();
                          final scoreStr = (overall['score'] ?? '').toString();
                          final summaryStr =
                              (overall['summary'] ?? '').toString();

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _gradeColor(colorStr).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _gradeColor(colorStr).withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified,
                                    color: _gradeColor(colorStr)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Relevance: ${colorStr.toUpperCase()} (Score: $scoreStr)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        summaryStr,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                TextButton(
                                  onPressed: () =>
                                      _showRelevanceDialog(_latestRelevanceAnalysis!),
                                  child: const Text('View'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // AI Analysis Button
                    ElevatedButton.icon(
                      onPressed: _isAnalyzingScene ? null : _analyzeSceneWithAI,
                      icon: _isAnalyzingScene
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isAnalyzingScene
                          ? AppLocalizations.of(context)!.analyzing
                          : AppLocalizations.of(context)!.analyzeSceneWithAI),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                  
                  // AI Analysis Result
                  if (_sceneAnalysisResult != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: Colors.purple),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.aiSceneAnalysis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _sceneAnalysisResult!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Media Analysis Reports
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.image, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.crimeSceneAnalysisReports,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingMedia)
                    const Center(child: CircularProgressIndicator())
                  else if (_mediaAnalyses.isEmpty)
                    Text(AppLocalizations.of(context)!.noAnalysisReportsFound)
                  else
                    ..._mediaAnalyses.map((report) => _buildMediaReportCard(report, theme)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaReportCard(MediaAnalysisRecord report, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          report.originalFileName,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('Analyzed: ${_formatTimestamp(report.createdAt)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              tooltip: AppLocalizations.of(context)!.downloadReport,
              onPressed: () => _downloadAnalysisPdf(report),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              tooltip: AppLocalizations.of(context)!.deleteReport,
              onPressed: () => _deleteAnalysisReport(report),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.identifiedElements.isNotEmpty) ...[
                  Text(
                    AppLocalizations.of(context)!.identifiedElements,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...report.identifiedElements.map(
                    (element) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${element.name} (${element.category}): ${element.description}',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  AppLocalizations.of(context)!.sceneNarrative,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.sceneNarrative,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.caseFileSummary,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.caseFileSummary,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationTab(CaseDoc caseDoc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.book, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.caseJournalIOsDiary,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingJournal)
                    const Center(child: CircularProgressIndicator())
                  else if (_journalEntries.isEmpty)
                    Text(AppLocalizations.of(context)!.noJournalEntriesYet)
                  else
                    _buildJournalTimeline(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalTimeline(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _journalEntries.length,
      itemBuilder: (context, index) {
        final entry = _journalEntries[index];
        return _buildTimelineItem(entry, theme, index == _journalEntries.length - 1);
      },
    );
  }

  Widget _buildTimelineItem(CaseJournalEntry entry, ThemeData theme, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.activityType,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.entryText,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatTimestamp(entry.dateTime)} by ${entry.officerName} (${entry.officerRank})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceTab(CaseDoc caseDoc, ThemeData theme) {
    final hasJournalEvidence = _journalEntries.any(
      (e) => e.attachmentUrls != null && e.attachmentUrls!.isNotEmpty,
    );
    final hasPetitionEvidence = _linkedPetitions.any(
      (p) =>
          (p.proofDocumentUrls != null && p.proofDocumentUrls!.isNotEmpty) ||
          p.handwrittenDocumentUrl != null,
    );
    final hasCrimeSceneEvidence = _crimeSceneAttachments.isNotEmpty;
    final hasMediaAnalyses = _mediaAnalyses.isNotEmpty;

    final isLoading = _isLoadingJournal || 
                      _isLoadingPetitions || 
                      _isLoadingMedia; // Note: _isLoadingScenes not strictly checked here as it refers to CrimeDetails list

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.loadingEvidenceFromAllSources,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          
          if (!isLoading && 
              !(hasJournalEvidence || hasPetitionEvidence || hasCrimeSceneEvidence || hasMediaAnalyses))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.archive, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.noEvidenceDocumentsFound,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Attached documents from the Case Journal, Petitions, and Crime Scene captures will appear here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          if (hasCrimeSceneEvidence)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.crimeSceneCaptures,
              _buildCrimeSceneEvidenceWidgets(theme),
            ),

          if (hasJournalEvidence)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.fromInvestigationDiary,
              _buildJournalEvidenceWidgets(theme),
            ),

          if (hasPetitionEvidence)
            _buildSection(
              theme,
              AppLocalizations.of(context)!.fromPetitions,
              _buildPetitionEvidenceWidgets(theme),
            ),

          if (hasMediaAnalyses)
             _buildSection(
              theme,
              AppLocalizations.of(context)!.forensicAnalysisReports,
              _buildMediaAnalysisWidgets(theme),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCrimeSceneEvidenceWidgets(ThemeData theme) {
    if (_crimeSceneAttachments.isEmpty) return [];

    return [
       Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(_crimeSceneAttachments.length, (index) {
          final filePath = _crimeSceneAttachments[index];
          final isVideo = filePath.toLowerCase().endsWith('.mp4') ||
                          filePath.toLowerCase().endsWith('.mov');
          final fileName = filePath.split('/').last.split('?').first; // Handle URLs with params

          return InkWell(
            onTap: () => _showEvidenceOptions(filePath, index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Column(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      isVideo ? Icons.videocam : Icons.image,
                      color: Colors.grey.shade700,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Evidence ${index + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      )
    ];
  }

  List<Widget> _buildMediaAnalysisWidgets(ThemeData theme) {
     return _mediaAnalyses.map((report) {
       return Padding(
         padding: const EdgeInsets.only(bottom: 8.0),
         child: ListTile(
           contentPadding: EdgeInsets.zero,
           leading: const Icon(Icons.description, color: Colors.purple),
           title: Text(report.originalFileName),
           subtitle: Text('Analyzed on ${_formatTimestamp(report.createdAt)}'),
           trailing: IconButton(
             icon: const Icon(Icons.picture_as_pdf),
             onPressed: () => _downloadAnalysisPdf(report),
           ),
         ),
       );
     }).toList();
  }

  List<Widget> _buildJournalEvidenceWidgets(ThemeData theme) {
    final List<Widget> widgets = [];

    for (final entry in _journalEntries) {
      if (entry.attachmentUrls == null || entry.attachmentUrls!.isEmpty) {
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.activityType,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(entry.dateTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < entry.attachmentUrls!.length; i++)
                    ActionChip(
                      avatar: const Icon(Icons.attach_file, size: 16),
                      label: Text('Journal Doc ${i + 1}'),
                      onPressed: () async {
                        final url = Uri.parse(entry.attachmentUrls![i]);
                        if (!await launchUrl(url,
                            mode: LaunchMode.externalApplication)) {
                          debugPrint('Could not open $url');
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          'No documents attached in the investigation diary yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildPetitionEvidenceWidgets(ThemeData theme) {
    final List<Widget> widgets = [];

    for (final petition in _linkedPetitions) {
      final List<String> docs = [];
      if (petition.handwrittenDocumentUrl != null) {
        docs.add(petition.handwrittenDocumentUrl!);
      }
      if (petition.proofDocumentUrls != null) {
        docs.addAll(petition.proofDocumentUrls!);
      }
      if (docs.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                petition.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                petition.type.displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < docs.length; i++)
                    ActionChip(
                      avatar: const Icon(Icons.picture_as_pdf, size: 16),
                      label: Text('Petition Doc ${i + 1}'),
                      onPressed: () async {
                        final url = Uri.parse(docs[i]);
                        if (!await launchUrl(url,
                            mode: LaunchMode.externalApplication)) {
                          debugPrint('Could not open $url');
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          AppLocalizations.of(context)!.noPetitionDocumentsLinked,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildFinalReportTab(CaseDoc caseDoc, ThemeData theme) {
    final String? pdfUrl = caseDoc.investigationReportPdfUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, size: 48, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.finalInvestigationReport,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (caseDoc.investigationReportGeneratedAt != null)
                Text(
                  'Generated on: ${_formatTimestamp(caseDoc.investigationReportGeneratedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              const SizedBox(height: 16),
              if (pdfUrl == null || pdfUrl.isEmpty) ...[
                Text(
                  'No final investigation report has been attached to this case yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Once an investigating officer generates and confirms the AI-assisted investigation report from the Case Journal screen, the final PDF will be linked here.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                Text(
                  'A court-ready investigation report PDF has been generated and attached to this case.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final String resolvedUrl = pdfUrl.startsWith('http')
                        ? pdfUrl
                        : 'https://fastapi-app-335340524683.asia-south1.run.app$pdfUrl';

                    final url = Uri.parse(resolvedUrl);
                    if (!await launchUrl(url,
                        mode: LaunchMode.externalApplication)) {
                      debugPrint('Could not open $url');
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(AppLocalizations.of(context)!.downloadViewFinalReportPDF),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    List<Widget> children,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.newCase:
        return Colors.blue;
      case CaseStatus.underInvestigation:
        return Colors.orange;
      case CaseStatus.pendingTrial:
        return Colors.purple;
      case CaseStatus.resolved:
        return Colors.green;
      case CaseStatus.closed:
        return Colors.grey;
    }
  }
}
