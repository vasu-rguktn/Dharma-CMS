import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Video Enhancement Tab
class VideoEnhancementTab extends StatefulWidget {
  const VideoEnhancementTab({super.key});

  @override
  State<VideoEnhancementTab> createState() => _VideoEnhancementTabState();
}

class _VideoEnhancementTabState extends State<VideoEnhancementTab> {
  // Toggles
  bool _deblur = false;
  bool _denoise = false;
  bool _lowLight = false;
  bool _sharpen = false;
  bool _stabilize = false;
  bool _contrast = false;
  String? _upscalePreset = 'None';
  String? _upscaleMethod = 'cubic';

  // Video and state
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedVideo;
  bool _isLoading = false;
  String? _enhancedVideoPath;
  String? _errorMessage;
  Map<String, dynamic>? _enhancementResult;
  final Dio _dio = Dio();

  String _baseUrl = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize backend URL detection in background
    _initBackend();
  }

  Future<void> _initBackend() async {
    if (_isInitialized) return;

    // Prefer local FastAPI backend on port 8000.
    final List<String> candidates = <String>['http://localhost:8000'];

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      // For Android emulator, use 10.0.2.2 to access host machine's localhost
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
    // Only treat a backend as healthy if API health endpoints respond.
    final paths = [
      '/api/video-enhancement/health',
      '/api/health',
    ];
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
                'Video Enhancement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Improve video quality with AI-powered enhancement: upscale resolution, denoise, deblur, and more.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text('Upload Video',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Center(
                  child: TextButton.icon(
                    onPressed: _showVideoSourceDialog,
                    icon: const Icon(Icons.cloud_upload_outlined,
                        color: Colors.black54),
                    label: const Text('Select Video',
                        style: TextStyle(color: Colors.black87)),
                  ),
                ),
              ),
              if (_selectedVideo != null) ...[
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
                      Icon(Icons.check_circle,
                          color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedVideo!.name,
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
                            _selectedVideo = null;
                            _enhancedVideoPath = null;
                            _enhancementResult = null;
                            _errorMessage = null;
                          });
                        },
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text('Enhancement Options',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildToggle('Deblur', _deblur,
                            (v) => setState(() => _deblur = v)),
                        _buildToggle('Low-light Boost', _lowLight,
                            (v) => setState(() => _lowLight = v)),
                        _buildToggle('Sharpen', _sharpen,
                            (v) => setState(() => _sharpen = v)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildToggle('Denoise', _denoise,
                            (v) => setState(() => _denoise = v)),
                        _buildToggle('Stabilize', _stabilize,
                            (v) => setState(() => _stabilize = v)),
                        _buildToggle('Contrast', _contrast,
                            (v) => setState(() => _contrast = v)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Upscale Resolution',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _upscalePreset,
                    isExpanded: true,
                    items: ['None', '360p', '480p', '720p', '1080p', '2k', '4k']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _upscalePreset = v),
                  ),
                ),
              ),
              if (_upscalePreset != 'None') ...[
                const SizedBox(height: 16),
                const Text('Upscale Method',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _upscaleMethod,
                      isExpanded: true,
                      items: ['cubic', 'lanczos', 'linear', 'nearest']
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _upscaleMethod = v),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _runEnhancement,
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
                          Text('Processing...'),
                        ],
                      )
                    : const Text('Run Enhancement'),
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
              if (_enhancementResult != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Enhancement Results',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResultRow(
                          'Status', _enhancementResult!['status'] ?? 'N/A'),
                      if (_enhancementResult!['original_resolution'] != null)
                        _buildResultRow('Original Resolution',
                            _enhancementResult!['original_resolution']),
                      if (_enhancementResult!['final_resolution'] != null)
                        _buildResultRow('Final Resolution',
                            _enhancementResult!['final_resolution']),
                      if (_enhancementResult!['frame_count'] != null)
                        _buildResultRow('Frames Processed',
                            _enhancementResult!['frame_count'].toString()),
                      if (_enhancementResult!['enhancements_applied'] != null)
                        _buildResultRow(
                            'Enhancements Applied',
                            (_enhancementResult!['enhancements_applied']
                                    as List)
                                .join(', ')),
                    ],
                  ),
                ),
                if (_enhancedVideoPath != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.video_file,
                            color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Enhanced video ready',
                            style: TextStyle(
                              color: Colors.green[900],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Open video URL or download
                            if (_enhancedVideoPath!.startsWith('http')) {
                              // For web, open in new tab
                              // For mobile, you might want to download or open in video player
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Video URL: $_enhancedVideoPath'),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          },
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.deepPurple,
        ),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Future<void> _showVideoSourceDialog() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Video Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo(ImageSource.camera);
                  },
                ),
            ],
          ),
        ),
      );
    } else {
      // For desktop, just use gallery
      _pickVideo(ImageSource.gallery);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10), // Limit to 10 minutes
      );

      if (pickedFile != null) {
        setState(() {
          _selectedVideo = pickedFile;
          _enhancedVideoPath = null;
          _enhancementResult = null;
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

  Future<void> _runEnhancement() async {
    // Initialize backend URL if not already done
    if (!_isInitialized) {
      await _initBackend();
    }

    // Validate that at least one enhancement is selected
    if (!_deblur &&
        !_denoise &&
        !_lowLight &&
        !_sharpen &&
        !_stabilize &&
        !_contrast &&
        _upscalePreset == 'None') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one enhancement option'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _enhancedVideoPath = null;
      _enhancementResult = null;
    });

    try {
      // Read video file
      final bytes = await _selectedVideo!.readAsBytes();

      // Create FormData
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: _selectedVideo!.name,
        ),
        'denoise': _denoise,
        'deblur': _deblur,
        'sharpen': _sharpen,
        'low_light': _lowLight,
        'stabilize': _stabilize,
        'contrast': _contrast,
        'upscale': _upscalePreset != 'None',
        if (_upscalePreset != 'None')
          'upscale_preset': _upscalePreset!.toLowerCase(),
        'upscale_method': _upscaleMethod,
        'output_format': 'mp4',
      });

      // Make API call
      final response = await _dio.post(
        '$_baseUrl/api/video-enhancement/enhance',
        data: formData,
        options: Options(
          receiveTimeout:
              const Duration(minutes: 10), // Video processing can take time
          sendTimeout: const Duration(minutes: 2),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        String? outputPath = data['output_path'];

        // Construct full URL if it's a relative path
        if (outputPath != null && !outputPath.startsWith('http')) {
          // Remove leading slash if present
          if (outputPath.startsWith('/')) {
            outputPath = outputPath.substring(1);
          }
          outputPath = '$_baseUrl/$outputPath';
        }

        setState(() {
          _isLoading = false;
          _enhancedVideoPath = outputPath;
          _enhancementResult = data;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video enhanced successfully!'),
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
        // Handle Dio-specific errors
        if (e.response != null) {
          // Server responded with error status
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
          errorMessage =
              'Request timeout. Video processing may take longer. Please try again.';
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
            'Error enhancing video: ${e.toString().split('\n').first}';
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
