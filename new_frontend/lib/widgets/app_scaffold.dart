import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dharma/providers/auth_provider.dart';
import 'package:dharma/config/theme.dart';
import 'package:dharma/l10n/app_localizations.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});
  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/police_logo.png', height: 30, width: 30, errorBuilder: (_, __, ___) => Icon(Icons.balance, size: 30, color: Theme.of(context).primaryColor)),
            const SizedBox(width: 8),
            Flexible(child: Text(l.appTitle, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 16, child: Text((auth.displayNameOrUsername.isNotEmpty ? auth.displayNameOrUsername[0] : 'U').toUpperCase(), style: const TextStyle(fontSize: 12))),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
            onSelected: (v) {
              if (v == 'profile') context.push('/settings');
              if (v == 'signout') { auth.signOut(); context.go('/'); }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person), SizedBox(width: 8), Text('Profile')])),
              PopupMenuItem(value: 'signout', child: Row(children: [const Icon(Icons.logout), const SizedBox(width: 8), Text(l.signOut)])),
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
              decoration: BoxDecoration(color: AppTheme.sidebarBackground(isDark)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.balance, size: 48, color: AppTheme.sidebarForeground(isDark)),
                const SizedBox(height: 8),
                Text(l.appTitle, style: TextStyle(color: AppTheme.sidebarForeground(isDark), fontSize: 20)),
              ]),
            ),
            _item(context, Icons.dashboard, l.dashboard, '/dashboard', isDark),
            _section(l.aiTools, isDark),
            _item(context, Icons.chat, l.aiChat, '/ai-legal-chat', isDark),
            _section(l.caseManagement, isDark),
            _item(context, Icons.archive, l.mySavedComplaints, '/complaints', isDark),
            _item(context, Icons.book, l.petitions, '/petitions', isDark),
            _item(context, Icons.phone, l.support, '/helpline', isDark),
            const Divider(),
            _item(context, Icons.settings, l.settings, '/settings', isDark),
          ],
        ),
      ),
      body: widget.child,
    );
  }

  Widget _section(String title, bool isDark) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(title, style: TextStyle(color: AppTheme.sidebarForeground(isDark).withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
  );

  Widget _item(BuildContext ctx, IconData icon, String title, String route, bool isDark) {
    final active = GoRouterState.of(ctx).uri.path == route;
    return ListTile(
      leading: Icon(icon, color: active ? Theme.of(ctx).primaryColor : AppTheme.sidebarForeground(isDark)),
      title: Text(title, style: TextStyle(color: active ? Theme.of(ctx).primaryColor : AppTheme.sidebarForeground(isDark), fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      onTap: () { Navigator.pop(ctx); ctx.go(route); },
    );
  }
}
