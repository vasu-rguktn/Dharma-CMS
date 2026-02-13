// lib/screens/petition/police_petition_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/police_auth_provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/models/petition_update.dart';
import 'package:Dharma/utils/petition_filter.dart';
import 'package:Dharma/widgets/petition_update_timeline.dart';
import 'package:Dharma/widgets/add_petition_update_dialog.dart';
import 'package:Dharma/widgets/petition_feedback_timeline.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/providers/complaint_provider.dart';
import 'package:Dharma/data/station_data_constants.dart';

/// Police Petition List Screen
/// Shows filtered petitions for the police station and allows viewing/updating details
class PolicePetitionListScreen extends StatefulWidget {
  final PetitionFilter filter;
  final String title;

  const PolicePetitionListScreen({
    super.key,
    required this.filter,
    required this.title,
  });

  @override
  State<PolicePetitionListScreen> createState() =>
      _PolicePetitionListScreenState();
}

class _PolicePetitionListScreenState extends State<PolicePetitionListScreen> {
  bool _isLoading = true;
  List<Petition> _allPetitions = [];
  List<Petition> _filteredPetitions = [];
  final TextEditingController _searchController = TextEditingController();

  // Police Profile Data
  String? _policeRank;
  String? _policeRange;
  String? _policeDistrict;
  String? _policeStation;

  // Hierarchy filters
  String? _selectedRange;
  String? _selectedDistrict;
  String? _selectedStation;

  // Hierarchy data
  Map<String, Map<String, List<String>>> _policeHierarchy = {};

  /* ================= RANK TIERS ================= */
  static const List<String> _stateLevelRanks = [
    'Director General of Police',
    'Additional Director General of Police',
  ];

  static const List<String> _rangeLevelRanks = [
    'Inspector General of Police',
    'Deputy Inspector General of Police',
  ];

  static const List<String> _stationLevelRanks = [
    'Deputy Superintendent of Police',
    'Inspector of Police',
    'Sub Inspector of Police',
    'Assistant Sub Inspector of Police',
    'Head Constable',
    'Police Constable',
  ];

