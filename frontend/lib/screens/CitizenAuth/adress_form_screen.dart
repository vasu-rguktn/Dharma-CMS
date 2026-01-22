import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // 🔽 Searchable dropdown state
  bool _dataLoading = true;
  Map<String, List<String>> _districtStations = {};

  String? _selectedDistrict;
  String? _selectedPoliceStation;

  /* ================= INIT ================= */

  @override
  void initState() {
    super.initState();
    _loadDistrictStations();
  }

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

  /* ================= SEARCHABLE DROPDOWN ================= */

  Future<void> _openSearchableDropdown({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required void Function(String value) onSelected,
  }) async {
    if (items.isEmpty) return;

    final searchController = TextEditingController();
    List<String> filtered = List.from(items);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filtered = items
                              .where((e) =>
                                  e.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, index) {
                        final item = filtered[index];
                        return ListTile(
                          title: Text(item),
                          trailing: item == selectedValue
                              ? const Icon(Icons.check,
                                  color: Colors.green)
                              : null,
                          onTap: () {
                            onSelected(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /* ================= PICKER UI ================= */

  Widget _picker({
    required String label,
    required String? value,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.arrow_drop_down),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          value ?? 'Select $label',
          style: TextStyle(
            color: value == null ? Colors.grey : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /* ================= SUBMIT ================= */

  void _submitForm(Map<String, dynamic>? personalData, String userType) {
    final localizations = AppLocalizations.of(context);

    if (_selectedDistrict == null || _selectedPoliceStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select district and police station')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final addressData = {
        'houseNo': _houseController.text.trim(),
        'address': _cityController.text.trim(),
        'district': _selectedDistrict,
        'pincode': _pincodeController.text.trim(),
        'policestation': _selectedPoliceStation,
      };

      context.go('/login_details', extra: {
        'personal': personalData,
        'address': addressData,
        'userType': userType,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                localizations?.fillFieldsCorrectly ??
                    'Please fill all fields correctly')),
      );
    }
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context);

    final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final personalData = args?['personal'] as Map<String, dynamic>?;
    final addressArgs = args?['address'] as Map<String, dynamic>?;
    final userType = args?['userType'] ?? 'citizen';

    if (personalData == null) {
      return const Scaffold(
        body: Center(child: Text('Personal data not provided')),
      );
    }

    if (!_prefilledFromArgs && addressArgs != null) {
      _houseController.text = addressArgs['houseNo'] ?? '';
      _cityController.text = addressArgs['address'] ?? '';
      _pincodeController.text = addressArgs['pincode'] ?? '';
      _selectedDistrict = addressArgs['district'];
      _selectedPoliceStation = addressArgs['policestation'];
      _prefilledFromArgs = true;
    }

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.3,
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/Frame.svg',
                  fit: BoxFit.fill,
                  width: double.infinity,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/police_logo.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _dataLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            localizations?.addressDetails ?? 'Address Details',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 24),

                          TextFormField(
                            controller: _houseController,
                            decoration: const InputDecoration(
                              labelText: 'House No',
                              prefixIcon: Icon(Icons.home),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Enter house number'
                                    : null,
                          ),

                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City / Town',
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty
                                    ? 'Enter city'
                                    : null,
                          ),

                          const SizedBox(height: 20),

                          _picker(
                            label: 'District',
                            value: _selectedDistrict,
                            onTap: () {
                              _openSearchableDropdown(
                                title: 'Select District',
                                items: _districtStations.keys.toList(),
                                selectedValue: _selectedDistrict,
                                onSelected: (v) {
                                  setState(() {
                                    _selectedDistrict = v;
                                    _selectedPoliceStation = null;
                                  });
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _pincodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Pincode',
                              prefixIcon: Icon(Icons.pin),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter pincode';
                              }
                              if (!Validators
                                  .isValidAndhraPradeshPincode(v)) {
                                return 'Enter valid AP pincode';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          _picker(
                            label: 'Police Station',
                            value: _selectedPoliceStation,
                            onTap: _selectedDistrict == null
                                ? null
                                : () {
                                    _openSearchableDropdown(
                                      title: 'Select Police Station',
                                      items: _districtStations[
                                          _selectedDistrict!]!,
                                      selectedValue:
                                          _selectedPoliceStation,
                                      onSelected: (v) {
                                        setState(() =>
                                            _selectedPoliceStation = v);
                                      },
                                    );
                                  },
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _submitForm(personalData, userType),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18),
                                backgroundColor:
                                    const Color(0xFFFC633C),
                              ),
                              child: const Text(
                                'Next',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
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
    super.dispose();
  }
}
