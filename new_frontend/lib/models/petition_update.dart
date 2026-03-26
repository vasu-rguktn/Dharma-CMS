/// Represents a single update/progress on a petition.
class PetitionUpdate {
  final String? id;
  final String petitionId;
  final String updateText;
  final List<String> photoUrls;
  final List<Map<String, String>> documents;
  final String addedBy;
  final String addedByUserId;
  final DateTime createdAt;

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

  factory PetitionUpdate.fromJson(Map<String, dynamic> data, [String? docId]) {
    return PetitionUpdate(
      id: docId ?? data['id'],
      petitionId: data['petitionId'] ?? '',
      updateText: data['updateText'] ?? '',
      photoUrls: (data['photoUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      documents: (data['documents'] as List<dynamic>?)?.map((e) => Map<String, String>.from(e as Map)).toList() ?? [],
      addedBy: data['addedBy'] ?? '',
      addedByUserId: data['addedByUserId'] ?? '',
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'petitionId': petitionId,
        'updateText': updateText,
        'photoUrls': photoUrls,
        'documents': documents,
        'addedBy': addedBy,
        'addedByUserId': addedByUserId,
        'createdAt': createdAt.toIso8601String(),
      };
}
