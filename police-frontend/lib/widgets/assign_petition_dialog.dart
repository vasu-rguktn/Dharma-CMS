import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:Dharma/data/revised_police_hierarchy.dart';
import 'package:Dharma/utils/rank_utils.dart';

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

class _AssignPetitionDialogState extends State<AssignPetitionDialog>
    with SingleTickerProviderStateMixin {
  // Flattened Data Lists
  List<Map<String, dynamic>> _districtsList = []; // For Range/State officers
  List<Map<String, dynamic>> _sdposList = [];
  List<Map<String, dynamic>> _circlesList = [];
  List<Map<String, dynamic>> _stationsList = [];

  // Filtered Lists for Search
  List<Map<String, dynamic>> _filteredDistricts = [];
  List<Map<String, dynamic>> _filteredSdpos = [];
  List<Map<String, dynamic>> _filteredCircles = [];
  List<Map<String, dynamic>> _filteredStations = [];

  bool _isLoading = true;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Tabs configuration
  List<String> _tabTitles = [];

  @override
  void initState() {
    super.initState();
    _loadAndFlattenData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDistricts = _filterList(_districtsList, query);
      _filteredSdpos = _filterList(_sdposList, query);
      _filteredCircles = _filterList(_circlesList, query);
      _filteredStations = _filterList(_stationsList, query);
    });
  }

  List<Map<String, dynamic>> _filterList(
      List<Map<String, dynamic>> list, String query) {
    if (query.isEmpty) return list;
    return list.where((item) {
      final name = item['name'].toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  Future<void> _loadAndFlattenData() async {
    // Simulate async if needed, but data is local const
    await Future.delayed(Duration.zero);

    try {
      final allDistricts =
          kRevisedPoliceHierarchy['districts'] as List<dynamic>? ?? [];

      _districtsList.clear();
      _sdposList.clear();
      _circlesList.clear();
      _stationsList.clear();

      // Determined Scope
      bool isStateLevel =
          ['DGP', 'ADGP'].contains(RankUtils.normalizeRank(widget.assigningOfficerRank)) ||
          widget.assigningOfficerRank.contains('Director General');
      
      bool isRangeLevel =
          RankUtils.isRangeLevelOfficer(widget.assigningOfficerRank);
      
      bool isDistrictLevel =
          RankUtils.isDistrictLevelOfficer(widget.assigningOfficerRank);

      // Filter Districts based on Scope
      for (var districtObj in allDistricts) {
        String dName = districtObj['name'];
        String dRange = districtObj['range'] ?? '';

        // Scope Filters
        if (isRangeLevel &&
            widget.range != null &&
            !dRange.toLowerCase().contains(widget.range!.toLowerCase())) {
          continue;
        }
        if (isDistrictLevel &&
            widget.district != null &&
            !_matchDistrictName(dName, widget.district!)) {
          continue;
        }

        // Add to Districts List (Only for State/Range officers)
        if (isStateLevel || isRangeLevel) {
          _districtsList.add({
            'name': dName,
            'range': dRange,
            'type': 'district',
            'role': 'Superintendent of Police',
            'raw': districtObj,
          });
        }

        // Drill down to SDPOs
        final sdpos = districtObj['sdpos'] as List<dynamic>? ?? [];
        for (var sdpoObj in sdpos) {
          String sName = sdpoObj['name'];
          
          _sdposList.add({
            'name': sName,
            'district': dName,
            'range': dRange,
            'type': 'sdpo',
            'role': 'Deputy Superintendent of Police',
            'raw': sdpoObj,
          });

          // Drill down to Circles
          final circles = sdpoObj['circles'] as List<dynamic>? ?? [];
          for (var circleObj in circles) {
            String cName = circleObj['name'];
            
             _circlesList.add({
              'name': cName,
              'sdpo': sName,
              'district': dName,
              'range': dRange,
              'type': 'circle',
              'role': 'Circle Inspector',
              'raw': circleObj,
            });

            // Drill down to Stations
            // Note: In kRevisedPoliceHierarchy, stations are just strings in a list
            final stations = circleObj['police_stations'] as List<dynamic>? ?? [];
            for (var stationName in stations) {
              _stationsList.add({
                'name': stationName.toString(),
                'circle': cName,
                'sdpo': sName,
                'district': dName,
                'range': dRange,
                'type': 'station',
                'role': 'Station House Officer',
              });
            }
          }
        }
      }

      // Configure Tabs based on populated lists
      _setupTabs(isStateLevel, isRangeLevel, isDistrictLevel);

      // Initial Filter
      _onSearchChanged();

    } catch (e) {
      debugPrint('Error flattening assignment data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _matchDistrictName(String dataName, String userDistrict) {
    final d1 = dataName.toLowerCase().replaceAll('sp ', '').trim();
    final d2 = userDistrict.toLowerCase().replaceAll('sp ', '').trim();
    return d1 == d2 || d1.contains(d2) || d2.contains(d1);
  }

  void _setupTabs(bool isState, bool isRange, bool isDistrict) {
    _tabTitles.clear();

    if (isState || isRange) {
      _tabTitles.add('Districts (SP)');
    }
    
    // Everyone sees these (filtered by their scope)
    _tabTitles.add('Sub-Divisions (DSP)');
    _tabTitles.add('Circles (CI)');
    _tabTitles.add('Stations (SHO)');

    // In case logic filtered everything out (edge case), add at least one
    if (_tabTitles.isEmpty) _tabTitles.add('Stations');

    _tabController = TabController(length: _tabTitles.length, vsync: this);
  }

  void _handleSelection(Map<String, dynamic> item) {
    Map<String, dynamic> result = {};

    final type = item['type'];
    final name = item['name'];

    // Construct the result map expected by the parent
    // Note: We include all higher-level context we have
    if (type == 'district') {
      result = {
        'assignmentType': 'district',
        'assignedToDistrict': name,
        'assignedToDistrictName': name, // Redundant but safe
        'assignedToRange': item['range'],
        'targetRole': item['role'],
        'targetUnit': name,
      };
    } else if (type == 'sdpo') {
      result = {
        'assignmentType': 'sdpo',
        'assignedToSDPO': name,
        'assignedToDistrict': item['district'],
        'assignedToRange': item['range'],
        'targetRole': item['role'],
        'targetUnit': name,
      };
    } else if (type == 'circle') {
      result = {
         'assignmentType': 'circle',
        'assignedToCircle': name,
        'assignedToSDPO': item['sdpo'],
        'assignedToDistrict': item['district'],
        'assignedToRange': item['range'],
        'targetRole': item['role'],
        'targetUnit': name,
      };
    } else if (type == 'station') {
      result = {
        'assignmentType': 'station',
        'assignedToStation': name,
        'assignedToStationName': name,
        'assignedToCircle': item['circle'],
        'assignedToSDPO': item['sdpo'],
        'assignedToDistrict': item['district'],
        'assignedToRange': item['range'],
        'targetRole': item['role'],
        'targetUnit': name,
      };
    }

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    // If loading
    if (_isLoading) {
      return const Dialog(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Constrain height if possible
        children: [
           // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment_ind, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Direct Assignment',
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

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search officer, station, or unit...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.blue.shade50,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.blue.shade800,
              unselectedLabelColor: Colors.grey.shade700,
              indicatorColor: Colors.blue.shade700,
              tabs: _tabTitles.map((t) => Tab(text: t)).toList(),
            ),
          ),

          // Tab View (List Content)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: TabBarView(
              controller: _tabController,
              children: _tabTitles.map((title) {
                if (title.contains('District')) return _buildList(_filteredDistricts, Icons.location_city);
                if (title.contains('Sub-Division')) return _buildList(_filteredSdpos, Icons.security);
                if (title.contains('Circle')) return _buildList(_filteredCircles, Icons.group_work);
                if (title.contains('Station')) return _buildList(_filteredStations, Icons.local_police);
                return const Center(child: Text('Unknown Tab'));
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, IconData icon) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No matching officers found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          title: Text(
            item['name'],
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            // Show relevant parent info for context
            _getContextSubtitle(item),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          trailing: ElevatedButton(
            onPressed: () => _handleSelection(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Assign'),
          ),
          onTap: () => _handleSelection(item),
        );
      },
    );
  }

  String _getContextSubtitle(Map<String, dynamic> item) {
    final type = item['type'];
    if (type == 'district') return 'Range: ${item['range']}';
    if (type == 'sdpo') return 'Dist: ${item['district']}';
    if (type == 'circle') return 'SDPO: ${item['sdpo']}';
    if (type == 'station') return 'Circle: ${item['circle']}';
    return '';
  }
}
