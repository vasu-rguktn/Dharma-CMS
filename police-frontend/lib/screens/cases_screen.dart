// lib/screens/cases_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/providers/case_provider.dart';
import 'package:Dharma/models/case_status.dart';
import 'package:go_router/go_router.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/police_auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:Dharma/data/station_data_constants.dart';


class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});

  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  bool _hasLoaded = false;
  bool _isFiltersExpanded = true;
  String? _searchQuery;
  // String? _selectedStation; // Replaced by hierarchy logic for police
  String? _selectedStatus;
  String? _selectedAgeRange;

  // Police Profile Data
  String? _policeRank;
  String? _policeRange;
  String? _policeDistrict;
  String? _policeStation;

  // Filter selections (for dynamic filtering based on rank)
  String? _selectedRange;
  String? _selectedDistrict;
  String? _selectedStation; // Reusing this name but managed differently

  // Hierarchy data
  Map<String, Map<String, List<String>>> _policeHierarchy = {};
  bool _hierarchyLoading = true;
  String? _hierarchyError; // Error message if loading fails
  bool _usingFirestoreFallback = false; // Track if using Firestore fallback

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

  Color _statusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.newCase:
        return const Color(0xFF1E88E5); // blue
      case CaseStatus.underInvestigation:
        return const Color(0xFFF9A825); // amber
      case CaseStatus.pendingTrial:
        return const Color(0xFF8E24AA); // purple
      case CaseStatus.resolved:
        return const Color(0xFF43A047); // green
      case CaseStatus.closed:
        return const Color(0xFF757575); // grey
    }
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat.yMMMd().format(dateTime);
  }

  /* ================= INIT & LOAD ================= */
  
  @override
  void initState() {
    super.initState();
    _loadHierarchyData();

    // Defer profile loading until context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileAndFetch();
    });
  }

  Future<void> _loadProfileAndFetch() async {
    final auth = context.read<AuthProvider>();
    
    if (auth.role == 'police') {
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
        print('👮 [CASES] Police Profile: Rank=$_policeRank, Dist=$_policeDistrict');
      }
    }
    
    if (mounted) _fetchData();
  }

  void _loadHierarchyData({bool retry = false}) {
    // Simplify loading by using hardcoded constants - 100% reliable
    debugPrint('🔄 [CASES] Loading police hierarchy data from constants...');
    
    try {
      Map<String, Map<String, List<String>>> hierarchy = {};
      final data = kPoliceHierarchyComplete;
      
      data.forEach((range, districts) {
        if (districts is Map) {
          Map<String, List<String>> districtMap = {};
          districts.forEach((district, stations) {
            final stationList = List<String>.from(stations ?? []);
            districtMap[district.toString()] = stationList;
          });
          hierarchy[range] = districtMap;
        }
      });

      if (mounted) {
        setState(() {
          _policeHierarchy = hierarchy;
          _hierarchyLoading = false;
          _hierarchyError = null;
          _usingFirestoreFallback = false;
        });
        debugPrint('✅ [CASES] Hierarchy loaded successfully from constants!');
      }
    } catch (e) {
      debugPrint('❌ [CASES] Error parsing hierarchy constants: $e');
      if (mounted) {
        setState(() {
          _hierarchyError = 'Failed to parse station data: $e';
        });
      }
    }
  }

  // Firestore fallback removed as it is no longer needed with hardcoded constants


  Future<void> _fetchData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final caseProvider = Provider.of<CaseProvider>(context, listen: false);
    
    // Determine effective filters
    String? targetDistrict;
    String? targetStation;

    if (auth.role == 'police') {
      // 1. Station Level: Must filter by assigned station
      if (_isStationLevel() && _policeStation != null) {
        targetStation = _policeStation;
        targetDistrict = _policeDistrict; 
      }
      // 2. District Level (SP, ASP):
      else if (_districtLevelRanks.contains(_policeRank)) {
        // If they chose a specific station, filter by it
        if (_selectedStation != null) {
          targetStation = _selectedStation;
          targetDistrict = _selectedDistrict ?? _policeDistrict;
        } 
        // Otherwise, filter by their district (SHOW ALL STATIONS IN DISTRICT)
        else {
          targetStation = null; // Important: Clear station filter
          targetDistrict = _policeDistrict;
        }
      }
      // 3. Range Level (IGP, DIG):
      else if (_rangeLevelRanks.contains(_policeRank)) {
        if (_selectedStation != null) {
          targetStation = _selectedStation;
          targetDistrict = _selectedDistrict; // Might be null if implicitly selected
        } else if (_selectedDistrict != null) {
          targetStation = null;
          targetDistrict = _selectedDistrict;
        } else if (_policeRange != null) {
          // Ideally filter by range, but backend might not support range query directly on cases.
          // For now, we rely on selectedDistrict. If none selected, we might show all or limit?
          // Let's assume fetching all for range if supported, or let them pick.
          // Based on current CaseProvider, we can't filter by 'range'. 
          // So we default to no district/station filter unless specified.
          targetStation = null;
          targetDistrict = null; 
        }
      }
      // 4. State Level (DGP):
      else if (_stateLevelRanks.contains(_policeRank)) {
        if (_selectedStation != null) {
          targetStation = _selectedStation;
          targetDistrict = _selectedDistrict;
        } else if (_selectedDistrict != null) {
          targetStation = null;
          targetDistrict = _selectedDistrict;
        }
      }
      // Fallback for edge cases or untagged ranks
      else {
         // Attempt to respect manual selections if rank logic fails
         targetStation = _selectedStation;
         targetDistrict = _selectedDistrict ?? _policeDistrict;
      }
    }

    print('📡 [CASES] Fetching with District=$targetDistrict, Station=$targetStation');
    await caseProvider.fetchCases(
      userId: auth.user?.uid,
      isAdmin: auth.role == 'police',
      district: targetDistrict,
      station: targetStation,
    );
  }

  /* ================= RANK VISIBILITY HELPERS ================= */

  bool _canFilterByRange() {
    if (_policeRank == null) return false;
    return _stateLevelRanks.contains(_policeRank);
  }

  bool _canFilterByDistrict() {
    if (_policeRank == null) return false;
    return _stateLevelRanks.contains(_policeRank) ||
           _rangeLevelRanks.contains(_policeRank);
  }

  bool _canFilterByStation() {
    if (_policeRank == null) return false;
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
    if (_selectedRange != null) {
      return _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
    }
    if (_policeRange != null) {
      return _policeHierarchy[_policeRange]?.keys.toList() ?? [];
    }
    return [];
  }

  List<String> _getAvailableStations() {
    String? targetRange;
    String? targetDistrict;

    if (_selectedDistrict != null) {
      targetDistrict = _selectedDistrict;
    } else if (_policeDistrict != null) {
      targetDistrict = _policeDistrict;
    }

    if (_selectedRange != null) {
      targetRange = _selectedRange;
    } else if (_policeRange != null) {
      targetRange = _policeRange;
    } else if (targetDistrict != null) {
      // Search for range containing this district (Case-insensitive check)
      for (var range in _policeHierarchy.keys) {
         final districtMap = _policeHierarchy[range] ?? {};
         // Check if any key matches targetDistrict (ignore case/space)
         final matchedKey = districtMap.keys.firstWhere(
           (k) => k.trim().toLowerCase() == targetDistrict!.trim().toLowerCase(),
           orElse: () => '',
         );
         
         if (matchedKey.isNotEmpty) {
           targetRange = range;
           // Update targetDistrict to the exact key found in JSON for lookup
           targetDistrict = matchedKey; 
           break;
         }
      }
    }

    List<String> stations = [];

    // If we have a target range and district, ensure we match the exact key in the JSON
    if (targetRange != null && targetDistrict != null) {
      final districtMap = _policeHierarchy[targetRange] ?? {};
      // Try exact match first
      if (districtMap.containsKey(targetDistrict)) {
        stations = List.from(districtMap[targetDistrict] ?? []);
      } else {
        // Try case-insensitive match
        final matchedKey = districtMap.keys.firstWhere(
          (k) => k.trim().toLowerCase() == targetDistrict!.trim().toLowerCase(),
          orElse: () => '',
        );
        if (matchedKey.isNotEmpty) {
          stations = List.from(districtMap[matchedKey] ?? []);
        }
      }
    } else if (targetDistrict != null) { // Fallback global search
       for (var range in _policeHierarchy.keys) {
         final districtMap = _policeHierarchy[range] ?? {};
         final matchedKey = districtMap.keys.firstWhere(
           (k) => k.trim().toLowerCase() == targetDistrict!.trim().toLowerCase(),
           orElse: () => '',
         );
         if (matchedKey.isNotEmpty) {
            stations = List.from(districtMap[matchedKey] ?? []);
            break; 
         }
       }
    }

    // MERGE WITH DYNAMIC STATIONS FROM FETCHED CASES
    // This handles missing data in JSON (e.g. Commissionerates) 
    // and ensures all actual active stations are listed.
    try {
      final caseProvider = Provider.of<CaseProvider>(context, listen: false);
      final dynamicStations = caseProvider.cases
          .where((c) => c.policeStation != null && c.policeStation!.isNotEmpty)
          .map((c) => c.policeStation!)
          .toSet();
      
      for (final s in dynamicStations) {
        if (!stations.contains(s)) {
          stations.add(s);
        }
      }
    } catch (e) {
      // Ignore errors if provider not ready
    }

    stations.sort();
    return stations;
  }

  /* ================= HANDLERS ================= */

  void _onRangeChanged(String? range) {
    setState(() {
      _selectedRange = range;
      _selectedDistrict = null;
      _selectedStation = null;
    });
    _fetchData();
  }

  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedStation = null;
    });
    _fetchData();
  }

  void _onStationChanged(String? station) {
    setState(() {
      _selectedStation = station;
    });
    _fetchData();
  }

  /* ================= BUILDERS ================= */

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Logic moved to initState and _loadProfileAndFetch
    // Leaving empty or minimal to avoid double-fetching
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = Provider.of<CaseProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    const Color orange = Color(0xFFFC633C);

    print('📱 [CASES_SCREEN] Screen built');
    print('📚 [CASES_SCREEN] Can pop: ${Navigator.of(context).canPop()}');

    // Show loading state
    if (_hierarchyLoading && Provider.of<AuthProvider>(context).role == 'police') {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F3F6),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading police hierarchy data...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show error state with retry option (only for police)
    if (_policeHierarchy.isEmpty && 
        Provider.of<AuthProvider>(context).role == 'police') {
      return Scaffold(
        backgroundColor: const Color(0xFFF1F3F6),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to Load Police Stations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unknown Error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      // Slightly darker background so white cards stand out clearly
      backgroundColor: const Color(0xFFF1F3F6),
      body: SafeArea(
        child: Column(
          children: [
            // Show warning if using Firestore fallback
            if (_usingFirestoreFallback && Provider.of<AuthProvider>(context).role == 'police')
              Container(
                width: double.infinity,
                color: Colors.orange.shade50,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Using fallback data. Some stations may be missing. Tap retry to reload from asset.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _loadHierarchyData(retry: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            // HEADER: Arrow + Title + New Case Button (all in one row)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: Row(
                children: [
                  // Pure Orange Back Arrow
                  GestureDetector(
                    onTap: () {
                      print('⬅️ [CASES_SCREEN] Back button pressed');
                      Navigator.of(context).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: orange,
                        size: 32,
                        shadows: const [
                          Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Title
                  Expanded(
                    child: Text(
                      localizations.allCases,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  // New Case Button — same row, right aligned
                  ElevatedButton.icon(
                    onPressed: () {
                      print('🆕 [CASES_SCREEN] New Case button pressed');
                      context.push('/cases/new');
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(localizations.newCase),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),

            // Subheading under title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  localizations.casesScreenSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),

            // SEARCH & FILTERS,

            // SEARCH & FILTERS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by FIR number, title, complainant...',
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
                            localizations.filters,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // JURISDICTION FILTERS (For Police)
                          if (Provider.of<AuthProvider>(context).role == 'police' && !_hierarchyLoading) ...[
                             if (_canFilterByRange()) ...[
                                _buildFilterDropdown(
                                  label: localizations.range,
                                  value: _selectedRange,
                                  items: _getAvailableRanges(),
                                  onChanged: _onRangeChanged,
                                ),
                                const SizedBox(width: 8),
                             ],
                             if (_canFilterByDistrict()) ...[
                                _buildFilterDropdown(
                                  label: localizations.district,
                                  value: _selectedDistrict,
                                  items: _getAvailableDistricts(),
                                  onChanged: _onDistrictChanged,
                                ),
                                const SizedBox(width: 8),
                             ],
                             if (_canFilterByStation()) ...[
                                _buildFilterDropdown(
                                  label: localizations.policeStation,
                                  value: _selectedStation,
                                  items: _getAvailableStations(),
                                  onChanged: _onStationChanged,
                                ),
                                const SizedBox(width: 8),
                             ],
                          ],

                          // Only show Station chip if NOT police (since police use hierarchy above)
                          if (Provider.of<AuthProvider>(context).role != 'police') ...[
                            _buildFilterChip<String>(
                              label: localizations.policeStation,
                              value: _selectedStation,
                              options: {
                                for (final c in caseProvider.cases)
                                  if (c.policeStation != null)
                                    c.policeStation!: c.policeStation!,
                              }.values.toList(),
                              onSelected: (value) {
                                setState(() => _selectedStation = value);
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                          _buildFilterChip<String>(
                            label: localizations.status,
                            value: _selectedStatus,
                            options: CaseStatus.values
                                .map((s) => s.displayName)
                                .toList(),
                            onSelected: (value) {
                              setState(() => _selectedStatus = value);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip<String>(
                            label: localizations.age,
                            value: _selectedAgeRange,
                            options: const [
                              'Below 18',
                              '18-30',
                              '31-50',
                              'Above 50',
                            ],
                            onSelected: (value) {
                              setState(() => _selectedAgeRange = value);
                            },
                          ),
                          
                          // Info Icon (Police Only) - At the end of filters
                          if (Provider.of<AuthProvider>(context).role == 'police') ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _showAccessLevelDialog,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // MAIN LIST
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFilteredList(caseProvider, localizations, orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredList(
    CaseProvider caseProvider,
    AppLocalizations localizations,
    Color orange,
  ) {
    if (caseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (caseProvider.error != null) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading cases',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  caseProvider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Apply in-memory filters
    final filteredCases = caseProvider.cases.where((c) {
      // Search query
      final query = _searchQuery;
      if (query != null && query.isNotEmpty) {
        final haystack = [
          c.title,
          c.firNumber,
          c.complainantName,
          c.victimName,
          c.policeStation,
          c.district,
        ]
            .whereType<String>()
            .join(' ')
            .toLowerCase();
        if (!haystack.contains(query)) return false;
      }

      // Station filter (Skip if police, as handled by backend fetch)
      // For non-police (user view), keep client side filter
      if (Provider.of<AuthProvider>(context, listen: false).role != 'police' &&
          _selectedStation != null &&
          _selectedStation!.isNotEmpty &&
          c.policeStation != _selectedStation) {
        return false;
      }

      // Status filter
      if (_selectedStatus != null &&
          _selectedStatus!.isNotEmpty &&
          c.status.displayName != _selectedStatus) {
        return false;
      }

      // Age filter (based on complainantAge if available)
      if (_selectedAgeRange != null && _selectedAgeRange!.isNotEmpty) {
        final age = int.tryParse(c.complainantAge ?? '');
        if (age != null) {
          switch (_selectedAgeRange) {
            case 'Below 18':
              if (age >= 18) return false;
              break;
            case '18-30':
              if (age < 18 || age > 30) return false;
              break;
            case '31-50':
              if (age < 31 || age > 50) return false;
              break;
            case 'Above 50':
              if (age <= 50) return false;
              break;
          }
        }
      }

      return true;
    }).toList();

    if (filteredCases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              localizations.noCasesFound,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredCases.length,
      itemBuilder: (context, index) {
        final caseItem = filteredCases[index];
        final filedDate = _formatDate(caseItem.dateFiled.toDate());
        final lastUpdated = _formatDate(caseItem.lastUpdated.toDate());

        return Card(
          elevation: 2,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              print('📝 [CASES_SCREEN] Case card tapped: ${caseItem.id}');
              context.push('/cases/${caseItem.id}');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: orange,
                        child: const Icon(Icons.gavel, color: Colors.white, size: 18),
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
                                    caseItem.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(caseItem.status)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    caseItem.status.displayName,
                                    style: TextStyle(
                                      color: _statusColor(caseItem.status),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'FIR No: ${caseItem.firNumber} | Filed: $filedDate',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (caseItem.policeStation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Station: ${caseItem.policeStation!}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            if (caseItem.complainantName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Complainant: ${caseItem.complainantName!}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Last Updated: $lastUpdated',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          print('🔍 [CASES_SCREEN] View Details button pressed: ${caseItem.id}');
                          context.push('/cases/${caseItem.id}');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          localizations.viewDetails,
                          style: const TextStyle(fontSize: 13),
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
    );
  }

  void _showAccessLevelDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.yourAccessLevel, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccessInfoRow('Rank', _policeRank),
            const SizedBox(height: 8),
            _buildAccessInfoRow('Range', _policeRange),
            const SizedBox(height: 8),
            _buildAccessInfoRow('District', _policeDistrict),
            const SizedBox(height: 8),
            _buildAccessInfoRow('Station', _policeStation),
            const SizedBox(height: 16),
            Text(
              localizations.filterCasesUsingFilters,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.ok, style: const TextStyle(color: Color(0xFFFC633C))),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildAccessInfoRow(String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'N/A',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip<T>({
    required String label,
    required T? value,
    required List<T> options,
    required void Function(T?) onSelected,
  }) {
    // ... existing implementation ...
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
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    // ... existing implementation ...
    return InkWell(
      onTap: () async {
        if (items.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No $label options available')),
          );
          return;
        }

        final searchController = TextEditingController();
        List<String> filtered = List.from(items);

        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => StatefulBuilder(
            builder: (context, setModalState) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text('Select $label',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            filtered = items
                                .where((e) =>
                                    e.toLowerCase().contains(val.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return ListTile(
                              title: Text('All $label'),
                              onTap: () {
                                onChanged(null);
                                Navigator.pop(context);
                              },
                            );
                          }
                          final item = filtered[i - 1];
                          return ListTile(
                            title: Text(item),
                            selected: item == value,
                            trailing: item == value
                                ? const Icon(Icons.check, color: Colors.green)
                                : null,
                            onTap: () {
                              onChanged(item);
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
          ),
        );
      },
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
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}