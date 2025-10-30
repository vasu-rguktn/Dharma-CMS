import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

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

  // Primary Orange Color (#FC633C)
  static const Color primaryOrange = Color(0xFFFC633C);

  @override
  void dispose() {
    _userContextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select an image smaller than 10MB.'),
                backgroundColor: Colors.red,
              ),
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

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source', style: TextStyle(color: primaryOrange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: primaryOrange),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: primaryOrange),
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
  }

  Future<void> _handleAnalyze() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image to analyze.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _analysisResult = null;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final imageDataUri = 'data:image/jpeg;base64,$base64Image';

      final response = await _dio.post(
        '/api/media-analysis',
        data: {
          'imageDataUri': imageDataUri,
          'userContext': _userContextController.text.trim().isEmpty
              ? null
              : _userContextController.text,
        },
      );

      setState(() {
        _analysisResult = response.data;
        _editableSceneNarrative = response.data['sceneNarrative'];
        _editableCaseFileSummary = response.data['caseFileSummary'];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Analysis complete. Review the AI-generated findings below.'),
            backgroundColor: primaryOrange,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze media: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _analysisResult = {
          'identifiedElements': [
            {
              'name': 'Error',
              'category': 'System',
              'description': 'Analysis failed: $error'
            }
          ],
          'sceneNarrative': 'Could not generate scene narrative due to an error.',
          'caseFileSummary': 'Could not generate case file summary due to an error.',
        };
        _editableSceneNarrative = 'Could not generate scene narrative due to an error.';
        _editableCaseFileSummary = 'Could not generate case file summary due to an error.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: primaryOrange,
            ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image_search, color: primaryOrange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI Crime Scene Investigator',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryOrange,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload an image (max 10MB) for crime scene analysis. The AI will identify elements, describe the scene, and provide a summary.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Upload Image',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showImageSourceDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryOrange,
                            side: BorderSide(color: primaryOrange),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Choose Image'),
                        ),
                        if (_selectedImage != null) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedImage!.path.split('/').last,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (_selectedImage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: primaryOrange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryOrange.withOpacity(0.3)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Text(
                      'Context / Specific Instructions (Optional)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _userContextController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'E.g., \'Focus on potential weapons.\', \'Is there any sign of forced entry?\', \'What is written on the note on the table?\'',
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryOrange, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || _selectedImage == null)
                            ? null
                            : _handleAnalyze,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isLoading ? 'Analyzing...' : 'Analyze Image'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading State
            if (_isLoading) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: primaryOrange),
                      const SizedBox(height: 16),
                      Text(
                        'AI is analyzing the image, please wait...',
                        style: TextStyle(color: primaryOrange),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '(This may take a moment depending on image complexity)',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Result Card
            if (_analysisResult != null && !_isLoading) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crime Scene Analysis Report',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primaryOrange,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date: ${DateTime.now().toString().split(' ')[0]} | File: ${_selectedImage?.path.split('/').last ?? 'N/A'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),

                      // Identified Elements
                      Row(
                        children: [
                          Icon(Icons.checklist, color: primaryOrange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Identified Elements',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryOrange,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_analysisResult!['identifiedElements'] != null &&
                          (_analysisResult!['identifiedElements'] as List).isNotEmpty &&
                          !(_analysisResult!['identifiedElements'][0]['name'] as String)
                              .startsWith('Error')) ...[
                        Container(
                          constraints: const BoxConstraints(maxHeight: 400),
                          decoration: BoxDecoration(
                            color: primaryOrange.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryOrange.withOpacity(0.3)),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(12),
                            itemCount:
                                (_analysisResult!['identifiedElements'] as List).length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final element =
                                  _analysisResult!['identifiedElements'][index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${element['name']}${element['count'] != null ? ' (Count: ${element['count']})' : ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: primaryOrange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Category: ${element['category']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Description: ${element['description']}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryOrange.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryOrange.withOpacity(0.3)),
                          ),
                          child: Text(
                            _analysisResult!['identifiedElements']?[0]?['description'] ??
                                'No specific elements prominently identified or analysis incomplete.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Scene Narrative
                      Row(
                        children: [
                          Icon(Icons.description, color: primaryOrange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Scene Narrative (Editable)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryOrange,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: _editableSceneNarrative),
                        onChanged: (value) => _editableSceneNarrative = value,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText:
                              'AI-generated scene narrative will appear here. You can edit it.',
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryOrange, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Case File Summary
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: primaryOrange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Case File Summary & Hypotheses (Editable)',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: primaryOrange,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: _editableCaseFileSummary),
                        onChanged: (value) => _editableCaseFileSummary = value,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText:
                              'AI-generated summary and hypotheses will appear here. You can edit it.',
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryOrange, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber, color: primaryOrange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'AI-generated analysis. Verify with physical investigation.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Download feature coming soon'),
                                  backgroundColor: primaryOrange,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryOrange,
                              side: BorderSide(color: primaryOrange),
                            ),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Download'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}