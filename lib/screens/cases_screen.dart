import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nyay_setu_flutter/providers/case_provider.dart';
import 'package:nyay_setu_flutter/models/case_status.dart';
import 'package:go_router/go_router.dart';

class CasesScreen extends StatelessWidget {
  const CasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Cases',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/cases/new'),
                icon: const Icon(Icons.add),
                label: const Text('New Case'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: caseProvider.cases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No cases found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first case to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/cases/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Case'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: caseProvider.cases.length,
                    itemBuilder: (context, index) {
                      final caseItem = caseProvider.cases[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.gavel, color: Colors.white),
                          ),
                          title: Text(
                            caseItem.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${caseItem.status.displayName} • FIR: ${caseItem.firNumber}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/cases/${caseItem.id}'),
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
