import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:Dharma/data/revised_police_hierarchy.dart'; // ✅ Use Revised Data

class AssignPetitionDialog extends StatefulWidget {
  final String assigningOfficerRank;
  final String? district;
  final String? stationName;
  final String? range;
  final String? petitionId;
  final String? currentAssignedTo;

  const AssignPetitionDialog({
    required this.assigningOfficerRank,
    this.district,
    this.stationName,
    this.range,
    this.petitionId,
    this.currentAssignedTo,
    super.key,
  });

  @override
  State<AssignPetitionDialog> createState() => _AssignPetitionDialogState();
}

class _AssignPetitionDialogState extends State<AssignPetitionDialog> {
  // Rank hierarchy
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

  // Hierarchy data
  Map<String, Map<String, List<String>>> _policeHierarchy = {};
  List<dynamic> _deepDistricts = []; // ✅ New deep data
  bool _hierarchyLoading = true;

  // Assignment type: 'range', 'district', 'sdpo', 'circle', 'station'
  String? _assignmentType;

  // Location selections
  String? _selectedRange;
  String? _selectedDistrict;
  String? _selectedSDPO; // ✅ New
  String? _selectedCircle; // ✅ New
  String? _selectedStation;

  @override
  void initState() {
    super.initState();
    _loadHierarchyData();
  }

  Future<void> _loadHierarchyData() async {
    debugPrint('🔄 [AssignDialog] Loading Revised Hierarchy Data...');
    try {
      // 1. Load Legacy (For Range Mapping if needed, or build it from revised)
      final jsonStr = await rootBundle
          .loadString('assets/data/ap_police_hierarchy_complete.json');
      final Map<String, dynamic> data = json.decode(jsonStr);
      
      Map<String, Map<String, List<String>>> hierarchy = {};
      data.forEach((range, districts) {
        if (districts is Map) {
          Map<String, List<String>> districtMap = {};
          districts.forEach((district, stations) {
             districtMap[district.toString()] = [];
          });
          hierarchy[range] = districtMap;
        }
      });

      // 2. Load Deep Data from Revised Data
      // ignore: undefined_identifier
      final districtsList = kRevisedPoliceHierarchy['districts'] as List<dynamic>? ?? [];
      debugPrint('✅ [AssignDialog] Revised Deep hierarchy loaded. Districts count: ${districtsList.length}');
      
      // Update local hierarchy map with ranges from deep data if possible
      // (Optional: Rebuild _policeHierarchy from deep data for consistency)

      if (mounted) {
        setState(() {
          _policeHierarchy = hierarchy;
          _deepDistricts = districtsList;
          _hierarchyLoading = false;
          
          // Pre-select based on officer's rank
          if (_isStateLevelRank()) {
            // DGP
          } else if (_isRangeLevelRank()) {
            if (widget.range != null) _selectedRange = widget.range;
          } else if (_isDistrictLevelRank()) {
            if (widget.range != null) _selectedRange = widget.range;
            else if (widget.district != null) _selectedRange = _findRangeForDistrict(widget.district!);
            _selectedDistrict = widget.district;
          }
        });
      }
    } catch (e, stack) {
      debugPrint('❌ [AssignDialog] Error loading hierarchy: $e');
      debugPrint('❌ [AssignDialog] Stack trace: $stack');
      if (mounted) setState(() => _hierarchyLoading = false);
    }
  }

  bool _isStateLevelRank() =>
      _stateLevelRanks.contains(widget.assigningOfficerRank);
  bool _isRangeLevelRank() =>
      _rangeLevelRanks.contains(widget.assigningOfficerRank);
  bool _isDistrictLevelRank() =>
      _districtLevelRanks.contains(widget.assigningOfficerRank);

  String? _findRangeForDistrict(String district) {
    for (final range in _policeHierarchy.keys) {
      if (_policeHierarchy[range]?.containsKey(district) ?? false) {
        return range;
      }
    }
    return null;
  }

  List<String> _getAvailableRanges() => _policeHierarchy.keys.toList();

  List<String> _getAvailableDistricts() {
    if (_selectedRange == null) return [];
    return _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
  }

