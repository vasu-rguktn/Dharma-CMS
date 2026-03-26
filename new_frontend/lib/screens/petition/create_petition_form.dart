import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dharma/providers/auth_provider.dart';
import 'package:dharma/providers/petition_provider.dart';
import 'package:dharma/models/petition.dart';
import 'package:dharma/l10n/app_localizations.dart';

class CreatePetitionForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const CreatePetitionForm({super.key, this.initialData});
  @override
  State<CreatePetitionForm> createState() => _CreatePetitionFormState();
}

class _CreatePetitionFormState extends State<CreatePetitionForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _grounds = TextEditingController();
  final _incidentAddress = TextEditingController();
  final _district = TextEditingController();
  final _stationName = TextEditingController();
  bool _isLoading = false;
  bool _isAnonymous = false;
  static const Color orange = Color(0xFFFC633C);

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    if (d != null) {
      _name.text = d['petitionerName'] ?? '';
      _phone.text = d['phoneNumber'] ?? '';
      _address.text = d['address'] ?? '';
      _grounds.text = d['grounds'] ?? '';
      _title.text = d['type'] ?? d['complaint_type'] ?? 'Complaint';
      _isAnonymous = d['isAnonymous'] == true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profile = auth.userProfile;
      if (profile != null && _name.text.isEmpty) {
        _name.text = profile.displayName ?? '';
        _phone.text = profile.phoneNumber ?? '';
        _address.text = profile.address ?? '';
        _district.text = profile.district ?? '';
        _stationName.text = profile.stationName ?? '';
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<PetitionProvider>(context, listen: false);
      final uid = auth.user?.uid ?? '';
      final now = DateTime.now();
      final petition = Petition(
        title: _title.text.trim(),
        petitionerName: _isAnonymous ? 'Anonymous' : _name.text.trim(),
        phoneNumber: _phone.text.trim(),
        address: _address.text.trim(),
        grounds: _grounds.text.trim(),
        incidentAddress: _incidentAddress.text.trim(),
        district: _district.text.trim(),
        stationName: _stationName.text.trim(),
        userId: uid,
        isAnonymous: _isAnonymous,
        createdAt: now,
        updatedAt: now,
      );
      final result = await provider.createPetition(petition: petition);
      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Petition created successfully!'), backgroundColor: Colors.green),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create petition'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.createPetition)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                title: const Text('Submit Anonymously'),
                subtitle: const Text('Your identity will be hidden'),
                value: _isAnonymous,
                activeColor: orange,
                onChanged: (v) => setState(() => _isAnonymous = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Petition Title *'),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              if (!_isAnonymous) ...[
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: '${l.fullName} *'),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  decoration: InputDecoration(labelText: l.mobileNumber),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(labelText: l.address),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _grounds,
                decoration: const InputDecoration(labelText: 'Complaint Details / Grounds *'),
                maxLines: 5,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _incidentAddress,
                decoration: const InputDecoration(labelText: 'Incident Address'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _district,
                decoration: InputDecoration(labelText: l.district),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stationName,
                decoration: const InputDecoration(labelText: 'Police Station'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l.submit,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _grounds.dispose();
    _incidentAddress.dispose();
    _district.dispose();
    _stationName.dispose();
    super.dispose();
  }
}
