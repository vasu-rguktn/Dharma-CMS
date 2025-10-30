import 'package:flutter/material.dart';
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

  // Primary Orange Color (#FC633C)
  static const Color primaryOrange = Color(0xFFFC633C);

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
            content: Text('Error loading journal: $e'),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activityController = TextEditingController();
    final entryController = TextEditingController();
    String selectedActivity = 'FIR Registered';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Add Journal Entry', style: TextStyle(color: primaryOrange)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedActivity,
                decoration: InputDecoration(
                  labelText: 'Activity Type',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryOrange, width: 2),
                  ),
                ),
                items: [
                  'FIR Registered',
                  'Evidence Collected',
                  'Witness Examined',
                  'Arrest Made',
                  'Medical Report Obtained',
                  'Scene Visited',
                  'Document Submitted',
                  'Hearing Attended',
                  'Other',
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
                  labelText: 'Entry Details',
                  hintText: 'Describe the activity in detail...',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryOrange, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: primaryOrange)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (entryController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter entry details'),
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
                      content: const Text('Journal entry added successfully'),
                      backgroundColor: primaryOrange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding entry: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Entry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.book, color: primaryOrange, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Case Journal',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'View investigation diaries and case activity logs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    'Select Case',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (caseProvider.cases.isEmpty)
                    Text(
                      'No cases available. Please register a case first.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedCaseId,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'Choose a case to view journal',
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryOrange, width: 2),
                        ),
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
                          'Investigation Diary',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryOrange,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.add_circle, color: primaryOrange),
                              tooltip: 'Add journal entry',
                              onPressed: () => _showAddEntryDialog(),
                            ),
                            IconButton(
                              icon: Icon(Icons.open_in_new, color: primaryOrange),
                              tooltip: 'Open case details',
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
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(color: primaryOrange),
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
                                color: primaryOrange.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No journal entries yet',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Journal entries will appear here as the investigation progresses.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      _buildJournalTimeline(),
                  ],
                ),
              ),
            ),
          ],
        ],
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
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.3),
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
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primaryOrange,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              entry.officerRank,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.entryText,
                        style: Theme.of(context).textTheme.bodyMedium,
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                              'Ref: ${entry.relatedDocumentId}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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