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
    // Debug info: print profile state during builds
    debugPrint('AppScaffold build -> isProfileLoading=${authProvider.isProfileLoading}, userProfile=${authProvider.userProfile}, profile.displayName=${authProvider.userProfile?.displayName}, profile.username=${authProvider.userProfile?.username}, firebaseDisplay=${authProvider.user?.displayName}');
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final dashboardRoute = authProvider.role == 'police' ? '/police-dashboard' : '/dashboard';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(localizations.dharma??'Dharma'),
        actions: [
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Use provider getter directly
                    CircleAvatar(child: Text((authProvider.displayNameOrUsername.isNotEmpty ? authProvider.displayNameOrUsername[0].toUpperCase() : 'U'))),
                    const SizedBox(width: 8),
                    // Show spinner while profile is loading so we don't show the fallback 'User' prematurely
                    authProvider.isProfileLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(authProvider.displayNameOrUsername),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            onSelected: (value) {
              if (value == 'signout') {
                authProvider.signOut();
                context.go('/login');
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
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.sidebarBackground(isDark),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.sidebarBackground(isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.balance, size: 48, color: AppTheme.sidebarForeground(isDark)),
                  const SizedBox(height: 8),
                  Text(
                    localizations.dharma ?? 'Dharma',
                    style: TextStyle(color: AppTheme.sidebarForeground(isDark), fontSize: 20),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(context, Icons.dashboard, localizations.dashboard, dashboardRoute, isDark),
            
            _buildDrawerSection(localizations.aiTools, isDark),
            _buildDrawerItem(context, Icons.chat, localizations.aiChat, '/ai-legal-chat', isDark),
            
            // Police users see a concise menu that mirrors the Quick Actions
            // shown on the Police dashboard to avoid duplication and confusion.
            if (authProvider.role == 'police') ...[
              _buildDrawerItem(context, Icons.folder_open, localizations.allCases, '/cases', isDark),
              _buildDrawerItem(context, Icons.archive, localizations.mySavedComplaints, '/complaints', isDark),
              // Dashboard uses '/ai-tools' but router exposes '/ai-legal-chat' — map to an existing route
              _buildDrawerItem(context, Icons.psychology, localizations.aiTools, '/ai-legal-chat', isDark),
              _buildDrawerItem(context, Icons.edit_document, localizations.documentDrafting, '/document-drafting', isDark),
              _buildDrawerItem(context, Icons.file_present, localizations.chargesheetGen, '/chargesheet-generation', isDark),
              _buildDrawerItem(context, Icons.image_search, localizations.mediaAnalysis, '/media-analysis', isDark),
            ] else if (authProvider.role == 'admin') ...[
              // Admins keep the full advanced menu
              _buildDrawerItem(context, Icons.psychology, localizations.legalQueries, '/legal-queries', isDark),
              _buildDrawerItem(context, Icons.gavel, localizations.legalSuggestion, '/legal-suggestion', isDark),
              _buildDrawerItem(context, Icons.edit_document, localizations.documentDrafting, '/document-drafting', isDark),
              _buildDrawerItem(context, Icons.file_present, localizations.chargesheetGen, '/chargesheet-generation', isDark),
              _buildDrawerItem(context, Icons.fact_check, localizations.chargesheetVetting, '/chargesheet-vetting', isDark),
              _buildDrawerItem(context, Icons.people, localizations.witnessPrep, '/witness-preparation', isDark),
              _buildDrawerItem(context, Icons.image_search, localizations.mediaAnalysis, '/media-analysis', isDark),
            ],

            _buildDrawerSection(localizations.caseManagement, isDark),
            _buildDrawerItem(context, Icons.folder_open, localizations.allCases, '/cases', isDark),
            
            if (authProvider.role == 'admin' || authProvider.role == 'police')
              _buildDrawerItem(context, Icons.book, localizations.caseJournal, '/case-journal', isDark),
            
            _buildDrawerItem(context, Icons.gavel, localizations.petitions, '/petitions', isDark),
            _buildDrawerItem(context, Icons.archive, localizations.mySavedComplaints, '/complaints', isDark),
            const Divider(),
            _buildDrawerItem(context, Icons.settings, localizations.settings, '/settings', isDark),
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

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
    bool isDark,
  ) {
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
        Navigator.of(context).pop();
        context.go(route);
      },
    );
  }
}
