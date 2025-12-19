import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/models/case_doc.dart';
import 'package:Dharma/models/case_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../utils/district_translations.dart';

class _AccusedFormData {
  final name = TextEditingController();
  final fatherName = TextEditingController();
  String? gender;
  final age = TextEditingController();
  final nationality = TextEditingController(text: 'Indian');
  final caste = TextEditingController();
  final occupation = TextEditingController();
  final cellNo = TextEditingController();
  final email = TextEditingController();

  // Address
  final houseNo = TextEditingController();
  final street = TextEditingController();
  final area = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final pin = TextEditingController();

  // Physical
  final build = TextEditingController();
  final heightCms = TextEditingController();
  final complexion = TextEditingController();
  final deformities = TextEditingController();

  void dispose() {
    name.dispose();
    fatherName.dispose();
    age.dispose();
    nationality.dispose();
    caste.dispose();
    occupation.dispose();
    cellNo.dispose();
    email.dispose();
    houseNo.dispose();
    street.dispose();
    area.dispose();
    city.dispose();
    state.dispose();
    pin.dispose();
    build.dispose();
    heightCms.dispose();
    complexion.dispose();
    deformities.dispose();
  }

  Map<String, dynamic> toMap() => {
        'name': name.text,
        'fatherHusbandName': fatherName.text,
        'gender': gender,
        'age': age.text,
        'nationality': nationality.text,
        'caste': caste.text,
        'occupation': occupation.text,
        'cellNo': cellNo.text,
        'email': email.text,
        'address': [
          houseNo.text,
          street.text,
          area.text,
          city.text,
          state.text,
          pin.text,
        ].where((p) => p.trim().isNotEmpty).join(', '),
        'build': build.text,
        'heightCms': heightCms.text,
        'complexion': complexion.text,
        'deformities': deformities.text,
      };
}

