// // lib/screens/phone_login_screen.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:provider/provider.dart';
// import 'package:go_router/go_router.dart';
// import 'package:Dharma/providers/auth_provider.dart';

// class PhoneLoginScreen extends StatefulWidget {
//   const PhoneLoginScreen({super.key});

//   @override
//   State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
// }

// class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
//   final _phoneController = TextEditingController();
//   final _otpController = TextEditingController();

//   bool _isLoading = false;
//   bool _otpSent = false;

//   // ✅ Flag to disable Send OTP button
//   bool _isSendOtpDisabled = false;

//   int _countdown = 0;
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
//   }

//   // ✅ Countdown logic for Send OTP
//   void _startCountdown() {
//     _countdown = 60;
//     _isSendOtpDisabled = true;

//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_countdown == 0) {
//         timer.cancel();
//         setState(() {
//           _isSendOtpDisabled = false; // Enable Send OTP after 60 sec
//         });
//       } else {
//         setState(() => _countdown--);
//       }
//     });
//   }

//   // ✅ Send OTP
//   Future<void> _sendOtp({bool isResend = false}) async {
//     final phone = '+91${_phoneController.text.trim()}';

//     if (phone.length != 13) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Enter 10-digit mobile number')),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _isSendOtpDisabled = true;
//     });

//     try {
//       final auth = Provider.of<AuthProvider>(context, listen: false);

//       await auth.sendOtp(
//         phoneNumber: phone,
//         onCodeSent: (vid, token) {
//           setState(() {
//             _otpSent = true;
//             _startCountdown(); // Start 60s timer after OTP sent
//           });

//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(isResend ? 'OTP Resent!' : 'OTP sent! Check SMS'),
//             ),
//           );
//         },
//         onError: (msg) {
//           setState(() {
//             _isSendOtpDisabled = false;
//           });

//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Error: $msg')),
//           );
//         },
//       );
//     } catch (e) {
//       setState(() {
//         _isSendOtpDisabled = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   // ✅ Verify OTP
//   Future<void> _verifyOtp() async {
//     if (_otpController.text.length != 6) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Enter 6-digit OTP')),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     try {
//       final auth = Provider.of<AuthProvider>(context, listen: false);
//       final userCredential = await auth.verifyOtp(_otpController.text);

//       if (userCredential != null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Login successful!')),
//         );
//         context.go('/ai-legal-guider');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Invalid OTP: $e')),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   // ✅ Input Decoration
//   InputDecoration _inputDecoration(String label,
//       {String? prefixText, IconData? prefixIcon}) {
//     return InputDecoration(
//       labelText: label,
//       labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//       filled: true,
//       fillColor: Colors.white,
//       prefixText: prefixText,
//       prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
//       contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       body: Column(
//         children: [
//           // ✅ HEADER
//           Container(
//             height: screenHeight * 0.3,
//             width: double.infinity,
//             child: Stack(
//               children: [
//                 SvgPicture.asset(
//                   'assets/Frame.svg',
//                   fit: BoxFit.fill,
//                   height: screenHeight * 0.3,
//                 ),
//                 Positioned(
//                   left: 0,
//                   right: 0,
//                   bottom: 0,
//                   child: Image.asset(
//                     'assets/police_logo.png',
//                     height: 120,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 32),

//           // ✅ FORM
//           Expanded(
//   child: SingleChildScrollView(
//     physics: const ClampingScrollPhysics(), // ✅ Stops extra scroll
//     padding: const EdgeInsets.symmetric(
//       horizontal: 24,
//       vertical: 16,
//     ), //
//               child: Column(
//                 children: [
//                   const Text(
//                     'Login with Phone',
//                     style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
//                   ),

//                   const SizedBox(height: 32),

//                   if (!_otpSent)
//                     TextFormField(
//                       controller: _phoneController,
//                       keyboardType: TextInputType.phone,
//                       decoration:
//                           _inputDecoration('Mobile Number', prefixText: '+91 '),
//                     ),

//                   if (_otpSent)
//                     TextFormField(
//                       controller: _otpController,
//                       keyboardType: TextInputType.number,
//                       decoration: _inputDecoration('Enter OTP'),
//                     ),

//                   const SizedBox(height: 24),

//                   // ✅ MAIN BUTTON
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: (_isLoading || (!_otpSent && _isSendOtpDisabled))
//                           ? null
//                           : _otpSent
//                               ? _verifyOtp
//                               : () => _sendOtp(isResend: false),
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 20),
//                         backgroundColor: (!_otpSent && _isSendOtpDisabled)
//                             ? Colors.grey
//                             : const Color(0xFFFC633C),
//                       ),
//                       child: _isLoading
//                           ? const CircularProgressIndicator(color: Colors.white)
//                           : Text(
//                               _otpSent ? 'Verify OTP' : 'Send OTP',
//                               style: const TextStyle(
//                                   fontSize: 22, fontWeight: FontWeight.bold),
//                             ),
//                     ),
//                   ),

//                   // ✅ RESEND TIMER
//                   if (_otpSent) ...[
//                     const SizedBox(height: 16),
//                     _countdown > 0
//                         ? Text('Resend in $_countdown sec')
//                         : TextButton(
//                             onPressed: _isLoading
//                                 ? null
//                                 : () => _sendOtp(isResend: true),
//                             child: const Text('Resend OTP'),
//                           ),
//                   ],

//                   const SizedBox(height: 32),

//                   // ✅ BACK BUTTON
//                   TextButton(
//                     onPressed: () => context.go('/login'),
//                     child: const Text('Back to Email Login'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _phoneController.dispose();
//     _otpController.dispose();
//     super.dispose();
//   }
// }

import 'dart:async';

