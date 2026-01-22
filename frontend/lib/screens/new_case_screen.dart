import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
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
import 'package:Dharma/data/station_data_constants.dart';

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
        'fatherHusbandName': fatherName.text.isNotEmpty ? fatherName.text : null,
        'gender': gender,
        'age': age.text.isNotEmpty ? age.text : null,
        'nationality': nationality.text.isNotEmpty ? nationality.text : null,
        'caste': caste.text.isNotEmpty ? caste.text : null,
        'occupation': occupation.text.isNotEmpty ? occupation.text : null,
        'cellNo': cellNo.text.isNotEmpty ? cellNo.text : null,
        'email': email.text.isNotEmpty ? email.text : null,
        'address': [
          houseNo.text,
          street.text,
          area.text,
          city.text,
          state.text,
          pin.text,
        ].where((p) => p.trim().isNotEmpty).join(', '),
        'build': build.text.isNotEmpty ? build.text : null,
        'heightCms': heightCms.text.isNotEmpty ? heightCms.text : null,
        'complexion': complexion.text.isNotEmpty ? complexion.text : null,
        'deformities': deformities.text.isNotEmpty ? deformities.text : null,
      };
}

class NewCaseScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final CaseDoc? existingCase;
  
  const NewCaseScreen({super.key, this.initialData, this.existingCase});

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
  final _stateController = TextEditingController(text: 'Andhra Pradesh');
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
  String? _selectedComplainantGender = 'Male'; // Default to Male
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
  final _complainantStateController = TextEditingController(text: 'Andhra Pradesh');
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
  final _victimStateController = TextEditingController(text: 'Andhra Pradesh');
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
  List<String> _apDistrictsEnglish = [];
  
  // Sub-Division list - will be loaded dynamically from JSON
  List<String> _subDivisions = [];
  
  // Circle list - will be loaded dynamically from JSON
  List<String> _circles = [];
  
  // Loading states
  bool _isLoadingSubDivisions = false;
  bool _isLoadingCircles = false;
  
  // Police Station list - will be loaded dynamically from JSON
  List<String> _policeStationsEnglish = []; // English names
  bool _isLoadingPoliceStations = false; // Loading state for police stations
  String? _policeStationLoadError; // Error message if loading fails

  bool _hasPrefilled = false; // Flag to prevent multiple pre-fills
  
  // Search controllers for dropdowns
  final TextEditingController _districtSearchController = TextEditingController();
  final TextEditingController _policeStationSearchController = TextEditingController();

  // Loaded hierarchy data
  Map<String, dynamic>? _policeHierarchyData;

  @override
  void initState() {
    super.initState();
    // Start with one accused by default
    _accusedList.add(_AccusedFormData());
    // Auto-fill FIR registration date to today
    _firRegistrationDate = DateTime.now();

    // Load hierarchy data
    _loadHierarchy();
  }

  Future<void> _loadHierarchy() async {
    try {
      // Use hardcoded constant for reliability
      debugPrint('🔄 Loading police hierarchy (FIR) from constants...');
      final Map<String, dynamic> jsonData = kPoliceHierarchyFir;
      
      if (mounted) {
        setState(() {
          _policeHierarchyData = jsonData;
          // Populate districts from the JSON
          if (jsonData['districts'] != null) {
            _apDistrictsEnglish = (jsonData['districts'] as List)
                .map((d) => d['name'] as String)
                .toList()
              ..sort();
            debugPrint('✅ Loaded ${_apDistrictsEnglish.length} districts from hierarchy JSON');
          } else {
            debugPrint('❌ "districts" key missing or null in hierarchy JSON');
          }
        });
        
        // If we have a selected district (e.g. from prefill), reload stations
        if (_selectedDistrict != null) {
          _loadSubDivisionsForDistrict();
          _loadAllPoliceStationsForDistrict();
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing police hierarchy constants: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Pre-fill from existing case if provided
    if (!_hasPrefilled && widget.existingCase != null) {
      _hasPrefilled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prefillFromExistingCase();
      });
    }
    // Pre-fill from petition data if available (and not editing)
    else if (!_hasPrefilled && widget.initialData != null) {
      _hasPrefilled = true;
      // Use a small delay to ensure all controllers are fully initialized
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _prefillFromPetition();
            }
          });
        }
      });
    }
  }

  void _prefillFromPetition() {
    if (widget.initialData == null) {
      debugPrint('❌ No initial data provided for pre-filling');
      return;
    }
    
    final data = widget.initialData!;
    debugPrint('✅ Pre-filling from petition data. Keys: ${data.keys.toList()}');
    debugPrint('✅ Full data: $data');
    
    // Use setState to batch all updates
    setState(() {
      // Pre-fill case ID from petition case_id (not petition.id)
      if (data['caseId'] != null) {
        final caseId = data['caseId'].toString().trim();
        if (caseId.isNotEmpty && caseId != 'null') {
          _caseIdController.text = caseId;
          debugPrint('✅ Pre-filled case ID: $caseId');
        }
      }
      
      // Pre-fill case title from petition title
      if (data['title'] != null) {
        final title = data['title'].toString().trim();
        if (title.isNotEmpty && title != 'null') {
          _titleController.text = title;
          debugPrint('✅ Pre-filled title: $title');
        }
      }
      
      // Pre-fill complainant name from petitioner name
      if (data['petitionerName'] != null) {
        final name = data['petitionerName'].toString().trim();
        if (name.isNotEmpty && name != 'null') {
          _complainantNameController.text = name;
          debugPrint('✅ Pre-filled complainant name: $name');
        }
      }
      
      // Pre-fill mobile number from phone number
      if (data['phoneNumber'] != null) {
        final phone = data['phoneNumber'].toString().trim();
        if (phone.isNotEmpty && phone != 'null') {
          _mobileNumberController.text = phone;
          debugPrint('✅ Pre-filled mobile number: $phone');
        }
      }
      
      // Pre-fill complaint narrative from grounds (grounds = complaint statement)
      if (data['grounds'] != null) {
        final grounds = data['grounds'].toString().trim();
        if (grounds.isNotEmpty && grounds != 'null') {
          _complaintNarrativeController.text = grounds;
          debugPrint('✅ Pre-filled complaint narrative (length: ${grounds.length})');
        }
      }
      
      // Pre-fill incident address if available
      if (data['incidentAddress'] != null) {
        final address = data['incidentAddress'].toString().trim();
        if (address.isNotEmpty && address != 'null') {
          _streetVillageController.text = address;
          debugPrint('✅ Pre-filled incident address: $address');
        }
      }
      
      // Pre-fill address if available (complainant address)
      if (data['address'] != null) {
        final address = data['address'].toString().trim();
        if (address.isNotEmpty && address != 'null') {
          _complainantStreetController.text = address;
          debugPrint('✅ Pre-filled complainant address: $address');
        }
      }
      
      // Pre-fill district if available
      if (data['district'] != null) {
        final districtName = data['district'].toString().trim();
        if (districtName.isNotEmpty && districtName != 'null') {
          debugPrint('🔍 Attempting to pre-fill district: $districtName');
          if (_apDistrictsEnglish.contains(districtName)) {
            _selectedDistrict = districtName;
            debugPrint('✅ Pre-filled district: $districtName');
            // Load police stations for the district (async, will update later)
            _loadSubDivisionsForDistrict();
            _loadAllPoliceStationsForDistrict().then((_) {
              if (mounted && data['stationName'] != null) {
                final stationName = data['stationName'].toString().trim();
                if (stationName.isNotEmpty && stationName != 'null') {
                  debugPrint('🔍 Attempting to pre-fill police station: $stationName');
                  debugPrint('🔍 Available stations count: ${_policeStationsEnglish.length}');
                  if (_policeStationsEnglish.contains(stationName)) {
                    setState(() {
                      _selectedPoliceStation = stationName;
                    });
                    debugPrint('✅ Pre-filled police station: $stationName');
                  } else {
                    debugPrint('❌ Police station "$stationName" not found in list');
                    debugPrint('🔍 First few stations: ${_policeStationsEnglish.take(3).toList()}');
                  }
                }
              }
            });
          } else {
            debugPrint('❌ District "$districtName" not found in list');
            debugPrint('🔍 Available districts: ${_apDistrictsEnglish.take(5).toList()}...');
          }
        }
      } else if (data['stationName'] != null) {
        // If district is not available but station is, just set it
        final stationName = data['stationName'].toString().trim();
        if (stationName.isNotEmpty && stationName != 'null') {
          _selectedPoliceStation = stationName;
          debugPrint('✅ Pre-filled police station (without district): $stationName');
        }
      }
      
      // Pre-fill occurrence date from incident date if available
      if (data['incidentDate'] != null) {
        try {
          final timestampData = data['incidentDate'];
          Timestamp? timestamp;
          
          // Handle both Timestamp object and serialized Map format
          if (timestampData is Timestamp) {
            timestamp = timestampData;
          } else if (timestampData is Map) {
            // Reconstruct Timestamp from serialized format
            final seconds = timestampData['seconds'];
            final nanoseconds = timestampData['nanoseconds'] ?? 0;
            if (seconds != null) {
              timestamp = Timestamp(seconds as int, nanoseconds as int);
            }
          }
          
        if (timestamp != null) {
          final date = timestamp.toDate();
          _occurrenceDateTimeFrom = date;
          // Auto-fill day of occurrence based on the date
          final dayName = DateFormat('EEEE').format(date);
          _occurrenceDayController.text = dayName;
          debugPrint('✅ Pre-filled occurrence date: $date');
          debugPrint('✅ Pre-filled day of occurrence: $dayName');
        } else {
            debugPrint('❌ Could not parse incident date: $timestampData (type: ${timestampData.runtimeType})');
          }
        } catch (e) {
          debugPrint('❌ Error parsing incident date: $e');
        }
      }
    });
    
    debugPrint('✅ Pre-fill completed. UI should update now.');
  }

  void _prefillFromExistingCase() {
    final c = widget.existingCase!;
    setState(() {
      _caseIdController.text = c.caseId ?? '';
      _titleController.text = c.title;
      _firNumberController.text = c.firNumber;
      _yearController.text = c.year ?? '';
      _selectedDistrict = c.district;
      _selectedPoliceStation = c.policeStation;
      _firRegistrationDate = c.dateFiled.toDate();
      
      _complainantNameController.text = c.complainantName ?? '';
      _fatherHusbandNameController.text = c.complainantFatherHusbandName ?? '';
      _selectedComplainantGender = c.complainantGender;
      _mobileNumberController.text = c.complainantMobileNumber ?? '';
      _nationalityController.text = c.complainantNationality ?? '';
      _casteController.text = c.complainantCaste ?? '';
      _occupationController.text = c.complainantOccupation ?? '';
      if (c.complainantDob != null) {
        try { _complainantDob = DateFormat('yyyy-MM-dd').parse(c.complainantDob!); } catch (_) {}
      }
      _ageController.text = c.complainantAge ?? '';
      
      // Parse complainant address
      if (c.complainantAddress != null) {
        final parts = c.complainantAddress!.split(', ');
        if (parts.isNotEmpty) _complainantHouseNoController.text = parts.length > 0 ? parts[0] : '';
        if (parts.length > 1) _complainantStreetController.text = parts[1];
        if (parts.length > 2) _complainantAreaController.text = parts[2];
        if (parts.length > 3) _complainantCityController.text = parts[3];
        if (parts.length > 4) _complainantStateController.text = parts[4];
        if (parts.length > 5) _complainantPinController.text = parts[5];
      }

      _ioNameController.text = c.investigatingOfficerName ?? '';
      _ioRankController.text = c.investigatingOfficerRank ?? '';
      _ioDistrictController.text = c.investigatingOfficerDistrict ?? '';
      
      // Occurrence Details
      _occurrenceDayController.text = c.occurrenceDay ?? '';
      if (c.occurrenceDateTimeFrom != null) {
         try { _occurrenceDateTimeFrom = DateFormat('yyyy-MM-dd HH:mm').parse(c.occurrenceDateTimeFrom!); } catch (_) {}
      }
      if (c.occurrenceDateTimeTo != null) {
         try { _occurrenceDateTimeTo = DateFormat('yyyy-MM-dd HH:mm').parse(c.occurrenceDateTimeTo!); } catch (_) {}
      }
      _timePeriodController.text = c.timePeriod ?? '';
      _priorToDateTimeDetailsController.text = c.priorToDateTimeDetails ?? '';
      _beatNumberController.text = c.beatNumber ?? '';
      _streetVillageController.text = c.placeOfOccurrenceStreet ?? '';
      _areaMandalController.text = c.placeOfOccurrenceArea ?? '';
      _cityDistrictController.text = c.placeOfOccurrenceCity ?? '';
      _stateController.text = c.placeOfOccurrenceState ?? 'Andhra Pradesh';
      _pinController.text = c.placeOfOccurrencePin ?? '';
      _latitudeController.text = c.placeOfOccurrenceLatitude ?? '';
      _longitudeController.text = c.placeOfOccurrenceLongitude ?? '';
      _distanceFromPSController.text = c.distanceFromPS ?? '';
      _directionFromPSController.text = c.directionFromPS ?? '';
      _isOutsideJurisdiction = c.isOutsideJurisdiction ?? false;

      // Information Received
      if (c.informationReceivedDateTime != null) {
        try { _informationReceivedAtPs = DateFormat('yyyy-MM-dd HH:mm').parse(c.informationReceivedDateTime!); } catch (_) {}
      }
      _generalDiaryEntryNumberController.text = c.generalDiaryEntryNumber ?? '';
      _selectedInformationType = c.informationType;

      // Complainant Extra
      _complainantPassportNumberController.text = c.complainantPassportNumber ?? '';
      _complainantPassportPlaceController.text = c.complainantPassportPlaceOfIssue ?? '';
      if (c.complainantPassportDateOfIssue != null) {
        try { _complainantPassportDateOfIssue = DateFormat('yyyy-MM-dd').parse(c.complainantPassportDateOfIssue!); } catch (_) {}
      }

      // Incident & Complaint
      _incidentDetailsController.text = c.incidentDetails ?? '';
      _actsAndSectionsController.text = c.actsAndSectionsInvolved ?? '';
      _complaintNarrativeController.text = c.complaintStatement ?? '';

      // Properties / Delay / Inquest
      _propertiesDetailsController.text = c.propertiesDetails ?? '';
      _propertiesTotalValueController.text = c.propertiesTotalValueInr ?? '';
      _isDelayInReporting = c.isDelayInReporting ?? false;
      _inquestReportCaseNoController.text = c.inquestReportCaseNo ?? '';

      // Action Taken / Dispatch
      _actionTakenDetailsController.text = c.actionTakenDetails ?? '';
      // io details already mapped
      if (c.dispatchDateTime != null) {
        try { _dispatchDateTime = DateFormat('yyyy-MM-dd HH:mm').parse(c.dispatchDateTime!); } catch (_) {}
      }
      _dispatchOfficerNameController.text = c.dispatchOfficerName ?? '';
      _dispatchOfficerRankController.text = c.dispatchOfficerRank ?? '';
      
      // Confirmation
      _isFirReadOverAndAdmittedCorrect = c.isFirReadOverAndAdmittedCorrect;
      _isFirCopyGivenFreeOfCost = c.isFirCopyGivenFreeOfCost;
      _isRoacRecorded = c.isRoacRecorded;
      _complainantSignatureNoteController.text = c.complainantSignatureNote ?? '';

      // Victim Details
      _victimNameController.text = c.victimName ?? '';
      _victimAgeController.text = c.victimAge ?? '';
      _selectedVictimGender = c.victimGender;
      _victimFatherNameController.text = c.victimFatherHusbandName ?? '';
      _victimNationalityController.text = c.victimNationality ?? '';
      _victimReligionController.text = c.victimReligion ?? '';
      _victimCasteController.text = c.victimCaste ?? '';
      _victimOccupationController.text = c.victimOccupation ?? '';
      if (c.victimDob != null) {
         try { _victimDob = DateFormat('yyyy-MM-dd').parse(c.victimDob!); } catch (_) {}
      }
      _isComplainantAlsoVictim = c.isComplainantAlsoVictim;
      
      // Parse victim address
      if (c.victimAddress != null) {
        final parts = c.victimAddress!.split(', ');
        if (parts.isNotEmpty) _victimHouseNoController.text = parts.length > 0 ? parts[0] : '';
        if (parts.length > 1) _victimStreetController.text = parts[1];
        if (parts.length > 2) _victimAreaController.text = parts[2];
        if (parts.length > 3) _victimCityController.text = parts[3];
        if (parts.length > 4) _victimStateController.text = parts[4];
        if (parts.length > 5) _victimPinController.text = parts[5];
      }

      // Accused List
      _accusedList.clear();
      if (c.accusedPersons != null && c.accusedPersons!.isNotEmpty) {
        for (var a in c.accusedPersons!) {
             final accused = _AccusedFormData();
             accused.name.text = a['name'] ?? '';
             accused.fatherName.text = a['fatherHusbandName'] ?? '';
             accused.gender = a['gender'];
             accused.age.text = a['age'] ?? '';
             accused.nationality.text = a['nationality'] ?? '';
             accused.caste.text = a['caste'] ?? '';
             accused.occupation.text = a['occupation'] ?? '';
             accused.cellNo.text = a['cellNo'] ?? '';
             accused.email.text = a['email'] ?? '';
             accused.build.text = a['build'] ?? '';
             accused.heightCms.text = a['heightCms'] ?? '';
             accused.complexion.text = a['complexion'] ?? '';
             accused.deformities.text = a['deformities'] ?? '';
             
            // Parse accused address
            if (a['address'] != null) {
              final parts = (a['address'] as String).split(', ');
              if (parts.isNotEmpty) accused.houseNo.text = parts.length > 0 ? parts[0] : '';
              if (parts.length > 1) accused.street.text = parts[1];
              if (parts.length > 2) accused.area.text = parts[2];
              if (parts.length > 3) accused.city.text = parts[3];
              if (parts.length > 4) accused.state.text = parts[4];
              if (parts.length > 5) accused.pin.text = parts[5];
            }
            _accusedList.add(accused);
        }
      } else {
         _accusedList.add(_AccusedFormData());
      }
      
      // Load districts to ensure dropdown works
      if (_selectedDistrict != null) {
        _loadSubDivisionsForDistrict();
        _loadAllPoliceStationsForDistrict().then((_) {
          if (mounted && c.policeStation != null) {
            setState(() {
              // Ensure the loaded station exists in the list
              if (_policeStationsEnglish.contains(c.policeStation)) {
                 _selectedPoliceStation = c.policeStation;
              }
            });
          }
        });
      }
    });
  }

  Future<void> _loadSubDivisionsForDistrict() async {
    if (_policeHierarchyData == null || _selectedDistrict == null) return;

    setState(() {
      _isLoadingSubDivisions = true;
      _subDivisions.clear();
      _circles.clear();
      _policeStationsEnglish.clear();
      _selectedSubDivision = null;
      _selectedCircle = null;
      _selectedPoliceStation = null;
    });

    try {
      if (_policeHierarchyData?['districts'] != null) {
        final districts = _policeHierarchyData!['districts'] as List;
        final districtData = districts.firstWhere(
          (d) => d['name'] == _selectedDistrict,
          orElse: () => null,
        );

        if (districtData != null && districtData['sdpos'] != null) {
          final sdpos = districtData['sdpos'] as List;
          setState(() {
            _subDivisions = sdpos.map((s) => s['name'] as String).toList()..sort();
            _isLoadingSubDivisions = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading sub-divisions: $e');
      setState(() => _isLoadingSubDivisions = false);
    }
  }

  Future<void> _loadCirclesForSubDivision() async {
    if (_policeHierarchyData == null || _selectedDistrict == null || _selectedSubDivision == null) return;

    setState(() {
      _isLoadingCircles = true;
      _circles.clear();
      _policeStationsEnglish.clear();
      _selectedCircle = null;
      _selectedPoliceStation = null;
    });

    try {
      final districts = _policeHierarchyData!['districts'] as List;
      final districtData = districts.firstWhere((d) => d['name'] == _selectedDistrict, orElse: () => null);

      if (districtData != null && districtData['sdpos'] != null) {
        final sdpos = districtData['sdpos'] as List;
        final sdpoData = sdpos.firstWhere((s) => s['name'] == _selectedSubDivision, orElse: () => null);

        if (sdpoData != null && sdpoData['circles'] != null) {
          final circles = sdpoData['circles'] as List;
          setState(() {
            _circles = circles.map((c) => c['name'] as String).toList()..sort();
            _isLoadingCircles = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading circles: $e');
      setState(() => _isLoadingCircles = false);
    }
  }

  Future<void> _loadPoliceStationsForCircle() async {
    if (_policeHierarchyData == null || _selectedDistrict == null || _selectedSubDivision == null || _selectedCircle == null) return;

    setState(() {
      _isLoadingPoliceStations = true;
      _policeStationsEnglish.clear();
      _selectedPoliceStation = null;
    });

    try {
      final districts = _policeHierarchyData!['districts'] as List;
      final districtData = districts.firstWhere((d) => d['name'] == _selectedDistrict, orElse: () => null);

      if (districtData != null && districtData['sdpos'] != null) {
        final sdpos = districtData['sdpos'] as List;
        final sdpoData = sdpos.firstWhere((s) => s['name'] == _selectedSubDivision, orElse: () => null);

        if (sdpoData != null && sdpoData['circles'] != null) {
          final circles = sdpoData['circles'] as List;
          final circleData = circles.firstWhere((c) => c['name'] == _selectedCircle, orElse: () => null);

          if (circleData != null && circleData['police_stations'] != null) {
            final stations = (circleData['police_stations'] as List).cast<String>().toList()..sort();
            setState(() {
              _policeStationsEnglish = stations;
              _isLoadingPoliceStations = false;
              if (stations.isEmpty) {
                _policeStationLoadError = _getLocalizedLabel(
                  'No police stations found for this circle',
                  'ఈ సర్కిల్ కోసం పోలీస్ స్టేషన్లు కనుగొనబడలేదు',
                );
              }
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading police stations: $e');
    }
    
    setState(() {
      _isLoadingPoliceStations = false;
      _policeStationLoadError = _getLocalizedLabel(
        'Failed to load police stations',
        'పోలీస్ స్టేషన్లను లోడ్ చేయడంలో విఫలమైంది',
      );
    });
  }

  /// Keep this for backwards compatibility or direct district selection
  Future<void> _loadAllPoliceStationsForDistrict() async {
    if (_selectedDistrict != null) {
      if (_policeHierarchyData == null) {
        await _loadHierarchy();
      }

      setState(() {
        _isLoadingPoliceStations = true;
        _policeStationLoadError = null;
        _policeStationsEnglish = [];
      });
      
      try {
        List<String> stations = [];
        
        if (_policeHierarchyData != null && _policeHierarchyData!['districts'] != null) {
           final districts = _policeHierarchyData!['districts'] as List;
           final districtData = districts.firstWhere(
             (d) => d['name'] == _selectedDistrict, 
             orElse: () => null
           );
           
           if (districtData != null && districtData['sdpos'] != null) {
             final sdpos = districtData['sdpos'] as List;
             for (var sdpo in sdpos) {
               if (sdpo['circles'] != null) {
                 final circles = sdpo['circles'] as List;
                 for (var circle in circles) {
                    if (circle['police_stations'] != null) {
                      final psList = (circle['police_stations'] as List).cast<String>();
                      stations.addAll(psList);
                    }
                 }
               }
             }
           }
        }

        // Stations are returned in English for storage
        setState(() {
          // Remove duplicates if any and sort
          _policeStationsEnglish = stations.toSet().toList()..sort();
          _isLoadingPoliceStations = false;
          if (stations.isEmpty) {
            _policeStationLoadError = _getLocalizedLabel(
              'No police stations found for this district',
              'ఈ జిల్లా కోసం పోలీస్ స్టేషన్లు కనుగొనబడలేదు',
            );
          }
        });
      } catch (e) {
        debugPrint('Error loading police stations: $e');
        setState(() {
          _isLoadingPoliceStations = false;
          _policeStationLoadError = _getLocalizedLabel(
            'Failed to load police stations. Please try again.',
            'పోలీస్ స్టేషన్లను లోడ్ చేయడంలో విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
          );
        });
      }
    }
  }

  /// Helper method to get localized label based on current locale
  String _getLocalizedLabel(String english, String telugu) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'te' ? telugu : english;
  }

  /// Helper method to get localized information type
  String _getLocalizedInformationType(String type) {
    switch (type) {
      case 'Oral':
        return _getLocalizedLabel('Oral', 'మౌఖిక');
      case 'Written':
        return _getLocalizedLabel('Written', 'లిఖిత');
      case 'Phone':
        return _getLocalizedLabel('Phone', 'ఫోన్');
      case 'Email':
        return _getLocalizedLabel('Email', 'ఇమెయిల్');
      case 'Other':
        return _getLocalizedLabel('Other', 'ఇతర');
      default:
        return type;
    }
  }

  /// Helper method to get localized gender
  String _getLocalizedGender(String gender) {
    switch (gender) {
      case 'Male':
        return _getLocalizedLabel('Male', 'పురుషుడు');
      case 'Female':
        return _getLocalizedLabel('Female', 'స్త్రీ');
      case 'Other':
        return _getLocalizedLabel('Other', 'ఇతర');
      default:
        return gender;
    }
  }

  /// Copy complainant details to victim details
  void _copyComplainantToVictim() {
    setState(() {
      // Copy name
      _victimNameController.text = _complainantNameController.text;
      
      // Copy father/husband name
      _victimFatherNameController.text = _fatherHusbandNameController.text;
      
      // Copy gender
      _selectedVictimGender = _selectedComplainantGender;
      
      // Copy DOB and age
      _victimDob = _complainantDob;
      _victimAgeController.text = _ageController.text;
      
      // Copy nationality
      _victimNationalityController.text = _nationalityController.text;
      
      // Copy caste
      _victimCasteController.text = _casteController.text;
      
      // Copy occupation
      _victimOccupationController.text = _occupationController.text;
      
      // Copy address
      _victimHouseNoController.text = _complainantHouseNoController.text;
      _victimStreetController.text = _complainantStreetController.text;
      _victimAreaController.text = _complainantAreaController.text;
      _victimCityController.text = _complainantCityController.text;
      _victimStateController.text = _complainantStateController.text;
      _victimPinController.text = _complainantPinController.text;
    });
  }

  /// Auto-fill Mandal and District based on Street/Village name (for place of occurrence)
  Future<void> _autoFillMandalAndDistrict() async {
    final villageName = _streetVillageController.text.trim();
    if (villageName.isEmpty) return;

    try {
      // Load police stations data
      final String jsonString = await rootBundle.loadString('assets/data/district_police_stations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      String? foundDistrict;
      String? foundMandal;

      // Search through all districts and their police stations
      for (var districtEntry in jsonData.entries) {
        final districtName = districtEntry.key;
        final policeStations = (districtEntry.value as List).cast<String>();

        // Search for village name in police station names
        for (var stationName in policeStations) {
          // Remove common suffixes for matching
          final cleanStationName = stationName
              .replaceAll(' Town', '')
              .replaceAll(' Rural', '')
              .replaceAll(' Traffic', '')
              .replaceAll(' Traffic PS', '')
              .replaceAll(' Taluk', '')
              .replaceAll(' Taluk PS', '')
              .replaceAll(' UPS', '')
              .replaceAll(' CCS', '')
              .replaceAll('I Town', '')
              .replaceAll('II Town', '')
              .replaceAll('III Town', '')
              .replaceAll('IV Town', '')
              .replaceAll('Mahila UPS, ', '')
              .trim();

          // Check if village name matches or is contained in station name
          if (cleanStationName.toLowerCase() == villageName.toLowerCase() ||
              cleanStationName.toLowerCase().contains(villageName.toLowerCase()) ||
              villageName.toLowerCase().contains(cleanStationName.toLowerCase())) {
            foundDistrict = districtName;
            
            // Try to extract mandal from station name
            // Many police stations are named after mandals
            if (cleanStationName.isNotEmpty) {
              foundMandal = cleanStationName;
            }
            break;
          }

          // Also check if any part of the station name matches
          final stationParts = cleanStationName.split(' ');
          for (var part in stationParts) {
            if (part.toLowerCase() == villageName.toLowerCase() ||
                part.toLowerCase().contains(villageName.toLowerCase()) ||
                villageName.toLowerCase().contains(part.toLowerCase())) {
              if (part.length >= 3) { // Only consider meaningful matches
                foundDistrict = districtName;
                foundMandal = part;
                break;
              }
            }
          }

          if (foundDistrict != null) break;
        }

        if (foundDistrict != null) break;
      }

      // Update the form fields if matches found
      if (mounted && (foundDistrict != null || foundMandal != null)) {
        setState(() {
          if (foundDistrict != null) {
            _cityDistrictController.text = foundDistrict;
          }
          if (foundMandal != null && foundMandal.isNotEmpty) {
            _areaMandalController.text = foundMandal;
          }
        });

        if (foundDistrict != null || foundMandal != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                foundDistrict != null && foundMandal != null
                    ? 'Auto-filled: $foundMandal, $foundDistrict'
                    : foundDistrict != null
                        ? 'Auto-filled District: $foundDistrict'
                        : 'Auto-filled Mandal: $foundMandal',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        // No match found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedLabel(
              'Could not find matching Mandal/District. Please enter manually.',
              'సరిపోలే మండలం/జిల్లా కనుగొనబడలేదు. దయచేసి మాన్యువల్‌గా నమోదు చేయండి.',
            )),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error auto-filling mandal and district: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedLabel(
              'Error looking up location. Please enter manually.',
              'స్థానాన్ని శోధించడంలో లోపం. దయచేసి మాన్యువల్‌గా నమోదు చేయండి.',
            )),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Auto-fill Mandal and District for accused address based on Street/Village name
  Future<void> _autoFillAccusedMandalAndDistrict(_AccusedFormData accusedData) async {
    final villageName = accusedData.street.text.trim();
    if (villageName.isEmpty) return;

    try {
      // Load police stations data
      final String jsonString = await rootBundle.loadString('assets/data/district_police_stations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      String? foundDistrict;
      String? foundMandal;

      // Search through all districts and their police stations
      for (var districtEntry in jsonData.entries) {
        final districtName = districtEntry.key;
        final policeStations = (districtEntry.value as List).cast<String>();

        // Search for village name in police station names
        for (var stationName in policeStations) {
          // Remove common suffixes for matching
          final cleanStationName = stationName
              .replaceAll(' Town', '')
              .replaceAll(' Rural', '')
              .replaceAll(' Traffic', '')
              .replaceAll(' Traffic PS', '')
              .replaceAll(' Taluk', '')
              .replaceAll(' Taluk PS', '')
              .replaceAll(' UPS', '')
              .replaceAll(' CCS', '')
              .replaceAll('I Town', '')
              .replaceAll('II Town', '')
              .replaceAll('III Town', '')
              .replaceAll('IV Town', '')
              .replaceAll('Mahila UPS, ', '')
              .trim();

          // Check if village name matches or is contained in station name
          if (cleanStationName.toLowerCase() == villageName.toLowerCase() ||
              cleanStationName.toLowerCase().contains(villageName.toLowerCase()) ||
              villageName.toLowerCase().contains(cleanStationName.toLowerCase())) {
            foundDistrict = districtName;
            
            // Try to extract mandal from station name
            if (cleanStationName.isNotEmpty) {
              foundMandal = cleanStationName;
            }
            break;
          }

          // Also check if any part of the station name matches
          final stationParts = cleanStationName.split(' ');
          for (var part in stationParts) {
            if (part.toLowerCase() == villageName.toLowerCase() ||
                part.toLowerCase().contains(villageName.toLowerCase()) ||
                villageName.toLowerCase().contains(part.toLowerCase())) {
              if (part.length >= 3) {
                foundDistrict = districtName;
                foundMandal = part;
                break;
              }
            }
          }

          if (foundDistrict != null) break;
        }

        if (foundDistrict != null) break;
      }

      // Update the form fields if matches found
      if (mounted && (foundDistrict != null || foundMandal != null)) {
        setState(() {
          if (foundDistrict != null) {
            accusedData.city.text = foundDistrict;
          }
          if (foundMandal != null && foundMandal.isNotEmpty) {
            accusedData.area.text = foundMandal;
          }
        });

        if (foundDistrict != null || foundMandal != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                foundDistrict != null && foundMandal != null
                    ? 'Auto-filled: $foundMandal, $foundDistrict'
                    : foundDistrict != null
                        ? 'Auto-filled District: $foundDistrict'
                        : 'Auto-filled Mandal: $foundMandal',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        // No match found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedLabel(
              'Could not find matching Mandal/District. Please enter manually.',
              'సరిపోలే మండలం/జిల్లా కనుగొనబడలేదు. దయచేసి మాన్యువల్‌గా నమోదు చేయండి.',
            )),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error auto-filling accused mandal and district: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedLabel(
              'Error looking up location. Please enter manually.',
              'స్థానాన్ని శోధించడంలో లోపం. దయచేసి మాన్యువల్‌గా నమోదు చేయండి.',
            )),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Auto-fill Mandal and District for complainant address based on Street/Village name
  Future<void> _autoFillComplainantMandalAndDistrict() async {
    final villageName = _complainantStreetController.text.trim();
    if (villageName.isEmpty) return;

    try {
      // Load police stations data
      final String jsonString = await rootBundle.loadString('assets/data/district_police_stations.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      String? foundDistrict;
      String? foundMandal;

      // Search through all districts and their police stations
      for (var districtEntry in jsonData.entries) {
        final districtName = districtEntry.key;
        final policeStations = (districtEntry.value as List).cast<String>();

        // Search for village name in police station names
        for (var stationName in policeStations) {
          // Remove common suffixes for matching
          final cleanStationName = stationName
              .replaceAll(' Town', '')
              .replaceAll(' Rural', '')
              .replaceAll(' Traffic', '')
              .replaceAll(' Traffic PS', '')
              .replaceAll(' Taluk', '')
              .replaceAll(' Taluk PS', '')
              .replaceAll(' UPS', '')
              .replaceAll(' CCS', '')
              .replaceAll('I Town', '')
              .replaceAll('II Town', '')
              .replaceAll('III Town', '')
              .replaceAll('IV Town', '')
              .replaceAll('Mahila UPS, ', '')
              .trim();

          // Check if village name matches or is contained in station name
          if (cleanStationName.toLowerCase() == villageName.toLowerCase() ||
              cleanStationName.toLowerCase().contains(villageName.toLowerCase()) ||
              villageName.toLowerCase().contains(cleanStationName.toLowerCase())) {
            foundDistrict = districtName;
            
            // Try to extract mandal from station name
            if (cleanStationName.isNotEmpty) {
              foundMandal = cleanStationName;
            }
            break;
          }

          // Also check if any part of the station name matches
          final stationParts = cleanStationName.split(' ');
          for (var part in stationParts) {
            if (part.toLowerCase() == villageName.toLowerCase() ||
                part.toLowerCase().contains(villageName.toLowerCase()) ||
                villageName.toLowerCase().contains(part.toLowerCase())) {
              if (part.length >= 3) {
                foundDistrict = districtName;
                foundMandal = part;
                break;
              }
            }
          }

          if (foundDistrict != null) break;
        }

        if (foundDistrict != null) break;
      }

      // Update the form fields if matches found
      if (mounted && (foundDistrict != null || foundMandal != null)) {
        setState(() {
          if (foundDistrict != null) {
            _complainantCityController.text = foundDistrict;
          }
          if (foundMandal != null && foundMandal.isNotEmpty) {
            _complainantAreaController.text = foundMandal;
          }
        });

        if (foundDistrict != null || foundMandal != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                foundDistrict != null && foundMandal != null
                    ? 'Auto-filled: $foundMandal, $foundDistrict'
                    : foundDistrict != null
                        ? 'Auto-filled District: $foundDistrict'
                        : 'Auto-filled Mandal: $foundMandal',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        // No match found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedLabel(
              'Could not find matching Mandal/District. Please enter manually.',
              'సరిపోలే మండలం/జిల్లా కనుగొనబడలేదు. దయచేసి మాన్యువల్‌గా నమోదు చేయండి.',
            )),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error auto-filling complainant mandal and district: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedLabel(
              'Error looking up location. Please enter manually.',
              'స్థానాన్ని శోధించడంలో లోపం. దయచేసి మాన్యువల్‌గా నమోదు చేయండి.',
            )),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Build a searchable dropdown widget
  Widget _buildSearchableDropdown<T>({
    required String label,
    required String hint,
    required IconData icon,
    required T? value,
    required List<T> items,
    required TextEditingController searchController,
    required String Function(T) getDisplayText,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    String? emptyMessage,
  }) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (formFieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TextField for search and display
            InkWell(
              onTap: () {
                _showSearchableDropdownDialog<T>(
                  context: context,
                  label: label,
                  hint: hint,
                  icon: icon,
                  items: items,
                  searchController: searchController,
                  getDisplayText: getDisplayText,
                  onSelected: (selectedValue) {
                    onChanged(selectedValue);
                    formFieldState.didChange(selectedValue);
                  },
                  emptyMessage: emptyMessage,
                );
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(icon),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                  errorText: formFieldState.hasError ? formFieldState.errorText : null,
                ),
                child: Text(
                  value != null ? getDisplayText(value) : hint,
                  style: TextStyle(
                    color: value != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show a dialog with searchable dropdown
  void _showSearchableDropdownDialog<T>({
    required BuildContext context,
    required String label,
    required String hint,
    required IconData icon,
    required List<T> items,
    required TextEditingController searchController,
    required String Function(T) getDisplayText,
    required void Function(T?) onSelected,
    String? emptyMessage,
  }) {
    List<T> filteredItems = List.from(items);
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter items based on search query
            void filterItems(String query) {
              setDialogState(() {
                if (query.isEmpty) {
                  filteredItems = List.from(items);
                } else {
                  filteredItems = items.where((item) {
                    final displayText = getDisplayText(item).toLowerCase();
                    final englishText = item.toString().toLowerCase();
                    return displayText.contains(query.toLowerCase()) ||
                        englishText.contains(query.toLowerCase());
                  }).toList();
                }
              });
            }

            // Initialize filtered items
            if (searchController.text.isNotEmpty) {
              filterItems(searchController.text);
            }

            return AlertDialog(
              title: Row(
                children: [
                  Icon(icon, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label.replaceAll(' *', ''),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search TextField
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: hint,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  filterItems('');
                                },
                              )
                            : null,
                      ),
                      onChanged: filterItems,
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    // List of items
                    Flexible(
                      child: filteredItems.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                emptyMessage ?? _getLocalizedLabel(
                                  'No items found',
                                  'ఎటువంటి అంశాలు కనుగొనబడలేదు',
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final displayText = getDisplayText(item);
                                return ListTile(
                                  title: Text(displayText),
                                  onTap: () {
                                    onSelected(item);
                                    Navigator.pop(dialogContext);
                                  },
                                  dense: true,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    searchController.clear();
                    Navigator.pop(dialogContext);
                  },
                  child: Text(_getLocalizedLabel('Cancel', 'రద్దు చేయి')),
                ),
              ],
            );
          },
        );
      },
    );
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
    _districtSearchController.dispose();
    _policeStationSearchController.dispose();
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
          // Auto-fill day of occurrence based on the selected date
          final dayName = DateFormat('EEEE').format(_occurrenceDateTimeFrom!);
          _occurrenceDayController.text = dayName;
          // Auto-fill time period if date/time to is also set
          if (_occurrenceDateTimeTo != null) {
            _updateTimePeriod();
          }
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
          // Auto-fill time period from date/time from and to
          _updateTimePeriod();
        });
      }
    }
  }

  /// Auto-fill time period from date/time from and to
  void _updateTimePeriod() {
    if (_occurrenceDateTimeFrom != null && _occurrenceDateTimeTo != null) {
      final fromTime = DateFormat('HH:mm').format(_occurrenceDateTimeFrom!);
      final toTime = DateFormat('HH:mm').format(_occurrenceDateTimeTo!);
      setState(() {
        _timePeriodController.text = '$fromTime-$toTime';
      });
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
        accusedPersons: _accusedList
            .where((a) => a.name.text.trim().isNotEmpty)
            .map((a) => a.toMap())
            .toList(),
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
        status: widget.existingCase?.status ?? CaseStatus.newCase,
        dateFiled: widget.existingCase?.dateFiled ?? Timestamp.now(),
        lastUpdated: Timestamp.now(),
        userId: widget.existingCase?.userId ?? authProvider.userProfile?.uid,
      );

      if (widget.existingCase != null) {
        // Update existing case
        await caseProvider.updateCase(widget.existingCase!.id!, newCase.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Case updated successfully')),
          );
        }
      } else {
        // Create new case
        await caseProvider.addCase(newCase);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.caseCreatedSuccess)),
           );
        }
      }

      if (mounted) {
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
            // District Searchable Dropdown
            _buildSearchableDropdown<String>(
              label: '${localizations.district} *',
              hint: _getLocalizedLabel('Search district...', 'జిల్లాను శోధించండి...'),
              icon: Icons.location_city,
              value: _selectedDistrict,
              items: _apDistrictsEnglish,
              searchController: _districtSearchController,
              getDisplayText: (districtEnglish) => DistrictTranslations.getDistrictName(context, districtEnglish),
              onChanged: (value) async {
                setState(() {
                  _selectedDistrict = value;
                  // Reset dependent dropdowns when district changes
                  _selectedSubDivision = null;
                  _selectedCircle = null;
                  _selectedPoliceStation = null;
                  _policeStationsEnglish = [];
                  _districtSearchController.clear();
                });
                if (value != null) {
                   // Load sub-divisions for the new district
                  _loadSubDivisionsForDistrict();
                  
                  // Also load full flattened list for direct station selection
                  // (Currently the UI will clear this list visually via state but data will be fetched)
                  _loadAllPoliceStationsForDistrict();
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
            // Dynamic Sub-Division (SDPO) Dropdown
            if (_subDivisions.isNotEmpty || _isLoadingSubDivisions) ...[
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
                        suffixIcon: _isLoadingSubDivisions 
                          ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                          : null,
                      ),
                      items: _subDivisions
                          .map((subDivEnglish) {
                            final localizedName = DistrictTranslations.getSubDivisionName(context, subDivEnglish);
                            return DropdownMenuItem(
                              value: subDivEnglish, // Store English name
                              child: Text(
                                localizedName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (value) {
                         // Only update if value changed
                         if(value != _selectedSubDivision) {
                            setState(() {
                              _selectedSubDivision = value;
                              _selectedCircle = null;
                              _selectedPoliceStation = null;
                              _policeStationSearchController.clear();
                              _policeStationsEnglish.clear();
                              _circles.clear();
                            });
                            // Load circles for selected SDPO
                            _loadCirclesForSubDivision();
                         }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return validationMsg;
                        }
                        return null;
                      },
                      isExpanded: true,
                    );
                  },
                ),
                const SizedBox(height: 16),
            ],

            // Dynamic Circle Dropdown
            if (_circles.isNotEmpty || _isLoadingCircles) ...[
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
                        suffixIcon: _isLoadingCircles
                          ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                          : null,
                      ),
                      items: _circles
                          .map((circleEnglish) {
                            final localizedName = DistrictTranslations.getCircleName(context, circleEnglish);
                            return DropdownMenuItem(
                              value: circleEnglish, // Store English name
                              child: Text(
                                localizedName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (value) {
                        if (value != _selectedCircle) {
                          setState(() {
                            _selectedCircle = value;
                            _selectedPoliceStation = null;
                            _policeStationSearchController.clear();
                          });
                          // Load police stations for selected circle
                          _loadPoliceStationsForCircle();
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty || value == '-') {
                          return validationMsg;
                        }
                        return null;
                      },
                      isExpanded: true,
                    );
                  },
                ),
                const SizedBox(height: 16),
            ],
            const SizedBox(height: 16),
            // Police Station Searchable Dropdown
            _buildSearchableDropdown<String>(
              label: '${localizations.policeStation} *',
              hint: _getLocalizedLabel('Search police station...', 'పోలీస్ స్టేషన్‌ను శోధించండి...'),
              icon: Icons.local_police,
              value: _selectedPoliceStation,
              items: _policeStationsEnglish,
              searchController: _policeStationSearchController,
              getDisplayText: (stationEnglish) => DistrictTranslations.getLocalizedPoliceStationName(
                context,
                stationEnglish,
              ),
              onChanged: (value) {
                setState(() {
                  _selectedPoliceStation = value; // Store English name
                  _policeStationSearchController.clear();
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a Police Station';
                }
                return null;
              },
              emptyMessage: _selectedDistrict == null
                  ? _getLocalizedLabel('Please select a district first', 'దయచేసి ముందు జిల్లాను ఎంచుకోండి')
                  : _isLoadingPoliceStations
                      ? localizations.loading
                      : _policeStationLoadError ?? _getLocalizedLabel(
                          'No police stations found',
                          'పోలీస్ స్టేషన్లు కనుగొనబడలేదు',
                        ),
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
                labelText: localizations.dayOfOccurrence,
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
                  labelText: localizations.dateTimeFrom,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _occurrenceDateTimeFrom != null
                      ? DateFormat('dd-MM-yyyy HH:mm').format(_occurrenceDateTimeFrom!)
                      : localizations.selectDateAndTime,
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
                  labelText: localizations.dateTimeTo,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _occurrenceDateTimeTo != null
                      ? DateFormat('dd-MM-yyyy HH:mm').format(_occurrenceDateTimeTo!)
                      : localizations.selectDateAndTime,
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
                labelText: localizations.timePeriod,
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
                labelText: localizations.priorToDateTimeDetails,
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
                labelText: localizations.beatNumber,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 24),
            // Place of Occurrence sub-heading
            Text(
              localizations.placeOfOccurrence,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Street/Village
            TextFormField(
              controller: _streetVillageController,
              decoration: InputDecoration(
                labelText: localizations.streetVillage,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Auto-fill Mandal and District',
                  onPressed: () => _autoFillMandalAndDistrict(),
                ),
                helperText: _getLocalizedLabel(
                  'Type village name and click search icon to auto-fill Mandal & District',
                  'గ్రామం పేరు టైప్ చేసి, మండలం & జిల్లాను స్వయంచాలకంగా నింపడానికి శోధన చిహ్నంపై క్లిక్ చేయండి',
                ),
                helperMaxLines: 2,
              ),
              onChanged: (value) {
                // Auto-fill when user finishes typing (after a delay)
                if (value.isNotEmpty && value.length >= 3) {
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (_streetVillageController.text == value && mounted) {
                      _autoFillMandalAndDistrict();
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // Area/Mandal
            TextFormField(
              controller: _areaMandalController,
              decoration: InputDecoration(
                labelText: localizations.areaMandal,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 16),
            // City/District
            TextFormField(
              controller: _cityDistrictController,
              decoration: InputDecoration(
                labelText: localizations.cityDistrict,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 16),
            // State
            TextFormField(
              controller: _stateController,
              decoration: InputDecoration(
                labelText: localizations.state,
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
                labelText: localizations.pin,
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
                labelText: localizations.latitude,
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
                labelText: localizations.longitude,
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
              _getLocalizedLabel(
                'Distance & Direction from PS:',
                'PS నుండి దూరం & దిశ:',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Distance from PS
            TextFormField(
              controller: _distanceFromPSController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Distance from PS',
                  'PS నుండి దూరం',
                ),
                hintText: _getLocalizedLabel(
                  'E.g., 1km',
                  'ఉదా., 1km',
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.straighten),
              ),
            ),
            const SizedBox(height: 16),
            // Direction from PS
            TextFormField(
              controller: _directionFromPSController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Direction from PS',
                  'PS నుండి దిశ',
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.explore),
              ),
            ),
            const SizedBox(height: 24),
            // Outside Jurisdiction section
            Text(
              _getLocalizedLabel(
                'Outside Jurisdiction:',
                'అధికార పరిధి వెలుపల:',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(_getLocalizedLabel(
                'Is Outside Jurisdiction?',
                'అధికార పరిధి వెలుపల ఉందా?',
              )),
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
              _getLocalizedLabel(
                '3. Information Received',
                '3. సమాచారం అందింది',
              ),
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
                decoration: InputDecoration(
                  labelText: _getLocalizedLabel(
                    'Date/Time Received at PS',
                    'PS వద్ద అందిన తేదీ/సమయం',
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.access_time),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _informationReceivedAtPs != null
                      ? DateFormat('dd-MM-yyyy HH:mm').format(_informationReceivedAtPs!)
                      : _getLocalizedLabel(
                          'Select date and time',
                          'తేదీ మరియు సమయాన్ని ఎంచుకోండి',
                        ),
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
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'General Diary Entry No.',
                  'సాధారణ డైరీ ఎంట్రీ నం.',
                ),
                hintText: _getLocalizedLabel(
                  'E.g., 40',
                  'ఉదా., 40',
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _getLocalizedLabel(
                '4. Type of Information',
                '4. సమాచారం రకం',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            // Type of Information
            DropdownButtonFormField<String>(
              value: _selectedInformationType,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Type',
                  'రకం',
                ),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Oral',
                  child: Text(_getLocalizedLabel('Oral', 'మౌఖిక')),
                ),
                DropdownMenuItem(
                  value: 'Written',
                  child: Text(_getLocalizedLabel('Written', 'లిఖిత')),
                ),
                DropdownMenuItem(
                  value: 'Phone',
                  child: Text(_getLocalizedLabel('Phone', 'ఫోన్')),
                ),
                DropdownMenuItem(
                  value: 'Email',
                  child: Text(_getLocalizedLabel('Email', 'ఇమెయిల్')),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text(_getLocalizedLabel('Other', 'ఇతర')),
                ),
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
                _getLocalizedLabel(
                  '6. Accused Details',
                  '6. నిందితుడి వివరాలు',
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addAccused,
                icon: const Icon(Icons.add),
                label: Text(_getLocalizedLabel(
                  'Add Accused',
                  'నిందితుడిని జోడించండి',
                )),
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
                          _getLocalizedLabel(
                            'Accused $serialNo',
                            'నిందితుడు $serialNo',
                          ),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        if (_accusedList.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            tooltip: _getLocalizedLabel(
                              'Delete Accused',
                              'నిందితుడిని తొలగించండి',
                            ),
                            onPressed: () => _removeAccused(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Serial No.
                    TextFormField(
                      initialValue: serialNo.toString(),
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Serial No.',
                          'సీరియల్ నం.',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    TextFormField(
                      controller: data.name,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Name',
                          'పేరు',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Father's/Husband's Name
                    TextFormField(
                      controller: data.fatherName,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          "Father's/Husband's Name",
                          "తండ్రి/భర్త పేరు",
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Gender
                    DropdownButtonFormField<String>(
                      value: data.gender,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Gender',
                          'లింగం',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text(_getLocalizedLabel('Male', 'పురుషుడు')),
                        ),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text(_getLocalizedLabel('Female', 'స్త్రీ')),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text(_getLocalizedLabel('Other', 'ఇతర')),
                        ),
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
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Age',
                          'వయస్సు',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nationality
                    TextFormField(
                      controller: data.nationality,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Nationality',
                          'జాతీయత',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Caste
                    TextFormField(
                      controller: data.caste,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Caste',
                          'కులం',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Occupation
                    TextFormField(
                      controller: data.occupation,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Occupation',
                          'వృత్తి',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cell No.
                    TextFormField(
                      controller: data.cellNo,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Cell No.',
                          'సెల్ నం.',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextFormField(
                      controller: data.email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Email',
                          'ఇమెయిల్',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Accused Address
                    Text(
                      _getLocalizedLabel(
                        'Accused Address:',
                        'నిందితుడి చిరునామా:',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.houseNo,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'House No.',
                          'ఇంటి నం.',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.street,
                      decoration: InputDecoration(
                        labelText: localizations.streetVillage,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: _getLocalizedLabel(
                            'Auto-fill Mandal and District',
                            'మండలం మరియు జిల్లాను స్వయంచాలకంగా నింపండి',
                          ),
                          onPressed: () => _autoFillAccusedMandalAndDistrict(data),
                        ),
                        helperText: _getLocalizedLabel(
                          'Type village name and click search icon to auto-fill Mandal & District',
                          'గ్రామం పేరు టైప్ చేసి, మండలం & జిల్లాను స్వయంచాలకంగా నింపడానికి శోధన చిహ్నంపై క్లిక్ చేయండి',
                        ),
                        helperMaxLines: 2,
                      ),
                      onChanged: (value) {
                        // Auto-fill when user finishes typing (after a delay)
                        if (value.isNotEmpty && value.length >= 3) {
                          Future.delayed(const Duration(milliseconds: 1500), () {
                            if (data.street.text == value && mounted) {
                              _autoFillAccusedMandalAndDistrict(data);
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.area,
                      decoration: InputDecoration(
                        labelText: localizations.areaMandal,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.map),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.city,
                      decoration: InputDecoration(
                        labelText: localizations.cityDistrict,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.state,
                      decoration: InputDecoration(
                        labelText: localizations.state,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.pin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: localizations.pin,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Physical Features
                    Text(
                      _getLocalizedLabel(
                        'Physical Features:',
                        'శారీరక లక్షణాలు:',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.build,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Build',
                          'నిర్మాణం',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.heightCms,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Height (cms)',
                          'ఎత్తు (సెం.మీ)',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.complexion,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Complexion',
                          'రంగు',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: data.deformities,
                      decoration: InputDecoration(
                        labelText: _getLocalizedLabel(
                          'Deformities/Peculiarities',
                          'వైకల్యాలు/ప్రత్యేకతలు',
                        ),
                        border: const OutlineInputBorder(),
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
              _getLocalizedLabel(
                '7. Properties Involved',
                '7. ప్రమేయం ఉన్న ఆస్తులు',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _propertiesDetailsController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Details of Properties Stolen/Involved',
                  'దొంగిలించబడిన/ప్రమేయం ఉన్న ఆస్తుల వివరాలు',
                ),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _propertiesTotalValueController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Total Value of Properties Stolen (INR)',
                  'దొంగిలించబడిన ఆస్తుల మొత్తం విలువ (INR)',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            // 8. Delay in Reporting (if any)
            Text(
              _getLocalizedLabel(
                '8. Delay in Reporting (if any)',
                '8. నివేదించడంలో ఆలస్యం (ఏదైనా ఉంటే)',
              ),
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
              title: Text(_getLocalizedLabel(
                'Was there a delay in reporting?',
                'నివేదించడంలో ఆలస్యం ఉందా?',
              )),
            ),
            const SizedBox(height: 32),
            // 9. Inquest Report / U.D. Case No. (if any)
            Text(
              _getLocalizedLabel(
                '9. Inquest Report / U.D. Case No. (if any)',
                '9. విచారణ నివేదిక / U.D. కేసు నం. (ఏదైనా ఉంటే)',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _inquestReportCaseNoController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Inquest Report / U.D. Case No.',
                  'విచారణ నివేదిక / U.D. కేసు నం.',
                ),
                border: const OutlineInputBorder(),
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
              _getLocalizedLabel(
                'Acts & Sections Involved',
                'ప్రమేయం ఉన్న చట్టాలు & సెక్షన్లు',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actsAndSectionsController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Acts & Sections (comma-separated or detailed)',
                  'చట్టాలు & సెక్షన్లు (కామా-విభజించబడిన లేదా వివరణాత్మకం)',
                ),
                hintText: _getLocalizedLabel(
                  'E.g., IPC 379, BNS 101',
                  'ఉదా., IPC 379, BNS 101',
                ),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            // Complaint / Statement
            Text(
              _getLocalizedLabel(
                '10. Complaint / Statement of Complainant/Informant *',
                '10. ఫిర్యాదు / ఫిర్యాదుదారు/సమాచారదాత ప్రకటన *',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _getLocalizedLabel(
                'Detailed Narrative',
                'వివరణాత్మక కథనం',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _complaintNarrativeController,
              decoration: InputDecoration(
                hintText: _getLocalizedLabel(
                  'AI Suggestion: Draft complaint based on the original conversation.',
                  'ఏఐ సూచన: అసలు సంభాషణ ఆధారంగా ఫిర్యాదును రూపొందించండి.',
                ),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
            ),
            const SizedBox(height: 32),
            // Victim Details
            Row(
              children: [
                Text(
                  _getLocalizedLabel(
                    'Victim Details',
                    'బాధితుడు వివరాలు',
                  ),
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
                      if (value == true) {
                        // Copy complainant details to victim details
                        _copyComplainantToVictim();
                      }
                    });
                  },
                ),
                Text(_getLocalizedLabel(
                  'Complainant is also the Victim',
                  'ఫిర్యాదుదారు కూడా బాధితుడు',
                )),
              ],
            ),
            const SizedBox(height: 16),
            // Victim Name
            TextFormField(
              controller: _victimNameController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Victim Name',
                  'బాధితుడు పేరు',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim DOB
            InkWell(
              onTap: _selectVictimDob,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _getLocalizedLabel(
                    'Victim DOB',
                    'బాధితుడు పుట్టిన తేదీ',
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _victimDob != null
                      ? DateFormat('dd-MM-yyyy').format(_victimDob!)
                      : _getLocalizedLabel(
                          'Select date',
                          'తేదీని ఎంచుకోండి',
                        ),
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
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Victim Age (auto-calculated)',
                  'బాధితుడు వయస్సు (స్వయంచాలకంగా లెక్కించబడింది)',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Gender
            DropdownButtonFormField<String>(
              value: _selectedVictimGender,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Victim Gender',
                  'బాధితుడు లింగం',
                ),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Male',
                  child: Text(_getLocalizedLabel('Male', 'పురుషుడు')),
                ),
                DropdownMenuItem(
                  value: 'Female',
                  child: Text(_getLocalizedLabel('Female', 'స్త్రీ')),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text(_getLocalizedLabel('Other', 'ఇతర')),
                ),
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
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  "Victim Father's/Husband's Name",
                  "బాధితుడు తండ్రి/భర్త పేరు",
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Nationality
            TextFormField(
              controller: _victimNationalityController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Victim Nationality',
                  'బాధితుడు జాతీయత',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Religion
            TextFormField(
              controller: _victimReligionController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Victim Religion',
                  'బాధితుడు మతం',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Caste
            TextFormField(
              controller: _victimCasteController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Victim Caste',
                  'బాధితుడు కులం',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Victim Occupation
            TextFormField(
              controller: _victimOccupationController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Victim Occupation',
                  'బాధితుడు వృత్తి',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Victim Address
            Text(
              _getLocalizedLabel(
                'Victim Address:',
                'బాధితుడు చిరునామా:',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimHouseNoController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'House No.',
                  'ఇంటి నం.',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimStreetController,
              decoration: InputDecoration(
                labelText: localizations.streetVillage,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimAreaController,
              decoration: InputDecoration(
                labelText: localizations.areaMandal,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimCityController,
              decoration: InputDecoration(
                labelText: localizations.cityDistrict,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimStateController,
              decoration: InputDecoration(
                labelText: localizations.state,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _victimPinController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localizations.pin,
                border: const OutlineInputBorder(),
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
              _getLocalizedLabel(
                '11. Action Taken',
                '11. తీసుకున్న చర్య',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _getLocalizedLabel(
                'Action Taken (Details)',
                'తీసుకున్న చర్య (వివరాలు)',
              ),
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
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Investigating Officer Name',
                  'దర్యాప్తు అధికారి పేరు',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ioRankController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Officer Rank',
                  'అధికారి ర్యాంక్',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ioDistrictController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'District (of officer)',
                  'జిల్లా (అధికారి)',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            // 12. Dispatch to Court
            Text(
              _getLocalizedLabel(
                '12. Dispatch to Court',
                '12. కోర్టుకు పంపడం',
              ),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectDispatchDateTime,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _getLocalizedLabel(
                    'Date/Time of Dispatch',
                    'పంపిన తేదీ/సమయం',
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _dispatchDateTime != null
                      ? DateFormat('dd-MM-yyyy HH:mm').format(_dispatchDateTime!)
                      : _getLocalizedLabel(
                          'Select date and time',
                          'తేదీ మరియు సమయాన్ని ఎంచుకోండి',
                        ),
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
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Name of Officer',
                  'అధికారి పేరు',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dispatchOfficerRankController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Rank of Officer',
                  'అధికారి ర్యాంక్',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            // 13. Confirmation
            Text(
              _getLocalizedLabel(
                '13. Confirmation',
                '13. నిర్ధారణ',
              ),
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
              title: Text(_getLocalizedLabel(
                'FIR read over and admitted correct by Complainant/Informant',
                'ఫిర్యాదుదారు/సమాచారదాత చేత FIR చదవబడి మరియు సరైనదిగా అంగీకరించబడింది',
              )),
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
              title: Text(_getLocalizedLabel(
                'Copy of FIR given to Complainant/Informant free of cost',
                'ఫిర్యాదుదారు/సమాచారదాతకు ఖర్చు లేకుండా FIR కాపీ ఇవ్వబడింది',
              )),
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
              title: Text(_getLocalizedLabel(
                'ROAC (Recorded Over & Admitted Correct)',
                'ROAC (రికార్డ్ చేయబడింది & సరైనదిగా అంగీకరించబడింది)',
              )),
            ),
            const SizedBox(height: 16),
            Text(
              _getLocalizedLabel(
                "Signature/Thumb Impression of Complainant/Informant (Enter 'Digitally Signed' or path if applicable)",
                "ఫిర్యాదుదారు/సమాచారదాత సంతకం/బొటనవేలు ముద్ర (వర్తించినట్లయితే 'డిజిటల్‌గా సంతకం చేయబడింది' లేదా మార్గాన్ని నమోదు చేయండి)",
              ),
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
              _getLocalizedLabel(
                '5. Complainant / Informant Details',
                '5. ఫిర్యాదుదారు / సమాచారం అందించినవారి వివరాలు',
              ),
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
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  "Father's/Husband's Name",
                  "తండ్రి/భర్త పేరు",
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            // Gender
            DropdownButtonFormField<String>(
              value: _selectedComplainantGender,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Gender',
                  'లింగం',
                ),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Male',
                  child: Text(_getLocalizedLabel('Male', 'పురుషుడు')),
                ),
                DropdownMenuItem(
                  value: 'Female',
                  child: Text(_getLocalizedLabel('Female', 'స్త్రీ')),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text(_getLocalizedLabel('Other', 'ఇతర')),
                ),
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
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Nationality',
                  'జాతీయత',
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.flag),
              ),
            ),
            const SizedBox(height: 16),
            // Caste
            TextFormField(
              controller: _casteController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Caste',
                  'కులం',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Occupation
            TextFormField(
              controller: _occupationController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Occupation',
                  'వృత్తి',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Date of Birth
            InkWell(
              onTap: _selectComplainantDob,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _getLocalizedLabel(
                    'Date of Birth',
                    'పుట్టిన తేదీ',
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.cake),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _complainantDob != null
                      ? DateFormat('dd-MM-yyyy').format(_complainantDob!)
                      : _getLocalizedLabel(
                          'Select date',
                          'తేదీని ఎంచుకోండి',
                        ),
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
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Age (auto-calculated)',
                  'వయస్సు (స్వయంచాలకంగా లెక్కించబడింది)',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Mobile Number
            TextFormField(
              controller: _mobileNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Mobile Number',
                  'మొబైల్ నంబర్',
                ),
                hintText: _getLocalizedLabel(
                  '10 digits',
                  '10 అంకెలు',
                ),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 24),
            // Complainant Address
            Text(
              _getLocalizedLabel(
                'Complainant Address:',
                'ఫిర్యాదుదారు చిరునామా:',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantHouseNoController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'House No.',
                  'ఇంటి నం.',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantStreetController,
              decoration: InputDecoration(
                labelText: localizations.streetVillage,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: _getLocalizedLabel(
                    'Auto-fill Mandal and District',
                    'మండలం మరియు జిల్లాను స్వయంచాలకంగా నింపండి',
                  ),
                  onPressed: () => _autoFillComplainantMandalAndDistrict(),
                ),
                helperText: _getLocalizedLabel(
                  'Type village name and click search icon to auto-fill Mandal & District',
                  'గ్రామం పేరు టైప్ చేసి, మండలం & జిల్లాను స్వయంచాలకంగా నింపడానికి శోధన చిహ్నంపై క్లిక్ చేయండి',
                ),
                helperMaxLines: 2,
              ),
              onChanged: (value) {
                // Auto-fill when user finishes typing (after a delay)
                if (value.isNotEmpty && value.length >= 3) {
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (_complainantStreetController.text == value && mounted) {
                      _autoFillComplainantMandalAndDistrict();
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantAreaController,
              decoration: InputDecoration(
                labelText: localizations.areaMandal,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantCityController,
              decoration: InputDecoration(
                labelText: localizations.cityDistrict,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantStateController,
              decoration: InputDecoration(
                labelText: localizations.state,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantPinController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: localizations.pin,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Complainant Passport (Optional)
            Text(
              _getLocalizedLabel(
                'Complainant Passport (Optional):',
                'ఫిర్యాదుదారు పాస్పోర్ట్ (ఐచ్ఛికం):',
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantPassportNumberController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Passport No.',
                  'పాస్పోర్ట్ నం.',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _complainantPassportPlaceController,
              decoration: InputDecoration(
                labelText: _getLocalizedLabel(
                  'Place of Issue',
                  'జారీ చేసిన ప్రదేశం',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectComplainantPassportDateOfIssue,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _getLocalizedLabel(
                    'Date of Issue',
                    'జారీ చేసిన తేదీ',
                  ),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.event),
                  suffixIcon: const Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _complainantPassportDateOfIssue != null
                      ? DateFormat('dd-MM-yyyy').format(_complainantPassportDateOfIssue!)
                      : _getLocalizedLabel(
                          'Select date',
                          'తేదీని ఎంచుకోండి',
                        ),
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
                _getLocalizedLabel(
                  "Father's/Husband's Name",
                  "తండ్రి/భర్త పేరు",
                ),
                _fatherHusbandNameController.text,
                Icons.person_outline,
              ),
            ],
            if (_selectedComplainantGender != null &&
                _selectedComplainantGender!.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Gender',
                  'లింగం',
                ),
                _getLocalizedGender(_selectedComplainantGender!),
                Icons.wc,
              ),
            ],
            if (_nationalityController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Nationality',
                  'జాతీయత',
                ),
                _nationalityController.text,
                Icons.flag,
              ),
            ],
            if (_casteController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Caste',
                  'కులం',
                ),
                _casteController.text,
                Icons.assignment_ind,
              ),
            ],
            if (_occupationController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Occupation',
                  'వృత్తి',
                ),
                _occupationController.text,
                Icons.work,
              ),
            ],
            if (_complainantDob != null) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Date of Birth',
                  'పుట్టిన తేదీ',
                ),
                DateFormat('dd-MM-yyyy').format(_complainantDob!),
                Icons.cake,
              ),
            ],
            if (_ageController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Age',
                  'వయస్సు',
                ),
                _ageController.text,
                Icons.accessibility_new,
              ),
            ],
            if (_mobileNumberController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Mobile Number',
                  'మొబైల్ నంబర్',
                ),
                _mobileNumberController.text,
                Icons.phone,
              ),
            ],
            if (_victimNameController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Victim Name',
                  'బాధితుడు పేరు',
                ),
                _victimNameController.text,
                Icons.person,
              ),
            ],
            if (_victimDob != null) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Victim DOB',
                  'బాధితుడు పుట్టిన తేదీ',
                ),
                DateFormat('dd-MM-yyyy').format(_victimDob!),
                Icons.cake,
              ),
            ],
            if (_victimAgeController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Victim Age',
                  'బాధితుడు వయస్సు',
                ),
                _victimAgeController.text,
                Icons.accessibility_new,
              ),
            ],
            if (_selectedVictimGender != null &&
                _selectedVictimGender!.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Victim Gender',
                  'బాధితుడు లింగం',
                ),
                _getLocalizedGender(_selectedVictimGender!),
                Icons.wc,
              ),
            ],
            if (_victimFatherNameController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  "Victim Father's/Husband's Name",
                  "బాధితుడు తండ్రి/భర్త పేరు",
                ),
                _victimFatherNameController.text,
                Icons.person_outline,
              ),
            ],
            if (_victimNationalityController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Victim Nationality',
                  'బాధితుడు జాతీయత',
                ),
                _victimNationalityController.text,
                Icons.flag,
              ),
            ],
            if (_victimReligionController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Victim Religion',
                  'బాధితుడు మతం',
                ),
                _victimReligionController.text,
                Icons.account_balance,
              ),
            ],
            if (_victimCasteController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Victim Caste',
                  'బాధితుడు కులం',
                ),
                _victimCasteController.text,
                Icons.assignment_ind,
              ),
            ],
            if (_victimOccupationController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Victim Occupation',
                  'బాధితుడు వృత్తి',
                ),
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
                _getLocalizedLabel(
                  'Victim Address',
                  'బాధితుడు చిరునామా',
                ),
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
              _getLocalizedLabel(
                'Complainant is also the Victim',
                'ఫిర్యాదుదారు కూడా బాధితుడు',
              ),
              (_isComplainantAlsoVictim ?? false) 
                  ? _getLocalizedLabel('Yes', 'అవును')
                  : _getLocalizedLabel('No', 'కాదు'),
              Icons.people_alt,
            ),
            if (_actionTakenDetailsController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Action Taken',
                  'తీసుకున్న చర్య',
                ),
                _actionTakenDetailsController.text,
                Icons.fact_check,
                isMultiline: true,
              ),
            ],
            if (_ioNameController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Investigating Officer Name',
                  'దర్యాప్తు అధికారి పేరు',
                ),
                _ioNameController.text,
                Icons.person,
              ),
            ],
            if (_ioRankController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Investigating Officer Rank',
                  'దర్యాప్తు అధికారి ర్యాంక్',
                ),
                _ioRankController.text,
                Icons.badge,
              ),
            ],
            if (_ioDistrictController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Investigating Officer District',
                  'దర్యాప్తు అధికారి జిల్లా',
                ),
                _ioDistrictController.text,
                Icons.location_city,
              ),
            ],
            if (_dispatchDateTime != null) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Date/Time of Dispatch',
                  'పంపిన తేదీ/సమయం',
                ),
                DateFormat('dd-MM-yyyy HH:mm').format(_dispatchDateTime!),
                Icons.schedule_send,
              ),
            ],
            if (_dispatchOfficerNameController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Dispatch Officer Name',
                  'పంపిన అధికారి పేరు',
                ),
                _dispatchOfficerNameController.text,
                Icons.person_outline,
              ),
            ],
            if (_dispatchOfficerRankController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Dispatch Officer Rank',
                  'పంపిన అధికారి ర్యాంక్',
                ),
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
                _getLocalizedLabel(
                  'Complainant Address',
                  'ఫిర్యాదుదారు చిరునామా',
                ),
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
                _getLocalizedLabel(
                  'Passport No.',
                  'పాస్పోర్ట్ నం.',
                ),
                _complainantPassportNumberController.text,
                Icons.badge,
              ),
            ],
            if (_complainantPassportPlaceController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Passport Place of Issue',
                  'పాస్పోర్ట్ జారీ చేసిన ప్రదేశం',
                ),
                _complainantPassportPlaceController.text,
                Icons.place,
              ),
            ],
            if (_complainantPassportDateOfIssue != null) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Passport Date of Issue',
                  'పాస్పోర్ట్ జారీ చేసిన తేదీ',
                ),
                DateFormat('dd-MM-yyyy').format(_complainantPassportDateOfIssue!),
                Icons.event,
              ),
            ],
            if (_actsAndSectionsController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Acts & Sections Involved',
                  'ప్రమేయం ఉన్న చట్టాలు & సెక్షన్లు',
                ),
                _actsAndSectionsController.text,
                Icons.gavel,
                isMultiline: true,
              ),
            ],
            if (_complaintNarrativeController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Complaint / Statement',
                  'ఫిర్యాదు / ప్రకటన',
                ),
                _complaintNarrativeController.text,
                Icons.description,
                isMultiline: true,
              ),
            ],
            // Properties involved
            if (_propertiesDetailsController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Details of Properties Stolen/Involved',
                  'దొంగిలించబడిన/ప్రమేయం ఉన్న ఆస్తుల వివరాలు',
                ),
                _propertiesDetailsController.text,
                Icons.inventory_2,
                isMultiline: true,
              ),
            ],
            if (_propertiesTotalValueController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Total Value of Properties Stolen (INR)',
                  'దొంగిలించబడిన ఆస్తుల మొత్తం విలువ (INR)',
                ),
                _propertiesTotalValueController.text,
                Icons.currency_rupee,
              ),
            ],
            // Delay in reporting
            const Divider(),
            _buildReviewItem(
              _getLocalizedLabel(
                'Delay in Reporting',
                'నివేదించడంలో ఆలస్యం',
              ),
              _isDelayInReporting 
                  ? _getLocalizedLabel('Yes', 'అవును')
                  : _getLocalizedLabel('No', 'కాదు'),
              Icons.schedule,
            ),
            // Inquest report
            if (_inquestReportCaseNoController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Inquest Report / U.D. Case No.',
                  'విచారణ నివేదిక / U.D. కేసు నం.',
                ),
                _inquestReportCaseNoController.text,
                Icons.description_outlined,
              ),
            ],
            // Information received
            if (_informationReceivedAtPs != null) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Date/Time Received at PS',
                  'PS వద్ద అందిన తేదీ/సమయం',
                ),
                DateFormat('dd-MM-yyyy HH:mm').format(_informationReceivedAtPs!),
                Icons.access_time,
              ),
            ],
            if (_generalDiaryEntryNumberController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'General Diary Entry No.',
                  'సాధారణ డైరీ ఎంట్రీ నం.',
                ),
                _generalDiaryEntryNumberController.text,
                Icons.book,
              ),
            ],
            if (_selectedInformationType != null &&
                _selectedInformationType!.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Type of Information',
                  'సమాచారం రకం',
                ),
                _getLocalizedInformationType(_selectedInformationType!),
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
                _getLocalizedLabel(
                  'Distance from PS',
                  'PS నుండి దూరం',
                ),
                _distanceFromPSController.text,
                Icons.straighten,
              ),
            ],
            if (_directionFromPSController.text.isNotEmpty) ...[
              const Divider(),
              _buildReviewItem(
                _getLocalizedLabel(
                  'Direction from PS',
                  'PS నుండి దిశ',
                ),
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
                          _getLocalizedLabel(
                            'Outside Jurisdiction',
                            'అధికార పరిధి వెలుపల',
                          ),
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
                  physicalLines.add('${_getLocalizedLabel('Build', 'నిర్మాణం')}: ${data.build.text}');
                }
                if (data.heightCms.text.trim().isNotEmpty) {
                  physicalLines.add('${_getLocalizedLabel('Height', 'ఎత్తు')}: ${data.heightCms.text} ${_getLocalizedLabel('cms', 'సెం.మీ')}');
                }
                if (data.complexion.text.trim().isNotEmpty) {
                  physicalLines.add('${_getLocalizedLabel('Complexion', 'రంగు')}: ${data.complexion.text}');
                }
                if (data.deformities.text.trim().isNotEmpty) {
                  physicalLines.add('${_getLocalizedLabel('Deformities/Peculiarities', 'వైకల్యాలు/ప్రత్యేకతలు')}: ${data.deformities.text}');
                }

                return <Widget>[
                  if (data.name.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      _getLocalizedLabel(
                        'Accused $serialNo Name',
                        'నిందితుడు $serialNo పేరు',
                      ),
                      data.name.text,
                      Icons.person_outline,
                    ),
                  ],
                  if (data.fatherName.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      _getLocalizedLabel(
                        "Accused $serialNo Father's/Husband's Name",
                        "నిందితుడు $serialNo తండ్రి/భర్త పేరు",
                      ),
                      data.fatherName.text,
                      Icons.person_outline,
                    ),
                  ],
                  if (data.gender != null && data.gender!.isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      _getLocalizedLabel(
                        'Accused $serialNo Gender',
                        'నిందితుడు $serialNo లింగం',
                      ),
                      _getLocalizedGender(data.gender!),
                      Icons.wc,
                    ),
                  ],
                  if (data.age.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      _getLocalizedLabel(
                        'Accused $serialNo Age',
                        'నిందితుడు $serialNo వయస్సు',
                      ),
                      data.age.text,
                      Icons.accessibility_new,
                    ),
                  ],
                  if (data.occupation.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      _getLocalizedLabel(
                        'Accused $serialNo Occupation',
                        'నిందితుడు $serialNo వృత్తి',
                      ),
                      data.occupation.text,
                      Icons.work,
                    ),
                  ],
                  if (data.cellNo.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      _getLocalizedLabel(
                        'Accused $serialNo Cell No.',
                        'నిందితుడు $serialNo సెల్ నం.',
                      ),
                      data.cellNo.text,
                      Icons.phone_android,
                    ),
                  ],
                  if (data.email.text.trim().isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      _getLocalizedLabel(
                        'Accused $serialNo Email',
                        'నిందితుడు $serialNo ఇమెయిల్',
                      ),
                      data.email.text,
                      Icons.email,
                    ),
                  ],
                  if (address.isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      _getLocalizedLabel(
                        'Accused $serialNo Address',
                        'నిందితుడు $serialNo చిరునామా',
                      ),
                      address,
                      Icons.home,
                      isMultiline: true,
                    ),
                  ],
                  if (physicalLines.isNotEmpty) ...[
                    const Divider(),
                    _buildReviewItem(
                      _getLocalizedLabel(
                        'Accused $serialNo Physical Features',
                        'నిందితుడు $serialNo శారీరక లక్షణాలు',
                      ),
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
        title: Text(widget.existingCase != null 
            ? 'Edit Case' // Localize this later
            : localizations.createNewCase),
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
                        child: Text(localizations.previous),
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
                            child: Text(
                              localizations.next,
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
