import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:Dharma/models/petition.dart';
import 'package:Dharma/models/petition_update.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/police_auth_provider.dart';
import 'package:Dharma/widgets/petition_update_timeline.dart';
import 'package:Dharma/widgets/add_petition_update_dialog.dart';

class PolicePetitionsScreen extends StatefulWidget {
  const PolicePetitionsScreen({super.key});

  @override
  State<PolicePetitionsScreen> createState() =>
      _PolicePetitionsScreenState();
}

class _PolicePetitionsScreenState extends State<PolicePetitionsScreen> {
  // Police Profile Data
  String? _policeRank;
  String? _policeRange;
  String? _policeDistrict;
  String? _policeStation;

  // Filter selections (for dynamic filtering based on rank)
  String? _selectedRange;
  String? _selectedDistrict;
  String? _selectedStation;

  // Standard filters
  String? _searchQuery = '';
  String? _selectedPoliceStatus;
  String? _selectedType;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedUrgency; // 'Escalated' or 'DGP Level'

  // Hierarchy data
  Map<String, Map<String, List<String>>> _policeHierarchy = {};
  bool _hierarchyLoading = true;

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

  /* ================= INIT ================= */

  @override
  void initState() {
    super.initState();
    _loadHierarchyData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final policeProvider = context.read<PoliceAuthProvider>();
    // Ensure profile is loaded
    await policeProvider.loadPoliceProfileIfLoggedIn();
    
    final profile = policeProvider.policeProfile;

    if (profile != null && mounted) {
      setState(() {
        _policeRank = profile['rank']?.toString();
        _policeRange = profile['range']?.toString();
        _policeDistrict = profile['district']?.toString();
        _policeStation = profile['stationName']?.toString();

        debugPrint('👮 Police Profile Loaded:');
        debugPrint('   Rank: $_policeRank');
        debugPrint('   Range: $_policeRange');
        debugPrint('   District: $_policeDistrict');
        debugPrint('   Station: $_policeStation');
      });
    }
  }

  /* ================= LOAD HIERARCHY ================= */

  Future<void> _loadHierarchyData() async {
    try {
      debugPrint('🔄 [Petitions] Loading police hierarchy data...');
      final jsonStr = await rootBundle
          .loadString('assets/data/ap_police_hierarchy_complete.json');
      final Map<String, dynamic> data = json.decode(jsonStr);

      Map<String, Map<String, List<String>>> hierarchy = {};
      int totalDistricts = 0;
      int totalStations = 0;
      
      data.forEach((range, districts) {
        if (districts is Map) {
          Map<String, List<String>> districtMap = {};
          districts.forEach((district, stations) {
            final stationList = List<String>.from(stations ?? []);
            districtMap[district.toString()] = stationList;
            totalDistricts++;
            totalStations += stationList.length;
          });
          hierarchy[range] = districtMap;
        }
      });

      setState(() {
        _policeHierarchy = hierarchy;
        _hierarchyLoading = false;
      });
      
      debugPrint('✅ [Petitions] Hierarchy loaded successfully!');
      debugPrint('   📊 Ranges: ${hierarchy.length}');
      debugPrint('   📊 Districts: $totalDistricts');
      debugPrint('   📊 Stations: $totalStations');
    } catch (e) {
      debugPrint('❌ [Petitions] Error loading hierarchy data: $e');
      setState(() => _hierarchyLoading = false);
    }
  }

  /* ================= RANK-BASED FILTER VISIBILITY ================= */

  bool _canFilterByRange() {
    if (_policeRank == null) return false;
    // DGP/Addl. DGP can filter by range
    return _stateLevelRanks.contains(_policeRank);
  }

  bool _canFilterByDistrict() {
    if (_policeRank == null) return false;
    // DGP/Addl. DGP, IGP/DIG can filter by district
    return _stateLevelRanks.contains(_policeRank) ||
           _rangeLevelRanks.contains(_policeRank);
  }

