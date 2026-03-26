import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma_police/providers/case_provider.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});
  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  static const Color navy = Color(0xFF1A237E);
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CaseProvider>(context, listen: false).fetchCases();
    });
  }

  void _filterByStatus(String? status) {
    setState(() => _statusFilter = status);
    Provider.of<CaseProvider>(context, listen: false).fetchCases(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final cases = Provider.of<CaseProvider>(context);

    return Column(
      children: [
        // ── Header + Filter + New Case ──
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text('Cases', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: navy)),
              const Spacer(),
              PopupMenuButton<String?>(
                icon: const Icon(Icons.filter_list),
                onSelected: _filterByStatus,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('All')),
                  const PopupMenuItem(value: 'open', child: Text('Open')),
                  const PopupMenuItem(value: 'investigation', child: Text('Investigation')),
                  const PopupMenuItem(value: 'closed', child: Text('Closed')),
                ],
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => context.push('/cases/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Case'),
                style: ElevatedButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),

        if (_statusFilter != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Chip(
              label: Text('Filter: ${_statusFilter!}'),
              onDeleted: () => _filterByStatus(null),
            ),
          ),

        // ── List ──
        Expanded(
          child: cases.isLoading
              ? const Center(child: CircularProgressIndicator())
              : cases.cases.isEmpty
                  ? Center(child: Text('No cases found', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)))
                  : RefreshIndicator(
                      onRefresh: () => cases.fetchCases(status: _statusFilter),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: cases.cases.length,
                        itemBuilder: (_, i) {
                          final c = cases.cases[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(c.status).withOpacity(0.15),
                                child: Icon(Icons.folder_open, color: _statusColor(c.status), size: 20),
                              ),
                              title: Text(c.title ?? c.firNumber ?? 'Case #${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (c.firNumber != null) Text('FIR: ${c.firNumber}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  Text(c.status.toUpperCase(), style: TextStyle(fontSize: 11, color: _statusColor(c.status), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/cases/${c.id}'),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open': return Colors.green;
      case 'closed': return Colors.red;
      case 'investigation': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
