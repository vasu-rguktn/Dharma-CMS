import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:Dharma/screens/petition/petition_list_screen.dart';
import 'package:Dharma/screens/petition/police_petition_list_screen.dart';

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
    final localizations = AppLocalizations.of(context)!;
    // ✅ Access petition provider (for police dashboard)
    final petitionProvider = Provider.of<PetitionProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${localizations.welcome}, ${auth.userProfile?.displayName ?? "User"}!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPolice
                ? localizations.policeCommandCenter
                : localizations.yourLegalAssistanceHub,
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // ✅ Stats Row (with petition count if police)
          _buildStatsRow(context, petitionProvider),

          const SizedBox(height: 32),

          Text(localizations.quickActions,
              style: theme.textTheme.titleLarge?.copyWith(color: orange)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                isPolice ? _policeActions(context) : _citizenActions(context),
          ),

          const SizedBox(height: 32),

          Text(localizations.recentActivity,
              style: theme.textTheme.titleLarge?.copyWith(color: orange)),
          const SizedBox(height: 16),
          _recentActivityCard(context),
        ],
      ),
    );
  }

  // ── STATISTICS ROW ──
  // ── STATISTICS SECTION ──
  Widget _buildStatsRow(BuildContext ctx, PetitionProvider petitionProvider) {
    final localizations = AppLocalizations.of(ctx)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PETITIONS SECTION
        // Since Cases are removed, we can either keep the header or remove it.
        // Showing "Petition Overview" is still helpful for context.
        Text(localizations.petitionOverview,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.grey[800])),
        const SizedBox(height: 12),
        _buildPetitionStatsGrid(ctx, petitionProvider),
      ],
    );
  }

  Widget _buildPetitionStatsGrid(
      BuildContext ctx, PetitionProvider petitionProvider) {
    final localizations = AppLocalizations.of(ctx)!;
    // Select stats based on role
    final stats =
        isPolice ? petitionProvider.globalStats : petitionProvider.userStats;

    // For Citizen, if stats are 0, it might mean they haven't loaded yet OR they have 0.
    // We display whatever is in the provider. Authentication check logic resides in the Screen.

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                ctx,
                localizations.totalPetitions,
                '${stats['total']}',
                Icons.gavel,
                Colors.deepPurple,
                PetitionFilter.all,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                ctx,
                localizations.received,
                '${stats['received']}',
                Icons.call_received,
                Colors.blue.shade700,
                PetitionFilter.received,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                ctx,
                localizations.inProgress,
                '${stats['inProgress']}',
                Icons.sync,
                Colors.orange.shade700,
                PetitionFilter.inProgress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                ctx,
                localizations.closed,
                '${stats['closed']}',
                Icons.task_alt,
                Colors.green.shade700,
                PetitionFilter.closed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext ctx,
    String title,
    String value,
    IconData icon,
    Color iconColor,
    PetitionFilter filter,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to the petition list screen
          Navigator.of(ctx).push(
            MaterialPageRoute(
              builder: (context) => isPolice
                  ? PolicePetitionListScreen(
                      filter: filter,
                      title: title,
                    )
                  : CitizenPetitionListScreen(
                      filter: filter,
                      title: title,
                    ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
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
          // onTap: () => ctx.go(route),
          onTap: () => GoRouter.of(ctx).go(route),

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
  List<Widget> _citizenActions(BuildContext ctx) {
    final localizations = AppLocalizations.of(ctx)!;
    return [
      _quickActionCard(
          ctx, localizations.aiChat, Icons.chat, '/ai-legal-chat', Colors.blue),
      _quickActionCard(ctx, localizations.legalQueries, Icons.psychology,
          '/legal-queries', Colors.purple),
      _quickActionCard(ctx, localizations.legalSuggestion, Icons.gavel,
          '/legal-suggestion', Colors.red.shade700),
      _quickActionCard(ctx, localizations.mySavedComplaints, Icons.archive,
          '/complaints', Colors.orange.shade700),
      _quickActionCard(ctx, localizations.witnessPrep, Icons.people,
          '/witness-preparation', Colors.brown),
      _quickActionCard(ctx, localizations.petitions, Icons.book, '/petitions',
          Colors.red.shade800),
      _quickActionCard(ctx, localizations.helpline, Icons.phone, '/helpline',
          Colors.red.shade800),
    ];
  }

  // ── POLICE QUICK ACTIONS ──
  List<Widget> _policeActions(BuildContext ctx) {
    final localizations = AppLocalizations.of(ctx)!;
    return [
      _quickActionCard(ctx, localizations.documentDrafting, Icons.edit_document,
          '/document-drafting', Colors.green),
      _quickActionCard(ctx, localizations.chargesheetGen, Icons.file_present,
          '/chargesheet-generation', Colors.teal),
      _quickActionCard(ctx, localizations.chargesheetVetting, Icons.fact_check,
          '/chargesheet-vetting', Colors.indigo),
      _quickActionCard(ctx, localizations.mediaAnalysis, Icons.image_search,
          '/media-analysis', Colors.cyan.shade700),
      _quickActionCard(ctx, localizations.caseJournal, Icons.book,
          '/case-journal', Colors.deepOrange),
      _quickActionCard(
        ctx,
        localizations.aiInvestigationGuidelines,
        Icons.rule,
        '/ai-investigation-guidelines',
        Colors.deepPurple,
      ),
      _quickActionCard(ctx, localizations.allCases, Icons.file_copy_rounded,
          '/cases', Colors.blue.shade700),
      _quickActionCard(ctx, localizations.complaints, Icons.archive,
          '/complaints', Colors.orange.shade700),
      _quickActionCard(ctx, localizations.petitions, Icons.gavel, '/petitions',
          Colors.red.shade800),
      _quickActionCard(
          ctx, "Image Lab", Icons.camera_alt, '/image-lab', Colors.deepPurple),
    ];
  }

  // ── RECENT ACTIVITY ──
  Widget _recentActivityCard(BuildContext ctx) {
    final localizations = AppLocalizations.of(ctx)!;
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
                    localizations.noRecentActivity,
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizations.recentActivityDescription,
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
