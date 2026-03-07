import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:Dharma/screens/petition/petition_list_screen.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/providers/activity_provider.dart';

class DashboardBody extends StatefulWidget {
  final AuthProvider auth;
  final ThemeData theme;
  const DashboardBody({
    required this.auth,
    required this.theme,
    super.key,
  });

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  int _currentPage = 0;
  // Orange only for text & highlights
  static const Color orange = Color(0xFFFC633C);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final petitionProvider = Provider.of<PetitionProvider>(context);
    final activityProvider = Provider.of<ActivityProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${localizations.welcome}, ${widget.auth.userProfile?.displayName ?? "User"}!',
            style: widget.theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.yourLegalAssistanceHub,
            style: widget.theme.textTheme.bodyLarge
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // ✅ Stats Row (with petition count if police)
          _buildStatsRow(context, petitionProvider),

          const SizedBox(height: 32),

          Text(localizations.quickActions,
              style:
                  widget.theme.textTheme.titleLarge?.copyWith(color: orange)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 130, // Fixed height for all boxes
            ),
            itemCount: _citizenActions(context).length,
            itemBuilder: (context, index) => _citizenActions(context)[index],
          ),

          const SizedBox(height: 32),

          // Header with navigation arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(localizations.recentActivity,
                  style: widget.theme.textTheme.titleLarge
                      ?.copyWith(color: orange)),
              if (activityProvider.activities.isNotEmpty)
                _buildPaginationControls(activityProvider.activities.length),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecentActivitySection(context, activityProvider),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(int totalItems) {
    return LayoutBuilder(builder: (context, constraints) {
      final itemsPerPage = _getItemsPerPage(MediaQuery.of(context).size.width);
      final totalPages = (totalItems / itemsPerPage).ceil();

      if (totalPages <= 1) return const SizedBox.shrink();

      return Row(
        children: [
          _paginationButton(
            icon: Icons.chevron_left,
            enabled: _currentPage > 0,
            onPressed: () => setState(() => _currentPage--),
          ),
          Text(
            '${_currentPage + 1} / $totalPages',
            style: widget.theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          _paginationButton(
            icon: Icons.chevron_right,
            enabled: _currentPage < totalPages - 1,
            onPressed: () => setState(() => _currentPage++),
          ),
        ],
      );
    });
  }

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: enabled ? orange : Colors.grey[300],
      onPressed: enabled ? onPressed : null,
      visualDensity: VisualDensity.compact,
    );
  }

  int _getItemsPerPage(double width) {
    if (width > 1200) return 3; // Desktop
    if (width > 600) return 2; // Tablet
    return 1; // Mobile
  }

  // ── STATISTICS ROW ──
  Widget _buildStatsRow(BuildContext ctx, PetitionProvider petitionProvider) {
    final localizations = AppLocalizations.of(ctx)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.petitionOverview,
            style: widget.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.grey[800])),
        const SizedBox(height: 12),
        _buildPetitionStatsGrid(ctx, petitionProvider),
      ],
    );
  }

  Widget _buildPetitionStatsGrid(
      BuildContext ctx, PetitionProvider petitionProvider) {
    final localizations = AppLocalizations.of(ctx)!;
    // Citizen sees only their stats
    final stats = petitionProvider.userStats;

    // Define all cards
    final cards = [
      _statCard(ctx, localizations.totalPetitions, '${stats['total']}',
          Icons.gavel, Colors.deepPurple, PetitionFilter.all),
      _statCard(ctx, localizations.received, '${stats['received']}',
          Icons.call_received, Colors.blue.shade700, PetitionFilter.received),
      _statCard(ctx, localizations.inProgress, '${stats['inProgress']}',
          Icons.sync, Colors.orange.shade700, PetitionFilter.inProgress),
      _statCard(ctx, localizations.closed, '${stats['closed']}', Icons.task_alt,
          Colors.green.shade700, PetitionFilter.closed),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop Web View: Render in a single row (4 columns)
        if (kIsWeb && constraints.maxWidth > 900) {
          return Row(
            children: cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: index < cards.length - 1 ? 12.0 : 0),
                  child: card,
                ),
              );
            }).toList(),
          );
        }

        // Mobile/Default View: 2 Columns
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
              builder: (context) => CitizenPetitionListScreen(
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
    return Card(
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

          ctx.push(route).then((_) {});
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 40),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(ctx)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
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
      _quickActionCard(ctx, localizations.mySavedComplaints, Icons.archive,
          '/complaints', Colors.orange.shade700),
      _quickActionCard(ctx, localizations.petitions, Icons.book, '/petitions',
          Colors.red.shade800),
      _quickActionCard(ctx, localizations.helpline, Icons.phone, '/helpline',
          Colors.red.shade800),
    ];
  }

  // ── RECENT ACTIVITY SECTION ──
  Widget _buildRecentActivitySection(
      BuildContext ctx, ActivityProvider provider) {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, _) {
        final allActivities = activityProvider.activities;

        if (allActivities.isEmpty) {
          return _noActivityCard(ctx);
        }

        return LayoutBuilder(builder: (context, constraints) {
          final itemsPerPage = _getItemsPerPage(constraints.maxWidth);
          final startIndex = _currentPage * itemsPerPage;

          // Ensure current page is valid if items changed
          if (startIndex >= allActivities.length && _currentPage > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _currentPage = 0);
            });
          }

          final displayItems =
              allActivities.skip(startIndex).take(itemsPerPage).toList();

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Row(
              key: ValueKey<int>(_currentPage),
              children: displayItems.map((activity) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _userActivityCard(ctx, activity),
                  ),
                );
              }).toList()
                ..addAll(
                  // Add empty spacers to maintain layout if last page has fewer items
                  List.generate(
                    itemsPerPage - displayItems.length,
                    (_) => const Expanded(child: SizedBox.shrink()),
                  ),
                ),
            ),
          );
        });
      },
    );
  }

  Widget _userActivityCard(BuildContext ctx, UserActivity activity) {
    final theme = Theme.of(ctx);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => ctx.push(activity.route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getLocalizedActivityTitle(ctx, activity.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(activity.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey[500],
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Colors.grey[300],
              ),
            ],
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
}
