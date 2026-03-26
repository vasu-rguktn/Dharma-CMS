import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma/providers/auth_provider.dart';
import 'package:dharma/providers/settings_provider.dart';
import 'package:dharma/config/languages.dart';
import 'package:dharma/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const Color orange = Color(0xFFFC633C);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userProfile;
    final l = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { if (context.canPop()) context.pop(); }),
          const SizedBox(width: 8),
          Text(l.settings, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 24),

        // Profile card
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.profileInformation, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            CircleAvatar(radius: 30, backgroundColor: orange, child: Text((user?.displayName ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (user?.email != null && user!.email.isNotEmpty) Text(user.email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ])),
          ]),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => context.push('/profile'), icon: const Icon(Icons.person, size: 18, color: orange), label: Text(l.viewProfile, style: const TextStyle(color: orange, fontWeight: FontWeight.bold)))),
        ]))),
        const SizedBox(height: 16),

        // Language
        Card(child: Consumer<SettingsProvider>(builder: (ctx, settings, _) {
          final current = settings.locale?.languageCode ?? 'en';
          final chatLang = settings.chatLanguageCode ?? current;
          return Column(children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l.language),
              subtitle: Text(_langName(current)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageSheet(ctx, settings, false),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(l.chatbotLanguage),
              subtitle: Text(_langName(chatLang)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageSheet(ctx, settings, true),
            ),
          ]);
        })),
        const SizedBox(height: 16),        // Sign out
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
            title: Text(l.signOut, style: const TextStyle(color: Colors.red)),
            onTap: () { auth.signOut(); context.go('/'); },
          ),
        ])),
      ]),
    );
  }

  String _langName(String code) => AppLanguages.displayName(code);

  void _showLanguageSheet(BuildContext ctx, SettingsProvider settings, bool isChat) {
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
          Text(isChat ? 'Select Chat Language' : 'Select App Language', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),          Expanded(child: ListView.builder(
            itemCount: AppLanguages.supported.length,
            itemBuilder: (_, i) {
              final l = AppLanguages.supported[i];
              final currentCode = isChat ? (settings.chatLanguageCode ?? settings.locale?.languageCode ?? 'en') : (settings.locale?.languageCode ?? 'en');
              final selected = currentCode == l['code'];
              return ListTile(
                title: Text(AppLanguages.displayName(l['code']!), style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? orange : null)),
                trailing: selected ? const Icon(Icons.check_circle, color: orange) : null,
                onTap: () { if (isChat) { settings.setChatLanguage(l['code']!); } else { settings.setLanguage(l['code']!); } Navigator.pop(ctx); },
              );
            },
          )),
        ]),
      ),
    );
  }
}
