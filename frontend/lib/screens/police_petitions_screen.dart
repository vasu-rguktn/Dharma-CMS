import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

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
        '🔎 Filters → status=$_selectedPoliceStatus type=$_selectedType fromDate=$_fromDate toDate=$_toDate');
    return petitions.where((p) {
      // Filter by police status
      if (_selectedPoliceStatus != null &&
          p.policeStatus != _selectedPoliceStatus) {
        return false;
      }
      
      // Filter by type - compare display names
      if (_selectedType != null && p.type.displayName != _selectedType) {
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

              /// 🔎 FILTER BAR
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Row 1: Status and Type dropdowns
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        DropdownButton<String>(
                          hint: const Text('Police Status'),
                          value: _selectedPoliceStatus,
                          items: const [
                            DropdownMenuItem(
                                value: 'Pending', child: Text('Pending')),
                            DropdownMenuItem(
                                value: 'Received', child: Text('Received')),
                            DropdownMenuItem(
                                value: 'In Progress',
                                child: Text('In Progress')),
                            DropdownMenuItem(
                                value: 'Closed', child: Text('Closed')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedPoliceStatus = v),
                        ),
                        DropdownButton<String>(
                          hint: const Text('Petition Type'),
                          value: _selectedType,
                          items: const [
                            DropdownMenuItem(
                                value: 'Bail Application', 
                                child: Text('Bail Application')),
                            DropdownMenuItem(
                                value: 'Anticipatory Bail',
                                child: Text('Anticipatory Bail')),
                            DropdownMenuItem(
                                value: 'Revision Petition', 
                                child: Text('Revision Petition')),
                            DropdownMenuItem(
                                value: 'Appeal', 
                                child: Text('Appeal')),
                            DropdownMenuItem(
                                value: 'Writ Petition', 
                                child: Text('Writ Petition')),
                            DropdownMenuItem(
                                value: 'Quashing Petition', 
                                child: Text('Quashing Petition')),
                            DropdownMenuItem(
                                value: 'Other', 
                                child: Text('Other')),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedType = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Row 2: Date filters
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
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
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _fromDate == null
                                ? 'From Date'
                                : 'From: ${_formatTimestamp(Timestamp.fromDate(_fromDate!))}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
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
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _toDate == null
                                ? 'To Date'
                                : 'To: ${_formatTimestamp(Timestamp.fromDate(_toDate!))}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedPoliceStatus = null;
                              _selectedType = null;
                              _fromDate = null;
                              _toDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Clear All Filters'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// 📋 LIST OR EMPTY STATE
              Expanded(
                child: petitions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.filter_list_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matching petitions',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              allPetitions.isEmpty
                                  ? 'No petitions registered yet'
                                  : 'Try adjusting the filters above',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: petitions.length,
                        itemBuilder: (_, i) {
                          final p = petitions[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showPetitionDetails(context, p),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.title,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold),
                                          ),
                                        ),
                                        if (p.policeStatus != null)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getPoliceStatusColor(
                                                  p.policeStatus!),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              p.policeStatus!,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          )
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(p.petitionerName,
                                        style: TextStyle(
                                            color:
                                                Colors.grey.shade600)),
                                    Text(
                                      'Created: ${_formatTimestamp(p.createdAt)}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