  @override
  void initState() {
    super.initState();
    _loadHierarchyData();
    _loadProfile().then((_) => _loadFilteredPetitions());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFilteredPetitions() async {
    setState(() => _isLoading = true);

    final petitionProvider =
        Provider.of<PetitionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final officerId = authProvider.userProfile?.uid;

    // Determine target hierarchy parameters
    // If high-level officer has selected a filter, use it; otherwise use their own profile
    final targetStation =
        _selectedStation ?? (_isStationLevel() ? _policeStation : null);
    final targetDistrict = _selectedDistrict ??
        (!_canFilterByRange() && !_canFilterByDistrict()
            ? _policeDistrict
            : null);
    final targetRange =
        _selectedRange ?? (!_canFilterByRange() ? _policeRange : null);

    await petitionProvider.fetchFilteredPetitions(
      isPolice: true,
      officerId: officerId,
      stationName: targetStation,
      district: targetDistrict,
      range: targetRange,
      filter: widget.filter,
    );

    if (mounted) {
      setState(() {
        _allPetitions = petitionProvider.petitions;
        _filteredPetitions = _allPetitions;
        _isLoading = false;
        _searchController.clear();
      });
    }
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
            districtMap[district.toString()] =
                List<String>.from(stations ?? []);
          });
          hierarchy[range] = districtMap;
        }
      });

      if (mounted) {
        setState(() {
          _policeHierarchy = hierarchy;
        });
      }
    } catch (e) {
      debugPrint('Error loading hierarchy: $e');
      if (mounted) {
        setState(() {
          // Error state ignored for constants loading
        });
      }
    }
  }

  /* ================= RANK-BASED FILTER VISIBILITY ================= */
  bool _canFilterByRange() =>
      _policeRank != null && _stateLevelRanks.contains(_policeRank);
  bool _canFilterByDistrict() =>
      _policeRank != null &&
      (_stateLevelRanks.contains(_policeRank) ||
          _rangeLevelRanks.contains(_policeRank));
  bool _canFilterByStation() =>
      _policeRank != null && !_stationLevelRanks.contains(_policeRank);
  bool _isStationLevel() =>
      _policeRank != null && _stationLevelRanks.contains(_policeRank);

  /* ================= HIERARCHY HELPERS ================= */
  List<String> _getAvailableRanges() => _policeHierarchy.keys.toList();
  List<String> _getAvailableDistricts() {
    // For DGP: Show districts from selected range
    if (_selectedRange != null) {
      return _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
    }

    // For IGP: Show districts from their assigned range (robust match)
    if (_policeRange != null) {
      final normalizedRange = _policeRange!.trim().toLowerCase();
      final matchedRange = _policeHierarchy.keys.firstWhere(
        (r) => r.trim().toLowerCase() == normalizedRange,
        orElse: () => '',
      );
      if (matchedRange.isNotEmpty) {
        return _policeHierarchy[matchedRange]?.keys.toList() ?? [];
      }
    }

    return [];
  }

  List<String> _getAvailableStations() {
    String? targetRange = _selectedRange ?? _policeRange;
    String? targetDistrict = _selectedDistrict ?? _policeDistrict;

    if (targetDistrict == null) return [];

    final normalizedDistrict = targetDistrict.trim().toLowerCase();
    String? matchedRange;
    String? matchedDistrict;

    // 1. If we have a range (selected or from profile), try to find the district within it
    if (targetRange != null) {
      final normalizedRange = targetRange.trim().toLowerCase();
      matchedRange = _policeHierarchy.keys.firstWhere(
        (r) => r.trim().toLowerCase() == normalizedRange,
        orElse: () => '',
      );

      if (matchedRange.isNotEmpty) {
        final districts = _policeHierarchy[matchedRange] ?? {};
        matchedDistrict = districts.keys.firstWhere(
          (d) => d.trim().toLowerCase() == normalizedDistrict,
          orElse: () => '',
        );
      }
    }

    // 2. Fallback: Search all ranges if range lookup failed or no range provided
    if (matchedDistrict == null || matchedDistrict.isEmpty) {
      for (var range in _policeHierarchy.keys) {
        final districts = _policeHierarchy[range] ?? {};
        final dKey = districts.keys.firstWhere(
          (d) => d.trim().toLowerCase() == normalizedDistrict,
          orElse: () => '',
        );
        if (dKey.isNotEmpty) {
          matchedRange = range;
          matchedDistrict = dKey;
          break;
        }
      }
    }

    if (matchedRange != null &&
        matchedDistrict != null &&
        matchedDistrict.isNotEmpty) {
      return List<String>.from(
          _policeHierarchy[matchedRange]?[matchedDistrict] ?? []);
    }

    debugPrint(
        '⚠️ Could not find stations for Range: $targetRange, District: $targetDistrict');
    return [];
  }

  void _onRangeChanged(String? range) {
    setState(() {
      _selectedRange = range;
      _selectedDistrict = null;
      _selectedStation = null;
    });
    _loadFilteredPetitions();
  }

  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedStation = null;
    });
    _loadFilteredPetitions();
  }

  void _onStationChanged(String? station) {
    setState(() {
      _selectedStation = station;
    });
    _loadFilteredPetitions();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPetitions = _allPetitions;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredPetitions = _allPetitions.where((petition) {
        final matchesTitle =
            petition.title.toLowerCase().contains(lowercaseQuery);
        final matchesName =
            petition.petitionerName.toLowerCase().contains(lowercaseQuery);
        final matchesId =
            (petition.id ?? '').toLowerCase().contains(lowercaseQuery);
        final matchesFir =
            (petition.firNumber ?? '').toLowerCase().contains(lowercaseQuery);

        return matchesTitle || matchesName || matchesId || matchesFir;
      }).toList();
    });
  }

  /* ================= SEARCHABLE DROPDOWN ================= */
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
                        fontSize: 20, fontWeight: FontWeight.bold),
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
                      itemCount: filtered.length + 1,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  color: value != null ? Colors.black87 : Colors.grey[600],
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

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

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getFilterColor(PetitionFilter filter) {
    switch (filter) {
      case PetitionFilter.all:
        return Colors.deepPurple;
      case PetitionFilter.received:
        return Colors.blue.shade700;
      case PetitionFilter.inProgress:
        return Colors.orange.shade700;
      case PetitionFilter.closed:
        return Colors.green.shade700;
      case PetitionFilter.escalated:
        return Colors.red.shade700;
    }
  }

  IconData _getFilterIcon(PetitionFilter filter) {
    switch (filter) {
      case PetitionFilter.all:
        return Icons.gavel;
      case PetitionFilter.received:
        return Icons.call_received;
      case PetitionFilter.inProgress:
        return Icons.sync;
      case PetitionFilter.closed:
        return Icons.task_alt;
      case PetitionFilter.escalated:
        return Icons.trending_up;
    }
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

  void _showPetitionDetails(BuildContext context, Petition petition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        builder: (_, controller) {
          // Initialize to null so officer must select a new status
          String? selectedStatus = null; // Changed from: petition.policeStatus
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
                                fontSize: 20, fontWeight: FontWeight.bold),
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    _buildDetailRow('Petition ID', petition.id ?? '-'),
                    _buildDetailRow('Petition Type', petition.type.displayName),
                    _buildDetailRow('Status', petition.status.displayName),
                    _buildDetailRow('Petitioner Name', petition.petitionerName),
                    _buildDetailRow(
                      'Phone Number',
                      petition.phoneNumber == null
                          ? '-'
                          : (petition.isAnonymous
                              ? maskPhoneNumber(petition.phoneNumber)
                              : petition.phoneNumber!),
                    ),
                    if (petition.address != null &&
                        petition.address!.isNotEmpty)
                      _buildDetailRow('Address', petition.address!),
                    if (petition.district != null &&
                        petition.district!.isNotEmpty)
                      _buildDetailRow('District', petition.district!),
                    if (petition.stationName != null &&
                        petition.stationName!.isNotEmpty)
                      _buildDetailRow('Police Station', petition.stationName!),
                    if (petition.incidentAddress != null &&
                        petition.incidentAddress!.isNotEmpty)
                      _buildDetailRow(
                          'Incident Address', petition.incidentAddress!),
                    if (petition.incidentDate != null)
                      _buildDetailRow('Incident Date',
                          _formatTimestamp(petition.incidentDate!)),
                    if (petition.firNumber != null &&
                        petition.firNumber!.isNotEmpty)
                      _buildDetailRow('FIR Number', petition.firNumber!),

                    const SizedBox(height: 16),

                    // Grounds Section
                    if (petition.grounds.isNotEmpty) ...[
                      const Text(
                        'Grounds',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                    if (petition.prayerRelief != null &&
                        petition.prayerRelief!.isNotEmpty) ...[
                      const Text(
                        'Prayer/Relief Sought',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                        'Created At', _formatTimestamp(petition.createdAt)),
                    _buildDetailRow(
                        'Last Updated', _formatTimestamp(petition.updatedAt)),
                    if (petition.filingDate != null &&
                        petition.filingDate!.isNotEmpty)
                      _buildDetailRow('Filing Date', petition.filingDate!),
                    if (petition.nextHearingDate != null &&
                        petition.nextHearingDate!.isNotEmpty)
                      _buildDetailRow(
                          'Next Hearing Date', petition.nextHearingDate!),
                    if (petition.orderDate != null &&
                        petition.orderDate!.isNotEmpty)
                      _buildDetailRow('Order Date', petition.orderDate!),

                    const SizedBox(height: 16),

                    // Police Status Section
                    const Text(
                      'Police Status',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (petition.policeStatus != null)
                      _buildDetailRow('Status', petition.policeStatus!),
                    if (petition.policeSubStatus != null)
                      _buildDetailRow('Sub Status', petition.policeSubStatus!),

                    const SizedBox(height: 24),
                    const Divider(),

                    // ============= PETITION UPDATES TIMELINE =============
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Case Updates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final policeProfile = context
                                .read<PoliceAuthProvider>()
                                .policeProfile;
                            final policeOfficerName =
                                policeProfile?['displayName'] ?? 'Officer';
                            final policeOfficerUserId =
                                policeProfile?['uid'] ?? '';

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
                      stream: context
                          .read<PetitionProvider>()
                          .streamPetitionUpdates(petition.id!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                        return PetitionUpdateTimeline(updates: updates);
                      },
                    ),

                    // ============= CITIZEN FEEDBACK =============
                    if (petition.feedbacks != null &&
                        petition.feedbacks!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        "Citizen Feedback",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PetitionFeedbackTimeline(feedbacks: petition.feedbacks!),
                    ],

                    const SizedBox(height: 24),
                    const Divider(),

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
                            value: 'In Progress', child: Text('In Progress')),
                        DropdownMenuItem(
                            value: 'Closed', child: Text('Closed')),
                      ],
                      onChanged: (v) => setModal(() => selectedStatus = v),
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
                              value: 'Rejected', child: Text('Rejected')),
                          DropdownMenuItem(
                              value: 'FIR Registered',
                              child: Text('FIR Registered')),
                          DropdownMenuItem(
                              value: 'Compromised / Disposed',
                              child: Text('Compromised / Disposed')),
                        ],
                        onChanged: (v) => setModal(() => selectedSubStatus = v),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // AI Investigation Guidelines Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close the modal first

                          // Navigate to AI Investigation Guidelines
                          if (petition.caseId != null &&
                              petition.caseId!.isNotEmpty) {
                            context.go(
                              '/ai-investigation-guidelines',
                              extra: {'caseId': petition.caseId},
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'No case ID associated with this petition'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.psychology, size: 20),
                        label: const Text(
                          'AI Investigation Guidelines',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Register FIR Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // Close the modal first

                          // Prepare data for navigation - convert Timestamp to Map for serialization
                          final Map<String, dynamic> petitionData = {};

                          // Use case_id from petition (not petition.id)
                          if (petition.caseId != null &&
                              petition.caseId!.isNotEmpty) {
                            petitionData['caseId'] = petition.caseId;
                            debugPrint(
                                '✅ Using petition.caseId: ${petition.caseId}');
                          } else if (petition.id != null &&
                              petition.id!.isNotEmpty) {
                            // Fallback to petition.id if caseId is not available
                            petitionData['caseId'] = petition.id;
                            debugPrint(
                                '⚠️ Using petition.id as fallback: ${petition.id}');
                          }

                          // Map petition fields to FIR form fields
                          if (petition.title.isNotEmpty) {
                            petitionData['title'] = petition.title;
                          }
                          if (petition.petitionerName.isNotEmpty) {
                            petitionData['petitionerName'] =
                                petition.petitionerName;
                          }
                          if (petition.phoneNumber != null &&
                              petition.phoneNumber!.isNotEmpty) {
                            petitionData['phoneNumber'] = petition.phoneNumber;
                          }
                          // grounds maps to complaint narrative in FIR
                          if (petition.grounds.isNotEmpty) {
                            petitionData['grounds'] = petition.grounds;
                          }
                          if (petition.district != null &&
                              petition.district!.isNotEmpty) {
                            petitionData['district'] = petition.district;
                          }
                          if (petition.stationName != null &&
                              petition.stationName!.isNotEmpty) {
                            petitionData['stationName'] = petition.stationName;
                          }
                          if (petition.incidentAddress != null &&
                              petition.incidentAddress!.isNotEmpty) {
                            petitionData['incidentAddress'] =
                                petition.incidentAddress;
                          }
                          if (petition.address != null &&
                              petition.address!.isNotEmpty) {
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
                          debugPrint(
                              '📦 Petition data being passed: $petitionData');

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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Status updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Refresh the list
                                  _loadFilteredPetitions();
                                }
                              },
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Submit Update'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _getFilterColor(widget.filter),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Hierarchy Filters
          if (_canFilterByDistrict() || _canFilterByStation())
            Container(
              color: _getFilterColor(widget.filter).withOpacity(0.05),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_canFilterByRange())
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterPicker(
                              label: 'Range',
                              value: _selectedRange,
                              icon: Icons.location_city,
                              onTap: () => _openSearchableDropdown(
                                title: 'Select Range',
                                items: _getAvailableRanges(),
                                selectedValue: _selectedRange,
                                onSelected: _onRangeChanged,
                              ),
                            ),
                          ),
                        ),
                      if (_canFilterByDistrict())
                        Expanded(
                          child: _buildFilterPicker(
                            label: 'District',
                            value: _selectedDistrict,
                            icon: Icons.map,
                            onTap: () => _openSearchableDropdown(
                              title: 'Select District',
                              items: _getAvailableDistricts(),
                              selectedValue: _selectedDistrict,
                              onSelected: _onDistrictChanged,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_canFilterByStation()) ...[
                    const SizedBox(height: 8),
                    _buildFilterPicker(
                      label: 'Police Station',
                      value: _selectedStation,
                      icon: Icons.local_police,
                      onTap: () => _openSearchableDropdown(
                        title: 'Select Station',
                        items: _getAvailableStations(),
                        selectedValue: _selectedStation,
                        onSelected: _onStationChanged,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by Name, Title, or ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _getFilterColor(widget.filter)),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPetitions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No Petitions Found'
                                  : 'No matches for "${_searchController.text}"',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFilteredPetitions,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filteredPetitions.length,
                          itemBuilder: (context, index) {
                            final petition = _filteredPetitions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: _getFilterColor(widget.filter)
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    _showPetitionDetails(context, petition),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title and Police Status
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  petition.title,
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[800],
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (petition.id != null)
                                                  Text(
                                                    'ID: ${petition.id}',
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: Colors.grey[500],
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getPoliceStatusColor(
                                                      petition.policeStatus ??
                                                          'Pending')
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getPoliceStatusColor(
                                                    petition.policeStatus ??
                                                        'Pending'),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              petition.policeStatus ??
                                                  'Pending',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: _getPoliceStatusColor(
                                                    petition.policeStatus ??
                                                        'Pending'),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // SAVE BUTTON
                                          Consumer<ComplaintProvider>(
                                              builder: (context, provider, _) {
                                            final isSaved = provider
                                                .isPetitionSaved(petition.id!);
                                            return InkWell(
                                              onTap: () async {
                                                final auth =
                                                    Provider.of<AuthProvider>(
                                                        context,
                                                        listen: false);
                                                final userId = auth.user?.uid;
                                                if (userId == null) return;

                                                await provider
                                                    .toggleSaveComplaint(
                                                        petition.toMap(),
                                                        userId);
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Icon(
                                                  isSaved
                                                      ? Icons.bookmark
                                                      : Icons.bookmark_border,
                                                  color: isSaved
                                                      ? Colors.orange
                                                      : Colors.grey,
                                                  size: 24,
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Type and Date
                                      Row(
                                        children: [
                                          Icon(Icons.category,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            petition.type.displayName,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateFormat.format(
                                                petition.createdAt.toDate()),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Petitioner name
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.person,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            petition.petitionerName,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Station name
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.local_police,
                                              size: 16,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              petition.stationName ?? 'N/A',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
      ),
    );
  }
}
