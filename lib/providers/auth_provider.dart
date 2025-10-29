// lib/providers/auth_provider.dart
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
  String? _verificationId;
  int? _resendToken;

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
      await _ensureUserProfile(firebaseUser);
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
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _userProfile = null;
    }

    _isProfileLoading = false;
    notifyListeners();
  }

  Future<void> _ensureUserProfile(User user) async {
    if (_userProfile != null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await createUserProfile(
        uid: user.uid,
        email: user.email,
        phoneNumber: user.phoneNumber,
        displayName: user.displayName ?? 'Anonymous User',
        role: 'citizen',
      );
    }
  }

  // ── Email/Password Sign In ──
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // ── Email/Password Sign Up ──
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

  // ── Google Sign In ──
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // ── Phone: Send OTP (FIXED for Resend) ──
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String, int?) onCodeSent,
    required Function(String) onError,
    bool isResend = false,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
      forceResendingToken: isResend ? _resendToken : null, // Only when resending
    );
  }

  // ── Phone: Verify OTP ──
  Future<UserCredential?> verifyOtp(String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  // ── Create or Update Profile ──
  Future<void> createUserProfile({
    required String uid,
    String? email,
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
    String role = 'citizen',
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
      }..removeWhere((key, value) => value == null);

      await _firestore.collection('users').doc(uid).set(profileData, SetOptions(merge: true));
      await _loadUserProfile(uid);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  // ── Sign Out ──
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}