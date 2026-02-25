import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/services/storage_service.dart';
import 'package:Dharma/utils/rank_utils.dart';

/// Provider specifically for handling offline petition submissions and assignments
/// This manages petitions submitted by police officers on behalf of citizens
class OfflinePetitionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Petition> _offlinePetitions = [];
  List<Petition> _sentPetitions = [];
  List<Petition> _assignedPetitions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Petition> get offlinePetitions => _offlinePetitions;
  List<Petition> get sentPetitions => _sentPetitions;
  List<Petition> get assignedPetitions => _assignedPetitions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Generate a unique case ID for offline petition
  String _generateCaseId({
    required String district,
    required String stationName,
  }) {
    final date = DateTime.now();
    final formattedDate =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    final random = DateTime.now()
        .millisecondsSinceEpoch
        .toString()
        .substring(7); // pseudo-random

    final safeDistrict = district.replaceAll(' ', '');
    final safeStation = stationName.replaceAll(' ', '');

    return 'case-$safeDistrict-$safeStation-$formattedDate-$random';
  }

  /// Submit an offline petition to Firestore
  Future<String?> submitOfflinePetition({
    required Petition petition,
    PlatformFile? handwrittenFile,
    List<PlatformFile>? proofFiles,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String? handwrittenUrl;
      List<String>? proofUrls;

      // Generate case ID
      final caseId = _generateCaseId(
        district: petition.district ?? 'UnknownDistrict',
        stationName: petition.stationName ?? 'UnknownStation',
      );

      // Upload handwritten document if provided
      if (handwrittenFile != null) {
        final timestamp = DateTime.now()
            .toString()
            .split('.')
            .first
            .replaceAll(':', '-')
            .replaceAll(' ', '_');

        final fileName = 'Handwritten_${timestamp}_${handwrittenFile.name}';
        final path =
            'offline_petitions/${petition.submittedBy}/handwritten/$fileName';

        handwrittenUrl =
            await StorageService.uploadFile(file: handwrittenFile, path: path);
        debugPrint('✅ Handwritten document uploaded: $handwrittenUrl');
      }

      // Upload proof documents if provided
      if (proofFiles != null && proofFiles.isNotEmpty) {
        final timestamp = DateTime.now()
            .toString()
            .split('.')
            .first
            .replaceAll(':', '-')
            .replaceAll(' ', '_');

        final folderPath =
            'offline_petitions/${petition.submittedBy}/proofs/Proofs_$timestamp';

        proofUrls = await StorageService.uploadMultipleFiles(
          files: proofFiles,
          folderPath: folderPath,
        );
        debugPrint('✅ ${proofUrls.length} proof documents uploaded');
      }

      // Custom petition ID
      final safeName = petition.petitionerName.replaceAll(' ', '_');
      final safeDate = DateTime.now()
          .toString()
          .replaceAll(' ', '_')
          .replaceAll(':', '-')
          .split('.')
          .first;

      final petitionId = "OfflinePetition_${safeName}_$safeDate";

      // Create final petition object
      final finalPetition = Petition(
        id: petitionId,
        caseId: caseId,
        title: petition.title,
        type: petition.type,
        status: petition.status,
        petitionerName: petition.petitionerName,
        phoneNumber: petition.phoneNumber,
        address: petition.address,
        grounds: petition.grounds,
        incidentAddress: petition.incidentAddress,
        incidentDate: petition.incidentDate,
        district: petition.district,
        stationName: petition.stationName,
        prayerRelief: petition.prayerRelief,
        firNumber: petition.firNumber,
        nextHearingDate: petition.nextHearingDate,
        filingDate: petition.filingDate,
        orderDate: petition.orderDate,
        orderDetails: petition.orderDetails,
        policeStatus: petition.policeStatus ?? 'Received',
        policeSubStatus: petition.policeSubStatus,
        extractedText: petition.extractedText,
        handwrittenDocumentUrl: handwrittenUrl,
        proofDocumentUrls: proofUrls,
        // ⭐ OFFLINE SUBMISSION FIELDS ⭐
        submissionType: 'offline',
        submittedBy: petition.submittedBy,
        submittedByName: petition.submittedByName,
        submittedByRank: petition.submittedByRank,
        // ⭐ ASSIGNMENT FIELDS ⭐
        assignmentType: petition.assignmentType,
        assignedTo: petition.assignedTo,
        assignedToName: petition.assignedToName,
        assignedToRank: petition.assignedToRank,
        assignedToRange: petition.assignedToRange,
        assignedToDistrict: petition.assignedToDistrict,
        assignedToStation: petition.assignedToStation,
        assignedBy: petition.assignedBy,
        assignedByName: petition.assignedByName,
        assignedAt: petition.assignedAt,
        assignmentStatus: petition.assignmentStatus,
        assignmentNotes: petition.assignmentNotes,
        userId: petition.userId,
        createdAt: petition.createdAt,
        updatedAt: petition.updatedAt,
      );

      // Save to Firestore in 'offlinepetitions' collection
      await _firestore
          .collection('offlinepetitions')
          .doc(petitionId)
          .set(finalPetition.toMap());

      debugPrint('✅ Offline petition saved to Firestore: $petitionId');
      debugPrint('📊 Collection: offlinepetitions');
      debugPrint('📊 Case ID: $caseId');
      debugPrint('👤 Submitted by: ${petition.submittedByName}');
      debugPrint(
          '🎯 Assignment status: ${petition.assignmentStatus ?? "Not assigned"}');

      _isLoading = false;
      notifyListeners();

      return petitionId;
    } catch (e, stackTrace) {
      _error = e.toString();
      _isLoading = false;
      debugPrint('❌ Error submitting offline petition: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('❌ Error type: ${e.runtimeType}');
      notifyListeners();
      return null;
    }
  }

  /// Fetch petitions SENT by this officer (assigned by them)
  /// Used in the "Sent" tab for high-level officers
  Future<void> fetchSentPetitions(String officerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching petitions sent by officer: $officerId');

      final snapshot = await _firestore
          .collection('offlinepetitions')
          .where('assignedBy', isEqualTo: officerId)
          .orderBy('assignedAt', descending: true)
          .get();

      _sentPetitions =
          snapshot.docs.map((doc) => Petition.fromFirestore(doc)).toList();

      debugPrint('✅ Fetched ${_sentPetitions.length} sent petitions');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _sentPetitions = [];
      _isLoading = false;
      debugPrint('❌ Error fetching sent petitions: $e');
      notifyListeners();
    }
  }

  /// Fetch petitions ASSIGNED to this officer (Direct, Range, District, or Station)
  Future<void> fetchAssignedPetitions(String officerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching petitions assigned to officer: $officerId');

      // Get officer's profile to find their station, district, and range
      final officerDoc =
          await _firestore.collection('police').doc(officerId).get();
      final officerData = officerDoc.data();

      final officerStation = officerData?['stationName'] as String?;
      final officerDistrict = officerData?['district'] as String?;
      final officerRange = officerData?['range'] as String?;

      debugPrint(
          '👮 Officer Info: Station: $officerStation, District: $officerDistrict, Range: $officerRange, Rank: ${officerData?['rank']}');

      final officerRank = officerData?['rank'] as String?;
      final isRangeOfficer = RankUtils.isRangeLevelOfficer(officerRank);
      final isDistrictOfficer = RankUtils.isDistrictLevelOfficer(officerRank);
      final isStationOfficer = RankUtils.isStationLevelOfficer(officerRank);

      List<QueryDocumentSnapshot> allDocs = [];

      // Query 1: Petitions assigned directly to this specific officer (UID) - ALWAYS CHECK THIS
      final directAssignments = await _firestore
          .collection('offlinepetitions')
          .where('assignedTo', isEqualTo: officerId)
          .orderBy('assignedAt', descending: true)
          .get();
      allDocs.addAll(directAssignments.docs);
      debugPrint(
          '✅ Found ${directAssignments.docs.length} directly assigned petitions');

      // Query 2: Petitions assigned to officer's station - ONLY FOR STATION OFFICERS
      if (isStationOfficer &&
          officerStation != null &&
          officerStation.isNotEmpty) {
        final stationAssignments = await _firestore
            .collection('offlinepetitions')
            .where('assignedToStation', isEqualTo: officerStation)
            .orderBy('assignedAt', descending: true)
            .get();
        allDocs.addAll(stationAssignments.docs);
        debugPrint(
            '✅ Found ${stationAssignments.docs.length} station-assigned petitions');
      }

      // Query 3: Petitions assigned to officer's district - ONLY FOR DISTRICT OFFICERS (e.g., SP)
      if (isDistrictOfficer &&
          officerDistrict != null &&
          officerDistrict.isNotEmpty) {
        final districtAssignments = await _firestore
            .collection('offlinepetitions')
            .where('assignedToDistrict', isEqualTo: officerDistrict)
            .orderBy('assignedAt', descending: true)
            .get();
        allDocs.addAll(districtAssignments.docs);
        debugPrint(
            '✅ Found ${districtAssignments.docs.length} district-assigned petitions');
      }

      // Query 4: Petitions assigned to officer's range - ONLY FOR RANGE OFFICERS (e.g., IG/DIG)
      if (isRangeOfficer && officerRange != null && officerRange.isNotEmpty) {
        final rangeAssignments = await _firestore
            .collection('offlinepetitions')
            .where('assignedToRange', isEqualTo: officerRange)
            .orderBy('assignedAt', descending: true)
            .get();
        allDocs.addAll(rangeAssignments.docs);
        debugPrint(
            '✅ Found ${rangeAssignments.docs.length} range-assigned petitions');
      }

      // Combine all results and remove duplicates using Map by Document ID
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      List<Petition> petitionsList = uniqueDocs.values
          .map((doc) => Petition.fromFirestore(doc))
          .where((p) =>
              p.assignedBy !=
              officerId) // Filter out petitions sent by this officer
          .toList();

      // Sort combined list by assignedAt (newest first)
      petitionsList.sort((a, b) {
        final aTime = a.assignedAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.assignedAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });

      _assignedPetitions = petitionsList;
      debugPrint(
          '✅ Total unique assigned petitions: ${_assignedPetitions.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _assignedPetitions = [];
      _isLoading = false;
      debugPrint('❌ Error fetching assigned petitions: $e');
      notifyListeners();
    }
  }

  /// Fetch all offline petitions (for admin/monitoring)
  Future<void> fetchAllOfflinePetitions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching all offline petitions');

      final snapshot = await _firestore
          .collection('offlinepetitions')
          .orderBy('createdAt', descending: true)
          .get();

      _offlinePetitions =
          snapshot.docs.map((doc) => Petition.fromFirestore(doc)).toList();

      debugPrint('✅ Fetched ${_offlinePetitions.length} offline petitions');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _offlinePetitions = [];
      _isLoading = false;
      debugPrint('❌ Error fetching offline petitions: $e');
      notifyListeners();
    }
  }

  /// Update assignment status (accept/reject)
  Future<bool> updateAssignmentStatus({
    required String petitionId,
    required String newStatus, // 'accepted', 'rejected', 'in_progress'
    String? userId,
  }) async {
    try {
      debugPrint('🔄 Updating assignment status for $petitionId to $newStatus');

      await _firestore.collection('offlinepetitions').doc(petitionId).update({
        'assignmentStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Assignment status updated successfully');

      // Refresh the lists
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error updating assignment status: $e');
      notifyListeners();
      return false;
    }
  }

  /// Get count of sent petitions by an officer
  Future<int> getSentPetitionsCount(String officerId) async {
    try {
      final snapshot = await _firestore
          .collection('offlinepetitions')
          .where('assignedBy', isEqualTo: officerId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting sent petitions count: $e');
      return 0;
    }
  }

  /// Get count of assigned petitions to an officer
  Future<int> getAssignedPetitionsCount(String officerId) async {
    try {
      final snapshot = await _firestore
          .collection('offlinepetitions')
          .where('assignedTo', isEqualTo: officerId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting assigned petitions count: $e');
      return 0;
    }
  }

  /// Get count by assignment status
  Future<Map<String, int>> getAssignmentStatusCounts(String officerId) async {
    try {
      final pendingSnapshot = await _firestore
          .collection('offlinepetitions')
          .where('assignedTo', isEqualTo: officerId)
          .where('assignmentStatus', isEqualTo: 'pending')
          .count()
          .get();

      final acceptedSnapshot = await _firestore
          .collection('offlinepetitions')
          .where('assignedTo', isEqualTo: officerId)
          .where('assignmentStatus', isEqualTo: 'accepted')
          .count()
          .get();

      final rejectedSnapshot = await _firestore
          .collection('offlinepetitions')
          .where('assignedTo', isEqualTo: officerId)
          .where('assignmentStatus', isEqualTo: 'rejected')
          .count()
          .get();

      return {
        'pending': pendingSnapshot.count ?? 0,
        'accepted': acceptedSnapshot.count ?? 0,
        'rejected': rejectedSnapshot.count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Error getting assignment status counts: $e');
      return {
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
      };
    }
  }

  /// Clear all cached data
  void clearCache() {
    _offlinePetitions = [];
    _sentPetitions = [];
    _assignedPetitions = [];
    _error = null;
    notifyListeners();
  }
}
