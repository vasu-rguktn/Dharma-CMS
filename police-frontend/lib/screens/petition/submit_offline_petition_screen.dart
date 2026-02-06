import 'package:Dharma/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/offline_petition_provider.dart';
import 'package:Dharma/providers/police_auth_provider.dart';
import 'package:Dharma/widgets/assign_petition_dialog.dart';

class SubmitOfflinePetitionScreen extends StatefulWidget {
  final Petition? initialPetition;

  const SubmitOfflinePetitionScreen({this.initialPetition, super.key});

  @override
  State<SubmitOfflinePetitionScreen> createState() =>
      _SubmitOfflinePetitionScreenState();
}

class _SubmitOfflinePetitionScreenState
    extends State<SubmitOfflinePetitionScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialPetition != null) {
      _prefillData(widget.initialPetition!);
    }
  }

  void _prefillData(Petition petition) {
    _titleController.text = petition.title;
    _petitionerNameController.text = petition.petitionerName;
    _phoneController.text = petition.phoneNumber ?? '';
    _addressController.text = petition.address ?? '';
    _groundsController.text = petition.grounds;
    _prayerReliefController.text = petition.prayerRelief ?? '';
    _incidentAddressController.text = petition.incidentAddress ?? '';
    _firNumberController.text = petition.firNumber ?? '';
    _selectedType = petition.type;
    _incidentDate = petition.incidentDate?.toDate();
    _selectedDistrict = petition.district;
    _selectedStation = petition.stationName;
  }

  // Form controllers
  final _titleController = TextEditingController();
  final _petitionerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _groundsController = TextEditingController();
  final _prayerReliefController = TextEditingController();
  final _incidentAddressController = TextEditingController();
  final _firNumberController = TextEditingController();

  // Dropdown selections
  PetitionType _selectedType = PetitionType.other;
  DateTime? _incidentDate;
  String? _selectedDistrict;
  String? _selectedStation;

  // File attachments
  PlatformFile? _handwrittenDocument;
  List<PlatformFile> _proofDocuments = [];

  // Assignment
  bool _assignImmediately = false;
  Map<String, dynamic>? _assignmentData;

  // Loading state
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _petitionerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _groundsController.dispose();
    _prayerReliefController.dispose();
    _incidentAddressController.dispose();
    _firNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickHandwrittenDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _handwrittenDocument = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _pickProofDocuments() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _proofDocuments.addAll(result.files);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  Future<void> _submitPetition() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final policeAuthProvider = context.read<PoliceAuthProvider>();
    final policeProfile = policeAuthProvider.policeProfile;

    if (policeProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Police profile not found')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get officer details
      final officerUid = policeProfile['uid'] as String;
      final officerName = policeProfile['displayName'] as String;
      final officerRank = policeProfile['rank'] as String;
      final officerDistrict = policeProfile['district'] as String?;
      final officerStation = policeProfile['stationName'] as String?;

      // Create petition
      final petition = Petition(
        title: _titleController.text.trim(),
        type: _selectedType,
        status: PetitionStatus.filed,
        petitionerName: _petitionerNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        grounds: _groundsController.text.trim(),
        prayerRelief: _prayerReliefController.text.trim().isEmpty
            ? null
            : _prayerReliefController.text.trim(),
        incidentAddress: _incidentAddressController.text.trim().isEmpty
            ? null
            : _incidentAddressController.text.trim(),
        incidentDate: _incidentDate != null
            ? Timestamp.fromDate(_incidentDate!)
            : null,
        district: _selectedDistrict ?? officerDistrict,
        stationName: _selectedStation ?? officerStation,
        firNumber: _firNumberController.text.trim().isEmpty
            ? null
            : _firNumberController.text.trim(),
        policeStatus: 'Received',
        // ⭐ OFFLINE SUBMISSION FIELDS ⭐
        submissionType: 'offline',
        submittedBy: officerUid,
        submittedByName: officerName,
        submittedByRank: officerRank,
        // ⭐ ASSIGNMENT FIELDS (if immediate assignment) ⭐
        assignmentType: _assignmentData?['assignmentType'],
        assignedTo: _assignmentData?['assignedTo'],  // Added: officer ID if individual assignment
        assignedToName: _assignmentData?['assignedToName'],  // Added: officer name if individual
        assignedToRank: _assignmentData?['assignedToRank'],  // Added: officer rank if individual
        assignedToRange: _assignmentData?['assignedToRange'],
        assignedToDistrict: _assignmentData?['assignedToDistrict'],
        assignedToSDPO: _assignmentData?['assignedToSDPO'], // ✅ NEW
        assignedToCircle: _assignmentData?['assignedToCircle'], // ✅ NEW
        assignedToStation: _assignmentData?['assignedToStation'],
        // ⭐ ALWAYS SET assignedBy to the submitting officer ⭐
        assignedBy: officerUid,
        assignedByName: officerName,
        assignedByRank: officerRank,
        assignedAt: _assignImmediately ? Timestamp.now() : null,
        assignmentStatus: _assignImmediately ? 'pending' : null,
        userId: officerUid, // For offline, userId is the submitting officer
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // ✅ Submit petition using OfflinePetitionProvider
      final offlinePetitionProvider = context.read<OfflinePetitionProvider>();
      final petitionId = await offlinePetitionProvider.submitOfflinePetition(
        petition: petition,
        handwrittenFile: _handwrittenDocument,
        proofFiles: _proofDocuments.isEmpty ? null : _proofDocuments,
      );

      if (mounted && petitionId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _assignImmediately
                  ? 'Offline petition submitted and assigned successfully!'
                  : 'Offline petition submitted successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else if (mounted) {
        throw Exception('Failed to submit petition');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting petition: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _getAssignmentLabel() {
    if (_assignmentData == null) return 'Not selected';
    final type = _assignmentData!['assignmentType'];
    if (type == 'range') {
      return 'Range: ${_assignmentData!['assignedToRange'] ?? 'Unknown'}';
    } else if (type == 'district') {
      return 'District: ${_assignmentData!['assignedToDistrict'] ?? 'Unknown'}';
    } else if (type == 'sdpo') { // ✅ NEW
      return 'SDPO: ${_assignmentData!['assignedToSDPO'] ?? 'Unknown'}';
    } else if (type == 'circle') { // ✅ NEW
      return 'Circle: ${_assignmentData!['assignedToCircle'] ?? 'Unknown'}';
    } else if (type == 'station') {
      return 'Station: ${_assignmentData!['assignedToStation'] ?? 'Unknown'}';
    }
    return 'Unknown assignment';
  }

  String _getAssignmentSubtitle() {
    if (_assignmentData == null) return '';
    final type = _assignmentData!['assignmentType'];
    if (type == 'range') {
      return 'Assigned to IG/DIG of this range';
    } else if (type == 'district') {
      return 'Assigned to SP of this district';
    } else if (type == 'sdpo') { // ✅ NEW
      return 'Assigned to DSP of this SDPO';
    } else if (type == 'circle') { // ✅ NEW
      return 'Assigned to Circle Inspector';
    } else if (type == 'station') {
      return 'Assigned to SHO of this station';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final policeProfile =
        context.watch<PoliceAuthProvider>().policeProfile;
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Offline Petition'),
        elevation: 0,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting petition...'),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info banner
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Submit offline petitions received from citizens via documents, images, or text.',
                              style: TextStyle(color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Petition Details
                  Text(
                    'Petition Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Petition Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter petition title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<PetitionType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Petition Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: PetitionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section: Petitioner Information
                  Text(
                    'Petitioner Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _petitionerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Petitioner Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter petitioner name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Section: Incident Details
                  Text(
                    localizations.incidentDetails,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _incidentAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Incident Address (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    title: Text(
                      _incidentDate == null
                          ? 'Incident Date (Optional)'
                          : 'Incident Date: ${_incidentDate!.day}/${_incidentDate!.month}/${_incidentDate!.year}',
                    ),
                    leading: const Icon(Icons.calendar_today),
                    trailing: _incidentDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _incidentDate = null;
                              });
                            },
                          )
                        : null,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _incidentDate = date;
                        });
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _firNumberController,
                    decoration: const InputDecoration(
                      labelText: 'FIR Number (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Complaint Description
                  Text(
                    'Complaint Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _groundsController,
                    decoration: const InputDecoration(
                      labelText: 'Grounds / Details',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter complaint details';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _prayerReliefController,
                    decoration: const InputDecoration(
                      labelText: 'Prayer / Relief Sought (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.request_page),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Section: Document Attachments
                  Text(
                    'Document Attachments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Handwritten Document
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: Text(_handwrittenDocument == null
                          ? 'Upload Handwritten Complaint'
                          : _handwrittenDocument!.name),
                      subtitle: const Text('PDF, JPG, PNG'),
                      trailing: _handwrittenDocument != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _handwrittenDocument = null;
                                });
                              },
                            )
                          : const Icon(Icons.add),
                      onTap: _pickHandwrittenDocument,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Proof Documents
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.attach_file),
                          title: Text(_proofDocuments.isEmpty
                              ? 'Add Proof Documents'
                              : '${_proofDocuments.length} file(s) selected'),
                          subtitle: const Text('PDF, JPG, PNG (Multiple)'),
                          trailing: const Icon(Icons.add),
                          onTap: _pickProofDocuments,
                        ),
                        if (_proofDocuments.isNotEmpty) ...[
                          const Divider(),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _proofDocuments.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.insert_drive_file,
                                    size: 20),
                                title: Text(
                                  _proofDocuments[index].name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _proofDocuments.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Assignment
                  Text(
                    'Assignment (Optional)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Assign to officer immediately'),
                    subtitle: const Text(
                        'Assign this petition to a lower-level officer'),
                    value: _assignImmediately,
                    onChanged: (value) {
                      setState(() {
                        _assignImmediately = value;
                      });
                    },
                  ),

                  if (_assignImmediately) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.assignment),
                        title: Text(_assignmentData == null
                            ? 'Select Assignment Target'
                            : _getAssignmentLabel()),
                        subtitle: _assignmentData == null
                            ? const Text('Assign to Range, District, or Station')
                            : Text(_getAssignmentSubtitle()),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final assignmentData = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => AssignPetitionDialog(
                              assigningOfficerRank: policeProfile?['rank'] ?? '',
                              range: policeProfile?['range'],
                              district: policeProfile?['district'],
                              stationName: policeProfile?['stationName'],
                            ),
                          );
                          if (assignmentData != null) {
                            setState(() {
                              _assignmentData = assignmentData;
                            });
                          }
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: _submitPetition,
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Offline Petition'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
