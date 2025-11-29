// lib/screens/petition/petitions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'petitions_list_tab.dart';
import 'create_petition_form.dart';

class PetitionsScreen extends StatefulWidget {
  const PetitionsScreen({super.key});

  @override
  State<PetitionsScreen> createState() => _PetitionsScreenState();
}

class _PetitionsScreenState extends State<PetitionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Your signature orange
  static const Color orange = Color(0xFFFC633C);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Safe fetch after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPetitions());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPetitions() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final petition = Provider.of<PetitionProvider>(context, listen: false);
    if (auth.user != null) {
      await petition.fetchPetitions(auth.user!.uid);
    }
  }

  String _formatTimestamp(Timestamp ts) {
    final d = ts.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        // Back arrow added here — right beside the title
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: orange,
              size: 32,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))
              ],
            ),
            onPressed: () => context.go('/dashboard'),
          ),
        ),
        title: Text(
          localizations.petitionManagement,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: orange,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: orange,
          tabs: [
            Tab(icon: const Icon(Icons.list), text: localizations.myPetitions),
            Tab(icon: const Icon(Icons.add_circle), text: localizations.createNew),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PetitionsListTab(
            onRefresh: _fetchPetitions,
            formatTimestamp: _formatTimestamp,
          ),
          CreatePetitionForm(
            onCreatedSuccess: () => _tabController.index = 0,
          ),
        ],
      ),
    );
  }
}