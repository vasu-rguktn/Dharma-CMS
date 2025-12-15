import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/utils/validators.dart';
class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _prefilledFromArgs = false;
  final _houseController = TextEditingController();
  final _cityController = TextEditingController();
  

  final _pincodeController = TextEditingController();
  final _policeStationController = TextEditingController();


   String? _selectedDistrict;

final List<String> _apDistricts = [
  'Alluri Sitharama Raju',
  'Anakapalli',
  'Anantapur',
  'Annamayya',
  'Bapatla',
  'Chittoor',
  'East Godavari',
  'Eluru',
  'Guntur',
  'Kadapa',
  'Kakinada',
  'Konaseema',
  'Krishna',
  'Kurnool',
  'Manyam',
  'Nandyal',
  'NTR',
  'Palnadu',
  'Prakasam',
  'Sri Sathya Sai',
  'Srikakulam',
  'Tirupati',
  'Visakhapatnam',
  'Vizianagaram',
  'West Godavari',
]..sort();

  void _submitForm(Map<String, dynamic>? personalData, String? userType) {
    final localizations = AppLocalizations.of(context);
    if (personalData == null) {
      debugPrint('Error: Personal data is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.personalDataNotProvided ?? 'Error: Personal data not provided')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final addressData = {
        'houseNo': _houseController.text.trim(),
        'address': _cityController.text.trim(),
        'district': _selectedDistrict,

        
        'pincode': _pincodeController.text.trim(),
        'policestation': _policeStationController.text.trim(),
      };
      debugPrint('Submitting address data: $addressData');
      try {
        context.go('/login_details', extra: {
          'personal': personalData,
          'address': addressData,
          'userType': userType ?? 'citizen',
        });
        debugPrint('Navigation to /login_details attempted with userType: ${userType ?? 'citizen'}');
      } catch (e) {
        debugPrint('Navigation error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations?.personalDataNotProvided ?? 'Error: Personal data not provided')),
        );
      }
    } else {
      debugPrint('Address form validation failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations?.fillFieldsCorrectly ?? 'Please fill all fields correctly')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context);
    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final personalData = args?['personal'] as Map<String, dynamic>?;
    final addressArgs = args?['address'] as Map<String, dynamic>?;
    final userType = args?['userType'] as String? ?? 'citizen';
    debugPrint('Received args in AddressFormScreen: $args');
    debugPrint('Received userType: $userType');

    if (personalData == null) {
      debugPrint('Personal data is null, showing error screen');
      final localizations = AppLocalizations.of(context);
      return Scaffold(
        body: Center(child: Text(localizations?.personalDataNotProvided ?? 'Error: Personal data not provided')),
      );
    }

    // Prefill address fields if we received them via `extra`.
    if (!_prefilledFromArgs && addressArgs != null) {
      _houseController.text = addressArgs['houseNo'] ?? _houseController.text;
      _cityController.text = addressArgs['address'] ?? _cityController.text;
     _selectedDistrict = addressArgs['district'];

      _pincodeController.text = addressArgs['pincode'] ?? _pincodeController.text;
      _policeStationController.text = addressArgs['policestation'] ?? _policeStationController.text;
      _prefilledFromArgs = true;
    }

    return Scaffold(
      body: Column(
        children: [
          // 🖼️ SVG Image with Logo at the Top
          SizedBox(
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
          // 📏 Gap between image and text
          const SizedBox(height: 32),
          // 📱 Address Form Content with Scrolling
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
                      localizations?.addressDetails ?? 'Address Details',
                      style:const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // House No Field
                    TextFormField(
                      controller: _houseController,
                      decoration: InputDecoration(
                        labelText: localizations?.houseNo ?? 'House No',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.home, color: Colors.black),
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
                          return localizations?.enterHouseNumber ?? 'Please enter your house number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // City/Town Field
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: localizations?.cityTown ?? 'City/Town',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.location_city, color: Colors.black),
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
                          return localizations?.enterCity ?? 'Enter your city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // District Field
                  DropdownButtonFormField<String>(
  value: _selectedDistrict,
  decoration: InputDecoration(
    labelText: localizations?.district ?? 'District',
    prefixIcon: const Icon(Icons.map),
    filled: true,                     // ✅ add
    fillColor: Colors.white,           // ✅ add
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
  ),
  items: _apDistricts
      .map(
        (district) => DropdownMenuItem(
          value: district,
          child: Text(district),
        ),
      )
      .toList(),
  onChanged: (value) {
    setState(() {
      _selectedDistrict = value;
    });
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return localizations?.enterDistrict ?? 'Select your district';
    }
    return null;
  },
),

                    // State Field
                    
                    const SizedBox(height: 20),
                    // Pincode Field
                    TextFormField(
                      controller: _pincodeController,
                      decoration: InputDecoration(
                        labelText: localizations?.pincode ?? 'Pincode',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.pin, color: Colors.black),
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
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return localizations?.enterPincode ?? 'Please enter your pincode';
                        }
                       if (!Validators.isValidAndhraPradeshPincode(value)) {
  return localizations?.enterValidPincode ??
      'Enter a valid Andhra Pradesh pincode';
}

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Police Station Field
                    TextFormField(
                      controller: _policeStationController,
                      decoration: InputDecoration(
                        labelText: localizations?.policeStation ?? 'Police Station',
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.local_police, color: Colors.black),
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
                          return localizations?.enterPoliceStation ?? 'Enter police station';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    // Previous + Next Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Navigate back to the personal details (signup) step
                              // and pass the personal data and current address so the forms
                              // can be prefilled when navigating back and forth.
                              try {
                                final currentAddress = {
                                  'houseNo': _houseController.text.trim(),
                                  'address': _cityController.text.trim(),
                                  'district': _selectedDistrict,
                                  'pincode': _pincodeController.text.trim(),
                                  'policestation': _policeStationController.text.trim(),
                                };
                                context.go('/signup', extra: {'personal': personalData, 'address': currentAddress});
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
                            onPressed: () => _submitForm(personalData, userType),
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
    _houseController.dispose();
    _cityController.dispose();
    
    _pincodeController.dispose();
    _policeStationController.dispose();
    super.dispose();
  }
}