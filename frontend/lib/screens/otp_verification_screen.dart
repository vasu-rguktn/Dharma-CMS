import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitForm(Map<String, dynamic>? args) async {
    debugPrint('🔥 SUBMIT OTP FORM CALLED');
    debugPrint('📦 Received args: $args');

    if (args == null ||
        args['personal'] == null ||
        args['address'] == null ||
        args['username'] == null ||
        args['uid'] == null) {
      debugPrint('❌ Missing required arguments in OtpVerificationScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Required data not provided'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      debugPrint('✅ OTP FORM VALIDATION PASSED');
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          debugPrint('❌ No user signed in');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user is signed in'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (_otpController.text == '123456') {
          debugPrint('✅ OTP verified successfully, navigating to /dashboard');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Completed!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/dashboard');
        } else {
          debugPrint('❌ Invalid OTP entered: ${_otpController.text}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on FirebaseException catch (e) {
        debugPrint('🔥 Firestore error: ${e.code} - ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firestore error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e, stackTrace) {
        debugPrint('❌ Unexpected error: $e\nStackTrace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      debugPrint('❌ OTP VALIDATION FAILED: otp=${_otpController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint('📋 OtpVerificationScreen initialized');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    debugPrint('📋 Received args in OtpVerificationScreen: $args');

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: screenHeight * 0.4,
            width: double.infinity,
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/Frame.svg',
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: screenHeight * 0.4,
                ),
                Center(
                  child: Image.asset(
                    'assets/police_logo.png',
                    fit: BoxFit.contain,
                    width: 150,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'Error loading logo: $error',
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'OTP Verification',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: _otpController,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: 'OTP *',
                          hintText: 'Enter 6-digit OTP',
                          filled: true,
                          fillColor: Colors.grey[200],
                          prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFF1976D2)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          errorStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          debugPrint('🔍 Validating OTP: "$value"');
                          if (value == null || value.length != 6) {
                            debugPrint('❌ OTP invalid: length=${value?.length}');
                            return 'Enter a 6-digit OTP';
                          }
                          debugPrint('✅ OTP valid');
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _submitForm(args),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF1976D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Verify & Complete',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
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
    debugPrint('🗑️ Disposing OtpVerificationScreen');
    _otpController.dispose();
    super.dispose();
  }
}