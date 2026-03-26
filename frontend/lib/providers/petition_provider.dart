/// Petition Provider — refactored to use backend API instead of direct Firestore.
///
/// BEFORE: Every method called `FirebaseFirestore.instance.collection('petitions')` directly.
/// AFTER:  Every method calls the centralized PetitionsApi which hits the FastAPI backend.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:file_picker/file_picker.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/models/petition_update.dart';
import 'package:Dharma/services/storage_service.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:Dharma/services/api/petitions_api.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetitionProvider with ChangeNotifier {
  List<Petition> _petitions = [];
  bool _isLoading = false;
  int _petitionCount = 0;

  // Separate stats to avoid collisions
  Map<String, int> _globalStats = {
    'total': 0, 'closed': 0, 'received': 0, 'inProgress': 0, 'escalated': 0,
  };
  Map<String, int> _userStats = {
    'total': 0, 'closed': 0, 'received': 0, 'inProgress': 0, 'escalated': 0,
  };

  List<Petition> get petitions => _petitions;
  bool get isLoading => _isLoading;
  int get petitionCount => _petitionCount;
  Map<String, int> get globalStats => _globalStats;
  Map<String, int> get userStats => _userStats;
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

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Fetch petitions belonging to a single user
  Future<void> fetchPetitions(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await PetitionsApi.list(userId);
      _petitions = results
          .map((item) => Petition.fromMap(
              Map<String, dynamic>.from(item as Map), item['id'] ?? ''))
          .toList();
      // Sort newest first
      _petitions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      // debugPrint("Error fetching petitions: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 🚓 Fetch petitions for POLICE by station name
  Future<void> fetchPetitionsByStation(String stationName) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results =
          await PetitionsApi.listAll(limit: 500, statusFilter: null);
      final allPetitions = results
          .map((item) => Petition.fromMap(
              Map<String, dynamic>.from(item as Map), item['id'] ?? ''))
          .toList();
      _petitions = allPetitions
          .where((p) => p.stationName == stationName)
          .toList();
      _petitions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _petitions = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 🔍 Fetch a single petition by caseId (for AI Investigation)
  Future<Petition?> fetchPetitionByCaseId(String caseId) async {
    try {
      final results = await PetitionsApi.listAll(limit: 500);
      final allPetitions = results
          .map((item) => Petition.fromMap(
              Map<String, dynamic>.from(item as Map), item['id'] ?? ''))
          .toList();
      return allPetitions.where((p) => p.caseId == caseId).firstOrNull;
    } catch (e) {
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
    final random =
        DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final safeDistrict = district.replaceAll(' ', '');
    final safeStation = stationName.replaceAll(' ', '');
    return 'case-$safeDistrict-$safeStation-$formattedDate-$random';
  }

  /// Fetch petition stats via backend
  Future<void> fetchPetitionStats({
    String? userId,
    String? officerId,
    String? stationName,
    String? district,
    String? range,
  }) async {
    try {
      // Fetch all relevant petitions via API
      List<dynamic> results;
      if (userId != null) {
        results = await PetitionsApi.list(userId, limit: 1000);
      } else {
        results = await PetitionsApi.listAll(limit: 1000);
      }

      final allDocs = results
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      // Filter by station/district if needed (for police)
      List<Map<String, dynamic>> filteredDocs;
      if (userId != null) {
        filteredDocs = allDocs;
      } else if (stationName != null && stationName.isNotEmpty) {
        filteredDocs =
            allDocs.where((d) => d['stationName'] == stationName).toList();
      } else if (district != null && district.isNotEmpty) {
        filteredDocs =
            allDocs.where((d) => d['district'] == district).toList();
      } else {
        filteredDocs = allDocs;
      }

      int total = filteredDocs.length;
      int closed = 0, received = 0, inProgress = 0, escalated = 0;

      for (var data in filteredDocs) {
        final status = (data['policeStatus'] as String? ?? '').toLowerCase();
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
        if (!isClosed &&
            !status.contains('progress') &&
            !status.contains('investigation')) {
          final createdAtStr = data['createdAt']?.toString();
          if (createdAtStr != null) {
            final createdAt = DateTime.tryParse(createdAtStr);
            if (createdAt != null) {
              final days = DateTime.now().difference(createdAt).inDays;
              if (days >= 15) escalated++;
            }
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
      } else {
        _globalStats = statsMap;
        _petitionCount = total;
      }

      notifyListeners();
    } catch (e) {
      // debugPrint('❌ Error fetching petition stats: $e');
    }
  }

  Future<void> fetchPetitionCount() async {
    await fetchPetitionStats();
  }

  /// Create a new petition with document uploads
  Future<Map<String, String>?> createPetition({
    required Petition petition,
    PlatformFile? handwrittenFile,
    List<PlatformFile>? proofFiles,
  }) async {
    try {
      String? handwrittenUrl;
      List<String>? proofUrls;

      final safeName = petition.petitionerName.replaceAll(' ', '_');
      final safeDate = DateTime.now()
          .toString()
          .replaceAll(' ', '_')
          .replaceAll(':', '-')
          .split('.')
          .first;
      final petitionCustomId = "Petition_${safeName}_$safeDate";

      final caseId = generateCaseId(
        district: petition.district ?? 'UnknownDistrict',
        stationName: petition.stationName ?? 'UnknownStation',
      );

      // Upload Handwritten Document (still uses Firebase Storage directly)
      if (handwrittenFile != null) {
        final timestamp = DateTime.now()
            .toString()
            .split('.')
            .first
            .replaceAll(':', '-')
            .replaceAll(' ', '_');
        final fileName = 'Handwritten_${timestamp}_${handwrittenFile.name}';
        final path = 'petition-documents/$petitionCustomId/$fileName';
        handwrittenUrl =
            await StorageService.uploadFile(file: handwrittenFile, path: path);
      }

      // Upload Proof Documents
      if (proofFiles != null && proofFiles.isNotEmpty) {
        final folderPath = 'petition-documents/$petitionCustomId';
        proofUrls = await StorageService.uploadMultipleFiles(
          files: proofFiles,
          folderPath: folderPath,
        );
        if (proofUrls.isEmpty) {
          throw Exception('Failed to upload proof documents.');
        }
      }

      // Build petition data map
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
        accusedDetails: petition.accusedDetails,
        stolenProperty: petition.stolenProperty,
        witnesses: petition.witnesses,
        evidenceStatus: petition.evidenceStatus,
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

      // Send to backend
      await PetitionsApi.create(petition.userId, newPetition.toMap());

      await fetchPetitions(petition.userId);
      await fetchPetitionStats(userId: petition.userId);
      await fetchPetitionStats();

      notifyListeners();
      return {
        'petitionId': petitionCustomId,
        'caseId': caseId,
        'petitionNumber': petitionCustomId,
      };
    } catch (e) {
      // debugPrint("Error creating petition: $e");
      return null;
    }
  }

  /// Update any petition field
  Future<bool> updatePetition(
    String petitionId,
    Map<String, dynamic> updates,
    String userId,
  ) async {
    try {
      await PetitionsApi.update(userId, petitionId, updates);
      await fetchPetitions(userId);
      await fetchPetitionStats(userId: userId);
      await fetchPetitionStats();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Submit feedback for a petition
  Future<bool> submitFeedback(
      String petitionId, double rating, String comment) async {
    try {
      await PetitionsApi.update(_uid, petitionId, {
        'feedbacks_append': {
          'rating': rating,
          'comment': comment,
          'createdAt': DateTime.now().toIso8601String(),
        },
      });
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete petition
  Future<bool> deletePetition(String petitionId) async {
    try {
      await PetitionsApi.delete(_uid, petitionId);
      _petitions.removeWhere((p) => p.id == petitionId);
      await fetchPetitionStats();
      notifyListeners();
      return true;
    } catch (e) {
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
      List<Petition> allPetitions = [];

      // Fetch via API
      List<dynamic> results;
      if (isPolice) {
        results = await PetitionsApi.listAll(limit: 1000);
      } else if (userId != null) {
        results = await PetitionsApi.list(userId, limit: 1000);
      } else {
        results = await PetitionsApi.listAll(limit: 1000);
      }

      allPetitions = results
          .map((item) => Petition.fromMap(
              Map<String, dynamic>.from(item as Map), item['id'] ?? ''))
          .toList();

      // Filter by station/district for police
      if (isPolice) {
        if (stationName != null && stationName.isNotEmpty) {
          allPetitions = allPetitions
              .where((p) => p.stationName == stationName)
              .toList();
        } else if (district != null && district.isNotEmpty) {
          allPetitions =
              allPetitions.where((p) => p.district == district).toList();
        }
      }

      // Sort in memory (newest first)
      allPetitions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Filter by status
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
    } catch (e) {
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

      // Upload photos (still uses Firebase Storage directly)
      if (photoFiles != null && photoFiles.isNotEmpty) {
        try {
          final timestamp = DateTime.now()
              .toString()
              .split('.')
              .first
              .replaceAll(':', '-')
              .replaceAll(' ', '_');
          final photoFolderPath =
              'petition_updates/$petitionId/photos/Photos_$timestamp';
          photoUrls = await StorageService.uploadMultipleFiles(
            files: photoFiles,
            folderPath: photoFolderPath,
          );
        } catch (photoError) {
          // Continue without photos
        }
      }

      // Upload documents
      if (documentFiles != null && documentFiles.isNotEmpty) {
        try {
          final timestamp = DateTime.now()
              .toString()
              .split('.')
              .first
              .replaceAll(':', '-')
              .replaceAll(' ', '_');
          final docFolderPath =
              'petition_updates/$petitionId/documents/Docs_$timestamp';
          for (var docFile in documentFiles) {
            final fileName = 'Doc_${timestamp}_${docFile.name}';
            final path = '$docFolderPath/$fileName';
            final url =
                await StorageService.uploadFile(file: docFile, path: path);
            if (url != null) {
              documents.add({'name': docFile.name, 'url': url});
            }
          }
        } catch (docError) {
          // Continue without documents
        }
      }

      // Create update via backend
      await PetitionsApi.createUpdate(_uid, petitionId, {
        'petitionId': petitionId,
        'updateText': updateText,
        'photoUrls': photoUrls,
        'documents': documents,
        'addedBy': addedBy,
        'addedByUserId': addedByUserId,
        'createdAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Fetch all updates for a specific petition
  Future<List<PetitionUpdate>> fetchPetitionUpdates(String petitionId) async {
    try {
      final results = await PetitionsApi.listUpdates(_uid, petitionId);
      return results
          .map((item) => PetitionUpdate.fromMap(
              Map<String, dynamic>.from(item as Map), item['id']))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream petition updates (compatibility — returns a single-value stream)
  Stream<List<PetitionUpdate>> streamPetitionUpdates(String petitionId) {
    return Stream.fromFuture(fetchPetitionUpdates(petitionId));
  }

  /// Merges real updates with system-generated escalation updates
  List<PetitionUpdate> getUpdatesWithEscalations(
      Petition petition, List<PetitionUpdate> realUpdates) {
    List<PetitionUpdate> allUpdates = List.from(realUpdates);
    final createdDate = petition.createdAt.toDate();

    final status = (petition.policeStatus ?? '').toLowerCase();
    final isResolved = status.contains('close') ||
        status.contains('resolve') ||
        status.contains('reject');

    if (isResolved) return realUpdates;

    final spEscalationDate = createdDate.add(const Duration(days: 15));
    if (DateTime.now().isAfter(spEscalationDate)) {
      allUpdates.add(PetitionUpdate(
        petitionId: petition.id ?? '',
        updateText:
            "⚠️ ESCALATION: Petition has been pending for over 15 days at the Police Station level. It has now been automatically escalated to the District Superintendent of Police (SP) for review.",
        addedBy: "System Auto-Escalation",
        addedByUserId: "system",
        createdAt: Timestamp.fromDate(spEscalationDate),
      ));
    }

    final igEscalationDate = createdDate.add(const Duration(days: 30));
    if (DateTime.now().isAfter(igEscalationDate)) {
      allUpdates.add(PetitionUpdate(
        petitionId: petition.id ?? '',
        updateText:
            "⚠️ ESCALATION: Petition remains pending after 30 days. It has been further escalated to the Range Inspector General (IG) for urgent attention.",
        addedBy: "System Auto-Escalation",
        addedByUserId: "system",
        createdAt: Timestamp.fromDate(igEscalationDate),
      ));
    }

    allUpdates.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return allUpdates;
  }

  /* ================= OFFLINE PETITION ASSIGNMENT ================= */

  Future<void> fetchSentPetitions(String officerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await PetitionsApi.listAll(limit: 1000);
      _petitions = results
          .map((item) => Petition.fromMap(
              Map<String, dynamic>.from(item as Map), item['id'] ?? ''))
          .where((p) =>
              p.assignedBy == officerId && p.submissionType == 'offline')
          .toList();
      _petitions.sort((a, b) =>
          (b.assignedAt ?? b.createdAt).compareTo(a.assignedAt ?? a.createdAt));
    } catch (e) {
      _petitions = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAssignedPetitions(String officerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await PetitionsApi.listAll(limit: 1000);
      _petitions = results
          .map((item) => Petition.fromMap(
              Map<String, dynamic>.from(item as Map), item['id'] ?? ''))
          .where((p) =>
              p.assignedTo == officerId && p.submissionType == 'offline')
          .toList();
      _petitions.sort((a, b) =>
          (b.assignedAt ?? b.createdAt).compareTo(a.assignedAt ?? a.createdAt));
    } catch (e) {
      _petitions = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAssignedPetitionsByUnit({
    String? stationName,
    String? districtName,
    String? rangeName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await PetitionsApi.listAll(limit: 1000);
      var all = results
          .map((item) => Petition.fromMap(
              Map<String, dynamic>.from(item as Map), item['id'] ?? ''))
          .where((p) => p.submissionType == 'offline')
          .toList();

      if (stationName != null && stationName.isNotEmpty) {
        all = all.where((p) => p.assignedToStation == stationName).toList();
      } else if (districtName != null && districtName.isNotEmpty) {
        all =
            all.where((p) => p.assignedToDistrict == districtName).toList();
      } else if (rangeName != null && rangeName.isNotEmpty) {
        all = all.where((p) => p.assignedToRange == rangeName).toList();
      }

      _petitions = all;
      _petitions.sort((a, b) =>
          (b.assignedAt ?? b.createdAt).compareTo(a.assignedAt ?? a.createdAt));
    } catch (e) {
      _petitions = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<int> getSentPetitionsCount(String officerId) async {
    try {
      final results = await PetitionsApi.listAll(limit: 1000);
      return results
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((d) =>
              d['assignedBy'] == officerId && d['submissionType'] == 'offline')
          .length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getAssignedPetitionsCount(String officerId) async {
    try {
      final results = await PetitionsApi.listAll(limit: 1000);
      return results
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((d) =>
              d['assignedTo'] == officerId && d['submissionType'] == 'offline')
          .length;
    } catch (e) {
      return 0;
    }
  }
}
