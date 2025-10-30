import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/models/petition.dart';

class PetitionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Internal state
  List<Petition> _petitions = [];
  bool _isLoading = false;
  int _petitionCount = 0; // Non-nullable int for total petitions

  // Getters
  List<Petition> get petitions => _petitions;
  bool get isLoading => _isLoading;
  int get petitionCount => _petitionCount;

  // ✅ Fetch total petition count from Firestore
  Future<void> fetchPetitionCount() async {
    try {
      final AggregateQuery countQuery = _firestore.collection('petitions').count();
      final AggregateQuerySnapshot snapshot = await countQuery.get();

      // Use ?? 0 to safely handle nullable count (older Firestore versions)
      _petitionCount = snapshot.count ?? 0;
    } catch (e) {
      debugPrint('⚠️ Error fetching petition count: $e');
      _petitionCount = 0;
    }
    notifyListeners();
  }

  // ✅ Refresh count (can be called after create/update/delete)
  Future<void> refreshPetitionCount() async {
    await fetchPetitionCount();
  }

  // ✅ Fetch petitions for a specific user
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
      debugPrint('⚠️ Error fetching petitions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Create a new petition
  Future<bool> createPetition(Petition petition) async {
    try {
      await _firestore.collection('petitions').add(petition.toMap());
      await refreshPetitionCount(); // Refresh count after create
      return true;
    } catch (e) {
      debugPrint('⚠️ Error creating petition: $e');
      return false;
    }
  }

  // ✅ Update an existing petition
  Future<bool> updatePetition(
      String petitionId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('petitions').doc(petitionId).update(updates);
      await refreshPetitionCount();
      return true;
    } catch (e) {
      debugPrint('⚠️ Error updating petition: $e');
      return false;
    }
  }

  // ✅ Delete a petition
  Future<bool> deletePetition(String petitionId) async {
    try {
      await _firestore.collection('petitions').doc(petitionId).delete();
      _petitions.removeWhere((p) => p.id == petitionId);
      await refreshPetitionCount();
      return true;
    } catch (e) {
      debugPrint('⚠️ Error deleting petition: $e');
      return false;
    }
  }
}
