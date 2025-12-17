import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:Dharma/providers/police_auth_provider.dart';
import 'package:Dharma/utils/validators.dart';

class PoliceRegistrationScreen extends StatefulWidget {
  const PoliceRegistrationScreen({super.key});

  @override
  State<PoliceRegistrationScreen> createState() =>
      _PoliceRegistrationScreenState();
}

class _PoliceRegistrationScreenState
    extends State<PoliceRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedDistrict;
  String? _selectedStation;
  String? _selectedRank;

  bool _loading = false;
  bool _dataLoading = true;

  Map<String, List<String>> _districtStations = {};

  final List<String> _ranks = const [
    'Constable',
    'Head Constable',
    'Sub Inspector',
    'Inspector',
    'DSP',
    'SP',
  ];

  @override
  void initState() {
    super.initState();
    _loadDistrictStations();
  }

  /* ================= LOAD DISTRICT DATA ================= */

  Future<void> _loadDistrictStations() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/data/district_police_stations.json');
      final Map<String, dynamic> data = json.decode(jsonStr);

      setState(() {
        _districtStations =
            data.map((k, v) => MapEntry(k, List<String>.from(v)));
        _dataLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading district data: $e');
      setState(() => _dataLoading = false);
    }
  }

  /* ================= SUBMIT ================= */

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await context.read<PoliceAuthProvider>().registerPolice(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            district: _selectedDistrict!,
            stationName: _selectedStation!,
            rank: _selectedRank!,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Police registered successfully')),
      );

      // ✅ After registration → go to police login
      context.go('/police-login');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          // ───────── HEADER ─────────
          SizedBox(
            height: screenHeight * 0.3,
            width: double.infinity,
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/Frame.svg',
                  fit: BoxFit.fill,
                  width: double.infinity,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/police_logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: _dataLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'Police Registration',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),

                          _textField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person,
                            validator: (v) =>
                                Validators.isValidName(v ?? '')
                                    ? null
                                    : 'Invalid name',
                          ),

                          const SizedBox(height: 20),

                          _textField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email,
                            validator: (v) =>
                                Validators.isValidEmail(v ?? '')
                                    ? null
                                    : 'Invalid email',
                          ),

                          const SizedBox(height: 20),

                          _textField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock,
                            obscure: true,
                            validator: (v) =>
                                Validators.isValidPassword(v ?? '')
                                    ? null
                                    : 'Min 8 chars, 1 number',
                          ),

                          const SizedBox(height: 20),

                          _dropdown(
                            label: 'District',
                            value: _selectedDistrict,
                            items: _districtStations.keys.toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedDistrict = v;
                                _selectedStation = null;
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          _dropdown(
                            label: 'Police Station',
                            value: _selectedStation,
                            items: _selectedDistrict == null
                                ? []
                                : _districtStations[_selectedDistrict!]!,
                            onChanged: (v) =>
                                setState(() => _selectedStation = v),
                          ),

                          const SizedBox(height: 20),

                          _dropdown(
                            label: 'Rank',
                            value: _selectedRank,
                            items: _ranks,
                            onChanged: (v) =>
                                setState(() => _selectedRank = v),
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor:
                                    const Color(0xFFFC633C),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= HELPERS ================= */

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: value,
      items: items
          .map((e) =>
              DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: items.isEmpty ? null : onChanged,
      validator: (v) => v == null ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.arrow_drop_down),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
