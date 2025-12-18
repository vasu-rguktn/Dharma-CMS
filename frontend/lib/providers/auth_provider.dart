 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Dharma/models/user_profile.dart';
import 'package:Dharma/utils/validators.dart';
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isProfileLoading = true;
  bool _isPhoneVerifying = false;
  String? _verificationId;

  // ── GETTERS ───────────────────────────────────────────────────────
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isProfileLoading => _isProfileLoading;
  bool get isPhoneVerifying => _isPhoneVerifying;
  String? get verificationId => _verificationId;
  bool get isAuthenticated => _user != null;

  // ROLE GETTER
  String get role => _userProfile?.role ?? 'citizen';

  // Friendly display name getter: prefer displayName, then username,
  // then FirebaseAuth user's displayName, else 'User'. Trims empty strings.
  String get displayNameOrUsername {
    final profile = _userProfile;
    final profileDisplay = profile?.displayName?.trim();
    if (profileDisplay != null && profileDisplay.isNotEmpty) return profileDisplay;

    final profileUsername = profile?.username?.trim();
    if (profileUsername != null && profileUsername.isNotEmpty) return profileUsername;

    final firebaseName = _auth.currentUser?.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) return firebaseName;

    return 'User';
  }

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ── AUTH STATE LISTENER ───────────────────────────────────────────
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _user = firebaseUser;
    _isLoading = true;
    notifyListeners();

    if (firebaseUser != null) {
      debugPrint('AuthProvider: auth state changed -> user uid=${firebaseUser.uid}');
      try {
        await _loadUserProfile(firebaseUser.uid);
      } catch (e, st) {
        debugPrint('AuthProvider: _loadUserProfile threw: $e\n$st');
      }
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
    debugPrint('AuthProvider: checking police collection for uid=$uid');

    // 1️⃣ CHECK POLICE COLLECTION FIRST
    final policeQuery = await _firestore
        .collection('police')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (policeQuery.docs.isNotEmpty) {
      final doc = policeQuery.docs.first;
      _userProfile = UserProfile.fromFirestore(doc);

      // Force role
      _userProfile = _userProfile!.copyWith(role: 'police');

      debugPrint('AuthProvider: police profile loaded for uid=$uid');
      _isProfileLoading = false;
      notifyListeners();
      return;
    }

    debugPrint('AuthProvider: not police, checking users collection');

    // 2️⃣ CHECK USERS (CITIZEN)
    final userQuery = await _firestore
        .collection('users')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      _userProfile = UserProfile.fromFirestore(userQuery.docs.first);

      debugPrint('AuthProvider: citizen profile loaded for uid=$uid');
    } else {
      debugPrint('AuthProvider: no profile found for uid=$uid');
      _userProfile = null;
    }

  } catch (e, st) {
    debugPrint('AuthProvider: error loading profile -> $e\n$st');
    _userProfile = null;
  }

  _isProfileLoading = false;
  notifyListeners();
}

 
 
  Future<void> loadUserProfile(String uid) async {
  return await _loadUserProfile(uid);
}


  // ── EMAIL SIGN IN ─────────────────────────────────────────────────
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!Validators.isValidEmail(email)) {
  throw Exception('Invalid email');
}

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('signInWithEmail error: ${e.message}');
      rethrow;
    }
  }

  // ── EMAIL SIGN UP ─────────────────────────────────────────────────
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    if (!Validators.isValidEmail(email)) {
  throw Exception('Invalid email');
}

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('signUpWithEmail error: ${e.message}');
      rethrow;
    }
  }

  // ── GOOGLE SIGN IN ────────────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('signInWithGoogle error: ${e.message}');
      rethrow;
    }
  }

  // ── PHONE OTP SEND ────────────────────────────────────────────────
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String message) onError,
  }) async {
    if (!Validators.isValidIndianPhone(phoneNumber)) {
  onError('Enter a valid Indian mobile number');
  return;
}


    _isPhoneVerifying = true;
    _verificationId = null;
    notifyListeners();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isPhoneVerifying = false;
          notifyListeners();
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isPhoneVerifying = false;
          notifyListeners();
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _isPhoneVerifying = false;
      notifyListeners();
      onError(e.toString());
    }
  }

  // ── PHONE OTP VERIFY ──────────────────────────────────────────────
  Future<UserCredential?> verifyOtp(String otp) async {
    if (_verificationId == null) throw Exception('No verification ID');

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    return await _auth.signInWithCredential(credential);
  }

  // ── SIGN OUT ──────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) await GoogleSignIn().signOut();
    _verificationId = null;
    notifyListeners();
  }

  // ── CREATE USER PROFILE ───────────────────────────────────────────
 Future<void> createUserProfile({
  required String uid,
  required String email,
  String? displayName,
  String? phoneNumber,
  String? username,
  String? dob,
  String? gender,
  String? houseNo,
  String? address,
  String? district,
  
  String? pincode,
  String? stationName,
  String role = 'citizen',
}) async {
  // ── VALIDATIONS (ADDED CORRECTLY) ─────────────────────
  if (!Validators.isValidEmail(email)) {
    throw Exception('Invalid email');
  }

  if (displayName != null && !Validators.isValidName(displayName)) {
    throw Exception('Invalid name');
  }

  if (phoneNumber != null && !Validators.isValidIndianPhone(phoneNumber)) {
    throw Exception('Invalid phone number');
  }

  if (dob != null && !Validators.isValidDOB(dob)) {
    throw Exception('Invalid DOB');
  }

  if (pincode != null && !Validators.isValidIndianPincode(pincode)) {
    throw Exception('Invalid pincode');
  }

  // ── EXISTING LOGIC (UNCHANGED) ───────────────────────
  final now = Timestamp.now();
  final data = {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'phoneNumber': phoneNumber ?? '',
    'username': username,
    'dob': dob,
    'gender': gender,
    'houseNo': houseNo,
    'address': address,
    'district': district,
    
    'pincode': pincode,
    'stationName': stationName,
    'role': role,
    'createdAt': now,
    'updatedAt': now,
  };

  // Remove null values (existing logic)
  data.removeWhere((key, value) => value == null);

  await _firestore.collection('users').doc(uid).set(data);
  await _loadUserProfile(uid);
}
}