import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma/providers/auth_provider.dart';
import 'package:dharma/providers/petition_provider.dart';
import 'package:dharma/models/petition.dart';
import 'package:dharma/l10n/app_localizations.dart';

class PetitionsScreen extends StatefulWidget {
  const PetitionsScreen({super.key});
  @override
  State<PetitionsScreen> createState() => _PetitionsScreenState();
}

class _PetitionsScreenState extends State<PetitionsScreen> {
  static const Color orange = Color(0xFFFC633C);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final uid = auth.user?.uid;
      if (uid != null) Provider.of<PetitionProvider>(context, listen: false).fetchPetitions(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final petitions = Provider.of<PetitionProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      appBar: AppBar(title: Text(l.petitions)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/petitions/create'),
        backgroundColor: orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: petitions.isLoading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : petitions.petitions.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.description_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),                  Text(l.noPetitionsYet, style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(onPressed: () => context.push('/petitions/create'), icon: const Icon(Icons.add), label: Text(l.createPetition), style: ElevatedButton.styleFrom(backgroundColor: orange)),
                ]))
              : RefreshIndicator(
                  onRefresh: () async {
                    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                    if (uid != null) await petitions.fetchPetitions(uid);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: petitions.petitions.length,
                    itemBuilder: (ctx, i) => _PetitionCard(petition: petitions.petitions[i]),
                  ),
                ),
    );
  }
}

class _PetitionCard extends StatelessWidget {
  final Petition petition;
  const _PetitionCard({required this.petition});

  @override
  Widget build(BuildContext context) {
    final status = petition.policeStatus ?? petition.status.displayName;
    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),        onTap: () {
          if (petition.id != null) {
            context.push('/petitions/${petition.id}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(petition.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(status, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            if (petition.caseId != null) Text('Case: ${petition.caseId}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(petition.isAnonymous ? 'Anonymous' : petition.petitionerName, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const Spacer(),
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text('${petition.createdAt.day}/${petition.createdAt.month}/${petition.createdAt.year}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ]),
            if (petition.isEscalated) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.warning_amber, size: 14, color: Colors.red[700]),
                  const SizedBox(width: 4),
                  Text('Escalated (${petition.escalationLevel == 3 ? "DGP" : petition.escalationLevel == 2 ? "IG" : "SP"} level)', style: TextStyle(fontSize: 11, color: Colors.red[700], fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('pending') || s.contains('received')) return Colors.blue;
    if (s.contains('progress') || s.contains('investigation')) return Colors.orange;
    if (s.contains('closed') || s.contains('resolved')) return Colors.green;
    if (s.contains('rejected')) return Colors.red;
    return Colors.grey;
  }
}
