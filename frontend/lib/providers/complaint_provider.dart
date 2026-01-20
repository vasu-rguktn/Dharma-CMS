import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? _currentUserId; // Store user ID for refresh logic

  // Check if a petition is already saved
  bool isPetitionSaved(String? petitionId) {
    if (petitionId == null) return false;
    // Check if any complaint originates from this petition ID (assuming we store it)
    // Or simpler: check if ID matches (if we use same ID)
    return _complaints.any((c) => c['originalPetitionId'] == petitionId);
  }

  Future<void> fetchComplaints({String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _firestore
          .collection('complaints')
          .orderBy('createdAt', descending: true);

      if (userId != null) {
        _currentUserId = userId; // Capture ID
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      _complaints = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching complaints: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle Save/Unsave for a Petition
  Future<bool> toggleSaveComplaint(
      Map<String, dynamic> petitionData, String userId) async {
    try {
      final String petitionId = petitionData['id'];

      // Check if already saved by querying
      // We'll use a compound ID or query to find duplicates.
      // Strategy: Use 'saved_${userId}_${petitionId}' as ID to ensure uniqueness per user.
      final String savedDocId = "saved_${userId}_${petitionId}";

      // Use Query to check existence (Safe with strict rules)
      final querySnap = await _firestore
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .where('originalPetitionId', isEqualTo: petitionId)
          .limit(1)
          .get();

      if (querySnap.docs.isNotEmpty) {
        // UNSAVE (Delete)
        // We can use the ID from the query, or the deterministic ID
        await _firestore.collection('complaints').doc(savedDocId).delete();
        await fetchComplaints(userId: userId); // Refresh
        return false; // Not saved anymore
      } else {
        // SAVE (Create)
        // Map Petition data to Complaint structure
        final docRef = _firestore.collection('complaints').doc(savedDocId);

        final complaintData = {
          ...petitionData,
          'originalPetitionId': petitionId,
          'savedAt': FieldValue.serverTimestamp(),
          'userId': userId, // Ensure it belongs to current user
          'status': 'Saved', // Visual indicator
          'isSaved': true,
        };

        await docRef.set(complaintData);
        await fetchComplaints(userId: userId); // Refresh
        return true; // Saved
      }
    } catch (e) {
      debugPrint("Error toggling save: $e");
      return false;
    }
  }

  /// Delete a complaint (Fixing the refresh bug)
  Future<void> deleteComplaint(String complaintId) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).delete();
      // Use stored user ID to refresh correctly
      await fetchComplaints(userId: _currentUserId);
    } catch (e) {
      debugPrint("Error deleting complaint: $e");
      throw e;
    }
  }
}
