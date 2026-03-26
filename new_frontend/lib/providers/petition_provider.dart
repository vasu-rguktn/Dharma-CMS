import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dharma/models/petition.dart';
import 'package:dharma/utils/petition_filter.dart';
import 'package:dharma/services/api/petitions_api.dart';

class PetitionProvider with ChangeNotifier {
  List<Petition> _petitions = [];
  bool _isLoading = false;
  int _petitionCount = 0;

  Map<String, int> _globalStats = {'total': 0, 'closed': 0, 'received': 0, 'inProgress': 0, 'escalated': 0};
  Map<String, int> _userStats = {'total': 0, 'closed': 0, 'received': 0, 'inProgress': 0, 'escalated': 0};

  List<Petition> get petitions => _petitions;
  bool get isLoading => _isLoading;
  int get petitionCount => _petitionCount;
  Map<String, int> get globalStats => _globalStats;
  Map<String, int> get userStats => _userStats;
  Map<String, int> get stats => _globalStats;

  List<PlatformFile> _tempEvidence = [];
  List<PlatformFile> get tempEvidence => _tempEvidence;
  void setTempEvidence(List<PlatformFile> files) { _tempEvidence = List.from(files); notifyListeners(); }
  void clearTempEvidence() { _tempEvidence = []; notifyListeners(); }

  Future<void> fetchPetitions(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await PetitionsApi.list();
      _petitions = results.map((item) => Petition.fromJson(Map<String, dynamic>.from(item as Map), item['id'] ?? '')).toList();
      _petitions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  String generateCaseId({required String district, required String stationName}) {
    final d = DateTime.now();
    final date = '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return 'case-${district.replaceAll(' ', '')}-${stationName.replaceAll(' ', '')}-$date-$rand';
  }

  Future<void> fetchPetitionStats({String? userId}) async {
    try {
      List<dynamic> results;
      if (userId != null) {
        results = await PetitionsApi.list(limit: 1000);
      } else {
        results = await PetitionsApi.listAll(limit: 1000);
      }
      final docs = results.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      int total = docs.length, closed = 0, received = 0, inProgress = 0, escalated = 0;
      for (var data in docs) {
        final status = (data['policeStatus'] as String? ?? '').toLowerCase();
        if (status.contains('close') || status.contains('resolve') || status.contains('reject')) {
          closed++;
        } else if (status.contains('progress') || status.contains('investigation')) {
          inProgress++;
        } else {
          received++;
        }
        // Escalation check
        if (!status.contains('close') && !status.contains('progress') && !status.contains('investigation')) {
          final dt = DateTime.tryParse(data['createdAt']?.toString() ?? '');
          if (dt != null && DateTime.now().difference(dt).inDays >= 15) escalated++;
        }
      }
      final m = {'total': total, 'closed': closed, 'received': received, 'inProgress': inProgress, 'escalated': escalated};
      if (userId != null) { _userStats = m; } else { _globalStats = m; _petitionCount = total; }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchPetitionCount() => fetchPetitionStats();

  Future<Map<String, String>?> createPetition({required Petition petition}) async {
    try {
      final caseId = generateCaseId(district: petition.district ?? 'Unknown', stationName: petition.stationName ?? 'Unknown');
      final safeName = petition.petitionerName.replaceAll(' ', '_');
      final safeDate = DateTime.now().toString().replaceAll(' ', '_').replaceAll(':', '-').split('.').first;
      final petitionCustomId = 'Petition_${safeName}_$safeDate';

      final data = petition.toJson();
      data['case_id'] = caseId;
      data['id'] = petitionCustomId;
      data['policeStatus'] = 'Pending';

      await PetitionsApi.create(data);
      await fetchPetitions(petition.userId);
      await fetchPetitionStats(userId: petition.userId);
      notifyListeners();
      return {'petitionId': petitionCustomId, 'caseId': caseId};
    } catch (_) {
      return null;
    }
  }

  Future<bool> updatePetition(String petitionId, Map<String, dynamic> updates, String userId) async {
    try {
      await PetitionsApi.update(petitionId, updates);
      await fetchPetitions(userId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deletePetition(String petitionId) async {
    try {
      await PetitionsApi.delete(petitionId);
      _petitions.removeWhere((p) => p.id == petitionId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> fetchFilteredPetitions({
    required bool isPolice,
    String? userId,
    String? stationName,
    String? district,
    required PetitionFilter filter,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      List<dynamic> results;
      if (isPolice) {
        results = await PetitionsApi.listAll(limit: 1000);
      } else if (userId != null) {
        results = await PetitionsApi.list(limit: 1000);
      } else {
        results = await PetitionsApi.listAll(limit: 1000);
      }
      var all = results.map((item) => Petition.fromJson(Map<String, dynamic>.from(item as Map), item['id'] ?? '')).toList();
      if (isPolice && stationName != null) all = all.where((p) => p.stationName == stationName).toList();
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _petitions = all.where((p) {
        final s = (p.policeStatus ?? '').toLowerCase();
        switch (filter) {
          case PetitionFilter.received: return s.isEmpty || s.contains('pending') || s.contains('received');
          case PetitionFilter.inProgress: return s.contains('progress') || s.contains('investigation');
          case PetitionFilter.closed: return s.contains('closed') || s.contains('resolved') || s.contains('rejected');
          case PetitionFilter.escalated: return p.isEscalated;
          case PetitionFilter.all: return true;
        }
      }).toList();
    } catch (_) {
      _petitions = [];
    }
    _isLoading = false;
    notifyListeners();
  }
}
