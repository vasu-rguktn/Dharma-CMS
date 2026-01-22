import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/config/theme.dart';
import 'package:Dharma/l10n/app_localizations.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    final dashboardRoute =
        authProvider.role == 'police' ? '/police-dashboard' : '/dashboard';

    // Police-specific permission checks for offline petitions
    bool canSubmitOffline = false;
    String offlinePetitionsTitle = 'Assigned Petitions';
    if (authProvider.role == 'police' && authProvider.userProfile != null) {
      final policeRank = authProvider.userProfile?.rank;
      final spLevelRanks = [
        'Superintendent of Police',
        'Additional Superintendent of Police',
        'Inspector General of Police',
        'Deputy Inspector General of Police',
        'Director General of Police',
        'Additional Director General of Police',
      ];
      canSubmitOffline = policeRank != null && spLevelRanks.contains(policeRank);
      if (canSubmitOffline) {
        offlinePetitionsTitle = 'Offline Petitions';
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Builder(
          builder: (context) {
            // On mobile (narrow screens), adjust spacing
            final screenWidth = MediaQuery.of(context).size.width;
            final isMobile = screenWidth < 600;
            return Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/police_logo.png',
                  height: isMobile ? 28 : 32,
                  width: isMobile ? 28 : 32,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.balance,
                      size: isMobile ? 28 : 32,
                      color: Theme.of(context).primaryColor,
                    );
                  },
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Flexible(
                  child: Text(
                    localizations.dharma ?? 'Dharma',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isMobile = screenWidth < 600;
              return PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 4.0 : 8.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: isMobile ? 16 : 18,
                        child: Text(
                          (authProvider.displayNameOrUsername.isNotEmpty
                                  ? authProvider.displayNameOrUsername[0]
                                  : 'U')
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 8),
                        authProvider.isProfileLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Flexible(
                                child: Text(
                                  authProvider.displayNameOrUsername,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ] else ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ],
                  ),
                ),
                onSelected: (value) {
                  if (value == 'signout') {
                    final isPolice = authProvider.role == 'police';
                    authProvider.signOut();
                    context.go(isPolice ? '/police-login' : '/phone-login');
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        const Icon(Icons.logout),
                        const SizedBox(width: 8),
                        Text(localizations.signOut),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),

      drawer: Drawer(
        backgroundColor: AppTheme.sidebarBackground(isDark),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration:
                  BoxDecoration(color: AppTheme.sidebarBackground(isDark)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.balance,
                      size: 48, color: AppTheme.sidebarForeground(isDark)),
                  const SizedBox(height: 8),
                  Text(
                    localizations.dharma ?? 'Dharma',
                    style: TextStyle(
                        color: AppTheme.sidebarForeground(isDark),
                        fontSize: 20),
                  ),
                ],
              ),
            ),

            // Dashboard - always visible
            _buildDrawerItem(context, Icons.dashboard,
                localizations.dashboard, dashboardRoute, isDark),

            // Citizen Menu
            if (authProvider.role == 'citizen') ...[
              _buildDrawerSection(localizations.aiTools, isDark),
              _buildDrawerItem(context, Icons.chat, localizations.aiChat,
                  '/ai-legal-chat', isDark),
              _buildDrawerItem(context, Icons.psychology,
                  localizations.legalQueries, '/legal-queries', isDark),
              _buildDrawerItem(context, Icons.gavel,
                  localizations.legalSuggestion, '/legal-suggestion', isDark),

              _buildDrawerSection(localizations.caseManagement, isDark),
              _buildDrawerItem(context, Icons.archive,
                  localizations.mySavedComplaints, '/complaints', isDark),
              // _buildDrawerItem(context, Icons.people,
              //     localizations.witnessPrep, '/witness-preparation', isDark),
              _buildDrawerItem(context, Icons.book, localizations.petitions,
                  '/petitions', isDark),
              _buildDrawerItem(context, Icons.phone, localizations.support,
                  '/helpline', isDark),
            ],

            // Police Menu
            if (authProvider.role == 'police') ...[
              _buildDrawerSection(localizations.aiTools, isDark),
              _buildDrawerItem(context, Icons.edit_document,
                  localizations.documentDrafting, '/document-drafting', isDark),
              _buildDrawerItem(context, Icons.file_present,
                  localizations.chargesheetGen, '/chargesheet-generation', isDark),
              _buildDrawerItem(context, Icons.fact_check,
                  localizations.chargesheetVetting, '/chargesheet-vetting', isDark),
              // _buildDrawerItem(context, Icons.image_search,
              //     localizations.mediaAnalysis, '/media-analysis', isDark),
              _buildDrawerItem(context, Icons.search,
                  localizations.aiInvestigationGuidelines, '/ai-investigation-guidelines', isDark),
              _buildDrawerItem(context, Icons.book,
                  localizations.caseJournal, '/case-journal', isDark),

              _buildDrawerSection(localizations.caseManagement, isDark),
              
              // Offline Petitions Section
              if (canSubmitOffline)
                _buildDrawerItem(context, Icons.post_add, 'Submit Offline Petition',
                    '/submit-offline-petition', isDark),
              
              _buildDrawerItem(context, Icons.assignment, offlinePetitionsTitle,
                  '/offline-petitions', isDark),

               _buildDrawerItem(context, Icons.file_copy_rounded,
                  localizations.allCases, '/cases', isDark),
              _buildDrawerItem(context, Icons.archive,
                  localizations.mySavedComplaints, '/complaints', isDark),
              _buildDrawerItem(context, Icons.gavel, localizations.petitions,
                  '/petitions', isDark),
            ],

            const Divider(),
            _buildDrawerItem(context, Icons.settings, localizations.settings,
                '/settings', isDark),
          ],
        ),
      ),

      body: widget.child,
    );
  }

  Widget _buildDrawerSection(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.sidebarForeground(isDark).withOpacity(0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title,
      String route, bool isDark) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isActive = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive
            ? Theme.of(context).primaryColor
            : AppTheme.sidebarForeground(isDark),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive
              ? Theme.of(context).primaryColor
              : AppTheme.sidebarForeground(isDark),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      onTap: () {
        print('📂 [SIDEBAR] Navigating to: $route');
        print('📚 [SIDEBAR] Can pop before navigation: ${Navigator.of(context).canPop()}');
        
        // Safely close the drawer if it's open, then navigate.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Use push instead of go to preserve navigation stack
        context.push(route).then((_) {
          print('🔙 [SIDEBAR] Returned from: $route');
        });
      },
    );
  }
}