import 'package:Dharma/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sms_autofill/sms_autofill.dart'; // Correct package
import 'package:pin_code_fields/pin_code_fields.dart';

// Fix name conflict: your own AuthProvider (not the one from firebase_auth)
import 'package:Dharma/providers/auth_provider.dart' as MyAuth;

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> with CodeAutoFill {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _isSendOtpDisabled = false;

  int _countdown = 0;
  Timer? _timer;

  String? _verificationId;
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _listenForOtp();
  }

  @override
  void dispose() {
    cancel(); // From CodeAutoFill mixin
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    SmsAutoFill().unregisterListener(); // CORRECT: SmsAutoFill()
    super.dispose();
  }

  void _listenForOtp() async {
    await SmsAutoFill().listenForCode; // CORRECT: SmsAutoFill()
  }

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      setState(() => _otpController.text = code!);
      _verifyOtp(); // Auto verify instantly
    }
  }

  void _startCountdown() {
    _countdown = 60;
    _isSendOtpDisabled = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
        if (mounted) setState(() => _isSendOtpDisabled = false);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    final phone = '+91${_phoneController.text.trim()}';
    if (phone.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterValidNumber)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSendOtpDisabled = true;
    });

    try {
      final auth = Provider.of<MyAuth.AuthProvider>(context, listen: false);

      await auth.sendOtp(
        phoneNumber: phone,
        onCodeSent: (verificationId, resendToken) {
          setState(() {
            _otpSent = true;
            _verificationId = verificationId;
            _resendToken = resendToken;
            _startCountdown();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(isResend
                  ? AppLocalizations.of(context)!.otpResent
                  : AppLocalizations.of(context)!.otpSent),
            ),
          );
        },
        onError: (error) {
          setState(() => _isSendOtpDisabled = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        },
      );
    } catch (e) {
      setState(() => _isSendOtpDisabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || _verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterOtp)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(AppLocalizations.of(context)!.loginSuccessful),
          ),
        );
        context.go('/ai-legal-guider');
      }
    } on FirebaseAuthException catch (e) {
      // ignore: use_build_context_synchronously
      String msg = AppLocalizations.of(context)!.invalidOtp;
      if (e.code == 'invalid-verification-code') {
        // ignore: use_build_context_synchronously
        msg = AppLocalizations.of(context)!.wrongOtp;
      }
      if (e.code == 'session-expired') {
        // ignore: use_build_context_synchronously
        msg = AppLocalizations.of(context)!.otpExpired;
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      prefixText: prefixText,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive header height: smaller on small screens
    final headerHeight = (screenHeight * 0.25).clamp(180.0, 250.0);
    final logoSize = (headerHeight * 0.45).clamp(80.0, 120.0);
    
    // Responsive PIN field dimensions
    final pinFieldHeight = (screenWidth * 0.12).clamp(45.0, 58.0);
    final pinFieldWidth = (screenWidth * 0.11).clamp(40.0, 50.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER - Responsive height
            Container(
              height: headerHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  SvgPicture.asset(
                    'assets/Frame.svg',
                    fit: BoxFit.fill,
                    height: headerHeight,
                    width: double.infinity,
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: Image.asset('assets/police_logo.png', height: logoSize),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.loginWithPhone,
                      style: TextStyle(
                        fontSize: (screenWidth * 0.075).clamp(24.0, 32.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),

                    // Phone Number
                    if (!_otpSent)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          AppLocalizations.of(context)!.mobileNumber,
                          prefixText: '+91 ',
                        ),
                      ),

                    // OTP PIN Field - Responsive sizing
                    if (_otpSent)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                        ),
                        child: PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: _otpController,
                          autoFocus: true,
                          keyboardType: TextInputType.number,
                          textStyle: TextStyle(
                            fontSize: (pinFieldHeight * 0.35).clamp(16.0, 20.0),
                            fontWeight: FontWeight.bold,
                          ),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(8),
                            fieldHeight: pinFieldHeight,
                            fieldWidth: pinFieldWidth,
                            activeFillColor: Colors.white,
                            selectedFillColor: Colors.white,
                            inactiveFillColor: Colors.white,
                            activeColor: const Color(0xFFFC633C),
                            selectedColor: const Color(0xFFFC633C),
                            inactiveColor: Colors.grey.shade300,
                          ),
                          enableActiveFill: true,
                          onChanged: (_) {},
                          onCompleted: (_) => _verifyOtp(),
                        ),
                      ),

                    SizedBox(height: screenHeight * 0.03),

                    // Main Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || (!_otpSent && _isSendOtpDisabled)
                            ? null
                            : _otpSent
                                ? _verifyOtp
                                : () => _sendOtp(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (!_otpSent && _isSendOtpDisabled)
                              ? Colors.grey
                              : const Color(0xFFFC633C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              )
                            : Text(
                                _otpSent
                                    ? AppLocalizations.of(context)!.verifyOtp
                                    : AppLocalizations.of(context)!.sendOtp,
                                style: TextStyle(
                                  fontSize: (screenWidth * 0.05).clamp(18.0, 22.0),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    // Resend Timer
                    if (_otpSent) ...[
                      SizedBox(height: screenHeight * 0.02),
                      _countdown > 0
                          ? Text(
                              'Resend in $_countdown sec',
                              style: const TextStyle(color: Colors.grey),
                            )
                          : TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _sendOtp(isResend: true),
                              child: Text(
                                AppLocalizations.of(context)!.resendOtp,
                                style: const TextStyle(color: Color(0xFFFC633C)),
                              ),
                            ),
                    ],

                    SizedBox(height: screenHeight * 0.03),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(AppLocalizations.of(context)!.backToEmailLogin),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
