import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _aadharController;
  late TextEditingController _dobController;
  late TextEditingController _houseNoController;
  late TextEditingController _addressController;
  late TextEditingController _districtController;
  late TextEditingController _pincodeController;

  String? _selectedGender;

  // Police specific fields
  String? _selectedRank;
  String? _selectedRange;
  String? _selectedDistrict;
  String? _selectedStation;

  bool _dataLoading = true;
  Map<String, Map<String, List<String>>> _policeHierarchy = {};

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

  static const List<String> _rangeLevelRanks = [
    'Inspector General of Police',
    'Deputy Inspector General of Police',
  ];

  static const List<String> _districtLevelRanks = [
    'Superintendent of Police',
    'Additional Superintendent of Police',
  ];

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
    final user = context.read<AuthProvider>().userProfile;
    
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _aadharController = TextEditingController(text: user?.aadharNumber ?? '');
    _dobController = TextEditingController(text: user?.dob ?? '');
    _houseNoController = TextEditingController(text: user?.houseNo ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _districtController = TextEditingController(text: user?.district ?? '');
    _pincodeController = TextEditingController(text: user?.pincode ?? '');
    
    _selectedGender = user?.gender;

    // Load police specific fields
    if (user?.role == 'police') {
      _selectedRank = user?.rank;
      _selectedRange = user?.range;
      _selectedDistrict = user?.district;
      _selectedStation = user?.stationName;
      _loadPoliceHierarchy();
    } else {
      _dataLoading = false;
    }
  }

  Future<void> _loadPoliceHierarchy() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/data/ap_police_hierarchy_complete.json');
      final Map<String, dynamic> data = json.decode(jsonStr);

      Map<String, Map<String, List<String>>> hierarchy = {};
      data.forEach((range, districts) {
        if (districts is Map) {
          Map<String, List<String>> districtMap = {};
          districts.forEach((district, stations) {
            districtMap[district.toString()] = List<String>.from(stations ?? []);
          });
          hierarchy[range] = districtMap;
        }
      });

      if (mounted) {
        setState(() {
          _policeHierarchy = hierarchy;
          _dataLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading hierarchy: $e');
      if (mounted) setState(() => _dataLoading = false);
    }
  }

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

  bool _shouldShowStation() {
    if (_selectedRank == null) return false;
    return _stationLevelRanks.contains(_selectedRank);
  }

  List<String> _getAvailableRanges() => _policeHierarchy.keys.toList();

  List<String> _getAvailableDistricts() {
    if (_selectedRange == null) return [];
    return _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
  }

  List<String> _getAvailableStations() {
    if (_selectedRange == null || _selectedDistrict == null) return [];
    return _policeHierarchy[_selectedRange]?[_selectedDistrict] ?? [];
  }

  Future<void> _openSearchableDropdown({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required void Function(String value) onSelected,
  }) async {
    if (!_isEditing) return;
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
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                              .where((e) => e.toLowerCase().contains(value.toLowerCase()))
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
                          trailing: item == selectedValue ? const Icon(Icons.check, color: Colors.green) : null,
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

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _aadharController.dispose();
    _dobController.dispose();
    _houseNoController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context)!;

    try {
      await auth.updateUserProfile(
        uid: auth.user!.uid,
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        aadharNumber: _aadharController.text.trim(),
        dob: _dobController.text.trim(),
        houseNo: _houseNoController.text.trim(),
        address: _addressController.text.trim(),
        district: auth.role == 'police' ? _selectedDistrict : _districtController.text.trim(),
        pincode: _pincodeController.text.trim(),
        gender: _selectedGender,
        rank: _selectedRank,
        range: _selectedRange,
        stationName: _selectedStation,
      );

      setState(() => _isEditing = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Profile Updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${localizations.somethingWentWrong ?? "Error"}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: Colors.orange) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: _isEditing ? Colors.white : Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userProfile;
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (auth.isProfileLoading || _dataLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.profileInformation, 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.orange.shade100,
                      child: Text(
                        (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.camera_alt, color: Colors.orange.shade800, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Fields
              _buildSectionHeader(localizations.basicInformation ?? 'Basic Information'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _displayNameController,
                enabled: _isEditing,
                decoration: _inputDecoration(localizations.fullName ?? 'Full Name', icon: Icons.person),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(localizations.mobileNumber, icon: Icons.phone),
                validator: (val) {
                  if (val == null || val.isEmpty) return null; // Now optional
                  if (val.length < 10) return 'Invalid Number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _aadharController,
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration: _inputDecoration('Aadhar Number', icon: Icons.fingerprint).copyWith(counterText: ""),
                validator: (val) {
                  if (val == null || val.isEmpty) return null; // Now optional
                  if (val.length != 12) {
                    return 'Must be 12 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (auth.role != 'police') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        enabled: _isEditing,
                        decoration: _inputDecoration(localizations.dateOfBirth ?? 'Date of Birth', icon: Icons.calendar_today),
                        onTap: _isEditing ? () async {
                           final date = await showDatePicker(
                             context: context,
                             initialDate: DateTime.now(),
                             firstDate: DateTime(1900),
                             lastDate: DateTime.now(),
                           );
                           if (date != null) {
                             _dobController.text = "${date.day}/${date.month}/${date.year}";
                           }
                        } : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: _inputDecoration(localizations.gender ?? 'Gender', icon: Icons.people),
                        items: ['Male', 'Female', 'Other']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: _isEditing ? (val) => setState(() => _selectedGender = val) : null,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              if (auth.role == 'police') ...[
                _buildSectionHeader('Police Details'),
                const SizedBox(height: 16),
                _buildReadOnlyField(
                  label: 'State',
                  value: 'Andhra Pradesh',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                _buildPicker(
                  label: localizations.rank,
                  value: _selectedRank,
                  icon: Icons.military_tech,
                  onTap: () {
                    _openSearchableDropdown(
                      title: localizations.selectRank,
                      items: _ranks,
                      selectedValue: _selectedRank,
                      onSelected: (v) => setState(() {
                        _selectedRank = v;
                        _selectedRange = null;
                        _selectedDistrict = null;
                        _selectedStation = null;
                      }),
                    );
                  },
                ),
                if (_shouldShowRange()) ...[
                  const SizedBox(height: 16),
                  _buildPicker(
                    label: 'Range (Zone)',
                    value: _selectedRange,
                    icon: Icons.location_city,
                    onTap: () {
                      _openSearchableDropdown(
                        title: 'Select Range',
                        items: _getAvailableRanges(),
                        selectedValue: _selectedRange,
                        onSelected: (v) => setState(() {
                          _selectedRange = v;
                          _selectedDistrict = null;
                          _selectedStation = null;
                        }),
                      );
                    },
                  ),
                ],
                if (_shouldShowDistrict()) ...[
                  const SizedBox(height: 16),
                  _buildPicker(
                    label: localizations.district,
                    value: _selectedDistrict,
                    icon: Icons.map,
                    onTap: () {
                      _openSearchableDropdown(
                        title: localizations.selectDistrict,
                        items: _getAvailableDistricts(),
                        selectedValue: _selectedDistrict,
                        onSelected: (v) => setState(() {
                          _selectedDistrict = v;
                          _selectedStation = null;
                        }),
                      );
                    },
                  ),
                ],
                if (_shouldShowStation()) ...[
                  const SizedBox(height: 16),
                  _buildPicker(
                    label: localizations.policeStation,
                    value: _selectedStation,
                    icon: Icons.local_police,
                    onTap: () {
                      _openSearchableDropdown(
                        title: localizations.selectPoliceStationText,
                        items: _getAvailableStations(),
                        selectedValue: _selectedStation,
                        onSelected: (v) => setState(() => _selectedStation = v),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
              ],

              if (auth.role != 'police') ...[
                _buildSectionHeader(localizations.address ?? 'Address'),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _houseNoController,
                  enabled: _isEditing,
                  decoration: _inputDecoration(localizations.houseNo ?? 'House No', icon: Icons.home),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _addressController,
                  enabled: _isEditing,
                  maxLines: 2,
                  decoration: _inputDecoration(localizations.streetVillage ?? 'Street / Area', icon: Icons.map),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _districtController,
                        enabled: _isEditing,
                        decoration: _inputDecoration(localizations.district ?? 'District', icon: Icons.location_city),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _pincodeController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(localizations.pincode ?? 'Pincode', icon: Icons.pin_drop),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),

              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Reset fields
                           setState(() {
                             _isEditing = false;
                             // Reload original values
                             final u = auth.userProfile;
                             _displayNameController.text = u?.displayName ?? '';
                             _phoneController.text = u?.phoneNumber ?? '';
                             _aadharController.text = u?.aadharNumber ?? '';
                             _selectedRank = u?.rank;
                             _selectedRange = u?.range;
                             _selectedDistrict = u?.district;
                             _selectedStation = u?.stationName;
                             _selectedGender = u?.gender;
                             // ... reset others 
                           });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: Text(localizations.cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: Colors.white,
                        ),
                        child: auth.isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : Text(localizations.save ?? 'Save'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.orange.shade800,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return InputDecorator(
      decoration: _inputDecoration(label, icon: icon).copyWith(
        fillColor: Colors.grey.shade100,
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildPicker({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isEditing ? onTap : null,
      child: InputDecorator(
        decoration: _inputDecoration(label, icon: icon).copyWith(
          suffixIcon: _isEditing ? const Icon(Icons.arrow_drop_down) : null,
        ),
        child: Text(
          value ?? 'Select $label',
          style: TextStyle(
            fontSize: 16,
            color: value == null ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }
}
