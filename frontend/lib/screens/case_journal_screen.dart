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
        title: Text(localizations.addJournalEntry),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedActivity,
                decoration: InputDecoration(
                  labelText: localizations.activityType,
                  border: const OutlineInputBorder(),
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
                ].map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  selectedActivity = value!;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: entryController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: localizations.entryDetails,
                  hintText: localizations.entryDetailsHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (entryController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(localizations.pleaseEnterEntryDetails),
                    backgroundColor: Colors.red,
                  ),
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
                  entryText: entryController.text,
                  activityType: selectedActivity,
                );

                await FirebaseFirestore.instance
                    .collection('caseJournalEntries')
                    .add(entry.toMap());

                Navigator.pop(dialogContext);
                await _fetchJournalEntries(_selectedCaseId!);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.journalEntryAddedSuccess),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(localizations.errorAddingEntry(e.toString())),
                      backgroundColor: Colors.red,
                    ),
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
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.book, color: theme.primaryColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localizations.caseJournal,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localizations.caseJournalDesc,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Case Selector
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.selectCase,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (caseProvider.cases.isEmpty)
                    Text(
                      localizations.noCasesAvailable,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedCaseId,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: localizations.chooseCaseToViewJournal,
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
                        if (value != null) {
                          _fetchJournalEntries(value);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Journal Entries
          if (_selectedCaseId != null) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          localizations.investigationDiary,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              tooltip: localizations.addJournalEntryTooltip,
                              onPressed: () => _showAddEntryDialog(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.open_in_new),
                              tooltip: localizations.openCaseDetails,
                              onPressed: () {
                                context.go('/cases/$_selectedCaseId');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_journalEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizations.noJournalEntries,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localizations.noJournalEntriesDesc,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      _buildJournalTimeline(theme, localizations),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJournalTimeline(ThemeData theme, AppLocalizations localizations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _journalEntries.length,
      itemBuilder: (context, index) {
        final entry = _journalEntries[index];
        final isLast = index == _journalEntries.length - 1;
        return _buildTimelineItem(entry, theme, isLast, localizations);
      },
    );
  }

  Widget _buildTimelineItem(CaseJournalEntry entry, ThemeData theme, bool isLast, AppLocalizations localizations) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Card(
                elevation: 1,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.activityType,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              entry.officerRank,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.entryText,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            entry.officerName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(entry.dateTime),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (entry.relatedDocumentId != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${localizations.ref}: ${entry.relatedDocumentId}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue[700],
                              ),
                            ),
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
