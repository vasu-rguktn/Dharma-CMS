import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Primary Orange Color (#FC633C)
  static const Color primaryOrange = Color(0xFFFC633C);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryOrange, // Orange title
            ),
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
                    'Profile Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryOrange, // Orange heading
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: primaryOrange, // Orange avatar
                      child: Text(
                        (user?.displayName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    title: Text(
                      user?.displayName ?? 'User',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    subtitle: Text(user?.email ?? '', style: TextStyle(color: Colors.grey[600])),
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
                  leading: Icon(Icons.notifications, color: primaryOrange),
                  title: const Text('Notifications'),
                  trailing: Switch(
                    value: true,
                    activeColor: primaryOrange,
                    onChanged: (value) {
                      // Handle notification toggle
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.dark_mode, color: primaryOrange),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: false,
                    activeColor: primaryOrange,
                    onChanged: (value) {
                      // Handle theme toggle
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.language, color: primaryOrange),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  trailing: Icon(Icons.chevron_right, color: primaryOrange),
                  onTap: () {
                    // Handle language selection
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
                  leading: Icon(Icons.info, color: primaryOrange),
                  title: const Text('About'),
                  trailing: Icon(Icons.chevron_right, color: primaryOrange),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Dharma',
                      applicationVersion: '1.0.0',
                      applicationIcon: Icon(Icons.balance, size: 48, color: primaryOrange),
                      children: [
                        Text(
                          'Legal assistance platform powered by AI technology.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: primaryOrange),
                  title: const Text('Privacy Policy'),
                  trailing: Icon(Icons.chevron_right, color: primaryOrange),
                  onTap: () {
                    // Handle privacy policy
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description, color: primaryOrange),
                  title: const Text('Terms of Service'),
                  trailing: Icon(Icons.chevron_right, color: primaryOrange),
                  onTap: () {
                    // Handle terms of service
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Logout Button
          Card(
            color: primaryOrange.withOpacity(0.1), // Light orange background
            child: ListTile(
              leading: Icon(Icons.logout, color: primaryOrange),
              title: Text(
                'Sign Out',
                style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Sign Out', style: TextStyle(color: primaryOrange)),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: primaryOrange)),
                      ),
                      TextButton(
                        onPressed: () {
                          authProvider.signOut();
                          context.go('/login');
                        },
                        style: TextButton.styleFrom(foregroundColor: primaryOrange),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}