  // Deep Data Getters
  Map<String, dynamic>? _getCurrentDistrictObj() {
    if (_selectedDistrict == null) return null;
    try {
      debugPrint('🔍 [AssignDialog] Looking for District: "$_selectedDistrict"');
      
      dynamic match;
      for (var d in _deepDistricts) {
          final dataName = d['name'].toString().toLowerCase().trim(); // e.g., "sp eluru"
          final selected = _selectedDistrict!.toLowerCase().trim();   // e.g., "eluru"
          
          if (dataName == selected || 
              dataName == "sp $selected" || 
              dataName.toString().replaceFirst('sp ', '').trim() == selected) {
            match = d;
            break;
          }
      }

      if (match != null) {
        debugPrint('✅ [AssignDialog] Found District Match: "${match['name']}"');
      } else {
        debugPrint('❌ [AssignDialog] No District Match found for: "$_selectedDistrict" in ${_deepDistricts.length} districts.');
      }
      return match as Map<String, dynamic>?;
    } catch (e) { 
      debugPrint('❌ [AssignDialog] Error finding district: $e');
      return null; 
    }
  }

  List<String> _getAvailableSDPOs() {
    final distObj = _getCurrentDistrictObj();
    if (distObj == null) {
      debugPrint('⚠️ [AssignDialog] Cannot load SDPOs because district object is null.');
      return [];
    }
    final sdpos = distObj['sdpos'] as List<dynamic>? ?? [];
    debugPrint('✅ [AssignDialog] Loaded ${sdpos.length} SDPOs for district.');
    return sdpos.map((s) => s['name'] as String).toList();
  }

  Map<String, dynamic>? _getCurrentSDPOObj() {
    final distObj = _getCurrentDistrictObj();
    if (distObj == null || _selectedSDPO == null) return null;
    final sdpos = distObj['sdpos'] as List<dynamic>? ?? [];
    try {
      debugPrint('🔍 [AssignDialog] Looking for SDPO: "$_selectedSDPO"');
      for (var s in sdpos) {
        if (s['name'].toString().trim() == _selectedSDPO!.trim()) {
           debugPrint('✅ [AssignDialog] Found SDPO Match: "${s['name']}"');
           return s;
        }
      }
      debugPrint('❌ [AssignDialog] No SDPO Match found for "$_selectedSDPO"');
      return null;
    } catch (e) { return null; }
  }

  List<String> _getAvailableCircles() {
    final sdpoObj = _getCurrentSDPOObj();
    if (sdpoObj == null) {
      debugPrint('⚠️ [AssignDialog] Cannot load Circles because SDPO object is null.');
      return [];
    }
    final circles = sdpoObj['circles'] as List<dynamic>? ?? [];
    debugPrint('✅ [AssignDialog] Loaded ${circles.length} Circles for SDPO.');
    return circles.map((c) => c['name'] as String).toList();
  }

  Map<String, dynamic>? _getCurrentCircleObj() {
    final sdpoObj = _getCurrentSDPOObj();
    if (sdpoObj == null || _selectedCircle == null) return null;
    final circles = sdpoObj['circles'] as List<dynamic>? ?? [];
    try {
       debugPrint('🔍 [AssignDialog] Looking for Circle: "$_selectedCircle"');
       for (var c in circles) {
         if (c['name'].toString().trim() == _selectedCircle!.trim()) {
            debugPrint('✅ [AssignDialog] Found Circle Match: "${c['name']}"');
            return c;
         }
       }
       debugPrint('❌ [AssignDialog] No Circle Match found for "$_selectedCircle"');
       return null;
    } catch (e) { return null; }
  }

  List<String> _getAvailableStations() {
    // Rely on Circle
    final circleObj = _getCurrentCircleObj();
    if (circleObj == null) {
       debugPrint('⚠️ [AssignDialog] Cannot load Stations because Circle object is null.');
       return [];
    }
    final stations = circleObj['police_stations'] as List<dynamic>? ?? [];
    debugPrint('✅ [AssignDialog] Loaded ${stations.length} Stations for Circle.');
    return stations.map((s) => s.toString()).toList();
  }

