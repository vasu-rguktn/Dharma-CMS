import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetitionFeedbackTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> feedbacks;

  const PetitionFeedbackTimeline({Key? key, required this.feedbacks}) : super(key: key);

  String _formatTimestamp(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} • ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: feedbacks.length,
      itemBuilder: (context, index) {
        final feedback = feedbacks[index];
        final isLast = index == feedbacks.length - 1;
        
        final rating = (feedback['rating'] is int) 
            ? (feedback['rating'] as int).toDouble() 
            : (feedback['rating'] as double? ?? 0.0);
        final comment = feedback['comment'] as String? ?? '';
        final date = (feedback['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

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
                        color: Colors.amber,
                        border: Border.all(
                          color: Colors.amber.shade200,
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
                                Colors.amber.shade200,
                                Colors.amber.shade100,
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Feedback Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timestamp
                      Text(
                        _formatTimestamp(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating Stars
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      
                      const SizedBox(height: 8),

                      // Comment Text
                      if (comment.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            comment,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.brown.shade800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
