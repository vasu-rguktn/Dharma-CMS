import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/models/case_doc.dart';
import 'package:Dharma/models/case_status.dart';
import 'package:Dharma/models/case_journal_entry.dart';
import 'package:Dharma/models/crime_details.dart';
import 'package:Dharma/models/media_analysis.dart';
import 'package:Dharma/models/petition.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoadingPetitions = false;
  List<Petition> _linkedPetitions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchCaseJournal();
    _fetchMediaAnalyses();
    _fetchCrimeDetails();
    // Fetch petitions linked to this case (by FIR number) after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLinkedPetitions();
    });
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

  Future<void> _fetchLinkedPetitions() async {
    setState(() => _isLoadingPetitions = true);
    try {
      final caseProvider = Provider.of<CaseProvider>(context, listen: false);
      final caseDoc = caseProvider.cases.firstWhere(
        (c) => c.id == widget.caseId,
        orElse: () => throw Exception('Case not found'),
      );

      final firNumber = caseDoc.firNumber;
      if (firNumber.isEmpty) {
        setState(() => _isLoadingPetitions = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('petitions')
          .where('firNumber', isEqualTo: firNumber)
          .get();

      setState(() {
        _linkedPetitions = snapshot.docs
            .map((doc) => Petition.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error fetching linked petitions: $e');
    } finally {
      setState(() => _isLoadingPetitions = false);
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
          // Align tabs starting from the very left to avoid wasted space
          tabAlignment: TabAlignment.start,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.black87,
          indicator: const BoxDecoration(), // no underline
          dividerColor: Colors.transparent,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.description, size: 20),
              child: Text(
                'FIR Details',
                style: TextStyle(fontSize: 12),
              ),
            ),
            Tab(
              icon: Icon(Icons.search, size: 20),
              child: Text(
                'Crime Scene',
                style: TextStyle(fontSize: 12),
              ),
            ),
            Tab(
              icon: Icon(Icons.book, size: 20),
              child: Text(
                'Investigation',
                style: TextStyle(fontSize: 12),
              ),
            ),
            Tab(
              icon: Icon(Icons.archive, size: 20),
              child: Text(
                'Evidence',
                style: TextStyle(fontSize: 12),
              ),
            ),
            Tab(
              icon: Icon(Icons.gavel, size: 20),
              child: Text(
                'Final Report',
                style: TextStyle(fontSize: 12),
              ),
            ),
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

  Widget _buildFIRDetailsTab(CaseDoc caseDoc, ThemeData theme) {
    String _boolText(bool? value) => value == true ? 'Yes' : 'No';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top summary card with status + key info
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FIR No: ${caseDoc.firNumber}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              caseDoc.status.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Filed on: ${_formatTimestamp(caseDoc.dateFiled)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(caseDoc.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          caseDoc.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (caseDoc.policeStation != null || caseDoc.district != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        [
                          if (caseDoc.policeStation != null)
                            caseDoc.policeStation!,
                          if (caseDoc.district != null) caseDoc.district!,
                        ].join(' • '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Case information
          _buildSection(
            theme,
            'Case Information',
            [
              _buildInfoRow('FIR Number', caseDoc.firNumber),
              if (caseDoc.year != null) _buildInfoRow('Year', caseDoc.year!),
              if (caseDoc.originalComplaintId != null)
                _buildInfoRow('Complaint ID', caseDoc.originalComplaintId!),
              if (caseDoc.date != null)
                _buildInfoRow('FIR Date', caseDoc.date!),
              if (caseDoc.firFiledTimestamp != null)
                _buildInfoRow(
                  'FIR Filed At',
                  _formatTimestamp(caseDoc.firFiledTimestamp!),
                ),
              if (caseDoc.district != null)
                _buildInfoRow('District', caseDoc.district!),
              if (caseDoc.policeStation != null)
                _buildInfoRow('Police Station', caseDoc.policeStation!),
            ],
          ),

          const SizedBox(height: 16),

          // Occurrence details
          if (caseDoc.occurrenceDay != null ||
              caseDoc.occurrenceDateTimeFrom != null ||
              caseDoc.occurrenceDateTimeTo != null ||
              caseDoc.placeOfOccurrenceStreet != null ||
              caseDoc.placeOfOccurrenceCity != null)
            _buildSection(
              theme,
              'Occurrence of Offence',
              [
                if (caseDoc.occurrenceDay != null)
                  _buildInfoRow('Day of Occurrence', caseDoc.occurrenceDay!),
                if (caseDoc.occurrenceDateTimeFrom != null)
                  _buildInfoRow(
                    'From',
                    caseDoc.occurrenceDateTimeFrom!,
                  ),
                if (caseDoc.occurrenceDateTimeTo != null)
                  _buildInfoRow(
                    'To',
                    caseDoc.occurrenceDateTimeTo!,
                  ),
                if (caseDoc.timePeriod != null)
                  _buildInfoRow('Time Period', caseDoc.timePeriod!),
                if (caseDoc.priorToDateTimeDetails != null)
                  _buildInfoRow(
                    'Prior to Date/Time Details',
                    caseDoc.priorToDateTimeDetails!,
                  ),
                if (caseDoc.beatNumber != null)
                  _buildInfoRow('Beat Number', caseDoc.beatNumber!),
                if (caseDoc.placeOfOccurrenceStreet != null)
                  _buildInfoRow(
                    'Street / Village',
                    caseDoc.placeOfOccurrenceStreet!,
                  ),
                if (caseDoc.placeOfOccurrenceArea != null)
                  _buildInfoRow(
                    'Area / Mandal',
                    caseDoc.placeOfOccurrenceArea!,
                  ),
                if (caseDoc.placeOfOccurrenceCity != null)
                  _buildInfoRow(
                    'City / District',
                    caseDoc.placeOfOccurrenceCity!,
                  ),
                if (caseDoc.placeOfOccurrenceState != null)
                  _buildInfoRow(
                    'State',
                    caseDoc.placeOfOccurrenceState!,
                  ),
                if (caseDoc.placeOfOccurrencePin != null)
                  _buildInfoRow('PIN', caseDoc.placeOfOccurrencePin!),
                if (caseDoc.placeOfOccurrenceLatitude != null)
                  _buildInfoRow(
                    'Latitude',
                    caseDoc.placeOfOccurrenceLatitude!,
                  ),
                if (caseDoc.placeOfOccurrenceLongitude != null)
                  _buildInfoRow(
                    'Longitude',
                    caseDoc.placeOfOccurrenceLongitude!,
                  ),
                if (caseDoc.distanceFromPS != null)
                  _buildInfoRow(
                    'Distance from PS',
                    caseDoc.distanceFromPS!,
                  ),
                if (caseDoc.directionFromPS != null)
                  _buildInfoRow(
                    'Direction from PS',
                    caseDoc.directionFromPS!,
                  ),
                if (caseDoc.isOutsideJurisdiction != null)
                  _buildInfoRow(
                    'Outside Jurisdiction',
                    _boolText(caseDoc.isOutsideJurisdiction),
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Information received
          if (caseDoc.informationReceivedDateTime != null ||
              caseDoc.generalDiaryEntryNumber != null ||
              caseDoc.informationType != null)
            _buildSection(
              theme,
              'Information Received at PS',
              [
                if (caseDoc.informationReceivedDateTime != null)
                  _buildInfoRow(
                    'Date & Time Received',
                    caseDoc.informationReceivedDateTime!,
                  ),
                if (caseDoc.generalDiaryEntryNumber != null)
                  _buildInfoRow(
                    'GD Entry No.',
                    caseDoc.generalDiaryEntryNumber!,
                  ),
                if (caseDoc.informationType != null)
                  _buildInfoRow('Type of Information', caseDoc.informationType!),
              ],
            ),

          const SizedBox(height: 16),

          // Complainant
          if (caseDoc.complainantName != null)
            _buildSection(
              theme,
              'Complainant / Informant Details',
              [
                _buildInfoRow('Name', caseDoc.complainantName!),
                if (caseDoc.complainantFatherHusbandName != null)
                  _buildInfoRow(
                    'Father/Husband Name',
                    caseDoc.complainantFatherHusbandName!,
                  ),
                if (caseDoc.complainantGender != null)
                  _buildInfoRow('Gender', caseDoc.complainantGender!),
                if (caseDoc.complainantDob != null)
                  _buildInfoRow('Date of Birth', caseDoc.complainantDob!),
                if (caseDoc.complainantAge != null)
                  _buildInfoRow('Age', caseDoc.complainantAge!),
                if (caseDoc.complainantNationality != null)
                  _buildInfoRow(
                    'Nationality',
                    caseDoc.complainantNationality!,
                  ),
                if (caseDoc.complainantCaste != null)
                  _buildInfoRow('Caste', caseDoc.complainantCaste!),
                if (caseDoc.complainantOccupation != null)
                  _buildInfoRow(
                    'Occupation',
                    caseDoc.complainantOccupation!,
                  ),
                if (caseDoc.complainantMobileNumber != null)
                  _buildInfoRow(
                    'Mobile Number',
                    caseDoc.complainantMobileNumber!,
                  ),
                if (caseDoc.complainantAddress != null)
                  _buildInfoRow(
                    'Address',
                    caseDoc.complainantAddress!,
                  ),
                if (caseDoc.complainantPassportNumber != null ||
                    caseDoc.complainantPassportPlaceOfIssue != null ||
                    caseDoc.complainantPassportDateOfIssue != null)
                  const SizedBox(height: 8),
                if (caseDoc.complainantPassportNumber != null)
                  _buildInfoRow(
                    'Passport No.',
                    caseDoc.complainantPassportNumber!,
                  ),
                if (caseDoc.complainantPassportPlaceOfIssue != null)
                  _buildInfoRow(
                    'Passport Place of Issue',
                    caseDoc.complainantPassportPlaceOfIssue!,
                  ),
                if (caseDoc.complainantPassportDateOfIssue != null)
                  _buildInfoRow(
                    'Passport Date of Issue',
                    caseDoc.complainantPassportDateOfIssue!,
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Victim
          if (caseDoc.victimName != null ||
              caseDoc.isComplainantAlsoVictim != null)
            _buildSection(
              theme,
              'Victim Details',
              [
                if (caseDoc.victimName != null)
                  _buildInfoRow('Name', caseDoc.victimName!),
                if (caseDoc.victimFatherHusbandName != null)
                  _buildInfoRow(
                    'Father/Husband Name',
                    caseDoc.victimFatherHusbandName!,
                  ),
                if (caseDoc.victimGender != null)
                  _buildInfoRow('Gender', caseDoc.victimGender!),
                if (caseDoc.victimDob != null)
                  _buildInfoRow('Date of Birth', caseDoc.victimDob!),
                if (caseDoc.victimAge != null)
                  _buildInfoRow('Age', caseDoc.victimAge!),
                if (caseDoc.victimNationality != null)
                  _buildInfoRow('Nationality', caseDoc.victimNationality!),
                if (caseDoc.victimReligion != null)
                  _buildInfoRow('Religion', caseDoc.victimReligion!),
                if (caseDoc.victimCaste != null)
                  _buildInfoRow('Caste', caseDoc.victimCaste!),
                if (caseDoc.victimOccupation != null)
                  _buildInfoRow(
                    'Occupation',
                    caseDoc.victimOccupation!,
                  ),
                if (caseDoc.victimAddress != null)
                  _buildInfoRow('Address', caseDoc.victimAddress!),
                if (caseDoc.isComplainantAlsoVictim != null)
                  _buildInfoRow(
                    'Complainant is also the Victim',
                    _boolText(caseDoc.isComplainantAlsoVictim),
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Accused
          if (caseDoc.accusedPersons != null &&
              caseDoc.accusedPersons!.isNotEmpty)
            _buildSection(
              theme,
              'Accused Details',
              [
                ...caseDoc.accusedPersons!.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final data = (entry.value as Map?) ?? {};
                  String valueOrEmpty(String key) =>
                      (data[key] as String?)?.trim().isNotEmpty == true
                          ? (data[key] as String).trim()
                          : '-';

                  // Build a readable physical-features string from the stored fields
                  final physicalParts = <String>[];
                  final build = (data['build'] as String?)?.trim();
                  final height = (data['heightCms'] as String?)?.trim();
                  final complexion = (data['complexion'] as String?)?.trim();
                  final deformities = (data['deformities'] as String?)?.trim();

                  if (build != null && build.isNotEmpty) {
                    physicalParts.add('Build: $build');
                  }
                  if (height != null && height.isNotEmpty) {
                    physicalParts.add('Height: ${height} cm');
                  }
                  if (complexion != null && complexion.isNotEmpty) {
                    physicalParts.add('Complexion: $complexion');
                  }
                  if (deformities != null && deformities.isNotEmpty) {
                    physicalParts.add('Deformities: $deformities');
                  }

                  final physicalFeatures =
                      physicalParts.isEmpty ? '-' : physicalParts.join(', ');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accused $index',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Name', valueOrEmpty('name')),
                        _buildInfoRow(
                          'Father/Husband Name',
                          valueOrEmpty('fatherHusbandName'),
                        ),
                        _buildInfoRow('Gender', valueOrEmpty('gender')),
                        _buildInfoRow('Age', valueOrEmpty('age')),
                        _buildInfoRow('Nationality', valueOrEmpty('nationality')),
                        _buildInfoRow('Caste', valueOrEmpty('caste')),
                        _buildInfoRow('Occupation', valueOrEmpty('occupation')),
                        _buildInfoRow('Cell No.', valueOrEmpty('cellNo')),
                        _buildInfoRow('Email', valueOrEmpty('email')),
                        _buildInfoRow('Address', valueOrEmpty('address')),
                        _buildInfoRow(
                          'Physical Features',
                          physicalFeatures,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),

          const SizedBox(height: 16),

          // Properties / Delay / Inquest
          if (caseDoc.propertiesDetails != null ||
              caseDoc.propertiesTotalValueInr != null ||
              caseDoc.isDelayInReporting != null ||
              caseDoc.inquestReportCaseNo != null)
            _buildSection(
              theme,
              'Properties / Delay / Inquest',
              [
                if (caseDoc.propertiesDetails != null)
                  _buildInfoRow(
                    'Properties Involved',
                    caseDoc.propertiesDetails!,
                  ),
                if (caseDoc.propertiesTotalValueInr != null)
                  _buildInfoRow(
                    'Total Value (INR)',
                    caseDoc.propertiesTotalValueInr!,
                  ),
                if (caseDoc.isDelayInReporting != null)
                  _buildInfoRow(
                    'Delay in Reporting',
                    _boolText(caseDoc.isDelayInReporting),
                  ),
                if (caseDoc.inquestReportCaseNo != null)
                  _buildInfoRow(
                    'Inquest Report / U.D. Case No.',
                    caseDoc.inquestReportCaseNo!,
                  ),
              ],
            ),

          const SizedBox(height: 16),

          // Acts & Complaint / Incident
          if (caseDoc.actsAndSectionsInvolved != null ||
              caseDoc.complaintStatement != null ||
              caseDoc.incidentDetails != null)
            _buildSection(
              theme,
              'Acts & Statement',
              [
                if (caseDoc.actsAndSectionsInvolved != null) ...[
                  Text(
                    'Acts & Sections Involved:',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caseDoc.actsAndSectionsInvolved!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                if (caseDoc.complaintStatement != null) ...[
                  Text(
                    'Complaint / Statement of Complainant:',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caseDoc.complaintStatement!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                if (caseDoc.incidentDetails != null) ...[
                  Text(
                    'Brief Incident Details:',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caseDoc.incidentDetails!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),

          const SizedBox(height: 16),

          // Action taken / Dispatch / Confirmation
          if (caseDoc.actionTakenDetails != null ||
              caseDoc.dispatchDateTime != null ||
              caseDoc.isFirReadOverAndAdmittedCorrect != null)
            _buildSection(
              theme,
              'Action Taken & Confirmation',
              [
                if (caseDoc.actionTakenDetails != null)
                  _buildInfoRow(
                    'Action Taken',
                    caseDoc.actionTakenDetails!,
                  ),
                if (caseDoc.investigatingOfficerName != null)
                  _buildInfoRow(
                    'Investigating Officer',
                    caseDoc.investigatingOfficerName!,
                  ),
                if (caseDoc.investigatingOfficerRank != null)
                  _buildInfoRow(
                    'Rank',
                    caseDoc.investigatingOfficerRank!,
                  ),
                if (caseDoc.investigatingOfficerDistrict != null)
                  _buildInfoRow(
                    'District',
                    caseDoc.investigatingOfficerDistrict!,
                  ),
                if (caseDoc.dispatchDateTime != null)
                  _buildInfoRow(
                    'Dispatch to Court (Date & Time)',
                    caseDoc.dispatchDateTime!,
                  ),
                if (caseDoc.dispatchOfficerName != null)
                  _buildInfoRow(
                    'Dispatching Officer',
                    caseDoc.dispatchOfficerName!,
                  ),
                if (caseDoc.dispatchOfficerRank != null)
                  _buildInfoRow(
                    'Dispatching Officer Rank',
                    caseDoc.dispatchOfficerRank!,
                  ),
                if (caseDoc.isFirReadOverAndAdmittedCorrect != null)
                  _buildInfoRow(
                    'FIR read over and admitted correct',
                    _boolText(caseDoc.isFirReadOverAndAdmittedCorrect),
                  ),
                if (caseDoc.isFirCopyGivenFreeOfCost != null)
                  _buildInfoRow(
                    'Copy of FIR given free of cost',
                    _boolText(caseDoc.isFirCopyGivenFreeOfCost),
                  ),
                if (caseDoc.isRoacRecorded != null)
                  _buildInfoRow(
                    'ROAC recorded',
                    _boolText(caseDoc.isRoacRecorded),
                  ),
                if (caseDoc.complainantSignatureNote != null)
                  _buildInfoRow(
                    'Signature / Thumb Impression',
                    caseDoc.complainantSignatureNote!,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCrimeSceneTab(CaseDoc caseDoc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Expanded(
                        child: Text(
                          'Crime Scene Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                      Expanded(
                        child: Text(
                          'Crime Scene Analysis Reports',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
        title: Text(
          report.originalFileName,
          overflow: TextOverflow.ellipsis,
        ),
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
                        overflow: TextOverflow.visible,
                        softWrap: true,
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
                Text(
                  report.sceneNarrative,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Case File Summary:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report.caseFileSummary,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestigationTab(CaseDoc caseDoc, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Expanded(
                        child: Text(
                          'Case Journal (IO\'s Diary)',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildEvidenceTab(CaseDoc caseDoc, ThemeData theme) {
    final hasJournalEvidence = _journalEntries.any(
      (e) => e.attachmentUrls != null && e.attachmentUrls!.isNotEmpty,
    );
    final hasPetitionEvidence = _linkedPetitions.any(
      (p) =>
          (p.proofDocumentUrls != null && p.proofDocumentUrls!.isNotEmpty) ||
          p.handwrittenDocumentUrl != null,
    );

    final isLoading = _isLoadingJournal || _isLoadingPetitions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Loading linked evidence from investigation diary and petitions...',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          if (!isLoading && !(hasJournalEvidence || hasPetitionEvidence))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.archive, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No linked evidence documents yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When officers attach documents in the Case Journal or upload proofs in related petitions, they will appear here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          if (hasJournalEvidence)
            _buildSection(
              theme,
              'From Investigation Diary',
              _buildJournalEvidenceWidgets(theme),
            ),
          if (hasPetitionEvidence)
            _buildSection(
              theme,
              'From Petitions',
              _buildPetitionEvidenceWidgets(theme),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildJournalEvidenceWidgets(ThemeData theme) {
    final List<Widget> widgets = [];

    for (final entry in _journalEntries) {
      if (entry.attachmentUrls == null || entry.attachmentUrls!.isEmpty) {
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.activityType,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(entry.dateTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < entry.attachmentUrls!.length; i++)
                    ActionChip(
                      avatar: const Icon(Icons.attach_file, size: 16),
                      label: Text('Journal Doc ${i + 1}'),
                      onPressed: () async {
                        final url = Uri.parse(entry.attachmentUrls![i]);
                        if (!await launchUrl(url,
                            mode: LaunchMode.externalApplication)) {
                          debugPrint('Could not open $url');
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          'No documents attached in the investigation diary yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildPetitionEvidenceWidgets(ThemeData theme) {
    final List<Widget> widgets = [];

    for (final petition in _linkedPetitions) {
      final List<String> docs = [];
      if (petition.handwrittenDocumentUrl != null) {
        docs.add(petition.handwrittenDocumentUrl!);
      }
      if (petition.proofDocumentUrls != null) {
        docs.addAll(petition.proofDocumentUrls!);
      }
      if (docs.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                petition.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                petition.type.displayName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < docs.length; i++)
                    ActionChip(
                      avatar: const Icon(Icons.picture_as_pdf, size: 16),
                      label: Text('Petition Doc ${i + 1}'),
                      onPressed: () async {
                        final url = Uri.parse(docs[i]);
                        if (!await launchUrl(url,
                            mode: LaunchMode.externalApplication)) {
                          debugPrint('Could not open $url');
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          'No petition documents linked to this case yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildFinalReportTab(CaseDoc caseDoc, ThemeData theme) {
    final String? pdfUrl = caseDoc.investigationReportPdfUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel, size: 48, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Final Investigation Report / Court Document',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (caseDoc.investigationReportGeneratedAt != null)
                Text(
                  'Generated on: ${_formatTimestamp(caseDoc.investigationReportGeneratedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              const SizedBox(height: 16),
              if (pdfUrl == null || pdfUrl.isEmpty) ...[
                Text(
                  'No final investigation report has been attached to this case yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Once an investigating officer generates and confirms the AI-assisted investigation report from the Case Journal screen, the final PDF will be linked here.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                Text(
                  'A court-ready investigation report PDF has been generated and attached to this case.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final String resolvedUrl = pdfUrl.startsWith('http')
                        ? pdfUrl
                        : 'https://fastapi-app-335340524683.asia-south1.run.app$pdfUrl';

                    final url = Uri.parse(resolvedUrl);
                    if (!await launchUrl(url,
                        mode: LaunchMode.externalApplication)) {
                      debugPrint('Could not open $url');
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download / View Final Report PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
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
    return SizedBox(
      width: double.infinity,
      child: Card(
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
            overflow: TextOverflow.visible,
            softWrap: true,
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
