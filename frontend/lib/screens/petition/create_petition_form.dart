import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/services/local_storage_service.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';

import 'dart:convert';

import 'package:flutter/services.dart';

import 'ocr_service.dart';

class CreatePetitionForm extends StatefulWidget {
  final VoidCallback? onCreatedSuccess;
  // Add new parameter for initial data
  final Map<String, dynamic>? initialData;

  const CreatePetitionForm({
    super.key,
    this.onCreatedSuccess,
    this.initialData,
  });

  @override
  State<CreatePetitionForm> createState() => _CreatePetitionFormState();
}

class _CreatePetitionFormState extends State<CreatePetitionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _petitionerNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _groundsController = TextEditingController();
  final _prayerReliefController = TextEditingController();
  final _districtController = TextEditingController();
  final _stationController = TextEditingController();

  // INCIDENT DETAILS
  final _incidentAddressController = TextEditingController();
  DateTime? _incidentDate;

// District & Police Station
  String? _selectedDistrict;
  String? _selectedStation;

  bool _isSubmitting = false;
  Map<String, List<String>> _districtStations = {};
  bool _dataLoading = true;

  List<PlatformFile> _pickedFiles = []; // Handwritten documents
  List<PlatformFile> _proofFiles = []; // Related proof documents

  final _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    _ocrService.init();
    _loadDistrictStations();

    final data = widget.initialData;
    if (data != null) {
      _titleController.text = data['complaintType']?.toString() ?? '';
      _petitionerNameController.text = data['fullName']?.toString() ?? '';
      _phoneNumberController.text = data['phone']?.toString() ?? '';
      _addressController.text = data['address']?.toString() ?? '';
      // Map Narrative to Grounds
      _groundsController.text = data['incident_details']?.toString() ??
          data['details']?.toString() ??
          '';
      // Map Incident Address
      _incidentAddressController.text =
          data['incident_address']?.toString() ?? '';
    }
  }

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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filtered = items
                              .where((e) =>
                                  e.toLowerCase().contains(value.toLowerCase()))
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
                          trailing: item == selectedValue
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
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
    _titleController.dispose();
    _petitionerNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _groundsController.dispose();
    _prayerReliefController.dispose();
    _incidentAddressController.dispose();
    _districtController.dispose();
    _stationController.dispose();

    super.dispose();
  }

  Future<void> _submitPetition() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final petitionProvider =
        Provider.of<PetitionProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    String? extractedText;
    if (_pickedFiles.isNotEmpty && _ocrService.result == null) {
      await _ocrService.runOcr(_pickedFiles.first);
    }
    extractedText = _ocrService.result?['text']?.trim().isNotEmpty == true
        ? _ocrService.result!['text']
        : null;

    final petition = Petition(
      title: _titleController.text,
      type: PetitionType.other,
      status: PetitionStatus.draft,
      petitionerName: _petitionerNameController.text,
      phoneNumber: _phoneNumberController.text,
      address: _addressController.text,
      grounds: _groundsController.text,

      // ✅ NEW FIELDS
      incidentAddress: _incidentAddressController.text,
      incidentDate:
          _incidentDate == null ? null : Timestamp.fromDate(_incidentDate!),
      district: _districtController.text.trim().isEmpty
          ? null
          : _districtController.text.trim(),
      stationName: _stationController.text.trim().isEmpty
          ? null
          : _stationController.text.trim(),

      prayerRelief: _prayerReliefController.text.isEmpty
          ? null
          : _prayerReliefController.text,
      extractedText: extractedText,
      userId: authProvider.user!.uid,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    // Save files locally (optional, for offline access or caching)
    if (_pickedFiles.isNotEmpty) {
      final folder = _titleController.text.isNotEmpty
          ? _titleController.text
          : 'petition_${DateTime.now().millisecondsSinceEpoch}';
      try {
        await LocalStorageService.savePickedFiles(
            files: _pickedFiles, subfolderName: folder);
      } catch (_) {}
    }

    // Use the updated createPetition method with named arguments
    final success = await petitionProvider.createPetition(
      petition: petition,
      handwrittenFile: _pickedFiles.isNotEmpty ? _pickedFiles.first : null,
      proofFiles: _proofFiles,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations.petitionCreatedSuccessfully),
            backgroundColor: Colors.green),
      );

      // call optional callback (keeps existing behavior for callers)
      widget.onCreatedSuccess?.call();

      // reset local form state
      _resetForm();

      // refresh list and then navigate back to petitions list
      await petitionProvider.fetchPetitions(authProvider.user!.uid);

      if (!mounted) return;

      GoRouter.of(context).go('/petitions'); // navigate back to petitions list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations.failedToCreatePetition),
            backgroundColor: Colors.red),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();

    _titleController.clear();
    _petitionerNameController.clear();
    _phoneNumberController.clear();
    _addressController.clear();
    _groundsController.clear();
    _prayerReliefController.clear();

    // ✅ NEW FIELDS RESET
    _incidentAddressController.clear();
    _districtController.clear();
    _stationController.clear();
    _incidentDate = null;
    _selectedDistrict = null;
    _selectedStation = null;

    setState(() {
      _pickedFiles = [];
      _proofFiles = [];
      _ocrService.clearResult();
    });
  }

  Future<void> _pickAndOcr() async {
    final localizations = AppLocalizations.of(context)!;
    // open file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    // update picked files immediately so UI shows upload
    setState(() {
      _pickedFiles = [file];
    });

    try {
      // run OCR and await completion
      await _ocrService.runOcr(file);

      // when extraction completes, update UI immediately
      final r = _ocrService.result;
      if (r != null && r['text'] != null) {
        final extracted = r['text'].toString().trim();
        if (extracted.isNotEmpty) {
          setState(() {
            final current = _groundsController.text.trim();

            // If the field is empty → fill it
            if (current.isEmpty) {
              _groundsController.text = extracted;
            } else {
              // If not empty → combine existing and extracted text cleanly
              if (!current.contains(extracted)) {
                _groundsController.text = '$current $extracted'.trim();
              }
            }
          });
        }
      } else {
        // extraction returned no text
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localizations.noTextExtracted)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.ocrFailed(e.toString()))),
        );
      }
    }
  }

  Widget _buildOcrSummary(ThemeData theme) {
    final localizations = AppLocalizations.of(context)!;
    final text = _ocrService.result?['text'] as String? ?? '';
    if (text.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.extractedText,
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(text, style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIncidentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _incidentDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === BASIC INFO ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.basicInformation,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                          labelText: localizations.petitionTypeLabel,
                          border: const OutlineInputBorder()),
                      validator: (v) =>
                          v?.isEmpty ?? true ? localizations.required : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _petitionerNameController,
                      decoration: InputDecoration(
                          labelText: localizations.yourNameLabel,
                          border: const OutlineInputBorder()),
                      validator: (v) =>
                          v?.isEmpty ?? true ? localizations.required : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: localizations.phoneNumberLabel,
                          border: const OutlineInputBorder()),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return localizations.required;
                        if (!RegExp(r'^\d{10}$').hasMatch(v))
                          return localizations.enterTenDigitNumber;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                          labelText: localizations.addressLabel,
                          border: const OutlineInputBorder()),
                      validator: (v) =>
                          v?.isEmpty ?? true ? localizations.required : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

