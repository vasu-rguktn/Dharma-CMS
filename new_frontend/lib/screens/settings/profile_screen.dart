import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma/providers/auth_provider.dart';
import 'package:dharma/l10n/app_localizations.dart';
import 'package:dharma/utils/validators.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color orange = Color(0xFFFC633C);

  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _houseNoCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _aadharCtrl;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().userProfile;
    _nameCtrl = TextEditingController(text: profile?.displayName ?? '');
    _emailCtrl = TextEditingController(text: profile?.email ?? '');
    _phoneCtrl = TextEditingController(text: profile?.phoneNumber ?? '');
    _usernameCtrl = TextEditingController(text: profile?.username ?? '');
    _dobCtrl = TextEditingController(text: profile?.dob ?? '');
    _houseNoCtrl = TextEditingController(text: profile?.houseNo ?? '');
    _addressCtrl = TextEditingController(text: profile?.address ?? '');
    _districtCtrl = TextEditingController(text: profile?.district ?? '');
    _pincodeCtrl = TextEditingController(text: profile?.pincode ?? '');
    _aadharCtrl = TextEditingController(text: profile?.aadharNumber ?? '');
    _selectedGender = profile?.gender;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _dobCtrl.dispose();
    _houseNoCtrl.dispose();
    _addressCtrl.dispose();
    _districtCtrl.dispose();
    _pincodeCtrl.dispose();
    _aadharCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.updateUserProfile(
        uid: auth.user!.uid,
        displayName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        dob: _dobCtrl.text.trim(),
        gender: _selectedGender,
        houseNo: _houseNoCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        aadharNumber: _aadharCtrl.text.trim(),
      );
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dobCtrl.text) ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      _dobCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.userProfile;
    final l = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/settings');
                  }
                },
              ),
              const SizedBox(width: 8),
              Text(
                l.viewProfile,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit, color: orange),
                  label: const Text('Edit', style: TextStyle(color: orange)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Avatar card
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: orange,
                  child: Text(
                    (profile?.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile?.displayName ?? 'User',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (profile?.email != null && profile!.email.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(profile.email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  ),
                if (profile?.role != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: Text(profile!.role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: orange,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form
          if (_isEditing) ...[
            _buildEditForm(l),
          ] else ...[
            _buildReadOnlyProfile(profile, l),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyProfile(dynamic profile, AppLocalizations l) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.profileInformation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _readOnlyRow(Icons.person, l.fullName, profile?.displayName ?? '-'),
            _readOnlyRow(Icons.email, l.email, profile?.email ?? '-'),
            _readOnlyRow(Icons.phone, l.phone, profile?.phoneNumber ?? '-'),
            _readOnlyRow(Icons.alternate_email, 'Username', profile?.username ?? '-'),
            _readOnlyRow(Icons.cake, 'Date of Birth', profile?.dob ?? '-'),
            _readOnlyRow(Icons.wc, 'Gender', profile?.gender ?? '-'),
            const Divider(height: 24),            Text(l.addressDetails, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _readOnlyRow(Icons.home, 'House No.', profile?.houseNo ?? '-'),
            _readOnlyRow(Icons.location_on, 'Address', profile?.address ?? '-'),
            _readOnlyRow(Icons.location_city, 'District', profile?.district ?? '-'),
            _readOnlyRow(Icons.pin, 'Pincode', profile?.pincode ?? '-'),
            const Divider(height: 24),
            _readOnlyRow(Icons.badge, 'Aadhar Number', _maskAadhar(profile?.aadharNumber)),
            _readOnlyRow(Icons.calendar_today, 'Member Since', _formatDate(profile?.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(AppLocalizations l) {
    return Form(
      key: _formKey,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.profileInformation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 24),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: l.fullName, prefixIcon: const Icon(Icons.person)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : (!Validators.isValidName(v.trim()) ? 'Enter a valid name' : null),
              ),
              const SizedBox(height: 16),

              // Email (read-only)
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: l.email, prefixIcon: const Icon(Icons.email)),
                readOnly: true,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: l.phone, prefixIcon: const Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email)),
              ),
              const SizedBox(height: 16),

              // DOB
              TextFormField(
                controller: _dobCtrl,
                decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.cake)),
                readOnly: true,
                onTap: _isEditing ? _pickDate : null,
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc)),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                  DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v),
              ),
              const SizedBox(height: 24),

              // Address Section
              Text(l.addressDetails, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              TextFormField(
                controller: _houseNoCtrl,
                decoration: const InputDecoration(labelText: 'House No.', prefixIcon: Icon(Icons.home)),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on)),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _districtCtrl,
                decoration: const InputDecoration(labelText: 'District', prefixIcon: Icon(Icons.location_city)),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _pincodeCtrl,
                decoration: const InputDecoration(labelText: 'Pincode', prefixIcon: Icon(Icons.pin)),
                keyboardType: TextInputType.number,
                validator: (v) => (v != null && v.trim().isNotEmpty && !Validators.isValidIndianPincode(v.trim())) ? 'Enter a valid 6-digit pincode' : null,
              ),
              const SizedBox(height: 16),

              // Aadhar
              TextFormField(
                controller: _aadharCtrl,
                decoration: const InputDecoration(labelText: 'Aadhar Number', prefixIcon: Icon(Icons.badge)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() => _isEditing = false);
                              // Reset controllers to current profile values
                              final profile = context.read<AuthProvider>().userProfile;
                              _nameCtrl.text = profile?.displayName ?? '';
                              _phoneCtrl.text = profile?.phoneNumber ?? '';
                              _usernameCtrl.text = profile?.username ?? '';
                              _dobCtrl.text = profile?.dob ?? '';
                              _houseNoCtrl.text = profile?.houseNo ?? '';
                              _addressCtrl.text = profile?.address ?? '';
                              _districtCtrl.text = profile?.district ?? '';
                              _pincodeCtrl.text = profile?.pincode ?? '';
                              _aadharCtrl.text = profile?.aadharNumber ?? '';
                              _selectedGender = profile?.gender;
                            },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white),
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save'),
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

  String _maskAadhar(String? aadhar) {
    if (aadhar == null || aadhar.isEmpty) return '-';
    if (aadhar.length <= 4) return aadhar;
    return '${'*' * (aadhar.length - 4)}${aadhar.substring(aadhar.length - 4)}';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
