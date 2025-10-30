import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ChargesheetVettingScreen extends StatefulWidget {
  const ChargesheetVettingScreen({super.key});

  @override
  State<ChargesheetVettingScreen> createState() => _ChargesheetVettingScreenState();
}

class _ChargesheetVettingScreenState extends State<ChargesheetVettingScreen> {
  final _chargesheetContentController = TextEditingController();
  final _dio = Dio();

  bool _isLoading = false;
  Map<String, dynamic>? _suggestions;

  // Primary Orange Color (#FC633C)
  static const Color primaryOrange = Color(0xFFFC633C);

  @override
  void dispose() {
    _chargesheetContentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        setState(() {
          _chargesheetContentController.text = content;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.files.single.name} content loaded.'),
              backgroundColor: primaryOrange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_chargesheetContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload or paste the charge sheet content.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestions = null;
    });

    try {
      final response = await _dio.post(
        '/api/chargesheet-vetting',
        data: {
          'chargesheet': _chargesheetContentController.text,
        },
      );

      setState(() {
        _suggestions = response.data;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Charge sheet vetted and suggestions provided.'),
            backgroundColor: primaryOrange,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to vet charge sheet: $error'),
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
                        Icon(Icons.fact_check, color: primaryOrange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Charge Sheet Vetting AI',
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
                      'Upload or paste an existing charge sheet. The AI will review it and suggest improvements to strengthen the case.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Upload Charge Sheet (.txt file)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryOrange,
                            side: BorderSide(color: primaryOrange),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Choose File'),
                        ),
                        if (_chargesheetContentController.text.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(
                            'File loaded. You can also edit below.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Or Paste Charge Sheet Content',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _chargesheetContentController,
                      maxLines: 15,
                      decoration: InputDecoration(
                        hintText: 'Paste the full content of the charge sheet here...',
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
                        onPressed: _isLoading ? null : _handleSubmit,
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
                            : const Icon(Icons.verified),
                        label: Text(_isLoading ? 'Vetting...' : 'Vet Charge Sheet'),
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
                      'Vetting charge sheet, please wait...',
                      style: TextStyle(color: primaryOrange),
                    ),
                  ],
                ),
              ),
            ],

            // Result Card
            if (_suggestions != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Vetting Suggestions',
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
                        'Review the suggestions to improve the charge sheet.',
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
                          _suggestions!['suggestions'] ?? 'No suggestions provided',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: primaryOrange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AI-generated suggestions. Legal expertise is required for final decisions.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
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