// === INCIDENT DETAILS ===
// === INCIDENT & JURISDICTION DETAILS ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= INCIDENT DETAILS =================
                    Text(
                      'Incident Details',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Incident Address
                    TextFormField(
                      controller: _incidentAddressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Incident Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter incident address'
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Incident Date
                    InkWell(
                      onTap: _pickIncidentDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Incident Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _incidentDate == null
                              ? 'Select date'
                              : _incidentDate!
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ================= JURISDICTION DETAILS =================
                    Text(
                      'Jurisdiction for Filing Complaint',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // District
                    _picker(
                      label: 'District',
                      value: _districtController.text.isEmpty
                          ? null
                          : _districtController.text,
                      onTap: () {
                        _openSearchableDropdown(
                          title: 'Select District',
                          items: _districtStations.keys.toList(),
                          selectedValue: _districtController.text,
                          onSelected: (v) {
                            setState(() {
                              _districtController.text = v;
                              _stationController.clear();
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // Police Station
                    _picker(
                      label: 'Police Station',
                      value: _stationController.text.isEmpty
                          ? null
                          : _stationController.text,
                      onTap: _districtController.text.isEmpty
                          ? null
                          : () {
                              _openSearchableDropdown(
                                title: 'Select Police Station',
                                items: _districtStations[
                                        _districtController.text] ??
                                    [],
                                selectedValue: _stationController.text,
                                onSelected: (v) {
                                  setState(() => _stationController.text = v);
                                },
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),

            // === PETITION DETAILS ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.petitionDetails,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _groundsController,
                      maxLines: 8,
                      decoration: InputDecoration(
                          labelText: localizations.groundsReasonsLabel,
                          border: const OutlineInputBorder()),
                      validator: (v) =>
                          v?.isEmpty ?? true ? localizations.required : null,
                    ),
                    const SizedBox(height: 16),

                    // === HANDWRITTEN DOCUMENTS ===
                    Text(localizations.handwrittenDocuments,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: Text(localizations.uploadDocuments),
                          onPressed: _isSubmitting ? null : _pickAndOcr,
                        ),
                        if (_pickedFiles.isNotEmpty)
                          Text(localizations.filesCount(_pickedFiles.length)),
                        if (_ocrService.isExtracting)
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    if (_pickedFiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8)),
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _pickedFiles.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final f = _pickedFiles[i];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.insert_drive_file),
                              title:
                                  Text(f.name, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  '${(f.size / 1024).toStringAsFixed(1)} KB'),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => setState(
                                        () => _pickedFiles.removeAt(i)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_ocrService.result != null) ...[
                      const SizedBox(height: 16),
                      _buildOcrSummary(theme),
                    ],

                    const SizedBox(height: 24),

                    // === RELATED DOCUMENT PROOFS ===
                    Text(
                      'Related Document Proofs (Optional)',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Proofs'),
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    withData: true,
                                    type: FileType.any,
                                  );
                                  if (result != null &&
                                      result.files.isNotEmpty) {
                                    setState(() {
                                      _proofFiles.addAll(result.files);
                                    });
                                  }
                                },
                        ),
                        if (_proofFiles.isNotEmpty)
                          Text('${_proofFiles.length} file(s) selected'),
                      ],
                    ),
                    if (_proofFiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _proofFiles.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final f = _proofFiles[index];
                            return ListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              leading: const Icon(Icons.attach_file),
                              title:
                                  Text(f.name, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                  '${(f.size / 1024).toStringAsFixed(1)} KB'),
                              trailing: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                                icon: const Icon(Icons.close),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => setState(
                                        () => _proofFiles.removeAt(index)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPetition,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(localizations.createPetition,
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
