import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:dharma/providers/auth_provider.dart' as my_auth;
import 'package:dharma/l10n/app_localizations.dart';

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
  bool _isSendOtpDisabled = false;
  bool _isConsentAccepted = false;
  int _countdown = 0;
  Timer? _timer;
  String? _verificationId;

  static const Color orange = Color(0xFFFC633C);

  @override
  void dispose() { _timer?.cancel(); _phoneController.dispose(); _otpController.dispose(); super.dispose(); }

  void _startCountdown() {
    _countdown = 60;
    _isSendOtpDisabled = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) { t.cancel(); if (mounted) setState(() => _isSendOtpDisabled = false); }
      else { if (mounted) setState(() => _countdown--); }
    });
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    final phone = '+91${_phoneController.text.trim()}';
    if (phone.length != 13) { _snack('Enter 10-digit mobile number'); return; }
    setState(() { _isLoading = true; _isSendOtpDisabled = true; });
    try {
      final auth = Provider.of<my_auth.AuthProvider>(context, listen: false);
      await auth.sendOtp(
        phoneNumber: phone,
        onCodeSent: (vid, token) { setState(() { _otpSent = true; _verificationId = vid; _startCountdown(); }); _snack(isResend ? 'OTP Resent!' : 'OTP Sent!', Colors.green); },
        onError: (msg) { setState(() => _isSendOtpDisabled = false); _snack('Error: $msg'); },
      );
    } catch (e) { setState(() => _isSendOtpDisabled = false); _snack('Failed: $e'); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6 || _verificationId == null) { _snack('Enter 6-digit OTP'); return; }
    setState(() => _isLoading = true);
    try {
      if (kIsWeb) {
        await Provider.of<my_auth.AuthProvider>(context, listen: false).verifyOtp(otp);
      } else {
        final cred = PhoneAuthProvider.credential(verificationId: _verificationId!, smsCode: otp);
        await FirebaseAuth.instance.signInWithCredential(cred);
      }
      if (mounted) { _snack('Login successful!', Colors.green); context.go('/dashboard'); }
    } on FirebaseAuthException catch (e) {
      _snack(e.code == 'invalid-verification-code' ? 'Wrong OTP' : e.code == 'session-expired' ? 'OTP expired' : 'Invalid OTP');
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _snack(String msg, [Color? bg]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Header
          SizedBox(
            height: h * 0.25,
            width: w,
            child: Stack(children: [
              SvgPicture.asset('assets/svg/Frame.svg', fit: BoxFit.fill, width: w, height: h * 0.25),
              Positioned(top: 0, left: 0, child: SafeArea(child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')))),
              Positioned(left: 0, right: 0, bottom: 10, child: Image.asset('assets/images/police_logo.png', height: 100)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(l.loginWithPhone, style: TextStyle(fontSize: (w * 0.075).clamp(24, 32), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  if (!_otpSent) TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: l.mobileNumber, prefixText: '+91 ')),
                  if (_otpSent) PinCodeTextField(appContext: context, length: 6, controller: _otpController, autoFocus: true, keyboardType: TextInputType.number, pinTheme: PinTheme(shape: PinCodeFieldShape.box, borderRadius: BorderRadius.circular(8), fieldHeight: 50, fieldWidth: 45, activeFillColor: Colors.white, selectedFillColor: Colors.white, inactiveFillColor: Colors.white, activeColor: orange, selectedColor: orange, inactiveColor: Colors.grey.shade300), enableActiveFill: true, onChanged: (_) {}, onCompleted: (_) => _verifyOtp()),
                  const SizedBox(height: 16),
                  // Consent
                  Row(children: [
                    Checkbox(value: _isConsentAccepted, activeColor: orange, onChanged: (v) => setState(() => _isConsentAccepted = v ?? false)),
                    Expanded(child: Text('${l.iAgreeToThe} Terms & Privacy Policy', style: const TextStyle(fontSize: 13))),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: (_isLoading || (!_otpSent && _isSendOtpDisabled)) ? null : () { if (!_isConsentAccepted) { _snack('Please accept Terms'); return; } _otpSent ? _verifyOtp() : _sendOtp(); },
                      style: ElevatedButton.styleFrom(backgroundColor: orange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5) : Text(_otpSent ? l.verifyOtp : l.sendOtp, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    _countdown > 0 ? Text('Resend in $_countdown sec', style: const TextStyle(color: Colors.grey)) : TextButton(onPressed: _isLoading ? null : () => _sendOtp(isResend: true), child: Text(l.resendOtp, style: const TextStyle(color: orange))),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/email-login'),
                    child: const Text('Use Email / Password Instead', style: TextStyle(color: orange, fontSize: 14)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
