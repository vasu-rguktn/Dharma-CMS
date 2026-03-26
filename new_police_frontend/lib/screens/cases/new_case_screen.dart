import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma_police/providers/case_provider.dart';

class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});
  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> {
  static const Color navy = Color(0xFF1A237E);
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _firController = TextEditingController();
  final _descController = TextEditingController();
  final _stationController = TextEditingController();
  final _districtController = TextEditingController();
  String _crimeType = 'Theft';
  bool _isLoading = false;

  static const _crimeTypes = ['Theft', 'Assault', 'Fraud', 'Murder', 'Kidnapping', 'Cyber Crime', 'Drug Offence', 'Other'];

  @override
  void dispose() { _titleController.dispose(); _firController.dispose(); _descController.dispose(); _stationController.dispose(); _districtController.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cp = Provider.of<CaseProvider>(context, listen: false);      await cp.createCase({
        'title': _titleController.text.trim(),
        'fir_number': _firController.text.trim(),
        'incident_details': _descController.text.trim(),
        'police_station': _stationController.text.trim(),
        'district': _districtController.text.trim(),
        'acts_and_sections_text': _crimeType,
        'status': 'open',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Case created!'), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
              const SizedBox(width: 8),
              const Text('New Case', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 20),

            TextFormField(controller: _titleController, decoration: _dec('Case Title'), validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _firController, decoration: _dec('FIR Number')),
            const SizedBox(height: 12),
            TextFormField(controller: _descController, decoration: _dec('Description'), maxLines: 4),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _crimeType,
              decoration: _dec('Crime Type'),
              items: _crimeTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _crimeType = v ?? 'Other'),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _stationController, decoration: _dec('Station Name')),
            const SizedBox(height: 12),
            TextFormField(controller: _districtController, decoration: _dec('District')),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                    : const Text('Create Case', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
}
