import 'package:flutter/material.dart';
import 'package:dharma_police/services/api/ai_gateway_api.dart';

class InvestigationScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const InvestigationScreen({super.key, this.extra});
  @override
  State<InvestigationScreen> createState() => _InvestigationScreenState();
}

class _InvestigationScreenState extends State<InvestigationScreen> {
  final _contextController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    if (widget.extra?['caseId'] != null) {
      _contextController.text = 'Case ID: ${widget.extra!['caseId']}';
    }
  }

  @override
  void dispose() { _contextController.dispose(); super.dispose(); }

  Future<void> _generate() async {
    if (_contextController.text.trim().isEmpty) { _snack('Enter case context'); return; }
    setState(() { _isLoading = true; _result = null; });
    try {
      final result = await AiGatewayApi.getInvestigationGuidelines({
        'case_context': _contextController.text.trim(),
      });
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
        const Text('Investigation Guidelines', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('AI-powered investigation guidance based on case details', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 20),

        TextField(controller: _contextController, decoration: InputDecoration(labelText: 'Case Context / Details', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 6),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _generate,
            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
            label: Text(_isLoading ? 'Generating...' : 'Get Guidelines'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),

        if (_result != null) ...[
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            SelectableText(_result!['guidelines']?.toString() ?? _result.toString(), style: const TextStyle(height: 1.6)),
          ]))),
        ],
      ]),
    );
  }
}
