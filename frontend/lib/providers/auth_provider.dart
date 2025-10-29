// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:Dharma/models/user_profile.dart';

// class AuthProvider with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   // Initialize GoogleSignIn lazily only on mobile/desktop; on web use FirebaseAuth popup API
  
//   User? _user;
//   UserProfile? _userProfile;
//   bool _isLoading = true;
//   bool _isProfileLoading = true;

//   User? get user => _user;
//   UserProfile? get userProfile => _userProfile;
//   bool get isLoading => _isLoading;
//   bool get isProfileLoading => _isProfileLoading;
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

//   Future<UserCredential?> signInWithGoogle() async {
//     try {
//       if (kIsWeb) {
//         // On web, use Firebase Auth's popup directly; no google_sign_in_web clientId/meta required
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

//   Future<void> signOut() async {
//     try {
//       await _auth.signOut();
//       if (!kIsWeb) {
//         try {
//           await GoogleSignIn().signOut();
//         } catch (_) {}
//       }
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> createUserProfile({
//     required String uid,
//     required String email,
//     String? displayName,
//     String? phoneNumber,
//     String? stationName,
//     String? district,
//     String? rank,
//     String? badgeNumber,
//     String? employeeId,
//     String role = 'officer',
//   }) async {
//     try {
//       final now = Timestamp.now();
//       final profileData = {
//         'uid': uid,
//         'email': email,
//         'displayName': displayName,
//         'phoneNumber': phoneNumber,
//         'stationName': stationName,
//         'district': district,
//         'rank': rank,
//         'badgeNumber': badgeNumber,
//         'employeeId': employeeId,
//         'role': role,
//         'createdAt': now,
//         'updatedAt': now,
//       };

//       await _firestore.collection('users').doc(uid).set(profileData);
//       await _loadUserProfile(uid);
//     } catch (e) {
//       rethrow;
//     }
//   }
// }



















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

  // ===========================
  // 🔑 Authentication Methods
  // ===========================
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
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
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
      }
    } catch (e) {
      rethrow;
    }
  }

  // ===========================
  // 👤 Profile Creation Method
  // ===========================
  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
    String? houseNo,
    String? address,
    String? district,
    String? state,
    String? country,
    String? pincode,
    String? username,
    String? dob,
    String? gender,
    String? stationName,
    String? role = 'citizen',
  }) async {
    try {
      final now = Timestamp.now();

      final profileData = {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
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

      await _firestore.collection('users').doc(uid).set(profileData);
      await _loadUserProfile(uid);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }
}

