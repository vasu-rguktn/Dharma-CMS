import 'package:cloud_firestore/cloud_firestore.dart';

class CaseJournalEntry {
  final String? id;
  final String caseId;
  final String officerUid;
  final String officerName;
  final String officerRank;
  final Timestamp dateTime;
  final String entryText;
  final String activityType;
  final String? relatedDocumentId;

  CaseJournalEntry({
    this.id,
    required this.caseId,
    required this.officerUid,
    required this.officerName,
    required this.officerRank,
    required this.dateTime,
    required this.entryText,
    required this.activityType,
    this.relatedDocumentId,
  });

  factory CaseJournalEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CaseJournalEntry(
      id: doc.id,
      caseId: data['caseId'] ?? '',
      officerUid: data['officerUid'] ?? '',
      officerName: data['officerName'] ?? 'Unknown Officer',
      officerRank: data['officerRank'] ?? 'N/A',
      dateTime: data['dateTime'] as Timestamp? ?? Timestamp.now(),
      entryText: data['entryText'] ?? '',
      activityType: data['activityType'] ?? '',
      relatedDocumentId: data['relatedDocumentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'officerUid': officerUid,
      'officerName': officerName,
      'officerRank': officerRank,
      'dateTime': dateTime,
      'entryText': entryText,
      'activityType': activityType,
      if (relatedDocumentId != null) 'relatedDocumentId': relatedDocumentId,
    };
  }
}