  bool _canFilterByStation() {
    if (_policeRank == null) return false;
    // Everyone except station-level can filter by station
    return _stateLevelRanks.contains(_policeRank) ||
           _rangeLevelRanks.contains(_policeRank) ||
           _districtLevelRanks.contains(_policeRank);
  }

  bool _isStationLevel() {
    if (_policeRank == null) return false;
    return _stationLevelRanks.contains(_policeRank);
  }

  /* ================= HIERARCHY HELPERS ================= */

  List<String> _getAvailableRanges() {
    return _policeHierarchy.keys.toList();
  }

  List<String> _getAvailableDistricts() {
    // For DGP: Show districts from selected range
    if (_selectedRange != null) {
      return _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
    }
    
    // For IGP: Show districts from their assigned range
    if (_policeRange != null) {
      return _policeHierarchy[_policeRange]?.keys.toList() ?? [];
    }
    
    return [];
  }

  List<String> _getAvailableStations() {
    String? targetRange;
    String? targetDistrict;

    // Determine which district to use
    if (_selectedDistrict != null) {
      targetDistrict = _selectedDistrict;
    } else if (_policeDistrict != null) {
      targetDistrict = _policeDistrict;
    }

    // Determine which range to use
    if (_selectedRange != null) {
      targetRange = _selectedRange;
    } else if (_policeRange != null) {
      targetRange = _policeRange;
    } else if (targetDistrict != null) {
      // If we have a district but no range, search for the district across all ranges
      // using case-insensitive match
      for (var range in _policeHierarchy.keys) {
        final districtMap = _policeHierarchy[range] ?? {};
        // Check keys case-insensitively
        final matchedKey = districtMap.keys.firstWhere(
          (k) => k.trim().toLowerCase() == targetDistrict!.trim().toLowerCase(),
          orElse: () => '',
        );

        if (matchedKey.isNotEmpty) {
          targetRange = range;
          // Update targetDistrict to the exact key found in JSON for lookup
          targetDistrict = matchedKey;
          debugPrint('🔍 Found district "$targetDistrict" (matched from "${_policeDistrict ?? _selectedDistrict}") in range "$range"');
          break;
        }
      }
    }

    if (targetRange == null || targetDistrict == null) {
      debugPrint('❌ Cannot get stations: targetRange=$targetRange, targetDistrict=$targetDistrict');
      return [];
    }

    // Final robust lookup using the exact keys
    final districtMap = _policeHierarchy[targetRange] ?? {};
    
    // Try exact match first
    if (districtMap.containsKey(targetDistrict)) {
      final stations = districtMap[targetDistrict] ?? [];
      debugPrint('✅ Found ${stations.length} stations in $targetRange > $targetDistrict');
      return stations;
    } 
    
    // Fallback: Try finding key again (redundant if we set it above, but safe)
    final matchedKey = districtMap.keys.firstWhere(
      (k) => k.trim().toLowerCase() == targetDistrict!.trim().toLowerCase(),
      orElse: () => '',
    );
    
    if (matchedKey.isNotEmpty) {
      final stations = districtMap[matchedKey] ?? [];
      debugPrint('✅ Found ${stations.length} stations via fuzzy match in $targetRange > $matchedKey');
      return stations;
    }

    return [];
  }

  /* ================= FILTER RESET ================= */

