import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Dharma/models/case_status.dart';

class CaseDoc {
  final String? id;
  final String? originalComplaintId;
  final CaseStatus status;
  final Timestamp dateFiled;
  final Timestamp lastUpdated;
  final String title;
  final String? userId;
  
  // District Details
  final String? district;
  final String? policeStation;
  final String? year;
  final String firNumber;
  final String? date;
  
  // Complainant
  final String? complainantName;
  final String? complainantFatherHusbandName;
  final String? complainantGender;
  final String? complainantMobileNumber;
  
  // Victim
  final String? victimName;
  final String? victimAge;
  final String? victimGender;
  
  // Occurrence details
  final String? occurrenceDay;
  final String? occurrenceDateTimeFrom;
  final String? occurrenceDateTimeTo;
  
  // Acts and sections
  final String? actsAndSectionsInvolved;
  final String? incidentDetails;
  final String? complaintStatement;
  
  CaseDoc({
    this.id,
    this.originalComplaintId,
    required this.status,
    required this.dateFiled,
    required this.lastUpdated,
    required this.title,
    this.userId,
    this.district,
    this.policeStation,
    this.year,
    required this.firNumber,
    this.date,
    this.complainantName,
    this.complainantFatherHusbandName,
    this.complainantGender,
    this.complainantMobileNumber,
    this.victimName,
    this.victimAge,
    this.victimGender,
    this.occurrenceDay,
    this.occurrenceDateTimeFrom,
    this.occurrenceDateTimeTo,
    this.actsAndSectionsInvolved,
    this.incidentDetails,
    this.complaintStatement,
  });

  factory CaseDoc.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CaseDoc(
      id: doc.id,
      originalComplaintId: data['originalComplaintId'],
      status: CaseStatusExtension.fromString(data['status'] ?? 'New'),
      dateFiled: data['dateFiled'] as Timestamp,
      lastUpdated: data['lastUpdated'] as Timestamp,
      title: data['title'] ?? '',
      userId: data['userId'],
      district: data['district'],
      policeStation: data['policeStation'],
      year: data['year'],
      firNumber: data['firNumber'] ?? '',
      date: data['date'],
      complainantName: data['complainantName'],
      complainantFatherHusbandName: data['complainantFatherHusbandName'],
      complainantGender: data['complainantGender'],
      complainantMobileNumber: data['complainantMobileNumber'],
      victimName: data['victimName'],
      victimAge: data['victimAge'],
      victimGender: data['victimGender'],
      occurrenceDay: data['occurrenceDay'],
      occurrenceDateTimeFrom: data['occurrenceDateTimeFrom'],
      occurrenceDateTimeTo: data['occurrenceDateTimeTo'],
      actsAndSectionsInvolved: data['actsAndSectionsInvolved'],
      incidentDetails: data['incidentDetails'],
      complaintStatement: data['complaintStatement'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'originalComplaintId': originalComplaintId,
      'status': status.displayName,
      'dateFiled': dateFiled,
      'lastUpdated': lastUpdated,
      'title': title,
      'userId': userId,
      'district': district,
      'policeStation': policeStation,
      'year': year,
      'firNumber': firNumber,
      'date': date,
      'complainantName': complainantName,
      'complainantFatherHusbandName': complainantFatherHusbandName,
      'complainantGender': complainantGender,
      'complainantMobileNumber': complainantMobileNumber,
      'victimName': victimName,
      'victimAge': victimAge,
      'victimGender': victimGender,
      'occurrenceDay': occurrenceDay,
      'occurrenceDateTimeFrom': occurrenceDateTimeFrom,
      'occurrenceDateTimeTo': occurrenceDateTimeTo,
      'actsAndSectionsInvolved': actsAndSectionsInvolved,
      'incidentDetails': incidentDetails,
      'complaintStatement': complaintStatement,
    };
  }
}
