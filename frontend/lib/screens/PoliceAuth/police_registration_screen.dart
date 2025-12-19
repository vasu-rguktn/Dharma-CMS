import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';

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
    'Director General of Police',
    'Additional Director General of Police',
    'Inspector General of Police',
    'Deputy Inspector General of Police',
    'Superintendent of Police',
    'Additional Superintendent of Police',
    'Deputy Superintendent of Police',
    'Inspector of Police',
    'Sub Inspector of Police',
    'Assistant Sub Inspector of Police',
    'Head Constable',
    'Police Constable',
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchHint,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filtered = items
                              .where((e) => e
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /* ================= SUBMIT ================= */

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDistrict == null ||
        _selectedStation == null ||
        _selectedRank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectAllDropdownFields)),
      );
      return;
    }

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
        SnackBar(content: Text(AppLocalizations.of(context)!.policeRegisteredSuccessfully)),
      );

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
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: h * 0.3,
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
        context.go('/'); // ✅ Always go to Home page
      },
                    ),
                  ),
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
                            AppLocalizations.of(context)!.policeRegistration,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 24),

                          _textField(
                            _nameController,
                            AppLocalizations.of(context)!.fullName,
                            Icons.person,
                            (v) =>
                                Validators.isValidName(v ?? '')
                                    ? null
                                    : AppLocalizations.of(context)!.invalidName,
                          ),

                          const SizedBox(height: 20),

                          _textField(
                            _emailController,
                            AppLocalizations.of(context)!.email,
                            Icons.email,
                            (v) =>
                                Validators.isValidEmail(v ?? '')
                                    ? null
                                    : AppLocalizations.of(context)!.invalidEmailShort,
                          ),

                          const SizedBox(height: 20),

                          _textField(
                            _passwordController,
                            AppLocalizations.of(context)!.password,
                            Icons.lock,
                            (v) =>
                                Validators.isValidPassword(v ?? '')
                                    ? null
                                    : AppLocalizations.of(context)!.passwordMinRequirement,
                            obscure: true,
                          ),

                          const SizedBox(height: 20),

                          _picker(
                            label: AppLocalizations.of(context)!.district,
                            value: _selectedDistrict,
                            onTap: () {
                              _openSearchableDropdown(
                                title: AppLocalizations.of(context)!.selectDistrict,
                                items: _districtStations.keys.toList(),
                                selectedValue: _selectedDistrict,
                                onSelected: (v) {
                                  setState(() {
                                    _selectedDistrict = v;
                                    _selectedStation = null;
                                  });
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          _picker(
                            label: AppLocalizations.of(context)!.policeStation,
                            value: _selectedStation,
                            onTap: _selectedDistrict == null
                                ? null
                                : () {
                                    _openSearchableDropdown(
                                      title: AppLocalizations.of(context)!.selectPoliceStationText,
                                      items: _districtStations[
                                          _selectedDistrict!]!,
                                      selectedValue: _selectedStation,
                                      onSelected: (v) {
                                        setState(() =>
                                            _selectedStation = v);
                                      },
                                    );
                                  },
                          ),

                          const SizedBox(height: 20),

                          _picker(
                            label: AppLocalizations.of(context)!.rank,
                            value: _selectedRank,
                            onTap: () {
                              _openSearchableDropdown(
                                title: AppLocalizations.of(context)!.selectRank,
                                items: _ranks,
                                selectedValue: _selectedRank,
                                onSelected: (v) {
                                  setState(() => _selectedRank = v);
                                },
                              );
                            },
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
                                  : Text(
                                      AppLocalizations.of(context)!.register,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
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

  /* ================= HELPERS ================= */

  Widget _textField(
    TextEditingController controller,
    String label,
    IconData icon,
    String? Function(String?) validator, {
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// ✅ SAFE PICKER (NO onTap CRASH)
  Widget _picker({
    required String label,
    required String? value,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap == null ? null : () => onTap(),
      child: IgnorePointer(
        ignoring: onTap == null,
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
              color: onTap == null ? Colors.grey : Colors.black,
              fontSize: 16,
            ),
          ),
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
