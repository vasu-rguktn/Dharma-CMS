import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ChargesheetGenerationScreen extends StatefulWidget {
  const ChargesheetGenerationScreen({super.key});

  @override
  State<ChargesheetGenerationScreen> createState() => _ChargesheetGenerationScreenState();
}

class _ChargesheetGenerationScreenState extends State<ChargesheetGenerationScreen> {
  final _additionalInstructionsController = TextEditingController();
  final _dio = Dio();

  List<File> _uploadedFiles = [];
  bool _isLoading = false;
  Map<String, dynamic>? _chargeSheet;

  // Primary Orange Color (#FC633C)
  static const Color primaryOrange = Color(0xFFFC633C);

  @override
  void dispose() {
    _additionalInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        setState(() {
          _uploadedFiles.addAll(
            result.paths.map((path) => File(path!)).toList(),
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.files.length} file(s) added'),
              backgroundColor: primaryOrange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _uploadedFiles.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_uploadedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one document.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _chargeSheet = null;
    });

    try {
      final formData = FormData();

      for (var file in _uploadedFiles) {
        formData.files.add(
          MapEntry(
            'documents',
            await MultipartFile.fromFile(file.path),
          ),
        );
      }

      if (_additionalInstructionsController.text.trim().isNotEmpty) {
        formData.fields.add(
          MapEntry('additionalInstructions', _additionalInstructionsController.text),
        );
      }

      final response = await _dio.post(
        '/api/chargesheet-generation',
        data: formData,
      );

      setState(() {
        _chargeSheet = response.data;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Draft charge sheet generated.'),
            backgroundColor: primaryOrange,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate charge sheet: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                        Icon(Icons.file_present, color: primaryOrange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Charge Sheet Generator',
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
                      'Upload relevant documents (FIR, witness statements, evidence reports in .doc, .docx, .pdf, .txt) and provide additional instructions. The AI will formulate a draft charge sheet based on the provided template.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Case Documents',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickFiles,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryOrange,
                        side: BorderSide(color: primaryOrange),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Choose Files'),
                    ),

                    if (_uploadedFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryOrange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryOrange.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.list, color: primaryOrange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Uploaded Files:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: primaryOrange,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...List.generate(_uploadedFiles.length, (index) {
                              final file = _uploadedFiles[index];
                              final fileName = file.path.split('/').last;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: Colors.black87),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      color: Colors.red,
                                      onPressed: () => _removeFile(index),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    Text(
                      'Additional Instructions (Optional)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _additionalInstructionsController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'E.g., \'Focus on connecting Accused A to the weapon found.\', \'Emphasize the premeditation aspect based on Witness B\'s statement.\'...',
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
                        onPressed: (_isLoading || _uploadedFiles.isEmpty)
                            ? null
                            : _handleSubmit,
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
                            : const Icon(Icons.create),
                        label: Text(
                            _isLoading ? 'Generating...' : 'Generate Draft Charge Sheet'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Loading State
            if (_isLoading) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: primaryOrange),
                    const SizedBox(height: 16),
                    Text(
                      'Generating charge sheet, this may take a moment...',
                      style: TextStyle(color: primaryOrange),
                    ),
                  ],
                ),
              ),
            ],

            // Result Card
            if (_chargeSheet != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generated Draft Charge Sheet',
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
                        'Review the generated draft. This is a starting point and requires legal review and verification against original documents.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryOrange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryOrange.withOpacity(0.3)),
                        ),
                        child: SelectableText(
                          _chargeSheet!['chargeSheet'] ?? 'No charge sheet generated',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  color: primaryOrange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'AI-generated content. Must be reviewed and verified by a legal professional.',
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
                                  content: const Text('Draft copied to clipboard'),
                                  backgroundColor: primaryOrange,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryOrange,
                              side: BorderSide(color: primaryOrange),
                            ),
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy Draft'),
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