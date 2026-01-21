import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

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
  bool _hierarchyLoading = true;

  // Assignment type: 'range', 'district', or 'station'
  String? _assignmentType;

  // Location selections
  String? _selectedRange;
  String? _selectedDistrict;
  String? _selectedStation;

  @override
  void initState() {
    super.initState();
    _loadHierarchyData();
  }

  Future<void> _loadHierarchyData() async {
    try {
      final jsonStr = await rootBundle
          .loadString('assets/Data/ap_police_hierarchy_complete.json');
      final Map<String, dynamic> data = json.decode(jsonStr);

      Map<String, Map<String, List<String>>> hierarchy = {};
      
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

      setState(() {
        _policeHierarchy = hierarchy;
        _hierarchyLoading = false;
        
        // Pre-select based on officer's rank
        if (_isStateLevelRank()) {
          // DGP - no pre-selection
        } else if (_isRangeLevelRank()) {
          // IG/DIG - pre-select their range
          if (widget.range != null) {
            _selectedRange = widget.range;
          }
        } else if (_isDistrictLevelRank()) {
          // SP - pre-select range and district
          if (widget.range != null) {
            _selectedRange = widget.range;
          } else if (widget.district != null) {
            _selectedRange = _findRangeForDistrict(widget.district!);
          }
          _selectedDistrict = widget.district;
        }
      });
    } catch (e) {
      debugPrint('Error loading hierarchy: $e');
      setState(() => _hierarchyLoading = false);
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

  List<String> _getAvailableRanges() {
    return _policeHierarchy.keys.toList();
  }

  List<String> _getAvailableDistricts() {
    if (_selectedRange == null) return [];
    return _policeHierarchy[_selectedRange]?.keys.toList() ?? [];
  }

  List<String> _getAvailableStations() {
    if (_selectedRange == null || _selectedDistrict == null) return [];
    return _policeHierarchy[_selectedRange]?[_selectedDistrict] ?? [];
  }

  void _handleAssignment() {
    // Prepare assignment data based on type
    Map<String, dynamic> assignmentData = {};

    if (_assignmentType == 'range' && _selectedRange != null) {
      assignmentData = {
        'assignmentType': 'range',
        'assignedToRange': _selectedRange,
        'assignedToRangeName': _selectedRange,
      };
    } else if (_assignmentType == 'district' && _selectedDistrict != null) {
      assignmentData = {
        'assignmentType': 'district',
        'assignedToDistrict': _selectedDistrict,
        'assignedToDistrictName': _selectedDistrict,
        'assignedToRange': _selectedRange,
      };
    } else if (_assignmentType == 'station' && _selectedStation != null) {
      assignmentData = {
        'assignmentType': 'station',
        'assignedToStation': _selectedStation,
        'assignedToStationName': _selectedStation,
        'assignedToDistrict': _selectedDistrict,
        'assignedToRange': _selectedRange,
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
                      'Assign Petition',
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
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
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

        // DGP: Can assign to Range, District, or Station
        if (_isStateLevelRank()) ...[
          _buildRangeAssignmentCard(),
          const SizedBox(height: 12),
          if (_selectedRange != null) ...[
            _buildDistrictAssignmentCard(),
            const SizedBox(height: 12),
          ],
          if (_selectedRange != null && _selectedDistrict != null) ...[
            _buildStationAssignmentCard(),
          ],
        ],

        // IG: Can assign to District or Station (within their range)
        if (_isRangeLevelRank()) ...[
          if (_selectedRange != null) ...[
            Text(
              'Your Range: $_selectedRange',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            _buildDistrictAssignmentCard(),
            const SizedBox(height: 12),
            if (_selectedDistrict != null) ...[
              _buildStationAssignmentCard(),
            ],
          ] else ...[
            const Text('Range information not available'),
          ],
        ],

        // SP: Can only assign to Station (within their district)
        if (_isDistrictLevelRank()) ...[
          if (_selectedRange != null && _selectedDistrict != null) ...[
            Text(
              'Your District: $_selectedDistrict ($_selectedRange)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            _buildStationAssignmentCard(),
          ] else ...[
            const Text('District information not available'),
          ],
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
            onChanged: (value) {
              setState(() {
                _assignmentType = value;
                _selectedDistrict = null;
                _selectedStation = null;
              });
            },
            title: const Text(
              'Assign to Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Petition will go to IG/DIG of the selected Range'),
          ),
          if (_assignmentType == 'range') ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () => _showSearchableSelection(
                  title: 'Select Range',
                  items: _getAvailableRanges(),
                  selectedValue: _selectedRange,
                  onSelected: (value) {
                    setState(() {
                      _selectedRange = value;
                    });
                  },
                ),
                child: IgnorePointer(
                  child: TextFormField(
                    controller: TextEditingController(text: _selectedRange),
                    decoration: const InputDecoration(
                      labelText: 'Select Range',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map),
                      suffixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),
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
            onChanged: (value) {
              setState(() {
                _assignmentType = value;
                _selectedStation = null;
              });
            },
            title: const Text(
              'Assign to District',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Petition will go to SP of the selected District'),
          ),
          if (_assignmentType == 'district') ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () => _showSearchableSelection(
                  title: 'Select District',
                  items: _getAvailableDistricts(),
                  selectedValue: _selectedDistrict,
                  onSelected: (value) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                  },
                ),
                child: IgnorePointer(
                  child: TextFormField(
                    controller: TextEditingController(text: _selectedDistrict),
                    decoration: const InputDecoration(
                      labelText: 'Select District',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                      suffixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),
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
            onChanged: (value) {
              setState(() {
                _assignmentType = value;
              });
            },
            title: const Text(
              'Assign to Police Station',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Petition will go to officers at the selected Station'),
          ),
          if (_assignmentType == 'station') ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () => _showSearchableSelection(
                  title: 'Select Police Station',
                  items: _getAvailableStations(),
                  selectedValue: _selectedStation,
                  onSelected: (value) {
                    setState(() {
                      _selectedStation = value;
                    });
                  },
                ),
                child: IgnorePointer(
                  child: TextFormField(
                    controller: TextEditingController(text: _selectedStation),
                    decoration: const InputDecoration(
                      labelText: 'Select Police Station',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_police),
                      suffixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
