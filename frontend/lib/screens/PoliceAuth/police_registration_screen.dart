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

  String? _selectedRank; // ✅ SELECT RANK FIRST
  String? _selectedRange;
  String? _selectedDistrict;
  String? _selectedStation;

  bool _loading = false;
  bool _dataLoading = true;

  // ✅ Store hierarchy: Range → Districts → Stations
  Map<String, Map<String, List<String>>> _policeHierarchy = {};

  // ✅ RANK HIERARCHY DEFINITION
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

  // ✅ State Level Ranks (DGP, Addl. DGP)
  static const List<String> _stateLevelRanks = [
    'Director General of Police',
    'Additional Director General of Police',
  ];

  // ✅ Range Level Ranks (IGP, DIG)
  static const List<String> _rangeLevelRanks = [
    'Inspector General of Police',
    'Deputy Inspector General of Police',
  ];

  // ✅ District Level Ranks (SP, Addl. SP)
  static const List<String> _districtLevelRanks = [
    'Superintendent of Police',
    'Additional Superintendent of Police',
  ];

  // ✅ Station Level Ranks (all others)
  static const List<String> _stationLevelRanks = [
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
    _loadPoliceHierarchy();
  }

  /* ================= LOAD HIERARCHY DATA ================= */

  Future<void> _loadPoliceHierarchy() async {
    try {
      debugPrint('🔄 Loading police hierarchy data...');
      final jsonStr = await rootBundle
          .loadString('assets/data/ap_police_hierarchy_complete.json');
      final Map<String, dynamic> data = json.decode(jsonStr);

      // Convert to proper structure
      Map<String, Map<String, List<String>>> hierarchy = {};
      int totalDistricts = 0;
      int totalStations = 0;
      
      data.forEach((range, districts) {
        if (districts is Map) {
          Map<String, List<String>> districtMap = {};
          districts.forEach((district, stations) {
            final stationList = List<String>.from(stations ?? []);
            districtMap[district.toString()] = stationList;
            totalDistricts++;
            totalStations += stationList.length;
          });
          hierarchy[range] = districtMap;
        }
      });

      setState(() {
        _policeHierarchy = hierarchy;
        _dataLoading = false;
      });
      
      debugPrint('✅ Hierarchy loaded successfully!');
      debugPrint('   📊 Ranges: ${hierarchy.length}');
      debugPrint('   📊 Districts: $totalDistricts');
      debugPrint('   📊 Stations: $totalStations');
      debugPrint('   📋 Available Ranges: ${hierarchy.keys.join(", ")}');
    } catch (e) {
      debugPrint('❌ Error loading hierarchy data: $e');
      setState(() => _dataLoading = false);
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading police hierarchy: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /* ================= RANK-BASED FIELD VISIBILITY ================= */

  bool _shouldShowRange() {
    if (_selectedRank == null) return false;
    // Show for Range, District, and Station level ranks
    return _rangeLevelRanks.contains(_selectedRank) ||
        _districtLevelRanks.contains(_selectedRank) ||
        _stationLevelRanks.contains(_selectedRank);
  }

  bool _shouldShowDistrict() {
    if (_selectedRank == null) return false;
    // Show for District and Station level ranks
    return _districtLevelRanks.contains(_selectedRank) ||
        _stationLevelRanks.contains(_selectedRank);
  }

  bool _shouldShowStation() {
    if (_selectedRank == null) return false;
    // Show ONLY for Station level ranks
    return _stationLevelRanks.contains(_selectedRank);
  }

  /* ================= RESET DEPENDENT FIELDS ================= */

  void _onRankChanged(String? rank) {
    setState(() {
      _selectedRank = rank;
      // Reset all hierarchy fields
      _selectedRange = null;
      _selectedDistrict = null;
      _selectedStation = null;
    });
    debugPrint('🎖️ Rank changed to: $rank');
  }

  void _onRangeChanged(String? range) {
    setState(() {
      _selectedRange = range;
      // Reset dependent fields
      _selectedDistrict = null;
      _selectedStation = null;
    });
    debugPrint('📍 Range changed to: $range');
    debugPrint('   Available districts: ${_getAvailableDistricts().length}');
  }

  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
      // Reset dependent field
      _selectedStation = null;
    });
    debugPrint('🗺️ District changed to: $district');
    debugPrint('   Available stations: ${_getAvailableStations().length}');
  }

  /* ================= GETTERS FOR DROPDOWNS ================= */

  List<String> _getAvailableRanges() {
    final ranges = _policeHierarchy.keys.toList();
    debugPrint('📋 Getting available ranges: ${ranges.length} found');
    return ranges;
  }

  List<String> _getAvailableDistricts() {
    if (_selectedRange == null) {
      debugPrint('⚠️ No range selected, returning empty district list');
      return [];
    }
    final districts = _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
    debugPrint('📋 Getting districts for "$_selectedRange": ${districts.length} found');
    if (districts.isNotEmpty) {
      debugPrint('   First 3 districts: ${districts.take(3).join(", ")}');
    }
    return districts;
  }

  List<String> _getAvailableStations() {
    if (_selectedRange == null || _selectedDistrict == null) {
      debugPrint('⚠️ Range or District not selected, returning empty station list');
      return [];
    }
    final stations = _policeHierarchy[_selectedRange]?[_selectedDistrict] ?? [];
    debugPrint('📋 Getting stations for "$_selectedRange → $_selectedDistrict": ${stations.length} found');
    if (stations.isNotEmpty) {
      debugPrint('   First 3 stations: ${stations.take(3).join(", ")}');
    }
    return stations;
  }

  /* ================= SEARCHABLE DROPDOWN ================= */

  Future<void> _openSearchableDropdown({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required void Function(String value) onSelected,
  }) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No options available for $title')),
      );
      return;
    }

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

  /* ================= VALIDATION & SUBMIT ================= */

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Rank-based validation
    if (_selectedRank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your rank first')),
      );
      return;
    }

    // Validate based on rank
    if (_shouldShowRange() && _selectedRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Range')),
      );
      return;
    }

    if (_shouldShowDistrict() && _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your District')),
      );
      return;
    }

    if (_shouldShowStation() && _selectedStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Police Station')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await context.read<PoliceAuthProvider>().registerPolice(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            rank: _selectedRank!,
            range: _selectedRange,
            district: _selectedDistrict,
            stationName: _selectedStation,
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

                          const SizedBox(height: 8),
                          
                          // ✅ IMPORTANT: RANK MUST BE SELECTED FIRST
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              border: Border.all(color: Colors.amber.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amber.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '⚠️ Please select your RANK first. Form fields will appear based on your rank.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ✅ 1. RANK (MANDATORY - FIRST STEP)
                          _picker(
                            label: AppLocalizations.of(context)!.rank,
                            value: _selectedRank,
                            icon: Icons.military_tech,
                            mandatory: true,
                            onTap: () {
                              _openSearchableDropdown(
                                title: AppLocalizations.of(context)!.selectRank,
                                items: _ranks,
                                selectedValue: _selectedRank,
                                onSelected: _onRankChanged,
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // ✅ 2. NAME
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

                          // ✅ 3. EMAIL
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

                          // ✅ 4. PASSWORD
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

                          // ✅ 5. STATE (READ-ONLY, Auto-populated)
                          _readOnlyField(
                            label: 'State',
                            value: 'Andhra Pradesh',
                            icon: Icons.location_on,
                          ),

                          // ✅ 6. RANGE (Show for IGP, DIG, SP, Addl. SP, and Station level)
                          if (_shouldShowRange()) ...[
                            const SizedBox(height: 20),
                            _picker(
                              label: 'Range (Zone)',
                              value: _selectedRange,
                              icon: Icons.location_city,
                              mandatory: true,
                              onTap: () {
                                _openSearchableDropdown(
                                  title: 'Select Range',
                                  items: _getAvailableRanges(),
                                  selectedValue: _selectedRange,
                                  onSelected: _onRangeChanged,
                                );
                              },
                            ),
                          ],

                          // ✅ 7. DISTRICT (Show for SP, Addl. SP, and Station level)
                          if (_shouldShowDistrict()) ...[
                            const SizedBox(height: 20),
                            _picker(
                              label: AppLocalizations.of(context)!.district,
                              value: _selectedDistrict,
                              icon: Icons.map,
                              mandatory: true,
                              onTap: _selectedRange == null
                                  ? null
                                  : () {
                                      _openSearchableDropdown(
                                        title: AppLocalizations.of(context)!.selectDistrict,
                                        items: _getAvailableDistricts(),
                                        selectedValue: _selectedDistrict,
                                        onSelected: _onDistrictChanged,
                                      );
                                    },
                            ),
                          ],

                          // ✅ 8. POLICE STATION (Show ONLY for Station level)
                          if (_shouldShowStation()) ...[
                            const SizedBox(height: 20),
                            _picker(
                              label: AppLocalizations.of(context)!.policeStation,
                              value: _selectedStation,
                              icon: Icons.local_police,
                              mandatory: true,
                              onTap: _selectedDistrict == null
                                  ? null
                                  : () {
                                      _openSearchableDropdown(
                                        title: AppLocalizations.of(context)!.selectPoliceStationText,
                                        items: _getAvailableStations(),
                                        selectedValue: _selectedStation,
                                        onSelected: (v) {
                                          setState(() => _selectedStation = v);
                                        },
                                      );
                                    },
                            ),
                          ],

                          const SizedBox(height: 30),

                          // ✅ SUBMIT BUTTON
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

  /// ✅ READ-ONLY FIELD (for State)
  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// ✅ SAFE PICKER
  Widget _picker({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback? onTap,
    bool mandatory = false,
  }) {
    final isDisabled = onTap == null;
    
    return InkWell(
      onTap: isDisabled ? null : () => onTap(),
      child: IgnorePointer(
        ignoring: isDisabled,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: mandatory ? '$label *' : label,
            labelStyle: TextStyle(
              color: mandatory ? Colors.red.shade700 : null,
              fontWeight: mandatory ? FontWeight.w600 : null,
            ),
            prefixIcon: Icon(icon, 
              color: isDisabled ? Colors.grey : null,
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            filled: true,
            fillColor: isDisabled ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            value ?? 'Select $label',
            style: TextStyle(
              color: isDisabled ? Colors.grey : Colors.black,
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
