import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma/providers/auth_provider.dart';
import 'package:dharma/providers/complaint_provider.dart';
import 'package:dharma/l10n/app_localizations.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});
  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  static const Color orange = Color(0xFFFC633C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      Provider.of<ComplaintProvider>(context, listen: false).fetchComplaints(userId: auth.user?.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = Provider.of<ComplaintProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      appBar: AppBar(title: Text(l.mySavedComplaints)),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : provider.complaints.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.archive_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No saved complaints', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                ]))
              : RefreshIndicator(
                  onRefresh: () async {
                    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                    await provider.fetchComplaints(userId: uid);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.complaints.length,
                    itemBuilder: (ctx, i) {
                      final c = provider.complaints[i];
                      final title = c['title'] ?? c['petitionerName'] ?? 'Untitled';
                      final status = c['status'] ?? 'Unknown';
                      final isDraft = c['isDraft'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: isDraft ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                            child: Icon(isDraft ? Icons.edit_note : Icons.bookmark, color: isDraft ? Colors.orange : Colors.blue),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const SizedBox(height: 4),
                            Text(isDraft ? 'AI Chat Draft' : 'Saved Petition', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            Text('Status: $status', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          ]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
                                title: const Text('Delete?'),
                                content: const Text('This action cannot be undone.'),
                                actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red)))],
                              ));
                              if (confirmed == true && c['id'] != null) {
                                try { await provider.deleteComplaint(c['id']); } catch (_) {}
                              }
                            },
                          ),
                          onTap: isDraft ? () => context.go('/ai-legal-chat', extra: c) : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
