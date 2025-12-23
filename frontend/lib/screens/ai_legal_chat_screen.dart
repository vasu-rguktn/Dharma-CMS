// // lib/screens/ai_legal_chat_screen.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:dio/dio.dart';

// class AiLegalChatScreen extends StatefulWidget {
//   const AiLegalChatScreen({super.key});

//   @override
//   State<AiLegalChatScreen> createState() => _AiLegalChatScreenState();
// }

// class _AiLegalChatScreenState extends State<AiLegalChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _inputFocus = FocusNode();
//   final List<_ChatMessage> _messages = [];
//   final Dio _dio = Dio();

//   final List<_ChatQ> _questions = const [
//     _ChatQ(key: 'full_name', question: 'What is your full name?'),
//     _ChatQ(key: 'address', question: 'Where do you live (place / area)?'),
//     _ChatQ(key: 'phone', question: 'What is your phone number?'),
//     _ChatQ(
//         key: 'complaint_type',
//         question:
//             'What type of complaint do you want to file? (Theft, Harassment, Missing person, etc.)'),
//     _ChatQ(key: 'details', question: 'Please describe your complaint in detail.'),
//   ];

//   Map<String, String> _answers = {};
//   int _currentQ = -2; // -2 = Welcome, -1 = Let us begin, 0+ = questions
//   bool _allowInput = false;
//   bool _isLoading = false;
//   bool _errored = false;
//   bool _inputError = false;

//   // Orange color
//   static const Color orange = Color(0xFFFC633C);
//   static const Color background = Color(0xFFF5F8FE);

//   @override
//   void initState() {
//     super.initState();
//     _startChatFlow();
//   }

//   Future<void> _startChatFlow() async {
//     setState(() {
//       _messages.clear();
//       _currentQ = -2;
//       _allowInput = false;
//     });
//     _addBot('Welcome to NyayaSetu');
//     await Future.delayed(const Duration(seconds: 1));
//     _addBot('Let us begin...');
//     _currentQ = -1;
//     setState(() {});
//     await Future.delayed(const Duration(seconds: 2));
//     _askNextQ();
//   }

//   void _addBot(String content) {
//     _messages.add(_ChatMessage(user: 'AI', content: content, isUser: false));
//     setState(() {});
//   }

//   void _addUser(String content) {
//     _messages.add(_ChatMessage(user: 'You', content: content, isUser: true));
//     setState(() {});
//   }

//   void _askNextQ() {
//     _currentQ++;
//     if (_currentQ < _questions.length) {
//       _addBot(_questions[_currentQ].question);
//       _allowInput = true;
//       setState(() => _inputError = false);
//       Timer(const Duration(milliseconds: 600), () => _inputFocus.requestFocus());
//     } else {
//       _submitToBackend();
//     }
//   }

//   Future<void> _submitToBackend() async {
//     setState(() {
//       _isLoading = true;
//       _allowInput = false;
//     });
//     try {
//       final baseUrl = Theme.of(context).platform == TargetPlatform.android
//           ? 'http://10.0.2.2:8000'
//           : 'https://dharma-backend-x1g4.onrender.com';
//       final resp = await _dio.post('$baseUrl/complaint/summarize', data: {
//         'full_name': _answers['full_name']!,
//         'address': _answers['address']!,
//         'phone': _answers['phone']!,
//         'complaint_type': _answers['complaint_type']!,
//         'details': _answers['details']!,
//       });

//       final data = resp.data;
//       _addBot('Complaint Summary:');
//       _messages.add(_ChatMessage(
//         user: 'AI',
//         content: data['formal_summary'] ?? '(no summary)',
//         isUser: false,
//       ));
//       _addBot('Classification: ${data['classification'] ?? '(none)'}');

//       setState(() {
//         _isLoading = false;
//         _allowInput = false;
//       });

//       Future.delayed(const Duration(seconds: 2), () {
//         if (mounted) {
//           context.go(
//             '/ai-chatbot-details',
//             extra: {
//               'answers': _answers,
//               'summary': data['formal_summary'] ?? '',
//               'classification': data['classification'] ?? '',
//             },
//           );
//         }
//       });
//     } catch (e) {
//       _addBot('Sorry, something went wrong. Please try again later.');
//       setState(() {
//         _isLoading = false;
//         _allowInput = false;
//         _errored = true;
//       });
//     }
//   }

