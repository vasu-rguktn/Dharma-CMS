import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/auth_provider.dart' as custom_auth;
import 'package:Dharma/l10n/app_localizations.dart';

class LoginDetailsScreen extends StatefulWidget {
  const LoginDetailsScreen({super.key});

  @override
  State<LoginDetailsScreen> createState() => _LoginDetailsScreenState();
}

class _LoginDetailsScreenState extends State<LoginDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Future<void> _submitForm(Map<String, dynamic>? personalData, Map<String, dynamic>? addressData) async {
    debugPrint('🔥 SUBMIT FORM CALLED');
    debugPrint('📧 personalData: $personalData');
    debugPrint('🏠 addressData: $addressData');
    final localizations = AppLocalizations.of(context);

    if (personalData == null || addressData == null) {
      debugPrint('❌ Missing personal or address data');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations?.dataNotProvided ?? 'Error: Required data not provided'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Log input values for debugging
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    debugPrint('👤 Username: "$username" (length: ${username.length})');
    debugPrint('🔒 Password: "$password" (length: ${password.length})');
    debugPrint('✅ Confirm: "$confirm"');

    if (_formKey.currentState!.validate()) {
      debugPrint('✅ FORM VALIDATION PASSED');
      setState(() => _isLoading = true);
      try {
        final authProvider = Provider.of<custom_auth.AuthProvider>(context, listen: false);
        final email = personalData['email'] as String?;
        if (email == null || email.isEmpty) {
          debugPrint('❌ Email is null or empty');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Invalid email provided'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        debugPrint('📧 Signing up with email: $email');
        final userCredential = await authProvider.signUpWithEmail(email, password);
        if (userCredential == null || userCredential.user == null) {
          debugPrint('❌ UserCredential or user is null');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text(localizations?.failedToCreateUser ?? 'Error: Failed to create user'),
            backgroundColor: Colors.red,
            ),
          );
          return;
        }

        debugPrint('✅ User created: ${userCredential.user!.uid}');
        await authProvider.createUserProfile(
          uid: userCredential.user!.uid,
          email: email,
          displayName: personalData['name'] as String?,
          phoneNumber: personalData['phone'] as String?,
          houseNo: addressData['houseNo'] as String?,
          address: addressData['address'] as String?,
          district: addressData['district'] as String?,
          state: addressData['state'] as String?,
          country: addressData['country'] as String?,
          pincode: addressData['pincode'] as String?,
          username: _usernameController.text,
          dob: personalData['dob'] as String?,
          gender: personalData['gender'] as String?,
          stationName: addressData['policestation'] as String?,
          role: 'citizen',
        );

        debugPrint('✅ Profile created successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.registrationSuccessful ?? 'Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );

        debugPrint('🚀 NAVIGATING TO DASHBOARD');
        context.go('/ai-legal-guider');
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'The email is already registered.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is invalid.';
            break;
          case 'weak-password':
            errorMessage = 'The password is too weak.';
            break;
          default:
            errorMessage = e.message ?? 'An error occurred during registration.';
        }
        debugPrint('🔥 FirebaseAuth error: ${e.code} - $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e, stackTrace) {
        debugPrint('❌ Unexpected error: $e\nStackTrace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.unexpectedError ?? 'An unexpected error occurred.'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      debugPrint('❌ FORM VALIDATION FAILED');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations?.fixFormErrors ?? 'Please fix the errors in the form'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('📋 LoginDetailsScreen initialized');
  }

  @override
  void didUpdateWidget(LoginDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🔄 LoginDetailsScreen updated, args: ${GoRouterState.of(context).extra}');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context);
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final personalData = args?['personal'] as Map<String, dynamic>?;
    final addressData = args?['address'] as Map<String, dynamic>?;
    debugPrint('📋 Received args in LoginDetailsScreen: $args');

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: screenHeight * 0.3,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  'assets/Frame.svg',
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: screenHeight * 0.3,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Transform.translate(
                    offset: const Offset(0, 0),
                    child: Image.asset(
                      'assets/police_logo.png',
                      fit: BoxFit.contain,
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          'Error loading logo: $error',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFD32F2F),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      localizations?.loginDetails ?? 'Login Details',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: localizations?.username ?? 'Username *',
                        hintText: localizations?.enterUsername ?? 'Enter username (min 4 characters)',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20.0,
                          horizontal: 16.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        debugPrint('🔍 Validating username: "$value"');
                        if (value == null || value.trim().isEmpty) {
                          debugPrint('❌ Username is empty');
                          return localizations?.usernameEmpty ?? 'Enter username';
                        }
                        if (value.trim().length < 4) {
                          debugPrint('❌ Username too short: ${value.trim().length}');
                          return localizations?.usernameMinLength ?? 'Username must be at least 4 characters';
                        }
                        debugPrint('✅ Username valid');
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: localizations?.password ?? 'Password *',
                        hintText: localizations?.enterPassword ?? 'Enter password (min 6 characters)',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock, color: Colors.black),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20.0,
                          horizontal: 16.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        debugPrint('🔍 Validating password: "$value"');
                        if (value == null || value.trim().isEmpty) {
                          debugPrint('❌ Password is empty');
                          return localizations?.passwordEmpty ?? 'Enter password';
                        }
                        if (value.length < 6) {
                          debugPrint('❌ Password too short: ${value.length}');
                          return localizations?.passwordMinLength ?? 'Password must be at least 6 characters';
                        }
                        debugPrint('✅ Password valid');
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: localizations?.confirmPassword ?? 'Confirm Password *',
                        hintText: localizations?.reenterPassword ?? 'Re-enter password',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.lock, color: Colors.black),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                            color: Colors.black,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20.0,
                          horizontal: 16.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        debugPrint('🔍 Validating confirm password: "$value"');
                        if (value == null || value.trim().isEmpty) {
                          debugPrint('❌ Confirm password is empty');
                          return localizations?.confirmPasswordEmpty ?? 'Confirm your password';
                        }
                        if (value != _passwordController.text) {
                          debugPrint('❌ Confirm password does not match');
                          return localizations?.passwordsDoNotMatch ?? 'Passwords do not match';
                        }
                        debugPrint('✅ Confirm password valid');
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              try {
                                context.go('/address', extra: {
                                  'personal': personalData,
                                  'address': addressData
                                });
                              } catch (e) {
                                debugPrint('Navigation error: $e');
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              localizations?.previous ?? 'Previous',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _submitForm(personalData, addressData),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: const Color(0xFFFC633C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    localizations?.next ?? 'Next',
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
    
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('🗑️ Disposing LoginDetailsScreen');
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}