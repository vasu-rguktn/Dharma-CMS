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
  DateTime? _recordingStartTime;
  DateTime? _lastRestartAttempt; // Track last restart to prevent rapid cycling
  bool _isRestarting = false; // Track if restart is in progress to prevent BUSY errors
  int _busyRetryCount = 0; // Track BUSY error retries
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
       baseUrl="https://fastapi-app-335340524683.asia-south1.run.app";
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android physical device (requires adb reverse tcp:8000 tcp:8000)
      // baseUrl = 'http://127.0.0.1:8000';
       baseUrl="https://fastapi-app-335340524683.asia-south1.run.app";
    } else {
      // iOS simulator / other platforms
      // baseUrl = 'https://fastapi-app-335340524683.asia-south1.run.app';
       baseUrl="https://fastapi-app-335340524683.asia-south1.run.app";
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

  /// Safely restart speech recognition with BUSY error handling
  Future<void> _safeRestartListening(String sttLang) async {
    // Prevent multiple simultaneous restart attempts
    if (_isRestarting) {
      print('Restart already in progress, skipping...');
      return;
    }
    
    // Check if already listening
    if (_speech.isListening) {
      print('Speech recognition already listening, skipping restart...');
      return;
    }
    
    // Check throttle
    final now = DateTime.now();
    if (_lastRestartAttempt != null && 
        now.difference(_lastRestartAttempt!).inMilliseconds < 2000) {
      print('Too soon since last restart attempt, skipping...');
      return;
    }
    
    _isRestarting = true;
    _lastRestartAttempt = now;
    
    try {
      // Small delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Double-check we're still recording and not already listening
      if (!mounted || !_isRecording || _speech.isListening) {
        _isRestarting = false;
        return;
      }
      
      await _speech.listen(
        localeId: sttLang,
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(minutes: 5),
        partialResults: true,
        cancelOnError: false,
        onResult: (result) {
          if (mounted) {
            setState(() {
              final newWords = result.recognizedWords.trim();
              if (newWords.isNotEmpty) {
                if (_currentTranscript.isNotEmpty && 
                    !_currentTranscript.endsWith(newWords)) {
                  if (!newWords.startsWith(_currentTranscript)) {
                    _currentTranscript = '$_currentTranscript $newWords';
                  } else {
                    _currentTranscript = newWords;
                  }
                } else {
                  _currentTranscript = newWords;
                }
                _controller.text = _currentTranscript;
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
      await _speech.stop();
      await _speech.cancel(); // Cancel to fully reset
      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
        // Keep the final transcript in _controller.text
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
          
          // "No match" errors should NEVER stop recording, even if marked permanent
          // This is a normal part of speech recognition when there's silence
          if (errorMsg.contains('no_match') || errorMsg.contains('no match')) {
            print('No match error detected - ignoring and continuing to listen...');
            // Don't stop recording, just restart listening after a delay
            if (mounted && _isRecording) {
              // Prevent rapid cycling
              final now = DateTime.now();
              if (_lastRestartAttempt != null && 
                  now.difference(_lastRestartAttempt!).inMilliseconds < 3000) {
                print('Skipping no match error restart - too soon since last attempt');
                return;
              }
              
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted && _isRecording) {
                  _safeRestartListening(sttLang);
                }
              });
            }
            return; // Don't process further, just restart
          }
          
          // Only stop on actual permanent errors (not "no match")
          if (val.permanent) {
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
            // Temporary error - try to restart listening
            print('Temporary error, attempting to restart...');
            if (mounted && _isRecording) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _isRecording) {
                  _safeRestartListening(sttLang);
                }
              });
            }
          }
        },
        onStatus: (val) {
          print('STT Status: $val');
          // Only stop on actual critical errors (not "no match" which is normal)
          if (val == 'error' || val == 'aborted') {
            if (mounted) {
              setState(() {
                _isRecording = false;
                _recordingStartTime = null;
              });
            }
          }
          // Handle various statuses that indicate speech recognition stopped
          // but we want to continue listening
          // Note: Don't restart on 'noMatch' immediately - it's just a temporary state
          if ((val == 'done' || val == 'notListening' || val == 'noSpeech') && 
              _isRecording && mounted) {
            // Prevent rapid cycling - only restart if enough time has passed since last attempt
            final now = DateTime.now();
            if (_lastRestartAttempt != null && 
                now.difference(_lastRestartAttempt!).inMilliseconds < 2000) {
              print('Skipping restart - too soon since last attempt');
              return;
            }
            
            // Restart listening after a delay to avoid BUSY errors
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted && _isRecording) {
                _safeRestartListening(sttLang);
              }
            });
          }
          // Handle 'noMatch' separately - wait longer before restarting
          // 'noMatch' is a temporary state that doesn't necessarily mean listening stopped
          if (val == 'noMatch' && _isRecording && mounted) {
            print('No match detected, waiting before checking if restart needed...');
            // Prevent rapid cycling
            final now = DateTime.now();
            if (_lastRestartAttempt != null && 
                now.difference(_lastRestartAttempt!).inMilliseconds < 3000) {
              print('Skipping noMatch restart - too soon since last attempt');
              return;
            }
            
            // Wait longer (8 seconds) before checking if we need to restart
            // This gives the speech recognition time to continue naturally
            Future.delayed(const Duration(seconds: 8), () {
              if (mounted && _isRecording) {
                _safeRestartListening(sttLang);
              }
            });
          }
        },
      );

      if (available) {
        setState(() {
          _isRecording = true;
          _currentTranscript = '';
          _recordingStartTime = DateTime.now();
          _lastRestartAttempt = null; // Reset restart tracker for new session
          _isRestarting = false; // Reset restart flag
          _busyRetryCount = 0; // Reset BUSY retry count
        });
        
        // Use try-catch for initial listen to handle BUSY errors
        try {
          await _speech.listen(
            localeId: sttLang,
            listenFor: const Duration(minutes: 10), // Listen for up to 10 minutes
            pauseFor: const Duration(minutes: 5), // Allow up to 5 minutes of silence/pause
            partialResults: true, // Get partial results as user speaks
            cancelOnError: false, // Don't cancel on errors, keep listening
            onResult: (result) {
              if (mounted) {
                setState(() {
                  // Accumulate transcript - append new words to existing
                  final newWords = result.recognizedWords.trim();
                  if (newWords.isNotEmpty) {
                    if (_currentTranscript.isNotEmpty && 
                        !_currentTranscript.endsWith(newWords)) {
                      // Only append if it's new content (not just a partial update)
                      if (!newWords.startsWith(_currentTranscript)) {
                        // New words - append them
                        _currentTranscript = '$_currentTranscript $newWords';
                      } else {
                        // It's an update to existing words - replace
                        _currentTranscript = newWords;
                      }
                    } else {
                      // First words or empty transcript
                      _currentTranscript = newWords;
                    }
                    _controller.text = _currentTranscript;
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
          }
        }
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
                      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                      builder: (context, snapshot) {
                        final duration = DateTime.now().difference(_recordingStartTime!);
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
                      // WhatsApp-style mic button with animated waves
                      SizedBox(
                        width: 40,
                        height: 40,
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _isRecording ? Colors.red : orange,
                                  shape: BoxShape.circle,
                                  boxShadow: _isRecording
                                      ? [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  _isRecording ? Icons.stop : Icons.mic,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
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
  final List<double> _barHeights = [0.3, 0.6, 0.4, 0.8, 0.5, 0.7, 0.4, 0.6, 0.5, 0.7, 0.4, 0.8, 0.5, 0.6, 0.4, 0.7];

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
                (0.2 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi + phase)));
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
