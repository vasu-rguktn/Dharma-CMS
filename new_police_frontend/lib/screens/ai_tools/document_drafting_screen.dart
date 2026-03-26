import 'package:flutter/material.dart';
import 'package:dharma_police/services/api/ai_gateway_api.dart';

class DocumentDraftingScreen extends StatefulWidget {
  const DocumentDraftingScreen({super.key});
  @override
  State<DocumentDraftingScreen> createState() => _DocumentDraftingScreenState();
}

class _DocumentDraftingScreenState extends State<DocumentDraftingScreen> {
  final _caseDataController = TextEditingController();
  final _instructionsController = TextEditingController();
  String? _recipientType;
  bool _isLoading = false;
  Map<String, dynamic>? _draft;

  static const _recipientTypes = ['Court', 'Prosecution', 'Senior Officer', 'Government', 'Other'];

  @override
  void dispose() { _caseDataController.dispose(); _instructionsController.dispose(); super.dispose(); }

  Future<void> _generate() async {
    if (_caseDataController.text.trim().isEmpty) { _snack('Enter case data'); return; }
    setState(() { _isLoading = true; _draft = null; });
    try {
      final result = await AiGatewayApi.draftDocument(
        caseData: _caseDataController.text.trim(),
        recipientType: _recipientType ?? '',
        additionalInstructions: _instructionsController.text.trim(),
      );
      setState(() => _draft = result);
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
        const Text('Document Drafting', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('AI-powered legal document drafting', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 20),

        DropdownButtonFormField<String>(
          value: _recipientType,
          decoration: InputDecoration(labelText: 'Recipient Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: _recipientTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => _recipientType = v),
        ),
        const SizedBox(height: 12),

        TextField(controller: _caseDataController, decoration: InputDecoration(labelText: 'Case Data / Context', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 5),
        const SizedBox(height: 12),
        TextField(controller: _instructionsController, decoration: InputDecoration(labelText: 'Additional Instructions (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _generate,
            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
            label: Text(_isLoading ? 'Generating...' : 'Generate Draft'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),

        if (_draft != null) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Generated Draft', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(),
                SelectableText(_draft!['draft']?.toString() ?? _draft.toString(), style: const TextStyle(height: 1.6)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}
