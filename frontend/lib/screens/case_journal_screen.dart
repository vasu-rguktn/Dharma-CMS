// lib/screens/case_journal_screen.dart
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/models/case_journal_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class CaseJournalScreen extends StatefulWidget {
  const CaseJournalScreen({super.key});

  @override
  State<CaseJournalScreen> createState() => _CaseJournalScreenState();
}

class _CaseJournalScreenState extends State<CaseJournalScreen> {
  String? _selectedCaseId;
  List<CaseJournalEntry> _journalEntries = [];
  bool _isLoading = false;

  // Your signature orange
  static const Color orange = Color(0xFFFC633C);

  Future<void> _fetchJournalEntries(String caseId) async {
    setState(() {
      _isLoading = true;
      _selectedCaseId = caseId;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('caseJournalEntries')
          .where('caseId', isEqualTo: caseId)
          .orderBy('dateTime', descending: true)
          .get();

      setState(() {
        _journalEntries = snapshot.docs
            .map((doc) => CaseJournalEntry.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorLoadingJournal(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showAddEntryDialog() {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activityController = TextEditingController();
    final entryController = TextEditingController();
    String selectedActivity = localizations.firRegistered;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(localizations.addJournalEntry),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedActivity,
                decoration: InputDecoration(
                  labelText: localizations.activityType,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  localizations.firRegistered,
                  localizations.evidenceCollected,
                  localizations.witnessExamined,
                  localizations.arrestMade,
                  localizations.medicalReportObtained,
                  localizations.sceneVisited,
                  localizations.documentSubmitted,
                  localizations.hearingAttended,
                  localizations.other,
                ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => selectedActivity = value!,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: entryController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: localizations.entryDetails,
                  hintText: localizations.entryDetailsHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(localizations.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: orange),
            onPressed: () async {
              if (entryController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.pleaseEnterEntryDetails), backgroundColor: Colors.red),
                );
                return;
              }

              try {
                final entry = CaseJournalEntry(
                  caseId: _selectedCaseId!,
                  officerUid: authProvider.user!.uid,
                  officerName: authProvider.userProfile?.displayName ?? 'Officer',
                  officerRank: authProvider.userProfile?.rank ?? 'N/A',
                  dateTime: Timestamp.now(),
                  entryText: entryController.text.trim(),
                  activityType: selectedActivity,
                );

                await FirebaseFirestore.instance.collection('caseJournalEntries').add(entry.toMap());
                Navigator.pop(dialogContext);
                await _fetchJournalEntries(_selectedCaseId!);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.journalEntryAddedSuccess), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(localizations.errorAddingEntry(e.toString())), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(localizations.addEntry),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // BEAUTIFUL HEADER WITH ORANGE BACK ARROW
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 24, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: orange,
                        size: 32,
                        shadows: const [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations.caseJournal,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -0.3),
                    ),
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 24, 24),
              child: Text(
                localizations.caseJournalDesc,
                style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.4),
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Case Selector Card
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.folder_open_rounded, color: orange, size: 28),
                                const SizedBox(width: 12),
                                Text(localizations.selectCase, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (caseProvider.cases.isEmpty)
                              Text(localizations.noCasesAvailable, style: TextStyle(color: Colors.grey[600]))
                            else
                              DropdownButtonFormField<String>(
                                value: _selectedCaseId,
                                decoration: InputDecoration(
                                  hintText: localizations.chooseCaseToViewJournal,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                items: caseProvider.cases.map((caseDoc) {
                                  return DropdownMenuItem(
                                    value: caseDoc.id,
                                    child: Text(
                                      '${caseDoc.firNumber} - ${caseDoc.title}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) _fetchJournalEntries(value);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Journal Timeline
                    if (_selectedCaseId != null)
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(localizations.investigationDiary, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.add_circle, color: orange, size: 32),
                                        tooltip: localizations.addJournalEntryTooltip,
                                        onPressed: _showAddEntryDialog,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.open_in_new),
                                        tooltip: localizations.openCaseDetails,
                                        onPressed: () => context.go('/cases/$_selectedCaseId'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (_isLoading)
                                const Center(child: CircularProgressIndicator(color: orange))
                              else if (_journalEntries.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(localizations.noJournalEntries, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                      Text(localizations.noJournalEntriesDesc, style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
                                    ],
                                  ),
                                )
                              else
                                _buildJournalTimeline(),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _journalEntries.length,
      itemBuilder: (context, index) {
        final entry = _journalEntries[index];
        final isLast = index == _journalEntries.length - 1;
        return _buildTimelineItem(entry, isLast);
      },
    );
  }

  Widget _buildTimelineItem(CaseJournalEntry entry, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [BoxShadow(color: orange.withOpacity(0.3), blurRadius: 8)],
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.activityType,
                              style: TextStyle(fontWeight: FontWeight.bold, color: orange, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(entry.officerRank, style: TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(entry.entryText, style: const TextStyle(height: 1.5)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(entry.officerName, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(_formatTimestamp(entry.dateTime), style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                      if (entry.relatedDocumentId != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.attach_file, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 6),
                            Text('Ref: ${entry.relatedDocumentId}', style: TextStyle(color: Colors.blue[700])),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}