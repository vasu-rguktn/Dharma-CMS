import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/settings_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/services/onboarding_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                        icon: const Icon(Icons.person,
                            size: 18, color: Colors.orange),
                        label: const Text(
                          'View Profile',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
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
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (bottomSheetContext) => Container(
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Drag handle
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 12, bottom: 8),
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  // Title
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0, vertical: 16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.language,
                                          color: Theme.of(context).primaryColor,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          localizations.language,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1, color: Colors.grey[200]),
                                  const SizedBox(height: 8),
                                  // Language options
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Column(
                                      children: [
                                        _buildLanguageOption(
                                          context: context,
                                          bottomSheetContext:
                                              bottomSheetContext,
                                          settingsProvider: settingsProvider,
                                          currentLocale: currentLocale,
                                          languageCode: 'en',
                                          languageName: localizations.english,
                                        ),
                                        const SizedBox(height: 8),
                                        _buildLanguageOption(
                                          context: context,
                                          bottomSheetContext:
                                              bottomSheetContext,
                                          settingsProvider: settingsProvider,
                                          currentLocale: currentLocale,
                                          languageCode: 'te',
                                          languageName: localizations.telugu,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          );
                        },
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
                    title: const Text(
                      'Reset Onboarding',
                      style: TextStyle(color: Colors.orange),
                    ),
                    subtitle: const Text('Show tutorial again'),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.orange),
                    onTap: () async {
                      // Show confirmation dialog
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reset Onboarding?'),
                          content: const Text(
                            'This will show the tutorial screens again on next app start. Continue?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(localizations.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Reset',
                                style: TextStyle(color: Colors.orange),
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
                            const SnackBar(
                              content: Text(
                                  'Onboarding reset! Restart the app to see tutorial.'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
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

  static Widget _buildLanguageOption({
    required BuildContext context,
    required BuildContext bottomSheetContext,
    required SettingsProvider settingsProvider,
    required Locale currentLocale,
    required String languageCode,
    required String languageName,
  }) {
    final isSelected = currentLocale.languageCode == languageCode;

    return InkWell(
      onTap: () {
        settingsProvider.setLanguage(languageCode);
        Navigator.pop(bottomSheetContext);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                languageName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[800],
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
