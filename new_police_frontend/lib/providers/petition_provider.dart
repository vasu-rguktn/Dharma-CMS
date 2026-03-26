import 'package:flutter/material.dart';
import 'package:dharma_police/models/petition_model.dart';
import 'package:dharma_police/services/api/petitions_api.dart';

class PetitionProvider with ChangeNotifier {
  List<Petition> _petitions = [];
  bool _isLoading = false;
  String? _error;

  List<Petition> get petitions => _petitions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get petitionCount => _petitions.length;

  int get pendingCount => _petitions.where((p) => p.status == 'pending').length;
  int get inProgressCount => _petitions.where((p) => p.status == 'in_progress').length;
  int get closedCount => _petitions.where((p) => p.status == 'closed').length;

  Future<void> fetchPetitions({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await PetitionsApi.listPetitions(status: status);
      _petitions = data.map((j) => Petition.fromJson(j)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updatePetitionStatus(String id, String status) async {
    try {
      await PetitionsApi.updatePetition(id, {'status': status});
      await fetchPetitions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> assignPetition(String petitionId, Map<String, dynamic> data) async {
    try {
      await PetitionsApi.assignPetition(petitionId, data);
      await fetchPetitions();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