//   void _handleSend() {
//     final text = _controller.text.trim();
//     if (!_allowInput || _isLoading) return;
//     if (text.isEmpty) {
//       setState(() => _inputError = true);
//       _inputFocus.requestFocus();
//       return;
//     }
//     setState(() => _inputError = false);
//     _controller.clear();
//     _addUser(text);
//     _answers[_questions[_currentQ].key] = text;
//     _allowInput = false;
//     setState(() {});
//     Future.delayed(const Duration(milliseconds: 600), _askNextQ);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _inputFocus.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: background,
//       appBar: AppBar(
//         backgroundColor: orange,
//         elevation: 0,
//         centerTitle: false,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'AI Legal Assistant',
//               style: theme.textTheme.titleLarge?.copyWith(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(
//               'Ask me anything about legal matters',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: Colors.white70,
//               ),
//             ),
//           ],
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => context.pop(),
//         ),
//       ),
//       body: Column(
//         children: [
//           // ── CHAT MESSAGES ──
//           Expanded(
//             child: _messages.isEmpty
//                 ? Center(
//                     child: Text(
//                       'Loading...',
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                     itemCount: _messages.length,
//                     itemBuilder: (context, index) {
//                       final msg = _messages[index];
//                       return Align(
//                         alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           margin: const EdgeInsets.symmetric(vertical: 4),
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                           constraints: BoxConstraints(
//                             maxWidth: MediaQuery.of(context).size.width * 0.75,
//                           ),
//                           decoration: BoxDecoration(
//                             color: msg.isUser ? orange : Colors.white,
//                             borderRadius: BorderRadius.circular(18),
//                             border: msg.isUser
//                                 ? null
//                                 : Border.all(color: Colors.grey.shade300, width: 1),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 3,
//                                 offset: const Offset(0, 1),
//                               ),
//                             ],
//                           ),
//                           child: Text(
//                             msg.content,
//                             style: TextStyle(
//                               color: msg.isUser ? Colors.white : Colors.black87,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ),

//           // ── INPUT FIELD ──
//           if (!_isLoading && !_errored && _allowInput)
//             Container(
//               padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
//               color: background,
//               child: Material(
//                 elevation: 6,
//                 borderRadius: BorderRadius.circular(30),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: _controller,
//                           focusNode: _inputFocus,
//                           decoration: InputDecoration(
//                             hintText: _currentQ >= 0 && _currentQ < _questions.length
//                                 ? _questions[_currentQ].question
//                                 : 'Type your message...',
//                             border: InputBorder.none,
//                             errorText: _inputError ? "Please enter your answer" : null,
//                             errorStyle: const TextStyle(fontSize: 12),
//                           ),
//                           onSubmitted: (_) => _handleSend(),
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.mic, color: orange),
//                         onPressed: () {},
//                         tooltip: "Voice input (coming soon)",
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.send, color: orange),
//                         onPressed: _handleSend,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//           // ── LOADER ──
//           if (_isLoading)
//             const Padding(
//               padding: EdgeInsets.all(20),
//               child: CircularProgressIndicator(color: orange),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // ── Helper Classes ──
// class _ChatQ {
//   final String key;
//   final String question;
//   const _ChatQ({required this.key, required this.question});
// }

// class _ChatMessage {
//   final String user;
//   final String content;
//   final bool isUser;
//   _ChatMessage({required this.user, required this.content, required this.isUser});
// }

// lib/screens/ai_legal_chat_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

// Static state holder to preserve chat state across navigation
class _ChatStateHolder {
  static final List<_ChatMessage> messages = [];
  static final Map<String, String> answers = {};
  static int currentQ = -2;
  static bool hasStarted = false;
  static bool allowInput = false;
  static bool isLoading = false;
  static bool errored = false;

  static void reset() {
    messages.clear();
    answers.clear();
    currentQ = -2;
    hasStarted = false;
    allowInput = false;
    isLoading = false;
    errored = false;
  }
}

class AiLegalChatScreen extends StatefulWidget {
  const AiLegalChatScreen({super.key});

  @override
  State<AiLegalChatScreen> createState() => _AiLegalChatScreenState();
}

