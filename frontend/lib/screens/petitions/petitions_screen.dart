// lib/screens/petitions/petitions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/petition_card.dart';
import 'widgets/create_petition_form.dart';
import 'widgets/petition_details.dart';
class PetitionsScreen extends StatefulWidget {
  const PetitionsScreen({super.key});

  @override
  State<PetitionsScreen> createState() => _PetitionsScreenState();
}

class _PetitionsScreenState extends State<PetitionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final provider = Provider.of<PetitionProvider>(context, listen: false);
    if (auth.user != null) {
      await provider.fetchPetitions(auth.user!.uid);
    }
  }

  String _formatTimestamp(Timestamp t) {
    final d = t.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petition Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'My Petitions'),
            Tab(icon: Icon(Icons.add_circle), text: 'Create New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListTab(theme),
          CreatePetitionForm(onCreatedSuccess: () => _tabController.index = 0),
        ],
      ),
    );
  }

  Widget _buildListTab(ThemeData theme) {
    return Consumer<PetitionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.petitions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No Petitions Yet', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Create your first petition', style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _fetchPetitions,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.petitions.length,
            itemBuilder: (context, i) {
              final p = provider.petitions[i];
              return PetitionCard(
                petition: p,
                onTap: () => _showDetails(p),
                formatTimestamp: _formatTimestamp,
              );
            },
          ),
        );
      },
    );
  }

  void _showDetails(Petition p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PetitionDetails(petition: p),
    );
  }
}