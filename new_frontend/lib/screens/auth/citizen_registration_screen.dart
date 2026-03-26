import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dharma/l10n/app_localizations.dart';
import 'package:dharma/utils/validators.dart';

class CitizenRegistrationScreen extends StatefulWidget {
  const CitizenRegistrationScreen({super.key});
  @override
  State<CitizenRegistrationScreen> createState() => _CitizenRegistrationScreenState();
}

class _CitizenRegistrationScreenState extends State<CitizenRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  String _gender = 'Male';

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
    if (picked != null) setState(() => _dob.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.go('/address', extra: {
        'personal': {'name': _name.text.trim(), 'email': _email.text.trim(), 'phone': _phone.text.trim(), 'dob': _dob.text.trim(), 'gender': _gender},
        'userType': 'citizen',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(      appBar: AppBar(title: const Text('Citizen Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(controller: _name, decoration: InputDecoration(labelText: l.fullName), validator: (v) => Validators.isValidName(v ?? '') ? null : 'Invalid name'),
            const SizedBox(height: 16),
            TextFormField(controller: _email, decoration: InputDecoration(labelText: l.email), keyboardType: TextInputType.emailAddress, validator: (v) => Validators.isValidEmail(v ?? '') ? null : 'Invalid email'),
            const SizedBox(height: 16),
            TextFormField(controller: _phone, decoration: InputDecoration(labelText: l.mobileNumber, prefixText: '+91 '), keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextFormField(controller: _dob, decoration: InputDecoration(labelText: l.dateOfBirth, suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _selectDate)), readOnly: true, onTap: _selectDate),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(value: _gender, items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => _gender = v ?? 'Male'), decoration: InputDecoration(labelText: l.gender)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _submit, child: Text(l.next)),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() { _name.dispose(); _email.dispose(); _phone.dispose(); _dob.dispose(); super.dispose(); }
}