  void _onRangeChanged(String? range) {
    setState(() {
      _selectedRange = range;
      _selectedDistrict = null;
      _selectedStation = null;
    });
  }

  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedStation = null;
    });
  }

  /* ================= BUILD QUERY ================= */

  Query<Map<String, dynamic>> _buildPetitionQuery() {
    Query<Map<String, dynamic>> query = 
        FirebaseFirestore.instance.collection('petitions');

    // Station-level officers: filter by their assigned station
    if (_isStationLevel() && _policeStation != null) {
      query = query.where('stationName', isEqualTo: _policeStation);
      debugPrint('🔍 Station Level Query: stationName = $_policeStation');
    }
    // SP/Addl. SP: filter by selected station (if any)
    else if (_districtLevelRanks.contains(_policeRank)) {
      if (_selectedStation != null) {
        query = query.where('stationName', isEqualTo: _selectedStation);
        debugPrint('🔍 District Level Query: stationName = $_selectedStation');
      } else if (_policeDistrict != null) {
        // If no station selected, show all from their district
        query = query.where('district', isEqualTo: _policeDistrict);
        debugPrint('🔍 District Level Query: district = $_policeDistrict');
      }
    }
    // IGP/DIG: filter by selected district or station
    else if (_rangeLevelRanks.contains(_policeRank)) {
      if (_selectedStation != null) {
        query = query.where('stationName', isEqualTo: _selectedStation);
        debugPrint('🔍 Range Level Query: stationName = $_selectedStation');
      } else if (_selectedDistrict != null) {
        query = query.where('district', isEqualTo: _selectedDistrict);
        debugPrint('🔍 Range Level Query: district = $_selectedDistrict');
      } else if (_policeRange != null) {
        // Show all from their range (would need a 'range' field in petitions)
        // For now, we'll show all petitions
        debugPrint('🔍 Range Level Query: Show all (no range filter in petition schema)');
      }
    }
    // DGP/Addl. DGP: filter by selected hierarchy
    else if (_stateLevelRanks.contains(_policeRank)) {
      if (_selectedStation != null) {
        query = query.where('stationName', isEqualTo: _selectedStation);
        debugPrint('🔍 State Level Query: stationName = $_selectedStation');
      } else if (_selectedDistrict != null) {
        query = query.where('district', isEqualTo: _selectedDistrict);
        debugPrint('🔍 State Level Query: district = $_selectedDistrict');
      }
      // If no filter, show all state petitions
    }

    return query.orderBy('createdAt', descending: true);
  }

  /* ================= FILTER PETITIONS ================= */

  List<Petition> _applyFilters(List<Petition> petitions) {
    debugPrint(
        '🔎 Filters → search=$_searchQuery status=$_selectedPoliceStatus type=$_selectedType fromDate=$_fromDate toDate=$_toDate');
    return petitions.where((p) {
      // Search query filter
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        final haystack = [
          p.title,
          p.petitionerName,
          p.phoneNumber,
          p.type.displayName,
          p.policeStatus,
        ]
            .whereType<String>()
            .join(' ')
            .toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      // Filter by police status
      if (_selectedPoliceStatus != null &&
          _selectedPoliceStatus!.isNotEmpty &&
          p.policeStatus != _selectedPoliceStatus) {
        return false;
      }
      
      // Filter by type - compare display names
      if (_selectedType != null &&
          _selectedType!.isNotEmpty &&
          p.type.displayName != _selectedType) {
        return false;
      }
      
      // Filter by from date
      if (_fromDate != null &&
          p.createdAt.toDate().isBefore(_fromDate!)) {
        return false;
      }
      
      // Filter by to date
      if (_toDate != null &&
          p.createdAt
              .toDate()
              .isAfter(_toDate!.add(const Duration(days: 1)))) {
        return false;
      }

      // Filter by Urgency
      if (_selectedUrgency == 'Escalated' && !p.isEscalated) {
        return false;
      }

      return true;
    }).toList();
  }

  /* ================= UI HELPERS ================= */

  Color _getPoliceStatusColor(String status) {
    switch (status) {
      case 'Received':
        return Colors.blue;
      case 'In Progress':
        return Colors.indigo;
      case 'Closed':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp t) {
    final d = t.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= SEARCHABLE DROPDOWN ================= */

  Future<void> _openSearchableDropdown({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required void Function(String?) onSelected,
  }) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No options available for $title')),
      );
      return;
    }

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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                              .where((e) => e
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: ListView.builder(
                        itemCount: filtered.length + 1, // +1 for "All" option
                        itemBuilder: (_, index) {
                          if (index == 0) {
                            return ListTile(
                              title: Text('All $title'),
                              trailing: selectedValue == null
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                onSelected(null);
                                Navigator.pop(context);
                              },
                            );
                          }
                          
                          final item = filtered[index - 1];
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
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /* ================= PETITION DETAIL MODAL ================= */

  void _showPetitionDetails(BuildContext context, Petition petition) {
    final policeProfile = context.read<PoliceAuthProvider>().policeProfile;
    final policeOfficerName = policeProfile?['displayName'] ?? 'Officer';
    final policeOfficerUserId = policeProfile?['uid'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        builder: (_, controller) {
          String? selectedStatus = petition.policeStatus;
          String? selectedSubStatus = petition.policeSubStatus;
          bool loading = false;

          return StatefulBuilder(
            builder: (context, setModal) {
              return SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            petition.title,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),

                    const Divider(),

                    // Petition Details Section
                    const Text(
                      'Petition Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildDetailRow('Petition ID', petition.id ?? '-'),
                    _buildDetailRow('Petition Type', petition.type.displayName),
                    _buildDetailRow('Status', petition.status.displayName),
                    _buildDetailRow('Petitioner Name', petition.petitionerName),
                    _buildDetailRow('Phone Number', petition.phoneNumber ?? '-'),
                    if (petition.address != null && petition.address!.isNotEmpty)
                      _buildDetailRow('Address', petition.address!),
                    if (petition.district != null && petition.district!.isNotEmpty)
                      _buildDetailRow('District', petition.district!),
                    if (petition.stationName != null && petition.stationName!.isNotEmpty)
                      _buildDetailRow('Police Station', petition.stationName!),
                    if (petition.incidentAddress != null && petition.incidentAddress!.isNotEmpty)
                      _buildDetailRow('Incident Address', petition.incidentAddress!),
                    if (petition.incidentDate != null)
                      _buildDetailRow('Incident Date', _formatTimestamp(petition.incidentDate!)),
                    if (petition.caseId != null && petition.caseId!.isNotEmpty)
                      _buildDetailRow('Related Case ID', petition.caseId!),
                    if (petition.firNumber != null && petition.firNumber!.isNotEmpty)
                      _buildDetailRow('FIR Number', petition.firNumber!),
                    
                    const SizedBox(height: 16),
                    
                    // Grounds Section
                    if (petition.grounds.isNotEmpty) ...[
                      const Text(
                        'Grounds',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          petition.grounds,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Prayer/Relief Section
                    if (petition.prayerRelief != null && petition.prayerRelief!.isNotEmpty) ...[
                      const Text(
                        'Prayer/Relief Sought',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          petition.prayerRelief!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Dates Section
                    const Text(
                      'Important Dates',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Created At', _formatTimestamp(petition.createdAt)),
                    _buildDetailRow('Last Updated', _formatTimestamp(petition.updatedAt)),
                    if (petition.filingDate != null && petition.filingDate!.isNotEmpty)
                      _buildDetailRow('Filing Date', petition.filingDate!),
                    if (petition.nextHearingDate != null && petition.nextHearingDate!.isNotEmpty)
                      _buildDetailRow('Next Hearing Date', petition.nextHearingDate!),
                    if (petition.orderDate != null && petition.orderDate!.isNotEmpty)
                      _buildDetailRow('Order Date', petition.orderDate!),
                    
                    const SizedBox(height: 24),

                    // ============= PETITION UPDATES TIMELINE ============= 
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Case Updates',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => AddPetitionUpdateDialog(
                                petition: petition,
                                policeOfficerName: policeOfficerName,
                                policeOfficerUserId: policeOfficerUserId,
                              ),
                            );
                            
                            // Refresh the modal if update was added
                            if (result == true && context.mounted) {
                              setModal(() {}); // Trigger rebuild
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Update'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Display petition updates in real-time using StreamBuilder
                    StreamBuilder<List<PetitionUpdate>>(
                      stream: context.read<PetitionProvider>().streamPetitionUpdates(petition.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'Error loading updates: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        }

                        final updates = snapshot.data ?? [];
                        final allUpdates = context.read<PetitionProvider>().getUpdatesWithEscalations(petition, updates);
                        return PetitionUpdateTimeline(updates: allUpdates);
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Police Status Section
                    const Text(
                      'Police Status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (petition.policeStatus != null)
                      _buildDetailRow('Status', petition.policeStatus!),
                    if (petition.policeSubStatus != null)
                      _buildDetailRow('Sub Status', petition.policeSubStatus!),
                    
                    const SizedBox(height: 16),

                    const Text(
                      'Police Status Update',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: ['Received', 'In Progress', 'Closed']
                              .contains(selectedStatus)
                          ? selectedStatus
                          : null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Status',
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Received', child: Text('Received')),
                        DropdownMenuItem(
                            value: 'In Progress',
                            child: Text('In Progress')),
                        DropdownMenuItem(
                            value: 'Closed', child: Text('Closed')),
                      ],
                      onChanged: (v) =>
                          setModal(() => selectedStatus = v),
                    ),

                    if (selectedStatus == 'Closed') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSubStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Closure Type',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Rejected',
                              child: Text('Rejected')),
                          DropdownMenuItem(
                              value: 'FIR Registered',
                              child: Text('FIR Registered')),
                          DropdownMenuItem(
                              value: 'Compromised / Disposed',
                              child:
                                  Text('Compromised / Disposed')),
                        ],
                        onChanged: (v) =>
                            setModal(() => selectedSubStatus = v),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Register FIR Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close the modal first
                          
                          // Prepare data for navigation - convert Timestamp to Map for serialization
                          final Map<String, dynamic> petitionData = {};
                          
                          // Use case_id from petition (not petition.id)
                          if (petition.caseId != null && petition.caseId!.isNotEmpty) {
                            petitionData['caseId'] = petition.caseId;
                            debugPrint('✅ Using petition.caseId: ${petition.caseId}');
                          } else if (petition.id != null && petition.id!.isNotEmpty) {
                            // Fallback to petition.id if caseId is not available
                            petitionData['caseId'] = petition.id;
                            debugPrint('⚠️ Using petition.id as fallback: ${petition.id}');
                          }
                          
                          // Map petition fields to FIR form fields
                          if (petition.title.isNotEmpty) {
                            petitionData['title'] = petition.title;
                          }
                          if (petition.petitionerName.isNotEmpty) {
                            petitionData['petitionerName'] = petition.petitionerName;
                          }
                          if (petition.phoneNumber != null && petition.phoneNumber!.isNotEmpty) {
                            petitionData['phoneNumber'] = petition.phoneNumber;
                          }
                          // grounds maps to complaint narrative in FIR
                          if (petition.grounds.isNotEmpty) {
                            petitionData['grounds'] = petition.grounds;
                          }
                          if (petition.district != null && petition.district!.isNotEmpty) {
                            petitionData['district'] = petition.district;
                          }
                          if (petition.stationName != null && petition.stationName!.isNotEmpty) {
                            petitionData['stationName'] = petition.stationName;
                          }
                          if (petition.incidentAddress != null && petition.incidentAddress!.isNotEmpty) {
                            petitionData['incidentAddress'] = petition.incidentAddress;
                          }
                          if (petition.address != null && petition.address!.isNotEmpty) {
                            petitionData['address'] = petition.address;
                          }
                          
                          // Convert Timestamp to serializable format
                          if (petition.incidentDate != null) {
                            petitionData['incidentDate'] = {
                              'seconds': petition.incidentDate!.seconds,
                              'nanoseconds': petition.incidentDate!.nanoseconds,
                            };
                          }
                          
                          debugPrint('🚀 Navigating to new case screen');
                          debugPrint('📦 Petition data being passed: $petitionData');
                          
                          // Navigate to new case screen with petition data
                          context.go(
                            '/cases/new',
                            extra: petitionData,
                          );
                        },
                        icon: const Icon(Icons.gavel, size: 20),
                        label: const Text(
                          'Register FIR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () async {
                                setModal(() => loading = true);

                                await context
                                    .read<PetitionProvider>()
                                    .updatePetition(
                                  petition.id!,
                                  {
                                    'policeStatus': selectedStatus,
                                    'policeSubStatus': selectedSubStatus,
                                  },
                                  petition.userId,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Status updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Submit Status Update'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /* ================= BUILD UI ================= */

  @override
  Widget build(BuildContext context) {
    if (_hierarchyLoading || _policeRank == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Petitions – ${_policeRank ?? "Loading..."}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Your Access Level'),
                  content: Text(
                    'Rank: $_policeRank\n\n'
                    'Range: ${_policeRange ?? "N/A"}\n'
                    'District: ${_policeDistrict ?? "N/A"}\n'
                    'Station: ${_policeStation ?? "N/A"}\n\n'
                    'Filter petitions using the dropdown filters below.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildPetitionQuery().snapshots(),
        builder: (context, snapshot) {
          debugPrint('📡 hasData=${snapshot.hasData} error=${snapshot.error}');

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allPetitions = snapshot.data!.docs
              .map((d) => Petition.fromFirestore(d))
              .toList();

          final petitions = _applyFilters(allPetitions);

          return Column(
            children: [
              // === RANK-BASED FILTERS ===
              Container(
                color: Colors.blue.shade50,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DGP: Range → District → Station
                    if (_canFilterByRange()) ...[
                      _buildFilterPicker(
                        label: 'Filter by Range',
                        value: _selectedRange,
                        icon: Icons.location_city,
                        onTap: () {
                          _openSearchableDropdown(
                            title: 'Select Range',
                            items: _getAvailableRanges(),
                            selectedValue: _selectedRange,
                            onSelected: _onRangeChanged,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],

                    // DGP, IGP: District
                    if (_canFilterByDistrict()) ...[
                      _buildFilterPicker(
                        label: 'Filter by District',
                        value: _selectedDistrict,
                        icon: Icons.map,
                        onTap: () {
                          _openSearchableDropdown(
                            title: 'Select District',
                            items: _getAvailableDistricts(),
                            selectedValue: _selectedDistrict,
                            onSelected: _onDistrictChanged,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                    ],

                    // DGP, IGP, SP: Station
                    if (_canFilterByStation()) ...[
                      _buildFilterPicker(
                        label: 'Filter by Police Station',
                        value: _selectedStation,
                        icon: Icons.local_police,
                        onTap: () {
                          debugPrint('🔍 Station filter tapped');
                          debugPrint('   Police Rank: $_policeRank');
                          debugPrint('   Police Range: $_policeRange');
                          debugPrint('   Police District: $_policeDistrict');
                          debugPrint('   Selected Range: $_selectedRange');
                          debugPrint('   Selected District: $_selectedDistrict');
                          
                          final availableStations = _getAvailableStations();
                          debugPrint('   Available Stations: ${availableStations.length}');
                          
                          _openSearchableDropdown(
                            title: 'Select Police Station',
                            items: availableStations,
                            selectedValue: _selectedStation,
                            onSelected: (station) {
                              setState(() => _selectedStation = station);
                            },
                          );
                        },
                      ),
                    ],
                    
                    // Station Level: Show assigned station (read-only)
                    if (_isStationLevel() && _policeStation != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_police, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Showing petitions from: $_policeStation',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // === STANDARD FILTERS ===
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by title, petitioner name, phone...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Icon(Icons.filter_list, size: 18, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'Filters:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip<String>(
                              label: 'Status',
                              value: _selectedPoliceStatus,
                              options: const [
                                'Pending',
                                'Received',
                                'In Progress',
                                'Closed',
                              ],
                              onSelected: (value) {
                                setState(() => _selectedPoliceStatus = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip<String>(
                              label: 'Type',
                              value: _selectedType,
                              options: const [
                                'Bail Application',
                                'Anticipatory Bail',
                                'Revision Petition',
                                'Appeal',
                                'Writ Petition',
                                'Quashing Petition',
                                'Other',
                              ],
                              onSelected: (value) {
                                setState(() => _selectedType = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            // ESCALATED FILTER
                            _buildFilterChip<String>(
                              label: 'Urgency',
                              value: _selectedUrgency,
                              options: const [
                                'Escalated',
                              ],
                              onSelected: (value) {
                                setState(() => _selectedUrgency = value);
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildDateFilterChip(
                              label: 'From Date',
                              value: _fromDate,
                              onSelected: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _fromDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _fromDate = picked);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildDateFilterChip(
                              label: 'To Date',
                              value: _toDate,
                              onSelected: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _toDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _toDate = picked);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            if (_selectedPoliceStatus != null ||
                                _selectedType != null ||
                                _selectedUrgency != null ||
                                _fromDate != null ||
                                _toDate != null ||
                                (_searchQuery != null && _searchQuery!.isNotEmpty))
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPoliceStatus = null;
                                    _selectedType = null;
                                    _selectedUrgency = null;
                                    _fromDate = null;
                                    _toDate = null;
                                    _searchQuery = '';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.red.shade300),
                                    color: Colors.red.shade50,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.clear, size: 16, color: Colors.red.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Clear All',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              /// 📋 LIST OR EMPTY STATE
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: petitions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_list_off,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No matching petitions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                allPetitions.isEmpty
                                    ? 'No petitions registered yet'
                                    : 'Try adjusting the filters above',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: petitions.length,
                          itemBuilder: (_, i) {
                            final p = petitions[i];
                            return Card(
                              elevation: 2,
                              color: Colors.white,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _showPetitionDetails(context, p),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: Colors.indigo,
                                            child: const Icon(
                                              Icons.gavel,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        p.title,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                      if (p.policeStatus != null)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: _getPoliceStatusColor(
                                                                    p.policeStatus!)
                                                                .withOpacity(0.12),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Text(
                                                            p.policeStatus!,
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w600,
                                                              color: _getPoliceStatusColor(
                                                                  p.policeStatus!),
                                                            ),
                                                          ),
                                                        ),
                                                      if (p.isEscalated) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.red.shade100,
                                                            borderRadius: BorderRadius.circular(20),
                                                            border: Border.all(color: Colors.red.shade300),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.trending_up,
                                                                  size: 10, color: Colors.red.shade800),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                'ESCALATED',
                                                                style: TextStyle(
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.red.shade900,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                      if (p.escalationLevel == 3) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.deepPurple.shade100,
                                                            borderRadius: BorderRadius.circular(20),
                                                            border: Border.all(color: Colors.deepPurple.shade300),
                                                          ),
                                                          child: Text(
                                                            'DGP LEVEL',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.deepPurple.shade900,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  p.petitionerName,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Created: ${_formatTimestamp(p.createdAt)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(
                                            Icons.category,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            p.type.displayName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      // AI Investigation Button
                                      if (p.caseId != null && p.caseId!.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              context.go(
                                                '/ai-investigation-guidelines?caseId=${p.caseId}',
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.psychology,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'AI Investigation Guidelines',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /* ================= FILTER UI WIDGETS ================= */

  Widget _buildFilterPicker({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 14,
                  color: value == null ? Colors.grey : Colors.black,
                  fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip<T>({
    required String label,
    required T? value,
    required List<T> options,
    required void Function(T?) onSelected,
  }) {
    return PopupMenuButton<T>(
      tooltip: label,
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem<T>(
          value: null,
          child: Text('All $label'),
        ),
        ...options.toSet().map(
          (opt) => PopupMenuItem<T>(
            value: opt,
            child: Text(opt.toString()),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == null ? label : '$label: $value',
              style: const TextStyle(fontSize: 12),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterChip({
    required String label,
    required DateTime? value,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == null
                  ? label
                  : '$label: ${_formatTimestamp(Timestamp.fromDate(value))}',
              style: const TextStyle(fontSize: 12),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}
