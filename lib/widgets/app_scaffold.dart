import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:nyay_setu_flutter/providers/auth_provider.dart';
import 'package:nyay_setu_flutter/config/theme.dart';

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

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text('Dharma'),
        actions: [
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      (authProvider.userProfile?.displayName ?? 'U')[0].toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(authProvider.userProfile?.displayName ?? 'User'),
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
                  children: const [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
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
                    'Dharma',
                    style: TextStyle(color: AppTheme.sidebarForeground(isDark), fontSize: 20),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(context, Icons.dashboard, 'Dashboard', '/dashboard', isDark),
            _buildDrawerSection('AI Tools', isDark),
            _buildDrawerItem(context, Icons.chat, 'AI Chat', '/chat', isDark),
            _buildDrawerItem(context, Icons.psychology, 'Legal Queries', '/legal-queries', isDark),
            _buildDrawerItem(context, Icons.gavel, 'Legal Suggestion', '/legal-suggestion', isDark),
            _buildDrawerItem(context, Icons.edit_document, 'Document Drafting', '/document-drafting', isDark),
            _buildDrawerItem(context, Icons.file_present, 'Chargesheet Gen', '/chargesheet-generation', isDark),
            _buildDrawerItem(context, Icons.fact_check, 'Chargesheet Vetting', '/chargesheet-vetting', isDark),
            _buildDrawerItem(context, Icons.people, 'Witness Prep', '/witness-preparation', isDark),
            _buildDrawerItem(context, Icons.image_search, 'Media Analysis', '/media-analysis', isDark),
            _buildDrawerSection('Case Management', isDark),
            _buildDrawerItem(context, Icons.folder_open, 'All Cases', '/cases', isDark),
            _buildDrawerItem(context, Icons.book, 'Case Journal', '/case-journal', isDark),
            _buildDrawerItem(context, Icons.gavel, 'Petitions', '/petitions', isDark),
            _buildDrawerItem(context, Icons.archive, 'My Saved Complaints', '/complaints', isDark),
            const Divider(),
            _buildDrawerItem(context, Icons.settings, 'Settings', '/settings', isDark),
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
