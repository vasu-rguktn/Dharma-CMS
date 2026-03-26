import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dharma_police/providers/petition_provider.dart';

class PolicePetitionsScreen extends StatefulWidget {
  const PolicePetitionsScreen({super.key});
  @override
  State<PolicePetitionsScreen> createState() => _PolicePetitionsScreenState();
}

class _PolicePetitionsScreenState extends State<PolicePetitionsScreen> {
  static const Color navy = Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PetitionProvider>(context, listen: false).fetchPetitions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final petitions = Provider.of<PetitionProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text('Petitions', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: navy)),
            const Spacer(),
            Chip(label: Text('Total: ${petitions.petitionCount}'), backgroundColor: navy.withOpacity(0.1)),
          ]),
        ),

        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _StatChip('Pending', petitions.pendingCount, Colors.amber),
            const SizedBox(width: 8),
            _StatChip('In Progress', petitions.inProgressCount, Colors.blue),
            const SizedBox(width: 8),
            _StatChip('Closed', petitions.closedCount, Colors.green),
          ]),
        ),
        const SizedBox(height: 12),

        Expanded(
          child: petitions.isLoading
              ? const Center(child: CircularProgressIndicator())
              : petitions.petitions.isEmpty
                  ? Center(child: Text('No petitions found', style: TextStyle(color: Colors.grey.shade500)))
                  : RefreshIndicator(
                      onRefresh: () => petitions.fetchPetitions(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: petitions.petitions.length,
                        itemBuilder: (_, i) {
                          final p = petitions.petitions[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(p.status).withOpacity(0.15),
                                child: Icon(Icons.description, color: _statusColor(p.status), size: 20),
                              ),
                              title: Text(p.subject ?? p.petitionNumber ?? 'Petition #${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (p.petitionerName != null) Text('By: ${p.petitionerName}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  Text(p.status.toUpperCase(), style: TextStyle(fontSize: 11, color: _statusColor(p.status), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (status) => petitions.updatePetitionStatus(p.id, status),
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'acknowledged', child: Text('Acknowledge')),
                                  const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
                                  const PopupMenuItem(value: 'closed', child: Text('Close')),
                                ],
                              ),
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
      case 'pending': return Colors.amber.shade700;
      case 'acknowledged': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'closed': return Colors.green;
      default: return Colors.grey;
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Column(children: [
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ]),
      ),
    );
  }
}