  void _handleAssignment() {
    // Prepare assignment data based on type
    Map<String, dynamic> assignmentData = {};

    if (_assignmentType == 'range' && _selectedRange != null) {
      assignmentData = {
        'assignmentType': 'range',
        'assignedToRange': _selectedRange,
        'assignedToRangeName': _selectedRange,
        'targetRole': 'Inspector General of Police', // Approximate
        'targetUnit': _selectedRange,
      };
    } else if (_assignmentType == 'district' && _selectedDistrict != null) {
      assignmentData = {
        'assignmentType': 'district',
        'assignedToDistrict': _selectedDistrict,
        'assignedToDistrictName': _selectedDistrict,
        'assignedToRange': _selectedRange,
        'targetRole': 'Superintendent of Police',
        'targetUnit': _selectedDistrict,
      };
    } else if (_assignmentType == 'sdpo' && _selectedSDPO != null) {
      assignmentData = {
        'assignmentType': 'sdpo',
        'assignedToSDPO': _selectedSDPO, // New field
        'assignedToDistrict': _selectedDistrict,
        'assignedToRange': _selectedRange,
        'targetRole': 'Deputy Superintendent of Police',
        'targetUnit': _selectedSDPO,
      };
    } else if (_assignmentType == 'circle' && _selectedCircle != null) {
      assignmentData = {
        'assignmentType': 'circle',
        'assignedToCircle': _selectedCircle, // New field
        'assignedToSDPO': _selectedSDPO,
        'assignedToDistrict': _selectedDistrict,
        'assignedToRange': _selectedRange,
        'targetRole': 'Inspector of Police',
        'targetUnit': _selectedCircle,
      };
    } else if (_assignmentType == 'station' && _selectedStation != null) {
      assignmentData = {
        'assignmentType': 'station',
        'assignedToStation': _selectedStation,
        'assignedToStationName': _selectedStation,
        'assignedToCircle': _selectedCircle,
        'assignedToSDPO': _selectedSDPO,
        'assignedToDistrict': _selectedDistrict,
        'assignedToRange': _selectedRange,
        'targetRole': 'Station House Officer',
        'targetUnit': _selectedStation,
      };
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the selection')),
      );
      return;
    }

