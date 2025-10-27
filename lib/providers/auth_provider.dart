import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:Dharma/models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isProfileLoading = true;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isProfileLoading => _isProfileLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _user = firebaseUser;
    _isLoading = true;
    notifyListeners();

    if (firebaseUser != null) {
      await _loadUserProfile(firebaseUser.uid);
    } else {
      _userProfile = null;
      _isProfileLoading = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    _isProfileLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userProfile = UserProfile.fromFirestore(doc);
      } else {
        _userProfile = null;
        debugPrint('User profile not found for UID: $uid');
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _userProfile = null;
    }

    _isProfileLoading = false;
    notifyListeners();
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
    String? stationName,
    String? district,
    String? rank,
    String? badgeNumber,
    String? employeeId,
    String? houseNo,
    String? address,
    String? state,
    String? country,
    String? pincode,
    String? username,
    String? dob,
    String? gender,
    String role = 'citizen', // Default to 'citizen' for non-police users
  }) async {
    try {
      final now = Timestamp.now();
      final profileData = {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'stationName': stationName,
        'district': district,
        'rank': rank,
        'badgeNumber': badgeNumber,
        'employeeId': employeeId,
        'houseNo': houseNo,
        'address': address,
        'state': state,
        'country': country,
        'pincode': pincode,
        'username': username,
        'dob': dob,
        'gender': gender,
        'role': role,
        'createdAt': now,
        'updatedAt': now,
      }..removeWhere((key, value) => value == null); // Remove null fields

      await _firestore.collection('users').doc(uid).set(profileData);
      await _loadUserProfile(uid);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }
}