import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/services/storage_service.dart';

class PetitionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Petition> _petitions = [];
  bool _isLoading = false;
  int _petitionCount = 0;

  // Separate stats to avoid collisions
  Map<String, int> _globalStats = {
    'total': 0,
    'closed': 0,
    'received': 0,
    'inProgress': 0,
  };

  Map<String, int> _userStats = {
    'total': 0,
    'closed': 0,
    'received': 0,
    'inProgress': 0,
  };

  List<Petition> get petitions => _petitions;
  bool get isLoading => _isLoading;
  int get petitionCount => _petitionCount;

  Map<String, int> get globalStats => _globalStats;
  Map<String, int> get userStats => _userStats;

  // Legacy getter for backward compatibility (returns global)
  Map<String, int> get stats => _globalStats;

  /// Fetch petitions belonging to a single user
  Future<void> fetchPetitions(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('petitions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _petitions =
          snapshot.docs.map((doc) => Petition.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Error fetching petitions: $e");
    }

    _isLoading = false;
    notifyListeners();
  }


  /// 🚓 Fetch petitions for POLICE by station name ✅
  Future<void> fetchPetitionsByStation(String stationName) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching petitions for station: $stationName');

      final snapshot = await _firestore
          .collection('petitions')
          .where('stationName', isEqualTo: stationName)
          .orderBy('createdAt', descending: true)
          .get();

      _petitions =
          snapshot.docs.map((doc) => Petition.fromFirestore(doc)).toList();

      debugPrint('✅ Fetched ${_petitions.length} petitions for station');
    } catch (e) {
      debugPrint('❌ Error fetching station petitions: $e');
      _petitions = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  String generateCaseId({
  required String district,
  required String stationName,
}) {
  final date = DateTime.now();
  final formattedDate =
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  final random = DateTime.now().millisecondsSinceEpoch
      .toString()
      .substring(7); // pseudo-random

  final safeDistrict = district.replaceAll(' ', '');
  final safeStation = stationName.replaceAll(' ', '');

  return 'case-$safeDistrict-$safeStation-$formattedDate-$random';
}


  /// Fetch petition stats (Total, Closed, Received, In Progress)
  /// If [userId] is provided, fetches stats for that specific user (Citizen)
  /// If [userId] is null, fetches global stats (Police)
  Future<void> fetchPetitionStats({String? userId}) async {
    try {
      debugPrint('🔍 fetchPetitionStats called with userId: $userId');

      final collection = _firestore.collection('petitions');

      // Base query
      Query query = collection;
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
        debugPrint('🔍 Querying petitions where userId == $userId');
      } else {
        debugPrint('🔍 Querying ALL petitions (police mode)');
      }

      // Fetch documents to count manually
      final snapshot = await query.get();
      debugPrint('🔍 Found ${snapshot.docs.length} total documents');

      int total = snapshot.docs.length;
      int closed = 0;
      int received = 0;
      int inProgress = 0;

      // Count by status
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final policeStatus = data['policeStatus'] as String?;
        final docUserId = data['userId'];

        debugPrint(
            '  📄 Doc ${doc.id}: userId=$docUserId, policeStatus=$policeStatus');

        if (policeStatus != null) {
          final statusLower = policeStatus.toLowerCase();

          if (statusLower.contains('close') ||
              statusLower.contains('resolve') ||
              statusLower.contains('reject')) {
            closed++;
          } else if (statusLower.contains('progress') ||
              statusLower.contains('investigation')) {
            inProgress++;
          } else if (statusLower.contains('receive') ||
              statusLower.contains('pending') ||
              statusLower.contains('acknowledge')) {
            received++;
          } else {
            received++; // Unknown status -> pending
          }
        } else {
          received++; // No status -> pending
        }
      }

      final statsMap = {
        'total': total,
        'closed': closed,
        'received': received,
        'inProgress': inProgress,
      };

      debugPrint('🔍 Final stats: $statsMap');

      if (userId != null) {
        _userStats = statsMap;
        debugPrint('🔍 Updated _userStats: $_userStats');
      } else {
        _globalStats = statsMap;
        _petitionCount = total;
        debugPrint('🔍 Updated _globalStats: $_globalStats');
      }

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error fetching petition stats: $e");
    }
  }

  /// Legacy method kept but redirected
  Future<void> fetchPetitionCount() async {
    await fetchPetitionStats();
  }

  /// Create a new petition with document uploads
  

     Future<bool> createPetition({
  required Petition petition,
  PlatformFile? handwrittenFile,
  List<PlatformFile>? proofFiles,
}) async {
  try {
    String? handwrittenUrl;
    List<String>? proofUrls;

    // ✅ GENERATE CASE ID ONCE
    final caseId = generateCaseId(
      district: petition.district ?? 'UnknownDistrict',
      stationName: petition.stationName ?? 'UnknownStation',
    );

    // Upload Handwritten Document
    if (handwrittenFile != null) {
      final timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-')
          .replaceAll(' ', '_');

      final fileName = 'Handwritten_${timestamp}_${handwrittenFile.name}';
      final path = 'petitions/${petition.userId}/handwritten/$fileName';

      handwrittenUrl =
          await StorageService.uploadFile(file: handwrittenFile, path: path);
    }

    // Upload Proof Documents
    if (proofFiles != null && proofFiles.isNotEmpty) {
      final timestamp = DateTime.now()
          .toString()
          .split('.')
          .first
          .replaceAll(':', '-')
          .replaceAll(' ', '_');

      final folderPath =
          'petitions/${petition.userId}/proofs/Proofs_$timestamp';

      proofUrls = await StorageService.uploadMultipleFiles(
        files: proofFiles,
        folderPath: folderPath,
      );
    }

    // Custom Petition ID
    final safeName =
        petition.petitionerName.replaceAll(' ', '_');
    final safeDate = DateTime.now()
        .toString()
        .replaceAll(' ', '_')
        .replaceAll(':', '-')
        .split('.')
        .first;

    final petitionCustomId = "Petition_${safeName}_$safeDate";

    // ✅ FINAL PETITION OBJECT
    final newPetition = Petition(
      id: petitionCustomId,
      caseId: caseId, // ✅ NOW WORKS
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

      policeStatus: 'Pending',
      policeSubStatus: petition.policeSubStatus,
      extractedText: petition.extractedText,
      handwrittenDocumentUrl: handwrittenUrl,
      proofDocumentUrls: proofUrls,

      userId: petition.userId,
      createdAt: petition.createdAt,
      updatedAt: petition.updatedAt,
    );

    await _firestore
        .collection('petitions')
        .doc(petitionCustomId)
        .set(newPetition.toMap());

    await fetchPetitions(petition.userId);
    await fetchPetitionStats(userId: petition.userId);
    await fetchPetitionStats();

    notifyListeners();
    return true;
  } catch (e) {
    debugPrint("Error creating petition: $e");
    return false;
  }
}

  /// Update any petition field (including police status fields)
  Future<bool> updatePetition(
    String petitionId,
    Map<String, dynamic> updates,
    String userId,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('petitions').doc(petitionId).update(updates);

      await fetchPetitions(userId);
      // Update user stats
      await fetchPetitionStats(userId: userId);
      // Update global stats
      await fetchPetitionStats();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("Error updating petition: $e");
      return false;
    }
  }

  /// Delete petition
  Future<bool> deletePetition(String petitionId) async {
    try {
      await _firestore.collection('petitions').doc(petitionId).delete();
      _petitions.removeWhere((p) => p.id == petitionId);

      await fetchPetitionStats();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting petition: $e");
      return false;
    }
  }
}

