import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma_police/providers/auth_provider.dart';
import 'package:dharma_police/providers/case_provider.dart';
import 'package:dharma_police/providers/petition_provider.dart';

class PoliceDashboardScreen extends StatefulWidget {
  const PoliceDashboardScreen({super.key});
  @override
  State<PoliceDashboardScreen> createState() => _PoliceDashboardScreenState();
}

class _PoliceDashboardScreenState extends State<PoliceDashboardScreen> {
  Timer? _refreshTimer;
  static const Color navy = Color(0xFF1A237E);
  static const Color orange = Color(0xFFFC633C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final caseProvider = Provider.of<CaseProvider>(context, listen: false);
      final petitionProvider = Provider.of<PetitionProvider>(context, listen: false);
      caseProvider.fetchCases();
      petitionProvider.fetchPetitions();

      _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) {
          caseProvider.fetchCases();
          petitionProvider.fetchPetitions();
        }
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cases = Provider.of<CaseProvider>(context);
    final petitions = Provider.of<PetitionProvider>(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome ──
          Text(
            'Welcome, ${auth.displayNameOrUsername}!',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: navy),
          ),
          const SizedBox(height: 4),
          Text(
            'Police Command Center',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          if (auth.userProfile?.rank != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: navy.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(auth.userProfile!.rank!, style: TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 24),

          // ── Stats ──
          Row(
            children: [
              _StatCard(title: 'Cases', value: '${cases.caseCount}', icon: Icons.folder_open, color: navy),
              const SizedBox(width: 12),
              _StatCard(title: 'Petitions', value: '${petitions.petitionCount}', icon: Icons.description, color: orange),
              const SizedBox(width: 12),
              _StatCard(title: 'Pending', value: '${petitions.pendingCount}', icon: Icons.pending_actions, color: Colors.amber.shade700),
            ],
          ),
          const SizedBox(height: 32),

          // ── Quick Actions ──
          Text('Quick Actions', style: theme.textTheme.titleLarge?.copyWith(color: navy, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _ActionCard(icon: Icons.folder_open, label: 'Cases', route: '/cases', color: navy),
              _ActionCard(icon: Icons.description, label: 'Petitions', route: '/petitions', color: orange),
              _ActionCard(icon: Icons.edit_document, label: 'Document\nDrafting', route: '/document-drafting', color: Colors.teal),
              _ActionCard(icon: Icons.gavel, label: 'Chargesheet\nGeneration', route: '/chargesheet', color: Colors.deepPurple),
              _ActionCard(icon: Icons.fact_check, label: 'Chargesheet\nVetting', route: '/chargesheet-vetting', color: Colors.indigo),
              _ActionCard(icon: Icons.search, label: 'Investigation\nGuidelines', route: '/investigation', color: Colors.brown),
              _ActionCard(icon: Icons.image_search, label: 'Media\nAnalysis', route: '/media-analysis', color: Colors.blueGrey),
              _ActionCard(icon: Icons.chat, label: 'Legal\nChat', route: '/chat', color: Colors.green),
            ],
          ),
          const SizedBox(height: 32),

          // ── Recent Cases ──
          Text('Recent Cases', style: theme.textTheme.titleLarge?.copyWith(color: navy, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (cases.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (cases.cases.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No cases yet', style: TextStyle(color: Colors.grey.shade500)))))
          else
            ...cases.cases.take(5).map((c) => Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: navy.withOpacity(0.1), child: Icon(Icons.folder, color: navy, size: 20)),
                title: Text(c.title ?? c.firNumber ?? 'Case', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(c.status.toUpperCase(), style: TextStyle(fontSize: 12, color: _statusColor(c.status))),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/cases/${c.id}'),
              ),
            )),
          const SizedBox(height: 24),
        ],
      ),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _ActionCard({required this.icon, required this.label, required this.route, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
