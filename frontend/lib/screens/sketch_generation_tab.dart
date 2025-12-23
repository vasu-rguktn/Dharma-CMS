import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class SketchGenerationTab extends StatefulWidget {
  const SketchGenerationTab({super.key});

  @override
  State<SketchGenerationTab> createState() => _SketchGenerationTabState();
}

class _SketchGenerationTabState extends State<SketchGenerationTab> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ageShiftController = TextEditingController();
  final TextEditingController _caseRefController = TextEditingController();
  
  bool _beard = false;
  bool _glasses = false;
  bool _isLoading = false;
  String? _generatedImageBase64;
  String? _errorMessage;
  final Dio _dio = Dio();
  
  String _baseUrl = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initBackend();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _ageShiftController.dispose();
    _caseRefController.dispose();
    super.dispose();
  }

  Future<void> _initBackend() async {
    if (_isInitialized) return;

    // Prefer local FastAPI backend on port 8000.
    final List<String> candidates = <String>['http://localhost:8000'];

    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroid) {
      candidates.add('http://10.0.2.2:8000');
    }

    String? resolved;
    for (final base in candidates) {
      if (await _isBackendHealthy(base)) {
        resolved = base;
        break;
      }
    }

    resolved ??= 'http://localhost:8000';
    _baseUrl = resolved;
    _isInitialized = true;
  }

  Future<bool> _isBackendHealthy(String base) async {
    final paths = ['/api/health', '/docs']; 
    // Note: The sketch router doesn't have a specific health check, so checking general API health
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
        if (resp.statusCode != null && resp.statusCode! >= 200 && resp.statusCode! < 400) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<void> _generateSketch() async {
    if (!_isInitialized) await _initBackend();

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _generatedImageBase64 = null;
    });

    try {
      // Construct prompt from fields
      final List<String> parts = [description];
      
      final ageShift = _ageShiftController.text.trim();
      if (ageShift.isNotEmpty) {
        parts.add('age shift $ageShift years');
      }
      
      if (_beard) parts.add('beard');
      if (_glasses) parts.add('glasses');
      
      final fullPrompt = parts.join(', ');

      final response = await _dio.post(
        '$_baseUrl/api/sketch/generate',
        data: {'prompt': fullPrompt},
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['status'] == 'success' && data['image_base64'] != null) {
          setState(() {
            _generatedImageBase64 = data['image_base64'];
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
        if (e is DioException) {
          if (e.response?.data != null && e.response!.data is Map) {
             _errorMessage = e.response!.data['detail'] ?? e.message;
          } else {
             _errorMessage = e.message;
          }
        }
      });
    }
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
                'Suspect Generation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate a suspect sketch based on a textual description using AI.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 24),
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'e.g., Male, mid-30s, short black hair, wearing glasses, prominent scar on left cheek...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Age Shift (Years)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _ageShiftController,
                decoration: InputDecoration(
                  hintText: 'e.g., -5 or 10',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Case Reference (FIR No.)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _caseRefController,
                decoration: InputDecoration(
                  hintText: 'Optional case reference',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Disguise Options',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Switch(
                      value: _beard,
                      onChanged: (v) => setState(() => _beard = v),
                      activeColor: Colors.deepPurple),
                  const Text('Beard'),
                  const SizedBox(width: 20),
                  Switch(
                      value: _glasses,
                      onChanged: (v) => setState(() => _glasses = v),
                      activeColor: Colors.deepPurple),
                  const Text('Glasses'),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateSketch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Text('Generate Image'),
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
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                ),
              ],
              
              if (_generatedImageBase64 != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Generated Sketch',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(_generatedImageBase64!),
                     width: double.infinity,
                     fit: BoxFit.contain,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
