import 'package:flutter/material.dart';
import 'package:Dharma/models/petition_update.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// A beautiful timeline widget to display petition updates
class PetitionUpdateTimeline extends StatelessWidget {
  final List<PetitionUpdate> updates;

  const PetitionUpdateTimeline({
    Key? key,
    required this.updates,
  }) : super(key: key);

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timeline,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No Updates Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The police will add updates about your case here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final update = updates[index];
        final isLast = index == updates.length - 1;

        return _TimelineItem(
          update: update,
          isLast: isLast,
          onPhotoTap: (url) => _launchUrl(url),
          onDocumentTap: (url) => _launchUrl(url),
          formatTimestamp: _formatTimestamp,
        );
      },
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final PetitionUpdate update;
  final bool isLast;
  final Function(String) onPhotoTap;
  final Function(String) onDocumentTap;
  final String Function(DateTime) formatTimestamp;

  const _TimelineItem({
    required this.update,
    required this.isLast,
    required this.onPhotoTap,
    required this.onDocumentTap,
    required this.formatTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = update.createdAt.toDate();

    Color statusColor = Colors.indigo;
    Color statusLightColor = Colors.indigo.shade200;
    Color statusVeryLightColor = Colors.indigo.shade100;

    if (update.aiStatus != null) {
      final status = update.aiStatus!.toLowerCase();
      if (status == 'green') {
        statusColor = Colors.green;
        statusLightColor = Colors.green.shade200;
        statusVeryLightColor = Colors.green.shade100;
      } else if (status == 'amber' || status == 'orange') {
        statusColor = Colors.orange;
        statusLightColor = Colors.orange.shade200;
        statusVeryLightColor = Colors.orange.shade100;
      } else if (status == 'red') {
        statusColor = Colors.red;
        statusLightColor = Colors.red.shade200;
        statusVeryLightColor = Colors.red.shade100;
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line and Dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    border: Border.all(
                      color: statusLightColor,
                      width: 3,
                    ),
                  ),
                ),
                // Vertical Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            statusLightColor,
                            statusVeryLightColor,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Update Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timestamp and Officer Name
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatTimestamp(dateTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: Colors.indigo.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  update.addedBy,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.indigo.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Update Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: update.aiStatus != null ? statusVeryLightColor.withOpacity(0.3) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusLightColor,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      update.updateText,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Photos
                  if (update.photoUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: update.photoUrls.map((photoUrl) {
                        return GestureDetector(
                          onTap: () => onPhotoTap(photoUrl),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(photoUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                              child: const Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Documents
                  if (update.documents.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...update.documents.map((doc) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            doc['name'] ?? 'Document',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.download,
                              color: Colors.blue.shade700,
                            ),
                            onPressed: () => onDocumentTap(doc['url'] ?? ''),
                          ),
                          onTap: () => onDocumentTap(doc['url'] ?? ''),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
