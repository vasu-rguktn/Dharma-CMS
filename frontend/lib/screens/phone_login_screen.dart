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
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    final phone = '+91${_phoneController.text.trim()}';
    if (phone.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 10-digit mobile number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.sendOtp(
        phoneNumber: phone,
        isResend: isResend,
        onCodeSent: (vid, token) {
          setState(() {
            _otpSent = true;
            if (isResend) _startCountdown(); // Restart timer on resend
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isResend ? 'OTP Resent!' : 'OTP sent! Check SMS')),
          );
        },
        onError: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $msg')),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
        context.go('/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Reusable InputDecoration
  InputDecoration _inputDecoration(String label, {String? prefixText, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      prefixText: prefixText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.black) : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
      errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // Top SVG + Logo
          Container(
            height: screenHeight * 0.3,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset('assets/Frame.svg', fit: BoxFit.fill, width: double.infinity, height: screenHeight * 0.3),
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Transform.translate(
                    offset: const Offset(0, 0),
                    child: Image.asset(
                      'assets/police_logo.png',
                      fit: BoxFit.contain,
                      width: 120, height: 120,
                      errorBuilder: (context, error, stackTrace) => Text(
                        'Error loading logo: $error',
                        style: const TextStyle(fontSize: 14, color: Color(0xFFD32F2F)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.0, right: 24.0, top: 16.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Login with Phone',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.black, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 32),

                  // Phone Number
                  if (!_otpSent)
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration('Mobile Number', prefixText: '+91 '),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),

                  // OTP
                  if (_otpSent)
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Enter OTP'),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                    ),

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _otpSent
                              ? _verifyOtp
                              : () => _sendOtp(isResend: false),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: const Color(0xFFFC633C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _otpSent ? 'Verify OTP' : 'Send OTP',
                              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                    ),
                  ),

                  // Resend OTP with Timer
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    _countdown > 0
                        ? Text(
                            'Resend in $_countdown sec',
                            style: const TextStyle(color: Colors.grey, fontSize: 16),
                          )
                        : TextButton(
                            onPressed: _isLoading ? null : () => _sendOtp(isResend: true),
                            child: const Text(
                              'Resend OTP',
                              style: TextStyle(color: Color(0xFFFC633C), fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                  ],

                  const SizedBox(height: 32),

                  // Back to Email Login
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Back to Email Login',
                      style: TextStyle(
                        color: Color(0xFFFC633C),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFFC633C),
                      ),
                    ),
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