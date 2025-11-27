import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
              SnackBar(
                content: Text(AppLocalizations.of(context)!.imageSizeLimit),
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
            content: Text(AppLocalizations.of(context)!.errorPickingImage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.selectImageSource),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(localizations.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(localizations.camera),
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectImageToAnalyze),
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
      // Convert image to base64
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final imageDataUri = 'data:image/jpeg;base64,$base64Image';

      // TODO: Replace with your actual API endpoint
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
            content: Text(AppLocalizations.of(context)!.analysisComplete),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToAnalyzeMedia(error.toString())),
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
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return SingleChildScrollView(
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
                      Icon(Icons.image_search, color: theme.primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations.aiCrimeSceneInvestigator,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.mediaAnalysisDesc,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    localizations.uploadImage,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showImageSourceDialog,
                        icon: const Icon(Icons.upload_file),
                        label: Text(localizations.chooseImage),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      if (_selectedImage != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedImage!.path.split('/').last,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
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
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
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
                    localizations.contextInstructions,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userContextController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: localizations.contextInstructionsHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: (_isLoading || _selectedImage == null) ? null : _handleAnalyze,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(_isLoading ? localizations.analyzing : localizations.analyzeImage),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_isLoading) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      localizations.analyzingImageWait,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localizations.analyzingComplexityNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
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
                      localizations.crimeSceneAnalysisReport,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${localizations.date}: ${DateTime.now().toString().split(' ')[0]} | ${localizations.file}: ${_selectedImage?.path.split('/').last ?? 'N/A'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Identified Elements
                    Row(
                      children: [
                        Icon(Icons.checklist, color: theme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          localizations.identifiedElements,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_analysisResult!['identifiedElements'] != null &&
                        (_analysisResult!['identifiedElements'] as List).isNotEmpty &&
                        !(_analysisResult!['identifiedElements'][0]['name'] as String).startsWith('Error')) ...[
                      Container(
                        constraints: const BoxConstraints(maxHeight: 400),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: (_analysisResult!['identifiedElements'] as List).length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final element = _analysisResult!['identifiedElements'][index];
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
                                    '${element['name']}${element['count'] != null ? ' (${localizations.count}: ${element['count']})' : ''}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${localizations.category}: ${element['category']}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${localizations.description}: ${element['description']}',
                                    style: theme.textTheme.bodySmall,
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _analysisResult!['identifiedElements']?[0]?['description'] ??
                              localizations.noElementsIdentified,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Scene Narrative
                    Row(
                      children: [
                        Icon(Icons.description, color: theme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          localizations.sceneNarrativeEditable,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
                        hintText: localizations.sceneNarrativeHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Case File Summary
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: theme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          localizations.caseFileSummaryEditable,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
                        hintText: localizations.caseFileSummaryHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                localizations.aiAnalysisDisclaimer,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(localizations.downloadFeatureComingSoon),
                              ),
                            );
                          },
                          icon: const Icon(Icons.download),
                          label: Text(localizations.download),
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
    );
  }
}
