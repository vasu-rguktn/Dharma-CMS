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
      debugPrint('AuthProvider: loading profile for uid=$uid');
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      debugPrint('AuthProvider: firestore get completed for uid=$uid, exists=${doc.exists}');
      if (doc.exists) {
        try {
          _userProfile = UserProfile.fromFirestore(doc);
          debugPrint('AuthProvider: parsed userProfile for uid=$uid -> displayName=${_userProfile?.displayName}, username=${_userProfile?.username}');

          // If profile fields are missing, try to backfill from FirebaseAuth (or email local-part)
          final updates = <String, dynamic>{};
          final firebaseName = _auth.currentUser?.displayName?.trim();
          final email = _auth.currentUser?.email;

          if ((_userProfile?.displayName == null || _userProfile!.displayName!.trim().isEmpty) && firebaseName != null && firebaseName.isNotEmpty) {
            updates['displayName'] = firebaseName;
          }

          if ((_userProfile?.username == null || _userProfile!.username!.trim().isEmpty) && email != null && email.isNotEmpty) {
            final localPart = email.split('@').first;
            if (localPart.isNotEmpty) updates['username'] = localPart;
          }

          if (updates.isNotEmpty) {
            debugPrint('AuthProvider: backfilling profile for uid=$uid with $updates');
            try {
              await docRef.update(updates);
              final refreshed = await docRef.get();
              if (refreshed.exists) {
                _userProfile = UserProfile.fromFirestore(refreshed);
                debugPrint('AuthProvider: refreshed userProfile for uid=$uid -> displayName=${_userProfile?.displayName}, username=${_userProfile?.username}');
              }
            } catch (e, st) {
              debugPrint('AuthProvider: failed to backfill profile for uid=$uid -> $e\n$st');
            }
          }
        } catch (e, st) {
          debugPrint('AuthProvider: error parsing UserProfile: $e\n$st');
          _userProfile = null;
        }
      } else {
        _userProfile = null;
      }
    } catch (e) {
      debugPrint('AuthProvider: error loading profile for uid=$uid -> $e');
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
    // Remove any keys with null values so we don't store nulls in Firestore
    data.removeWhere((key, value) => value == null);

    await _firestore.collection('users').doc(uid).set(data);
    await _loadUserProfile(uid);
  }
}