class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});

  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caseIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _firNumberController = TextEditingController();
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  final _complainantNameController = TextEditingController();
  final _incidentDetailsController = TextEditingController();
  
  // Occurrence fields (Step 2)
  final _occurrenceDayController = TextEditingController();
  final _timePeriodController = TextEditingController();
  final _priorToDateTimeDetailsController = TextEditingController();
  final _beatNumberController = TextEditingController();
  final _streetVillageController = TextEditingController();
  final _areaMandalController = TextEditingController();
  
  // Location fields
  final _cityDistrictController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _distanceFromPSController = TextEditingController();
  final _directionFromPSController = TextEditingController();
  
  // Information received (Step 3)
  DateTime? _informationReceivedAtPs;
  final _generalDiaryEntryNumberController = TextEditingController();
  String? _selectedInformationType;
  
  // Complainant / Informant extra details (Step 4)
  final _fatherHusbandNameController = TextEditingController();
  String? _selectedComplainantGender;
  final _nationalityController = TextEditingController(text: 'Indian');
  final _casteController = TextEditingController();
  final _occupationController = TextEditingController();
  DateTime? _complainantDob;
  final _ageController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  // Complainant address parts
  final _complainantHouseNoController = TextEditingController();
  final _complainantStreetController = TextEditingController();
  final _complainantAreaController = TextEditingController();
  final _complainantCityController = TextEditingController();
  final _complainantStateController = TextEditingController();
  final _complainantPinController = TextEditingController();
  // Complainant passport (optional)
  final _complainantPassportNumberController = TextEditingController();
  final _complainantPassportPlaceController = TextEditingController();
  DateTime? _complainantPassportDateOfIssue;
  
  // Accused details (Step 5 - dynamic list)
  final List<_AccusedFormData> _accusedList = [];
  
  // Properties / delay / inquest (Step 6)
  final _propertiesDetailsController = TextEditingController();
  final _propertiesTotalValueController = TextEditingController();
  bool _isDelayInReporting = false;
  final _inquestReportCaseNoController = TextEditingController();
  
  // Acts & sections + victim/complaint (next step)
  final _actsAndSectionsController = TextEditingController();
  final _complaintNarrativeController = TextEditingController();
  bool? _isComplainantAlsoVictim = false;
  final _victimNameController = TextEditingController();
  String? _selectedVictimGender;
  DateTime? _victimDob;
  final _victimAgeController = TextEditingController();
  final _victimFatherNameController = TextEditingController();
  final _victimNationalityController = TextEditingController(text: 'Indian');
  final _victimReligionController = TextEditingController();
  final _victimCasteController = TextEditingController();
  final _victimOccupationController = TextEditingController();
  final _victimHouseNoController = TextEditingController();
  final _victimStreetController = TextEditingController();
  final _victimAreaController = TextEditingController();
  final _victimCityController = TextEditingController();
  final _victimStateController = TextEditingController();
  final _victimPinController = TextEditingController();
  
  // Action taken / dispatch to court (final step)
  final _actionTakenDetailsController = TextEditingController();
  final _ioNameController = TextEditingController();
  final _ioRankController = TextEditingController();
  final _ioDistrictController = TextEditingController();
  DateTime? _dispatchDateTime;
  final _dispatchOfficerNameController = TextEditingController();
  final _dispatchOfficerRankController = TextEditingController();
  
  // Confirmation (last step)
  bool? _isFirReadOverAndAdmittedCorrect = true;
  bool? _isFirCopyGivenFreeOfCost = true;
  bool? _isRoacRecorded = true;
  final _complainantSignatureNoteController = TextEditingController();
  
  bool _isOutsideJurisdiction = false;
  
  DateTime? _occurrenceDateTimeFrom;
  DateTime? _occurrenceDateTimeTo;
  
  // Dropdown values - storing English names internally for data consistency
  String? _selectedDistrict; // English name
  String? _selectedSubDivision;
  String? _selectedCircle;
  String? _selectedPoliceStation; // English name
  DateTime? _firRegistrationDate;
  
  bool _isLoading = false;
  int _currentStep = 0;
  final int _totalSteps = 9;
  
  // District list (English names - will be displayed localized)
  final List<String> _apDistrictsEnglish = [
    'Alluri Sitharama Raju',
    'Anakapalli',
    'Anantapur',
    'Annamayya',
    'Bapatla',
    'Chittoor',
    'East Godavari',
    'Eluru',
    'Guntur',
    'Kadapa',
    'Kakinada',
    'Konaseema',
    'Krishna',
    'Kurnool',
    'Manyam',
    'Nandyal',
    'NTR',
    'Palnadu',
    'Prakasam',
    'Sri Sathya Sai',
    'Srikakulam',
    'Tirupati',
    'Visakhapatnam',
    'Vizianagaram',
    'West Godavari',
  ]..sort();
  
  // Sub-Division list (example - you may need to populate based on selected district)
  final List<String> _subDivisions = [
    'Nuzvid SDPO',
    'Gudivada SDPO',
    'Machilipatnam SDPO',
    'Vijayawada SDPO',
    // Add more as needed
  ];
  
  // Circle list (example - you may need to populate based on selected sub-division)
  final List<String> _circles = [
    '-',
    'Circle 1',
    'Circle 2',
    'Circle 3',
    // Add more as needed
  ];
  
  // Police Station list - will be loaded dynamically from JSON
  List<String> _policeStationsEnglish = []; // English names

  @override
  void initState() {
    super.initState();
    // Start with one accused by default
    _accusedList.add(_AccusedFormData());
    // Load police stations when district is selected
    _loadPoliceStationsForDistrict();
  }

  Future<void> _loadPoliceStationsForDistrict() async {
    if (_selectedDistrict != null) {
      final stations = await DistrictTranslations.getPoliceStationsForDistrict(
        context,
        _selectedDistrict!,
      );
      // Stations are returned in English for storage
      setState(() {
        _policeStationsEnglish = stations;
      });
    }
  }

  /// Helper method to get localized label based on current locale
  String _getLocalizedLabel(String english, String telugu) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'te' ? telugu : english;
  }

  @override
  void dispose() {
    _caseIdController.dispose();
    _titleController.dispose();
    _firNumberController.dispose();
    _yearController.dispose();
    _complainantNameController.dispose();
    _incidentDetailsController.dispose();
    _occurrenceDayController.dispose();
    _timePeriodController.dispose();
    _priorToDateTimeDetailsController.dispose();
    _beatNumberController.dispose();
    _streetVillageController.dispose();
    _areaMandalController.dispose();
    _cityDistrictController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _distanceFromPSController.dispose();
    _directionFromPSController.dispose();
    _generalDiaryEntryNumberController.dispose();
    _fatherHusbandNameController.dispose();
    _nationalityController.dispose();
    _casteController.dispose();
    _occupationController.dispose();
    _ageController.dispose();
    _mobileNumberController.dispose();
    _complainantHouseNoController.dispose();
    _complainantStreetController.dispose();
    _complainantAreaController.dispose();
    _complainantCityController.dispose();
    _complainantStateController.dispose();
    _complainantPinController.dispose();
    _complainantPassportNumberController.dispose();
    _complainantPassportPlaceController.dispose();
    for (final a in _accusedList) {
      a.dispose();
    }
    _propertiesDetailsController.dispose();
    _propertiesTotalValueController.dispose();
    _inquestReportCaseNoController.dispose();
    _actsAndSectionsController.dispose();
    _complaintNarrativeController.dispose();
    _victimNameController.dispose();
    _victimAgeController.dispose();
    _victimFatherNameController.dispose();
    _victimNationalityController.dispose();
    _victimReligionController.dispose();
    _victimCasteController.dispose();
    _victimOccupationController.dispose();
    _victimHouseNoController.dispose();
    _victimStreetController.dispose();
    _victimAreaController.dispose();
    _victimCityController.dispose();
    _victimStateController.dispose();
    _victimPinController.dispose();
    _actionTakenDetailsController.dispose();
    _ioNameController.dispose();
    _ioRankController.dispose();
    _ioDistrictController.dispose();
    _dispatchOfficerNameController.dispose();
    _dispatchOfficerRankController.dispose();
    _complainantSignatureNoteController.dispose();
    super.dispose();
  }
  
  Future<void> _selectFirRegistrationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _firRegistrationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _firRegistrationDate) {
      setState(() {
        _firRegistrationDate = picked;
      });
    }
  }
  
  Future<void> _selectInformationReceivedAtPs() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _informationReceivedAtPs ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _informationReceivedAtPs = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
  
  Future<void> _selectOccurrenceDateTimeFrom() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _occurrenceDateTimeFrom ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _occurrenceDateTimeFrom = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  Future<void> _selectOccurrenceDateTimeTo() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _occurrenceDateTimeTo ?? (_occurrenceDateTimeFrom ?? DateTime.now()),
      firstDate: _occurrenceDateTimeFrom ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _occurrenceDateTimeTo = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  Future<void> _selectComplainantDob() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _complainantDob ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _complainantDob = pickedDate;
        // Auto-calculate age
        final now = DateTime.now();
        int age = now.year - pickedDate.year;
        if (now.month < pickedDate.month ||
            (now.month == pickedDate.month && now.day < pickedDate.day)) {
          age--;
        }
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _selectVictimDob() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _victimDob ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _victimDob = pickedDate;
        final now = DateTime.now();
        int age = now.year - pickedDate.year;
        if (now.month < pickedDate.month ||
            (now.month == pickedDate.month && now.day < pickedDate.day)) {
          age--;
        }
        _victimAgeController.text = age.toString();
      });
    }
  }

  Future<void> _selectDispatchDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dispatchDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _dispatchDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
  
  Future<void> _selectComplainantPassportDateOfIssue() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _complainantPassportDateOfIssue ?? DateTime.now().subtract(const Duration(days: 365 * 5)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _complainantPassportDateOfIssue = pickedDate;
      });
    }
  }

  void _addAccused() {
    setState(() {
      _accusedList.add(_AccusedFormData());
    });
  }

  void _removeAccused(int index) {
    if (_accusedList.length <= 1) return; // Keep at least one
    setState(() {
      final removed = _accusedList.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _submitCase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final caseProvider = Provider.of<CaseProvider>(context, listen: false);

      final newCase = CaseDoc(
        caseId: _caseIdController.text.isNotEmpty ? _caseIdController.text : null,
        title: _titleController.text,
        firNumber: _firNumberController.text,
        district: _selectedDistrict,
        policeStation: _selectedPoliceStation,
        year: _yearController.text.isNotEmpty ? _yearController.text : null,
        date: _firRegistrationDate != null 
            ? DateFormat('yyyy-MM-dd').format(_firRegistrationDate!)
            : null,
        firFiledTimestamp: _firRegistrationDate != null
            ? Timestamp.fromDate(_firRegistrationDate!)
            : null,
        complainantName: _complainantNameController.text.isNotEmpty
            ? _complainantNameController.text
            : null,
        complainantFatherHusbandName: _fatherHusbandNameController.text.isNotEmpty
            ? _fatherHusbandNameController.text
            : null,
        complainantGender: _selectedComplainantGender,
        complainantMobileNumber: _mobileNumberController.text.isNotEmpty
            ? _mobileNumberController.text
            : null,
        complainantNationality: _nationalityController.text.isNotEmpty
            ? _nationalityController.text
            : null,
        complainantCaste: _casteController.text.isNotEmpty
            ? _casteController.text
            : null,
        complainantOccupation: _occupationController.text.isNotEmpty
            ? _occupationController.text
            : null,
        complainantDob: _complainantDob != null
            ? DateFormat('yyyy-MM-dd').format(_complainantDob!)
            : null,
        complainantAge: _ageController.text.isNotEmpty
            ? _ageController.text
            : null,
        complainantAddress: [
          _complainantHouseNoController.text,
          _complainantStreetController.text,
          _complainantAreaController.text,
          _complainantCityController.text,
          _complainantStateController.text,
          _complainantPinController.text,
        ]
            .where((part) => part.trim().isNotEmpty)
            .join(', '),
        complainantPassportNumber:
            _complainantPassportNumberController.text.isNotEmpty
                ? _complainantPassportNumberController.text
                : null,
        complainantPassportPlaceOfIssue:
            _complainantPassportPlaceController.text.isNotEmpty
                ? _complainantPassportPlaceController.text
                : null,
        complainantPassportDateOfIssue:
            _complainantPassportDateOfIssue != null
                ? DateFormat('yyyy-MM-dd').format(_complainantPassportDateOfIssue!)
                : null,
        accusedPersons: _accusedList.map((a) => a.toMap()).toList(),
        incidentDetails: _incidentDetailsController.text.isNotEmpty
            ? _incidentDetailsController.text
            : null,
        occurrenceDay: _occurrenceDayController.text.isNotEmpty
            ? _occurrenceDayController.text
            : null,
        occurrenceDateTimeFrom: _occurrenceDateTimeFrom != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(_occurrenceDateTimeFrom!)
            : null,
        occurrenceDateTimeTo: _occurrenceDateTimeTo != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(_occurrenceDateTimeTo!)
            : null,
        timePeriod: _timePeriodController.text.isNotEmpty
            ? _timePeriodController.text
            : null,
        priorToDateTimeDetails: _priorToDateTimeDetailsController.text.isNotEmpty
            ? _priorToDateTimeDetailsController.text
            : null,
        beatNumber: _beatNumberController.text.isNotEmpty
            ? _beatNumberController.text
            : null,
        placeOfOccurrenceStreet: _streetVillageController.text.isNotEmpty
            ? _streetVillageController.text
            : null,
        placeOfOccurrenceArea: _areaMandalController.text.isNotEmpty
            ? _areaMandalController.text
            : null,
        placeOfOccurrenceCity: _cityDistrictController.text.isNotEmpty
            ? _cityDistrictController.text
            : null,
        placeOfOccurrenceState: _stateController.text.isNotEmpty
            ? _stateController.text
            : null,
        placeOfOccurrencePin: _pinController.text.isNotEmpty
            ? _pinController.text
            : null,
        placeOfOccurrenceLatitude: _latitudeController.text.isNotEmpty
            ? _latitudeController.text
            : null,
        placeOfOccurrenceLongitude: _longitudeController.text.isNotEmpty
            ? _longitudeController.text
            : null,
        distanceFromPS: _distanceFromPSController.text.isNotEmpty
            ? _distanceFromPSController.text
            : null,
        directionFromPS: _directionFromPSController.text.isNotEmpty
            ? _directionFromPSController.text
            : null,
        informationReceivedDateTime: _informationReceivedAtPs != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(_informationReceivedAtPs!)
            : null,
        generalDiaryEntryNumber: _generalDiaryEntryNumberController.text.isNotEmpty
            ? _generalDiaryEntryNumberController.text
            : null,
        informationType: _selectedInformationType,
        propertiesDetails: _propertiesDetailsController.text.isNotEmpty
            ? _propertiesDetailsController.text
            : null,
        propertiesTotalValueInr: _propertiesTotalValueController.text.isNotEmpty
            ? _propertiesTotalValueController.text
            : null,
        isDelayInReporting: _isDelayInReporting,
        inquestReportCaseNo: _inquestReportCaseNoController.text.isNotEmpty
            ? _inquestReportCaseNoController.text
            : null,
        actsAndSectionsInvolved: _actsAndSectionsController.text.isNotEmpty
            ? _actsAndSectionsController.text
            : null,
        complaintStatement: _complaintNarrativeController.text.isNotEmpty
            ? _complaintNarrativeController.text
            : null,
        victimName: _victimNameController.text.isNotEmpty
            ? _victimNameController.text
            : null,
        victimAge: _victimAgeController.text.isNotEmpty
            ? _victimAgeController.text
            : null,
        victimGender: _selectedVictimGender,
        victimFatherHusbandName: _victimFatherNameController.text.isNotEmpty
            ? _victimFatherNameController.text
            : null,
        victimNationality: _victimNationalityController.text.isNotEmpty
            ? _victimNationalityController.text
            : null,
        victimReligion: _victimReligionController.text.isNotEmpty
            ? _victimReligionController.text
            : null,
        victimCaste: _victimCasteController.text.isNotEmpty
            ? _victimCasteController.text
            : null,
        victimOccupation: _victimOccupationController.text.isNotEmpty
            ? _victimOccupationController.text
            : null,
        victimDob: _victimDob != null
            ? DateFormat('yyyy-MM-dd').format(_victimDob!)
            : null,
        victimAddress: [
          _victimHouseNoController.text,
          _victimStreetController.text,
          _victimAreaController.text,
          _victimCityController.text,
          _victimStateController.text,
          _victimPinController.text,
        ]
            .where((p) => p.trim().isNotEmpty)
            .join(', '),
        isComplainantAlsoVictim: _isComplainantAlsoVictim,
        actionTakenDetails: _actionTakenDetailsController.text.isNotEmpty
            ? _actionTakenDetailsController.text
            : null,
        investigatingOfficerName: _ioNameController.text.isNotEmpty
            ? _ioNameController.text
            : null,
        investigatingOfficerRank: _ioRankController.text.isNotEmpty
            ? _ioRankController.text
            : null,
        investigatingOfficerDistrict: _ioDistrictController.text.isNotEmpty
            ? _ioDistrictController.text
            : null,
        dispatchDateTime: _dispatchDateTime != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(_dispatchDateTime!)
            : null,
        dispatchOfficerName: _dispatchOfficerNameController.text.isNotEmpty
            ? _dispatchOfficerNameController.text
            : null,
        dispatchOfficerRank: _dispatchOfficerRankController.text.isNotEmpty
            ? _dispatchOfficerRankController.text
            : null,
        isFirReadOverAndAdmittedCorrect:
            _isFirReadOverAndAdmittedCorrect ?? false,
        isFirCopyGivenFreeOfCost: _isFirCopyGivenFreeOfCost ?? false,
        isRoacRecorded: _isRoacRecorded ?? false,
        complainantSignatureNote:
            _complainantSignatureNoteController.text.isNotEmpty
                ? _complainantSignatureNoteController.text
                : null,
        isOutsideJurisdiction: _isOutsideJurisdiction,
        status: CaseStatus.newCase,
        dateFiled: Timestamp.now(),
        lastUpdated: Timestamp.now(),
        userId: authProvider.userProfile?.uid,
      );

      await caseProvider.addCase(newCase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.caseCreatedSuccess)),
        );
        context.go('/cases');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorCreatingCase(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // District & FIR Details
        if (_caseIdController.text.isEmpty) {
          final locale = Localizations.localeOf(context);
          final msg = locale.languageCode == 'te'
              ? 'దయచేసి కేసు ID ను నమోదు చేయండి'
              : 'Please enter case ID';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          return false;
        }
        if (_titleController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.pleaseEnterCaseTitle),
            ),
          );
          return false;
        }
        if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a district')),
          );
          return false;
        }
        if (_selectedSubDivision == null || _selectedSubDivision!.isEmpty) {
          final locale = Localizations.localeOf(context);
          final msg = locale.languageCode == 'te' 
              ? 'దయచేసి ఉప-విభాగం (SDPO) ను ఎంచుకోండి'
              : 'Please select a Sub-Division (SDPO)';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          return false;
        }
        if (_selectedCircle == null || _selectedCircle!.isEmpty || _selectedCircle == '-') {
          final locale = Localizations.localeOf(context);
          final msg = locale.languageCode == 'te'
              ? 'దయచేసి సర్కిల్ ను ఎంచుకోండి'
              : 'Please select a Circle';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          return false;
        }
        if (_selectedPoliceStation == null || _selectedPoliceStation!.isEmpty) {
          final locale = Localizations.localeOf(context);
          final msg = locale.languageCode == 'te'
              ? 'దయచేసి పోలీస్ స్టేషన్ ను ఎంచుకోండి'
              : 'Please select a Police Station';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          return false;
        }
        if (_yearController.text.isEmpty) {
          final locale = Localizations.localeOf(context);
          final msg = locale.languageCode == 'te'
              ? 'దయచేసి సంవత్సరాన్ని నమోదు చేయండి'
              : 'Please enter the year';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          return false;
        }
        if (_firNumberController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.pleaseEnterFirNumber),
            ),
          );
          return false;
        }
        if (_firRegistrationDate == null) {
          final locale = Localizations.localeOf(context);
          final msg = locale.languageCode == 'te'
              ? 'దయచేసి FIR నమోదు తేదీని ఎంచుకోండి'
              : 'Please select FIR Registration Date';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          return false;
        }
        return true;
      default:
        return true; // Other steps are optional
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (index < _totalSteps - 1)
                  const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    final localizations = AppLocalizations.of(context)!;
    
    switch (_currentStep) {
      case 0:
        return _buildBasicInformationStep(localizations);
      case 1:
        return _buildLocationDetailsStep(localizations);
      case 2:
        return _buildInformationReceivedStep(localizations);
      case 3:
        return _buildAdditionalInformationStep(localizations);
      case 4:
        return _buildAccusedDetailsStep(localizations);
      case 5:
        return _buildPropertiesDelayInquestStep(localizations);
      case 6:
        return _buildActsVictimComplaintStep(localizations);
      case 7:
        return _buildActionDispatchStep(localizations);
      case 8:
        return _buildReviewStep(localizations);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInformationStep(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "1. ${localizations.districtAndFirDetails}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Case ID
            Builder(
              builder: (context) {
                final locale = Localizations.localeOf(context);
                final labelText = locale.languageCode == 'te' ? 'కేసు ID' : 'Case ID';
                final hintText = locale.languageCode == 'te' ? 'కేసు ID ను నమోదు చేయండి' : 'Enter case ID';
                final validationMsg = locale.languageCode == 'te'
                    ? 'దయచేసి కేసు ID ను నమోదు చేయండి'
                    : 'Please enter case ID';
                
                return TextFormField(
                  controller: _caseIdController,
                  decoration: InputDecoration(
                    labelText: '$labelText *',
                    hintText: hintText,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.tag),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return validationMsg;
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Case Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '${localizations.caseTitleRequired} *',
                hintText: localizations.caseTitleHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterCaseTitle;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // District Dropdown
            DropdownButtonFormField<String>(
              value: _selectedDistrict,
              decoration: InputDecoration(
                labelText: '${localizations.district} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_city),
              ),
              items: _apDistrictsEnglish
                  .map((districtEnglish) {
                    final localizedName = DistrictTranslations.getDistrictName(context, districtEnglish);
                    return DropdownMenuItem(
                      value: districtEnglish, // Store English name
                      child: Text(localizedName), // Display localized name
                    );
                  })
                  .toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedDistrict = value;
                  // Reset dependent dropdowns when district changes
                  _selectedSubDivision = null;
                  _selectedCircle = null;
                  _selectedPoliceStation = null;
                  _policeStationsEnglish = [];
                });
                // Load police stations for selected district
                if (value != null) {
                  final stations = await DistrictTranslations.getPoliceStationsForDistrict(
                    context,
                    value,
                  );
                  setState(() {
                    _policeStationsEnglish = stations;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a district';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Sub-Division (SDPO) Dropdown
            Builder(
              builder: (context) {
                final locale = Localizations.localeOf(context);
                final labelText = locale.languageCode == 'te' ? 'ఉప-విభాగం (SDPO)' : 'Sub-Division (SDPO)';
                final validationMsg = locale.languageCode == 'te' 
                    ? 'దయచేసి ఉప-విభాగం (SDPO) ను ఎంచుకోండి'
                    : 'Please select a Sub-Division (SDPO)';
                
                return DropdownButtonFormField<String>(
                  value: _selectedSubDivision,
                  decoration: InputDecoration(
                    labelText: '$labelText *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.account_tree),
                  ),
                  items: _subDivisions
                      .map((subDivEnglish) {
                        final localizedName = DistrictTranslations.getSubDivisionName(context, subDivEnglish);
                        return DropdownMenuItem(
                          value: subDivEnglish, // Store English name
                          child: Text(localizedName), // Display localized name
                        );
                      })
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubDivision = value;
                      // Reset dependent dropdowns when sub-division changes
                      _selectedCircle = null;
                      _selectedPoliceStation = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return validationMsg;
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Circle Dropdown
            Builder(
              builder: (context) {
                final locale = Localizations.localeOf(context);
                final labelText = locale.languageCode == 'te' ? 'సర్కిల్' : 'Circle';
                final validationMsg = locale.languageCode == 'te'
                    ? 'దయచేసి సర్కిల్ ను ఎంచుకోండి'
                    : 'Please select a Circle';
                
                return DropdownButtonFormField<String>(
                  value: _selectedCircle,
                  decoration: InputDecoration(
                    labelText: '$labelText *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.place),
                  ),
                  items: _circles
                      .map((circleEnglish) {
                        final localizedName = DistrictTranslations.getCircleName(context, circleEnglish);
                        return DropdownMenuItem(
                          value: circleEnglish, // Store English name
                          child: Text(localizedName), // Display localized name
                        );
                      })
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCircle = value;
                      // Reset police station when circle changes
                      _selectedPoliceStation = null;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty || value == '-') {
                      return validationMsg;
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            // Police Station Dropdown
            DropdownButtonFormField<String>(
              value: _selectedPoliceStation,
              decoration: InputDecoration(
                labelText: '${localizations.policeStation} *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.local_police),
              ),
              items: _policeStationsEnglish.isEmpty
                  ? [
                      DropdownMenuItem(
                        value: null,
                        enabled: false,
                        child: Text(
                          _selectedDistrict == null
                              ? 'Please select a district'
                              : localizations.loading,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    ]
                  : _policeStationsEnglish
                      .map((stationEnglish) {
                        // Store English name, display localized name
                        final localizedName = DistrictTranslations.getLocalizedPoliceStationName(
                          context,
                          stationEnglish,
                        );
                        return DropdownMenuItem(
                          value: stationEnglish, // Store English name for data consistency
                          child: Text(
                            localizedName, // Display localized name
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      })
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPoliceStation = value; // Store English name
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a Police Station';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Year Field
            TextFormField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel('Year *', 'సంవత్సరం *'),
                hintText: _getLocalizedLabel('E.g., 2025', 'ఉదా: 2025'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the year';
                }
                final year = int.tryParse(value);
                if (year == null || year < 2000 || year > DateTime.now().year + 1) {
                  return 'Please enter a valid year';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // FIR Number
            TextFormField(
              controller: _firNumberController,
              decoration: InputDecoration(
                labelText: '${localizations.firNumberRequired} *',
                hintText: localizations.firNumberHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return localizations.pleaseEnterFirNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // FIR Registration Date
            Builder(
              builder: (context) {
                final locale = Localizations.localeOf(context);
                final labelText = locale.languageCode == 'te' ? 'FIR నమోదు తేదీ' : 'FIR Registration Date';
                final placeholderText = locale.languageCode == 'te' ? 'తేదీని ఎంచుకోండి' : 'Select date';
                
                return InkWell(
                  onTap: _selectFirRegistrationDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: '$labelText *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_month),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      _firRegistrationDate != null
                          ? DateFormat('dd-MM-yyyy').format(_firRegistrationDate!)
                          : placeholderText,
                      style: TextStyle(
                        color: _firRegistrationDate != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetailsStep(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${2}. ${localizations.occurenceOfOffence}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            // Day of Occurrence
            TextFormField(
              controller: _occurrenceDayController,
              decoration: InputDecoration(
                labelText: 'Day of Occurrence',
                hintText: 'E.g., Monday',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            // Date/Time From
            InkWell(
              onTap: _selectOccurrenceDateTimeFrom,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date/Time From',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _occurrenceDateTimeFrom != null
                      ? DateFormat('dd-MM-yyyy HH:mm').format(_occurrenceDateTimeFrom!)
                      : 'Select date and time',
                  style: TextStyle(
                    color: _occurrenceDateTimeFrom != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Date/Time To
            InkWell(
              onTap: _selectOccurrenceDateTimeTo,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date/Time To',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _occurrenceDateTimeTo != null
                      ? DateFormat('dd-MM-yyyy HH:mm').format(_occurrenceDateTimeTo!)
                      : 'Select date and time',
                  style: TextStyle(
                    color: _occurrenceDateTimeTo != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Time Period
            TextFormField(
              controller: _timePeriodController,
              decoration: InputDecoration(
                labelText: 'Time Period',
                hintText: 'E.g., 19:15-21:30',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.schedule),
              ),
            ),
            const SizedBox(height: 16),
            // Prior to Date/Time (Details)
            TextFormField(
              controller: _priorToDateTimeDetailsController,
              decoration: InputDecoration(
                labelText: 'Prior to Date/Time (Details)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            // Beat Number
            TextFormField(
              controller: _beatNumberController,
              decoration: InputDecoration(
                labelText: 'Beat Number',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 24),
            // Place of Occurrence sub-heading
            Text(
              'Place of Occurrence',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Street/Village
            TextFormField(
              controller: _streetVillageController,
              decoration: InputDecoration(
                labelText: 'Street/Village',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            // Area/Mandal
            TextFormField(
              controller: _areaMandalController,
              decoration: InputDecoration(
                labelText: 'Area/Mandal',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 16),
            // City/District
            TextFormField(
              controller: _cityDistrictController,
              decoration: InputDecoration(
                labelText: 'City/District',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 16),
            // State
            TextFormField(
              controller: _stateController,
              decoration: InputDecoration(
                labelText: 'State',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.public),
              ),
            ),
            const SizedBox(height: 16),
            // PIN
            TextFormField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'PIN',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.pin),
              ),
            ),
            const SizedBox(height: 16),
            // Latitude
            TextFormField(
              controller: _latitudeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g., 16.5062',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.my_location),
              ),
            ),
            const SizedBox(height: 16),
            // Longitude
            TextFormField(
              controller: _longitudeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g., 80.6480',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.my_location),
              ),
            ),
            const SizedBox(height: 16),
            // Pick on Map button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement map picker functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Map picker functionality will be implemented'),
                    ),
                  );
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Pick on Map (Placeholder)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Distance & Direction from PS section
            Text(
              'Distance & Direction from PS:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Distance from PS
            TextFormField(
              controller: _distanceFromPSController,
              decoration: InputDecoration(
                labelText: 'Distance from PS',
                hintText: 'E.g., 1km',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.straighten),
              ),
            ),
            const SizedBox(height: 16),
            // Direction from PS
            TextFormField(
              controller: _directionFromPSController,
              decoration: InputDecoration(
                labelText: 'Direction from PS',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.explore),
              ),
            ),
            const SizedBox(height: 24),
            // Outside Jurisdiction section
            Text(
              'Outside Jurisdiction:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Is Outside Jurisdiction?'),
              value: _isOutsideJurisdiction,
              onChanged: (bool value) {
                setState(() {
                  _isOutsideJurisdiction = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationReceivedStep(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3. Information Received',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 24),
            // Date/Time Received at PS
            InkWell(
              onTap: _selectInformationReceivedAtPs,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date/Time Received at PS',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _informationReceivedAtPs != null
                      ? DateFormat('dd-MM-yyyy HH:mm').format(_informationReceivedAtPs!)
                      : 'Select date and time',
                  style: TextStyle(
                    color: _informationReceivedAtPs != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // General Diary Entry No.
            TextFormField(
              controller: _generalDiaryEntryNumberController,
              decoration: const InputDecoration(
                labelText: 'General Diary Entry No.',
                hintText: 'E.g., 40',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '4. Type of Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            // Type of Information
            DropdownButtonFormField<String>(
              value: _selectedInformationType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Oral', child: Text('Oral')),
                DropdownMenuItem(value: 'Written', child: Text('Written')),
                DropdownMenuItem(value: 'Phone', child: Text('Phone')),
                DropdownMenuItem(value: 'Email', child: Text('Email')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedInformationType = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccusedDetailsStep(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                '6. Accused Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addAccused,
                icon: const Icon(Icons.add),
                label: const Text('Add Accused'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_accusedList.length, (index) {
          final data = _accusedList[index];
          final serialNo = index + 1;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Accused $serialNo',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        if (_accusedList.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete Accused',
                            onPressed: () => _removeAccused(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Serial No.
                    TextFormField(
                      initialValue: serialNo.toString(),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Serial No.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    TextFormField(
                      controller: data.name,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Father's/Husband's Name
                    TextFormField(
                      controller: data.fatherName,
                      decoration: const InputDecoration(
                        labelText: "Father's/Husband's Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Gender
                    DropdownButtonFormField<String>(
                      value: data.gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          data.gender = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Age
                    TextFormField(
                      controller: data.age,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nationality
                    TextFormField(
                      controller: data.nationality,
                      decoration: const InputDecoration(
                        labelText: 'Nationality',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Caste
                    TextFormField(
                      controller: data.caste,
                      decoration: const InputDecoration(
                        labelText: 'Caste',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Occupation
                    TextFormField(
                      controller: data.occupation,
                      decoration: const InputDecoration(
                        labelText: 'Occupation',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cell No.
                    TextFormField(
                      controller: data.cellNo,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Cell No.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextFormField(
                      controller: data.email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Accused Address
                    Text(
                      'Accused Address:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.houseNo,
                      decoration: const InputDecoration(
                        labelText: 'House No.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.street,
                      decoration: const InputDecoration(
                        labelText: 'Street/Village',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.area,
                      decoration: const InputDecoration(
                        labelText: 'Area/Mandal',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.city,
                      decoration: const InputDecoration(
                        labelText: 'City/District',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.state,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.pin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Physical Features
                    Text(
                      'Physical Features:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.build,
                      decoration: const InputDecoration(
                        labelText: 'Build',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.heightCms,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (cms)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.complexion,
                      decoration: const InputDecoration(
                        labelText: 'Complexion',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.deformities,
                      decoration: const InputDecoration(
                        labelText: 'Deformities/Peculiarities',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPropertiesDelayInquestStep(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 7. Properties Involved
            Text(
              '7. Properties Involved',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _propertiesDetailsController,
              decoration: const InputDecoration(
                labelText: 'Details of Properties Stolen/Involved',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _propertiesTotalValueController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Value of Properties Stolen (INR)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            // 8. Delay in Reporting (if any)
            Text(
              '8. Delay in Reporting (if any)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isDelayInReporting,
              onChanged: (value) {
                setState(() {
                  _isDelayInReporting = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('Was there a delay in reporting?'),
            ),
            const SizedBox(height: 32),
            // 9. Inquest Report / U.D. Case No. (if any)
            Text(
              '9. Inquest Report / U.D. Case No. (if any)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _inquestReportCaseNoController,
              decoration: const InputDecoration(
                labelText: 'Inquest Report / U.D. Case No.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActsVictimComplaintStep(AppLocalizations localizations) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Acts & Sections
            Text(
              'Acts & Sections Involved',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actsAndSectionsController,
              decoration: const InputDecoration(
                labelText: 'Acts & Sections (comma-separated or detailed)',
                hintText: 'E.g., IPC 379, BNS 101',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            // Complaint / Statement
            Text(
              '10. Complaint / Statement of Complainant/Informant *',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Detailed Narrative',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _complaintNarrativeController,
              decoration: const InputDecoration(
                hintText: 'AI Suggestion: Draft complaint based on the original conversation.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 32),
            // Victim Details
            Row(
              children: [
                Text(
                  'Victim Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(width: 12),
                Checkbox(
                  value: _isComplainantAlsoVictim ?? false,
                  onChanged: (value) {
                    setState(() {
                      _isComplainantAlsoVictim = value ?? false;
                    });
                  },
                ),
                const Text('Complainant is also the Victim'),
              ],
            ),
            const SizedBox(height: 16),
            // Victim Name
            TextFormField(
              controller: _victimNameController,
              decoration: const InputDecoration(
                labelText: 'Victim Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim DOB
            InkWell(
              onTap: _selectVictimDob,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Victim DOB',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _victimDob != null
                      ? DateFormat('dd-MM-yyyy').format(_victimDob!)
                      : 'Select date',
                  style: TextStyle(
                    color: _victimDob != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Age
            TextFormField(
              controller: _victimAgeController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Victim Age (auto-calculated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Gender
            DropdownButtonFormField<String>(
              value: _selectedVictimGender,
              decoration: const InputDecoration(
                labelText: 'Victim Gender',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedVictimGender = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Victim Father/Husband
            TextFormField(
              controller: _victimFatherNameController,
              decoration: const InputDecoration(
                labelText: "Victim Father's/Husband's Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Nationality
            TextFormField(
              controller: _victimNationalityController,
              decoration: const InputDecoration(
                labelText: 'Victim Nationality',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Religion
            TextFormField(
              controller: _victimReligionController,
              decoration: const InputDecoration(
                labelText: 'Victim Religion',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Caste
            TextFormField(
              controller: _victimCasteController,
              decoration: const InputDecoration(
                labelText: 'Victim Caste',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Occupation
            TextFormField(
              controller: _victimOccupationController,
              decoration: const InputDecoration(
                labelText: 'Victim Occupation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Victim Address
            Text(
              'Victim Address:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimHouseNoController,
              decoration: const InputDecoration(
                labelText: 'House No.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimStreetController,
              decoration: const InputDecoration(
                labelText: 'Street/Village',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimAreaController,
              decoration: const InputDecoration(
                labelText: 'Area/Mandal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimCityController,
              decoration: const InputDecoration(
                labelText: 'City/District',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimStateController,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimPinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionDispatchStep(AppLocalizations localizations) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 11. Action Taken
            Text(
              '11. Action Taken',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Action Taken (Details)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _actionTakenDetailsController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _ioNameController,
              decoration: const InputDecoration(
                labelText: 'Investigating Officer Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ioRankController,
              decoration: const InputDecoration(
                labelText: 'Officer Rank',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ioDistrictController,
              decoration: const InputDecoration(
                labelText: 'District (of officer)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            // 12. Dispatch to Court
            Text(
              '12. Dispatch to Court',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDispatchDateTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date/Time of Dispatch',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _dispatchDateTime != null
                      ? DateFormat('dd-MM-yyyy HH:mm').format(_dispatchDateTime!)
                      : 'Select date and time',
                  style: TextStyle(
                    color: _dispatchDateTime != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dispatchOfficerNameController,
              decoration: const InputDecoration(
                labelText: 'Name of Officer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dispatchOfficerRankController,
              decoration: const InputDecoration(
                labelText: 'Rank of Officer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            // 13. Confirmation
            Text(
              '13. Confirmation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isFirReadOverAndAdmittedCorrect ?? false,
              onChanged: (value) {
                setState(() {
                  _isFirReadOverAndAdmittedCorrect = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'FIR read over and admitted correct by Complainant/Informant',
              ),
            ),
            CheckboxListTile(
              value: _isFirCopyGivenFreeOfCost ?? false,
              onChanged: (value) {
                setState(() {
                  _isFirCopyGivenFreeOfCost = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Copy of FIR given to Complainant/Informant free of cost',
              ),
            ),
            CheckboxListTile(
              value: _isRoacRecorded ?? false,
              onChanged: (value) {
                setState(() {
                  _isRoacRecorded = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'ROAC (Recorded Over & Admitted Correct)',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Signature/Thumb Impression of Complainant/Informant (Enter 'Digitally Signed' or path if applicable)",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _complainantSignatureNoteController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInformationStep(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5. Complainant / Informant Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Name
            TextFormField(
              controller: _complainantNameController,
              decoration: InputDecoration(
                labelText: localizations.complainantName,
                hintText: localizations.enterComplainantName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            // Father's/Husband's Name
            TextFormField(
              controller: _fatherHusbandNameController,
              decoration: const InputDecoration(
                labelText: "Father's/Husband's Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            // Gender
            DropdownButtonFormField<String>(
              value: _selectedComplainantGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedComplainantGender = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Nationality
            TextFormField(
              controller: _nationalityController,
              decoration: const InputDecoration(
                labelText: 'Nationality',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
            ),
            const SizedBox(height: 16),
            // Caste
            TextFormField(
              controller: _casteController,
              decoration: const InputDecoration(
                labelText: 'Caste',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Occupation
            TextFormField(
              controller: _occupationController,
              decoration: const InputDecoration(
                labelText: 'Occupation',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Date of Birth
            InkWell(
              onTap: _selectComplainantDob,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _complainantDob != null
                      ? DateFormat('dd-MM-yyyy').format(_complainantDob!)
                      : 'Select date',
                  style: TextStyle(
                    color: _complainantDob != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Age (auto-calculated)
            TextFormField(
              controller: _ageController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Age (auto-calculated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Mobile Number
            TextFormField(
              controller: _mobileNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                hintText: '10 digits',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 24),
            // Complainant Address
            Text(
              'Complainant Address:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantHouseNoController,
              decoration: const InputDecoration(
                labelText: 'House No.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantStreetController,
              decoration: const InputDecoration(
                labelText: 'Street/Village',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantAreaController,
              decoration: const InputDecoration(
                labelText: 'Area/Mandal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantCityController,
              decoration: const InputDecoration(
                labelText: 'City/District',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantStateController,
              decoration: const InputDecoration(
                labelText: 'State',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantPinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Complainant Passport (Optional)
            Text(
              'Complainant Passport (Optional):',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantPassportNumberController,
              decoration: const InputDecoration(
                labelText: 'Passport No.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantPassportPlaceController,
              decoration: const InputDecoration(
                labelText: 'Place of Issue',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectComplainantPassportDateOfIssue,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Issue',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _complainantPassportDateOfIssue != null
                      ? DateFormat('dd-MM-yyyy').format(_complainantPassportDateOfIssue!)
                      : 'Select date',
                  style: TextStyle(
                    color: _complainantPassportDateOfIssue != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep(AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Case Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            if (_caseIdController.text.isNotEmpty) ...[
              _buildReviewItem(
                _getLocalizedLabel('Case ID', 'కేసు ID'),
                _caseIdController.text,
                Icons.tag,
              ),
              const Divider(),
            ],
            _buildReviewItem(
              localizations.caseTitleRequired,
              _titleController.text,
              Icons.title,
            ),
            const Divider(),
            _buildReviewItem(
              localizations.firNumberRequired,
              _firNumberController.text,
              Icons.numbers,
            ),
            if (_selectedDistrict != null) ...[
              const Divider(),
              _buildReviewItem(
                localizations.district,
                _selectedDistrict!,
                Icons.location_city,
              ),
            ],
            if (_selectedSubDivision != null) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel('Sub-Division (SDPO)', 'ఉప-విభాగం (SDPO)'),
                DistrictTranslations.getSubDivisionName(context, _selectedSubDivision!),
                Icons.account_tree,
              ),
            ],
            if (_selectedCircle != null && _selectedCircle != '-') ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel('Circle', 'సర్కిల్'),
                DistrictTranslations.getCircleName(context, _selectedCircle!),
                Icons.place,
              ),
            ],
            if (_selectedPoliceStation != null) ...[
              const Divider(),
              _buildReviewItem(
                localizations.policeStation,
                DistrictTranslations.getLocalizedPoliceStationName(context, _selectedPoliceStation!),
                Icons.local_police,
              ),
            ],
            if (_yearController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Year',
                _yearController.text,
                Icons.calendar_today,
              ),
            ],
            if (_firRegistrationDate != null) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel('FIR Registration Date', 'FIR నమోదు తేదీ'),
                DateFormat('dd-MM-yyyy').format(_firRegistrationDate!),
                Icons.calendar_month,
              ),
            ],
            if (_complainantNameController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                localizations.complainantName,
                _complainantNameController.text,
                Icons.person,
              ),
            ],
            if (_fatherHusbandNameController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                "Father's/Husband's Name",
                _fatherHusbandNameController.text,
                Icons.person_outline,
              ),
            ],
            if (_selectedComplainantGender != null &&
                _selectedComplainantGender!.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Gender',
                _selectedComplainantGender!,
                Icons.wc,
              ),
            ],
            if (_nationalityController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Nationality',
                _nationalityController.text,
                Icons.flag,
              ),
            ],
            if (_casteController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Caste',
                _casteController.text,
                Icons.assignment_ind,
              ),
            ],
            if (_occupationController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Occupation',
                _occupationController.text,
                Icons.work,
              ),
            ],
            if (_complainantDob != null) ...[
              const Divider(),
              _buildReviewItem(
                'Date of Birth',
                DateFormat('dd-MM-yyyy').format(_complainantDob!),
                Icons.cake,
              ),
            ],
            if (_ageController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Age',
                _ageController.text,
                Icons.accessibility_new,
              ),
            ],
            if (_mobileNumberController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Mobile Number',
                _mobileNumberController.text,
                Icons.phone,
              ),
            ],
            if (_victimNameController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Victim Name',
                _victimNameController.text,
                Icons.person,
              ),
            ],
            if (_victimDob != null) ...[
              const Divider(),
              _buildReviewItem(
                'Victim DOB',
                DateFormat('dd-MM-yyyy').format(_victimDob!),
                Icons.cake,
              ),
            ],
            if (_victimAgeController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Victim Age',
                _victimAgeController.text,
                Icons.accessibility_new,
              ),
            ],
            if (_selectedVictimGender != null &&
                _selectedVictimGender!.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Victim Gender',
                _selectedVictimGender!,
                Icons.wc,
              ),
            ],
            if (_victimFatherNameController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                "Victim Father's/Husband's Name",
                _victimFatherNameController.text,
                Icons.person_outline,
              ),
            ],
            if (_victimNationalityController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Victim Nationality',
                _victimNationalityController.text,
                Icons.flag,
              ),
            ],
            if (_victimReligionController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Victim Religion',
                _victimReligionController.text,
                Icons.account_balance,
              ),
            ],
            if (_victimCasteController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Victim Caste',
                _victimCasteController.text,
                Icons.assignment_ind,
              ),
            ],
            if (_victimOccupationController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Victim Occupation',
                _victimOccupationController.text,
                Icons.work,
              ),
            ],
            if (_victimHouseNoController.text.isNotEmpty ||
                _victimStreetController.text.isNotEmpty ||
                _victimAreaController.text.isNotEmpty ||
                _victimCityController.text.isNotEmpty ||
                _victimStateController.text.isNotEmpty ||
                _victimPinController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Victim Address',
                [
                  _victimHouseNoController.text,
                  _victimStreetController.text,
                  _victimAreaController.text,
                  _victimCityController.text,
                  _victimStateController.text,
                  _victimPinController.text,
                ]
                    .where((p) => p.trim().isNotEmpty)
                    .join(', '),
                Icons.home,
                isMultiline: true,
              ),
            ],
            const Divider(),
            _buildReviewItem(
              'Complainant is also the Victim',
              (_isComplainantAlsoVictim ?? false) ? 'Yes' : 'No',
              Icons.people_alt,
            ),
            if (_actionTakenDetailsController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Action Taken',
                _actionTakenDetailsController.text,
                Icons.fact_check,
                isMultiline: true,
              ),
            ],
            if (_ioNameController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Investigating Officer Name',
                _ioNameController.text,
                Icons.person,
              ),
            ],
            if (_ioRankController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Investigating Officer Rank',
                _ioRankController.text,
                Icons.badge,
              ),
            ],
            if (_ioDistrictController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Investigating Officer District',
                _ioDistrictController.text,
                Icons.location_city,
              ),
            ],
            if (_dispatchDateTime != null) ...[
              const Divider(),
              _buildReviewItem(
                'Date/Time of Dispatch',
                DateFormat('dd-MM-yyyy HH:mm').format(_dispatchDateTime!),
                Icons.schedule_send,
              ),
            ],
            if (_dispatchOfficerNameController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Dispatch Officer Name',
                _dispatchOfficerNameController.text,
                Icons.person_outline,
              ),
            ],
            if (_dispatchOfficerRankController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Dispatch Officer Rank',
                _dispatchOfficerRankController.text,
                Icons.badge_outlined,
              ),
            ],
            if (_complainantHouseNoController.text.isNotEmpty ||
                _complainantStreetController.text.isNotEmpty ||
                _complainantAreaController.text.isNotEmpty ||
                _complainantCityController.text.isNotEmpty ||
                _complainantStateController.text.isNotEmpty ||
                _complainantPinController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Complainant Address',
                [
                  _complainantHouseNoController.text,
                  _complainantStreetController.text,
                  _complainantAreaController.text,
                  _complainantCityController.text,
                  _complainantStateController.text,
                  _complainantPinController.text,
                ]
                    .where((part) => part.trim().isNotEmpty)
                    .join(', '),
                Icons.home,
                isMultiline: true,
              ),
            ],
            if (_complainantPassportNumberController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Passport No.',
                _complainantPassportNumberController.text,
                Icons.badge,
              ),
            ],
            if (_complainantPassportPlaceController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Passport Place of Issue',
                _complainantPassportPlaceController.text,
                Icons.place,
              ),
            ],
            if (_complainantPassportDateOfIssue != null) ...[
              const Divider(),
              _buildReviewItem(
                'Passport Date of Issue',
                DateFormat('dd-MM-yyyy').format(_complainantPassportDateOfIssue!),
                Icons.event,
              ),
            ],
            if (_actsAndSectionsController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Acts & Sections Involved',
                _actsAndSectionsController.text,
                Icons.gavel,
                isMultiline: true,
              ),
            ],
            if (_complaintNarrativeController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Complaint / Statement',
                _complaintNarrativeController.text,
                Icons.description,
                isMultiline: true,
              ),
            ],
            // Properties involved
            if (_propertiesDetailsController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Details of Properties Stolen/Involved',
                _propertiesDetailsController.text,
                Icons.inventory_2,
                isMultiline: true,
              ),
            ],
            if (_propertiesTotalValueController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Total Value of Properties Stolen (INR)',
                _propertiesTotalValueController.text,
                Icons.currency_rupee,
              ),
            ],
            // Delay in reporting
            const Divider(),
            _buildReviewItem(
              'Delay in Reporting',
              _isDelayInReporting ? 'Yes' : 'No',
              Icons.schedule,
            ),
            // Inquest report
            if (_inquestReportCaseNoController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Inquest Report / U.D. Case No.',
                _inquestReportCaseNoController.text,
                Icons.description_outlined,
              ),
            ],
            // Information received
            if (_informationReceivedAtPs != null) ...[
              const Divider(),
              _buildReviewItem(
                'Date/Time Received at PS',
                DateFormat('dd-MM-yyyy HH:mm').format(_informationReceivedAtPs!),
                Icons.access_time,
              ),
            ],
            if (_generalDiaryEntryNumberController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'General Diary Entry No.',
                _generalDiaryEntryNumberController.text,
                Icons.book,
              ),
            ],
            if (_selectedInformationType != null &&
                _selectedInformationType!.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Type of Information',
                _selectedInformationType!,
                Icons.info,
              ),
            ],
            // Occurrence fields
            if (_occurrenceDayController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Day of Occurrence',
                _occurrenceDayController.text,
                Icons.calendar_today,
              ),
            ],
            if (_occurrenceDateTimeFrom != null) ...[
              const Divider(),
              _buildReviewItem(
                'Date/Time From',
                DateFormat('dd-MM-yyyy HH:mm').format(_occurrenceDateTimeFrom!),
                Icons.access_time,
              ),
            ],
            if (_occurrenceDateTimeTo != null) ...[
              const Divider(),
              _buildReviewItem(
                'Date/Time To',
                DateFormat('dd-MM-yyyy HH:mm').format(_occurrenceDateTimeTo!),
                Icons.access_time,
              ),
            ],
            if (_timePeriodController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Time Period',
                _timePeriodController.text,
                Icons.schedule,
              ),
            ],
            if (_priorToDateTimeDetailsController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Prior to Date/Time (Details)',
                _priorToDateTimeDetailsController.text,
                Icons.description,
                isMultiline: true,
              ),
            ],
            if (_beatNumberController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Beat Number',
                _beatNumberController.text,
                Icons.numbers,
              ),
            ],
            if (_streetVillageController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Street/Village',
                _streetVillageController.text,
                Icons.location_on,
              ),
            ],
            if (_areaMandalController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Area/Mandal',
                _areaMandalController.text,
                Icons.map,
              ),
            ],
            if (_cityDistrictController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'City/District',
                _cityDistrictController.text,
                Icons.location_city,
              ),
            ],
            if (_stateController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'State',
                _stateController.text,
                Icons.public,
              ),
            ],
            if (_pinController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'PIN',
                _pinController.text,
                Icons.pin,
              ),
            ],
            if (_latitudeController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Latitude',
                _latitudeController.text,
                Icons.my_location,
              ),
            ],
            if (_longitudeController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Longitude',
                _longitudeController.text,
                Icons.my_location,
              ),
            ],
            if (_distanceFromPSController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Distance from PS',
                _distanceFromPSController.text,
                Icons.straighten,
              ),
            ],
            if (_directionFromPSController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                'Direction from PS',
                _directionFromPSController.text,
                Icons.explore,
              ),
            ],
            // Outside Jurisdiction
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.gps_fixed, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Outside Jurisdiction',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isOutsideJurisdiction ? 'Yes' : 'No',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Accused summary
            if (_accusedList.isNotEmpty)
              ..._accusedList.asMap().entries.expand<Widget>((entry) {
                final index = entry.key;
                final data = entry.value;
                final serialNo = index + 1;
                final address = [
                  data.houseNo.text,
                  data.street.text,
                  data.area.text,
                  data.city.text,
                  data.state.text,
                  data.pin.text,
                ].where((p) => p.trim().isNotEmpty).join(', ');
                final physicalLines = <String>[];
                if (data.build.text.trim().isNotEmpty) {
                  physicalLines.add('Build: ${data.build.text}');
                }
                if (data.heightCms.text.trim().isNotEmpty) {
                  physicalLines.add('Height: ${data.heightCms.text} cms');
                }
                if (data.complexion.text.trim().isNotEmpty) {
                  physicalLines.add('Complexion: ${data.complexion.text}');
                }
                if (data.deformities.text.trim().isNotEmpty) {
                  physicalLines.add('Deformities/Peculiarities: ${data.deformities.text}');
                }

                return <Widget>[
                  if (data.name.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      'Accused $serialNo Name',
                      data.name.text,
                      Icons.person_outline,
                    ),
                  ],
                  if (data.fatherName.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      "Accused $serialNo Father's/Husband's Name",
                      data.fatherName.text,
                      Icons.person_outline,
                    ),
                  ],
                  if (data.gender != null && data.gender!.isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      'Accused $serialNo Gender',
                      data.gender!,
                      Icons.wc,
                    ),
                  ],
                  if (data.age.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      'Accused $serialNo Age',
                      data.age.text,
                      Icons.accessibility_new,
                    ),
                  ],
                  if (data.occupation.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      'Accused $serialNo Occupation',
                      data.occupation.text,
                      Icons.work,
                    ),
                  ],
                  if (data.cellNo.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      'Accused $serialNo Cell No.',
                      data.cellNo.text,
                      Icons.phone_android,
                    ),
                  ],
                  if (data.email.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      'Accused $serialNo Email',
                      data.email.text,
                      Icons.email,
                    ),
                  ],
                  if (address.isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      'Accused $serialNo Address',
                      address,
                      Icons.home,
                      isMultiline: true,
                    ),
                  ],
                  if (physicalLines.isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      'Accused $serialNo Physical Features',
                      physicalLines.join('\n'),
                      Icons.accessibility,
                      isMultiline: true,
                    ),
                  ],
                ];
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value, IconData icon, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cases'),
        ),
        title: Text(localizations.createNewCase),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: _buildStepIndicator(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildStepContent(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 1,
                    child: _currentStep == _totalSteps - 1
                        ? ElevatedButton(
                            onPressed: _isLoading ? null : _submitCase,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    localizations.createCase,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          )
                        : ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Next',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
