import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:Dharma/models/user_profile.dart';
import 'package:Dharma/utils/validators.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Dharma/services/notification_service.dart';
import 'package:Dharma/services/api/accounts_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

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
    if (profileDisplay != null && profileDisplay.isNotEmpty)
      return profileDisplay;

    final profileUsername = profile?.username?.trim();
    if (profileUsername != null && profileUsername.isNotEmpty)
      return profileUsername;

    final firebaseName = _auth.currentUser?.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) return firebaseName;

    return 'User';
  }

  AuthProvider() {
    _initializeSession();
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ── SESSION MANAGEMENT ───────────────────────────────────────────────

  /// Initialize session: check if existing session is still valid
  /// Note: This is called before Firebase Auth restores the user, so we only check
  /// if there's an expired session. The actual session validation happens in _onAuthStateChanged
  Future<void> _initializeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActivityStr = prefs.getString(_lastActivityKey);

      if (lastActivityStr != null) {
        final lastActivity = DateTime.parse(lastActivityStr);
        final now = DateTime.now();
        final timeSinceLastActivity = now.difference(lastActivity);

        // If session expired (more than 3 hours since last activity), clear it
        // But don't sign out here - Firebase Auth will restore the user, and we'll handle it in _onAuthStateChanged
        if (timeSinceLastActivity > _sessionDuration) {
          // debugPrint(
              // 'AuthProvider: Session expired (${timeSinceLastActivity.inHours} hours). Will clear on auth state change...');
          // Don't sign out here - let Firebase restore first, then we'll check in _onAuthStateChanged
        } else {
          // debugPrint(
              // 'AuthProvider: Session valid (${timeSinceLastActivity.inMinutes} minutes since last activity)');
        }
      } else {
        // debugPrint(
            // 'AuthProvider: No existing session found - will save when Firebase restores user');
      }
    } catch (e) {
      // debugPrint('AuthProvider: Error initializing session: $e');
    }
  }

  /// Save session timestamp on successful login
  Future<void> _saveSessionTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(_sessionTimestampKey, now.toIso8601String());
      await prefs.setString(_lastActivityKey, now.toIso8601String());
      // debugPrint(
          // 'AuthProvider: ✅ Session timestamp saved at ${now.toIso8601String()}');

      // Verify it was saved
      final saved = prefs.getString(_lastActivityKey);
      // debugPrint('AuthProvider: ✅ Verified session saved: $saved');
    } catch (e) {
      // debugPrint('AuthProvider: ❌ Error saving session timestamp: $e');
    }
  }

  /// Update last activity timestamp (called when user interacts with app)
  Future<void> _updateLastActivity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString(_lastActivityKey, now.toIso8601String());
    } catch (e) {
      // debugPrint('AuthProvider: Error updating last activity: $e');
    }
  }

  /// Clear session data
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionTimestampKey);
      await prefs.remove(_lastActivityKey);
      // debugPrint('AuthProvider: Session cleared');
    } catch (e) {
      // debugPrint('AuthProvider: Error clearing session: $e');
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
      // debugPrint('AuthProvider: Error checking session validity: $e');
      return false;
    }
  }

  /// Update last activity (call this periodically or on user interactions)
  Future<void> updateLastActivity() async {
    await _updateLastActivity();
  }

  // ── AUTH STATE LISTENER ───────────────────────────────────────────
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _user = firebaseUser;
    _isLoading = true;
    notifyListeners();

    if (firebaseUser != null) {
      // debugPrint(
          // 'AuthProvider: 🔐 auth state changed -> user uid=${firebaseUser.uid}');

      // Check if we have a session timestamp - if not, this is a restored session, save it
      final prefs = await SharedPreferences.getInstance();
      final lastActivityStr = prefs.getString(_lastActivityKey);

      // debugPrint(
          // 'AuthProvider: 📋 Checking session - lastActivityStr: ${lastActivityStr != null ? "exists" : "null"}');

      if (lastActivityStr == null) {
        // No session timestamp found - this is likely a restored Firebase session
        // Save the session timestamp to maintain it
        // debugPrint(
            // 'AuthProvider: 💾 No session timestamp found, saving restored Firebase session...');
        await _saveSessionTimestamp();
      } else {
        // We have a session timestamp - check if it's still valid
        final lastActivity = DateTime.parse(lastActivityStr);
        final now = DateTime.now();
        final timeSinceLastActivity = now.difference(lastActivity);
        // debugPrint(
            // 'AuthProvider: ⏰ Session check - Last activity: $lastActivity, Now: $now, Duration: ${timeSinceLastActivity.inMinutes} minutes');

        final sessionValid = await isSessionValid();
        if (!sessionValid) {
          // debugPrint(
              // 'AuthProvider: ⏰ Session expired (${timeSinceLastActivity.inHours} hours), signing out...');
          await _auth.signOut();
          await _clearSession();
          _user = null;
          _userProfile = null;
          _isLoading = false;
          _isProfileLoading = false;
          notifyListeners();
          return;
        } else {
          // Session is valid, update last activity
          // debugPrint(
              // 'AuthProvider: ✅ Session valid, updating last activity...');
          await _updateLastActivity();
        }
      }

      try {
        await _loadUserProfile(firebaseUser.uid);
      } catch (e, st) {
        // debugPrint('AuthProvider: _loadUserProfile threw: $e\n$st');
      }
    } else {
      _userProfile = null;
      _isProfileLoading = false;
    }

    _isLoading = false;
    notifyListeners();
  }
  /// Parse a timestamp from API response (ISO string or Firestore Timestamp).
  static Timestamp _parseTimestamp(dynamic value) {
    if (value == null) return Timestamp.now();
    if (value is Timestamp) return value;
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return Timestamp.fromDate(dt);
    }
    return Timestamp.now();
  }

  Future<void> _loadUserProfile(String uid) async {
    _isProfileLoading = true;
    notifyListeners();

    try {
      // Call backend /accounts/me which resolves role from token
      final data = await AccountsApi.getMyAccount();

      _userProfile = UserProfile(
        uid: data['uid'] ?? uid,
        email: data['email'] ?? '',
        displayName: data['displayName'],
        phoneNumber: data['phoneNumber'],
        stationName: data['stationName'],
        district: data['district'],
        rank: data['rank'],
        badgeNumber: data['badgeNumber'],
        employeeId: data['employeeId'],
        houseNo: data['houseNo'],
        address: data['address'],
        state: data['state'],
        country: data['country'],
        pincode: data['pincode'],
        username: data['username'],
        dob: data['dob'],
        gender: data['gender'],
        aadharNumber: data['aadharNumber'],
        role: data['role'] ?? 'citizen',
        createdAt: _parseTimestamp(data['createdAt']),
        updatedAt: _parseTimestamp(data['updatedAt']),
      );

      // Register FCM token for citizens ONLY (not for police)
      if (_userProfile!.role != 'police') {
        _registerNotificationToken(uid);
      }
    } catch (e) {
      // debugPrint('AuthProvider: error loading profile -> $e');
      _userProfile = null;
    }

    _isProfileLoading = false;
    notifyListeners();
  }

  /// Register FCM notification token for citizen users
  /// This runs in the background and won't block the UI if it fails
  Future<void> _registerNotificationToken(String userId) async {
    try {
      final notificationService = NotificationService();

      // Initialize FCM for citizen users only (isCitizen: true)
      await notificationService.initialize(userId, isCitizen: true);

      // debugPrint('AuthProvider: ✅ FCM token registered for citizen user');
    } catch (e) {
      // Don't crash - notifications are optional
      // debugPrint(
          // 'AuthProvider: FCM token registration failed (non-critical): $e');
    }
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
      // Save session timestamp on successful login
      await _saveSessionTimestamp();
      return credential;
    } on FirebaseAuthException catch (e) {
      // debugPrint('signInWithEmail error: ${e.message}');
      rethrow;
    }
  }

  // ── PASSWORD RESET ────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    if (!Validators.isValidEmail(email)) {
      throw Exception('Invalid email');
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      // debugPrint('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      // debugPrint('sendPasswordResetEmail error: ${e.message}');
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
      // debugPrint('signUpWithEmail error: ${e.message}');
      rethrow;
    }
  }

  // ── GOOGLE SIGN IN ────────────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential? credential;
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final authCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        credential = await _auth.signInWithCredential(authCredential);
      }
      // Save session timestamp on successful login
      await _saveSessionTimestamp();
      return credential;
    } on FirebaseAuthException catch (e) {
      // debugPrint('signInWithGoogle error: ${e.message}');
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
    _webConfirmationResult = null; // Reset web result
    notifyListeners();

    try {
      if (kIsWeb) {
        // Web: Use signInWithPhoneNumber for standard reCAPTCHA flow
        try {
          final confirmationResult =
              await _auth.signInWithPhoneNumber(phoneNumber);
          _webConfirmationResult = confirmationResult;
          _verificationId = confirmationResult.verificationId;
          _isPhoneVerifying = false;
          notifyListeners();
          onCodeSent(confirmationResult.verificationId, null);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'invalid-app-credential') {
            throw Exception(
                'CRITICAL: App Check is likely blocking localhost.\n\nSOLUTION 1 (Easist): Go to Firebase Console > App Check > Apps. Click the "trash icon" or "unregister" specifically for the Web App to DISABLE App Check temporarily.\n\nSOLUTION 2: Generate a "Debug Token" in your browser console and add it to Firebase App Check settings for localhost.\n\nSOLUTION 3: Ensure "Authorized Domains" has ONLY "localhost" (no http/https).');
          }
          rethrow;
        }
      } else {
        // Mobile: Use verifyPhoneNumber
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
      }
    } catch (e) {
      _isPhoneVerifying = false;
      notifyListeners();
      onError(e.toString());
    }
  }

  // ── PHONE OTP VERIFY ──────────────────────────────────────────────
  Future<UserCredential?> verifyOtp(String otp) async {
    // Web Verification
    if (kIsWeb) {
      if (_webConfirmationResult == null)
        throw Exception('No web confirmation result found');
      final userCredential = await _webConfirmationResult!.confirm(otp);
      await _saveSessionTimestamp();
      return userCredential;
    }

    // Mobile Verification
    if (_verificationId == null) throw Exception('No verification ID');

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    await _saveSessionTimestamp();
    return userCredential;
  }

  // ── SIGN OUT ──────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) await GoogleSignIn().signOut();
    await _clearSession(); // Clear session data on logout
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
    String? aadharNumber,
    String role = 'citizen',
  }) async {
    // ── VALIDATIONS ────────────────────────────────────────────────
    if (!Validators.isValidEmail(email)) {
      throw Exception('Invalid email');
    }

    if (displayName != null && !Validators.isValidName(displayName)) {
      throw Exception('Invalid name');
    }

    if (phoneNumber != null &&
        phoneNumber.trim().isNotEmpty &&
        !Validators.isValidIndianPhone(phoneNumber)) {
      throw Exception('Invalid phone number');
    }

    if (dob != null && dob.trim().isNotEmpty && !Validators.isValidDOB(dob)) {
      throw Exception('Invalid DOB');
    }

    if (pincode != null &&
        pincode.trim().isNotEmpty &&
        !Validators.isValidIndianPincode(pincode)) {
      throw Exception('Invalid pincode');
    }

    // Simple Aadhar validation (12 digits)
    if (aadharNumber != null && aadharNumber.isNotEmpty) {
      if (!RegExp(r'^\d{12}$').hasMatch(aadharNumber)) {
        throw Exception('Invalid Aadhar number (must be 12 digits)');
      }
    }    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
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
      'aadharNumber': aadharNumber,
      'role': role,
      'createdAt': now,
      'updatedAt': now,
    };

    // Remove null values
    data.removeWhere((key, value) => value == null);

    await AccountsApi.createCitizenProfile(data);
    await _loadUserProfile(uid);
  }

  // ── UPDATE USER PROFILE ───────────────────────────────────────────
  Future<void> updateUserProfile({
    required String uid,
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
    String? aadharNumber,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // ── VALIDATIONS ──────────────────────────────────────────────
      if (displayName != null && !Validators.isValidName(displayName)) {
        throw Exception('Invalid name');
      }

      if (phoneNumber != null &&
          phoneNumber.trim().isNotEmpty &&
          !Validators.isValidIndianPhone(phoneNumber)) {
        throw Exception('Invalid phone number');
      }

      if (dob != null && dob.trim().isNotEmpty && !Validators.isValidDOB(dob)) {
        throw Exception('Invalid DOB');
      }

      if (pincode != null &&
          pincode.trim().isNotEmpty &&
          !Validators.isValidIndianPincode(pincode)) {
        throw Exception('Invalid pincode');
      }

      if (aadharNumber != null && aadharNumber.isNotEmpty) {
        if (!RegExp(r'^\d{12}$').hasMatch(aadharNumber)) {
          throw Exception('Invalid Aadhar number (must be 12 digits)');
        }
      }      final now = DateTime.now().toIso8601String();
      final Map<String, dynamic> data = {
        'updatedAt': now,
        'uid': uid, // Ensure UID is present in the document
      };

      if (displayName != null) data['displayName'] = displayName;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      if (username != null) data['username'] = username;
      if (dob != null) data['dob'] = dob;
      if (gender != null) data['gender'] = gender;
      if (houseNo != null) data['houseNo'] = houseNo;
      if (address != null) data['address'] = address;
      if (district != null) data['district'] = district;
      if (pincode != null) data['pincode'] = pincode;
      if (stationName != null) data['stationName'] = stationName;
      if (aadharNumber != null) data['aadharNumber'] = aadharNumber;

      // Update via backend API
      await AccountsApi.updateMyAccount(data);

      // Reload profile to get fresh data
      await _loadUserProfile(uid);
    } catch (e) {
      // debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
