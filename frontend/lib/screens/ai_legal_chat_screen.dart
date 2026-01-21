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
// lib/screens/ai_legal_chat_screen.dart
import 'dart:async';
import 'dart:io';
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
import 'package:Dharma/services/native_speech_recognizer.dart';

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
  @override
  bool get wantKeepAlive => true;

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

  // Helper to check if we're running on a real Android device (not web)
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  // Local state
  bool _inputError = false;
  bool _isDynamicMode = false;
  List<Map<String, String>> _dynamicHistory = [];

  // STT (Speech-to-Text) variables
  late final stt.SpeechToText _speech;
  late final NativeSpeechRecognizer _nativeSpeech; // Android native ASR
  late final FlutterTts _flutterTts;
  bool _isRecording = false;
  String _currentTranscript =
      ''; // Live/streaming transcript (temporary, gets replaced)
  String _finalizedTranscript =
      ''; // Finalized transcript (locked when user stops/sends)
  String _lastRecognizedText = ''; // Last text from SDK (for comparison)
  DateTime? _recordingStartTime;
  DateTime? _lastRestartAttempt; // Track last restart to prevent rapid cycling
  bool _isRestarting =
      false; // Track if restart is in progress to prevent BUSY errors
  DateTime? _lastSpeechDetected; // Track when speech was last detected
  DateTime? _lastDoneStatus; // Track when "done" status was last received
  int _busyRetryCount = 0; // Track BUSY error retries
  Timer? _listeningMonitorTimer; // Timer to monitor continuous listening
  String? _currentSttLang; // Store current STT language for restarting
  bool _ignoreAsrCallbacks = false; // Ignore ASR callbacks after sending
  bool _isUpdatingFromAsr = false; // Flag to prevent manual edit detection during ASR updates
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
    _nativeSpeech = NativeSpeechRecognizer();
    _flutterTts = FlutterTts();
    _flutterTts.setSpeechRate(0.45);
    _flutterTts.setPitch(1.0);
    
    // Setup TTS-ASR coordination to prevent feedback loop
    _setupTTSHandlers();
    
    // Setup native speech recognizer callbacks (Android only)
    if (_isAndroid) {
      _setupNativeSpeechCallbacks();
    }
    
    // Listen to text controller changes to sync with manual edits
    _controller.addListener(() {
      if (_isRecording && !_isUpdatingFromAsr) {
        final currentText = _controller.text.trim();
        
        // If user manually edited the text, sync ASR state
        final expectedText = _finalizedTranscript.isEmpty
            ? _currentTranscript
            : '$_finalizedTranscript $_currentTranscript';
        
        if (currentText != expectedText.trim()) {
          // User manually edited - update state to match
          final expectedTextTrimmed = expectedText.trim();
          final textWasShortened = currentText.length < expectedTextTrimmed.length;
          
          print('Manual edit detected: "$currentText" (was: "$expectedTextTrimmed", shortened: $textWasShortened)');
          setState(() {
            // Treat entire text as finalized (user's manual edit)
            _finalizedTranscript = currentText;
            _currentTranscript = '';
            _lastRecognizedText = '';
          });
          print('ASR state synced with manual edit');
          
          // CRITICAL: If text was shortened (words removed), restart ASR to clear its buffer
          // This prevents ASR from re-adding removed words when user speaks again
          if (textWasShortened && _isRecording) {
            print('🔄 Text was shortened - restarting ASR to clear buffer...');
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_isRecording && mounted) {
                if (_isAndroid) {
                  // Restart native Android ASR
                  _nativeSpeech.stopListening();
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (_isRecording && _currentSttLang != null && mounted) {
                      _nativeSpeech.startListening(language: _currentSttLang!);
                    }
                  });
                } else {
                  // Restart speech_to_text (iOS/Web)
                  _seamlessRestart();
                }
              }
            });
          }
        }
      }
    });
  }
  
  /// Setup native speech recognizer callbacks (Android only)
  void _setupNativeSpeechCallbacks() {
    _nativeSpeech.onPartialResult = (text) {
      // Ignore if we just sent a message
      if (_ignoreAsrCallbacks) {
        print('Ignoring ASR callback (just sent message)');
        // Ensure controller stays clear
        if (mounted) {
          setState(() {
            _controller.clear();
          });
        }
        return;
      }
      
      if (mounted && _isRecording) {
        setState(() {
          _isUpdatingFromAsr = true;
          // PARTIAL RESULT: Extract only genuinely new words (not already at end)
          String partialToShow;
          if (_finalizedTranscript.isEmpty) {
            // No finalized text yet - use ASR text directly
            partialToShow = text;
          } else {
            // Have finalized text - extract only new words
            partialToShow = extractNewWordsOnly(_finalizedTranscript, text);
            // If extraction returns empty but ASR has text, use ASR text
            if (partialToShow.isEmpty && text.isNotEmpty) {
              partialToShow = text;
            }
          }
          
          // Update current transcript
          _currentTranscript = partialToShow;
          _lastRecognizedText = text;
          // Display: finalized + current partial
          final displayText = _finalizedTranscript.isEmpty
              ? _currentTranscript
              : (_currentTranscript.isEmpty 
                  ? _finalizedTranscript 
                  : '$_finalizedTranscript $_currentTranscript');
          _controller.text = displayText.trim();
          
          _isUpdatingFromAsr = false;
          print('Native partial: "$text" -> showing "$partialToShow" (finalized: "$_finalizedTranscript", current: "$_currentTranscript")');
        });
      }
    };
    
    _nativeSpeech.onFinalResult = (text) {
      // Ignore if we just sent a message
      if (_ignoreAsrCallbacks) {
        print('Ignoring final ASR callback (just sent message)');
        // Ensure controller stays clear
        if (mounted) {
          setState(() {
            _controller.clear();
          });
        }
        return;
      }
      
      if (mounted && _isRecording) {
        setState(() {
          _isUpdatingFromAsr = true;
          // FINAL RESULT: Merge with finalized transcript
          final merged = mergeAsrWithCurrentText(_finalizedTranscript, text);
          _finalizedTranscript = merged;
          _currentTranscript = '';
          _lastRecognizedText = text;
          _controller.text = merged;
          
          _isUpdatingFromAsr = false;
          print('Native final (merged): "$text" -> "$merged"');
        });
      }
    };
    
    _nativeSpeech.onError = (error, message) {
      print('Native ASR error: $error - $message');
      // Errors are handled by auto-restart in native code
    };
    
    _nativeSpeech.onListeningStarted = () {
      print('Native ASR started');
    };
    
    _nativeSpeech.onListeningStopped = () {
      print('Native ASR stopped');
    };
  }
  
  /// Extract only genuinely new words from ASR text (for partial results)
  /// Returns only words that aren't already at the end of current text
  String extractNewWordsOnly(String currentText, String asrText) {
    currentText = currentText.trim();
    asrText = asrText.trim();
    
    if (currentText.isEmpty) return asrText;
    
    final normalizedCurrent = currentText.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalizedAsr = asrText.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // If ASR doesn't start with current, return ASR as-is (might be completely new)
    if (!normalizedAsr.startsWith(normalizedCurrent)) {
      return asrText;
    }
    
    final currentWords = normalizedCurrent.split(' ');
    final asrWords = normalizedAsr.split(' ');
    
    if (asrWords.length <= currentWords.length) {
      return ''; // No new words
    }
    
    final suffixWordsNormalized = asrWords.sublist(currentWords.length);
    final asrWordsOriginal = asrText.split(RegExp(r'\s+'));
    
    if (asrWordsOriginal.length <= currentWords.length) {
      return '';
    }
    
    final suffixWordsOriginal = asrWordsOriginal.sublist(currentWords.length);
    
    // CRITICAL: Check if suffix starts with words that don't match current text end
    // This handles cases where ASR re-adds manually removed words
    // Example: current="hello", ASR="hello world welcome", suffix="world welcome"
    // "world" doesn't match end of "hello", so it was likely removed - skip it
    
    // Strategy: If suffix has multiple words and first word doesn't match current end,
    // skip the first word (it's likely a removed word that ASR is re-adding)
    int startIndex = 0;
    if (currentWords.isNotEmpty && suffixWordsNormalized.length > 1) {
      final lastWordOfCurrent = currentWords.last.toLowerCase();
      final firstWordOfSuffix = suffixWordsNormalized[0].toLowerCase();
      
      // If first word of suffix doesn't match last word of current, skip it
      // This handles: current="hello", suffix="world welcome" → skip "world", add "welcome"
      if (firstWordOfSuffix != lastWordOfCurrent) {
        startIndex = 1; // Skip first word, start from second
      }
    }
    
    // Check each word individually - only add words that aren't already at the end
    final wordsToAdd = <String>[];
    for (int i = startIndex; i < suffixWordsNormalized.length; i++) {
      final wordToCheck = suffixWordsNormalized[i];
      
      // Check if this word is already at the end of current text
      bool wordAlreadyPresent = false;
      if (currentWords.isNotEmpty) {
        // Check if the last word matches
        if (currentWords.last.toLowerCase() == wordToCheck.toLowerCase()) {
          wordAlreadyPresent = true;
        }
        // Also check if multiple words at the end match
        if (!wordAlreadyPresent && currentWords.length >= (i - startIndex + 1)) {
          final endWords = currentWords.sublist(currentWords.length - (i - startIndex + 1));
          final suffixSoFar = suffixWordsNormalized.sublist(startIndex, i + 1);
          if (endWords.join(' ').toLowerCase() == suffixSoFar.join(' ').toLowerCase()) {
            wordAlreadyPresent = true;
          }
        }
      }
      
      if (!wordAlreadyPresent) {
        wordsToAdd.add(suffixWordsOriginal[i]);
      } else {
        // Word already present - stop here (don't add this or following words)
        break;
      }
    }
    
    return wordsToAdd.join(' ');
  }
  
  /// Merge ASR text with current text intelligently to prevent duplication
  String mergeAsrWithCurrentText(String currentText, String asrText) {
    currentText = currentText.trim();
    asrText = asrText.trim();

    if (currentText.isEmpty) return asrText;

    // Normalize both texts for comparison (lowercase, single spaces)
    final normalizedCurrent = currentText.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalizedAsr = asrText.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

    // If texts are exactly the same, return current (preserve user's capitalization)
    if (normalizedCurrent == normalizedAsr) {
      return currentText;
    }

    // If ASR text is already fully contained in current text, don't append
    if (normalizedCurrent.contains(normalizedAsr)) {
      return currentText;
    }

    // If ASR text starts with current text, extract only the suffix (new words)
    if (normalizedAsr.startsWith(normalizedCurrent)) {
      // Split into words for accurate comparison
      final currentWords = normalizedCurrent.split(' ');
      final asrWords = normalizedAsr.split(' ');
      
      // If ASR has same or fewer words, it's already contained
      if (asrWords.length <= currentWords.length) {
        return currentText;
      }
      
      // Get the suffix words (words after currentText in ASR)
      final suffixWordsNormalized = asrWords.sublist(currentWords.length);
      if (suffixWordsNormalized.isEmpty) return currentText;
      
      // Get suffix from original ASR text (preserve case)
      final asrWordsOriginal = asrText.split(RegExp(r'\s+'));
      if (asrWordsOriginal.length <= currentWords.length) {
        return currentText;
      }
      
      final suffixWordsOriginal = asrWordsOriginal.sublist(currentWords.length);
      
      // CRITICAL: Check each word individually - only add words that aren't already at the end
      final wordsToAdd = <String>[];
      for (int i = 0; i < suffixWordsNormalized.length; i++) {
        final wordToCheck = suffixWordsNormalized[i];
        
        // Check if this word is already at the end of current text
        bool wordAlreadyPresent = false;
        if (currentWords.isNotEmpty) {
          // Check if the last word(s) match this word
          // Check single word match
          if (currentWords.last.toLowerCase() == wordToCheck.toLowerCase()) {
            wordAlreadyPresent = true;
          }
          // Also check if multiple words at the end match (e.g., "purse purse" already there)
          if (!wordAlreadyPresent && currentWords.length >= i + 1) {
            final endWords = currentWords.sublist(currentWords.length - (i + 1));
            final suffixSoFar = suffixWordsNormalized.sublist(0, i + 1);
            if (endWords.join(' ').toLowerCase() == suffixSoFar.join(' ').toLowerCase()) {
              wordAlreadyPresent = true;
            }
          }
        }
        
        if (!wordAlreadyPresent) {
          // This word is genuinely new - add it
          wordsToAdd.add(suffixWordsOriginal[i]);
        } else {
          // This word is already at the end - skip it and all following words
          // (because if "purse" is already there, we don't want to add "purse Pur" or "purse purse")
          break;
        }
      }
      
      // If no new words to add, return current text as-is
      if (wordsToAdd.isEmpty) {
        return currentText;
      }
      
      // Append only the genuinely new words
      final suffix = wordsToAdd.join(' ');
      final result = (currentText + ' ' + suffix).replaceAll(RegExp(r'\s+'), ' ').trim();
      
      // Safety check: prevent duplicate patterns
      final normalizedResult = result.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (normalizedResult.contains(normalizedCurrent + ' ' + normalizedCurrent)) {
        return currentText; // Duplicate detected
      }
      
      return result;
    }

    // Find common prefix (for cases where texts don't align perfectly)
    int minLen = math.min(currentText.length, asrText.length);
    int i = 0;
    while (i < minLen && 
           currentText[i].toLowerCase() == asrText[i].toLowerCase()) {
      i++;
    }

    // Get the suffix (new words from ASR)
    final suffix = asrText.substring(i).trimLeft();
    if (suffix.isEmpty) return currentText;

    // Check if suffix is already at the end of current text (prevent duplicates)
    final normalizedSuffix = suffix.toLowerCase().trim();
    final currentWords = normalizedCurrent.split(' ');
    final suffixWords = normalizedSuffix.split(' ');
    
    // If the last few words of current text match the suffix words, don't append
    if (currentWords.length >= suffixWords.length) {
      final lastWords = currentWords.sublist(
        currentWords.length - suffixWords.length
      );
      if (lastWords.join(' ') == suffixWords.join(' ')) {
        return currentText; // Suffix already present, don't duplicate
      }
    }

    // Append only if there's genuinely new content
    return (currentText + ' ' + suffix).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Correct common speech recognition mistakes
  String _correctCommonMistakes(String text) {
    // Fix common misrecognitions
    // "triple it news video" → "IIIT Nuzvid"
    text = text.replaceAll(RegExp(r'triple\s*it\s*news\s*video', caseSensitive: false), 'IIIT Nuzvid');
    text = text.replaceAll(RegExp(r'triple\s*it', caseSensitive: false), 'IIIT');
    text = text.replaceAll(RegExp(r'news\s*video', caseSensitive: false), 'Nuzvid');
    
    // Add more corrections as you discover them
    // Example: text = text.replaceAll(RegExp(r'wrong\s*word', caseSensitive: false), 'correct word');
    
    return text;
  }
  
  /// Setup TTS handlers to coordinate with ASR (prevent feedback loop)
  void _setupTTSHandlers() {
    // When TTS starts speaking, pause ASR to prevent feedback
    _flutterTts.setStartHandler(() {
      print('TTS started - pausing ASR');
      _pauseASRForTTS();
    });
    
    // When TTS finishes, resume ASR automatically
    _flutterTts.setCompletionHandler(() {
      print('TTS completed - resuming ASR');
      _resumeASRAfterTTS();
    });
    
    // Handle TTS errors
    _flutterTts.setErrorHandler((msg) {
      print('TTS error: $msg - resuming ASR');
      _resumeASRAfterTTS();
    });
  }
  
  /// Pause ASR when TTS is speaking (prevent feedback loop)
  void _pauseASRForTTS() {
    if (_isRecording && mounted) {
      print('Pausing ASR for TTS...');

      
      if (_isAndroid) {
        // Use native recognizer on Android
        _nativeSpeech.stopListening();
      } else {
        // Use speech_to_text on iOS
        _speech.stop();
        _listeningMonitorTimer?.cancel();
      }
    }
  }
  
  /// Resume ASR after TTS finishes
  void _resumeASRAfterTTS() {
    if (_isRecording && mounted) {
      print('Resuming ASR after TTS...');
      
      // Small delay to ensure TTS audio has fully stopped
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (_isRecording && mounted) {
          if (_isAndroid) {
            // Restart native recognizer
            if (!_nativeSpeech.isListening && _currentSttLang != null) {
              await _nativeSpeech.startListening(language: _currentSttLang!);
            }
          } else {
            // Restart speech_to_text
            if (!_speech.isListening) {
              _seamlessRestart();
            }
          }
        }
      });
    }
  }
  
  /// Centralized function to reset chat state
  void _resetChatState({bool clearMessages = true, bool stopASR = false}) {
    print('Resetting chat state: clearMessages=$clearMessages, stopASR=$stopASR');
    
    setState(() {
      // Reset ASR state
      _finalizedTranscript = '';
      _currentTranscript = '';
      _lastRecognizedText = '';
      
      // Clear input
      _controller.clear();
      _inputError = false;
      
      // Clear chat messages if requested
      if (clearMessages) {
        _ChatStateHolder.messages.clear();
        _ChatStateHolder.answers.clear();
        _ChatStateHolder.currentQ = 0;
        _ChatStateHolder.hasStarted = false;
        _dynamicHistory.clear();
      }
      
      // Stop ASR if requested
      if (stopASR && _isRecording) {
        _isRecording = false;
        _recordingStartTime = null;
        _listeningMonitorTimer?.cancel();
      }
    });
    
    // Stop TTS
    try {
      _flutterTts.stop();
    } catch (_) {}
    
    // Stop ASR if requested
    if (stopASR) {
      try {
        if (_isAndroid) {
          _nativeSpeech.stopListening();
        } else {
          _speech.stop();
          _speech.cancel();
        }
      } catch (_) {}
    }
  }
  
  /// Handle back button press
  Future<bool> _onWillPop() async {
    // If chat is active, show confirmation dialog
    if (_messages.isNotEmpty || _isRecording) {
      await _showExitDialog();
      return false; // Prevent navigation
    }
    return true; // Allow navigation
  }
  
  /// Show exit confirmation dialog
  Future<void> _showExitDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('AI Chat in Progress'),
          content: const Text('Do you want to stop using the AI chatbot?'),
          actions: [
            // CLEAR CHAT button
            TextButton(
              onPressed: () => Navigator.of(context).pop('clear'),
              child: const Text(
                'CLEAR CHAT',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
            
            // CLOSE CHAT button
            TextButton(
              onPressed: () => Navigator.of(context).pop('close'),
              child: const Text(
                'CLOSE CHAT',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            
            // NO button
            TextButton(
              onPressed: () => Navigator.of(context).pop('no'),
              child: const Text('NO'),
            ),
          ],
        );
      },
    );
    
    // Handle user choice
    if (result == 'clear') {
      _clearChat();
    } else if (result == 'close') {
      _closeChat();
    }
    // If 'no', do nothing (dialog closes, chat continues)
  }
  
  /// Clear chat but stay on screen
  void _clearChat() {
    _resetChatState(clearMessages: true, stopASR: false);
    // Restart chat flow for fresh conversation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _startChatFlow();
      }
    });
  }
  
  /// Close chat and navigate away
  void _closeChat() {
    _resetChatState(clearMessages: true, stopASR: true);
    context.go('/dashboard'); // Navigate to dashboard
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only start chat flow if we haven't started AND have no messages
    // This preserves state when navigating back to the screen
    if (!_ChatStateHolder.hasStarted) {
      if (_ChatStateHolder.messages.isEmpty) {
        // First time - start the chat flow
        _ChatStateHolder.hasStarted = true;
        _startChatFlow();
      } else {
        // Returning to existing chat - preserve state
        _ChatStateHolder.hasStarted = true;
        // Ensure input is enabled if we're in the middle of a dynamic turn
        if (!_isLoading && !_errored) {
          _setAllowInput(true);
          setState(() {});
        }
      }
    }
  }

  Future<void> _startChatFlow() async {
    final localizations = AppLocalizations.of(context)!;

    setState(() {
      _ChatStateHolder.messages.clear();
      _ChatStateHolder.messages.clear();
      _dynamicHistory.clear();
      _ChatStateHolder.answers.clear();
      _setCurrentQ(0);
      _setAllowInput(false);
      _setErrored(false);
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
      _setAllowInput(true); // Wait for user info
    });
  }

  // Helper methods to sync local state and Holder
  void _setAllowInput(bool value) {
    setState(() {
      _ChatStateHolder.allowInput = value;
    });
  }

  void _setCurrentQ(int value) {
    setState(() {
      _ChatStateHolder.currentQ = value;
    });
  }

  void _setIsLoading(bool value) {
    setState(() {
      _ChatStateHolder.isLoading = value;
    });
  }

  void _setErrored(bool value) {
    setState(() {
      _ChatStateHolder.errored = value;
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
      baseUrl = "https://fastapi-app-335340524683.asia-south1.run.app";
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Android physical device (requires adb reverse tcp:8000 tcp:8000)
      baseUrl = "https://fastapi-app-335340524683.asia-south1.run.app";
    } else {
      // iOS simulator / other platforms
      baseUrl = "https://fastapi-app-335340524683.asia-south1.run.app";
    }

    final localeCode = Localizations.localeOf(context).languageCode;

    // Construct Payload
    final payload = {
      'full_name': _ChatStateHolder.answers['full_name'] ?? '',
      'address': _ChatStateHolder.answers['address'] ?? '',
      'phone': _ChatStateHolder.answers['phone'] ??
          _ChatStateHolder.answers['phone_number'] ??
          '',
      'complaint_type': _ChatStateHolder.answers['complaint_type'] ?? '',
      'initial_details': _ChatStateHolder.answers['details'] ?? '',
      'language': localeCode,
      'chat_history': _dynamicHistory,
    };
    
    print('🚀 Sending to backend:');
    print('   History items: ${_dynamicHistory.length}');
    print('   Payload: $payload');

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
          _setIsLoading(false);
          _setAllowInput(true);
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
      
      // Enhanced error logging for debugging
      print('❌ Chat step error: $e');
      
      if (e is DioException) {
        print('HTTP Status Code: ${e.response?.statusCode}');
        print('Response Data: ${e.response?.data}');
        
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
        _setIsLoading(false);
        _setAllowInput(true); // Allow retry?
        _setErrored(true);
      });
    }
  }

  Future<void> _handleFinalResponse(dynamic data) async {
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
        Map<String, String>.from(_ChatStateHolder.answers);
    final localizedFields = (data is Map) ? data['localized_fields'] : null;
    if (localizedFields is Map) {
      localizedFields.forEach((key, value) {
        if (key is String && value != null) {
          localizedAnswers[key] = value.toString();
        }
      });
    }

    // update stored answers
    _ChatStateHolder.answers
      ..clear()
      ..addAll(localizedAnswers);

    _addBot(formalSummary);
    _addBot(localizations.classification(classification as String) ??
        'Classification: $classification');

    setState(() {
      _setIsLoading(false);
      _setAllowInput(false);
    });
    
    // STOP ASR when chat completes
    if (_isRecording) {
      print('Chat completed - stopping ASR');
      if (_isAndroid) {
        _nativeSpeech.stopListening();
      } else {
        _speech.stop();
        _speech.cancel();
        _listeningMonitorTimer?.cancel();
      }
      setState(() {
        _isRecording = false;
        _recordingStartTime = null;
      });
    }

    // navigate to details screen
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      context.go(
        '/ai-chatbot-details',
        extra: {
          'answers': Map<String, String>.from(_ChatStateHolder.answers),
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

    // Capture the final message to send BEFORE resetting state
    String finalMessage = '';
    bool wasRecording = _isRecording;
    
    // If recording is active, finalize the current transcript
    if (_isRecording) {
      // Finalize all accumulated text for this message
      if (_currentTranscript.isNotEmpty) {
        if (_finalizedTranscript.isNotEmpty) {
          finalMessage = '$_finalizedTranscript $_currentTranscript'.trim();
        } else {
          finalMessage = _currentTranscript.trim();
        }
      } else {
        finalMessage = _finalizedTranscript.trim();
      }
      
      // Update controller with finalized message
      _controller.text = finalMessage;
    } else {
      // Not recording - use whatever is in the text field
      finalMessage = _controller.text.trim();
    }

    // Validate message
    if (!_allowInput || _isLoading) return;
    
    if (finalMessage.isEmpty) {
      setState(() => _inputError = false);
      _inputFocus.requestFocus();
      return;
    }

    // CRITICAL: Reset ALL ASR state for fresh start on next message
    // This prevents concatenation with previous messages/autofill issues
    if (_isRecording) {
      print('Sending message - restarting ASR to clear buffer');
      
      // Temporarily ignore callbacks to prevent flickering/race conditions
      setState(() {
        _ignoreAsrCallbacks = true;
        _finalizedTranscript = ''; 
        _currentTranscript = '';
        _lastRecognizedText = '';
        _inputError = false;
      });
      _controller.clear();

      try {
        if (_isAndroid) {
          // Android Native ASR: Explicitly stop and restart to clear buffer
          await _nativeSpeech.stopListening();
          // Small delay to ensure engine processes the stop
          await Future.delayed(const Duration(milliseconds: 200));
          
          if (mounted && _isRecording && _currentSttLang != null) {
             await _nativeSpeech.startListening(language: _currentSttLang!);
          }
        } else {
          // iOS/Web: Use existing clean restart helper
          await _restartSpeechRecognitionOnClear();
        }
      } catch (e) {
        print('Error restarting ASR in handleSend: $e');
      }
      
      // Re-enable callbacks
      if (mounted) {
        setState(() {
          _ignoreAsrCallbacks = false;
        });
      }
    } else {
       // Not recording - simple state clear
       setState(() {
        _finalizedTranscript = '';
        _currentTranscript = '';
        _lastRecognizedText = '';
        _inputError = false;
      });
      _controller.clear();
    }
    
    // Add message to chat
    _addUser(finalMessage);

    // Logic: If this is the VERY FIRST user message, it becomes 'initial_details'
    // AND we do NOT add it to history (because backend uses initial_details as context).
    // Subsequent messages are added to history.
    if (_ChatStateHolder.answers['details'] == null ||
        _ChatStateHolder.answers['details']!.isEmpty) {
      _ChatStateHolder.answers['details'] = finalMessage;
      print('📝 First message set as initial_details: "$finalMessage"');
    } else {
      _dynamicHistory.add({'role': 'user', 'content': finalMessage});
      print('📝 Added to history: "$finalMessage"');
      print('📚 Current history length: ${_dynamicHistory.length}');
    }

    _setAllowInput(false);
    setState(() {});

    // Explicitly call backend step
    _processDynamicStep();
    
    // NOTE: Continuous listening continues automatically
    // The monitoring timer will restart if SDK stopped
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
              _isUpdatingFromAsr = true;
              final newWords = result.recognizedWords.trim();
              if (newWords.isEmpty) {
                _isUpdatingFromAsr = false;
                return;
              }
              
              if (result.finalResult) {
                // FINAL RESULT: Merge with finalized transcript
                final merged = mergeAsrWithCurrentText(_finalizedTranscript, newWords);
                _finalizedTranscript = merged;
                _currentTranscript = '';
                _lastRecognizedText = newWords;
                _controller.text = merged;
                print('STT safe restart final (merged): "$newWords" -> "$merged"');
              } else {
                // PARTIAL RESULT: Extract only genuinely new words (not already at end)
                String partialToShow;
                if (_finalizedTranscript.isEmpty) {
                  // No finalized text yet - use ASR text directly
                  partialToShow = newWords;
                } else {
                  // Have finalized text - extract only new words
                  partialToShow = extractNewWordsOnly(_finalizedTranscript, newWords);
                  // If extraction returns empty but ASR has text, use ASR text
                  if (partialToShow.isEmpty && newWords.isNotEmpty) {
                    partialToShow = newWords;
                  }
                }
                
                // Update current transcript
                _currentTranscript = partialToShow;
                _lastRecognizedText = newWords;
                final displayText = _finalizedTranscript.isEmpty
                    ? _currentTranscript
                    : (_currentTranscript.isEmpty 
                        ? _finalizedTranscript 
                        : '$_finalizedTranscript $_currentTranscript');
                _controller.text = displayText.trim();
                print('STT safe restart partial: "$newWords" -> showing "$partialToShow" (finalized: "$_finalizedTranscript", current: "$_currentTranscript")');
              }
              
              _isUpdatingFromAsr = false;
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

  /// Start monitoring timer to detect when SDK stops and trigger restart
  void _startListeningMonitor() {
    // Cancel any existing timer
    _listeningMonitorTimer?.cancel();
    
    // Start periodic timer to check if SDK is still listening
    // Increased interval to 5 seconds to reduce restart frequency and sounds
    _listeningMonitorTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_isRecording) {
        timer.cancel();
        return;
      }
      
      // Check if SDK stopped listening
      if (!_speech.isListening && !_isRestarting) {
        print('Monitor detected SDK stopped - triggering seamless restart...');
        _seamlessRestart();
      }
    });
  }

  /// Seamlessly restart speech recognition without losing accumulated text
  /// Called when SDK stops but user hasn't manually stopped recording
  Future<void> _seamlessRestart() async {
    if (!_isRecording || !mounted || _currentSttLang == null) {
      print('Seamless restart skipped - not recording or no language set');
      return;
    }

    // Prevent multiple simultaneous restarts
    if (_isRestarting) {
      print('Restart already in progress, skipping...');
      return;
    }

    _isRestarting = true;
    print('=== SEAMLESS RESTART INITIATED ===');
    print('Preserving state: finalized="$_finalizedTranscript", current="$_currentTranscript"');

    try {
      // Stop any existing session
      if (_speech.isListening) {
        await _speech.stop();
        await _speech.cancel();
      }

      // Small delay for clean state
      await Future.delayed(const Duration(milliseconds: 200));

      // Double-check we're still recording
      if (!_isRecording || !mounted) {
        _isRestarting = false;
        return;
      }

      // Restart listening with same configuration
      print('Restarting speech recognition...');
      await _speech.listen(
        localeId: _currentSttLang!,
        listenFor: const Duration(hours: 1),
        pauseFor: const Duration(hours: 1),
        partialResults: true,
        cancelOnError: false,
        onResult: (result) {
          if (mounted && _isRecording) {
            setState(() {
              _isUpdatingFromAsr = true;
              final newWords = result.recognizedWords.trim();

              if (newWords.isEmpty) {
                _isUpdatingFromAsr = false;
                return;
              }

              print('onResult (restart): newWords="$newWords", isFinal=${result.finalResult}');
              _lastSpeechDetected = DateTime.now();

              if (result.finalResult) {
                // FINAL RESULT: Merge with finalized transcript
                final merged = mergeAsrWithCurrentText(_finalizedTranscript, newWords);
                _finalizedTranscript = merged;
                _currentTranscript = '';
                _lastRecognizedText = newWords;
                _controller.text = merged;
                print('STT restart final (merged): "$newWords" -> "$merged"');
              } else {
                // PARTIAL RESULT: Extract only genuinely new words (not already at end)
                String partialToShow;
                if (_finalizedTranscript.isEmpty) {
                  // No finalized text yet - use ASR text directly
                  partialToShow = newWords;
                } else {
                  // Have finalized text - extract only new words
                  partialToShow = extractNewWordsOnly(_finalizedTranscript, newWords);
                  // If extraction returns empty but ASR has text, use ASR text
                  if (partialToShow.isEmpty && newWords.isNotEmpty) {
                    partialToShow = newWords;
                  }
                }
                
                // Update current transcript
                _currentTranscript = partialToShow;
                _lastRecognizedText = newWords;
                final displayText = _finalizedTranscript.isEmpty
                    ? _currentTranscript
                    : (_currentTranscript.isEmpty 
                        ? _finalizedTranscript 
                        : '$_finalizedTranscript $_currentTranscript');
                _controller.text = displayText.trim();
                print('STT restart partial: "$newWords" -> showing "$partialToShow" (finalized: "$_finalizedTranscript", current: "$_currentTranscript")');
              }
              
              _isUpdatingFromAsr = false;
            });
          }
        },
      );
      
      // Start monitoring timer to detect when SDK stops
      _startListeningMonitor();

      _busyRetryCount = 0;
      _isRestarting = false;
      print('=== SEAMLESS RESTART COMPLETE ===');
    } catch (e) {
      _isRestarting = false;
      print('Error during seamless restart: $e');
      
      // Retry once after delay
      if (_busyRetryCount < 3 && mounted && _isRecording) {
        _busyRetryCount++;
        Future.delayed(Duration(milliseconds: 1000 * _busyRetryCount), () {
          if (mounted && _isRecording && !_speech.isListening) {
            _seamlessRestart();
          }
        });
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
    // Map 'te' to 'te-IN', 'en' to 'en-US' (Android uses hyphen format)
    String sttLang = langCode == 'te' ? 'te-IN' : 'en-US';

    if (_isRecording) {
      // Stop recording manually
      if (_isAndroid) {
        // Use native recognizer on Android
        await _nativeSpeech.stopListening();
      } else {
        // Use speech_to_text on iOS
        _listeningMonitorTimer?.cancel();
        _listeningMonitorTimer = null;
        await _speech.stop();
        await _speech.cancel();
      }

      // Unmute system sounds after stopping
      await _unmuteSystemSounds();

      // USER EXPLICITLY STOPPED MICROPHONE - Finalize all accumulated text
      final wasManuallyCleared = _controller.text.isEmpty;

      setState(() {
        if (!wasManuallyCleared) {
          // Finalize transcript if not manually cleared
          if (_currentTranscript.isNotEmpty) {
            if (_finalizedTranscript.isNotEmpty) {
              _finalizedTranscript =
                  '$_finalizedTranscript $_currentTranscript'.trim();
            } else {
              _finalizedTranscript = _currentTranscript;
            }
          }
          _controller.text = _finalizedTranscript;
        } else {
          _finalizedTranscript = '';
          _controller.text = '';
        }
        _currentTranscript = '';
        _isRecording = false;
        _recordingStartTime = null;
        _currentSttLang = null;
      });
    } else {
      // Start recording - ensure clean state
      await _flutterTts.stop();

      if (_isAndroid) {
        // Use Android Native SpeechRecognizer
        print('Starting Android Native SpeechRecognizer...');
        
        // Mute system sounds to prevent restart sounds
        await _muteSystemSounds();
        
        setState(() {
          _isRecording = true;
          _currentSttLang = sttLang;
          _currentTranscript = '';
          _lastRecognizedText = '';
          _recordingStartTime = DateTime.now();
        });

        try {
          await _nativeSpeech.startListening(language: sttLang);
          print('Native ASR started successfully');
        } catch (e) {
          print('Error starting native ASR: $e');
          await _unmuteSystemSounds(); // Unmute on error
          setState(() {
            _isRecording = false;
            _recordingStartTime = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting speech recognition: $e')),
          );
        }
      } else {
        // Use speech_to_text on iOS
        await _speech.stop();
        await _speech.cancel();
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
            return;
          }

          // For other errors, only stop on truly critical errors
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
                  _seamlessRestart();
                }
              });
            }
          }
        },
      );

      if (available) {
        setState(() {
          _isRecording = true;
          _currentSttLang =
              sttLang; // Store language for potential restart on clear
          // Start fresh - TRUE continuous mode
          _currentTranscript = ''; // Start fresh for streaming
          _lastRecognizedText = ''; // Reset for text comparison
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
                  _isUpdatingFromAsr = true;
                  final newWords = result.recognizedWords.trim();

                  if (newWords.isEmpty) {
                    _isUpdatingFromAsr = false;
                    return;
                  }

                  print('onResult: newWords="$newWords", isFinal=${result.finalResult}');
                  _lastSpeechDetected = DateTime.now();

                  if (result.finalResult) {
                    // FINAL RESULT: Merge with finalized transcript
                    final merged = mergeAsrWithCurrentText(_finalizedTranscript, newWords);
                    _finalizedTranscript = merged;
                    _currentTranscript = '';
                    _lastRecognizedText = newWords;
                    _controller.text = merged;
                    print('STT final result (merged): "$newWords" -> "$merged"');
                  } else {
                    // PARTIAL RESULT: Extract only genuinely new words (not already at end)
                    String partialToShow;
                    if (_finalizedTranscript.isEmpty) {
                      // No finalized text yet - use ASR text directly
                      partialToShow = newWords;
                    } else {
                      // Have finalized text - extract only new words
                      partialToShow = extractNewWordsOnly(_finalizedTranscript, newWords);
                      // If extraction returns empty but ASR has text, use ASR text
                      // (this handles cases where ASR doesn't start with finalized)
                      if (partialToShow.isEmpty && newWords.isNotEmpty) {
                        partialToShow = newWords;
                      }
                    }
                    
                    // Update current transcript
                    _currentTranscript = partialToShow;
                    _lastRecognizedText = newWords;
                    // Display: finalized + current partial
                    final displayText = _finalizedTranscript.isEmpty
                        ? _currentTranscript
                        : (_currentTranscript.isEmpty 
                            ? _finalizedTranscript 
                            : '$_finalizedTranscript $_currentTranscript');
                    _controller.text = displayText.trim();
                    print('STT partial result: "$newWords" -> showing "$partialToShow" (finalized: "$_finalizedTranscript", current: "$_currentTranscript")');
                  }
                  
                  _isUpdatingFromAsr = false;
                });
              }
            },
          );
          
          // Start monitoring timer to detect when SDK stops
          _startListeningMonitor();
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
          await _unmuteSystemSounds();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Speech recognition not available. Please check if your device supports it.'),
            ),
          );
        }
      } // Close iOS else branch
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
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Use same logic as back button
              final canPop = await _onWillPop();
              if (canPop) {
                context.go('/dashboard');
              }
            },
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
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(orange),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "AI is thinking...",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      ), // Close Scaffold
    ); // Close WillPopScope
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