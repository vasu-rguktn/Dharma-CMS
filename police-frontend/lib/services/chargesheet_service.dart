import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chargesheet_model.dart';

class ChargesheetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save a new chargesheet
  Future<void> saveChargesheet({
    required String content,
    String? caseId,
    String? firNumber,
    String? title,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    await _db.collection('chargesheets').add({
      'content': content,
      'caseId': caseId,
      'firNumber': firNumber,
      'officerId': user.uid,
      'title': title ?? 'Chargesheet - ${DateTime.now()}',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get stream of chargesheets for the current user
  Stream<List<ChargesheetModel>> getUserChargesheets() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _db
        .collection('chargesheets')
        .where('officerId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['createdAt'] == null) {
          data['createdAt'] = Timestamp.now(); // Handle pending writes
        }
        return ChargesheetModel.fromMap(data, doc.id);
      }).toList();

      // Sort client-side to avoid composite index requirement
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  // Delete a chargesheet
  Future<void> deleteChargesheet(String id) async {
    await _db.collection('chargesheets').doc(id).delete();
  }
}
