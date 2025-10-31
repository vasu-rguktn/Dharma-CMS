// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:Dharma/models/user_profile.dart';

// class AuthProvider with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   User? _user;
//   UserProfile? _userProfile;
//   bool _isLoading = true;
//   bool _isProfileLoading = true;
//   bool _isPhoneVerifying = false;
//   String? _verificationId;

//   // Getters
//   User? get user => _user;
//   UserProfile? get userProfile => _userProfile;
//   bool get isLoading => _isLoading;
//   bool get isProfileLoading => _isProfileLoading;
//   bool get isPhoneVerifying => _isPhoneVerifying;
//   String? get verificationId => _verificationId;
//   bool get isAuthenticated => _user != null;

//   AuthProvider() {
//     _auth.authStateChanges().listen(_onAuthStateChanged);
//   }

//   Future<void> _onAuthStateChanged(User? firebaseUser) async {
//     _user = firebaseUser;
//     _isLoading = true;
//     notifyListeners();

//     if (firebaseUser != null) {
//       await _loadUserProfile(firebaseUser.uid);
//     } else {
//       _userProfile = null;
//       _isProfileLoading = false;
//     }

//     _isLoading = false;
//     notifyListeners();
//   }

//   Future<void> _loadUserProfile(String uid) async {
//     _isProfileLoading = true;
//     notifyListeners();

//     try {
//       final doc = await _firestore.collection('users').doc(uid).get();
//       if (doc.exists) {
//         _userProfile = UserProfile.fromFirestore(doc);
//       } else {
//         _userProfile = null;
//         debugPrint('User profile not found for UID: $uid');
//       }
//     } catch (e) {
//       debugPrint('Error loading user profile: $e');
//       _userProfile = null;
//     }

//     _isProfileLoading = false;
//     notifyListeners();
//   }

//   // ===========================
//   // Email Authentication
//   // ===========================
//   Future<UserCredential?> signInWithEmail(String email, String password) async {
//     try {
//       final credential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return credential;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<UserCredential?> signUpWithEmail(String email, String password) async {
//     try {
//       final credential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       return credential;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // ===========================
//   // Google Authentication
//   // ===========================
//   Future<UserCredential?> signInWithGoogle() async {
//     try {
//       if (kIsWeb) {
//         final googleProvider = GoogleAuthProvider();
//         return await _auth.signInWithPopup(googleProvider);
//       } else {
//         final GoogleSignIn googleSignIn = GoogleSignIn();
//         final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
//         if (googleUser == null) return null;

//         final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//         final credential = GoogleAuthProvider.credential(
//           accessToken: googleAuth.accessToken,
//           idToken: googleAuth.idToken,
//         );
//         return await _auth.signInWithCredential(credential);
//       }
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // ===========================
//   // Phone Authentication (Convenience Methods)
//   // ===========================

//   /// Sends OTP with callbacks
//   Future<void> sendOtp({
//     required String phoneNumber,
//     required bool isResend,
//     required void Function(String verificationId, int? resendToken) onCodeSent,
//     required void Function(String message) onError,
//   }) async {
//     try {
//       _isPhoneVerifying = true;
//       _verificationId = null;
//       notifyListeners();

//       await _auth.verifyPhoneNumber(
//         phoneNumber: phoneNumber,
//         verificationCompleted: (PhoneAuthCredential credential) async {
//           try {
//             await _auth.signInWithCredential(credential);
//           } catch (e) {
//             onError('Auto verification failed');
//           }
//         },
//         verificationFailed: (FirebaseAuthException e) {
//           _isPhoneVerifying = false;
//           _verificationId = null;
//           notifyListeners();
//           onError(e.message ?? 'Verification failed');
//         },
//         codeSent: (String verificationId, int? resendToken) {
//           _verificationId = verificationId;
//           _isPhoneVerifying = false;
//           notifyListeners();
//           onCodeSent(verificationId, resendToken);
//         },
//         codeAutoRetrievalTimeout: (String verificationId) {
//           _verificationId = verificationId;
//           _isPhoneVerifying = false;
//           notifyListeners();
//         },
//         timeout: const Duration(seconds: 60),
//       );
//     } catch (e) {
//       _isPhoneVerifying = false;
//       notifyListeners();
//       onError(e.toString());
//       rethrow;
//     }
//   }

//   /// Verifies OTP and returns UserCredential
//   Future<UserCredential?> verifyOtp(String otp) async {
//     if (_verificationId == null) {
//       throw Exception('No verification ID found. Send OTP first.');
//     }

//     try {
//       final credential = PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: otp,
//       );
//       return await _auth.signInWithCredential(credential);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // ===========================
//   // Sign Out
//   // ===========================
//   Future<void> signOut() async {
//     try {
//       await _auth.signOut();
//       if (!kIsWeb) {
//         try {
//           await GoogleSignIn().signOut();
//         } catch (_) {}
//       }
//       _verificationId = null;
//     } catch (e) {
//       rethrow;
//     }
//   }

//   // ===========================
//   // Profile Creation
//   // ===========================
//   Future<void> createUserProfile({
//     required String uid,
//     required String email,
//     String? displayName,
//     String? phoneNumber,
//     String? username,
//     String? dob,
//     String? gender,
//     String? houseNo,
//     String? address,
//     String? district,
//     String? state,
//     String? country,
//     String? pincode,
//     String? stationName,
//     String role = 'citizen',
//   }) async {
//     try {
//       final now = Timestamp.now();

//       final profileData = {
//         'uid': uid,
//         'email': email,
//         'phoneNumber': phoneNumber ?? '',
//         'displayName': displayName,
//         'username': username,
//         'dob': dob,
//         'gender': gender,
//         'houseNo': houseNo,
//         'address': address,
//         'district': district,
//         'state': state,
//         'country': country,
//         'pincode': pincode,
//         'stationName': stationName,
//         'role': role,
//         'createdAt': now,
//         'updatedAt': now,
//       };

//       await _firestore.collection('users').doc(uid).set(profileData);
//       await _loadUserProfile(uid);
//     } catch (e) {
//       debugPrint('Error creating user profile: $e');
//       rethrow;
//     }
//   }
// }



// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Dharma/models/user_profile.dart';

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

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ── AUTH STATE LISTENER ───────────────────────────────────────────
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
      }
    } catch (e) {
      _userProfile = null;
    }

    _isProfileLoading = false;
    notifyListeners();
  }

  // ── EMAIL SIGN IN ─────────────────────────────────────────────────
  Future<UserCredential?> signInWithEmail(String email, String password) async {
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
    String? state,
    String? country,
    String? pincode,
    String? stationName,
    String role = 'citizen',
  }) async {
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
      'state': state,
      'country': country,
      'pincode': pincode,
      'stationName': stationName,
      'role': role,
      'createdAt': now,
      'updatedAt': now,
    };

    await _firestore.collection('users').doc(uid).set(data);
    await _loadUserProfile(uid);
  }
}