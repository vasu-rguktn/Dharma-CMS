import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';

/// Flutter wrapper for Android Native SpeechRecognizer
/// Falls back to speech_to_text package on iOS
class NativeSpeechRecognizer {
  static const MethodChannel _channel = MethodChannel('com.dharma.native_asr');
  
  // Callbacks
  Function(String text)? onPartialResult;
  Function(String text)? onFinalResult;
  Function(String error, String message)? onError;
  Function()? onListeningStarted;
  Function()? onListeningStopped;
  
  bool _isListening = false;
  bool _isInitialized = false;
  
  /// Initialize the native speech recognizer
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Set up method call handler for callbacks from native code
    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
  }
  
  /// Start listening for speech
  Future<void> startListening({required String language}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError('NativeSpeechRecognizer is only supported on Android');
    }
    
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _channel.invokeMethod('startListening', {
        'language': language,
      });
      _isListening = true;
    } catch (e) {
      // print('Error starting native speech recognizer: $e');
      rethrow;
    }
  }
  
  /// Stop listening for speech
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _channel.invokeMethod('stopListening');
      _isListening = false;
    } catch (e) {
      // print('Error stopping native speech recognizer: $e');
      rethrow;
    }
  }
  
  /// Check if currently listening
  bool get isListening => _isListening;
  
  /// Handle method calls from native code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPartialResult':
        final text = call.arguments['text'] as String?;
        if (text != null && onPartialResult != null) {
          onPartialResult!(text);
        }
        break;
        
      case 'onFinalResult':
        final text = call.arguments['text'] as String?;
        if (text != null && onFinalResult != null) {
          onFinalResult!(text);
        }
        break;
        
      case 'onError':
        final error = call.arguments['error'] as String? ?? 'UNKNOWN_ERROR';
        final message = call.arguments['message'] as String? ?? 'Unknown error occurred';
        if (onError != null) {
          onError!(error, message);
        }
        break;
        
      case 'onListeningStarted':
        _isListening = true;
        if (onListeningStarted != null) {
          onListeningStarted!();
        }
        break;
        
      case 'onListeningStopped':
        _isListening = false;
        if (onListeningStopped != null) {
          onListeningStopped!();
        }
        break;
        
      default:
        // print('Unknown method call from native: ${call.method}');
    }
  }
  
  /// Clean up resources
  void dispose() {
    if (_isListening) {
      stopListening();
    }
  }
}
