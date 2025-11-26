// lib/screens/phone_login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/auth_provider.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;

  // ✅ Flag to disable Send OTP button
  bool _isSendOtpDisabled = false;

  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  // ✅ Countdown logic for Send OTP
  void _startCountdown() {
    _countdown = 60;
    _isSendOtpDisabled = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
        setState(() {
          _isSendOtpDisabled = false; // Enable Send OTP after 60 sec
        });
      } else {
        setState(() => _countdown--);
      }
    });
  }

  // ✅ Send OTP
  Future<void> _sendOtp({bool isResend = false}) async {
    final phone = '+91${_phoneController.text.trim()}';

    if (phone.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 10-digit mobile number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSendOtpDisabled = true;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      await auth.sendOtp(
        phoneNumber: phone,
        onCodeSent: (vid, token) {
          setState(() {
            _otpSent = true;
            _startCountdown(); // Start 60s timer after OTP sent
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isResend ? 'OTP Resent!' : 'OTP sent! Check SMS'),
            ),
          );
        },
        onError: (msg) {
          setState(() {
            _isSendOtpDisabled = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $msg')),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isSendOtpDisabled = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Verify OTP
  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final userCredential = await auth.verifyOtp(_otpController.text);

      if (userCredential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        context.go('/ai-legal-guider');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Input Decoration
  InputDecoration _inputDecoration(String label,
      {String? prefixText, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      prefixText: prefixText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // ✅ HEADER
          Container(
            height: screenHeight * 0.3,
            width: double.infinity,
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/Frame.svg',
                  fit: BoxFit.fill,
                  height: screenHeight * 0.3,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/police_logo.png',
                    height: 120,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ✅ FORM
          Expanded(
  child: SingleChildScrollView(
    physics: const ClampingScrollPhysics(), // ✅ Stops extra scroll
    padding: const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 16,
    ), //
              child: Column(
                children: [
                  const Text(
                    'Login with Phone',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 32),

                  if (!_otpSent)
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration:
                          _inputDecoration('Mobile Number', prefixText: '+91 '),
                    ),

                  if (_otpSent)
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Enter OTP'),
                    ),

                  const SizedBox(height: 24),

                  // ✅ MAIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || (!_otpSent && _isSendOtpDisabled))
                          ? null
                          : _otpSent
                              ? _verifyOtp
                              : () => _sendOtp(isResend: false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: (!_otpSent && _isSendOtpDisabled)
                            ? Colors.grey
                            : const Color(0xFFFC633C),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _otpSent ? 'Verify OTP' : 'Send OTP',
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  // ✅ RESEND TIMER
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    _countdown > 0
                        ? Text('Resend in $_countdown sec')
                        : TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => _sendOtp(isResend: true),
                            child: const Text('Resend OTP'),
                          ),
                  ],

                  const SizedBox(height: 32),

                  // ✅ BACK BUTTON
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Back to Email Login'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
