import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPetitions();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Petition Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'My Petitions'),
            // Tab(icon: Icon(Icons.add_circle), text: 'Create New'),
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