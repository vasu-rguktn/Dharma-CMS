// screens/address_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _houseController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _policeStationController = TextEditingController();

  Map<String, dynamic>? _personalData;
  bool _restored = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_restored) {
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      _personalData = args?['personal'] as Map<String, dynamic>?;
      final address = args?['address'] as Map<String, dynamic>?;

      if (address != null) {
        _houseController.text = address['houseNo'] ?? '';
        _cityController.text = address['address'] ?? '';
        _districtController.text = address['district'] ?? '';
        _stateController.text = address['state'] ?? '';
        _countryController.text = address['country'] ?? '';
        _pincodeController.text = address['pincode'] ?? '';
        _policeStationController.text = address['policestation'] ?? '';
      }
      _restored = true;
    }
  }

  void _goPrevious() {
    final addressData = {
      'houseNo': _houseController.text.trim(),
      'address': _cityController.text.trim(),
      'district': _districtController.text.trim(),
      'state': _stateController.text.trim(),
      'country': _countryController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'policestation': _policeStationController.text.trim(),
    };
    context.go('/signup', extra: {'personal': _personalData, 'address': addressData});
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final addressData = {
        'houseNo': _houseController.text.trim(),
        'address': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'policestation': _policeStationController.text.trim(),
      };
      context.go('/login_details', extra: {
        'personal': _personalData,
        'address': addressData,
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

    if (_personalData == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Personal data not provided')),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Header SVG + Logo
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
                      'Address Details',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // House No
                    TextFormField(
                      controller: _houseController,
                      decoration: InputDecoration(
                        labelText: 'House No',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.home, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your house number' : null,
                    ),
                    const SizedBox(height: 20),

                    // City
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.location_city, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your city' : null,
                    ),
                    const SizedBox(height: 20),

                    // District
                    TextFormField(
                      controller: _districtController,
                      decoration: InputDecoration(
                        labelText: 'District',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.map, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your district' : null,
                    ),
                    const SizedBox(height: 20),

                    // State
                    TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.flag, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your state' : null,
                    ),
                    const SizedBox(height: 20),

                    // Country
                    TextFormField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: 'Country',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.public, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your country' : null,
                    ),
                    const SizedBox(height: 20),

                    // Pincode
                    TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Pincode',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.pin, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your pincode' : null,
                    ),
                    const SizedBox(height: 20),

                    // Police Station
                    TextFormField(
                      controller: _policeStationController,
                      decoration: InputDecoration(
                        labelText: 'Police Station',
                        labelStyle: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w500),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.local_police, color: Colors.black),
                        contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
                        errorStyle: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter nearest police station' : null,
                    ),
                    const SizedBox(height: 24),

                    // Buttons Row - Previous = Orange, Next = Orange
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _goPrevious,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: const Color(0xFFFC633C), // Same orange
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Previous',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
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
    _districtController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _policeStationController.dispose();
    super.dispose();
  }
}