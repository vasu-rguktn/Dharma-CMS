import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/settings_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/services/onboarding_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<Map<String, String>> _validLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'te', 'name': 'Telugu (తెలుగు)'},
    {'code': 'hi', 'name': 'Hindi (हिन्दी)'},
    {'code': 'ta', 'name': 'Tamil (தமிழ்)'},
    {'code': 'kn', 'name': 'Kannada (ಕನ್ನಡ)'},
    {'code': 'ml', 'name': 'Malayalam (മലയാളം)'},
    {'code': 'mr', 'name': 'Marathi (मराठी)'},
    {'code': 'gu', 'name': 'Gujarati (ગુજરાતી)'},
    {'code': 'bn', 'name': 'Bengali (বাংলা)'},
    {'code': 'pa', 'name': 'Punjabi (ਪੰਜਾਬੀ)'},
    {'code': 'ur', 'name': 'Urdu (اردو)'},
    {'code': 'or', 'name': 'Odia (ଓଡ଼ିଆ)'},
    {'code': 'as', 'name': 'Assamese (অসমীয়া)'},
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;
    final localizations = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: () async {
        // Use GoRouter's canPop to check navigation history
        if (context.canPop()) {
          context.pop();
          return false; // Prevent default exit, we handled navigation
        }
        return true; // Allow exit only if truly root
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    }
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.settings,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // User Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.profileInformation,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.orange,
                          child: Text(
                            (user?.displayName ?? localizations.user)[0]
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 24, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.displayName ?? localizations.user,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (user?.email != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  user!.email!,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.push('/profile'),
                        icon: const Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.orange,
                        ),
                        label: Text(
                          localizations.viewProfile,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Settings
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(localizations.notifications),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // Handle notification toggle
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Consumer<SettingsProvider>(
                    builder: (context, settingsProvider, child) {
                      final currentLocale =
                          settingsProvider.locale ?? const Locale('en');
                      final currentLanguage = currentLocale.languageCode == 'te'
                          ? localizations.telugu
                          : localizations.english;

                      return ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(localizations.language),
                        subtitle: Text(currentLanguage),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _showAppLanguageSheet(context, settingsProvider),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  Consumer<SettingsProvider>(
                    builder: (context, provider, _) {
                      final currentCode = provider.chatLanguageCode ??
                          provider.locale?.languageCode ??
                          'en';
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(localizations.chatbotLanguage),
                        subtitle: Text(_getLanguageName(currentCode)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChatLanguageSheet(context, provider),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // About Section
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: Text(localizations.about),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: localizations.appName,
                        applicationVersion: localizations.appVersion,
                        applicationIcon: const Icon(Icons.balance, size: 48),
                        children: [
                          Text(localizations.appDescription),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: Text(localizations.privacyPolicy),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/privacy');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(localizations.termsOfService),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/terms');
                    },
                  ),
                  // Reset Onboarding (Visible to all for testing)
                  // if (authProvider.role != 'police') ...[ // Removed check to ensure visibility
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.replay, color: Colors.orange),
                    title: Text(
                      localizations.resetOnboarding,
                      style: const TextStyle(color: Colors.orange),
                    ),
                    subtitle: Text(localizations.showTutorialAgain),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.orange),
                    onTap: () async {
                      // Show confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(localizations.resetOnboarding),
                          content: Text(localizations.showTutorialAgain),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(localizations.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                localizations.resetOnboarding,
                                style:
                                    const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        // Reset onboarding
                        await OnboardingService.resetOnboarding();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.showTutorialAgain,
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  // ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            Card(
              color: Colors.red[50],
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  localizations.signOut,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(localizations.signOut),
                      content: Text(localizations.signOutConfirmation),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(localizations.cancel),
                        ),
                        TextButton(
                          onPressed: () {
                            final isPolice = authProvider.role == 'police';
                            authProvider.signOut();
                            context.go(
                                isPolice ? '/police-login' : '/phone-login');
                          },
                          child: Text(
                            localizations.signOut,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getLanguageName(String code) {
    return _validLanguages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => {'name': 'English'},
    )['name']!;
  }

  static void _showAppLanguageSheet(
      BuildContext context, SettingsProvider settingsProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)!.language,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _validLanguages.length,
                itemBuilder: (context, index) {
                  final lang = _validLanguages[index];
                  final isSelected =
                      settingsProvider.locale?.languageCode == lang['code'];

                  return InkWell(
                    onTap: () {
                      settingsProvider.setLanguage(lang['code']!);
                      Navigator.pop(bottomSheetContext);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lang['name']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                                size: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showChatLanguageSheet(
      BuildContext context, SettingsProvider provider) {
    // Reuse _validLanguages
   final localizations = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                localizations.chatbotLanguage,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _validLanguages.length,
                itemBuilder: (context, index) {
                  final lang = _validLanguages[index];
                  final isSelected =
                      provider.chatLanguageCode == lang['code'] ||
                          (provider.chatLanguageCode == null &&
                              provider.locale?.languageCode == lang['code']);

                  return InkWell(
                    onTap: () {
                      provider.setChatLanguage(lang['code']!);
                      Navigator.pop(bottomSheetContext);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lang['name']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                                size: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
