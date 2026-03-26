import 'package:flutter/material.dart';
import 'package:dharma_police/services/api/ai_gateway_api.dart';

class ChargesheetVettingScreen extends StatefulWidget {
  const ChargesheetVettingScreen({super.key});
  @override
  State<ChargesheetVettingScreen> createState() => _ChargesheetVettingScreenState();
}

class _ChargesheetVettingScreenState extends State<ChargesheetVettingScreen> {
  final _textController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() { _textController.dispose(); _instructionsController.dispose(); super.dispose(); }

  Future<void> _vet() async {
    if (_textController.text.trim().isEmpty) { _snack('Enter chargesheet text'); return; }
    setState(() { _isLoading = true; _result = null; });
    try {
      final result = await AiGatewayApi.vetChargesheet(
        chargesheetText: _textController.text.trim(),
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
        const Text('Chargesheet Vetting', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('AI-powered review of existing chargesheets', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 20),

        TextField(controller: _textController, decoration: InputDecoration(labelText: 'Paste Chargesheet Text', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 8),
        const SizedBox(height: 12),
        TextField(controller: _instructionsController, decoration: InputDecoration(labelText: 'Additional Instructions (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _vet,
            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.fact_check),
            label: Text(_isLoading ? 'Analysing...' : 'Vet Chargesheet'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),

        if (_result != null) ...[
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Vetting Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            SelectableText(_result!['vetting_result']?.toString() ?? _result.toString(), style: const TextStyle(height: 1.6)),
          ]))),
        ],
      ]),
    );
  }
}
