import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dharma_police/services/api/ai_gateway_api.dart';

class MediaAnalysisScreen extends StatefulWidget {
  const MediaAnalysisScreen({super.key});
  @override
  State<MediaAnalysisScreen> createState() => _MediaAnalysisScreenState();
}

class _MediaAnalysisScreenState extends State<MediaAnalysisScreen> {
  final _instructionsController = TextEditingController();
  PlatformFile? _selectedFile;
  String _analysisType = 'general';
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  static const _analysisTypes = ['general', 'face_detection', 'text_extraction', 'object_detection', 'scene_analysis'];

  @override
  void dispose() { _instructionsController.dispose(); super.dispose(); }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'pdf']);
    if (result != null) setState(() => _selectedFile = result.files.first);
  }

  Future<void> _analyze() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) { _snack('Select a file first'); return; }
    setState(() { _isLoading = true; _result = null; });
    try {
      final result = await AiGatewayApi.analyzeMedia(
        fileBytes: _selectedFile!.bytes!,
        fileName: _selectedFile!.name,
        analysisType: _analysisType,
        additionalInstructions: _instructionsController.text.trim(),
      );
      setState(() => _result = result);
    } catch (e) {
      _snack('Error: $e');
    }
    setState(() => _isLoading = false);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Media Analysis', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('AI-powered image / video / document analysis', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 20),

        // File picker
        InkWell(
          onTap: _pickFile,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity, height: 100,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid), borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: _selectedFile != null
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.attach_file, size: 28, color: Colors.blueGrey),
                      const SizedBox(height: 4),
                      Text(_selectedFile!.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.cloud_upload_outlined, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 4),
                      Text('Tap to select file', style: TextStyle(color: Colors.grey.shade500)),
                    ]),
            ),
          ),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _analysisType,
          decoration: InputDecoration(labelText: 'Analysis Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: _analysisTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase()))).toList(),
          onChanged: (v) => setState(() => _analysisType = v ?? 'general'),
        ),
        const SizedBox(height: 12),
        TextField(controller: _instructionsController, decoration: InputDecoration(labelText: 'Instructions (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _analyze,
            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.image_search),
            label: Text(_isLoading ? 'Analysing...' : 'Analyze'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),

        if (_result != null) ...[
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Analysis Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            SelectableText(_result!['analysis']?.toString() ?? _result.toString(), style: const TextStyle(height: 1.6)),
          ]))),
        ],
      ]),
    );
  }
}
