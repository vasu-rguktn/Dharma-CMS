import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single update/progress made by police on a petition
class PetitionUpdate {
  final String? id;
  final String petitionId;
  final String updateText;
  final List<String> photoUrls;
  final List<Map<String, String>> documents; // {name, url}
  final String addedBy; // Police officer name
  final String addedByUserId; // Police officer user ID
  final Timestamp createdAt;

  PetitionUpdate({
    this.id,
    required this.petitionId,
    required this.updateText,
    this.photoUrls = const [],
    this.documents = const [],
    required this.addedBy,
    required this.addedByUserId,
    required this.createdAt,
  });

  factory PetitionUpdate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PetitionUpdate(
      id: doc.id,
      petitionId: data['petitionId'] ?? '',
      updateText: data['updateText'] ?? '',
      photoUrls: (data['photoUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      documents: (data['documents'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList() ?? [],
      addedBy: data['addedBy'] ?? '',
      addedByUserId: data['addedByUserId'] ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'petitionId': petitionId,
      'updateText': updateText,
      'photoUrls': photoUrls,
      'documents': documents,
      'addedBy': addedBy,
      'addedByUserId': addedByUserId,
      'createdAt': createdAt,
    };
  }
}
