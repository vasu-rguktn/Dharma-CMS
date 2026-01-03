import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'anpr_detection_tab.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageLabScreen extends StatefulWidget {
  const ImageLabScreen({super.key});

  @override
  State<ImageLabScreen> createState() => _ImageLabScreenState();
}

class _ImageLabScreenState extends State<ImageLabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color orange = const Color(0xFFFC633C);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: orange),
          onPressed: () => context.go('/police-dashboard'),
        ),
        title: Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.indigo, size: 28),
            const SizedBox(width: 12),
            const Text(
              'Image Lab',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(140), // Increased height for description
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'AI-powered tools for generating, enhancing, and analyzing visual evidence. All outputs are watermarked for investigative use only.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.deepPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepPurple,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(
                      text: 'Image Enhancement',
                      icon: Icon(Icons.auto_fix_high)),
                  Tab(text: 'ANPR Detection', icon: Icon(Icons.directions_car)),
                  Tab(text: 'Face Capture', icon: Icon(Icons.camera_front)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: const [
            ImageEnhancementTab(),
            AnprDetectionTab(),
            FaceCaptureTab(),
          ],
        ),
      ),
    );
  }
}

// ───────────────── TABS ─────────────────



// 2. Image Enhancement
class ImageEnhancementTab extends StatefulWidget {
  const ImageEnhancementTab({super.key});

  @override
  State<ImageEnhancementTab> createState() => _ImageEnhancementTabState();
}

class _ImageEnhancementTabState extends State<ImageEnhancementTab> {
  // Toggles
  bool _deblur = false;
  bool _denoise = false;
  bool _lowLight = false;
  bool _colorize = false;
  bool _sharpen = false;
  String? _upscaleFactor = 'None';

  // Image and state
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  bool _isLoading = false;
  String? _enhancedImagePath;
  String? _enhancedImageBase64;
  String? _errorMessage;
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
    final List<String> candidates = <String>['https://fastapi-app-335340524683.asia-south1.run.app'];

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      // For Android emulator, use 10.0.2.2 to access host machine's localhost
      candidates.add('https://fastapi-app-335340524683.asia-south1.run.app');
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
    resolved ??= 'https://fastapi-app-335340524683.asia-south1.run.app';

