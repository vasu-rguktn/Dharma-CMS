import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/providers/police_auth_provider.dart';
import 'package:Dharma/screens/petition/petition_card.dart';

class AssignedPetitionsTab extends StatefulWidget {
  const AssignedPetitionsTab({super.key});

  @override
  State<AssignedPetitionsTab> createState() => _AssignedPetitionsTabState();
}

class _AssignedPetitionsTabState extends State<AssignedPetitionsTab> {
  String? _statusFilter; // 'pending', 'accepted', 'rejected'

  @override
  Widget build(BuildContext context) {
    final policeProfile = context.watch<PoliceAuthProvider>().policeProfile;
    final officerUid = policeProfile?['uid'] as String?;

    if (officerUid == null) {
      return const Center(
        child: Text('Officer profile not loaded'),
      );
    }

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (selected) {
                    setState(() {
                      _statusFilter = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending'),
                  selected: _statusFilter == 'pending',
                  onSelected: (selected) {
                    setState(() {
                      _statusFilter = selected ? 'pending' : null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Accepted'),
                  selected: _statusFilter == 'accepted',
                  onSelected: (selected) {
                    setState(() {
                      _statusFilter = selected ? 'accepted' : null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Rejected'),
                  selected: _statusFilter == 'rejected',
                  onSelected: (selected) {
                    setState(() {
                      _statusFilter = selected ? 'rejected' : null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        // Petition list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _statusFilter == null
                ? FirebaseFirestore.instance
                    .collection('petitions')
                    .where('assignedTo', isEqualTo: officerUid)
                    .orderBy('assignedAt', descending: true)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('petitions')
                    .where('assignedTo', isEqualTo: officerUid)
                    .where('assignmentStatus', isEqualTo: _statusFilter)
                    .orderBy('assignedAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No assigned petitions',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final petitions = snapshot.data!.docs
                  .map((doc) => Petition.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: petitions.length,
                itemBuilder: (context, index) {
                  final petition = petitions[index];
                  return _buildAssignedPetitionCard(petition);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedPetitionCard(Petition petition) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Petition details
          ListTile(
            title: Text(
              petition.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Type: ${petition.type.displayName}'),
                Text('Petitioner: ${petition.petitionerName}'),
                if (petition.assignedByName != null)
                  Text('Assigned by: ${petition.assignedByName}'),
                if (petition.assignedAt != null)
                  Text(
                    'Assigned on: ${_formatDate(petition.assignedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
            trailing: _buildStatusChip(petition.assignmentStatus ?? 'pending'),
          ),

          // Assignment actions (for pending assignments)
          if (petition.assignmentStatus == null ||
              petition.assignmentStatus == 'pending') ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _updateAssignmentStatus(
                      petition.id!,
                      'rejected',
                    ),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _updateAssignmentStatus(
                      petition.id!,
                      'accepted',
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        icon = Icons.pending;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Future<void> _updateAssignmentStatus(
    String petitionId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('petitions')
          .doc(petitionId)
          .update({
        'assignmentStatus': newStatus,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assignment $newStatus'),
            backgroundColor:
                newStatus == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
