// lib/screens/media_analysis_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';

class MediaAnalysisScreen extends StatefulWidget {
  const MediaAnalysisScreen({super.key});

  @override
  State<MediaAnalysisScreen> createState() => _MediaAnalysisScreenState();
}

class _MediaAnalysisScreenState extends State<MediaAnalysisScreen> {
  final _userContextController = TextEditingController();
  final _dio = Dio();
  final _imagePicker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  String? _editableSceneNarrative;
  String? _editableCaseFileSummary;

  static const Color orange = Color(0xFFFC633C);

  @override
  void dispose() {
    _userContextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileSize = await file.length();

      if (fileSize > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.imageSizeLimit), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        _selectedImage = file;
        _analysisResult = null;
        _editableSceneNarrative = null;
        _editableCaseFileSummary = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorPickingImage(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.selectImageSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(l.camera),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAnalyze() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectImageToAnalyze), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final imageDataUri = 'data:image/jpeg;base64,$base64Image';

      final response = await _dio.post(
        '/api/media-analysis',
        data: {
          'imageDataUri': imageDataUri,
          'userContext': _userContextController.text.trim().isEmpty ? null : _userContextController.text.trim(),
        },
      );

      setState(() {
        _analysisResult = response.data;
        _editableSceneNarrative = response.data['sceneNarrative'];
        _editableCaseFileSummary = response.data['caseFileSummary'];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.analysisComplete), backgroundColor: Colors.green),
      );
    } catch (error) {
      final errorMsg = error.toString();
      setState(() {
        _analysisResult = {
          'identifiedElements': [
            {'name': 'Analysis Failed', 'category': 'Error', 'description': 'Failed: $errorMsg'}
          ],
          'sceneNarrative': 'Analysis failed.',
          'caseFileSummary': 'Analysis failed.',
        };
        _editableSceneNarrative = 'Analysis failed.';
        _editableCaseFileSummary = 'Analysis failed.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToAnalyzeMedia(errorMsg)), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER WITH ORANGE BACK ARROW
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final dashboardRoute = authProvider.role == 'police' ? '/police-dashboard' : '/dashboard';
                      context.go(dashboardRoute);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: orange,
                        size: 32,
                        shadows: const [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.aiCrimeSceneInvestigator,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 24, 24),
              child: Text(l.mediaAnalysisDesc, style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.4)),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.image_search_rounded, color: orange, size: 28),
                                const SizedBox(width: 12),
                                Text(l.aiCrimeSceneInvestigator, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 28),

                            const Text("Upload Image", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _showImageSourceDialog,
                                  icon: const Icon(Icons.add_photo_alternate_rounded),
                                  label: Text(l.chooseImage),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: orange,
                                    side: BorderSide(color: orange),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (_selectedImage != null)
                                  Expanded(
                                    child: Text(
                                      _selectedImage!.path.split('/').last,
                                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                              ],
                            ),

                            if (_selectedImage != null) ...[
                              const SizedBox(height: 20),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_selectedImage!, height: 340, width: double.infinity, fit: BoxFit.cover),
                              ),
                            ],

                            const SizedBox(height: 24),
                            const Text("Additional Context (Optional)", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _userContextController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: l.contextInstructionsHint,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),

                            const SizedBox(height: 32),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: (_isLoading || _selectedImage == null) ? null : _handleAnalyze,
                                icon: _isLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.search_rounded),
                                label: Text(_isLoading ? l.analyzing : l.analyzeImage),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isLoading) ...[
                      const SizedBox(height: 32),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: const Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: orange, strokeWidth: 5),
                              SizedBox(height: 24),
                              Text("Analyzing image...", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (_analysisResult != null && !_isLoading) ...[
                      const SizedBox(height: 32),
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.description_rounded, color: orange, size: 30),
                                  const SizedBox(width: 12),
                                  Text(l.crimeSceneAnalysisReport, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('${l.date}: ${DateTime.now().toString().split(' ')[0]}', style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(height: 28),

                              _buildSection(icon: Icons.check_circle_rounded, color: Colors.blue[700]!, title: l.identifiedElements, child: _buildElementsList(l)),
                              const SizedBox(height: 28),
                              _buildSection(icon: Icons.description_rounded, color: Colors.purple[700]!, title: l.sceneNarrativeEditable, child: TextField(
                                controller: TextEditingController(text: _editableSceneNarrative)
                                  ..selection = TextSelection.fromPosition(TextPosition(offset: _editableSceneNarrative?.length ?? 0)),
                                onChanged: (v) => _editableSceneNarrative = v,
                                maxLines: 12,
                                decoration: InputDecoration(filled: true, fillColor: Colors.purple[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                              )),
                              const SizedBox(height: 28),
                              _buildSection(icon: Icons.lightbulb_rounded, color: Colors.green[700]!, title: l.caseFileSummaryEditable, child: TextField(
                                controller: TextEditingController(text: _editableCaseFileSummary)
                                  ..selection = TextSelection.fromPosition(TextPosition(offset: _editableCaseFileSummary?.length ?? 0)),
                                onChanged: (v) => _editableCaseFileSummary = v,
                                maxLines: 10,
                                decoration: InputDecoration(filled: true, fillColor: Colors.green[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                              )),
                              const SizedBox(height: 32),
                              OutlinedButton.icon(
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.downloadFeatureComingSoon))),
                                icon: const Icon(Icons.download_rounded),
                                label: Text(l.download),
                                style: OutlinedButton.styleFrom(foregroundColor: orange, side: BorderSide(color: orange)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required IconData icon, required Color color, required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildElementsList(AppLocalizations l) {
    final elements = _analysisResult!['identifiedElements'] as List<dynamic>? ?? [];

    if (elements.isEmpty || (elements[0] as Map)['name'] == 'Analysis Failed') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)),
        child: Text(elements.isEmpty ? l.noElementsIdentified : elements[0]['description'], style: TextStyle(color: Colors.red[700])),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),  // Fixed here
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: elements.length,
        separatorBuilder: (_, __) => const Divider(height: 20),
        itemBuilder: (context, index) {
          final e = elements[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),  // Fixed here
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['name'], style: TextStyle(fontWeight: FontWeight.bold, color: orange, fontSize: 16)),
                if (e['count'] != null) Text("Count: ${e['count']}", style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 6),
                Text("Category: ${e['category']}", style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 6),
                Text(e['description'], style: const TextStyle(height: 1.4)),
              ],
            ),
          );
        },
      ),
    );
  }
}