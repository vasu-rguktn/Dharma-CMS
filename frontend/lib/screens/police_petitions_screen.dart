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

  /* ---------------- INIT ---------------- */
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final policeProvider = context.read<PoliceAuthProvider>();
      final station = policeProvider.policeProfile?['stationName'];

      if (station != null && station.toString().trim().isNotEmpty) {
        setState(() {
          _stationName = station.toString().trim();
        });
        debugPrint('✅ Station loaded: $_stationName');
      } else {
        debugPrint('❌ Station name not found');
      }
    });
  }

  /* ---------------- HELPERS ---------------- */
  Color _getStatusColor(PetitionStatus status) {
    switch (status) {
      case PetitionStatus.draft:
        return Colors.grey;
      case PetitionStatus.filed:
        return Colors.blue;
      case PetitionStatus.underReview:
        return Colors.orange;
      case PetitionStatus.hearingScheduled:
        return Colors.purple;
      case PetitionStatus.granted:
        return Colors.green;
      case PetitionStatus.rejected:
        return Colors.red;
      case PetitionStatus.withdrawn:
        return Colors.brown;
    }
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
    final d = timestamp.toDate();
    return '${d.day}/${d.month}/${d.year}';
  }

  /* ---------------- PETITION DETAIL (ORIGINAL FEATURE) ---------------- */
  void _showPetitionDetails(BuildContext context, Petition petition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) {
          String? selectedStatus = petition.policeStatus;
          String? selectedSubStatus = petition.policeSubStatus;
          bool isSubmitting = false;

          return StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            petition.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// PETITION STATUS
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(petition.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        petition.status.displayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    const Divider(height: 32),

                    _detailRow('Petitioner', petition.petitionerName),
                    if (petition.phoneNumber != null)
                      _detailRow('Phone', petition.phoneNumber!),
                    if (petition.address != null)
                      _detailRow('Address', petition.address!),
                    if (petition.firNumber != null)
                      _detailRow('FIR No', petition.firNumber!),

                    const SizedBox(height: 16),
                    const Text(
                      'Grounds',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(petition.grounds),

                    const SizedBox(height: 24),

                    /// POLICE STATUS UPDATE
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
                        labelText: 'Select Status',
                        border: OutlineInputBorder(),
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
                      onChanged: (v) {
                        setModalState(() {
                          selectedStatus = v;
                          if (v != 'Closed') selectedSubStatus = null;
                        });
                      },
                    ),

                    if (selectedStatus == 'Closed') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSubStatus,
                        decoration: const InputDecoration(
                          labelText: 'Closure Type',
                          border: OutlineInputBorder(),
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
                            setModalState(() => selectedSubStatus = v),
                      ),
                    ],

                    const SizedBox(height: 24),

                    /// SUBMIT
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (selectedStatus == null) return;

                                setModalState(() => isSubmitting = true);

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
                        child: isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Submit Update'),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    if (_stationName == null) {
      debugPrint('⏳ Waiting for station name...');
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
          debugPrint('📡 Snapshot state: ${snapshot.connectionState}');
          debugPrint('📡 Snapshot hasData: ${snapshot.hasData}');
          debugPrint('📡 Snapshot error: ${snapshot.error}');
          debugPrint(
              '📡 Docs count: ${snapshot.data?.docs.length ?? 0}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No petitions for your station'),
            );
          }

          final petitions = snapshot.data!.docs
              .map((d) => Petition.fromFirestore(d))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: petitions.length,
            itemBuilder: (_, i) {
              final p = petitions[i];
              debugPrint(
                  '🧾 Rendering petition: ${p.title} | station=${p.stationName}');

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showPetitionDetails(context, p),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.title,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (p.policeStatus != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
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
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.petitionerName,
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${_formatTimestamp(p.createdAt)}',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
