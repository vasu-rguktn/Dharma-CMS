import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nyay_setu_flutter/models/case_doc.dart';

class CaseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<CaseDoc> _cases = [];
  bool _isLoading = false;
  String? _error;

  List<CaseDoc> get cases => _cases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCases({String? userId, bool isAdmin = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _firestore.collection('cases').orderBy('dateFiled', descending: true);
      
      if (!isAdmin && userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      _cases = snapshot.docs.map((doc) => CaseDoc.fromFirestore(doc)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching cases: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCase(CaseDoc caseDoc) async {
    try {
      await _firestore.collection('cases').add(caseDoc.toMap());
      await fetchCases();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding case: $e');
      rethrow;
    }
  }

  Future<void> updateCase(String caseId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('cases').doc(caseId).update(updates);
      await fetchCases();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating case: $e');
      rethrow;
    }
  }

  Future<void> deleteCase(String caseId) async {
    try {
      await _firestore.collection('cases').doc(caseId).delete();
      _cases.removeWhere((c) => c.id == caseId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting case: $e');
      rethrow;
    }
  }
}
