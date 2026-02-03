import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AddPetitionUpdateDialog extends StatefulWidget {
  final Petition petition;
  final String policeOfficerName;
  final String policeOfficerUserId;

  const AddPetitionUpdateDialog({
    Key? key,
    required this.petition,
    required this.policeOfficerName,
    required this.policeOfficerUserId,
  }) : super(key: key);

  @override
  State<AddPetitionUpdateDialog> createState() => _AddPetitionUpdateDialogState();
}

class _AddPetitionUpdateDialogState extends State<AddPetitionUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _updateTextController = TextEditingController();
  
  List<PlatformFile> _selectedPhotos = [];
  List<PlatformFile> _selectedDocuments = [];
  bool _isSubmitting = false;
  bool _isAiChecking = false;
  String? _aiColor;   // 'green' | 'amber' | 'red'
  String? _aiReason;

  // Base URL for Dharma CMS backend.
  // You can override this at build time with:
  //   --dart-define=DHARMA_CMS_URL=https://your-backend
  static const String _cmsBaseUrl = String.fromEnvironment(
    'DHARMA_CMS_URL',
    defaultValue: 'http://localhost:8000',
  );

  @override
  void dispose() {
    _updateTextController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: kIsWeb, // Only load bytes on Web to avoid OOM on Android
      );

      if (result != null) {
        setState(() {
          _selectedPhotos.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx', 'csv'],
        allowMultiple: true,
        withData: kIsWeb, // Only load bytes on Web to avoid OOM on Android
      );

      if (result != null) {
        setState(() {
          _selectedDocuments.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final provider = context.read<PetitionProvider>();
      
      debugPrint('📤 [UPDATE] Starting petition update submission');
      debugPrint('📸 Photos: ${_selectedPhotos.length}, 📄 Documents: ${_selectedDocuments.length}');
      
      final success = await provider.createPetitionUpdate(
        petitionId: widget.petition.id!,
        updateText: _updateTextController.text.trim(),
        addedBy: widget.policeOfficerName,
        addedByUserId: widget.policeOfficerUserId,
        photoFiles: _selectedPhotos.isEmpty ? null : _selectedPhotos,
        documentFiles: _selectedDocuments.isEmpty ? null : _selectedDocuments,
        aiStatus: _aiColor, 
        // We aren't capturing the score in state yet, but color is what drives the UI
      );

      if (mounted) {
        if (success) {
          debugPrint('✅ [UPDATE] Petition update created successfully');
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Update added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint('❌ [UPDATE] Failed to create petition update');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to add update. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [UPDATE] Exception during update submission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _runAiRelevanceCheck() async {
    if (_isAiChecking) return;

    // Do not attempt AI check if there's no description at all.
    if ((_updateTextController.text.trim().isEmpty) &&
        _selectedPhotos.isEmpty &&
        _selectedDocuments.isEmpty) {
      return;
    }

    setState(() {
      _isAiChecking = true;
      _aiColor = null;
      _aiReason = null;
    });

    try {
      final petition = widget.petition;
      final uri = Uri.parse('$_cmsBaseUrl/api/document-relevance/');

      final request = http.MultipartRequest('POST', uri)
        ..fields['petition_title'] = petition.title
        ..fields['petition_description'] =
            (petition.grounds ?? petition.incidentAddress ?? '').toString()
        ..fields['petition_type'] = petition.type.displayName
        ..fields['station_name'] = petition.stationName ?? ''
        ..fields['update_text'] = _updateTextController.text.trim();

      // Attach any files that have in-memory bytes (Web primarily).
      final allFiles = <PlatformFile>[];
      allFiles.addAll(_selectedPhotos);
      allFiles.addAll(_selectedDocuments);

      for (final file in allFiles) {
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          _aiColor = (data['color'] as String?)?.toLowerCase();
          _aiReason = data['reason'] as String?;
        });
      } else {
        setState(() {
          _aiColor = 'amber';
          _aiReason =
              'AI relevance check failed (${response.statusCode}); please verify evidence manually.';
        });
      }
    } catch (e) {
      debugPrint('⚠️ [UPDATE] AI relevance check error: $e');
      if (mounted) {
        setState(() {
          _aiColor = 'amber';
          _aiReason =
              'AI relevance check failed; please verify evidence manually.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_task,
                          color: Colors.indigo.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Add Case Update',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  
                  Text(
                    'Case: ${widget.petition.title}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const Divider(height: 32),

                  // Update Text Field
                  const Text(
                    'Work Update',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _updateTextController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Describe the work done, progress made, or any developments...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter update details';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Photos Section
                  const Text(
                    'Photos (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _pickPhotos,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Photos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),

                  if (_selectedPhotos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedPhotos.map((photo) {
                        return Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        photo.name,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedPhotos.remove(photo);
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Documents Section
                  const Text(
                    'Documents (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _pickDocuments,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add Documents'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),

                  if (_selectedDocuments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._selectedDocuments.map((doc) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                doc.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _selectedDocuments.remove(doc);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],

                  const SizedBox(height: 32),
                  const SizedBox(height: 24),

                  // AI relevance feedback (if available)
                  if (_isAiChecking) ...[
                    Row(
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI is checking if the attached documents match this case...',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else if (_aiColor != null) ...[
                    _buildAiFeedbackBanner(),
                    const SizedBox(height: 12),
                  ],

                  // Action buttons row: Check with AI + Submit
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isAiChecking ? null : _runAiRelevanceCheck,
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('Check with AI'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Submit Update',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiFeedbackBanner() {
    Color border;
    Color background;
    IconData icon;

    switch (_aiColor) {
      case 'green':
        border = Colors.green;
        background = Colors.green.shade50;
        icon = Icons.check_circle;
        break;
      case 'red':
        border = Colors.red;
        background = Colors.red.shade50;
        icon = Icons.error;
        break;
      default:
        border = Colors.orange;
        background = Colors.orange.shade50;
        icon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: border),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _aiReason ??
                  'AI has reviewed the attached documents for this case.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
