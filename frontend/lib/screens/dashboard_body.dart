import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:Dharma/screens/petition/petition_list_screen.dart';
import 'package:Dharma/screens/petition/police_petition_list_screen.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/providers/activity_provider.dart';

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
    // ✅ Access providers
    final petitionProvider = Provider.of<PetitionProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);

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
          _buildRecentActivitySection(context, activityProvider),
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

    // Define all cards
    final cards = [
      _statCard(ctx, localizations.totalPetitions, '${stats['total']}', Icons.gavel, Colors.deepPurple, PetitionFilter.all),
      _statCard(ctx, localizations.received, '${stats['received']}', Icons.call_received, Colors.blue.shade700, PetitionFilter.received),
      _statCard(ctx, localizations.inProgress, '${stats['inProgress']}', Icons.sync, Colors.orange.shade700, PetitionFilter.inProgress),
      _statCard(ctx, localizations.closed, '${stats['closed']}', Icons.task_alt, Colors.green.shade700, PetitionFilter.closed),
    ];

    if (isPolice) {
      cards.add(_statCard(ctx, localizations.escalated, '${stats['escalated'] ?? 0}', Icons.report_problem, Colors.red.shade700, PetitionFilter.escalated));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop Web View: Render in a single row (4 or 5 columns)
        if (kIsWeb && constraints.maxWidth > 900) {
          return Row(
            children: cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < cards.length - 1 ? 12.0 : 0),
                  child: card,
                ),
              );
            }).toList(),
          );
        }

        // Mobile/Default View: 2 Columns (Preserve original structure)
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 12),
                Expanded(child: cards[3]),
              ],
            ),
            if (isPolice) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[4]),
                  const SizedBox(width: 12),
                  const Spacer(),
                ],
              ),
            ],
          ],
        );
      },
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
          onTap: () {
            // Log this activity
            Provider.of<ActivityProvider>(ctx, listen: false).logActivity(
              title: title,
              icon: icon,
              route: route,
              color: iconColor,
            );
            
            print('🚀 [NAVIGATION] Pushing route: $route');
            ctx.push(route).then((_) {
              print('🔙 [NAVIGATION] Returned from: $route');
            });
          },

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
      // _quickActionCard(ctx, localizations.witnessPrep, Icons.people,
      //     '/witness-preparation', Colors.brown),
      _quickActionCard(ctx, localizations.petitions, Icons.book, '/petitions',
          Colors.red.shade800),
      _quickActionCard(ctx, localizations.helpline, Icons.phone, '/helpline',
          Colors.red.shade800),
    ];
  }

  // ── POLICE QUICK ACTIONS ──
  List<Widget> _policeActions(BuildContext ctx) {
    final localizations = AppLocalizations.of(ctx)!;
    
    // Get police rank to check if officer can submit offline petitions
    final auth = Provider.of<AuthProvider>(ctx, listen: false);
    final policeProfile = auth.userProfile;
    final policeRank = policeProfile?.rank;
    
    // Ranks eligible for offline petition submission
    final spLevelRanks = [
      'Superintendent of Police',
      'Additional Superintendent of Police',
      'Inspector General of Police',
      'Deputy Inspector General of Police',
      'Director General of Police',
      'Additional Director General of Police',
    ];
    
    final canSubmitOffline = policeRank != null && spLevelRanks.contains(policeRank);
    
    final actions = [
      _quickActionCard(ctx, localizations.documentDrafting, Icons.edit_document,
          '/document-drafting', Colors.green),
      _quickActionCard(ctx, localizations.chargesheetGen, Icons.file_present,
          '/chargesheet-generation', Colors.teal),
      _quickActionCard(ctx, localizations.chargesheetVetting, Icons.fact_check,
          '/chargesheet-vetting', Colors.indigo),
      // _quickActionCard(ctx, localizations.mediaAnalysis, Icons.image_search,
      //     '/media-analysis', Colors.cyan.shade700),
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
      _quickActionCard(ctx, localizations.petitions, Icons.gavel, '/petitions',
          Colors.red.shade800),
      _quickActionCard(ctx, localizations.mySavedComplaints, Icons.archive,
          '/complaints', Colors.orange.shade700),

      _quickActionCard(
          ctx, localizations.imageLab, Icons.camera_alt, '/image-lab', Colors.deepPurple),
      _quickActionCard(
          ctx, localizations.addPolice, Icons.person_add, '/signup/police', Colors.blueGrey.shade700),
    ];
    
    // Add offline petition submission if officer is SP-level or above
    if (canSubmitOffline) {
      actions.insert(
        0, // Add at the beginning for prominence
        _quickActionCard(
          ctx,
          localizations.submitOfflinePetition,
          Icons.post_add,
          '/submit-offline-petition',
          Colors.teal.shade600,
        ),
      );
      
      // Add Offline Petitions (Sent & Assigned) button for high-level officers
      actions.insert(
        1, // Add right after Submit Offline Petition
        _quickActionCard(
          ctx,
          localizations.offlinePetitions,
          Icons.assignment,
          '/offline-petitions',
          Colors.purple.shade600,
        ),
      );
    } else {
      // For low-level officers, add view-only Assigned Petitions button
      actions.insert(
        0,
        _quickActionCard(
          ctx,
          localizations.assignedPetitions,
          Icons.assignment,
          '/offline-petitions',
          Colors.purple.shade600,
        ),
      );
    }

    
    return actions;
  }


  // ── RECENT ACTIVITY SECTION ──
  Widget _buildRecentActivitySection(BuildContext ctx, ActivityProvider provider) {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, _) {
        final displayItems = activityProvider.activities.take(3).toList();

        if (displayItems.isEmpty) {
          return _noActivityCard(ctx);
        }

        return SizedBox(
          height: 120, // Slightly more compact
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final activity = displayItems[index];
              return _userActivityCard(ctx, activity);
            },
          ),
        );
      },
    );
  }

  Widget _userActivityCard(BuildContext ctx, UserActivity activity) {
    final theme = Theme.of(ctx);
    
    return Container(
      width: MediaQuery.of(ctx).size.width * 0.7,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => ctx.push(activity.route),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (activity.color ?? orange).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activity.icon,
                    color: activity.color ?? orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getLocalizedActivityTitle(ctx, activity.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(activity.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _noActivityCard(BuildContext ctx) {
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

  String _getLocalizedActivityTitle(BuildContext context, String title) {
    final localizations = AppLocalizations.of(context)!;
    
    // Map activity titles to localization keys
    switch (title) {
      case "AI Chat":
        return localizations.aiChat;
      case "Legal Queries":
        return localizations.legalQueries;
      case "Helpline":
        return localizations.helpline;
      case "Legal Section Suggestions":
        return localizations.legalSuggestion;
      case "Document Drafting":
        return localizations.documentDrafting;
      case "Chargesheet Gen":
        return localizations.chargesheetGen;
      case "Chargesheet Vetting":
        return localizations.chargesheetVetting;
      case "Witness Prep":
        return localizations.witnessPrep;
      case "Media Analysis":
        return localizations.mediaAnalysis;
      case "Crime Scene":
        return localizations.mediaAnalysis;
      case "Cases":
        return localizations.cases;
      case "Complaints":
        return localizations.complaints;
      case "Petitions":
        return localizations.petitions;
      default:
        return title;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays == 1) return "Yesterday";
    return "${date.day}/${date.month}/${date.year}";
  }

  Color _getFilterColor(PetitionFilter filter) {
    switch (filter) {
      case PetitionFilter.all:
        return Colors.deepPurple;
      case PetitionFilter.received:
        return Colors.blue.shade700;
      case PetitionFilter.inProgress:
        return Colors.orange.shade700;
      case PetitionFilter.closed:
        return Colors.green.shade700;
      case PetitionFilter.escalated:
        return Colors.red.shade700;
    }
  }
}
