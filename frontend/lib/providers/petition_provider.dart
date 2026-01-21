import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/models/petition_update.dart';
import 'package:Dharma/services/storage_service.dart';
import 'package:Dharma/utils/petition_filter.dart';

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

  /// 🔍 Fetch a single petition by caseId (for AI Investigation)
  Future<Petition?> fetchPetitionByCaseId(String caseId) async {
    try {
      debugPrint('🔍 Fetching petition with caseId: $caseId');

      final snapshot = await _firestore
          .collection('petitions')
          .where('case_id', isEqualTo: caseId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('❌ No petition found with caseId: $caseId');
        return null;
      }

      final petition = Petition.fromFirestore(snapshot.docs.first);
      debugPrint('✅ Found petition: ${petition.title}');
      return petition;
    } catch (e) {
      debugPrint('❌ Error fetching petition by caseId: $e');
      return null;
    }
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
  Future<void> fetchPetitionStats({
    String? userId,
    String? officerId,
    String? stationName,
    String? district,
    String? range,
  }) async {
    try {
      debugPrint(
          '🔍 fetchPetitionStats called | userId=$userId | officerId=$officerId | station=$stationName | district=$district | range=$range');

      // 1️⃣ Query Online Petitions
      Query onlineQuery = _firestore.collection('petitions');
      if (userId != null) {
        onlineQuery = onlineQuery.where('userId', isEqualTo: userId);
      } else if (stationName != null && stationName.isNotEmpty) {
        onlineQuery = onlineQuery.where('stationName', isEqualTo: stationName);
      } else if (district != null && district.isNotEmpty) {
        onlineQuery = onlineQuery.where('district', isEqualTo: district);
      }

      final onlineSnapshot = await onlineQuery.get();
      debugPrint('📊 Online documents found: ${onlineSnapshot.docs.length}');

      // 2️⃣ Query Offline Petitions (only for Police mode)
      int offlineTotal = 0;
      int offlineClosed = 0;
      int offlineReceived = 0;
      int offlineInProgress = 0;

      if (userId == null) {
        Map<String, QueryDocumentSnapshot> offlineDocsMap = {};
        
        // 1. Direct Assignments (Always check if officerId is provided)
        if (officerId != null && officerId.isNotEmpty) {
          final snap = await _firestore
              .collection('offlinepetitions')
              .where('assignedTo', isEqualTo: officerId)
              .get();
          for (var doc in snap.docs) {
            offlineDocsMap[doc.id] = doc;
          }
        }

        // 2. Organisational Assignments (Station > District > Range)
        if (stationName != null && stationName.isNotEmpty) {
          final snap = await _firestore
              .collection('offlinepetitions')
              .where('assignedToStation', isEqualTo: stationName)
              .get();
          for (var doc in snap.docs) {
            offlineDocsMap[doc.id] = doc;
          }
        } else if (district != null && district.isNotEmpty) {
          final snap = await _firestore
              .collection('offlinepetitions')
              .where('assignedToDistrict', isEqualTo: district)
              .get();
          for (var doc in snap.docs) {
            offlineDocsMap[doc.id] = doc;
          }
        } else if (range != null && range.isNotEmpty) {
          final snap = await _firestore
              .collection('offlinepetitions')
              .where('assignedToRange', isEqualTo: range)
              .get();
          for (var doc in snap.docs) {
            offlineDocsMap[doc.id] = doc;
          }
        }

        final offlineDocs = offlineDocsMap.values.toList();
        offlineTotal = offlineDocs.length;
        debugPrint('📊 Offline documents found: $offlineTotal');

        offlineTotal = offlineDocs.length;
        debugPrint('📊 Offline documents found: $offlineTotal');

        for (var doc in offlineDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['policeStatus'] as String? ?? '').toLowerCase();

          if (status.contains('close') ||
              status.contains('resolve') ||
              status.contains('reject')) {
            offlineClosed++;
          } else if (status.contains('progress') ||
              status.contains('investigation')) {
            offlineInProgress++;
          } else {
            offlineReceived++;
          }
        }
      }

      // 3️⃣ Aggregate Stats
      int total = onlineSnapshot.docs.length + offlineTotal;
      int closed = offlineClosed;
      int received = offlineReceived;
      int inProgress = offlineInProgress;

      for (var doc in onlineSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final policeStatus = data['policeStatus'] as String?;

        if (policeStatus != null) {
          final status = policeStatus.toLowerCase();

          if (status.contains('close') ||
              status.contains('resolve') ||
              status.contains('reject')) {
            closed++;
          } else if (status.contains('progress') ||
              status.contains('investigation')) {
            inProgress++;
          } else {
            received++;
          }
        } else {
          received++;
        }
      }

      final statsMap = {
        'total': total,
        'closed': closed,
        'received': received,
        'inProgress': inProgress,
      };

      if (userId != null) {
        _userStats = statsMap;
        debugPrint('✅ Updated USER stats: $_userStats');
      } else {
        _globalStats = statsMap;
        _petitionCount = total;
        debugPrint('✅ Updated GLOBAL (Police) stats: $_globalStats');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching petition stats: $e');
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

  /// Fetch filtered petitions by status
  Future<void> fetchFilteredPetitions({
    required bool isPolice,
    String? userId,
    String? officerId,
    String? stationName,
    String? district,
    String? range,
    required PetitionFilter filter,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔍 fetchFilteredPetitions | isPolice=$isPolice | officerId=$officerId | station=$stationName | district=$district | range=$range | filter=$filter');
      List<Petition> allPetitions = [];

      // 1️⃣ Fetch Online Petitions (Citizens usually submit online)
      Query onlineQuery = _firestore.collection('petitions');
      if (isPolice) {
        if (stationName != null && stationName.isNotEmpty) {
          onlineQuery = onlineQuery.where('stationName', isEqualTo: stationName);
        } else if (district != null && district.isNotEmpty) {
          onlineQuery = onlineQuery.where('district', isEqualTo: district);
        }
      } else if (userId != null) {
        onlineQuery = onlineQuery.where('userId', isEqualTo: userId);
      }
      final onlineSnapshot = await onlineQuery.get();
      allPetitions.addAll(onlineSnapshot.docs.map((d) => Petition.fromFirestore(d)));

      // 2️⃣ Fetch Offline Petitions (Direct + Organisational)
      if (isPolice) {
        Map<String, QueryDocumentSnapshot> offlineDocsMap = {};

        // 1. Direct Assignments
        if (officerId != null && officerId.isNotEmpty) {
          final snap = await _firestore
              .collection('offlinepetitions')
              .where('assignedTo', isEqualTo: officerId)
              .get();
          for (var doc in snap.docs) {
            offlineDocsMap[doc.id] = doc;
          }
        }

        // 2. Organisational Assignments
        if (stationName != null && stationName.isNotEmpty) {
          final snap = await _firestore
              .collection('offlinepetitions')
              .where('assignedToStation', isEqualTo: stationName)
              .get();
          for (var doc in snap.docs) {
            offlineDocsMap[doc.id] = doc;
          }
        } else if (district != null && district.isNotEmpty) {
          final snap = await _firestore
              .collection('offlinepetitions')
              .where('assignedToDistrict', isEqualTo: district)
              .get();
          for (var doc in snap.docs) {
            offlineDocsMap[doc.id] = doc;
          }
        } else if (range != null && range.isNotEmpty) {
          final snap = await _firestore
              .collection('offlinepetitions')
              .where('assignedToRange', isEqualTo: range)
              .get();
          for (var doc in snap.docs) {
            offlineDocsMap[doc.id] = doc;
          }
        }
        
        allPetitions.addAll(offlineDocsMap.values.map((d) => Petition.fromFirestore(d)));
      }

      // 🕒 Sort in memory (newest first)
      allPetitions.sort((a, b) => (b.createdAt).compareTo(a.createdAt));

      // 🔍 Filter by status
      _petitions = allPetitions.where((p) {
        final status = (p.policeStatus ?? '').toLowerCase();

        switch (filter) {
          case PetitionFilter.received:
            return status.isEmpty ||
                status.contains('pending') ||
                status.contains('received') ||
                status.contains('acknowledge');

          case PetitionFilter.inProgress:
            return status.contains('progress') ||
                status.contains('investigation');

          case PetitionFilter.closed:
            return status.contains('closed') ||
                status.contains('resolved') ||
                status.contains('rejected');

          case PetitionFilter.all:
            return true;
        }
      }).toList();
      
      debugPrint('✅ fetchFilteredPetitions found: ${_petitions.length} petitions');
    } catch (e) {
      debugPrint('❌ Error fetchFilteredPetitions: $e');
      _petitions = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /* ================= PETITION UPDATES (TIMELINE) ================= */

  /// Create a new petition update with optional photos and documents
  Future<bool> createPetitionUpdate({
    required String petitionId,
    required String updateText,
    required String addedBy,
    required String addedByUserId,
    List<PlatformFile>? photoFiles,
    List<PlatformFile>? documentFiles,
  }) async {
    try {
      List<String> photoUrls = [];
      List<Map<String, String>> documents = [];

      // Upload photos
      if (photoFiles != null && photoFiles.isNotEmpty) {
        final timestamp = DateTime.now()
            .toString()
            .split('.')
            .first
            .replaceAll(':', '-')
            .replaceAll(' ', '_');

        final photoFolderPath = 'petition_updates/$petitionId/photos/Photos_$timestamp';

        photoUrls = await StorageService.uploadMultipleFiles(
          files: photoFiles,
          folderPath: photoFolderPath,
        );
      }

      // Upload documents
      if (documentFiles != null && documentFiles.isNotEmpty) {
        final timestamp = DateTime.now()
            .toString()
            .split('.')
            .first
            .replaceAll(':', '-')
            .replaceAll(' ', '_');

        final docFolderPath = 'petition_updates/$petitionId/documents/Docs_$timestamp';

        final documentUrls = await StorageService.uploadMultipleFiles(
          files: documentFiles,
          folderPath: docFolderPath,
        );

        // Create document objects with name and url
        for (int i = 0; i < documentFiles.length; i++) {
          documents.add({
            'name': documentFiles[i].name,
            'url': documentUrls[i],
          });
        }
      }

      // Create the update
      final update = PetitionUpdate(
        petitionId: petitionId,
        updateText: updateText,
        photoUrls: photoUrls,
        documents: documents,
        addedBy: addedBy,
        addedByUserId: addedByUserId,
        createdAt: Timestamp.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('petition_updates')
          .add(update.toMap());

      debugPrint('✅ Petition update created successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating petition update: $e');
      return false;
    }
  }

  /// Fetch all updates for a specific petition
  Future<List<PetitionUpdate>> fetchPetitionUpdates(String petitionId) async {
    try {
      final snapshot = await _firestore
          .collection('petition_updates')
          .where('petitionId', isEqualTo: petitionId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => PetitionUpdate.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching petition updates: $e');
      return [];
    }
  }

  /// Stream petition updates in real-time
  Stream<List<PetitionUpdate>> streamPetitionUpdates(String petitionId) {
    return _firestore
        .collection('petition_updates')
        .where('petitionId', isEqualTo: petitionId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PetitionUpdate.fromFirestore(doc))
            .toList());
  }

  /* ================= OFFLINE PETITION ASSIGNMENT ================= */

  /// 📤 Fetch petitions SENT by this officer (assigned by them)
  /// Used in the "Sent" tab for high-level officers
  Future<void> fetchSentPetitions(String officerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching petitions sent by officer: $officerId');

      final snapshot = await _firestore
          .collection('petitions')
          .where('assignedBy', isEqualTo: officerId)
          .where('submissionType', isEqualTo: 'offline')
          .orderBy('assignedAt', descending: true)
          .get();

      _petitions =
          snapshot.docs.map((doc) => Petition.fromFirestore(doc)).toList();

      debugPrint('✅ Fetched ${_petitions.length} sent petitions');
    } catch (e) {
      debugPrint('❌ Error fetching sent petitions: $e');
      _petitions = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 📥 Fetch petitions ASSIGNED to this officer
  /// Used in the "Assigned" tab for all officers
  Future<void> fetchAssignedPetitions(String officerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching petitions assigned to officer: $officerId');

      final snapshot = await _firestore
          .collection('petitions')
          .where('assignedTo', isEqualTo: officerId)
          .where('submissionType', isEqualTo: 'offline')
          .orderBy('assignedAt', descending: true)
          .get();

      _petitions =
          snapshot.docs.map((doc) => Petition.fromFirestore(doc)).toList();

      debugPrint('✅ Fetched ${_petitions.length} assigned petitions');
    } catch (e) {
      debugPrint('❌ Error fetching assigned petitions: $e');
      _petitions = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 📊 Fetch petitions assigned to a specific station/district/range
  /// Used when viewing organizational assignments
  Future<void> fetchAssignedPetitionsByUnit({
    String? stationName,
    String? districtName,
    String? rangeName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🔍 Fetching petitions assigned to unit');

      Query query = _firestore
          .collection('petitions')
          .where('submissionType', isEqualTo: 'offline');

      if (stationName != null && stationName.isNotEmpty) {
        query = query.where('assignedToStation', isEqualTo: stationName);
        debugPrint('📍 Filtering by station: $stationName');
      } else if (districtName != null && districtName.isNotEmpty) {
        query = query.where('assignedToDistrict', isEqualTo: districtName);
        debugPrint('📍 Filtering by district: $districtName');
      } else if (rangeName != null && rangeName.isNotEmpty) {
        query = query.where('assignedToRange', isEqualTo: rangeName);
        debugPrint('📍 Filtering by range: $rangeName');
      }

      final snapshot = await query.orderBy('assignedAt', descending: true).get();

      _petitions =
          snapshot.docs.map((doc) => Petition.fromFirestore(doc)).toList();

      debugPrint('✅ Fetched ${_petitions.length} unit-assigned petitions');
    } catch (e) {
      debugPrint('❌ Error fetching unit-assigned petitions: $e');
      _petitions = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 📈 Get count of sent petitions by an officer
  Future<int> getSentPetitionsCount(String officerId) async {
    try {
      final snapshot = await _firestore
          .collection('petitions')
          .where('assignedBy', isEqualTo: officerId)
          .where('submissionType', isEqualTo: 'offline')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting sent petitions count: $e');
      return 0;
    }
  }

  /// 📈 Get count of assigned petitions to an officer
  Future<int> getAssignedPetitionsCount(String officerId) async {
    try {
      final snapshot = await _firestore
          .collection('petitions')
          .where('assignedTo', isEqualTo: officerId)
          .where('submissionType', isEqualTo: 'offline')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Error getting assigned petitions count: $e');
      return 0;
    }
  }

}
