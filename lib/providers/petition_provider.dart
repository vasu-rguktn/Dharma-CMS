import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nyay_setu_flutter/models/petition.dart';

class PetitionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Petition> _petitions = [];
  bool _isLoading = false;

  List<Petition> get petitions => _petitions;
  bool get isLoading => _isLoading;

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
      print('Error fetching petitions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPetition(Petition petition) async {
    try {
      await _firestore.collection('petitions').add(petition.toMap());
      notifyListeners();
      return true;
    } catch (e) {
      print('Error creating petition: $e');
      return false;
    }
  }

  Future<bool> updatePetition(String petitionId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('petitions').doc(petitionId).update(updates);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating petition: $e');
      return false;
    }
  }

  Future<bool> deletePetition(String petitionId) async {
    try {
      await _firestore.collection('petitions').doc(petitionId).delete();
      _petitions.removeWhere((p) => p.id == petitionId);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting petition: $e');
      return false;
    }
  }
}
