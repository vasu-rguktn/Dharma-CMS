import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/models/case_status.dart';
import 'package:Dharma/models/case_journal_entry.dart';
import 'package:Dharma/models/crime_details.dart';
import 'package:Dharma/models/media_analysis.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaseDetailScreen extends StatefulWidget {
  final String caseId;
  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CaseJournalEntry> _journalEntries = [];
  List<MediaAnalysisRecord> _mediaAnalyses = [];
  CrimeDetails? _crimeDetails;
  bool _isLoadingJournal = false;
  bool _isLoadingMedia = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchCaseJournal();
    _fetchMediaAnalyses();
    _fetchCrimeDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCaseJournal() async {
    setState(() => _isLoadingJournal = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('caseJournalEntries')
          .where('caseId', isEqualTo: widget.caseId)
          .orderBy('dateTime', descending: true)
          .get();

      setState(() {
        _journalEntries = snapshot.docs
            .map((doc) => CaseJournalEntry.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error fetching journal entries: $e');
    } finally {
      setState(() => _isLoadingJournal = false);
    }
  }

  Future<void> _fetchMediaAnalyses() async {
    setState(() => _isLoadingMedia = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .collection('mediaAnalyses')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _mediaAnalyses = snapshot.docs
            .map((doc) => MediaAnalysisRecord.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error fetching media analyses: $e');
    } finally {
      setState(() => _isLoadingMedia = false);
    }
  }

  Future<void> _fetchCrimeDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('crimeDetails')
          .doc(widget.caseId)
          .get();

      if (doc.exists) {
        setState(() {
          _crimeDetails = CrimeDetails.fromFirestore(doc);
        });
      }
    } catch (e) {
      print('Error fetching crime details: $e');
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final caseDoc = caseProvider.cases.firstWhere(
      (c) => c.id == widget.caseId,
      orElse: () => throw Exception('Case not found'),
    );

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cases'),
        ),
        title: Text(caseDoc.title),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'FIR Details'),
            Tab(icon: Icon(Icons.search), text: 'Crime Scene'),
            Tab(icon: Icon(Icons.book), text: 'Investigation'),
            Tab(icon: Icon(Icons.archive), text: 'Evidence'),
            Tab(icon: Icon(Icons.gavel), text: 'Final Report'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFIRDetailsTab(caseDoc, theme),
          _buildCrimeSceneTab(caseDoc, theme),
          _buildInvestigationTab(caseDoc, theme),
          _buildEvidenceTab(caseDoc, theme),
          _buildFinalReportTab(caseDoc, theme),
        ],
      ),
    );
  }

  Widget _buildFIRDetailsTab(caseDoc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(caseDoc.status),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              caseDoc.status.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSection(
            theme,
            'Case Information',
            [
              _buildInfoRow('FIR Number', caseDoc.firNumber),
              if (caseDoc.district != null)
                _buildInfoRow('District', caseDoc.district!),
              if (caseDoc.policeStation != null)
                _buildInfoRow('Police Station', caseDoc.policeStation!),
              if (caseDoc.year != null) _buildInfoRow('Year', caseDoc.year!),
            ],
          ),
          const SizedBox(height: 16),

          if (caseDoc.complainantName != null)
            _buildSection(
              theme,
              'Complainant Information',
              [
                _buildInfoRow('Name', caseDoc.complainantName!),
                if (caseDoc.complainantFatherHusbandName != null)
                  _buildInfoRow(
                    'Father/Husband Name',
                    caseDoc.complainantFatherHusbandName!,
                  ),
                if (caseDoc.complainantGender != null)
                  _buildInfoRow('Gender', caseDoc.complainantGender!),
                if (caseDoc.complainantMobileNumber != null)
                  _buildInfoRow(
                    'Mobile Number',
                    caseDoc.complainantMobileNumber!,
                  ),
              ],
            ),
          const SizedBox(height: 16),

          if (caseDoc.incidentDetails != null)
            _buildSection(
              theme,
              'Incident Details',
              [
                Text(
                  caseDoc.incidentDetails!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          const SizedBox(height: 16),

          if (caseDoc.actsAndSectionsInvolved != null)
            _buildSection(
              theme,
              'Acts and Sections',
              [
                Text(
                  caseDoc.actsAndSectionsInvolved!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCrimeSceneTab(caseDoc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Crime Scene Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_crimeDetails != null) ...[
                    if (_crimeDetails!.crimeType != null)
                      _buildInfoRow('Crime Type', _crimeDetails!.crimeType!),
                    if (_crimeDetails!.placeOfOccurrenceDescription != null)
                      _buildInfoRow('Place Description',
                          _crimeDetails!.placeOfOccurrenceDescription!),
                    if (_crimeDetails!.physicalEvidenceDescription != null)
                      _buildInfoRow('Physical Evidence',
                          _crimeDetails!.physicalEvidenceDescription!),
                  ] else ...[
                    const Text('No crime scene details available yet.'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Media Analysis Reports
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.image, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'Crime Scene Analysis Reports',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingMedia)
                    const Center(child: CircularProgressIndicator())
                  else if (_mediaAnalyses.isEmpty)
                    const Text('No analysis reports found.')
                  else
                    ..._mediaAnalyses.map((report) => _buildMediaReportCard(report, theme)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaReportCard(MediaAnalysisRecord report, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(report.originalFileName),
        subtitle: Text('Analyzed: ${_formatTimestamp(report.createdAt)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.identifiedElements.isNotEmpty) ...[
                  Text(
                    'Identified Elements:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...report.identifiedElements.map(
                    (element) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${element.name} (${element.category}): ${element.description}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Scene Narrative:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(report.sceneNarrative),
                const SizedBox(height: 16),
                Text(
                  'Case File Summary:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(report.caseFileSummary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationTab(caseDoc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.book, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Case Journal (IO\'s Diary)',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingJournal)
                    const Center(child: CircularProgressIndicator())
                  else if (_journalEntries.isEmpty)
                    const Text('No journal entries yet for this case.')
                  else
                    _buildJournalTimeline(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalTimeline(ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _journalEntries.length,
      itemBuilder: (context, index) {
        final entry = _journalEntries[index];
        return _buildTimelineItem(entry, theme, index == _journalEntries.length - 1);
      },
    );
  }

  Widget _buildTimelineItem(CaseJournalEntry entry, ThemeData theme, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
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
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.activityType,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.entryText,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatTimestamp(entry.dateTime)} by ${entry.officerName} (${entry.officerRank})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceTab(caseDoc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.archive, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Evidence & Seizures',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Evidence management coming soon. This will include collected evidence and seized property details.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinalReportTab(caseDoc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.gavel, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Final Report/Chargesheet',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Final report section coming soon. This will include charge sheet or case closure report.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.newCase:
        return Colors.blue;
      case CaseStatus.underInvestigation:
        return Colors.orange;
      case CaseStatus.pendingTrial:
        return Colors.purple;
      case CaseStatus.resolved:
        return Colors.green;
      case CaseStatus.closed:
        return Colors.grey;
    }
  }
}
