import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// ANPR Detection Tab
class AnprDetectionTab extends StatefulWidget {
  const AnprDetectionTab({super.key});

  @override
  State<AnprDetectionTab> createState() => _AnprDetectionTabState();
}

class _AnprDetectionTabState extends State<AnprDetectionTab> {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedFile;
  bool _isLoading = false;
  Map<String, dynamic>? _detectionResult;
  String? _errorMessage;
  bool _isVideo = false;
  final Dio _dio = Dio();

  String _baseUrl = '';
  bool _isInitialized = false;

  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initBackend();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initBackend() async {
    if (_isInitialized) return;

    // Prefer local FastAPI backend on port 8000.
    final List<String> candidates = <String>['http://localhost:8000'];

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      candidates.add('http://10.0.2.2:8000');
    }

    // Try to find a healthy backend
    String? resolved;
    for (final base in candidates) {
      if (await _isBackendHealthy(base)) {
        resolved = base;
        break;
      }
    }

    // Fallback to localhost:8000 if none are healthy
    resolved ??= 'http://localhost:8000';
    _baseUrl = resolved;
    _isInitialized = true;
  }

  Future<bool> _isBackendHealthy(String base) async {
    // Only consider API health endpoints, not bare '/'.
    final paths = ['/api/anpr/health', '/api/health'];
    for (final p in paths) {
      try {
        final resp = await _dio.get(
          '$base$p',
          options: Options(
            receiveTimeout: const Duration(seconds: 3),
            sendTimeout: const Duration(seconds: 3),
            validateStatus: (_) => true,
          ),
        );
        if (resp.statusCode != null &&
            resp.statusCode! >= 200 &&
            resp.statusCode! < 400) {
          return true;
        }
      } catch (_) {
        // Continue to next path
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ANPR Detection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Detect and read vehicle number plates from images or videos. For videos, processes every 10th frame for faster detection.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text('Upload Image or Video',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => _showFileSourceDialog(isImage: true),
                          icon: const Icon(Icons.image_outlined,
                              color: Colors.black54),
                          label: const Text('Select Image',
                              style: TextStyle(color: Colors.black87)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              _showFileSourceDialog(isImage: false),
                          icon: const Icon(Icons.video_library_outlined,
                              color: Colors.black54),
                          label: const Text('Select Video',
                              style: TextStyle(color: Colors.black87)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(_isVideo ? Icons.video_file : Icons.image,
                          color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          style: TextStyle(
                            color: Colors.green[900],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _detectionResult = null;
                            _errorMessage = null;
                            _isVideo = false;
                            _videoPlayerController?.dispose();
                            _chewieController?.dispose();
                            _videoPlayerController = null;
                            _chewieController = null;
                          });
                        },
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                if (!_isVideo) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                            _selectedFile!.path,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_selectedFile!.path),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    _isLoading || _selectedFile == null ? null : _runDetection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9096F6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Detecting...'),
                        ],
                      )
                    : const Text('Detect Number Plates'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style:
                              TextStyle(color: Colors.red[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_detectionResult != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Detection Results',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_detectionResult!['type'] == 'image') ...[
                  _buildImageResults(),
                ] else if (_detectionResult!['type'] == 'video') ...[
                  _buildVideoResults(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageResults() {
    final plates = _detectionResult!['plates'] as List? ?? [];
    final count = _detectionResult!['count'] ?? 0;

    if (count == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No license plates detected in the image.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Detected $count plate${count > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.blue[900],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Display Processed Image
        if (_detectionResult!['image'] != null) ...[
          const Text(
            'Processed Image',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(_detectionResult!['image']),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text('Failed to load processed image'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Display Details List
        const Text(
          'Detailed Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...plates.asMap().entries.map((entry) {
          final index = entry.key;
          final plate = entry.value as Map<String, dynamic>;
          return _buildPlateCard(index + 1, plate);
        }),
      ],
    );
  }

  Widget _buildVideoResults() {
    final uniquePlates = _detectionResult!['unique_plates'] as List? ?? [];
    final processedFrames = _detectionResult!['processed_frames'] ?? 0;
    final totalFrames = _detectionResult!['total_frames'] ?? 0;
    final videoUrl = _detectionResult!['video_url'];

    // Initialize video player if we have a URL and haven't initialized yet
    if (videoUrl != null && _videoPlayerController == null) {
      // Construct full URL
      final fullUrl = '$_baseUrl$videoUrl';
      debugPrint('Video URL from backend: $videoUrl');
      debugPrint('Full Video URL: $fullUrl');
      
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(fullUrl));
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: true,
        autoInitialize: true,
        aspectRatio: 16 / 9,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error playing video: $errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
          );
        },
      );
    }

    if (uniquePlates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No license plates detected in the video.\nProcessed $processedFrames of $totalFrames frames.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_chewieController != null) ...[
             Container(
               height: 250,
               decoration: BoxDecoration(
                 color: Colors.black,
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Chewie(controller: _chewieController!),
             ),
             const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Detected ${uniquePlates.length} unique plate${uniquePlates.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Processed $processedFrames of $totalFrames frames',
                style: TextStyle(color: Colors.blue[700], fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...uniquePlates.asMap().entries.map((entry) {
          final index = entry.key;
          final plate = entry.value as Map<String, dynamic>;
          return _buildVideoPlateCard(index + 1, plate);
        }),
      ],
    );
  }

  Widget _buildPlateCard(int index, Map<String, dynamic> plate) {
    final text = plate['text'] ?? 'Unknown';
    final confidence = plate['confidence'] ?? 0.0;
    final textScore = plate['text_score'] ?? 0.0;
    final bbox = plate['bbox'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Plate $index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (bbox.isNotEmpty)
            Text(
              'Position: [${bbox[0]}, ${bbox[1]}, ${bbox[2]}, ${bbox[3]}]',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Detection: ${(confidence * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              Text(
                'OCR: ${(textScore * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlateCard(int index, Map<String, dynamic> plate) {
    final text = plate['text'] ?? 'Unknown';
    final detections = plate['detections'] as List? ?? [];
    final firstSeen = plate['first_seen_timestamp'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Plate $index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'First seen at: ${firstSeen.toStringAsFixed(2)}s',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Detected in ${detections.length} frame${detections.length > 1 ? 's' : ''}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _showFileSourceDialog({required bool isImage}) async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isImage ? 'Select Image Source' : 'Select Video Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    Icon(isImage ? Icons.photo_library : Icons.video_library),
                title: Text(isImage ? 'Gallery' : 'Video Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  if (isImage) {
                    _pickImage(ImageSource.gallery);
                  } else {
                    _pickVideo(ImageSource.gallery);
                  }
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: Icon(isImage ? Icons.camera_alt : Icons.videocam),
                  title: Text(isImage ? 'Camera' : 'Video Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    if (isImage) {
                      _pickImage(ImageSource.camera);
                    } else {
                      _pickVideo(ImageSource.camera);
                    }
                  },
                ),
            ],
          ),
        ),
      );
    } else {
      if (isImage) {
        _pickImage(ImageSource.gallery);
      } else {
        _pickVideo(ImageSource.gallery);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedFile = pickedFile;
          _isVideo = false;
          _detectionResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10),
      );

      if (pickedFile != null) {
        setState(() {
          _selectedFile = pickedFile;
          _isVideo = true;
          _detectionResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runDetection() async {
    if (!_isInitialized) {
      await _initBackend();
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _detectionResult = null;
    });

    try {
      final bytes = await _selectedFile!.readAsBytes();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: _selectedFile!.name,
        ),
        'frame_skip': 10, // Skip 10 frames for video processing
      });

      final response = await _dio.post(
        '$_baseUrl/api/anpr/detect',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(minutes: 5),
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _isLoading = false;
          _detectionResult = response.data;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(_detectionResult!['message'] ?? 'Detection completed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      String errorMessage = 'Unknown error occurred';

      if (e is DioException) {
        if (e.response != null) {
          final statusCode = e.response!.statusCode;
          final errorData = e.response!.data;

          if (errorData is Map && errorData['detail'] != null) {
            errorMessage = errorData['detail'].toString();
          } else {
            errorMessage =
                'Server error (${statusCode}): ${e.response!.statusMessage ?? 'Unknown error'}';
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout) {
          errorMessage = 'Request timeout. Please try again.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage =
              'Connection error. Please check your internet connection.';
        } else {
          errorMessage = 'Network error: ${e.message ?? e.toString()}';
        }
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        errorMessage =
            'Connection error. Please check your internet connection.';
      } else {
        errorMessage =
            'Error detecting plates: ${e.toString().split('\n').first}';
      }

      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
