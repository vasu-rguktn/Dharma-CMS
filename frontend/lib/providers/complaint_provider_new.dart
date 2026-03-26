/// Refactored Complaint Provider — uses backend API instead of direct Firestore.
///
/// BEFORE: Every method called `FirebaseFirestore.instance.collection(...)` directly.
/// AFTER:  Every method calls the centralized API service which hits the FastAPI backend.
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Dharma/services/api/complaint_drafts_api.dart';

class ComplaintProvider with ChangeNotifier {
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? _currentUserId;

  /// Check if a petition is already saved.
  bool isPetitionSaved(String? petitionId) {
    if (petitionId == null) return false;
    return _complaints.any((c) => c['petition_id'] == petitionId);
  }

  /// Fetch all complaint drafts for the current user via backend.
  Future<void> fetchComplaints({String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');
      _currentUserId = uid;

      final results = await ComplaintDraftsApi.list(uid);
      _complaints = results.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return map;
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save an AI Chat Session as a Draft via backend.
  Future<bool> saveChatAsDraft({
    required String userId,
    required String title,
    required Map<String, dynamic> chatData,
    String? draftId,
  }) async {
    try {
      if (draftId != null) {
        // Update existing draft
        await ComplaintDraftsApi.update(userId, draftId, {
          'title': title,
          'status': 'in_progress',
          'extra': chatData,
        });
      } else {
        // Create new draft
        await ComplaintDraftsApi.create(userId, {
          'title': title,
          'status': 'in_progress',
          'extra': chatData,
        });
      }
      await fetchComplaints(userId: userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete a complaint draft via backend.
  Future<void> deleteComplaint(String complaintId) async {
    try {
      final uid = _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');
      await ComplaintDraftsApi.delete(uid, complaintId);
      await fetchComplaints(userId: uid);
    } catch (e) {
      rethrow;
    }
  }
}
