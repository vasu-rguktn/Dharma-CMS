import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma_police/providers/auth_provider.dart';
import 'package:dharma_police/providers/settings_provider.dart';
import 'package:dharma_police/config/languages.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const Color navy = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        // Profile card
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Profile Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            CircleAvatar(radius: 30, backgroundColor: navy, child: Text((user?.displayName ?? 'O')[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.displayName ?? 'Officer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (user?.email != null) Text(user!.email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              if (user?.rank != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: navy.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(user!.rank!, style: TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ])),
          ]),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person, size: 18, color: navy),
            label: const Text('View Profile', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
          )),
        ]))),
        const SizedBox(height: 16),

        // Language
        Card(child: Consumer<SettingsProvider>(builder: (ctx, settings, _) {
          final current = settings.locale?.languageCode ?? 'en';
          return ListTile(
            leading: const Icon(Icons.language),
            title: const Text('App Language'),
            subtitle: Text(AppLanguages.displayName(current)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageSheet(ctx, settings),
          );
        })),
        const SizedBox(height: 16),        // Sign out & Privacy
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy-policy'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () { auth.signOut(); context.go('/'); },
          ),
        ])),
      ]),
    );
  }

  void _showLanguageSheet(BuildContext ctx, SettingsProvider settings) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(child: ListView.builder(
            itemCount: AppLanguages.supported.length,
            itemBuilder: (_, i) {
              final l = AppLanguages.supported[i];
              final current = settings.locale?.languageCode ?? 'en';
              final selected = current == l['code'];
              return ListTile(
                title: Text(AppLanguages.displayName(l['code']!), style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? navy : null)),
                trailing: selected ? const Icon(Icons.check_circle, color: navy) : null,
                onTap: () { settings.setLanguage(l['code']!); Navigator.pop(ctx); },
              );
            },
          )),
        ]),
      ),
    );
  }
}
