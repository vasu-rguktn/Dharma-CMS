import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dharma/models/user_profile.dart';
import 'package:dharma/utils/validators.dart';
import 'package:dharma/services/api/accounts_api.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _sessionTimestampKey = 'auth_session_timestamp';
  static const String _lastActivityKey = 'auth_last_activity';
  static const Duration _sessionDuration = Duration(hours: 3);

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isProfileLoading = true;
  bool _isPhoneVerifying = false;
  String? _verificationId;
  ConfirmationResult? _webConfirmationResult;

  // ── Getters ──
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isProfileLoading => _isProfileLoading;
  bool get isPhoneVerifying => _isPhoneVerifying;
  String? get verificationId => _verificationId;
  bool get isAuthenticated => _user != null;
  String get role => _userProfile?.role ?? 'citizen';

  String get displayNameOrUsername {
    final p = _userProfile;
    if (p?.displayName?.trim().isNotEmpty == true) return p!.displayName!;
    if (p?.username?.trim().isNotEmpty == true) return p!.username!;
    final fn = _auth.currentUser?.displayName?.trim();
    if (fn != null && fn.isNotEmpty) return fn;
    return 'User';
  }

  AuthProvider() {
    _initializeSession();
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ══════════════════════════════════════════════════════════════════
  //  SESSION MANAGEMENT
  // ══════════════════════════════════════════════════════════════════

  Future<void> _initializeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityStr = prefs.getString(_lastActivityKey);
      if (lastActivityStr != null) {
        final lastActivity = DateTime.parse(lastActivityStr);
        if (DateTime.now().difference(lastActivity) > _sessionDuration) {
          // Expired — will handle in _onAuthStateChanged
        }
      }
    } catch (_) {}
  }

  Future<void> _saveSessionTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();
    await prefs.setString(_sessionTimestampKey, now);
    await prefs.setString(_lastActivityKey, now);
  }

  Future<void> _updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, DateTime.now().toIso8601String());
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTimestampKey);
    await prefs.remove(_lastActivityKey);
  }

  Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_lastActivityKey);
    if (s == null) return false;
    return DateTime.now().difference(DateTime.parse(s)) <= _sessionDuration;
  }

  Future<void> updateLastActivity() async => _updateLastActivity();

  // ══════════════════════════════════════════════════════════════════
  //  AUTH STATE LISTENER
  // ══════════════════════════════════════════════════════════════════

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _user = firebaseUser;
    _isLoading = true;
    notifyListeners();

    if (firebaseUser != null) {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityStr = prefs.getString(_lastActivityKey);

      if (lastActivityStr == null) {
        await _saveSessionTimestamp();
      } else {
        final valid = await isSessionValid();
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
        await _updateLastActivity();
      }

      try {
        await _loadUserProfile(firebaseUser.uid);
      } catch (_) {}
    } else {
      _userProfile = null;
      _isProfileLoading = false;
    }

    _isLoading = false;
    notifyListeners();
  }
  // ══════════════════════════════════════════════════════════════════
  //  PROFILE (via backend API — PostgreSQL)
  // ══════════════════════════════════════════════════════════════════
  Future<void> _loadUserProfile(String uid) async {
    _isProfileLoading = true;
    notifyListeners();

    try {
      final data = await AccountsApi.getMyAccount();
      _userProfile = UserProfile.fromJson(data);

      // Also fetch citizen-specific profile and merge into UserProfile
      try {
        final citizenData = await AccountsApi.getMyCitizenProfile();
        _userProfile = _userProfile!.copyWith(
          dob: citizenData['dob'] as String?,
          gender: citizenData['gender'] as String?,
          aadharNumber: citizenData['aadhaar_number'] as String? ?? citizenData['aadhaarNumber'] as String?,
          houseNo: citizenData['house_no'] as String? ?? citizenData['houseNo'] as String?,
          address: citizenData['address_line1'] as String? ?? citizenData['addressLine1'] as String?,
          district: citizenData['district'] as String?,
          pincode: citizenData['pincode'] as String?,
        );
      } catch (_) {
        // Citizen profile not yet created — that's OK
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
            'role': 'citizen',
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

  Future<void> loadUserProfile(String uid) => _loadUserProfile(uid);

  // ══════════════════════════════════════════════════════════════════
  //  AUTH METHODS (Firebase only)
  // ══════════════════════════════════════════════════════════════════

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (!Validators.isValidEmail(email)) throw Exception('Invalid email');
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await _saveSessionTimestamp();
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
    await _saveSessionTimestamp();
    return credential;
  }

  // ── Phone OTP ──
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
    _webConfirmationResult = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        final result = await _auth.signInWithPhoneNumber(phoneNumber);
        _webConfirmationResult = result;
        _verificationId = result.verificationId;
        _isPhoneVerifying = false;
        notifyListeners();
        onCodeSent(result.verificationId, null);
      } else {
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (cred) async => await _auth.signInWithCredential(cred),
          verificationFailed: (e) {
            _isPhoneVerifying = false;
            notifyListeners();
            onError(e.message ?? 'Verification failed');
          },
          codeSent: (vid, token) {
            _verificationId = vid;
            _isPhoneVerifying = false;
            notifyListeners();
            onCodeSent(vid, token);
          },
          codeAutoRetrievalTimeout: (vid) => _verificationId = vid,
          timeout: const Duration(seconds: 60),
        );
      }
    } catch (e) {
      _isPhoneVerifying = false;
      notifyListeners();
      onError(e.toString());
    }
  }

  Future<UserCredential?> verifyOtp(String otp) async {
    if (kIsWeb) {
      if (_webConfirmationResult == null) throw Exception('No web confirmation result');
      final cred = await _webConfirmationResult!.confirm(otp);
      await _saveSessionTimestamp();
      return cred;
    }
    if (_verificationId == null) throw Exception('No verification ID');
    final cred = await _auth.signInWithCredential(
      PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: otp),
    );
    await _saveSessionTimestamp();
    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) await GoogleSignIn().signOut();
    await _clearSession();
    _verificationId = null;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════
  //  PROFILE CRUD (via backend API — PostgreSQL)
  // ══════════════════════════════════════════════════════════════════
  Future<void> createUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
    String? dob,
    String? gender,
    String? houseNo,
    String? address,
    String? district,
    String? pincode,
    String? aadharNumber,
    String role = 'citizen',
  }) async {
    if (!Validators.isValidEmail(email)) throw Exception('Invalid email');
    if (displayName != null && !Validators.isValidName(displayName)) throw Exception('Invalid name');

    // 1. Create account (display_name, phone_number, email, role)
    final accountData = <String, dynamic>{
      'email': email,
      'role': role,
    };
    if (displayName != null) accountData['displayName'] = displayName;
    if (phoneNumber != null) accountData['phoneNumber'] = phoneNumber;
    accountData.removeWhere((k, v) => v == null);
    await AccountsApi.createAccount(accountData);

    // 2. Create citizen profile (dob, gender, aadhaar, address fields)
    final citizenData = <String, dynamic>{};
    if (dob != null) citizenData['dob'] = dob;
    if (gender != null) citizenData['gender'] = gender;
    if (aadharNumber != null) citizenData['aadhaarNumber'] = aadharNumber;
    if (houseNo != null) citizenData['houseNo'] = houseNo;
    if (address != null) citizenData['addressLine1'] = address;
    if (district != null) citizenData['district'] = district;
    if (pincode != null) citizenData['pincode'] = pincode;
    if (citizenData.isNotEmpty) {
      await AccountsApi.createCitizenProfile(citizenData);
    }

    await _loadUserProfile(uid);
  }

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phoneNumber,
    String? dob,
    String? gender,
    String? houseNo,
    String? address,
    String? district,
    String? pincode,
    String? aadharNumber,
    // username kept for compatibility but not used by backend
    String? username,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (displayName != null && !Validators.isValidName(displayName)) throw Exception('Invalid name');

      // 1. Update Account (display_name, phone_number)
      final accountData = <String, dynamic>{};
      if (displayName != null) accountData['displayName'] = displayName;
      if (phoneNumber != null) accountData['phoneNumber'] = phoneNumber;
      if (accountData.isNotEmpty) {
        await AccountsApi.updateMyAccount(accountData);
      }

      // 2. Update or Create Citizen Profile (dob, gender, aadhaar, address fields)
      final citizenData = <String, dynamic>{};
      if (dob != null) citizenData['dob'] = dob;
      if (gender != null) citizenData['gender'] = gender;
      if (aadharNumber != null) citizenData['aadhaarNumber'] = aadharNumber;
      if (houseNo != null) citizenData['houseNo'] = houseNo;
      if (address != null) citizenData['addressLine1'] = address;
      if (district != null) citizenData['district'] = district;
      if (pincode != null) citizenData['pincode'] = pincode;
      if (citizenData.isNotEmpty) {
        try {
          await AccountsApi.updateMyCitizenProfile(citizenData);
        } catch (_) {
          // Profile doesn't exist yet — create it instead
          await AccountsApi.createCitizenProfile(citizenData);
        }
      }

      await _loadUserProfile(uid);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
