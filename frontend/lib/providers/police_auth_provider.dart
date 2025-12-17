import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PoliceAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Logged-in police profile (cached)
  Map<String, dynamic>? _policeProfile;

  Map<String, dynamic>? get policeProfile => _policeProfile;

  /* =====================================================
   * POLICE REGISTRATION
   * ===================================================== */

  Future<void> registerPolice({
    required String name,
    required String email,
    required String password,
    required String district,
    required String stationName,
    required String rank,
  }) async {
    try {
      // 1️⃣ Create Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // 2️⃣ Save ONLY in police collection
      await _firestore.collection('police').doc(uid).set({
        'uid': uid,
        'displayName': name,
        'email': email,
        'district': district,
        'stationName': stationName,
        'rank': rank,
        'role': 'police',
        'isApproved': true, // later admin controlled
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (_) {
      throw Exception('Police registration failed');
    }
  }

  /* =====================================================
   * POLICE LOGIN
   * ===================================================== */

  Future<void> loginPolice({
    required String email,
    required String password,
  }) async {
    try {
      // 1️⃣ Login
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // 2️⃣ Fetch police profile
      final doc = await _firestore.collection('police').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        throw Exception('Not a police account');
      }

      final data = doc.data()!;

      // 3️⃣ Approval check
      if (data['isApproved'] != true) {
        await _auth.signOut();
        throw Exception('Police account not approved');
      }

      // 4️⃣ Cache police profile
      _policeProfile = data;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      rethrow;
    }
  }
  Future<void> loadPoliceProfileIfLoggedIn() async {
  final user = _auth.currentUser;
  if (user == null) return;

  final doc =
      await _firestore.collection('police').doc(user.uid).get();

  if (doc.exists) {
    _policeProfile = doc.data();
    notifyListeners();
  }
}


  /* =====================================================
   * LOGOUT
   * ===================================================== */

  Future<void> logout() async {
    _policeProfile = null;
    await _auth.signOut();
    notifyListeners();
  }

  /* =====================================================
   * ERROR HANDLING
   * ===================================================== */

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'user-not-found':
        return 'Account not found';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'Account disabled';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
