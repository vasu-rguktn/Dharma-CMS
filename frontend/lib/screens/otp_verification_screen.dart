import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:permission_handler/permission_handler.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with CodeAutoFill {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _appSignature;

  @override
  void initState() {
    super.initState();
    // debugPrint('📋 OtpVerificationScreen initialized');
    _initializeSmsListener();
  }

  @override
  void dispose() {
    cancel(); // From CodeAutoFill mixin - stops listening for SMS
    _otpController.dispose();
    SmsAutoFill().unregisterListener();
    // debugPrint('🗑️ Disposing OtpVerificationScreen');
    super.dispose();
  }

  // Initialize SMS listener with permissions
  Future<void> _initializeSmsListener() async {
    try {
      // Get app signature for SMS verification
      _appSignature = await SmsAutoFill().getAppSignature;
      // debugPrint('📱 App Signature (include in OTP SMS): $_appSignature');

      // Request SMS permission
      final status = await Permission.sms.status;
      // debugPrint('📋 Current SMS permission status: $status');

      if (status.isDenied) {
        // debugPrint('⚠️ SMS permission denied, requesting...');
        final result = await Permission.sms.request();
        // debugPrint('📋 Permission request result: $result');

        if (result.isGranted) {
          // debugPrint('✅ SMS permission granted!');
          _listenForOtp();
        } else if (result.isPermanentlyDenied) {
          // debugPrint('❌ SMS permission permanently denied');
          _showPermissionDialog();
        } else {
          // debugPrint('❌ SMS permission denied');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS permission is required for auto-fill'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (status.isGranted) {
        // debugPrint('✅ SMS permission already granted');
        _listenForOtp();
      } else if (status.isPermanentlyDenied) {
        // debugPrint('❌ SMS permission permanently denied');
        _showPermissionDialog();
      }
    } catch (e) {
      // debugPrint('❌ Error initializing SMS listener: $e');
      // Still try to listen even if permission check fails
      _listenForOtp();
    }
  }

  // Show dialog for permanently denied permissions
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SMS Permission Required'),
        content: const Text(
          'To enable auto-fill for OTP, please grant SMS permission in your phone settings.\n\n'
          'Settings → Apps → Dharma → Permissions → SMS',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // Listen for incoming OTP SMS
  void _listenForOtp() async {
    try {
      // debugPrint('👂 Starting to listen for OTP SMS...');
      await SmsAutoFill().unregisterListener();
      listenForCode(); // From CodeAutoFill mixin
      // debugPrint('✅ CodeAutoFill listener started');

      // Also try the alternative method
      await SmsAutoFill().listenForCode();
      // debugPrint('✅ SmsAutoFill listener started');
    } catch (e) {
      // debugPrint('❌ Error starting SMS listener: $e');
    }
  }

  // This method is called when SMS code is detected
  @override
  void codeUpdated() {
    // debugPrint('📩 SMS Code detected: $code');
    if (code != null && code!.isNotEmpty) {
      // Extract only digits from the code
      final digits = code!.replaceAll(RegExp(r'\D'), '');
      // debugPrint('📩 Extracted digits: $digits');

      if (digits.length >= 6) {
        final otp = digits.substring(0, 6);
        if (mounted) {
          setState(() {
            _otpController.text = otp;
          });
          // debugPrint('✅ OTP auto-filled: $otp');

          // Auto-submit the form after a brief delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              final args =
                  GoRouterState.of(context).extra as Map<String, dynamic>?;
              _submitForm(args);
            }
          });
        }
      }
    }
  }

  Future<void> _submitForm(Map<String, dynamic>? args) async {
    // debugPrint('🔥 SUBMIT OTP FORM CALLED');
    // debugPrint('📦 Received args: $args');

    if (args == null ||
        args['personal'] == null ||
        args['address'] == null ||
        args['username'] == null ||
        args['uid'] == null) {
      // debugPrint('❌ Missing required arguments in OtpVerificationScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Required data not provided'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // debugPrint('✅ OTP FORM VALIDATION PASSED');
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          // debugPrint('❌ No user signed in');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No user is signed in'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (_otpController.text == '123456') {
          // debugPrint('✅ OTP verified successfully, navigating to /dashboard');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration Completed!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/dashboard');
        } else {
          // debugPrint('❌ Invalid OTP entered: ${_otpController.text}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on FirebaseException catch (e) {
        // debugPrint('🔥 Firestore error: ${e.code} - ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firestore error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e, stackTrace) {
        // debugPrint('❌ Unexpected error: $e\nStackTrace: $stackTrace');
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
      // debugPrint('❌ OTP VALIDATION FAILED: otp=${_otpController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    // debugPrint('📋 Received args in OtpVerificationScreen: $args');

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                // Add back button
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        // Navigate back to Welcome screen
                        context.go('/');
                      },
                      tooltip: 'Back',
                    ),
                  ),
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
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
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
                      const SizedBox(height: 12),
                      const Text(
                        'Enter the 6-digit code sent to your phone',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'OTP will auto-fill when received',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // PIN Code Field with auto-fill support
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpController,
                          autoFocus: true,
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.fade,
                          animationDuration: const Duration(milliseconds: 300),
                          enableActiveFill: true,
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 60,
                            fieldWidth: 50,
                            borderWidth: 2,
                            activeFillColor: Colors.white,
                            selectedFillColor: Colors.white,
                            inactiveFillColor: Colors.grey[100],
                            activeColor: const Color(0xFF1976D2),
                            selectedColor: const Color(0xFF1976D2),
                            inactiveColor: Colors.grey[300],
                            errorBorderColor: Colors.red,
                          ),
                          cursorColor: const Color(0xFF1976D2),
                          onChanged: (value) {
                            // debugPrint('📝 OTP changed: $value');
                          },
                          onCompleted: (value) {
                            // debugPrint('✅ OTP completed: $value');
                            _submitForm(args);
                          },
                          validator: (value) {
                            // debugPrint('🔍 Validating OTP: "$value"');
                            if (value == null || value.length != 6) {
                              // debugPrint(
                                  // '❌ OTP invalid: length=${value?.length}');
                              return 'Enter 6-digit OTP';
                            }
                            // debugPrint('✅ OTP valid');
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : () => _submitForm(args),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF1976D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
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

                      const SizedBox(height: 24),

                      // Resend OTP option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Didn't receive code? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    // debugPrint('🔄 Resend OTP requested');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('OTP Resent!'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                            child: const Text(
                              'Resend',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        ],
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
}
