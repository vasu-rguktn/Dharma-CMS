import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; 
import 'package:Dharma/l10n/app_localizations.dart';


import 'package:Dharma/utils/validators.dart';
import 'package:Dharma/screens/consent_pdf_viewer.dart';

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
  bool _prefilledFromArgs = false;
  Map<String, dynamic>? _incomingAddress;
  bool _isConsentAccepted = false;

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900), // Set a reasonable range for birth dates
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFC633C), // Matches your button color
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Format the selected date to YYYY-MM-DD
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submitForm() {
    final localizations = AppLocalizations.of(context);
    if (!_isConsentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please accept the Terms & Conditions')),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      final personalData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'gender': _gender,
      };
      debugPrint('Submitting personal data: $personalData');
      try {
        final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
        final userType = args?['userType'] as String? ?? 'citizen';
        
        final extra = <String, dynamic>{
          'personal': personalData,
          'userType': userType,
        };
        if (_incomingAddress != null) extra['address'] = _incomingAddress;
        context.go('/address', extra: extra);
        debugPrint('Navigation to /address attempted with userType: $userType');
      } catch (e) {
        debugPrint('Navigation error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation failed: $e')),
        );
      }
    } else {
      debugPrint('Form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.fillFieldsCorrectly ?? 'Please fill all fields correctly')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If this screen is opened with `extra: {'personal': ...}` we prefill the
    // controllers once so when user navigates back from the address step their
    // previously entered values are restored.
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final personal = args?['personal'] as Map<String, dynamic>?;
    final addressFromArgs = args?['address'] as Map<String, dynamic>?;
    if (!_prefilledFromArgs && personal != null) {
      _nameController.text = personal['name'] ?? _nameController.text;
      _emailController.text = personal['email'] ?? _emailController.text;
      _phoneController.text = personal['phone'] ?? _phoneController.text;
      _dobController.text = personal['dob'] ?? _dobController.text;
      _gender = personal['gender'] ?? _gender;
      _prefilledFromArgs = true;
      // Preserve any incoming address so we can forward it when going to /address
      if (addressFromArgs != null) _incomingAddress = addressFromArgs;
    }
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations=AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          // 🖼️ SVG Image with Logo at the Top
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
                // Back button positioned on top-left of the header SVG
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () async {
                        final popped = await Navigator.of(context).maybePop();
                        if (!popped) {
                          if (mounted) context.go('/');
                        }
                      },
                      tooltip: 'Back',
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Transform.translate(
                    offset: const Offset(0,0),
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
                      localizations?.register??'Register',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Full Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: localizations?.fullName ?? 'Full Name',
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
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations?.pleaseEnterName ?? 'Please enter your name';
                        }
                        if (!Validators.isValidName(value)) {
                          return localizations?.nameOnlyLetters ?? 'Name can only contain letters and spaces';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: localizations?.email ?? 'Email',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.email, color: Colors.black),
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
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations?.pleaseEnterEmail ?? 'Please enter your email';
                        }
                        if (!Validators.isValidEmail(value)) {
                          return localizations?.pleaseEnterValidEmail ?? 'Please enter a valid email';
                        }
                  
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: localizations?.phone ?? 'Phone',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.phone, color: Colors.black),
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
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations?.pleaseEnterPhone ?? 'Please enter your phone number';
                        }
                        if (!Validators.isValidIndianPhone(value)) {

                          return localizations?.pleaseEnterValidPhone ?? 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Date of Birth Field with Calendar
                    TextFormField(
                      controller: _dobController,
                      readOnly: true, // Prevent manual text input
                      decoration: InputDecoration(
                        labelText: localizations?.dateOfBirth ?? 'Date of Birth (YYYY-MM-DD)',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.calendar_today, color: Colors.black),
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
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      onTap: () => _selectDate(context), // Show date picker on tap
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations?.pleaseSelectDOB ?? 'Please select your date of birth';
                        }
                       if (!Validators.isValidDOB(value)) {

                          return localizations?.enterValidDateFormat ?? 'You must be at least 18 years old to register';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Gender Dropdown
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: [
                        DropdownMenuItem(value: 'Male', child: Text(localizations?.male ?? 'Male')),
                        DropdownMenuItem(value: 'Female', child: Text(localizations?.female ?? 'Female')),
                        DropdownMenuItem(value: 'Other', child: Text(localizations?.other ?? 'Other')),
                      ],
                      onChanged: (value) {
                        setState(() => _gender = value!);
                      },
                      decoration: InputDecoration(
                        labelText: localizations?.gender ?? 'Gender',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.black),
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
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        if (value == null) {
                          return localizations?.pleaseSelectGender ?? 'Please select your gender';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Consent Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _isConsentAccepted,
                          activeColor: const Color(0xFFFC633C),
                          onChanged: (val) {
                            setState(() => _isConsentAccepted = val ?? false);
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Open PDF Viewer
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ConsentPdfViewer(
                                    assetPath: 'assets/data/Dharma_Citizen_Consent.pdf',
                                    title: 'Terms & Conditions',
                                  ),
                                ),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: const TextStyle(color: Colors.black, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: const TextStyle(
                                      color: Color(0xFFFC633C),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          backgroundColor: const Color(0xFFFC633C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Text(
                          localizations?.next ?? 'Next',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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