import 'dart:async';
import 'dart:convert';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling Speech-to-Text functionality
/// Connects to backend WebSocket endpoint and streams audio for transcription
class SttService {
  final AudioRecorder _recorder = AudioRecorder();
  WebSocketChannel? _channel;
  final StreamController<SttResult> _transcriptController = 
      StreamController<SttResult>.broadcast();
  
  bool _isRecording = false;
  final String _baseUrl;
  String _lastTranscript = '';  // Store last transcript
  
  SttService(this._baseUrl);
  
  /// Stream of transcription results
  Stream<SttResult> get transcriptStream => _transcriptController.stream;
  
  /// Whether currently recording
  bool get isRecording => _isRecording;
  
  /// Get the last received transcript
  String get lastTranscript => _lastTranscript;
  
  /// Request microphone permission from user
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  /// Start recording and streaming audio to backend
  Future<void> startRecording(String languageCode) async {
    if (_isRecording) return;
    
    // Request permission
    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }
    
    // Connect to WebSocket
    final wsUrl = _baseUrl.replaceFirst('http', 'ws');
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/stt?lang=$languageCode'),
      );
      
      // Listen to transcripts from backend
      _channel!.stream.listen(
        (data) {
          try {
            print('Received from WebSocket: $data (type: ${data.runtimeType})');
            
            // Handle both String and Map responses
            dynamic json;
            if (data is String) {
              json = jsonDecode(data);
            } else if (data is Map) {
              json = data;
            } else {
              print('Unknown data type: ${data.runtimeType}');
              return;
            }
            
            print('Parsed JSON: $json');
            
            if (json.containsKey('error')) {
              print('Error from backend: ${json['error']}');
              _transcriptController.addError(json['error']);
            } else if (json.containsKey('transcript')) {
              final result = SttResult(
                transcript: json['transcript'] ?? '',
                isFinal: json['is_final'] ?? false,
                confidence: (json['confidence'] ?? 0.0).toDouble(),
              );
              _lastTranscript = result.transcript;  // Store last transcript
              print('Adding transcript: ${result.transcript} (final: ${result.isFinal})');
              _transcriptController.add(result);
            } else {
              print('JSON missing transcript key: $json');
            }
          } catch (e, stackTrace) {
            print('Error parsing STT response: $e');
            print('Stack trace: $stackTrace');
            print('Raw data: $data');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _transcriptController.addError(error);
        },
        onDone: () {
          print('WebSocket closed');
        },
      );
    } catch (e) {
      throw Exception('Failed to connect to STT service: $e');
    }
    
    // Start recording
    if (await _recorder.hasPermission()) {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      
      _isRecording = true;
      
      // Stream audio chunks to backend
      stream.listen(
        (chunk) {
          if (_channel != null && _isRecording) {
            try {
              _channel!.sink.add(chunk);
            } catch (e) {
              print('Error sending audio chunk: $e');
            }
          }
        },
        onError: (error) {
          print('Recording error: $error');
          stopRecording();
        },
      );
    } else {
      throw Exception('Microphone permission not granted');
    }
  }
  
  /// Stop recording and close connection
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    _isRecording = false;
    
    try {
      // Stop recording first
      await _recorder.stop();
      
      // Wait a bit for any final transcripts to arrive
      print('Waiting for final transcripts...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Close WebSocket
      _channel?.sink.close();
      print('WebSocket closed');
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _recorder.dispose();
    _channel?.sink.close();
    _transcriptController.close();
  }
}

/// Result from STT service containing transcript and metadata
class SttResult {
  final String transcript;
  final bool isFinal;
  final double confidence;
  
  SttResult({
    required this.transcript,
    required this.isFinal,
    required this.confidence,
  });
}
