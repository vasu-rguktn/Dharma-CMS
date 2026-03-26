import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma/providers/auth_provider.dart';
import 'package:dharma/providers/petition_provider.dart';
import 'package:dharma/providers/activity_provider.dart';
import 'package:dharma/utils/petition_filter.dart';
import 'package:dharma/l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color orange = Color(0xFFFC633C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final petitions = Provider.of<PetitionProvider>(context, listen: false);
      final uid = auth.user?.uid;
      if (uid != null) {
        petitions.fetchPetitionStats(userId: uid);
        petitions.fetchFilteredPetitions(isPolice: false, userId: uid, filter: PetitionFilter.all);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final petitions = Provider.of<PetitionProvider>(context);
    final activity = Provider.of<ActivityProvider>(context);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/ai-legal-chat'),
        backgroundColor: orange,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        label: Text(l.newCase, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text('${l.welcome}, ${auth.userProfile?.displayName ?? "User"}!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: orange)),
            const SizedBox(height: 8),
            Text(l.yourLegalAssistanceHub, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 24),

            // Stats
            Text(l.petitionOverview, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            const SizedBox(height: 12),
            _buildStatsGrid(context, petitions, l),
            const SizedBox(height: 32),

            // Quick Actions
            Text(l.quickActions, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: orange)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _actionCard(context, l.aiChat, Icons.chat, '/ai-legal-chat', Colors.blue, activity),
                _actionCard(context, l.mySavedComplaints, Icons.archive, '/complaints', Colors.orange.shade700, activity),
                _actionCard(context, l.petitions, Icons.book, '/petitions', Colors.red.shade800, activity),
                _actionCard(context, l.helpline, Icons.phone, '/helpline', Colors.red.shade800, activity),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Activity
            Text(l.recentActivity, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: orange)),
            const SizedBox(height: 16),
            _buildRecentActivity(context, activity),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext ctx, PetitionProvider p, AppLocalizations l) {
    final stats = p.userStats;
    return Column(children: [
      Row(children: [
        Expanded(child: _statCard(ctx, l.totalPetitions, '${stats['total']}', Icons.gavel, Colors.deepPurple)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(ctx, l.received, '${stats['received']}', Icons.call_received, Colors.blue.shade700)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _statCard(ctx, l.inProgress, '${stats['inProgress']}', Icons.sync, Colors.orange.shade700)),
        const SizedBox(width: 12),
        Expanded(child: _statCard(ctx, l.closed, '${stats['closed']}', Icons.task_alt, Colors.green.shade700)),
      ]),
    ]);
  }

  Widget _statCard(BuildContext ctx, String title, String value, IconData icon, Color iconColor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(icon, color: iconColor, size: 32),
            Text(value, style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: orange)),
          ]),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600])),
        ]),
      ),
    );
  }

  Widget _actionCard(BuildContext ctx, String title, IconData icon, String route, Color color, ActivityProvider activity) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () { activity.logActivity(title: title, icon: icon, route: route, color: color); ctx.push(route); },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext ctx, ActivityProvider provider) {
    final items = provider.activities.take(3).toList();
    if (items.isEmpty) return Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(Icons.history, size: 40, color: Colors.grey[400]), const SizedBox(width: 16), const Expanded(child: Text('No recent activity'))])));
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final a = items[i];
          return Container(
            width: MediaQuery.of(ctx).size.width * 0.7,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => ctx.push(a.route),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (a.color ?? orange).withOpacity(0.1), shape: BoxShape.circle), child: Icon(a.icon, color: a.color ?? orange, size: 24)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_formatDate(a.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ])),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }
}
