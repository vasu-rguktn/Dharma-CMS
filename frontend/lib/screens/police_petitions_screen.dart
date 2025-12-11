import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/models/Petition.dart';   // ✅ Correct model import
import 'package:Dharma/providers/petition_provider.dart';

class PolicePetitionsScreen extends StatelessWidget {
  const PolicePetitionsScreen({super.key});

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

  Color _getStringStatusColor(String status) {
    switch (status) {
      case 'Received': return Colors.blue;
      case 'In Progress': return Colors.indigo;
      case 'Closed': return Colors.green;
      case 'Rejected': return Colors.red;
      case 'Pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPetitionDetails(BuildContext context, Petition petition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          // Local state for the modal
          String? selectedStatus = petition.policeStatus;
          String? selectedSubStatus = petition.policeSubStatus;
          bool isSubmitting = false;

          return StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Title Row
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

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
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const Divider(height: 32),

                    _buildDetailRow('Petitioner', petition.petitionerName),
                    if (petition.phoneNumber != null)
                      _buildDetailRow('Phone', petition.phoneNumber!),
                    if (petition.address != null)
                      _buildDetailRow('Address', petition.address!),
                    if (petition.firNumber != null)
                      _buildDetailRow('FIR Number', petition.firNumber!),

                    const SizedBox(height: 16),
                    Text('Grounds',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(petition.grounds),

                    const SizedBox(height: 20),

                    /// 🔥 POLICE STATUS UPDATE UI STARTS HERE
                    Text(
                      "Police Status Update",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      // Ensure value matches one of the items or is null
                      value: ["Received", "In Progress", "Closed"].contains(selectedStatus)
                          ? selectedStatus
                          : null,
                      decoration: const InputDecoration(
                        labelText: "Select Status",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: "Received", child: Text("Received")),
                        DropdownMenuItem(
                            value: "In Progress", child: Text("In Progress")),
                        DropdownMenuItem(
                            value: "Closed", child: Text("Closed")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                          // Reset subStatus if not closed
                          if (value != "Closed") {
                            selectedSubStatus = null;
                          }
                        });
                      },
                    ),

                    if (selectedStatus == "Closed") ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedSubStatus,
                        decoration: const InputDecoration(
                          labelText: "Select Closure",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: "Rejected", child: Text("Rejected")),
                          DropdownMenuItem(
                              value: "FIR Registered",
                              child: Text("FIR Registered")),
                          DropdownMenuItem(
                            value: "Compromised / Disposed",
                            child: Text("Compromised / Disposed"),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedSubStatus = value;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (selectedStatus == null) return;

                                setState(() => isSubmitting = true);

                                try {
                                  Map<String, dynamic> updates = {
                                    'policeStatus': selectedStatus,
                                    'policeSubStatus': selectedSubStatus,
                                  };

                                  await context
                                      .read<PetitionProvider>()
                                      .updatePetition(
                                        petition.id!,
                                        updates,
                                        petition.userId,
                                      );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Petition status updated successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error updating status: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isSubmitting = false);
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Submit Update',
                                style:
                                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    /// 🔥 END OF POLICE STATUS UI
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Petitions')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('petitions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final petitions =
              snapshot.data!.docs.map((d) => Petition.fromFirestore(d)).toList();

          if (petitions.isEmpty) {
            return const Center(child: Text('No petitions found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: petitions.length,
            itemBuilder: (context, index) {
              final p = petitions[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _showPetitionDetails(context, p),
                  borderRadius: BorderRadius.circular(12),
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
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (p.policeStatus != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStringStatusColor(p.policeStatus!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  p.policeStatus!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.petitionerName,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${_formatTimestamp(p.createdAt)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
