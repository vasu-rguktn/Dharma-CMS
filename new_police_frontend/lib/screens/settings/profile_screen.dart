import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dharma_police/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  static const Color navy = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userProfile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Officer Profile', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        Center(child: CircleAvatar(radius: 50, backgroundColor: navy, child: Text((user?.displayName ?? 'O')[0].toUpperCase(), style: const TextStyle(fontSize: 36, color: Colors.white)))),
        const SizedBox(height: 24),

        _infoCard('Personal Information', [
          _row('Name', user?.displayName),
          _row('Email', user?.email),
          _row('Phone', user?.phoneNumber),
          _row('Role', user?.role.toUpperCase()),
        ]),
        const SizedBox(height: 16),

        _infoCard('Police Information', [
          _row('Rank', user?.rank),
          _row('District', user?.district),
          _row('Station', user?.stationName),
          _row('Range', user?.rangeName),
          _row('Circle', user?.circleName),
          _row('SDPO', user?.sdpoName),
          _row('Approved', user?.isApproved == true ? 'Yes' : 'No'),
        ]),
      ]),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(),
          ...children,
        ]),
      ),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
    );
  }
}
