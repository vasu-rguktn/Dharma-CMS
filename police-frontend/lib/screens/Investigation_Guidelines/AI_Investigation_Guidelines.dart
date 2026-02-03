import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/providers/police_auth_provider.dart';
import 'package:Dharma/data/station_data_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color orange = Color(0xFFFC633C);

class AiInvestigationGuidelinesScreen extends StatefulWidget {
  final String? caseId;

  const AiInvestigationGuidelinesScreen({
    super.key,
    this.caseId,
  });

  @override
  State<AiInvestigationGuidelinesScreen> createState() =>
      _AiInvestigationGuidelinesScreenState();
}

class _AiInvestigationGuidelinesScreenState
    extends State<AiInvestigationGuidelinesScreen> {
  final TextEditingController _caseIdController = TextEditingController();

  Petition? _petition;
  bool _fetchingPetition = false;
  bool _loadingAI = false;

  Map<String, dynamic>? _aiReport;

  // Police Profile Data
  String? _policeRank;
  String? _policeRange;
  String? _policeDistrict;
  String? _policeStation;

  // Filter selections
  String? _selectedRange;
  String? _selectedDistrict;
  String? _selectedStation;

  // Hierarchy data
  Map<String, Map<String, List<String>>> _policeHierarchy = {};
  bool _hierarchyLoading = true;

  // Filtered Petitions List
  List<Petition> _filteredPetitions = [];
  bool _loadingPetitions = false;

  /* ================= RANK TIERS ================= */
  
  static const List<String> _stateLevelRanks = [
    'Director General of Police',
    'Additional Director General of Police',
  ];

  static const List<String> _rangeLevelRanks = [
    'Inspector General of Police',
    'Deputy Inspector General of Police',
  ];

  static const List<String> _districtLevelRanks = [
    'Superintendent of Police',
    'Additional Superintendent of Police',
  ];

  static const List<String> _stationLevelRanks = [
    'Deputy Superintendent of Police',
    'Inspector of Police',
    'Sub Inspector of Police',
    'Assistant Sub Inspector of Police',
    'Head Constable',
    'Police Constable',
  ];

  // 🔗 Backend API
  final String _apiUrl =
      "https://fastapi-app-335340524683.asia-south1.run.app/api/ai-investigation/";

  @override
  void initState() {
    super.initState();
    _loadHierarchyData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
      if (widget.caseId != null && widget.caseId!.isNotEmpty) {
        _caseIdController.text = widget.caseId!;
        _fetchPetitionDetails();
      }
    });
  }

  Future<void> _loadProfile() async {
    final policeProvider = context.read<PoliceAuthProvider>();
    await policeProvider.loadPoliceProfileIfLoggedIn();
    
    final profile = policeProvider.policeProfile;

    if (profile != null && mounted) {
      setState(() {
        _policeRank = profile['rank']?.toString();
        _policeRange = profile['range']?.toString();
        _policeDistrict = profile['district']?.toString();
        _policeStation = profile['stationName']?.toString();
      });
      // After loading profile, fetch initial list of petitions if applicable
      _fetchPetitions();
    }
  }

  void _loadHierarchyData() {
    try {
      Map<String, Map<String, List<String>>> hierarchy = {};
      final data = kPoliceHierarchyComplete;
      
      data.forEach((range, districts) {
        if (districts is Map) {
          Map<String, List<String>> districtMap = {};
          districts.forEach((district, stations) {
            districtMap[district.toString()] = List<String>.from(stations ?? []);
          });
          hierarchy[range] = districtMap;
        }
      });

      if (mounted) {
        setState(() {
          _policeHierarchy = hierarchy;
          _hierarchyLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error parsing hierarchy constants: $e');
    }
  }

  /* ================= RANK-BASED FILTER VISIBILITY ================= */

  bool _canFilterByRange() => _policeRank != null && _stateLevelRanks.contains(_policeRank);
  bool _canFilterByDistrict() => _policeRank != null && (_stateLevelRanks.contains(_policeRank) || _rangeLevelRanks.contains(_policeRank));
  bool _canFilterByStation() => _policeRank != null && !_stationLevelRanks.contains(_policeRank);
  bool _isStationLevel() => _policeRank != null && _stationLevelRanks.contains(_policeRank);

  /* ================= HIERARCHY HELPERS ================= */

  List<String> _getAvailableRanges() => _policeHierarchy.keys.toList();

  List<String> _getAvailableDistricts() {
    if (_selectedRange != null) return _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
    if (_policeRange != null) return _policeHierarchy[_policeRange]?.keys.toList() ?? [];
    return [];
  }

  List<String> _getAvailableStations() {
    String? targetRange = _selectedRange ?? _policeRange;
    String? targetDistrict = _selectedDistrict ?? _policeDistrict;

    if (targetRange != null && targetDistrict != null) {
      return List.from(_policeHierarchy[targetRange]?[targetDistrict] ?? []);
    }
    return [];
  }

  void _onRangeChanged(String? range) {
    setState(() {
      _selectedRange = range;
      _selectedDistrict = null;
      _selectedStation = null;
    });
    _fetchPetitions();
  }

  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedStation = null;
    });
    _fetchPetitions();
  }

  void _onStationChanged(String? station) {
    setState(() {
      _selectedStation = station;
    });
    _fetchPetitions();
  }

  /* ---------------- FETCH PETITIONS LIST ---------------- */
  Future<void> _fetchPetitions() async {
    setState(() {
      _loadingPetitions = true;
    });

    try {
      // 1. Query 'petitions' (Online)
      Query<Map<String, dynamic>> onlineQuery = FirebaseFirestore.instance.collection('petitions');
      // 2. Query 'offlinepetitions' (Offline)
      Query<Map<String, dynamic>> offlineQuery = FirebaseFirestore.instance.collection('offlinepetitions');

      if (_isStationLevel() && _policeStation != null) {
        onlineQuery = onlineQuery.where('stationName', isEqualTo: _policeStation);
        offlineQuery = offlineQuery.where('stationName', isEqualTo: _policeStation);
      } else if (_selectedStation != null) {
        onlineQuery = onlineQuery.where('stationName', isEqualTo: _selectedStation);
        offlineQuery = offlineQuery.where('stationName', isEqualTo: _selectedStation);
      } else if (_selectedDistrict != null) {
        onlineQuery = onlineQuery.where('district', isEqualTo: _selectedDistrict);
        offlineQuery = offlineQuery.where('district', isEqualTo: _selectedDistrict);
      } else if (_selectedRange != null) {
        final districts = _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
        if (districts.isNotEmpty) {
          onlineQuery = onlineQuery.where('district', whereIn: districts.take(10).toList());
          offlineQuery = offlineQuery.where('district', whereIn: districts.take(10).toList());
        }
      } else if (_policeDistrict != null && !_canFilterByDistrict()) {
        onlineQuery = onlineQuery.where('district', isEqualTo: _policeDistrict);
        offlineQuery = offlineQuery.where('district', isEqualTo: _policeDistrict);
      }

      final onlineSnapshot = await onlineQuery.orderBy('createdAt', descending: true).limit(30).get();
      final offlineSnapshot = await offlineQuery.orderBy('createdAt', descending: true).limit(30).get();

      final onlinePetitions = onlineSnapshot.docs.map((d) => Petition.fromFirestore(d)).toList();
      final offlinePetitions = offlineSnapshot.docs.map((d) => Petition.fromFirestore(d)).toList();

      // Merge and sort
      final allPetitions = [...onlinePetitions, ...offlinePetitions];
      allPetitions.sort((a, b) {
        final dateA = a.createdAt?.toDate() ?? DateTime(2000);
        final dateB = b.createdAt?.toDate() ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _filteredPetitions = allPetitions;
          _loadingPetitions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching petitions: $e');
      if (mounted) {
        setState(() => _loadingPetitions = false);
      }
    }
  }

  /* ---------------- SEARCHABLE DROPDOWN ---------------- */
  Future<void> _openSearchableDropdown({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required void Function(String?) onSelected,
  }) async {
    final searchController = TextEditingController();
    List<String> filtered = List.from(items);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(hintText: 'Search...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                      onChanged: (value) {
                        setModalState(() {
                          filtered = items.where((e) => e.toLowerCase().contains(value.toLowerCase())).toList();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length + 1,
                      itemBuilder: (_, index) {
                        if (index == 0) {
                          return ListTile(
                            title: Text('All $title'),
                            trailing: selectedValue == null ? const Icon(Icons.check, color: Colors.green) : null,
                            onTap: () {
                              onSelected(null);
                              Navigator.pop(context);
                            },
                          );
                        }
                        final item = filtered[index - 1];
                        return ListTile(
                          title: Text(item),
                          trailing: item == selectedValue ? const Icon(Icons.check, color: Colors.green) : null,
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

  Widget _buildFilterPicker({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(value ?? 'Select...', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /* ---------------- FETCH PETITION ---------------- */
  Future<void> _fetchPetitionDetails() async {
    final caseId = _caseIdController.text.trim();
    if (caseId.isEmpty) {
      _showSnackbar('Please enter Case ID');
      return;
    }

    setState(() {
      _fetchingPetition = true;
      _petition = null;
      _aiReport = null;
    });

    try {
      final petitionProvider =
          Provider.of<PetitionProvider>(context, listen: false);

      final petition =
          await petitionProvider.fetchPetitionByCaseId(caseId);

      if (petition == null) {
        _showSnackbar('No petition found for Case ID: $caseId');
      } else {
        setState(() => _petition = petition);
      }
    } catch (e) {
      _showSnackbar('Error fetching petition');
    }

    setState(() => _fetchingPetition = false);
  }

  /* ---------------- BUILD FIR DETAILS ---------------- */
  String _buildFirDetails(Petition p) {
    final phoneDisplay = p.phoneNumber == null
        ? 'N/A'
        : (p.isAnonymous ? maskPhoneNumber(p.phoneNumber) : p.phoneNumber!);
    
    return '''
Case ID: ${p.caseId ?? 'N/A'}
Petition Title: ${p.title}
Petition Type: ${p.type.displayName}

Petitioner Name: ${p.petitionerName}
Phone Number: $phoneDisplay

District: ${p.district ?? 'N/A'}
Police Station: ${p.stationName ?? 'N/A'}

Incident Address:
${p.incidentAddress ?? 'N/A'}

Incident Date:
${p.incidentDate != null ? p.incidentDate!.toDate() : 'N/A'}

Complaint / Grounds:
${p.grounds}
''';
  }

  /* ---------------- GENERATE AI INVESTIGATION ---------------- */
  Future<void> _generateInvestigation() async {
    if (_petition == null) return;

    setState(() {
      _loadingAI = true;
      _aiReport = null;
    });

    final firDetails = _buildFirDetails(_petition!);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fir_id": _petition!.caseId,
          "fir_details": firDetails,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _aiReport = data["report"];
        });
      } else {
        _showSnackbar('AI generation failed');
      }
    } catch (e) {
      _showSnackbar(
          AppLocalizations.of(context)!.errorContactingInvestigationAI);
    }

    setState(() => _loadingAI = false);
  }

  /* ---------------- UI HELPERS ---------------- */
  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // 🎨 Build section cards
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor ?? Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor ?? Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 Build investigation tasks
  Widget _buildInvestigationTasks(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return const Text(
        "No tasks identified.",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Column(
      children: tasks.map((task) {
        final priority = task['priority']?.toString() ?? 'Routine';
        final isUrgent = priority.toLowerCase().contains('urgent');
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUrgent 
                ? Colors.red.shade50 
                : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUrgent 
                  ? Colors.red.shade300 
                  : Colors.blue.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task['task'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isUrgent 
                          ? Colors.red.shade100 
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUrgent 
                            ? Colors.red.shade900 
                            : Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🎨 Build applicable laws
  Widget _buildApplicableLaws(List<dynamic> laws) {
    if (laws.isEmpty) {
      return const Text(
        "No specific laws identified.",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Column(
      children: laws.map((law) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.gavel,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      law['section'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                law['justification'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🎨 Build list items
  Widget _buildListItems(List<dynamic> items, Color color) {
    if (items.isEmpty) {
      return const Text(
        "None identified.",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🎨 Build forensic suggestions
  Widget _buildForensicSuggestions(List<dynamic> suggestions) {
    if (suggestions.isEmpty) {
      return const Text(
        "No forensic suggestions.",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Column(
      children: suggestions.map((suggestion) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.science,
                    color: Colors.purple.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion['evidence_type'] ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                suggestion['protocol'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🎨 Build tags
  Widget _buildTags(List<dynamic> tags) {
    if (tags.isEmpty) {
      return const Text(
        "No tags.",
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: orange.withOpacity(0.3),
            ),
          ),
          child: Text(
            tag.toString(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: orange,
            ),
          ),
        );
      }).toList(),
    );
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/police-dashboard'),
        ),
        title: Text(
          AppLocalizations.of(context)!.aiInvestigationGuidelines,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [

      // 🔹 HIERARCHICAL FILTERS
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            if (_canFilterByRange()) ...[
              _buildFilterPicker(
                label: 'Filter by Range',
                value: _selectedRange,
                icon: Icons.location_city,
                onTap: () => _openSearchableDropdown(
                  title: 'Select Range',
                  items: _getAvailableRanges(),
                  selectedValue: _selectedRange,
                  onSelected: _onRangeChanged,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_canFilterByDistrict()) ...[
              _buildFilterPicker(
                label: 'Filter by District',
                value: _selectedDistrict,
                icon: Icons.map,
                onTap: () => _openSearchableDropdown(
                  title: 'Select District',
                  items: _getAvailableDistricts(),
                  selectedValue: _selectedDistrict,
                  onSelected: _onDistrictChanged,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_canFilterByStation()) ...[
              _buildFilterPicker(
                label: 'Filter by Police Station',
                value: _selectedStation,
                icon: Icons.local_police,
                onTap: () => _openSearchableDropdown(
                  title: 'Select Police Station',
                  items: _getAvailableStations(),
                  selectedValue: _selectedStation,
                  onSelected: _onStationChanged,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_isStationLevel() && _policeStation != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_police, color: orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Station: $_policeStation',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 🔹 PETITION SELECTION DROPDOWN
            DropdownButtonFormField<Petition>(
              isExpanded: true,
              value: _petition != null && _filteredPetitions.any((p) => p.id == _petition!.id) ? _filteredPetitions.firstWhere((p) => p.id == _petition!.id) : null,
              decoration: InputDecoration(
                labelText: 'Select Petition',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description, color: orange),
                hintText: _loadingPetitions ? 'Loading petitions...' : 'Choose a petition',
              ),
              items: _filteredPetitions.map((p) => DropdownMenuItem(
                value: p,
                child: Text('${p.caseId ?? "No ID"}: ${p.title}', overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (p) {
                setState(() {
                  _petition = p;
                  if (p != null) {
                    _caseIdController.text = p.caseId ?? '';
                  }
                  _aiReport = null; // Clear report when changing petition
                });
              },
            ),
            
            const SizedBox(height: 12),
            const Text('OR', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // 🔹 MANUAL CASE ID INPUT
            TextField(
              controller: _caseIdController,
              decoration: InputDecoration(
                labelText: 'Manual Case ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.edit, color: orange),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _fetchingPetition ? null : _fetchPetitionDetails,
              icon: _fetchingPetition
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: const Text('Load Petition'),
            ),
          ],
        ),
      ),

      // 🔹 PETITION DETAILS
      if (_petition != null) ...[
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _petition!.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _infoRow('Case ID', _petition!.caseId ?? 'N/A'),
                _infoRow('Type', _petition!.type.displayName),
                _infoRow('Petitioner', _petition!.petitionerName),
                _infoRow('District', _petition!.district ?? 'N/A'),
                _infoRow('Station', _petition!.stationName ?? 'N/A'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: orange,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _loadingAI ? null : _generateInvestigation,
          icon: _loadingAI
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.psychology, size: 24),
          label: const Text('Generate Investigation Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],

      // 🔹 AI REPORT (SCROLLS WITH ABOVE)
      if (_aiReport != null) ...[
        const SizedBox(height: 16),

        if (_aiReport!['summary'] != null)
          _buildSectionCard(
            title: 'Investigation Summary',
            icon: Icons.summarize,
            backgroundColor: Colors.orange.shade50.withOpacity(0.5),
            borderColor: orange.withOpacity(0.3),
            content: Text(
              _aiReport!['summary'],
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),

        if (_aiReport!['case_type_tags'] != null)
          _buildSectionCard(
            title: 'Case Type Tags',
            icon: Icons.label,
            backgroundColor: Colors.blue.shade50.withOpacity(0.5),
            borderColor: Colors.blue.shade200,
            content: _buildTags(_aiReport!['case_type_tags']),
          ),

        if (_aiReport!['modus_operandi_tags'] != null)
          _buildSectionCard(
            title: 'Modus Operandi Tags',
            icon: Icons.visibility,
            backgroundColor: Colors.indigo.shade50.withOpacity(0.5),
            borderColor: Colors.indigo.shade200,
            content: _buildTags(_aiReport!['modus_operandi_tags']),
          ),

        if (_aiReport!['investigation_tasks'] != null)
          _buildSectionCard(
            title: 'Investigation Tasks',
            icon: Icons.task_alt,
            backgroundColor: Colors.teal.shade50.withOpacity(0.5),
            borderColor: Colors.teal.shade200,
            content: _buildInvestigationTasks(
              _aiReport!['investigation_tasks'],
            ),
          ),

        if (_aiReport!['applicable_laws'] != null)
          _buildSectionCard(
            title: 'Applicable Laws',
            icon: Icons.gavel,
            backgroundColor: Colors.green.shade50.withOpacity(0.5),
            borderColor: Colors.green.shade200,
            content: _buildApplicableLaws(
              _aiReport!['applicable_laws'],
            ),
          ),

        if (_aiReport!['precautions_and_protocols'] != null)
          _buildSectionCard(
            title: 'Precautions & Protocols',
            icon: Icons.shield,
            backgroundColor: Colors.amber.shade50.withOpacity(0.5),
            borderColor: Colors.amber.shade200,
            content: _buildListItems(
              _aiReport!['precautions_and_protocols'],
              Colors.amber.shade700,
            ),
          ),

        if (_aiReport!['forensic_suggestions'] != null)
          _buildSectionCard(
            title: 'Forensic Suggestions',
            icon: Icons.science,
            backgroundColor: Colors.purple.shade50.withOpacity(0.5),
            borderColor: Colors.purple.shade200,
            content: _buildForensicSuggestions(
              _aiReport!['forensic_suggestions'],
            ),
          ),
      ],
    ],
  ),
),

    );
  }

  @override
  void dispose() {
    _caseIdController.dispose();
    super.dispose();
  }
}
