import 'package:flutter/material.dart';
import 'package:dharma/models/case_model.dart';
import 'package:dharma/services/api/cases_api.dart';

class CaseProvider with ChangeNotifier {
  List<CaseModel> _cases = [];
  CaseModel? _selectedCase;
  bool _isLoading = false;
  String? _error;

  List<CaseModel> get cases => _cases;
  CaseModel? get selectedCase => _selectedCase;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalCases => _cases.length;
  int get openCases => _cases.where((c) => c.isOpen).length;
  int get closedCases => _cases.where((c) => c.isClosed).length;

  Future<void> fetchCases({String? statusFilter}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await CasesApi.list(limit: 200, statusFilter: statusFilter);
      _cases = data.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCaseById(String caseId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await CasesApi.get(caseId);
      _selectedCase = CaseModel.fromJson(data);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createCase(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await CasesApi.create(data);
      await fetchCases();
      return res['id'] as String?;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCase(String caseId, Map<String, dynamic> data) async {
    try {
      await CasesApi.update(caseId, data);
      await fetchCases();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCase(String caseId) async {
    try {
      await CasesApi.delete(caseId);
      _cases.removeWhere((c) => c.id == caseId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearSelection() {
    _selectedCase = null;
    notifyListeners();
  }
}
