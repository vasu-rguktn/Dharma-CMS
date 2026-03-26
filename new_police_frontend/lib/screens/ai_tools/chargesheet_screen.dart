import 'package:flutter/material.dart';
import 'package:dharma_police/services/api/ai_gateway_api.dart';

class ChargesheetScreen extends StatefulWidget {
  const ChargesheetScreen({super.key});
  @override
  State<ChargesheetScreen> createState() => _ChargesheetScreenState();
}

class _ChargesheetScreenState extends State<ChargesheetScreen> {
  final _incidentController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _stationController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() { _incidentController.dispose(); _instructionsController.dispose(); _stationController.dispose(); super.dispose(); }

  Future<void> _generate() async {
    if (_incidentController.text.trim().isEmpty) { _snack('Enter incident details'); return; }
    setState(() { _isLoading = true; _result = null; });
    try {
      final result = await AiGatewayApi.generateChargesheet(
        incidentText: _incidentController.text.trim(),
        stationName: _stationController.text.trim(),
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
        const Text('Chargesheet Generation', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('AI-powered chargesheet drafting from incident data', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 20),

        TextField(controller: _stationController, decoration: InputDecoration(labelText: 'Station Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        const SizedBox(height: 12),
        TextField(controller: _incidentController, decoration: InputDecoration(labelText: 'Incident Details / FIR Text', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 6),
        const SizedBox(height: 12),
        TextField(controller: _instructionsController, decoration: InputDecoration(labelText: 'Additional Instructions (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), maxLines: 2),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _generate,
            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.gavel),
            label: Text(_isLoading ? 'Generating...' : 'Generate Chargesheet'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),

        if (_result != null) ...[
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Generated Chargesheet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            SelectableText(_result!['chargesheet']?.toString() ?? _result.toString(), style: const TextStyle(height: 1.6)),
          ]))),
        ],
      ]),
    );
  }
}
