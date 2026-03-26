import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dharma_police/models/user_profile.dart';
import 'package:dharma_police/utils/validators.dart';
import 'package:dharma_police/services/api/accounts_api.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _sessionTimestampKey = 'police_auth_session';
  static const String _lastActivityKey = 'police_auth_last_activity';
  static const Duration _sessionDuration = Duration(hours: 3);

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isProfileLoading = true;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isProfileLoading => _isProfileLoading;
  bool get isAuthenticated => _user != null;
  String get role => _userProfile?.role ?? 'police';

  String get displayNameOrUsername {
    final p = _userProfile;
    if (p?.displayName?.trim().isNotEmpty == true) return p!.displayName!;
    final fn = _auth.currentUser?.displayName?.trim();
    if (fn != null && fn.isNotEmpty) return fn;
    return 'Officer';
  }

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ═══════════════════════════════════════════════════════════
  //  SESSION
  // ═══════════════════════════════════════════════════════════

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString(_sessionTimestampKey, now);
    await prefs.setString(_lastActivityKey, now);
  }

  Future<void> _updateActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTimestampKey);
    await prefs.remove(_lastActivityKey);
  }

  Future<bool> _isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_lastActivityKey);
    if (s == null) return false;
    return DateTime.now().difference(DateTime.parse(s)) <= _sessionDuration;
  }

  // ═══════════════════════════════════════════════════════════
  //  AUTH STATE
  // ═══════════════════════════════════════════════════════════

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _user = firebaseUser;
    _isLoading = true;
    notifyListeners();

    if (firebaseUser != null) {
      final prefs = await SharedPreferences.getInstance();
      final lastActivity = prefs.getString(_lastActivityKey);
      if (lastActivity == null) {
        await _saveSession();
      } else {
        final valid = await _isSessionValid();
        if (!valid) {
          await _auth.signOut();
          await _clearSession();
          _user = null;
          _userProfile = null;
          _isLoading = false;
          _isProfileLoading = false;
          notifyListeners();
          return;
        }
        await _updateActivity();
      }
      try {
        await _loadUserProfile();
      } catch (_) {}
    } else {
      _userProfile = null;
      _isProfileLoading = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  PROFILE (via backend API — PostgreSQL)
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadUserProfile() async {
    _isProfileLoading = true;
    notifyListeners();
    try {
      final data = await AccountsApi.getMyAccount();
      _userProfile = UserProfile.fromJson(data);
      // Also try to load police-specific profile
      try {
        final policeData = await AccountsApi.getMyPoliceProfile();
        _userProfile = UserProfile(
          uid: _userProfile!.uid,
          email: _userProfile!.email,
          displayName: _userProfile!.displayName,
          phoneNumber: _userProfile!.phoneNumber,
          role: _userProfile!.role,
          photoUrl: _userProfile!.photoUrl,
          rank: policeData['rank'],
          district: policeData['district'],
          stationName: policeData['station_name'],
          rangeName: policeData['range_name'],
          circleName: policeData['circle_name'],
          sdpoName: policeData['sdpo_name'],
          isApproved: policeData['is_approved'] ?? false,
        );
      } catch (_) {
        // Police profile not yet created — that's OK
      }
    } catch (e) {
      // Account doesn't exist yet — auto-create it from Firebase user info
      _userProfile = null;
      try {
        final fbUser = _auth.currentUser;
        if (fbUser != null) {
          await AccountsApi.createAccount({
            'email': fbUser.email ?? '',
            'display_name': fbUser.displayName ?? '',
            'phone_number': fbUser.phoneNumber ?? '',
            'role': 'police',
          });
          // Now fetch the newly created account
          final data = await AccountsApi.getMyAccount();
          _userProfile = UserProfile.fromJson(data);
        }
      } catch (_) {
        // Still failed — user can try again later
        _userProfile = null;
      }
    }
    _isProfileLoading = false;
    notifyListeners();
  }

  Future<void> refreshProfile() => _loadUserProfile();

  // ═══════════════════════════════════════════════════════════
  //  AUTH METHODS
  // ═══════════════════════════════════════════════════════════

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!Validators.isValidEmail(email)) throw Exception('Invalid email');
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _saveSession();
    return cred;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!Validators.isValidEmail(email)) throw Exception('Invalid email');
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    if (!Validators.isValidEmail(email)) throw Exception('Invalid email');
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    UserCredential? credential;
    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      credential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken),
      );
    }
    await _saveSession();
    return credential;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) await GoogleSignIn().signOut();
    await _clearSession();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  PROFILE CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> createAccountAndPoliceProfile({
    required String displayName,
    required String email,
    required String rank,
    String? district,
    String? stationName,
    String? rangeName,
    String? circleName,
    String? sdpoName,
  }) async {
    // 1. Create account
    await AccountsApi.createAccount({
      'role': 'police',
      'display_name': displayName,
      'email': email,
    });

    // 2. Create police profile
    final profileData = <String, dynamic>{
      'rank': rank,
    };
    if (district != null) profileData['district'] = district;
    if (stationName != null) profileData['station_name'] = stationName;
    if (rangeName != null) profileData['range_name'] = rangeName;
    if (circleName != null) profileData['circle_name'] = circleName;
    if (sdpoName != null) profileData['sdpo_name'] = sdpoName;

    await AccountsApi.createPoliceProfile(profileData);
    await _loadUserProfile();
  }
}