    Navigator.pop(context, assignmentData);
  }

  void _showSearchableSelection({
    required String title,
    required List<String> items,
    required String? selectedValue,
    required Function(String) onSelected,
  }) {
    String searchQuery = '';
    List<String> filteredItems = List.from(items);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value.toLowerCase();
                          filteredItems = items
                              .where((item) =>
                                  item.toLowerCase().contains(searchQuery))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: filteredItems.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No matches found'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final isSelected = item == selectedValue;
                                return ListTile(
                                  title: Text(
                                    item,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.blue.shade700
                                          : null,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? Icon(Icons.check,
                                          color: Colors.blue.shade700)
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Assign Petition V2', // Changed title
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            if (_hierarchyLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading hierarchy data...',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Info Card
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Assign this petition to a Range, District, or Police Station',
                                style: TextStyle(color: Colors.blue.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Assignment Selection
                    _buildAssignmentSection(),
                  ],
                ),
              ),

            // Footer with Assign Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _assignmentType != null ? _handleAssignment : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Assign Petition'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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

  Widget _buildAssignmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Assignment Target',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // 1. Range Level
        if (_isStateLevelRank()) ...[
          _buildRangeAssignmentCard(),
          const SizedBox(height: 12),
        ],

        // 2. District Level
        if (_selectedRange != null && (_isStateLevelRank() || _isRangeLevelRank())) ...[
           _buildDistrictAssignmentCard(),
           const SizedBox(height: 12),
        ],

        // 3. SDPO Level (Show if District selected)
        if (_selectedDistrict != null) ...[
          if (_isDistrictLevelRank()) ...[
             // SP sees SDPO card directly
             Text(
              'Your District: $_selectedDistrict',
              style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
          ],
          _buildSDPOAssignmentCard(),
          const SizedBox(height: 12),
        ],

        // 4. Circle Level (Show if SDPO selected)
        if (_selectedSDPO != null) ...[
          _buildCircleAssignmentCard(),
          const SizedBox(height: 12),
        ],

        // 5. Station Level (Show if Circle selected - or just show if SDPO selected for direct?)
        // Hierarchy is strict: Circle -> Station.
        if (_selectedCircle != null) ...[
          _buildStationAssignmentCard(),
        ],
      ],
    );
  }

  Widget _buildRangeAssignmentCard() {
    return Card(
      elevation: _assignmentType == 'range' ? 4 : 1,
      color: _assignmentType == 'range' ? Colors.blue.shade50 : null,
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'range',
            groupValue: _assignmentType,
            onChanged: (value) => setState(() {
              _assignmentType = value;
              _selectedDistrict = null;
              _selectedSDPO = null;
              _selectedCircle = null;
              _selectedStation = null;
            }),
            title: const Text('Assign to Range', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Assign to IG/DIG of Range'),
          ),
          if (_assignmentType == 'range') ...[
            const Divider(),
            _buildSearchableField('Select Range', _selectedRange, _getAvailableRanges(), (val) {
              setState(() => _selectedRange = val);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDistrictAssignmentCard() {
    return Card(
      elevation: _assignmentType == 'district' ? 4 : 1,
      color: _assignmentType == 'district' ? Colors.green.shade50 : null,
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'district',
            groupValue: _assignmentType,
            onChanged: (value) => setState(() {
              _assignmentType = value;
               _selectedSDPO = null;
              _selectedCircle = null;
              _selectedStation = null;
            }),
            title: const Text('Assign to District', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Assign to SP of District'),
          ),
          if (_assignmentType == 'district') ...[
            const Divider(),
             _buildSearchableField('Select District (SP)', _selectedDistrict, _getAvailableDistricts(), (val) {
              setState(() => _selectedDistrict = val);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSDPOAssignmentCard() {
    return Card(
      elevation: _assignmentType == 'sdpo' ? 4 : 1,
      color: _assignmentType == 'sdpo' ? Colors.purple.shade50 : null,
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'sdpo',
            groupValue: _assignmentType,
            onChanged: (value) => setState(() {
              _assignmentType = value;
              _selectedCircle = null;
              _selectedStation = null;
            }),
            title: const Text('Assign to DSP (Sub-Division)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Assign to DSP of SDPO'),
          ),
          if (_assignmentType == 'sdpo') ...[
            const Divider(),
             _buildSearchableField('Select DSP (Sub-Division)', _selectedSDPO, _getAvailableSDPOs(), (val) {
              setState(() => _selectedSDPO = val);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCircleAssignmentCard() {
    return Card(
      elevation: _assignmentType == 'circle' ? 4 : 1,
      color: _assignmentType == 'circle' ? Colors.teal.shade50 : null,
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'circle',
            groupValue: _assignmentType,
            onChanged: (value) => setState(() {
              _assignmentType = value;
              _selectedStation = null;
            }),
            title: const Text('Assign to Circle Inspector', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Assign to CI of Circle'),
          ),
          if (_assignmentType == 'circle') ...[
            const Divider(),
             _buildSearchableField('Select Circle Inspector (Circle)', _selectedCircle, _getAvailableCircles(), (val) {
              setState(() => _selectedCircle = val);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStationAssignmentCard() {
    return Card(
      elevation: _assignmentType == 'station' ? 4 : 1,
      color: _assignmentType == 'station' ? Colors.orange.shade50 : null,
      child: Column(
        children: [
          RadioListTile<String>(
            value: 'station',
            groupValue: _assignmentType,
            onChanged: (value) => setState(() => _assignmentType = value),
            title: const Text('Assign to SHO (Station)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Assign to SHO of Police Station'),
          ),
          if (_assignmentType == 'station') ...[
            const Divider(),
             _buildSearchableField('Select SHO (Station)', _selectedStation, _getAvailableStations(), (val) {
              setState(() => _selectedStation = val);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchableField(String label, String? value, List<String> items, Function(String) onSelect) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _showSearchableSelection(
          title: label,
          items: items,
          selectedValue: value,
          onSelected: onSelect,
        ),
        child: IgnorePointer(
          child: TextFormField(
            controller: TextEditingController(text: value),
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.check_circle_outline),
              suffixIcon: const Icon(Icons.search),
            ),
          ),
        ),
      ),
    );
  }
}
