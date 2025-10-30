// screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  String _gender = 'Male';

  bool _restored = false;   // ← ONE-TIME restore

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Run only once – when we receive any extra data
    if (!_restored) {
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;

      // 1. PERSONAL (always present)
      final personal = args?['personal'] as Map<String, dynamic>?;
      if (personal != null) {
        _nameController.text = personal['name'] ?? '';
        _emailController.text = personal['email'] ?? '';
        _phoneController.text = personal['phone'] ?? '';
        _dobController.text = personal['dob'] ?? '';
        _gender = personal['gender'] ?? 'Male';
      }

      // 2. ADDRESS – fill if we came back from Address/Login
      final address = args?['address'] as Map<String, dynamic>?;
      if (address != null) {
        // (We don’t have fields here, but we keep the map for later)
        // → will be passed forward again
      }

      // 3. LOGIN – fill if we came back from Login Details
      final login = args?['login'] as Map<String, dynamic>?;
      if (login != null) {
        // (No fields here, but keep the map)
      }

      _restored = true;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFC633C),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Re-read current values (in case user edited after coming back)
      final personalData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _gender,
      };

      // Pull any address/login data that was sent back (from later screens)
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final addressData = args?['address'] as Map<String, dynamic>?;
      final loginData = args?['login'] as Map<String, dynamic>?;

      // Pass EVERYTHING forward
      context.go('/address', extra: {
        'personal': personalData,
        if (addressData != null) 'address': addressData,
        if (loginData != null) 'login': loginData,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // ── HEADER SVG + LOGO (unchanged) ───────────────────────
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
                          style: const TextStyle(fontSize: 14, color: Color(0xFFD32F2F)),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── FORM (exact same UI as before) ─────────────────────
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
                    const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your name';
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return 'Name can only contain letters and spaces';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.email, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.phone, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your phone number';
                        if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) return 'Please enter a valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // DOB
                    TextFormField(
                      controller: _dobController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth (YYYY-MM-DD)',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.calendar_today, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please select your date of birth';
                        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return 'Enter date in YYYY-MM-DD format';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Gender
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) => setState(() => _gender = value!),
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) => value == null ? 'Please select your gender' : null,
                    ),
                    const SizedBox(height: 24),

                    // NEXT BUTTON (orange)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: const Color(0xFFFC633C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Next',
                          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }
}