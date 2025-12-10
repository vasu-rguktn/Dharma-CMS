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
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class AiLegalChatScreen extends StatefulWidget {
  const AiLegalChatScreen({super.key});

  @override
  State<AiLegalChatScreen> createState() => _AiLegalChatScreenState();
}

class _AiLegalChatScreenState extends State<AiLegalChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final Dio _dio = Dio();

  List<_ChatQ> _questions = [];

  final Map<String, String> _answers = {};
  int _currentQ = -2; // -2 = Welcome, -1 = Let us begin, 0+ = questions
  bool _allowInput = false;
  bool _isLoading = false;
  bool _errored = false;
  bool _inputError = false;

  // STT (Speech-to-Text) variables
  // STT (Speech-to-Text) variables
  late final stt.SpeechToText _speech;
  late final FlutterTts _flutterTts;
  bool _isRecording = false;
  String _currentTranscript = '';
  // StreamSubscription<stt.SpeechRecognitionResult>? _sttSubscription;

  // Orange color
  static const Color orange = Color(0xFFFC633C);
  static const Color background = Color(0xFFF5F8FE);

  bool _hasStarted = false;

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
    final localizations = AppLocalizations.of(context)!;
    _questions = [
      _ChatQ(key: 'full_name', question: localizations.fullNameQuestion),
      _ChatQ(
          key: 'address',
          question: localizations.addressQuestion ??
              'Where do you live (place / area)?'),
      _ChatQ(
          key: 'phone',
          question:
              localizations.phoneQuestion ?? 'What is your phone number?'),
      _ChatQ(
          key: 'complaint_type',
          question: localizations.complaintTypeQuestion ??
              'What type of complaint do you want to file? (Theft, Harassment, Missing person, etc.)'),
      _ChatQ(
          key: 'details',
          question: localizations.detailsQuestion ??
              'Please describe your complaint in detail.'),
    ];
    
    // Initialize STT Service block removed

    
    if (!_hasStarted) {
      _hasStarted = true;
      _startChatFlow();
    }
  }

  Future<void> _startChatFlow() async {
    final localizations = AppLocalizations.of(context)!;

    setState(() {
      _messages.clear();
      _currentQ = -2;
      _allowInput = false;
      _errored = false;
    });
    _addBot(localizations.welcomeToDharma ?? 'Welcome to Dharma');
    await Future.delayed(const Duration(seconds: 1));
    _addBot(localizations.letUsBegin ?? 'Let us begin...');
    _currentQ = -1;
    setState(() {});
    await Future.delayed(const Duration(seconds: 2));
    _askNextQ();
  }

  void _addBot(String content) {
    _messages.add(_ChatMessage(user: 'AI', content: content, isUser: false));
    setState(() {});
    _scrollToEnd();
  }

  void _addUser(String content) {
    _messages.add(_ChatMessage(user: 'You', content: content, isUser: true));
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

  void _askNextQ() {
    _currentQ++;
    if (_currentQ < _questions.length) {
      _addBot(_questions[_currentQ].question);
      _speak(_questions[_currentQ].question);
      _allowInput = true;
      setState(() => _inputError = false);
      Timer(
          const Duration(milliseconds: 600), () => _inputFocus.requestFocus());
    } else {
      _submitToBackend();
    }
  }

  Future<void> _submitToBackend() async {
    final localizations = AppLocalizations.of(context)!;
    // prevent double submit
    if (_isLoading) return;
    // validate required fields
    final missing = <String>[];
    for (final q in _questions) {
      if (!(_answers.containsKey(q.key) &&
          _answers[q.key]!.trim().isNotEmpty)) {
        missing.add(q.key);
      }
    }
    if (missing.isNotEmpty) {
      _addBot(localizations.pleaseAnswerAllQuestions(missing as String) ??
          'Please answer all questions before submitting. Missing: ${missing.join(', ')}');
      setState(() {
        _allowInput = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _allowInput = false;
      _errored = false;
    });

    // Determine base URL robustly
    String baseUrl;
    if (kIsWeb) {
      // on web you probably want to call your absolute backend URL
      // baseUrl = 'https://dharma-backend-x1g4.onrender.com';
       baseUrl="https://dharma-backend-x1g4.onrender.com";
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android physical device (requires adb reverse tcp:8000 tcp:8000)
      // baseUrl = 'http://127.0.0.1:8000';
       baseUrl="https://dharma-backend-x1g4.onrender.com";
    } else {
      // iOS simulator / other platforms
      // baseUrl = 'https://dharma-backend-x1g4.onrender.com';
       baseUrl="https://dharma-backend-x1g4.onrender.com";
    }

    final localeCode = Localizations.localeOf(context).languageCode;

    final payload = {
      'full_name': _answers['full_name'] ?? '',
      'address': _answers['address'] ?? '',
      'phone': _answers['phone'] ?? _answers['phone_number'] ?? '',
      'complaint_type': _answers['complaint_type'] ?? '',
      'details': _answers['details'] ?? '',
      'language': localeCode,
    };

    try {
      final resp = await _dio.post(
        '$baseUrl/complaint/summarize',
        data: payload,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final data = resp.data ?? {};
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
              : classification; // Fallback to displayed one if missing

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

      // update stored answers to the localized variant so downstream screens see the selected language
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

      // navigate to details screen after a small delay, ensure still mounted
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        context.go(
          '/ai-chatbot-details',
          extra: {
            'answers': Map<String, String>.from(_answers),
            'summary': formalSummary,
            'classification': classification,
            'originalClassification': originalClassification, // Pass this!
          },
        );
      });
    } on DioError catch (e) {
      String msg = localizations.somethingWentWrong ??
          'Sorry, something went wrong. Please try again later.';
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
      } else if (e.error != null) {
        msg = e.error.toString();
      }
      _addBot(msg);
      setState(() {
        _isLoading = false;
        _allowInput = false;
        _errored = true;
      });
    } catch (e) {
      _addBot('Unexpected error: ${e.toString()}');
      setState(() {
        _isLoading = false;
        _allowInput = false;
        _errored = true;
      });
    }
  }

  void _handleSend() {
    _flutterTts.stop();
    final text = _controller.text.trim();
    if (!_allowInput || _isLoading) return;
    if (text.isEmpty) {
      setState(() => _inputError = true);
      _inputFocus.requestFocus();
      return;
    }
    setState(() => _inputError = false);
    _controller.clear();
    _addUser(text);

    if (_currentQ >= 0 && _currentQ < _questions.length) {
      _answers[_questions[_currentQ].key] = text;
    }

    _allowInput = false;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 600), _askNextQ);
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
      // Stop recording
      await _speech.stop();
      setState(() {
        _isRecording = false;
        // Keep the final transcript in _controller.text
      });
    } else {
      // Start recording
      await _flutterTts.stop();
      bool available = await _speech.initialize(
        onError: (val) {
          print('STT Error: $val');
          setState(() => _isRecording = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${val.errorMsg}')),
          );
        },
        onStatus: (val) {
          print('STT Status: $val');
          if (val == 'done' || val == 'notListening') {
            setState(() => _isRecording = false);
          }
        },
      );

      if (available) {
        setState(() => _isRecording = true);
        _speech.listen(
          localeId: sttLang,
          onResult: (result) {
            setState(() {
              _currentTranscript = result.recognizedWords;
              _controller.text = result.recognizedWords;
            });
          },
        );
      } else {
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
    _controller.dispose();
    _inputFocus.dispose();
    _scrollController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

          // ── RECORDING INDICATOR ──
          if (_isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.red.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mic, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentTranscript.isEmpty 
                        ? 'Listening...' 
                        : _currentTranscript,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // ── INPUT FIELD ──
          if (!_isLoading && !_errored && _allowInput)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              color: background,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _inputFocus,
                          decoration: InputDecoration(
                            hintText:
                                _currentQ >= 0 && _currentQ < _questions.length
                                    ? _questions[_currentQ].question
                                    : localizations.typeMessage ??
                                        'Type your message...',
                            border: InputBorder.none,
                            errorText: _inputError
                                ? localizations.pleaseEnterYourAnswer ??
                                    "Please enter your answer"
                                : null,
                            errorStyle: const TextStyle(fontSize: 12),
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isRecording ? Icons.stop_circle : Icons.mic,
                          color: _isRecording ? Colors.red : orange,
                        ),
                        onPressed: _toggleRecording,
                        tooltip: _isRecording 
                          ? "Tap to stop recording" 
                          : (localizations.voiceInputComingSoon ?? "Voice input"),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: orange),
                        onPressed: _handleSend,
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
