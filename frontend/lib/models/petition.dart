import 'package:cloud_firestore/cloud_firestore.dart';

enum PetitionType {
  bail,
  anticipatoryBail,
  revision,
  appeal,
  writ,
  quashing,
  other,
}

extension PetitionTypeExtension on PetitionType {
  String get displayName {
    switch (this) {
      case PetitionType.bail:
        return 'Bail Application';
      case PetitionType.anticipatoryBail:
        return 'Anticipatory Bail';
      case PetitionType.revision:
        return 'Revision Petition';
      case PetitionType.appeal:
        return 'Appeal';
      case PetitionType.writ:
        return 'Writ Petition';
      case PetitionType.quashing:
        return 'Quashing Petition';
      case PetitionType.other:
        return 'Other';
    }
  }

  static PetitionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bail application':
      case 'bail':
        return PetitionType.bail;
      case 'anticipatory bail':
        return PetitionType.anticipatoryBail;
      case 'revision petition':
      case 'revision':
        return PetitionType.revision;
      case 'appeal':
        return PetitionType.appeal;
      case 'writ petition':
      case 'writ':
        return PetitionType.writ;
      case 'quashing petition':
      case 'quashing':
        return PetitionType.quashing;
      default:
        return PetitionType.other;
    }
  }
}

enum PetitionStatus {
  draft,
  filed,
  underReview,
  hearingScheduled,
  granted,
  rejected,
  withdrawn,
}

extension PetitionStatusExtension on PetitionStatus {
  String get displayName {
    switch (this) {
      case PetitionStatus.draft:
        return 'Draft';
      case PetitionStatus.filed:
        return 'Filed';
      case PetitionStatus.underReview:
        return 'Under Review';
      case PetitionStatus.hearingScheduled:
        return 'Hearing Scheduled';
      case PetitionStatus.granted:
        return 'Granted';
      case PetitionStatus.rejected:
        return 'Rejected';
      case PetitionStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  static PetitionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return PetitionStatus.draft;
      case 'filed':
        return PetitionStatus.filed;
      case 'under review':
        return PetitionStatus.underReview;
      case 'hearing scheduled':
        return PetitionStatus.hearingScheduled;
      case 'granted':
        return PetitionStatus.granted;
      case 'rejected':
        return PetitionStatus.rejected;
      case 'withdrawn':
        return PetitionStatus.withdrawn;
      default:
        return PetitionStatus.draft;
    }
  }
}

class Petition {
  final String? id;
  final String title;
  final PetitionType type;
  final PetitionStatus status;
  final String? caseId; // Link to case if applicable
  final String? firNumber;
  final String petitionerName;
  final String? respondentName;
  final String courtName;
  final String? caseNumber;
  final String grounds; // Grounds/reasons for petition
  final String? prayerRelief; // Relief sought
  final String? supportingDocuments; // URLs or references
  final String? nextHearingDate;
  final String? filingDate;
  final String? orderDate;
  final String? orderDetails;
  final String? extractedText; // Text extracted from uploaded documents
  final String userId;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Petition({
    this.id,
    required this.title,
    required this.type,
    required this.status,
    this.caseId,
    this.firNumber,
    required this.petitionerName,
    this.respondentName,
    required this.courtName,
    this.caseNumber,
    required this.grounds,
    this.prayerRelief,
    this.supportingDocuments,
    this.nextHearingDate,
    this.filingDate,
    this.orderDate,
    this.orderDetails,
    this.extractedText,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Petition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Petition(
      id: doc.id,
      title: data['title'] ?? '',
      type: PetitionTypeExtension.fromString(data['type'] ?? 'other'),
      status: PetitionStatusExtension.fromString(data['status'] ?? 'draft'),
      caseId: data['caseId'],
      firNumber: data['firNumber'],
      petitionerName: data['petitionerName'] ?? '',
      respondentName: data['respondentName'],
      courtName: data['courtName'] ?? '',
      caseNumber: data['caseNumber'],
      grounds: data['grounds'] ?? '',
      prayerRelief: data['prayerRelief'],
      supportingDocuments: data['supportingDocuments'],
      nextHearingDate: data['nextHearingDate'],
      filingDate: data['filingDate'],
      orderDate: data['orderDate'],
      orderDetails: data['orderDetails'],
      extractedText: data['extractedText'],
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type.displayName,
      'status': status.displayName,
      if (caseId != null) 'caseId': caseId,
      if (firNumber != null) 'firNumber': firNumber,
      'petitionerName': petitionerName,
      if (respondentName != null) 'respondentName': respondentName,
      'courtName': courtName,
      if (caseNumber != null) 'caseNumber': caseNumber,
      'grounds': grounds,
      if (prayerRelief != null) 'prayerRelief': prayerRelief,
      if (supportingDocuments != null) 'supportingDocuments': supportingDocuments,
      if (nextHearingDate != null) 'nextHearingDate': nextHearingDate,
      if (filingDate != null) 'filingDate': filingDate,
      if (orderDate != null) 'orderDate': orderDate,
      if (orderDetails != null) 'orderDetails': orderDetails,
      if (extractedText != null) 'extractedText': extractedText,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
