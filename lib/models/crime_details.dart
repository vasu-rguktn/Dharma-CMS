import 'package:cloud_firestore/cloud_firestore.dart';

class Witness {
  final String? id;
  final String? name;
  final String? address;
  final String? contactNumber;

  Witness({
    this.id,
    this.name,
    this.address,
    this.contactNumber,
  });

  factory Witness.fromMap(Map<String, dynamic> map) {
    return Witness(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      contactNumber: map['contactNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (contactNumber != null) 'contactNumber': contactNumber,
    };
  }
}

class CrimeDetails {
  final String? id;
  final String firNumber;
  final String? crimeType;
  final String? majorHead;
  final String? minorHead;
  final String? languageDialectUsed;
  final String? specialFeatures;
  final String? conveyanceUsed;
  final String? characterAssumedByOffender;
  final String? methodUsed;
  final String? placeOfOccurrenceDescription;
  final String? dateTimeOfSceneVisit;
  final String? physicalEvidenceDescription;
  final List<Witness>? witnesses;
  final String? motiveOfCrime;
  final String? sketchOrMapUrl;
  final String userId;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  CrimeDetails({
    this.id,
    required this.firNumber,
    this.crimeType,
    this.majorHead,
    this.minorHead,
    this.languageDialectUsed,
    this.specialFeatures,
    this.conveyanceUsed,
    this.characterAssumedByOffender,
    this.methodUsed,
    this.placeOfOccurrenceDescription,
    this.dateTimeOfSceneVisit,
    this.physicalEvidenceDescription,
    this.witnesses,
    this.motiveOfCrime,
    this.sketchOrMapUrl,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CrimeDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    List<Witness>? witnessess;
    if (data['witnesses'] != null) {
      witnessess = (data['witnesses'] as List)
          .map((w) => Witness.fromMap(w as Map<String, dynamic>))
          .toList();
    }

    return CrimeDetails(
      id: doc.id,
      firNumber: data['firNumber'] ?? '',
      crimeType: data['crimeType'],
      majorHead: data['majorHead'],
      minorHead: data['minorHead'],
      languageDialectUsed: data['languageDialectUsed'],
      specialFeatures: data['specialFeatures'],
      conveyanceUsed: data['conveyanceUsed'],
      characterAssumedByOffender: data['characterAssumedByOffender'],
      methodUsed: data['methodUsed'],
      placeOfOccurrenceDescription: data['placeOfOccurrenceDescription'],
      dateTimeOfSceneVisit: data['dateTimeOfSceneVisit'],
      physicalEvidenceDescription: data['physicalEvidenceDescription'],
      witnesses: witnessess,
      motiveOfCrime: data['motiveOfCrime'],
      sketchOrMapUrl: data['sketchOrMapUrl'],
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firNumber': firNumber,
      if (crimeType != null) 'crimeType': crimeType,
      if (majorHead != null) 'majorHead': majorHead,
      if (minorHead != null) 'minorHead': minorHead,
      if (languageDialectUsed != null) 'languageDialectUsed': languageDialectUsed,
      if (specialFeatures != null) 'specialFeatures': specialFeatures,
      if (conveyanceUsed != null) 'conveyanceUsed': conveyanceUsed,
      if (characterAssumedByOffender != null) 'characterAssumedByOffender': characterAssumedByOffender,
      if (methodUsed != null) 'methodUsed': methodUsed,
      if (placeOfOccurrenceDescription != null) 'placeOfOccurrenceDescription': placeOfOccurrenceDescription,
      if (dateTimeOfSceneVisit != null) 'dateTimeOfSceneVisit': dateTimeOfSceneVisit,
      if (physicalEvidenceDescription != null) 'physicalEvidenceDescription': physicalEvidenceDescription,
      if (witnesses != null) 'witnesses': witnesses!.map((w) => w.toMap()).toList(),
      if (motiveOfCrime != null) 'motiveOfCrime': motiveOfCrime,
      if (sketchOrMapUrl != null) 'sketchOrMapUrl': sketchOrMapUrl,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
