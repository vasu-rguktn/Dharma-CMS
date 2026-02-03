import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';

import 'package:Dharma/data/revised_police_hierarchy.dart'; // ✅ UPDATED IMPORT
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
  String? _selectedSDPO; // New
  String? _selectedCircle; // New
  String? _selectedStation;

  bool _loading = false;
  bool _dataLoading = true;

  // ✅ Store hierarchy: Range → Districts → Stations (Legacy/Compat for Ranges)
  Map<String, Map<String, List<String>>> _policeHierarchy = {};
  
  // ✅ Store deep hierarchy from new data
  List<dynamic> _deepDistricts = [];

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
      
      // 1. Load Legacy Range/District Map (still useful for Range selection)
      final jsonStr = await rootBundle
          .loadString('assets/data/ap_police_hierarchy_complete.json');
      final Map<String, dynamic> data = json.decode(jsonStr);

      Map<String, Map<String, List<String>>> hierarchy = {};
      data.forEach((range, districts) {
        if (districts is Map) {
          Map<String, List<String>> districtMap = {};
          districts.forEach((district, stations) {
            // We ignore stations here, we'll get them from deep data
            districtMap[district.toString()] = []; 
          });
          hierarchy[range] = districtMap;
        }
      });

      // 2. Load Deep Data from Revised Data
      // ignore: undefined_identifier
      debugPrint('🔄 [Registration] Accessing kRevisedPoliceHierarchy...');
      final districtsList = kRevisedPoliceHierarchy['districts'] as List<dynamic>? ?? [];
      debugPrint('✅ [Registration] Deep Districts (Revised) found: ${districtsList.length}');
      
      if (districtsList.isNotEmpty) {
         debugPrint('ℹ️ [Registration] First District: ${districtsList.first['name']}');
      }

      setState(() {
        _policeHierarchy = hierarchy;
        _deepDistricts = districtsList;
        _dataLoading = false;
      });
      
    } catch (e, stack) {
      debugPrint('❌ [Registration] Error loading hierarchy data: $e');
      debugPrint('❌ [Registration] Stack: $stack');
      setState(() => _dataLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading hierarchy: $e')),
        );
      }
    }
  }

  /* ================= RANK-BASED FIELD VISIBILITY ================= */

  bool _shouldShowRange() {
    if (_selectedRank == null) return false;
    return _rangeLevelRanks.contains(_selectedRank) ||
        _districtLevelRanks.contains(_selectedRank) ||
        _stationLevelRanks.contains(_selectedRank);
  }

  bool _shouldShowDistrict() {
    if (_selectedRank == null) return false;
    return _districtLevelRanks.contains(_selectedRank) ||
        _stationLevelRanks.contains(_selectedRank);
  }

  bool _shouldShowSDPO() {
    if (_selectedRank == null) return false;
    // Show for DSP and below (Inspector, SI, Constable)
    // "Deputy Superintendent of Police" is in _stationLevelRanks in original code?
    // Let's check _stationLevelRanks definition: it INCLUDED DSP.
    return _stationLevelRanks.contains(_selectedRank);
  }

  bool _shouldShowCircle() {
    if (_selectedRank == null) return false;
    // Show for Inspector and below
    if (_selectedRank == 'Deputy Superintendent of Police') return false; // DSP is above Circle level assignment-wise (they manage SDPO)
    return _stationLevelRanks.contains(_selectedRank); 
  }

  bool _shouldShowStation() {
    if (_selectedRank == null) return false;
    // DSP heads the SDPO, so they don't select a Station.
    if (_selectedRank == 'Deputy Superintendent of Police') return false; 
    
    // For Inspector (SHO/CI) and below, they select Station.
    return _stationLevelRanks.contains(_selectedRank);
  }

  /* ================= RESET DEPENDENT FIELDS ================= */

  /* ================= RESET DEPENDENT FIELDS ================= */

  void _onRankChanged(String? rank) {
    setState(() {
      _selectedRank = rank;
      // Reset all hierarchy fields
      _selectedRange = null;
      _selectedDistrict = null;
      _selectedSDPO = null;
      _selectedCircle = null;
      _selectedStation = null;
    });
    debugPrint('🎖️ Rank changed to: $rank');
  }

  void _onRangeChanged(String? range) {
    setState(() {
      _selectedRange = range;
      _selectedDistrict = null;
      _selectedSDPO = null;
      _selectedCircle = null;
      _selectedStation = null;
    });
    debugPrint('📍 Range changed to: $range');
  }

  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedSDPO = null;
      _selectedCircle = null;
      _selectedStation = null;
    });
    debugPrint('🗺️ District changed to: $district');
  }

  void _onSDPOChanged(String? sdpo) {
    setState(() {
      _selectedSDPO = sdpo;
      _selectedCircle = null;
      _selectedStation = null;
    });
    debugPrint('🏢 SDPO changed to: $sdpo');
  }

  void _onCircleChanged(String? circle) {
    setState(() {
      _selectedCircle = circle;
      _selectedStation = null;
    });
    debugPrint('⭕ Circle changed to: $circle');
  }

  /* ================= GETTERS FOR DROPDOWNS ================= */

  List<String> _getAvailableRanges() {
    return _policeHierarchy.keys.toList();
  }

  List<String> _getAvailableDistricts() {
    if (_selectedRange == null) return [];
    final districts = _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
    return districts;
  }

  // Helper to find district object
  Map<String, dynamic>? _getCurrentDistrictObj() {
    if (_selectedDistrict == null) return null;
    try {
      debugPrint('🔍 [Registration] Looking for District: "$_selectedDistrict"');
      dynamic match;
      for (final d in _deepDistricts) {
          final dataName = d['name'].toString().toLowerCase().trim(); // e.g., "sp eluru"
          final selected = _selectedDistrict!.toLowerCase().trim();   // e.g., "eluru"
          
          if (dataName == selected || 
              dataName == "sp $selected" || 
              dataName.toString().replaceFirst('sp ', '').trim() == selected) {
            match = d;
            break;
          }
      }
      
      if (match != null) {
         debugPrint('✅ [Registration] Found District Match: "${match['name']}"');
      } else {
         debugPrint('❌ [Registration] No District Match found for: "$_selectedDistrict"');
      }
      return match as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('❌ [Registration] Error finding district: $e');
      return null;
    }
  }

  List<String> _getAvailableSDPOs() {
    if (_selectedDistrict == null) return [];
    
    final distObj = _getCurrentDistrictObj();
    if (distObj == null) {
      debugPrint('⚠️ [Registration] Cannot load SDPOs because district object is null.');
      return [];
    }

    final sdpos = distObj['sdpos'] as List<dynamic>? ?? [];
    debugPrint('✅ [Registration] Loaded ${sdpos.length} SDPOs for district.');
    return sdpos.map((s) => s['name'] as String).toList();
  }

  Map<String, dynamic>? _getCurrentSDPOObj() {
    final distObj = _getCurrentDistrictObj();
    if (distObj == null || _selectedSDPO == null) return null;
    
    final sdpos = distObj['sdpos'] as List<dynamic>? ?? [];
    try {
      debugPrint('🔍 [Registration] Looking for SDPO: "$_selectedSDPO"');
      for (final s in sdpos) {
        if (s['name'].toString().trim() == _selectedSDPO!.trim()) {
           debugPrint('✅ [Registration] Found SDPO Match: "${s['name']}"');
           return s;
        }
      }
      debugPrint('❌ [Registration] No SDPO Match found for "$_selectedSDPO"');
      return null;
    } catch (e) { return null; }
  }

  List<String> _getAvailableCircles() {
    if (_selectedSDPO == null) return [];
    
    final sdpoObj = _getCurrentSDPOObj();
    if (sdpoObj == null) {
       debugPrint('⚠️ [Registration] Cannot load Circles because SDPO object is null.');
       return [];
    }

    final circles = sdpoObj['circles'] as List<dynamic>? ?? [];
    debugPrint('✅ [Registration] Loaded ${circles.length} Circles for SDPO.');
    return circles.map((c) => c['name'] as String).toList();
  }

  Map<String, dynamic>? _getCurrentCircleObj() {
    final sdpoObj = _getCurrentSDPOObj();
    if (sdpoObj == null || _selectedCircle == null) return null;

    final circles = sdpoObj['circles'] as List<dynamic>? ?? [];
    try {
      debugPrint('🔍 [Registration] Looking for Circle: "$_selectedCircle"');
      for (final c in circles) {
         if (c['name'].toString().trim() == _selectedCircle!.trim()) {
            debugPrint('✅ [Registration] Found Circle Match: "${c['name']}"');
            return c;
         }
      }
      debugPrint('❌ [Registration] No Circle Match found for "$_selectedCircle"');
      return null;
    } catch (e) { return null; }
  }

  List<String> _getAvailableStations() {
    // If rank is Inspector/SI, they might select station under a circle
    if (_selectedCircle == null) return [];
    
    final circleObj = _getCurrentCircleObj();
    if (circleObj == null) return [];

    final stations = circleObj['police_stations'] as List<dynamic>? ?? [];
    return stations.map((s) => s.toString()).toList();
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

    if (_shouldShowSDPO() && _selectedSDPO == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Sub-Division (SDPO)')),
      );
      return;
    }

    if (_shouldShowCircle() && _selectedCircle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Circle')),
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
            sdpo: _selectedSDPO,
            circle: _selectedCircle,
            stationName: _selectedStation,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.policeRegisteredSuccessfully)),
      );

      context.go('/police-dashboard');
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading Registration Data...',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
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

                          // ✅ NEW: SDPO (Show if rank matches)
                          if (_shouldShowSDPO()) ...[
                            const SizedBox(height: 20),
                            _picker(
                              label: 'Sub-Division (SDPO)',
                              value: _selectedSDPO,
                              icon: Icons.business,
                              mandatory: true,
                              onTap: _selectedDistrict == null
                                  ? null
                                  : () {
                                      _openSearchableDropdown(
                                        title: 'Select SDPO',
                                        items: _getAvailableSDPOs(),
                                        selectedValue: _selectedSDPO,
                                        onSelected: _onSDPOChanged,
                                      );
                                    },
                            ),
                          ],

                          // ✅ NEW: CIRCLE (Show if rank matches)
                          if (_shouldShowCircle()) ...[
                            const SizedBox(height: 20),
                            _picker(
                              label: 'Circle',
                              value: _selectedCircle,
                              icon: Icons.trip_origin,
                              mandatory: true,
                              onTap: _selectedSDPO == null
                                  ? null
                                  : () {
                                      _openSearchableDropdown(
                                        title: 'Select Circle',
                                        items: _getAvailableCircles(),
                                        selectedValue: _selectedCircle,
                                        onSelected: _onCircleChanged,
                                      );
                                    },
                            ),
                          ],

                          // ✅ 8. POLICE STATION (Show ONLY for Station level)
                          if (_shouldShowStation()) ...[
                            const SizedBox(height: 20),
                            _picker(
                              label: 'SHO (Station)',
                              value: _selectedStation,
                              icon: Icons.local_police,
                              mandatory: true,
                              onTap: _selectedCircle == null
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
