import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/case_status.dart';

class DashboardBody extends StatelessWidget {
  final AuthProvider auth;
  final CaseProvider cases;
  final ThemeData theme;
  final bool isPolice;

  const DashboardBody({
    required this.auth,
    required this.cases,
    required this.theme,
    required this.isPolice,
    super.key,
  });

  // Orange only for text & highlights
  static const Color orange = Color(0xFFFC633C);

  @override
  Widget build(BuildContext context) {
    // ✅ Access petition provider (for police dashboard)
    final petitionProvider = Provider.of<PetitionProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${auth.userProfile?.displayName ?? "User"}!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPolice ? 'Police Command Centre' : 'Your Legal Assistance Hub',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // ✅ Stats Row (with petition count if police)
          _buildStatsRow(context, petitionProvider),

          const SizedBox(height: 32),

          Text('Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(color: orange)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                isPolice ? _policeActions(context) : _citizenActions(context),
          ),

          const SizedBox(height: 32),

          Text('Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(color: orange)),
          const SizedBox(height: 16),
          _recentActivityCard(context),
        ],
      ),
    );
  }

  // ── STATISTICS ROW ──
  Widget _buildStatsRow(BuildContext ctx, PetitionProvider petitionProvider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                ctx,
                'Total Cases',
                '${cases.cases.length}',
                Icons.folder_open,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _statCard(
                ctx,
                'Active Cases',
                '${cases.cases.where((c) => c.status != CaseStatus.closed && c.status != CaseStatus.resolved).length}',
                Icons.pending_actions,
                Colors.orange.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard(
                ctx,
                'Closed Cases',
                '${cases.cases.where((c) => c.status == CaseStatus.closed).length}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),

            // ✅ Show petition count only for police
            Expanded(
              child: _statCard(
                ctx,
                'Total Petitions',
                isPolice
                    ? '${petitionProvider.petitionCount}'
                    : '0', // show real data for police only
                Icons.gavel,
                Colors.red.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
      BuildContext ctx, String title, String value, IconData icon, Color iconColor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 32),
                Text(
                  value,
                  style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: orange,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: Theme.of(ctx)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  // ── QUICK ACTION CARD ──
  Widget _quickActionCard(BuildContext ctx, String title, IconData icon,
      String route, Color iconColor) {
    return SizedBox(
      width: (MediaQuery.of(ctx).size.width - 48) / 2,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => ctx.go(route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: iconColor, size: 40),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── CITIZEN QUICK ACTIONS ──
  List<Widget> _citizenActions(BuildContext ctx) => [
        _quickActionCard(ctx, 'AI Chat', Icons.chat, '/chat', Colors.blue),
        _quickActionCard(
            ctx, 'Legal Queries', Icons.psychology, '/legal-queries', Colors.purple),
        _quickActionCard(ctx, 'View Cases', Icons.folder_open, '/cases', Colors.blue),
        _quickActionCard(ctx, 'Complaints', Icons.archive, '/complaints', Colors.orange.shade700),
        _quickActionCard(ctx, 'Legal Suggestion', Icons.gavel, '/legal-suggestion', Colors.red.shade700),
        _quickActionCard(ctx, 'Document Drafting', Icons.edit_document, '/document-drafting', Colors.green),
        _quickActionCard(ctx, 'Chargesheet Gen', Icons.file_present, '/chargesheet-generation', Colors.teal),
        _quickActionCard(ctx, 'Chargesheet Vetting', Icons.fact_check, '/chargesheet-vetting', Colors.indigo),
        _quickActionCard(ctx, 'Witness Prep', Icons.people, '/witness-preparation', Colors.brown),
        _quickActionCard(ctx, 'Media Analysis', Icons.image_search, '/media-analysis', Colors.cyan.shade700),
        _quickActionCard(ctx, 'Case Journal', Icons.book, '/case-journal', Colors.deepOrange),
        _quickActionCard(ctx, 'Petitions', Icons.gavel, '/petitions', Colors.red.shade800),
      ];

  // ── POLICE QUICK ACTIONS ──
  List<Widget> _policeActions(BuildContext ctx) => [
        _quickActionCard(ctx, 'Case Management', Icons.folder_open, '/cases', Colors.blue),
        _quickActionCard(ctx, 'Complaints', Icons.archive, '/complaints', Colors.orange.shade700),
        _quickActionCard(ctx, 'AI Tools', Icons.psychology, '/ai-tools', Colors.purple),
        _quickActionCard(ctx, 'Document Drafting', Icons.edit_document, '/document-drafting', Colors.green),
        _quickActionCard(ctx, 'Chargesheet Tools', Icons.file_present, '/chargesheet-generation', Colors.teal),
        _quickActionCard(ctx, 'Media Analysis', Icons.image_search, '/media-analysis', Colors.cyan.shade700),
      ];

  // ── RECENT ACTIVITY ──
  Widget _recentActivityCard(BuildContext ctx) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.history, size: 40, color: Colors.grey[400]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No recent activity',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your recent cases and queries will appear here',
                    style: Theme.of(ctx)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
