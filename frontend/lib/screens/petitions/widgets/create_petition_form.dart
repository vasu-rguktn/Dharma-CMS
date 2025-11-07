// lib/screens/petitions/widgets/create_petition_form.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/services/local_storage_service.dart';
import './ocr_service.dart';

class CreatePetitionForm extends StatefulWidget {
  final VoidCallback? onCreatedSuccess;
  const CreatePetitionForm({super.key, this.onCreatedSuccess});

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
  final _prayer = TextEditingController();

  bool _submitting = false;
  List<PlatformFile> _files = [];
  bool _extracting = false;
  String? _extractedText;
  final _ocr = OcrService();

  @override
  void initState() {
    super.initState();
    _ocr.init();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<PetitionProvider>(context, listen: false);

    if (_extractedText == null && _files.isNotEmpty) {
      try { _extractedText = await _ocr.extractText(_files.first); } catch (_) {}
    }

    final p = Petition(
      title: _title.text,
      type: PetitionType.other,
      status: PetitionStatus.draft,
      petitionerName: _name.text,
      phoneNumber: _phone.text,
      address: _address.text,
      grounds: _grounds.text,
      prayerRelief: _prayer.text.isEmpty ? null : _prayer.text,
      extractedText: _extractedText,
      userId: auth.user!.uid,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    try {
      if (_files.isNotEmpty) {
        final folder = _title.text.isEmpty ? 'petition_${DateTime.now().millisecondsSinceEpoch}' : _title.text;
        await LocalStorageService.savePickedFiles(files: _files, subfolderName: folder);
      }
    } catch (_) {}

    final ok = await provider.createPetition(p);
    setState(() => _submitting = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Created!'), backgroundColor: Colors.green));
      _formKey.currentState!.reset();
      _title.clear(); _name.clear(); _phone.clear(); _address.clear(); _grounds.clear(); _prayer.clear();
      setState(() => _files = []);
      await provider.fetchPetitions(auth.user!.uid);
      widget.onCreatedSuccess?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed'), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickAndOcr() async {
    final res = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true, type: FileType.image);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _files = res.files);
      setState(() => _extracting = true);
      try {
        _extractedText = await _ocr.extractText(res.files.first);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OCR failed: $e')));
      } finally {
        if (mounted) setState(() => _extracting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basic Information', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Petition Title *', border: OutlineInputBorder()), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Your Name *', border: OutlineInputBorder()), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number *', border: OutlineInputBorder()), validator: (v) => v == null || !RegExp(r'^\d{10}$').hasMatch(v) ? '10 digits' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _address, maxLines: 3, decoration: const InputDecoration(labelText: 'Address *', border: OutlineInputBorder()), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Petition Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(controller: _grounds, maxLines: 8, decoration: const InputDecoration(labelText: 'Grounds / Reasons *', border: OutlineInputBorder()), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _prayer, maxLines: 5, decoration: const InputDecoration(labelText: 'Prayer / Relief (Optional)', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    Text('Supporting Documents', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        ElevatedButton.icon(icon: const Icon(Icons.upload_file), label: const Text('Upload'), onPressed: _submitting ? null : _pickAndOcr),
                        if (_files.isNotEmpty) Text('${_files.length} file(s)'),
                        if (_extracting) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    if (_files.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _files.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, i) {
                            final f = _files[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.insert_drive_file),
                              title: Text(f.name, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
                              trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _files.removeAt(i))),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_extractedText != null) ...[
                      const SizedBox(height: 16),
                      const Text('Extracted Text', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                        child: Text(_extractedText!, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Petition'),
            ),
          ],
        ),
      ),
    );
  }
}