    _baseUrl = resolved;
    _isInitialized = true;
  }

  Future<bool> _isBackendHealthy(String base) async {
    // Only treat a backend as healthy if API health endpoints respond.
    final paths = [
      '/api/image-enhancement/health',
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
                'Image Enhancement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Improve the quality of an image using AI enhancement tools.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text('Upload Image',
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
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.cloud_upload_outlined,
                        color: Colors.black54),
                    label: const Text('Select Image',
                        style: TextStyle(color: Colors.black87)),
                  ),
                ),
              ),
              if (_selectedImage != null) ...[
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
                          _selectedImage!.name,
                          style: TextStyle(
                            color: Colors.green[900],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.network(
                          _selectedImage!.path,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_selectedImage!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
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
                        _buildToggle('Colorize', _colorize,
                            (v) => setState(() => _colorize = v)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Upscale Factor',
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
                    value: _upscaleFactor,
                    isExpanded: true,
                    items: ['None', '2x', '4x', '8x']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _upscaleFactor = v),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _runEnhancement,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF9096F6), // Slightly lighter purple
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
              if (_enhancedImageBase64 != null ||
                  _enhancedImagePath != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Enhanced Image',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _enhancedImageBase64 != null
                      ? Image.memory(
                          base64Decode(_enhancedImageBase64!),
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        )
                      : _enhancedImagePath != null
                          ? kIsWeb
                              ? Image.network(
                                  _enhancedImagePath!,
                                  height: 300,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                )
                              : Image.file(
                                  File(_enhancedImagePath!),
                                  height: 300,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                )
                          : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
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

  Future<void> _showImageSourceDialog() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
            ],
          ),
        ),
      );
    } else {
      // For desktop, just use gallery
      _pickImage(ImageSource.gallery);
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
          _selectedImage = pickedFile;
          _enhancedImagePath = null;
          _enhancedImageBase64 = null;
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

  Future<void> _runEnhancement() async {
    // Initialize backend URL if not already done
    if (!_isInitialized) {
      await _initBackend();
    }

    // Validate that at least one enhancement is selected
    if (!_deblur &&
        !_denoise &&
        !_lowLight &&
        !_colorize &&
        !_sharpen &&
        _upscaleFactor == 'None') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one enhancement option'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _enhancedImagePath = null;
      _enhancedImageBase64 = null;
    });

    try {
      // Read image file
      final bytes = await _selectedImage!.readAsBytes();

      // Create FormData
      // Dio will automatically set Content-Type based on filename
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: _selectedImage!.name,
        ),
        'denoise': _denoise,
        'deblur': _deblur,
        'colorize': _colorize,
        'sharpen': _sharpen,
        'low_light': _lowLight,
        'upscale': _upscaleFactor != 'None',
        'upscale_factor': _upscaleFactor == 'None'
            ? 2.0
            : _upscaleFactor == '2x'
                ? 2.0
                : _upscaleFactor == '4x'
                    ? 4.0
                    : 8.0,
        'return_base64': true, // Request base64 for easier display
      });

      // Make API call
      // Note: Don't set Content-Type manually - Dio will set it automatically with boundary
      final response = await _dio.post(
        '$_baseUrl/api/image-enhancement/enhance',
        data: formData,
        options: Options(
            // Dio automatically sets Content-Type for FormData with proper boundary
            // Manually setting it breaks the request
            ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        setState(() {
          _isLoading = false;
          if (data['image_base64'] != null) {
            // Remove data URI prefix if present
            String base64String = data['image_base64'];
            if (base64String.contains(',')) {
              base64String = base64String.split(',').last;
            }
            _enhancedImageBase64 = base64String;
          } else if (data['output_path'] != null) {
            _enhancedImagePath = data['output_path'];
            // If it's a relative path, prepend base URL
            if (!_enhancedImagePath!.startsWith('http')) {
              _enhancedImagePath = '$_baseUrl/$_enhancedImagePath';
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image enhanced successfully!'),
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
            'Error enhancing image: ${e.toString().split('\n').first}';
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

// 3. Video Enhancement - Now imported from video_enhancement_tab.dart

// 4. ANPR Detection - Now imported from anpr_detection_tab.dart

// 5. Face Capture
class FaceCaptureTab extends StatefulWidget {
  const FaceCaptureTab({super.key});

  @override
  State<FaceCaptureTab> createState() => _FaceCaptureTabState();
}

class _FaceCaptureTabState extends State<FaceCaptureTab> {
  final TextEditingController _frameSkipController =
      TextEditingController(text: '10');
  
  // State
  XFile? _selectedFile;
  bool _isVideo = false;
  bool _isLoading = false;
  Map<String, dynamic>? _resultStats;
  String? _sessionId;
  String? _errorMessage;
  
  final Dio _dio = Dio();
  String _baseUrl = ''; // Will be resolved dynamically
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initBackend();
  }

  Future<void> _initBackend() async {
    if (_isInitialized) return;

    // Hardcode to localhost for local development as requested
    // This prevents accidental fallback to the cloud URL which might be outdated
    const String localUrl = 'http://127.0.0.1:8000';
    
    print("Forcing backend URL to: $localUrl");

    setState(() {
      _baseUrl = localUrl;
      _isInitialized = true;
    });
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
                'Face Detection & Capture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Detect and crop faces from an image or video file.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text('Upload Image or Video',
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
                    child: _selectedFile == null
                        ? TextButton.icon(
                            onPressed: _showSourceDialog,
                            icon: const Icon(Icons.cloud_upload_outlined,
                                color: Colors.black54),
                            label: const Text('Select File',
                                style: TextStyle(color: Colors.black87)),
                          )
                        : Column(
                            children: [
                              Icon(
                                _isVideo ? Icons.videocam : Icons.image,
                                size: 40,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedFile!.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: _showSourceDialog,
                                child: const Text('Change File'),
                              )
                            ],
                          )),
              ),
              const SizedBox(height: 20),
              if (_isVideo) ...[
                 const Text('Frame Skip (Video Only)',
                     style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                 const SizedBox(height: 6),
                 TextField(
                   controller: _frameSkipController,
                   keyboardType: TextInputType.number,
                   decoration: InputDecoration(
                     helperText: "Process every Nth frame (higher = faster)",
                     border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8),
                         borderSide: BorderSide(color: Colors.grey[300]!)),
                     filled: true,
                     fillColor: Colors.grey[50],
                   ),
                 ),
                 const SizedBox(height: 20),
              ],
              
              ElevatedButton(
                onPressed: _isLoading ? null : _processFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9096F6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Start Detection'),
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],

              if (_resultStats != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Results',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildStatItem("New Faces Saved", "${_resultStats!['new_persons_saved']}"),
                if (_resultStats!.containsKey('processed_frames'))
                   _buildStatItem("Processed Frames", "${_resultStats!['processed_frames']}"),
                if (_resultStats!.containsKey('total_detections'))
                   _buildStatItem("Total Detections", "${_resultStats!['total_detections']}"),
                
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                
                // Annotated Image Display
                if (_resultStats!['annotated_image'] != null) ...[
                   const Text(
                     "Detected Faces",
                     style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 12),
                   ClipRRect(
                     borderRadius: BorderRadius.circular(8),
                     child: Image.network(
                       '$_baseUrl/static/persons/${_resultStats!['annotated_image']}',
                       fit: BoxFit.contain,
                       errorBuilder: (context, error, stackTrace) =>
                           Container(color: Colors.grey[200], child: const Icon(Icons.error)),
                     ),
                   ),
                   const SizedBox(height: 24),
                ],

                if (_sessionId != null)
                  ElevatedButton.icon(
                    onPressed: _downloadResults,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Detected Faces (ZIP)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select File Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(bool isVideo) async {
    final ImagePicker picker = ImagePicker();
    XFile? file;
    
    try {
      if (isVideo) {
        file = await picker.pickVideo(source: ImageSource.gallery);
      } else {
        file = await picker.pickImage(source: ImageSource.gallery);
      }
      
      if (file != null) {
        setState(() {
          _selectedFile = file;
          _isVideo = isVideo;
          _resultStats = null;
          _sessionId = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking file: $e")));
      }
    }
  }

  Future<void> _processFile() async {
    if (_selectedFile == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultStats = null;
      _sessionId = null;
    });

    print("Processing file: ${_selectedFile!.name}, isVideo: $_isVideo");
    print("Using Backend URL: $_baseUrl");

    try {
      if (!_isInitialized) await _initBackend();

      // Read bytes into memory (caution with large videos on mobile devices)
      // For very large videos, streaming via file path is preferred if Dio supports it on that platform
      final bytes = await _selectedFile!.readAsBytes();
      print("File read into memory, size: ${bytes.length} bytes");

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: _selectedFile!.name),
        'is_video': _isVideo,
        'frame_skip': int.tryParse(_frameSkipController.text) ?? 10
      });

      print("Sending request to $_baseUrl/api/person/detect");
      
      final response = await _dio.post(
        '$_baseUrl/api/person/detect',
        data: formData,
        onSendProgress: (count, total) {
           print("Upload progress: $count / $total");
        },
      );
      
      print("Response status: ${response.statusCode}");
      print("Response data: ${response.data}");

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        setState(() {
          _resultStats = response.data;
          _sessionId = response.data['session_id'];
        });
      } else {
        setState(() {
          _errorMessage = response.data['message'] ?? 'Server returned error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print("Exception during processing: $e");
      String msg = 'Error processing file: $e';
      if (e is DioException) {
         msg = 'Network Error: ${e.message}';
         if (e.response != null) {
           msg += ' (Status: ${e.response?.statusCode}, Data: ${e.response?.data})';
         }
      }
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadResults() async {
    if (_sessionId == null) return;
    
    final url = '$_baseUrl/api/person/download/$_sessionId';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch download URL')),
      );
    }
  }
}
