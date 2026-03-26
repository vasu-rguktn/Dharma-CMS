import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma_police/services/api/cases_api.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});
  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  static const Color navy = Color(0xFF1A237E);
  Map<String, dynamic>? _caseData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCase();
  }

  Future<void> _loadCase() async {
    try {
      final data = await CasesApi.getCase(widget.caseId);
      setState(() { _caseData = data; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_caseData == null) return const Center(child: Text('Case not found'));

    final c = _caseData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            const SizedBox(width: 8),
            Expanded(child: Text(c['title'] ?? 'Case Detail', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 16),          _infoCard('Case Information', [
            _row('Case Ref', c['case_reference']),
            _row('FIR Number', c['fir_number']),
            _row('Status', c['status']),
            _row('Station', c['police_station'] ?? c['station_name']),
            _row('District', c['district']),
            _row('Acts & Sections', c['acts_and_sections_text'] ?? c['crime_type']),
            _row('Date Filed', c['date_filed']?.toString()),
            _row('Created', c['created_at']?.toString().substring(0, 10)),
          ]),
          const SizedBox(height: 16),

          if (c['incident_details'] != null || c['description'] != null) ...[
            _infoCard('Incident Details', [
              Padding(padding: const EdgeInsets.all(12), child: Text(c['incident_details'] ?? c['description'] ?? '', style: const TextStyle(height: 1.5))),
            ]),
            const SizedBox(height: 16),
          ],

          if (c['complaint_statement'] != null) ...[
            _infoCard('Complaint Statement', [
              Padding(padding: const EdgeInsets.all(12), child: Text(c['complaint_statement'], style: const TextStyle(height: 1.5))),
            ]),
            const SizedBox(height: 16),
          ],

          // Action buttons
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/investigation', extra: {'caseId': widget.caseId}),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Investigation'),
                style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/chargesheet', extra: {'caseId': widget.caseId}),
                icon: const Icon(Icons.gavel, size: 18),
                label: const Text('Chargesheet'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              ),
            ),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navy)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
