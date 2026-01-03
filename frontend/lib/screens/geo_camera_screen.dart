import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/geo_camera_service.dart';
import '../services/watermark_processor.dart';
import 'dart:io';

enum CaptureMode { image, video }

class GeoCameraScreen extends StatefulWidget {
  final CaptureMode captureMode;

  const GeoCameraScreen({
    super.key,
    this.captureMode = CaptureMode.image,
  });

  @override
  State<GeoCameraScreen> createState() => _GeoCameraScreenState();
}

class _GeoCameraScreenState extends State<GeoCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitializing = true;
  bool _isCameraReady = false;
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = true;
  String? _errorMessage;
  FlashMode _flashMode = FlashMode.off;
  int _selectedCameraIndex = 0;
  bool _isCapturing = false;

  final _geoService = GeoCameraService();
  final _watermarkProcessor = WatermarkProcessor();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // On web, camera plugin IS supported via camera_web
      // We just need to handle permissions differently
      
      if (kIsWeb) {
        // Web: Get available cameras directly (no permission_handler on web)
        try {
          _cameras = await availableCameras();
          if (_cameras == null || _cameras!.isEmpty) {
            setState(() {
              _errorMessage = 'No cameras available. Please check browser permissions.';
              _isInitializing = false;
            });
            return;
          }
          
          // Initialize camera controller for web
          await _setupCamera(0);
          
          // Get location for web (will request permission via browser)
          _fetchLocation();
        } catch (e) {
          setState(() {
            _errorMessage = 'Camera access denied. Please allow camera access in browser settings.\n\nError: $e';
            _isInitializing = false;
          });
        }
        return;
      }
      
      // Native platform (Android/iOS) - use permission_handler
      // Request permissions
      final cameraStatus = await Permission.camera.request();
      final locationStatus = await Permission.location.request();

      if (!cameraStatus.isGranted) {
        setState(() {
          _errorMessage = 'Camera permission is required to capture evidence.';
          _isInitializing = false;
        });
        return;
      }

      if (!locationStatus.isGranted) {
        setState(() {
          _errorMessage = 'Location permission is required for geo-tagging evidence.';
          _isInitializing = false;
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available on this device.';
          _isInitializing = false;
        });
        return;
      }

      // Initialize camera controller
      await _setupCamera(_selectedCameraIndex);

      // Get location
      _fetchLocation();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing camera: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    // Dispose previous controller if exists
    await _cameraController?.dispose();

    final camera = _cameras![cameraIndex];
    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: widget.captureMode == CaptureMode.video,
    );

    try {
      await _cameraController!.initialize();
      setState(() {
        _isCameraReady = true;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await _geoService.getCurrentLocation();
      if (position != null) {
        final address = await _geoService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _currentPosition = position;
          _currentAddress = address;
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Unable to fetch location. Please enable GPS.';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for location... Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isCapturing = true);

    try {
      // Capture image
      final XFile imageFile = await _cameraController!.takePicture();

      // On web, we can't use File operations for watermarking (dart:io not available)
      if (kIsWeb) {
        // Return the captured image directly on web
        if (mounted) {
          Navigator.pop(context, imageFile);
        }
        return;
      }

      // Native platforms: Add watermark
      final watermarkText = _geoService.formatLocationWatermark(
        _currentPosition!,
        _currentAddress,
      );

      final watermarkedFile = await _watermarkProcessor.addWatermarkToImage(
        File(imageFile.path),
        watermarkText,
      );

      // Return the watermarked file
      if (mounted) {
        Navigator.pop(context, XFile(watermarkedFile.path));
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureVideo() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for location... Please try again.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      if (_cameraController!.value.isRecordingVideo) {
        // Stop recording
        final XFile videoFile = await _cameraController!.stopVideoRecording();

        setState(() => _isCapturing = true);

        // On web, return video directly (no File operations available)
        if (kIsWeb) {
          if (mounted) {
            Navigator.pop(context, videoFile);
          }
          return;
        }

        // Native platforms: Process video with metadata
        final watermarkText = _geoService.formatLocationWatermark(
          _currentPosition!,
          _currentAddress,
        );

        final processedFile = await _watermarkProcessor.addWatermarkToVideo(
          File(videoFile.path),
          watermarkText,
        );

        // Return the processed file
        if (mounted) {
          Navigator.pop(context, XFile(processedFile.path));
        }
      } else {
        // Start recording
        await _cameraController!.startVideoRecording();
        setState(() {});
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error with video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleFlash() async {
    if (_cameraController == null) return;

    try {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.torch;
      } else {
        _flashMode = FlashMode.off;
      }
      await _cameraController!.setFlashMode(_flashMode);
      setState(() {});
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  void _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
      _isCameraReady = false;
    });

    await _setupCamera(_selectedCameraIndex);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFC633C);

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_errorMessage!.contains('permission')) {
                        openAppSettings();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(_errorMessage!.contains('permission')
                        ? Icons.settings
                        : Icons.arrow_back),
                    label: Text(_errorMessage!.contains('permission')
                        ? 'Open Settings'
                        : 'Go Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isInitializing || !_isCameraReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: _cameraController != null
                ? CameraPreview(_cameraController!)
                : const SizedBox(),
          ),

          // Location Overlay
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isLoadingLocation
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Fetching location...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    )
                  : _currentPosition != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '📍 ${_currentPosition!.latitude.toStringAsFixed(4)}°${_currentPosition!.latitude >= 0 ? 'N' : 'S'}, ${_currentPosition!.longitude.toStringAsFixed(4)}°${_currentPosition!.longitude >= 0 ? 'E' : 'W'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📅 ${DateTime.now().toString().substring(0, 19)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            if (_currentAddress != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '📌 $_currentAddress',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        )
                      : const Text(
                          'Location unavailable',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
            ),
          ),

          // Top Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                    // Flash button
                    IconButton(
                      onPressed: _toggleFlash,
                      icon: Icon(
                        _flashMode == FlashMode.off
                            ? Icons.flash_off
                            : Icons.flash_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Refresh location button
                    IconButton(
                      onPressed: _isLoadingLocation ? null : _fetchLocation,
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 32),
                    ),

                    // Capture button
                    GestureDetector(
                      onTap: _isCapturing
                          ? null
                          : (widget.captureMode == CaptureMode.image
                              ? _captureImage
                              : _captureVideo),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          color: _isCapturing
                              ? Colors.grey
                              : (widget.captureMode == CaptureMode.video &&
                                      _cameraController?.value.isRecordingVideo == true
                                  ? Colors.red
                                  : orange),
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                widget.captureMode == CaptureMode.video &&
                                        _cameraController?.value.isRecordingVideo == true
                                    ? Icons.stop
                                    : (widget.captureMode == CaptureMode.image
                                        ? Icons.camera_alt
                                        : Icons.videocam),
                                color: Colors.white,
                                size: 32,
                              ),
                      ),
                    ),

                    // Switch camera button
                    IconButton(
                      onPressed: _cameras != null && _cameras!.length > 1
                          ? _switchCamera
                          : null,
                      icon: const Icon(Icons.flip_camera_ios,
                          color: Colors.white, size: 32),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Recording indicator for video
          if (widget.captureMode == CaptureMode.video &&
              _cameraController?.value.isRecordingVideo == true)
            Positioned(
              top: 120,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                    SizedBox(width: 6),
                    Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
}
