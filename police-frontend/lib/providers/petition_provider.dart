import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/models/petition_update.dart';
import 'package:Dharma/services/storage_service.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:dio/dio.dart';

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
    'escalated': 0,
  };

  Map<String, int> _userStats = {
    'total': 0,
    'closed': 0,
    'received': 0,
    'inProgress': 0,
    'escalated': 0,
  };

  List<Petition> get petitions => _petitions;
  bool get isLoading => _isLoading;
  int get petitionCount => _petitionCount;

  Map<String, int> get globalStats => _globalStats;
  Map<String, int> get userStats => _userStats;

  // Legacy getter for backward compatibility (returns global)
  Map<String, int> get stats => _globalStats;

  // Staging for Evidence from AI Chat
  List<PlatformFile> _tempEvidence = [];
  List<PlatformFile> get tempEvidence => _tempEvidence;

  void setTempEvidence(List<PlatformFile> files) {
    _tempEvidence = List.from(files);
    notifyListeners();
  }

  void clearTempEvidence() {
    _tempEvidence = [];
    notifyListeners();
  }

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
      int offlineEscalated = 0;

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
          final createdAt = data['createdAt'] as Timestamp?;

          final isClosed = status.contains('close') ||
              status.contains('resolve') ||
              status.contains('reject');

          if (isClosed) {
            offlineClosed++;
          } else if (status.contains('progress') ||
              status.contains('investigation')) {
            offlineInProgress++;
          } else {
            offlineReceived++;
          }

          // Escalation check
          final isInProgress = status.contains('progress') ||
              status.contains('investigation');
          if (!isClosed && !isInProgress && createdAt != null) {
            final days = DateTime.now().difference(createdAt.toDate()).inDays;
            if (days >= 15) offlineEscalated++;
          }
        }
      }

      // 3️⃣ Aggregate Stats
      int total = onlineSnapshot.docs.length + offlineTotal;
      int closed = offlineClosed;
      int received = offlineReceived;
      int inProgress = offlineInProgress;
      int escalated = offlineEscalated;

      for (var doc in onlineSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final policeStatus = data['policeStatus'] as String?;

        if (policeStatus != null) {
          final status = policeStatus.toLowerCase();
          final createdAt = data['createdAt'] as Timestamp?;

          final isClosed = status.contains('close') ||
              status.contains('resolve') ||
              status.contains('reject');

          if (isClosed) {
            closed++;
          } else if (status.contains('progress') ||
              status.contains('investigation')) {
            inProgress++;
          } else {
            received++;
          }

          // Escalation check
          final isInProgress = status.contains('progress') ||
              status.contains('investigation');
          if (!isClosed && !isInProgress && createdAt != null) {
            final days = DateTime.now().difference(createdAt.toDate()).inDays;
            if (days >= 15) escalated++;
          }
        } else {
          received++;
          final createdAt = data['createdAt'] as Timestamp?;
          if (createdAt != null) {
            final days = DateTime.now().difference(createdAt.toDate()).inDays;
            if (days >= 15) escalated++;
          }
        }
      }

      final statsMap = {
        'total': total,
        'closed': closed,
        'received': received,
        'inProgress': inProgress,
        'escalated': escalated,
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

    // ✅ GENERATE CUSTOM ID FIRST (Needed for Storage Path)
    final safeName =
        petition.petitionerName.replaceAll(' ', '_');
    final safeDate = DateTime.now()
        .toString()
        .replaceAll(' ', '_')
        .replaceAll(':', '-')
        .split('.')
        .first;

    final petitionCustomId = "Petition_${safeName}_$safeDate";

    // ✅ GENERATE CASE ID
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
      // Fix: Use 'petition-documents' bucket which is allowed in storage.rules
      final path = 'petition-documents/$petitionCustomId/$fileName';

      handwrittenUrl =
          await StorageService.uploadFile(file: handwrittenFile, path: path);
    }

    // Upload Proof Documents
    if (proofFiles != null && proofFiles.isNotEmpty) {
      // Fix: Use 'petition-documents' bucket
      // Note: storage.rules 'match /{filename}' implies single level, no sub-folders allowed deep inside
      final folderPath = 'petition-documents/$petitionCustomId';

      proofUrls = await StorageService.uploadMultipleFiles(
        files: proofFiles,
        folderPath: folderPath,
      );
      
      if (proofUrls.isEmpty) {
        throw Exception('Failed to upload proof documents. Please check your connection and try again.');
      }
    }

    // ✅ FINAL PETITION OBJECT
    final newPetition = Petition(
      id: petitionCustomId,
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

      policeStatus: 'Pending',
      policeSubStatus: petition.policeSubStatus,
      extractedText: petition.extractedText,
      handwrittenDocumentUrl: handwrittenUrl,
      proofDocumentUrls: proofUrls,

      userId: petition.userId,
      createdAt: petition.createdAt,
      updatedAt: petition.updatedAt,
      isAnonymous: petition.isAnonymous,
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

      // 🔥 Get the OLD status BEFORE updating Firestore
      String? oldPoliceStatus;
      if (updates.containsKey('policeStatus')) {
        final petitionDoc = await _firestore.collection('petitions').doc(petitionId).get();
        if (petitionDoc.exists) {
          oldPoliceStatus = petitionDoc.data()?['policeStatus'];
        }
      }

      // 1️⃣ Update Firestore
      await _firestore.collection('petitions').doc(petitionId).update(updates);

      // 2️⃣ Call citizen backend to trigger FCM notification (if status changed)
      if (updates.containsKey('policeStatus')) {
        try {
          final dio = Dio();
          
          // TODO: Replace with your actual backend URL
          // For local testing on physical device, use your PC's IP (e.g., 'http://192.168.1.5:8000')
          // For production, use your deployed URL
          const backendUrl = 'https://fastapi-app-335340524683.asia-south1.run.app'; // Citizen backend URL
          
          debugPrint('📡 [PETITION_UPDATE] Calling backend to trigger notification...');
          debugPrint('📡 URL: $backendUrl/api/petitions/$petitionId/update-status');
          debugPrint('📡 Old status: $oldPoliceStatus → New status: ${updates['policeStatus']}');
          
          final response = await dio.post(
            '$backendUrl/api/petitions/$petitionId/update-status',
            data: {
              'policeStatus': updates['policeStatus'],
              'policeSubStatus': updates['policeSubStatus'] ?? '',
              'oldPoliceStatus': oldPoliceStatus,  // 🔥 Pass old status!
              'officerId': 'police_officer_123', // TODO: Pass actual officer ID
              'officerName': 'Police Officer', // TODO: Pass actual officer name
              'notes': 'Status updated via police portal',
            },
          );
          
          if (response.statusCode == 200) {
            debugPrint('✅ [PETITION_UPDATE] Backend notified successfully');
            debugPrint('📱 Notification sent: ${response.data['notificationSent']}');
          } else {
            debugPrint('⚠️ [PETITION_UPDATE] Backend returned ${response.statusCode}');
          }
        } catch (apiError) {
          // Don't fail the whole operation if notification fails
          debugPrint('⚠️ [PETITION_UPDATE] Failed to notify backend: $apiError');
          debugPrint('📝 Firestore update succeeded, but notification may not have been sent');
        }
      }

      // 3️⃣ Refresh local data
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

          case PetitionFilter.escalated:
            return p.isEscalated;

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

  /// Refreshes a single petition in the list with latest data from Firestore
  Future<void> refreshSinglePetition(String petitionId) async {
    try {
      final doc = await _firestore.collection('petitions').doc(petitionId).get();
      if (doc.exists) {
        final updatedPetition = Petition.fromFirestore(doc);
        final index = _petitions.indexWhere((p) => p.id == petitionId);
        if (index != -1) {
          _petitions[index] = updatedPetition;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error refreshing single petition: $e");
    }
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
    String? aiStatus, // 'green', 'amber', 'red'
    double? aiScore,
  }) async {
    try {
      debugPrint('🚀 [PETITION_UPDATE] Creating update for petition: $petitionId');
      List<String> photoUrls = [];
      List<Map<String, String>> documents = [];

      // Upload photos
      if (photoFiles != null && photoFiles.isNotEmpty) {
        try {
          debugPrint('📸 [PETITION_UPDATE] Uploading ${photoFiles.length} photos');
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
          debugPrint('✅ [PETITION_UPDATE] Photos uploaded: ${photoUrls.length} URLs');
        } catch (photoError) {
          debugPrint('⚠️ [PETITION_UPDATE] Photo upload error: $photoError');
          // Continue without photos rather than failing completely
        }
      }

      // Upload documents
      if (documentFiles != null && documentFiles.isNotEmpty) {
        try {
          debugPrint('📄 [PETITION_UPDATE] Uploading ${documentFiles.length} documents');
          final timestamp = DateTime.now()
              .toString()
              .split('.')
              .first
              .replaceAll(':', '-')
              .replaceAll(' ', '_');

          final docFolderPath = 'petition_updates/$petitionId/documents/Docs_$timestamp';

          // Upload individually to maintain mapping between file name and URL
          for (var docFile in documentFiles) {
            final fileName = 'Doc_${timestamp}_${docFile.name}';
            final path = '$docFolderPath/$fileName';

            final url = await StorageService.uploadFile(file: docFile, path: path);
            
            if (url != null) {
              documents.add({
                'name': docFile.name, // Display name
                'url': url,
              });
            }
          }
          debugPrint('✅ [PETITION_UPDATE] Documents uploaded: ${documents.length} with URLs');
        } catch (docError) {
          debugPrint('⚠️ [PETITION_UPDATE] Document upload error: $docError');
          // Continue without documents rather than failing completely
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
        aiStatus: aiStatus,
        aiScore: aiScore,
      );

      // Save to Firestore
      await _firestore
          .collection('petition_updates')
          .add(update.toMap());

      debugPrint('✅ [PETITION_UPDATE] Petition update created successfully');
      
      // 🔔 Trigger notification to citizen via backend
      try {
        // Get petition userId for notification
        final petitionDoc = await _firestore.collection('petitions').doc(petitionId).get();
        final userId = petitionDoc.data()?['userId'];
        
        if (userId != null) {
          final dio = Dio();
          const backendUrl = 'https://fastapi-app-335340524683.asia-south1.run.app';
          
          debugPrint('📲 [PETITION_UPDATE] Notifying citizen about case update...');
          
          await dio.post(
            '$backendUrl/api/petitions/$petitionId/case-update-notification',
            data: {
              'userId': userId,
              'updateText': updateText,
              'addedBy': addedBy,
            },
          );
          
          debugPrint('✅ [PETITION_UPDATE] Notification request sent');
        }
      } catch (notifError) {
        debugPrint('⚠️ [PETITION_UPDATE] Notification failed (continuing): $notifError');
        // Don't fail the whole operation if notification fails
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ [PETITION_UPDATE] Error creating petition update: $e');
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

  /// Merges real updates with system-generated escalation updates
  List<PetitionUpdate> getUpdatesWithEscalations(Petition petition, List<PetitionUpdate> realUpdates) {
    List<PetitionUpdate> allUpdates = List.from(realUpdates);
    final createdDate = petition.createdAt.toDate();
    
    // Status check: only escalate if not closed/rejected/resolved
    final status = (petition.policeStatus ?? '').toLowerCase();
    final isResolved = status.contains('close') || status.contains('resolve') || status.contains('reject');
    
    if (isResolved) return realUpdates;

    // 15 days for SP
    final spEscalationDate = createdDate.add(const Duration(days: 15));
    if (DateTime.now().isAfter(spEscalationDate)) {
      allUpdates.add(PetitionUpdate(
        petitionId: petition.id ?? '',
        updateText: "⚠️ ESCALATION: Petition has been pending for over 15 days at the Police Station level. It has now been automatically escalated to the District Superintendent of Police (SP) for review.",
        addedBy: "System Auto-Escalation",
        addedByUserId: "system",
        createdAt: Timestamp.fromDate(spEscalationDate),
      ));
    }

    // 30 days for IG
    final igEscalationDate = createdDate.add(const Duration(days: 30));
    if (DateTime.now().isAfter(igEscalationDate)) {
      allUpdates.add(PetitionUpdate(
        petitionId: petition.id ?? '',
        updateText: "⚠️ ESCALATION: Petition remains pending after 30 days. It has been further escalated to the Range Inspector General (IG) for urgent attention.",
        addedBy: "System Auto-Escalation",
        addedByUserId: "system",
        createdAt: Timestamp.fromDate(igEscalationDate),
      ));
    }

    // Sort all updates by createdAt
    allUpdates.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    return allUpdates;
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
