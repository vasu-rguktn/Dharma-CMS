import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:dharma/providers/auth_provider.dart';
import 'package:dharma/l10n/app_localizations.dart';

class AddressFormScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const AddressFormScreen({super.key, this.extra});
  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _houseNo = TextEditingController();
  final _address = TextEditingController();
  final _district = TextEditingController();
  final _pincode = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final personal = widget.extra?['personal'] as Map<String, dynamic>? ?? {};
      final uid = auth.user?.uid ?? '';

      await auth.createUserProfile(
        uid: uid,
        email: personal['email'] ?? auth.user?.email ?? '',
        displayName: personal['name'],
        phoneNumber: personal['phone'] ?? auth.user?.phoneNumber,
        dob: personal['dob'],
        gender: personal['gender'],
        houseNo: _houseNo.text.trim(),
        address: _address.text.trim(),
        district: _district.text.trim(),
        pincode: _pincode.text.trim(),
        role: 'citizen',
      );

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(      appBar: AppBar(title: Text(l.addressDetails)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(controller: _houseNo, decoration: InputDecoration(labelText: l.houseNo)),
            const SizedBox(height: 16),
            TextFormField(controller: _address, decoration: InputDecoration(labelText: l.address), maxLines: 2),
            const SizedBox(height: 16),
            TextFormField(controller: _district, decoration: InputDecoration(labelText: l.district)),
            const SizedBox(height: 16),
            TextFormField(controller: _pincode, decoration: InputDecoration(labelText: l.pincode), keyboardType: TextInputType.number),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(l.submit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() { _houseNo.dispose(); _address.dispose(); _district.dispose(); _pincode.dispose(); super.dispose(); }
}
