// lib/providers/petition_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/models/petition.dart';

class PetitionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Petition> _petitions = [];
  bool _isLoading = false;
  int _petitionCount = 0;

  List<Petition> get petitions => _petitions;
  bool get isLoading => _isLoading;
  int get petitionCount => _petitionCount;

  Future<void> fetchPetitions(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('petitions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _petitions = snapshot.docs
          .map((doc) => Petition.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching petitions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPetitionCount() async {
    try {
      final snapshot = await _firestore.collection('petitions').get();
      _petitionCount = snapshot.size;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching petition count: $e');
    }
  }

  Future<bool> createPetition(Petition petition) async {
    try {
      await _firestore.collection('petitions').add(petition.toMap());
      await fetchPetitions(petition.userId);
      await fetchPetitionCount();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creating petition: $e');
      return false;
    }
  }

  Future<bool> updatePetition(String petitionId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('petitions').doc(petitionId).update(updates);
      await fetchPetitionCount();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating petition: $e');
      return false;
    }
  }

  Future<bool> deletePetition(String petitionId) async {
    try {
      await _firestore.collection('petitions').doc(petitionId).delete();
      _petitions.removeWhere((p) => p.id == petitionId);
      await fetchPetitionCount();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting petition: $e');
      return false;
    }
  }
}