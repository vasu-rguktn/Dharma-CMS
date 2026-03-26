import 'package:flutter/material.dart';
import 'package:dharma_police/models/case_model.dart';
import 'package:dharma_police/services/api/cases_api.dart';

class CaseProvider with ChangeNotifier {
  List<CaseDoc> _cases = [];
  bool _isLoading = false;
  String? _error;

  List<CaseDoc> get cases => _cases;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get caseCount => _cases.length;

  Future<void> fetchCases({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await CasesApi.listCases(status: status);
      _cases = data.map((j) => CaseDoc.fromJson(j)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<CaseDoc?> createCase(Map<String, dynamic> data) async {
    try {
      final result = await CasesApi.createCase(data);
      await fetchCases();
      return CaseDoc.fromJson(result);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateCase(String id, Map<String, dynamic> data) async {
    try {
      await CasesApi.updateCase(id, data);
      await fetchCases();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCase(String id) async {
    try {
      await CasesApi.deleteCase(id);
      _cases.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
