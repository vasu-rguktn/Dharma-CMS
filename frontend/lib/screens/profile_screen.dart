import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userProfile;

    _displayNameController =
        TextEditingController(text: user?.displayName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _aadharController = TextEditingController(text: user?.aadharNumber ?? '');
    _dobController = TextEditingController(text: user?.dob ?? '');
    _houseNoController = TextEditingController(text: user?.houseNo ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _districtController = TextEditingController(text: user?.district ?? '');
    _pincodeController = TextEditingController(text: user?.pincode ?? '');

    _selectedGender = user?.gender;
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
        district: _districtController.text.trim(),
        pincode: _pincodeController.text.trim(),
        gender: _selectedGender,
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

    if (auth.isProfileLoading) {
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
                        (user?.displayName ?? user?.email ?? 'U')[0]
                            .toUpperCase(),
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
                          child: Icon(Icons.camera_alt,
                              color: Colors.orange.shade800, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Fields
              _buildSectionHeader(
                  localizations.basicInformation ?? 'Basic Information'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _displayNameController,
                enabled: _isEditing,
                decoration: _inputDecoration(
                    localizations.fullName ?? 'Full Name',
                    icon: Icons.person),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                    '${localizations.mobileNumber} (Optional)',
                    icon: Icons.phone),
                validator: (val) {
                  final trimmed = val?.trim() ?? '';
                  if (trimmed.isNotEmpty && trimmed.length < 10) {
                    return 'Invalid Number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _aadharController,
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                maxLength: 12,
                decoration:
                    _inputDecoration('Aadhar Number', icon: Icons.fingerprint)
                        .copyWith(counterText: ""),
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.length != 12) {
                    return 'Must be 12 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dobController,
                      enabled: _isEditing,
                      readOnly: true,
                      decoration: _inputDecoration(
                          localizations.dateOfBirth ??
                              'Date of Birth (Optional)',
                          icon: Icons.calendar_today),
                      onTap: _isEditing
                          ? () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                _dobController.text =
                                    "${date.day}/${date.month}/${date.year}";
                              }
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: _inputDecoration(
                          localizations.gender ?? 'Gender',
                          icon: Icons.people),
                      items: ['Male', 'Female', 'Other']
                          .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: _isEditing
                          ? (val) => setState(() => _selectedGender = val)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionHeader(localizations.address ?? 'Address'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _houseNoController,
                enabled: _isEditing,
                decoration: _inputDecoration(
                    localizations.houseNo ?? 'House No',
                    icon: Icons.home),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                enabled: _isEditing,
                maxLines: 2,
                decoration: _inputDecoration(
                    localizations.streetVillage ?? 'Street / Area',
                    icon: Icons.map),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      enabled: _isEditing,
                      decoration: _inputDecoration(
                          localizations.district ?? 'District',
                          icon: Icons.location_city),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                          localizations.pincode ?? 'Pincode (Optional)',
                          icon: Icons.pin_drop),
                      validator: (val) {
                        final trimmed = val?.trim() ?? '';
                        if (trimmed.isNotEmpty && trimmed.length != 6) {
                          return 'Must be 6 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
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
                            // ... reset others if strictly needed, or just pop
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
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
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
}