class _AiLegalChatScreenState extends State<AiLegalChatScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio();
  final ImagePicker _imagePicker = ImagePicker();
  List<String> _attachedFiles = []; // Store paths of attached files

  List<_ChatQ> _questions = [];

  // Use static holder for state preservation
  List<_ChatMessage> get _messages => _ChatStateHolder.messages;
  Map<String, String> get _answers => _ChatStateHolder.answers;
  int get _currentQ => _ChatStateHolder.currentQ;
  bool get _allowInput => _ChatStateHolder.allowInput;
  bool get _isLoading => _ChatStateHolder.isLoading;
  bool get _errored => _ChatStateHolder.errored;

  // Local state
  bool _inputError = false;
  bool _isDynamicMode = false;
  List<Map<String, String>> _dynamicHistory = [];

  // STT (Speech-to-Text) variables
  // STT (Speech-to-Text) variables
  late final stt.SpeechToText _speech;
  late final FlutterTts _flutterTts;
  bool _isRecording = false;
  String _currentTranscript =
      ''; // Live/streaming transcript (temporary, gets replaced)
  String _finalizedTranscript =
      ''; // Finalized transcript (locked when user stops/sends)
  DateTime? _recordingStartTime;
  DateTime? _lastRestartAttempt; // Track last restart to prevent rapid cycling
  bool _isRestarting =
      false; // Track if restart is in progress to prevent BUSY errors
  DateTime? _lastSpeechDetected; // Track when speech was last detected
  DateTime? _lastDoneStatus; // Track when "done" status was last received
  int _busyRetryCount = 0; // Track BUSY error retries
  Timer? _listeningMonitorTimer; // Timer to monitor continuous listening
  String? _currentSttLang; // Store current STT language for restarting
  // StreamSubscription<stt.SpeechRecognitionResult>? _sttSubscription;

  // Platform channel for muting system sounds during ASR
  static const MethodChannel _soundChannel =
      MethodChannel('com.dharma.sound_control');

  // Orange color
  static const Color orange = Color(0xFFFC633C);
  static const Color background = Color(0xFFF5F8FE);

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _flutterTts.setSpeechRate(0.45);
    _flutterTts.setPitch(1.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Static questions removed.

    if (!_hasStarted) {
      _hasStarted = true;
      _startChatFlow();
    }
  }

  Future<void> _startChatFlow() async {
    final localizations = AppLocalizations.of(context)!;

    setState(() {
      _messages.clear();
      _dynamicHistory.clear();
      _answers.clear();
      _isDynamicMode = true; // Always dynamic logic now
      _currentQ = 0; // Not used but resetting
      _allowInput = false;
      _errored = false;
    });
    _addBot(localizations.welcomeToDharma);
    await Future.delayed(const Duration(seconds: 1));
    _addBot(localizations.letUsBegin);
    await Future.delayed(const Duration(seconds: 1)); // Small delay for flow

    // Explicitly ask for description instead of calling backend immediately
    String startMsg = localizations.detailsQuestion ??
        'Please describe your complaint in detail.';
    _addBot(startMsg);
    _speak(startMsg);

    setState(() {
      _allowInput = true; // Wait for user info
    });
  }

  void _addBot(String content) {
    _ChatStateHolder.messages
        .add(_ChatMessage(user: 'AI', content: content, isUser: false));
    setState(() {});
    _scrollToEnd();
  }

  void _addUser(String content) {
    _ChatStateHolder.messages
        .add(_ChatMessage(user: 'You', content: content, isUser: true));
    setState(() {});
    _scrollToEnd();
  }

  void _scrollToEnd() {
    // small delay to allow list to update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _processDynamicStep() async {
    final localizations = AppLocalizations.of(context)!;

    setState(() {
      _setIsLoading(true);
      _setAllowInput(false);
      _setErrored(false);
    });

    // Determine base URL robustly
    String baseUrl;
    if (kIsWeb) {
      // on web you probably want to call your absolute backend URL
      baseUrl = "http://127.0.0.1:8000";
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android physical device (requires adb reverse tcp:8000 tcp:8000)
      baseUrl = "http://10.0.2.2:8000";
    } else {
      // iOS simulator / other platforms
      baseUrl = "http://127.0.0.1:8000";
    }

    final localeCode = Localizations.localeOf(context).languageCode;

    // Construct Payload
    final payload = {
      'full_name': _answers['full_name'] ?? '',
      'address': _answers['address'] ?? '',
      'phone': _answers['phone'] ?? _answers['phone_number'] ?? '',
      'complaint_type': _answers['complaint_type'] ?? '',
      'initial_details': _answers['details'] ??
          '', // This was the answer to the last static question
      'language': localeCode,
      'chat_history': _dynamicHistory,
    };

    try {
      final resp = await _dio
          .post(
            '$baseUrl/complaint/chat-step',
            data: payload,
            options: Options(headers: {'Content-Type': 'application/json'}),
          )
          .timeout(const Duration(seconds: 30));

      final data = resp.data;
      print("Backend Response: $data"); // DEBUG LOG

      if (data['status'] == 'question') {
        String question = data['message'] ?? '';
        if (question.trim().isEmpty) {
          question = "Could you please provide more details?";
        }
        _addBot(question);
        _speak(question);

        // Add AI's question to history so LLM knows what it asked
        _dynamicHistory.add({'role': 'assistant', 'content': question});

        setState(() {
          _isLoading = false;
          _allowInput = true;
          _inputError = false;
        });
        Timer(const Duration(milliseconds: 600),
            () => _inputFocus.requestFocus());
      } else if (data['status'] == 'done') {
        // FINISHED
        final finalResp = data['final_response'];
        _handleFinalResponse(finalResp);
      }
    } catch (e) {
      String msg = localizations.somethingWentWrong ??
          'Sorry, something went wrong. Please try again later.';
      if (e is DioError) {
        if (e.response != null && e.response?.data != null) {
          // try to show server-provided message if present
          try {
            final d = e.response!.data;
            if (d is Map && d['detail'] != null)
              msg = d['detail'].toString();
            else if (d is Map && d['message'] != null)
              msg = d['message'].toString();
            else if (d is String) msg = d;
          } catch (_) {}
        }
      }
      _addBot(msg);
      setState(() {
        _isLoading = false;
        _allowInput = true; // Allow retry?
        _errored = true;
      });
    }
  }

  void _handleFinalResponse(dynamic data) {
    final localizations = AppLocalizations.of(context)!;

    _addBot(localizations.complaintSummary ?? 'Complaint Summary:');
    final formalSummary = (data is Map && data['formal_summary'] != null)
        ? data['formal_summary'].toString()
        : '(no summary)';
    final classification = (data is Map && data['classification'] != null)
        ? data['classification'].toString()
        : '(none)';
    final originalClassification =
        (data is Map && data['original_classification'] != null)
            ? data['original_classification'].toString()
            : classification;

    final Map<String, String> localizedAnswers =
        Map<String, String>.from(_answers);
    final localizedFields = (data is Map) ? data['localized_fields'] : null;
    if (localizedFields is Map) {
      localizedFields.forEach((key, value) {
        if (key is String && value != null) {
          localizedAnswers[key] = value.toString();
        }
      });
    }

    // update stored answers
    _answers
      ..clear()
      ..addAll(localizedAnswers);

    _addBot(formalSummary);
    _addBot(localizations.classification(classification as String) ??
        'Classification: $classification');

    setState(() {
      _isLoading = false;
      _allowInput = false;
    });

    // navigate to details screen
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      context.go(
        '/ai-chatbot-details',
        extra: {
          'answers': Map<String, String>.from(_answers),
          'summary': formalSummary,
          'classification': classification,
          'originalClassification': originalClassification,
        },
      );
    });
  }

  void _handleSend() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}

    // If recording is active, stop it first and use the transcript
    if (_isRecording) {
      await _speech.stop();
      await _speech.cancel();

      // USER EXPLICITLY SENT MESSAGE - Finalize all accumulated text
      // This is the ONLY place where we finalize on send (not on pauses)
      setState(() {
        // Finalize: append current transcript to finalized (accumulate all text)
        if (_currentTranscript.isNotEmpty) {
          if (_finalizedTranscript.isNotEmpty) {
            _finalizedTranscript =
                '$_finalizedTranscript $_currentTranscript'.trim();
          } else {
            _finalizedTranscript = _currentTranscript;
          }
        }
        _controller.text =
            _finalizedTranscript; // Update controller with finalized text
        _currentTranscript = ''; // Clear current
        _isRecording = false;
        _recordingStartTime = null;
        _lastRestartAttempt = null;
        _isRestarting = false;
      });

      // Small delay to ensure transcript is finalized
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final text = _controller.text.trim();
    if (!_allowInput || _isLoading) return;

    if (text.isEmpty) {
      setState(() => _inputError = true);
      _inputFocus.requestFocus();
      return;
    }

    // Finalize transcript before sending
    _finalizedTranscript = text;
    _currentTranscript = ''; // Clear for next recording session

    setState(() => _inputError = false);
    _controller.clear();
    _addUser(text);

    // Logic: If this is the VERY FIRST user message, it becomes 'initial_details'
    // AND we do NOT add it to history (because backend uses initial_details as context).
    // Subsequent messages are added to history.
    if (_answers['details'] == null || _answers['details']!.isEmpty) {
      _answers['details'] = text;
    } else {
      _dynamicHistory.add({'role': 'user', 'content': text});
    }

    _setAllowInput(false);
    setState(() {});

    // Explicitly call backend step
    _processDynamicStep();
  }

  /// Show attachment options (photos, videos, PDFs, audio)
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Attach File',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Photo options
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: orange, size: 24),
                ),
                title: const Text('Take Photo'),
                subtitle: Text('Capture a new photo',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                onTap: () async {
                  Navigator.pop(context);
                  final image =
                      await _imagePicker.pickImage(source: ImageSource.camera);
                  if (image != null && mounted) {
                    setState(() {
                      _attachedFiles.add(image.path);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Photo attached: ${image.path.split('/').last}')),
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.photo_library, color: orange, size: 24),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: Text('Select photo or video',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                onTap: () async {
                  Navigator.pop(context);
                  final image =
                      await _imagePicker.pickImage(source: ImageSource.gallery);
                  if (image != null && mounted) {
                    setState(() {
                      _attachedFiles.add(image.path);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Photo attached: ${image.path.split('/').last}')),
                    );
                  }
                },
              ),
              // Video option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.videocam, color: orange, size: 24),
                ),
                title: const Text('Record Video'),
                subtitle: Text('Capture a new video',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                onTap: () async {
                  Navigator.pop(context);
                  final video =
                      await _imagePicker.pickVideo(source: ImageSource.camera);
                  if (video != null && mounted) {
                    setState(() {
                      _attachedFiles.add(video.path);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Video attached: ${video.path.split('/').last}')),
                    );
                  }
                },
              ),
              // File picker (PDFs, audio, etc.)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_file, color: orange, size: 24),
                ),
                title: const Text('Upload File'),
                subtitle: Text('PDF, Audio, or other files',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                    allowMultiple: true,
                  );
                  if (result != null && mounted) {
                    setState(() {
                      _attachedFiles
                          .addAll(result.files.map((f) => f.path ?? f.name));
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('${result.files.length} file(s) attached')),
                    );
                  }
                },
              ),
              // Show attached files count if any
              if (_attachedFiles.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_attachedFiles.length} file(s) attached',
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 14),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _attachedFiles.clear();
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Attachments removed')),
                          );
                        },
                        child: const Text('Clear',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  /// Mute system sounds to prevent ASR start/stop/restart sounds
  Future<void> _muteSystemSounds() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        await _soundChannel.invokeMethod('muteSystemSounds');
      }
    } catch (e) {
      // Silently fail - sound muting is optional
      print('Could not mute system sounds: $e');
    }
  }

  /// Unmute system sounds
  Future<void> _unmuteSystemSounds() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        await _soundChannel.invokeMethod('unmuteSystemSounds');
      }
    } catch (e) {
      // Silently fail - sound unmuting is optional
      print('Could not unmute system sounds: $e');
    }
  }

  /// Restart speech recognition when user manually clears text
  /// This resets the SDK's internal buffer to get fresh transcript
  Future<void> _restartSpeechRecognitionOnClear() async {
    if (!_isRecording || _currentSttLang == null) return;

    print('Restarting speech recognition after manual text clear...');

    try {
      // Stop and cancel current session to reset SDK buffer
      await _speech.stop();
      await _speech.cancel();

      // Small delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 200));

      // Reset all transcript state
      setState(() {
        _currentTranscript = '';
        _finalizedTranscript = '';
        _busyRetryCount = 0;
        _isRestarting = false;
        _lastRestartAttempt = null;
        _lastSpeechDetected = null;
      });

      // Restart listening with fresh state
      await _safeRestartListening(_currentSttLang!);
    } catch (e) {
      print('Error restarting speech recognition on clear: $e');
      // If restart fails, try safe restart
      if (mounted && _isRecording && _currentSttLang != null) {
        await _safeRestartListening(_currentSttLang!);
      }
    }
  }

  /// Safely restart speech recognition with BUSY error handling
  Future<void> _safeRestartListening(String sttLang) async {
    // Prevent multiple simultaneous restart attempts
    if (_isRestarting) {
      print('Restart already in progress, skipping...');
      return;
    }

    // Check throttle - reduced from 2000ms to 500ms for faster response
    final now = DateTime.now();
    if (_lastRestartAttempt != null &&
        now.difference(_lastRestartAttempt!).inMilliseconds < 500) {
      print('Too soon since last restart attempt, skipping...');
      return;
    }

    _isRestarting = true;
    _lastRestartAttempt = now;

    try {
      // Double-check we're still recording
      if (!mounted || !_isRecording) {
        _isRestarting = false;
        return;
      }

      // Always cancel any existing session first to ensure clean state
      // This is critical - even if isListening is false, the session might be in a "done" state
      print(
          'Canceling any existing session before restart (isListening: ${_speech.isListening})...');
      try {
        // Only stop/cancel if actually listening - if already stopped, skip
        if (_speech.isListening) {
          await _speech.stop();
          await _speech.cancel();
          // Short delay for clean state - fast restart for continuous listening
          await Future.delayed(const Duration(milliseconds: 150));
        } else {
          print(
              'Session already stopped, skipping cancel - restarting directly...');
          // Even if stopped, give a tiny delay for SDK to be ready
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        print('Error canceling session: $e - continuing anyway');
        // Continue anyway - might already be stopped
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Final check before starting
      if (!mounted || !_isRecording) {
        _isRestarting = false;
        await _unmuteSystemSounds(); // Unmute if we're not restarting
        return;
      }

      print('Starting new listening session after restart...');
      await _speech.listen(
        localeId: sttLang,
        listenFor: const Duration(
            hours: 1), // Listen for up to 1 hour - continuous listening
        pauseFor: const Duration(
            hours:
                1), // Allow very long pauses - treat silence as thinking time
        partialResults: true,
        cancelOnError: false,
        onResult: (result) {
          if (mounted) {
            setState(() {
              // Simplified and more permissive transcript accumulation
              final newWords = result.recognizedWords.trim();
              if (newWords.isNotEmpty) {
                print(
                    'onResult (restart): newWords="$newWords", currentTranscript="$_currentTranscript"');
                // Update last speech detected timestamp
                _lastSpeechDetected = DateTime.now();

                if (_currentTranscript.isEmpty) {
                  // First words
                  _currentTranscript = newWords;
                } else if (newWords == _currentTranscript) {
                  // Exact match - no change needed
                  return;
                } else if (newWords.startsWith(_currentTranscript.trim())) {
                  // Partial update - new words contain existing transcript (expanding)
                  _currentTranscript = newWords;
                } else if (_currentTranscript.trim().endsWith(newWords)) {
                  // New words are a suffix of existing - likely a partial update, keep existing
                  return;
                } else {
                  // New words - append them
                  // Check if we need to add a space
                  final trimmedCurrent = _currentTranscript.trim();
                  if (trimmedCurrent.isNotEmpty) {
                    final lastChar = trimmedCurrent[trimmedCurrent.length - 1];
                    if (lastChar != ' ' &&
                        lastChar != '.' &&
                        lastChar != ',' &&
                        lastChar != '!' &&
                        lastChar != '?' &&
                        lastChar != ':') {
                      _currentTranscript = '$trimmedCurrent $newWords';
                    } else {
                      _currentTranscript = '$trimmedCurrent$newWords';
                    }
                  } else {
                    _currentTranscript = newWords;
                  }
                }
                _controller.text = _currentTranscript;
                print(
                    'onResult (restart): updated transcript to "$_currentTranscript"');
              }
            });
          }
        },
      );

      _busyRetryCount = 0; // Reset retry count on success
      _isRestarting = false;
      print('Successfully restarted speech recognition');
    } catch (e) {
      _isRestarting = false;
      final errorStr = e.toString().toLowerCase();

      // Handle BUSY errors specifically
      if (errorStr.contains('busy') || errorStr.contains('already')) {
        _busyRetryCount++;
        print('BUSY error detected (attempt $_busyRetryCount), will retry...');

        // Exponential backoff: 1s, 2s, 4s, 8s...
        final delayMs = 1000 * (1 << (_busyRetryCount - 1).clamp(0, 4));

        if (_busyRetryCount <= 5 && mounted && _isRecording) {
          Future.delayed(Duration(milliseconds: delayMs), () {
            if (mounted && _isRecording && !_speech.isListening) {
              _safeRestartListening(sttLang);
            }
          });
        } else {
          print('Max BUSY retries reached, giving up');
          _busyRetryCount = 0;
        }
      } else {
        // Other errors - log and reset retry count
        print('Error restarting speech recognition: $e');
        _busyRetryCount = 0;
      }
    }
  }

  /// Toggle recording on/off for speech-to-text
  Future<void> _toggleRecording() async {
    if (!_allowInput) return;

    // Request microphone permission
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
        return;
      }
    }

    final langCode = Localizations.localeOf(context).languageCode;
    // Map 'te' to 'te_IN', 'en' to 'en_US'
    String sttLang = langCode == 'te' ? 'te_IN' : 'en_US';

    if (_isRecording) {
      // Stop recording manually
      _listeningMonitorTimer?.cancel(); // Stop the monitoring timer
      _listeningMonitorTimer = null;
      await _speech.stop();
      await _speech.cancel(); // Cancel to fully reset

      // Unmute system sounds after stopping
      await _unmuteSystemSounds();

      // USER EXPLICITLY STOPPED MICROPHONE - Finalize all accumulated text
      // This is the ONLY place where we finalize on stop (not on pauses)
      // BUT: If user manually cleared the input box, respect that and keep it empty
      final wasManuallyCleared = _controller.text.isEmpty;

      setState(() {
        if (!wasManuallyCleared) {
          // Only finalize if user didn't manually clear the text
          // Finalize: append current transcript to finalized (accumulate all text)
          if (_currentTranscript.isNotEmpty) {
            if (_finalizedTranscript.isNotEmpty) {
              _finalizedTranscript =
                  '$_finalizedTranscript $_currentTranscript'.trim();
            } else {
              _finalizedTranscript = _currentTranscript;
            }
          }
          _controller.text =
              _finalizedTranscript; // Update controller with finalized text
        } else {
          // User manually cleared the text - respect that and keep it empty
          _finalizedTranscript = '';
          _controller.text = '';
        }
        _currentTranscript = ''; // Clear current
        _isRecording = false;
        _recordingStartTime = null;
        _currentSttLang = null; // Clear language when stopping
      });
    } else {
      // Start recording - ensure clean state
      await _flutterTts.stop();
      await _speech.stop(); // Stop any existing session
      await _speech.cancel(); // Cancel to fully reset

      // Small delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 100));

      bool available = await _speech.initialize(
        onError: (val) {
          print('STT Error: ${val.errorMsg}, permanent: ${val.permanent}');
          final errorMsg = val.errorMsg.toLowerCase();

          // For continuous listening: Treat all errors as non-fatal
          // Silence and "no match" are normal - just continue listening
          if (errorMsg.contains('no_match') || errorMsg.contains('no match')) {
            print(
                'No match error detected - treating as silence/pause, continuing to listen...');
            // Don't do anything - just let it continue listening
            // The status handler will restart if needed
            return;
          }

          // For other errors, only stop on truly critical errors
          // Most errors are temporary and should not stop continuous listening
          if (val.permanent &&
              (errorMsg.contains('permission') ||
                  errorMsg.contains('denied'))) {
            // Only stop on permission errors - these are truly critical
            if (mounted) {
              setState(() {
                _isRecording = false;
                _recordingStartTime = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${val.errorMsg}')),
              );
            }
          } else {
            // All other errors (temporary or non-critical) - just restart listening
            print(
                'Non-critical error detected, will restart listening if needed: ${val.errorMsg}');
            if (mounted && _isRecording) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _isRecording && !_speech.isListening) {
                  _safeRestartListening(sttLang);
                }
              });
            }
          }
        },
        onStatus: (val) {
          // For continuous listening: IGNORE "done", "notListening", "noSpeech", "noMatch" completely
          // These are just SDK status updates during pauses - we treat them as normal, not completion
          // We do NOT restart or cancel - we just keep listening
          if (val == 'done' ||
              val == 'notListening' ||
              val == 'noSpeech' ||
              val == 'noMatch') {
            // Completely ignore these statuses - they're just pause indicators, not completion
            // The SDK will continue listening if we don't interfere
            // Only restart if speech recognition actually stopped (checked separately)
            return;
          }

          // Only handle critical statuses
          if (val == 'error' || val == 'aborted') {
            // Even for errors, don't auto-stop - let user decide
            print(
                'STT Status: $val - Critical status, but continuing in continuous mode');
            // DO NOT set _isRecording = false - let user manually stop
          } else if (val == 'listening') {
            // Speech recognition is active - this is good, no action needed
            print('STT Status: listening - Active and listening');
          }

          // Periodically check if we need to restart (only if actually stopped)
          // Do this check less frequently to avoid interference
          if (_isRecording && mounted && val == 'listening') {
            // Reset restart attempt when we confirm we're listening
            _lastRestartAttempt = null;
          }
        },
      );

      if (available) {
        setState(() {
          _isRecording = true;
          _currentSttLang =
              sttLang; // Store language for potential restart on clear
          // Start fresh - streaming mode will replace with latest recognized text
          // If user wants to continue, they can type or the finalized text is already in the controller
          _currentTranscript = ''; // Start fresh for streaming
          _recordingStartTime = DateTime.now();
          _lastRestartAttempt = null; // Reset restart tracker for new session
          _isRestarting = false; // Reset restart flag
          _busyRetryCount = 0; // Reset BUSY retry count
          _lastSpeechDetected = null; // Reset last speech timestamp
        });

        // Use try-catch for initial listen to handle BUSY errors
        try {
          await _speech.listen(
            localeId: sttLang,
            listenFor: const Duration(
                hours: 1), // Listen for up to 1 hour - continuous listening
            pauseFor: const Duration(
                hours:
                    1), // Allow very long pauses - treat silence as thinking time
            partialResults: true, // Get partial results as user speaks
            cancelOnError: false, // Don't cancel on errors, keep listening
            onResult: (result) {
              if (mounted && _isRecording) {
                setState(() {
                  final newWords = result.recognizedWords.trim();

                  // CONTINUOUS MODE: For initial session, newWords contains full transcript
                  // Replace current transcript (streaming updates), but preserve finalized text
                  if (newWords.isNotEmpty) {
                    print(
                        'onResult: newWords="$newWords", currentTranscript="$_currentTranscript"');
                    // Update last speech detected timestamp
                    _lastSpeechDetected = DateTime.now();

                    if (_currentTranscript.isEmpty) {
                      // First words
                      _currentTranscript = newWords;
                    } else if (newWords == _currentTranscript) {
                      // Exact match - no change needed
                      return;
                    } else if (newWords.startsWith(_currentTranscript.trim())) {
                      // Partial update - new words contain existing transcript (expanding)
                      _currentTranscript = newWords;
                    } else if (_currentTranscript.trim().endsWith(newWords)) {
                      // New words are a suffix of existing - likely a partial update, keep existing
                      return;
                    } else {
                      // New words - append them
                      // Check if we need to add a space
                      final trimmedCurrent = _currentTranscript.trim();
                      if (trimmedCurrent.isNotEmpty) {
                        final lastChar =
                            trimmedCurrent[trimmedCurrent.length - 1];
                        if (lastChar != ' ' &&
                            lastChar != '.' &&
                            lastChar != ',' &&
                            lastChar != '!' &&
                            lastChar != '?' &&
                            lastChar != ':') {
                          _currentTranscript = '$trimmedCurrent $newWords';
                        } else {
                          _currentTranscript = '$trimmedCurrent$newWords';
                        }
                      } else {
                        _currentTranscript = newWords;
                      }
                    }
                    _controller.text = _currentTranscript;
                    print(
                        'onResult: updated transcript to "$_currentTranscript"');
                  }
                });
              }
            },
          );
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('busy') || errorStr.contains('already')) {
            // Handle BUSY error on initial listen - use safe restart
            print('BUSY error on initial listen, using safe restart...');
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _isRecording) {
                _safeRestartListening(sttLang);
              }
            });
          } else {
            print('Error starting speech recognition: $e');
            // Unmute on error
            await _unmuteSystemSounds();
          }
        }
      } else {
        await _unmuteSystemSounds(); // Unmute if not available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Speech recognition not available. Please check if your device supports it.'),
          ),
        );
      }
    }
  }

  bool _textContainsTelugu(String s) {
    for (final r in s.runes) {
      if (r >= 0x0C00 && r <= 0x0C7F) return true;
    }
    return false;
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    final langCode = Localizations.localeOf(context).languageCode;
    String ttsLang = langCode == 'te' ? 'te-IN' : 'en-US';
    if (_textContainsTelugu(text)) ttsLang = 'te-IN';

    try {
      await _flutterTts.setLanguage(ttsLang);
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS Error: $e');
      // Fallback to English if Telugu fails or generic error
      if (ttsLang == 'te-IN') {
        try {
          await _flutterTts.setLanguage('en-US');
          await _flutterTts.speak(text);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _listeningMonitorTimer?.cancel(); // Cancel monitoring timer
    _listeningMonitorTimer = null;
    _controller.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    _speech.stop();
    _flutterTts.stop();
    // Ensure system sounds are unmuted when disposing
    _unmuteSystemSounds();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.go('/ai-legal-guider'), // Add this navigation
        ),
        title: Text(localizations.aiLegalAssistant ?? 'AI Legal Assistant'),
        backgroundColor: const Color(0xFFFC633C),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── CHAT MESSAGES ──
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      localizations.loading ?? 'Loading...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Align(
                        alignment: msg.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: msg.isUser ? orange : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: msg.isUser
                                ? null
                                : Border.all(
                                    color: Colors.grey.shade300, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            msg.content,
                            style: TextStyle(
                              color: msg.isUser ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── RECORDING INDICATOR (WhatsApp style with waveform) ──
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: background,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Recording indicator dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Timer
                  if (_recordingStartTime != null)
                    StreamBuilder<DateTime>(
                      stream: Stream.periodic(
                          const Duration(seconds: 1), (_) => DateTime.now()),
                      builder: (context, snapshot) {
                        final duration =
                            DateTime.now().difference(_recordingStartTime!);
                        final minutes = duration.inMinutes;
                        final seconds = duration.inSeconds % 60;
                        return Text(
                          '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  const SizedBox(width: 12),
                  // Waveform visualization
                  Expanded(
                    child: _WaveformVisualization(
                      isActive: _currentTranscript.isNotEmpty,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Pause/Stop button
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pause,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── INPUT FIELD ──
          if (!_isLoading && !_errored && _allowInput)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: background,
              child: Material(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Attachment button
                      GestureDetector(
                        onTap: _showAttachmentOptions,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.attach_file,
                            color: Colors.grey.shade700,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Text input field with rounded corners
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _inputFocus,
                            maxLines: 1,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            decoration: InputDecoration(
                              hintText: _currentQ >= 0 &&
                                      _currentQ < _questions.length
                                  ? _questions[_currentQ].question
                                  : localizations.typeMessage ??
                                      'Type your message...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 2,
                              ),
                              errorText: _inputError
                                  ? localizations.pleaseEnterYourAnswer ??
                                      "Please enter your answer"
                                  : null,
                              errorStyle: const TextStyle(fontSize: 10),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                            onSubmitted: (_) => _handleSend(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // WhatsApp-style mic button with animated waves
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Animated waves (only when recording) - positioned absolutely
                            if (_isRecording) ...[
                              Positioned.fill(
                                child: _AnimatedWave(
                                  delay: 0,
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              Positioned.fill(
                                child: _AnimatedWave(
                                  delay: 200,
                                  color: Colors.red.withOpacity(0.2),
                                ),
                              ),
                              Positioned.fill(
                                child: _AnimatedWave(
                                  delay: 400,
                                  color: Colors.red.withOpacity(0.1),
                                ),
                              ),
                            ],
                            // Microphone button
                            GestureDetector(
                              onTap: _toggleRecording,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: _isRecording ? Colors.red : orange,
                                  shape: BoxShape.circle,
                                  boxShadow: _isRecording
                                      ? [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.4),
                                            blurRadius: 5,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: orange.withOpacity(0.3),
                                            blurRadius: 2,
                                            spreadRadius: 0.5,
                                          ),
                                        ],
                                ),
                                child: Icon(
                                  _isRecording ? Icons.stop : Icons.mic,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Send button
                      GestureDetector(
                        onTap: _handleSend,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: orange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: orange.withOpacity(0.3),
                                blurRadius: 2,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── LOADER ──
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: orange),
            ),
        ],
      ),
    );
  }
}

// ── Helper Classes ──
class _ChatQ {
  final String key;
  final String question;
  const _ChatQ({required this.key, required this.question});
}

class _ChatMessage {
  final String user;
  final String content;
  final bool isUser;
  _ChatMessage(
      {required this.user, required this.content, required this.isUser});
}

// Animated wave widget for microphone button
class _AnimatedWave extends StatefulWidget {
  final int delay;
  final Color color;

  const _AnimatedWave({
    required this.delay,
    required this.color,
  });

  @override
  State<_AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<_AnimatedWave>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Start animation after delay
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Calculate size based on animation - expand outward from center
        final baseSize = 40.0;
        final maxExpansion = 35.0;
        final currentSize = baseSize + (_animation.value * maxExpansion);
        final opacity = 1.0 - _animation.value;

        return Center(
          child: Container(
            width: currentSize,
            height: currentSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withOpacity(opacity),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Waveform visualization widget
class _WaveformVisualization extends StatefulWidget {
  final bool isActive;

  const _WaveformVisualization({
    required this.isActive,
  });

  @override
  State<_WaveformVisualization> createState() => _WaveformVisualizationState();
}

class _WaveformVisualizationState extends State<_WaveformVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = [
    0.3,
    0.6,
    0.4,
    0.8,
    0.5,
    0.7,
    0.4,
    0.6,
    0.5,
    0.7,
    0.4,
    0.8,
    0.5,
    0.6,
    0.4,
    0.7
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        const orange = Color(0xFFFC633C);

        if (!widget.isActive) {
          // Show minimal static bars when not actively speaking
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(16, (index) {
              return Container(
                width: 2.5,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          );
        }

        // Animated bars when actively speaking
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(16, (index) {
            // Vary the height based on animation and index for wave effect
            final baseHeight = _barHeights[index];
            final phase = (index % 4) * 0.5;
            final animatedHeight = baseHeight +
                (0.2 *
                    (0.5 +
                        0.5 *
                            math.sin(_controller.value * 2 * math.pi + phase)));
            final height = (animatedHeight * 20).clamp(4.0, 20.0);

            return Container(
              width: 2.5,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        );
      },
    );
  }
}
