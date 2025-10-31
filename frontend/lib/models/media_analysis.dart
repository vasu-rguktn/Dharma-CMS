import 'package:cloud_firestore/cloud_firestore.dart';

class IdentifiedElement {
  final String name;
  final String category;
  final String description;
  final int? count;

  IdentifiedElement({
    required this.name,
    required this.category,
    required this.description,
    this.count,
  });

  factory IdentifiedElement.fromMap(Map<String, dynamic> map) {
    return IdentifiedElement(
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      count: map['count'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      if (count != null) 'count': count,
    };
  }
}

class MediaAnalysisRecord {
  final String? id;
  final String userId;
  final String originalFileName;
  final String? originalFileContentType;
  final String? storagePath;
  final String imageDataUri;
  final String? userContext;
  final List<IdentifiedElement> identifiedElements;
  final String sceneNarrative;
  final String caseFileSummary;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? caseId;

  MediaAnalysisRecord({
    this.id,
    required this.userId,
    required this.originalFileName,
    this.originalFileContentType,
    this.storagePath,
    required this.imageDataUri,
    this.userContext,
    required this.identifiedElements,
    required this.sceneNarrative,
    required this.caseFileSummary,
    required this.createdAt,
    required this.updatedAt,
    this.caseId,
  });

  factory MediaAnalysisRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    List<IdentifiedElement> elements = [];
    if (data['identifiedElements'] != null) {
      elements = (data['identifiedElements'] as List)
          .map((e) => IdentifiedElement.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return MediaAnalysisRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      originalFileName: data['originalFileName'] ?? '',
      originalFileContentType: data['originalFileContentType'],
      storagePath: data['storagePath'],
      imageDataUri: data['imageDataUri'] ?? '',
      userContext: data['userContext'],
      identifiedElements: elements,
      sceneNarrative: data['sceneNarrative'] ?? '',
      caseFileSummary: data['caseFileSummary'] ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      caseId: data['caseId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'originalFileName': originalFileName,
      if (originalFileContentType != null) 'originalFileContentType': originalFileContentType,
      if (storagePath != null) 'storagePath': storagePath,
      'imageDataUri': imageDataUri,
      if (userContext != null) 'userContext': userContext,
      'identifiedElements': identifiedElements.map((e) => e.toMap()).toList(),
      'sceneNarrative': sceneNarrative,
      'caseFileSummary': caseFileSummary,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (caseId != null) 'caseId': caseId,
    };
  }
}
