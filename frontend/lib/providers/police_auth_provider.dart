import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PoliceAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // 1️⃣ Create Firebase Auth account
      UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // 2️⃣ Store police profile in 'police' collection (for police-specific data)
      await _firestore.collection('police').doc(uid).set({
        'uid': uid,
        'displayName': name,
        'email': email,
        'district': district,
        'stationName': stationName,
        'rank': rank,
        'role': 'police',
        'isApproved': true, // keep true for now
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 3️⃣ Also store in 'users' collection for consistency with AuthProvider
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'displayName': name,
        'email': email,
        'district': district,
        'stationName': stationName,
        'rank': rank,
        'role': 'police',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
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
      // 1️⃣ Firebase Auth login
      UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // 2️⃣ Verify police profile exists
      final doc =
          await _firestore.collection('police').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        throw Exception('Not a police account');
      }

      // 3️⃣ Approval check
      if (doc.data()?['isApproved'] != true) {
        await _auth.signOut();
        throw Exception('Police account not approved');
      }

      // ✅ SUCCESS — DO NOT update UI state here
      // UI state is handled by AuthProvider
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      rethrow;
    }
  }

  /* =====================================================
   * LOGOUT
   * ===================================================== */

  Future<void> logout() async {
    await _auth.signOut();
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
