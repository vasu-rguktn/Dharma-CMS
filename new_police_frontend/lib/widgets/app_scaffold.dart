import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dharma_police/providers/auth_provider.dart';
import 'package:dharma_police/config/theme.dart';

class AppScaffold extends StatefulWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});
  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  static const Color navy = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/police_logo.png', height: 30, width: 30, errorBuilder: (_, __, ___) => const Icon(Icons.local_police, size: 30)),
          const SizedBox(width: 8),
          const Flexible(child: Text('Dharma Police', overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(radius: 16, backgroundColor: navy, child: Text((auth.displayNameOrUsername.isNotEmpty ? auth.displayNameOrUsername[0] : 'O').toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white))),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 18),
              ]),
            ),
            onSelected: (v) {
              if (v == 'profile') context.push('/settings');
              if (v == 'signout') { auth.signOut(); context.go('/'); }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Row(children: [Icon(Icons.person), SizedBox(width: 8), Text('Profile')])),
              PopupMenuItem(value: 'signout', child: Row(children: [Icon(Icons.logout), SizedBox(width: 8), Text('Sign Out')])),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.sidebarBackground(isDark),
        child: ListView(padding: EdgeInsets.zero, children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.sidebarBackground(isDark)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.local_police, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              const Text('Dharma Police', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(auth.displayNameOrUsername, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            ]),
          ),
          _item(context, Icons.dashboard, 'Dashboard', '/dashboard', isDark),
          _section('Case Management', isDark),
          _item(context, Icons.folder_open, 'Cases', '/cases', isDark),
          _item(context, Icons.description, 'Petitions', '/petitions', isDark),
          _section('AI Tools', isDark),
          _item(context, Icons.edit_document, 'Document Drafting', '/document-drafting', isDark),
          _item(context, Icons.gavel, 'Chargesheet Gen', '/chargesheet', isDark),
          _item(context, Icons.fact_check, 'Chargesheet Vetting', '/chargesheet-vetting', isDark),
          _item(context, Icons.search, 'Investigation', '/investigation', isDark),
          _item(context, Icons.image_search, 'Media Analysis', '/media-analysis', isDark),
          _item(context, Icons.chat, 'Legal Chat', '/chat', isDark),
          const Divider(color: Colors.white24),
          _item(context, Icons.settings, 'Settings', '/settings', isDark),
        ]),
      ),
      body: widget.child,
    );
  }

  Widget _section(String title, bool isDark) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
  );

  Widget _item(BuildContext ctx, IconData icon, String title, String route, bool isDark) {
    final active = GoRouterState.of(ctx).uri.path == route;
    return ListTile(
      leading: Icon(icon, color: active ? Colors.amber : Colors.white),
      title: Text(title, style: TextStyle(color: active ? Colors.amber : Colors.white, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      onTap: () { Navigator.pop(ctx); ctx.go(route); },
    );
  }
}
