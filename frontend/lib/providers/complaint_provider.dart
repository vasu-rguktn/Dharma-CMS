/// Complaint Provider — refactored to use backend API instead of direct Firestore.
///
/// BEFORE: Every method called `FirebaseFirestore.instance.collection(...)` directly.
/// AFTER:  Every method calls the centralized API service which hits the FastAPI backend.

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
    return _complaints.any((c) =>
        c['originalPetitionId'] == petitionId ||
        c['petition_id'] == petitionId);
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

  /// Toggle Save/Unsave for a Petition via backend.
  Future<bool> toggleSaveComplaint(
      Map<String, dynamic> petitionData, String userId) async {
    try {
      final String petitionId = petitionData['id'];

      // Check if already saved locally
      final existingIndex = _complaints.indexWhere((c) =>
          c['originalPetitionId'] == petitionId ||
          c['petition_id'] == petitionId);

      if (existingIndex >= 0) {
        // UNSAVE — delete from backend
        final docId = _complaints[existingIndex]['id'];
        if (docId != null) {
          await ComplaintDraftsApi.delete(userId, docId);
        }
        await fetchComplaints(userId: userId);
        return false; // Not saved anymore
      } else {
        // SAVE — create on backend
        final complaintData = {
          ...petitionData,
          'originalPetitionId': petitionId,
          'status': 'Saved',
          'isSaved': true,
        };
        await ComplaintDraftsApi.create(userId, complaintData);
        await fetchComplaints(userId: userId);
        return true; // Saved
      }
    } catch (e) {
      return false;
    }
  }

  /// Save AI Chat Session as a Draft via backend.
  Future<bool> saveChatAsDraft({
    required String userId,
    required String title,
    required Map<String, dynamic> chatData,
    String? draftId,
  }) async {
    try {
      final draftPayload = {
        'title': title,
        'type': 'AI Chat Draft',
        'isDraft': true,
        'status': 'Draft',
        'chatData': chatData,
        'petitionerName': 'Chat Session',
        'grounds': 'In-progress AI Legal Chat session',
      };

      if (draftId != null) {
        // Update existing draft
        await ComplaintDraftsApi.update(userId, draftId, draftPayload);
      } else {
        // Create new draft
        await ComplaintDraftsApi.create(userId, draftPayload);
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
      throw e;
    }
  }
}
