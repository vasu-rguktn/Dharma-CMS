import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Dharma/models/petition.dart';
import 'package:Dharma/models/petition_update.dart';
import 'package:Dharma/providers/petition_provider.dart';
import 'package:Dharma/widgets/petition_update_timeline.dart';
import 'package:Dharma/l10n/app_localizations.dart';
import 'package:Dharma/widgets/full_screen_image_viewer.dart';
import 'package:Dharma/providers/auth_provider.dart';
import 'package:Dharma/providers/complaint_provider.dart';
import 'package:Dharma/screens/petition/feedback_input.dart';

class PetitionDetailBottomSheet {
  static void show(BuildContext context, Petition petition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: _DetailContent(petition: petition),
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Petition petition;

  const _DetailContent({required this.petition});

  Color _getStatusColor(PetitionStatus status, String? policeStatus) {
    if (policeStatus != null && policeStatus.isNotEmpty) {
      switch (policeStatus.toLowerCase()) {
        case 'pending':
          return Colors.orange;
        case 'received':
          return Colors.blue;
        case 'in progress':
          return Colors.indigo;
        case 'closed':
          return Colors.green;
        case 'rejected':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  int _currentStep(PetitionStatus status, String? policeStatus) {
    if (policeStatus != null && policeStatus.isNotEmpty) {
      switch (policeStatus.toLowerCase()) {
        case 'pending':
        case 'submitted':
          return 0; // Submitted
        case 'received':
        case 'acknowledged':
          return 1; // Received
        case 'in progress':
        case 'investigation':
          return 2; // In Progress
        case 'closed':
        case 'resolved':
        case 'rejected':
          return 3; // Closed
        default:
          return 0;
      }
    }

    switch (status) {
      case PetitionStatus.draft:
      case PetitionStatus.filed:
        return 0; // Submitted
      case PetitionStatus.underReview:
        return 1; // Received
      case PetitionStatus.hearingScheduled:
        return 2; // In Progress
      case PetitionStatus.granted:
      case PetitionStatus.rejected:
      case PetitionStatus.withdrawn:
        return 3; // Closed
    }
  }

  Widget _buildTrackingTimeline(
      BuildContext context, PetitionStatus status, String? policeStatus) {
    final int currentStep = _currentStep(status, policeStatus);
    final localizations = AppLocalizations.of(context)!;

    // Labels based on request
    final steps = [
      'Submitted',
      localizations.received,
      localizations.inProgress, // Use inProgress usually 'In Progress'
      localizations.closed,
    ];

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                // Line + Dot + Line
                Row(
                  children: [
                    // Left Line
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == 0
                            ? Colors.transparent
                            : (i <= currentStep
                                ? Colors.green
                                : Colors.grey.shade300),
                      ),
                    ),
                    // Dot
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= currentStep
                              ? Colors.green
                              : Colors.grey.shade300,
                          border: Border.all(
                              color: i <= currentStep
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              width: 2)),
                      child: Icon(
                        i < currentStep ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    // Right Line
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == steps.length - 1
                            ? Colors.transparent
                            : (i < currentStep
                                ? Colors.green
                                : Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  steps[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: i <= currentStep
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: i <= currentStep ? Colors.black : Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentPreview(BuildContext context, String url, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageViewer(
                  imageUrls: [url],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    final displayStatus =
        (petition.policeStatus != null && petition.policeStatus!.isNotEmpty)
            ? petition.policeStatus!
            : petition.status.displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                petition.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            // SAVE BUTTON
            Consumer<ComplaintProvider>(
              builder: (context, complaintProvider, _) {
                final isSaved = complaintProvider.isPetitionSaved(petition.id);
                return IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.orange : Colors.grey,
                  ),
                  onPressed: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final userId = auth.user?.uid;
                    if (userId == null) return;

                    await complaintProvider.toggleSaveComplaint(
                        petition.toMap(), userId);
                  },
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(petition.status, petition.policeStatus),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            displayStatus,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
        // Tracking Timeline
        _buildTrackingTimeline(context, petition.status, petition.policeStatus),
        const Divider(height: 32),

        _buildDetailRow(localizations.petitioner, petition.petitionerName),
        if (petition.phoneNumber != null)
          _buildDetailRow(
            localizations.phone,
            petition.isAnonymous ? maskPhoneNumber(petition.phoneNumber) : petition.phoneNumber!,
          ),
        if (petition.address != null)
          _buildDetailRow(localizations.address, petition.address!),
        if (petition.firNumber != null)
          _buildDetailRow(localizations.firNumber, petition.firNumber!),

        const SizedBox(height: 16),

        const SizedBox(height: 8),

// ================= INCIDENT DETAILS =================
        Text(
          'Incident Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        if (petition.incidentAddress != null &&
            petition.incidentAddress!.isNotEmpty)
          _buildDetailRow(
            'Incident Address',
            petition.incidentAddress!,
          ),

        if (petition.incidentDate != null)
          _buildDetailRow(
            'Incident Date',
            petition.incidentDate!.toDate().toLocal().toString().split(' ')[0],
          ),

        const SizedBox(height: 16),

// ================= JURISDICTION DETAILS =================
        Text(
          'Jurisdiction for Filing Complaint',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        if (petition.district != null && petition.district!.isNotEmpty)
          _buildDetailRow(
            'District',
            petition.district!,
          ),

        if (petition.stationName != null && petition.stationName!.isNotEmpty)
          _buildDetailRow(
            'Police Station',
            petition.stationName!,
          ),

        Text(localizations.grounds,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(petition.grounds),

        if (petition.prayerRelief != null) ...[
          const SizedBox(height: 16),
          Text(localizations.prayerReliefSought,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(petition.prayerRelief!),
        ],

        if (petition.filingDate != null)
          _buildDetailRow(localizations.filingDate, petition.filingDate!),
        if (petition.nextHearingDate != null)
          _buildDetailRow(localizations.nextHearing, petition.nextHearingDate!),
        if (petition.orderDate != null)
          _buildDetailRow(localizations.orderDate, petition.orderDate!),

        if (petition.orderDetails != null) ...[
          const SizedBox(height: 16),
          Text(localizations.orderDetails,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(petition.orderDetails!),
        ],

        if (petition.extractedText != null &&
            petition.extractedText!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(localizations.extractedTextFromDocuments,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(petition.extractedText!,
                style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Text(localizations.extractedTextFromDocuments,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(localizations.noDocumentsUploaded,
              style: TextStyle(
                  color: Colors.grey[600], fontStyle: FontStyle.italic)),
        ],

        // ================= UPLOADED DOCUMENTS =================
        if (petition.handwrittenDocumentUrl != null ||
            (petition.proofDocumentUrls != null &&
                petition.proofDocumentUrls!.isNotEmpty)) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Uploaded Documents',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (petition.handwrittenDocumentUrl != null) ...[
          _buildDocumentPreview(context, petition.handwrittenDocumentUrl!,
              'Handwritten Petition'),
          const SizedBox(height: 16),
        ],

        if (petition.proofDocumentUrls != null &&
            petition.proofDocumentUrls!.isNotEmpty) ...[
          Text(
            'Proof Documents (${petition.proofDocumentUrls!.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: petition.proofDocumentUrls!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 200,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImageViewer(
                              imageUrls: petition.proofDocumentUrls!,
                              initialIndex: index,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          petition.proofDocumentUrls![index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.grey)),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        // ============= PETITION UPDATES TIMELINE (FOR CITIZENS) =============
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        
        Text(
          'Case Progress Updates',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track the progress of your petition here. Police will add updates about the work done on your case.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),

        // Display petition updates in real-time using StreamBuilder
        if (petition.id != null)
          StreamBuilder<List<PetitionUpdate>>(
            stream: context.read<PetitionProvider>().streamPetitionUpdates(petition.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
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
              final allUpdates = context.read<PetitionProvider>().getUpdatesWithEscalations(petition, updates);
              return PetitionUpdateTimeline(updates: allUpdates);
            },
          ),
          
          // ================= FEEDBACK SECTION =================
          if (_shouldShowFeedbackSection(petition)) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
             FeedbackInput(
              petitionId: petition.id!,
              onSuccess: () {
                // Refresh or close? 
                // Since this is inside a BottomSheet/Modal, maybe just show success message (handled in widget)
                // and maybe refresh current view?
                // The widget handles validation and UI state.
                Navigator.pop(context);
              },
            ),
          ],
      ],
    );
  }

  bool _shouldShowFeedbackSection(Petition petition) {
    final status = (petition.policeStatus ?? '').toLowerCase();
    
    // 1. Must be resolved/closed
    final isResolved = status.contains('closed') || 
                       status.contains('resolved') || 
                       status.contains('reject') ||
                       petition.status == PetitionStatus.granted ||
                       petition.status == PetitionStatus.rejected ||
                       petition.status == PetitionStatus.withdrawn;

    if (!isResolved) return false;

    // 2. Limit to 5 feedbacks (or 1 if strict "rating" logic but users said "upto 5")
    final feedbackCount = petition.feedbacks?.length ?? 0;
    if (feedbackCount >= 5) return false;

    return true;
  }
}
