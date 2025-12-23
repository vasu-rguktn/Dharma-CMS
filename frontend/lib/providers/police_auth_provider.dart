import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PoliceAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _sessionTimestampKey = 'police_auth_session_timestamp';
  static const String _lastActivityKey = 'police_auth_last_activity';
  static const Duration _sessionDuration = Duration(hours: 3);

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
      // Save session timestamp on successful login
      await _saveSessionTimestamp();
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

    // Check if we have a session timestamp - if not, this is a restored session, save it
    final prefs = await SharedPreferences.getInstance();
    final lastActivityStr = prefs.getString(_lastActivityKey);
    
    if (lastActivityStr == null) {
      // No session timestamp found - this is likely a restored Firebase session
      // Save the session timestamp to maintain it
      debugPrint('PoliceAuthProvider: No session timestamp found, saving restored session...');
      await _saveSessionTimestamp();
    } else {
      // We have a session timestamp - check if it's still valid
      final sessionValid = await isSessionValid();
      if (!sessionValid) {
        debugPrint('PoliceAuthProvider: Session expired, signing out...');
        await _auth.signOut();
        await _clearSession();
        _policeProfile = null;
        notifyListeners();
        return;
      } else {
        // Session is valid, update last activity
        await _updateLastActivity();
      }
    }

    final doc = await _firestore.collection('police').doc(user.uid).get();

    if (doc.exists) {
      _policeProfile = doc.data();
      notifyListeners();
    }
  }

  // ── SESSION MANAGEMENT ───────────────────────────────────────────────
  
  /// Save session timestamp on successful login
  Future<void> _saveSessionTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(_sessionTimestampKey, now.toIso8601String());
      await prefs.setString(_lastActivityKey, now.toIso8601String());
      debugPrint('PoliceAuthProvider: Session timestamp saved');
    } catch (e) {
      debugPrint('PoliceAuthProvider: Error saving session timestamp: $e');
    }
  }

  /// Update last activity timestamp (called when user interacts with app)
  Future<void> _updateLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(_lastActivityKey, now.toIso8601String());
    } catch (e) {
      debugPrint('PoliceAuthProvider: Error updating last activity: $e');
    }
  }

  /// Clear session data
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionTimestampKey);
      await prefs.remove(_lastActivityKey);
      debugPrint('PoliceAuthProvider: Session cleared');
    } catch (e) {
      debugPrint('PoliceAuthProvider: Error clearing session: $e');
    }
  }

  /// Check if current session is valid
  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityStr = prefs.getString(_lastActivityKey);
      
      if (lastActivityStr == null) return false;
      
      final lastActivity = DateTime.parse(lastActivityStr);
      final now = DateTime.now();
      final timeSinceLastActivity = now.difference(lastActivity);
      
      return timeSinceLastActivity <= _sessionDuration;
    } catch (e) {
      debugPrint('PoliceAuthProvider: Error checking session validity: $e');
      return false;
    }
  }

  /// Update last activity (call this periodically or on user interactions)
  Future<void> updateLastActivity() async {
    await _updateLastActivity();
  }


  /* =====================================================
   * LOGOUT
   * ===================================================== */

  Future<void> logout() async {
    _policeProfile = null;
    await _auth.signOut();
    await _clearSession(); // Clear session data on logout
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
