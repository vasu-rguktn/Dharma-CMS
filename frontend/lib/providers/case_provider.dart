import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/models/case_doc.dart';
import 'package:dio/dio.dart';

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
      Query query =
          _firestore.collection('cases').orderBy('dateFiled', descending: true);

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

  Future<void> addCase(CaseDoc caseDoc, {String locale = 'en'}) async {
    try {
      final dio = Dio();
      // Replace with your actual backend URL or use a global constant
      final String baseUrl = 'https://fastapi-app-335340524683.asia-south1.run.app';

      final response = await dio.post(
        '$baseUrl/api/cases/create',
        data: {
          'caseData': _sanitizeForJson(caseDoc.toMap()),
          'locale': locale,
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        await fetchCases();
      } else {
        throw Exception('Failed to create case: ${response.data}');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding case: $e');
      rethrow;
    }
  }

  /// Recursively converts Timestamp objects to ISO-8601 Strings for JSON serialization
  Map<String, dynamic> _sanitizeForJson(Map<String, dynamic> map) {
    final sanitized = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeForJson(value);
      } else if (value is List) {
        sanitized[key] = value.map((e) {
          if (e is Map<String, dynamic>) return _sanitizeForJson(e);
          if (e is Timestamp) return e.toDate().toIso8601String();
          return e;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
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
