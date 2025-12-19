import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:Dharma/models/petition.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/providers/police_auth_provider.dart';

class PolicePetitionsScreen extends StatefulWidget {
  const PolicePetitionsScreen({super.key});

  @override
  State<PolicePetitionsScreen> createState() =>
      _PolicePetitionsScreenState();
}

class _PolicePetitionsScreenState extends State<PolicePetitionsScreen> {
  String? _stationName;

  /// 🔎 FILTER STATE
  String? _searchQuery = '';
  String? _selectedPoliceStatus;
  String? _selectedType;
  DateTime? _fromDate;
  DateTime? _toDate;

  /* ---------------- INIT ---------------- */
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final policeProvider = context.read<PoliceAuthProvider>();
      final station = policeProvider.policeProfile?['stationName'];

      if (station != null && station.toString().trim().isNotEmpty) {
        setState(() => _stationName = station.toString().trim());
        debugPrint('✅ Station loaded: $_stationName');
      } else {
        debugPrint('❌ Station name not found');
      }
    });
  }
  /* ---------------- FILTER LOGIC ---------------- */
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

      return true;
    }).toList();
  }

  /* ---------------- HELPERS ---------------- */
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

  /* ---------------- PETITION DETAIL (UNCHANGED) ---------------- */
  void _showPetitionDetails(BuildContext context, Petition petition) {
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

                    Text('Petitioner: ${petition.petitionerName}'),
                    Text('Phone: ${petition.phoneNumber ?? "-"}'),
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

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    if (_stationName == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Petitions – $_stationName')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('petitions')
            .where('stationName', isEqualTo: _stationName)
            .orderBy('createdAt', descending: true)
            .snapshots(),
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
              // SEARCH & FILTERS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                _fromDate != null ||
                                _toDate != null ||
                                (_searchQuery != null && _searchQuery!.isNotEmpty))
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPoliceStatus = null;
                                    _selectedType = null;
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
}
