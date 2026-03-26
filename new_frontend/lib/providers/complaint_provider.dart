import 'package:flutter/material.dart';
import 'package:dharma/services/api/complaint_drafts_api.dart';

class ComplaintProvider with ChangeNotifier {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isPetitionSaved(String? petitionId) {
    if (petitionId == null) return false;
    return _complaints.any((c) => c['originalPetitionId'] == petitionId || c['petition_id'] == petitionId);
  }

  Future<void> fetchComplaints({String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await ComplaintDraftsApi.list();
      _complaints = results.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleSaveComplaint(Map<String, dynamic> petitionData, String userId) async {
    try {
      final petitionId = petitionData['id'] as String;
      final idx = _complaints.indexWhere((c) => c['originalPetitionId'] == petitionId || c['petition_id'] == petitionId);
      if (idx >= 0) {
        final docId = _complaints[idx]['id'];
        if (docId != null) await ComplaintDraftsApi.delete(docId);
        await fetchComplaints();
        return false;
      } else {
        await ComplaintDraftsApi.create({...petitionData, 'originalPetitionId': petitionId, 'status': 'Saved', 'isSaved': true});
        await fetchComplaints();
        return true;
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> saveChatAsDraft({
    required String userId,
    required String title,
    required Map<String, dynamic> chatData,
    String? draftId,
  }) async {
    try {
      final payload = {
        'title': title,
        'type': 'AI Chat Draft',
        'isDraft': true,
        'status': 'Draft',
        'chatData': chatData,
        'petitionerName': 'Chat Session',
        'grounds': 'In-progress AI Legal Chat session',
      };
      if (draftId != null) {
        await ComplaintDraftsApi.update(draftId, payload);
      } else {
        await ComplaintDraftsApi.create(payload);
      }
      await fetchComplaints();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteComplaint(String complaintId) async {
    await ComplaintDraftsApi.delete(complaintId);
    await fetchComplaints();
  }
}
