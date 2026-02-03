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
  final String? caseId; // Case ID
  
  // District Details
  final String? district;
  final String? policeStation;
  final String? year;
  final String firNumber;
  final String? date;
  final Timestamp? firFiledTimestamp; // Exact date and time when FIR was filed
  
  // Complainant
  final String? complainantName;
  final String? complainantFatherHusbandName;
  final String? complainantGender;
  final String? complainantMobileNumber;
  final String? complainantNationality;
  final String? complainantCaste;
  final String? complainantOccupation;
  final String? complainantDob; // ISO date string
  final String? complainantAge;
  final String? complainantAddress;
  final String? complainantPassportNumber;
  final String? complainantPassportPlaceOfIssue;
  final String? complainantPassportDateOfIssue; // ISO date string
  
  // Victim
  final String? victimName;
  final String? victimAge;
  final String? victimGender;
  final String? victimFatherHusbandName;
  final String? victimNationality;
  final String? victimReligion;
  final String? victimCaste;
  final String? victimOccupation;
  final String? victimDob;
  final String? victimAddress;
  final bool? isComplainantAlsoVictim;
  
  // Occurrence details
  final String? occurrenceDay;
  final String? occurrenceDateTimeFrom;
  final String? occurrenceDateTimeTo;
  final String? timePeriod; // E.g., "19:15-21:30"
  final String? priorToDateTimeDetails; // Prior to Date/Time (Details)
  final String? beatNumber;
  final String? placeOfOccurrenceStreet; // Street/Village
  final String? placeOfOccurrenceArea; // Area/Mandal
  final String? placeOfOccurrenceCity; // City/District
  final String? placeOfOccurrenceState; // State
  final String? placeOfOccurrencePin; // PIN
  final String? placeOfOccurrenceLatitude; // Latitude
  final String? placeOfOccurrenceLongitude; // Longitude
  final String? distanceFromPS; // Distance from Police Station
  final String? directionFromPS; // Direction from Police Station
  final bool? isOutsideJurisdiction; // Is Outside Jurisdiction
  
  // Information received at PS
  final String? informationReceivedDateTime; // e.g. "2025-01-01 10:30"
  final String? generalDiaryEntryNumber;
  final String? informationType; // e.g. Oral/Written/Phone
  
  // Acts and sections
  final String? actsAndSectionsInvolved;
  final String? incidentDetails;
  final String? complaintStatement;
  
  // Properties involved, delay, inquest
  final String? propertiesDetails; // Details of properties stolen/involved
  final String? propertiesTotalValueInr;
  final bool? isDelayInReporting;
  final String? inquestReportCaseNo;
  
  // Action taken / dispatch to court
  final String? actionTakenDetails;
  final String? investigatingOfficerName;
  final String? investigatingOfficerRank;
  final String? investigatingOfficerDistrict;
  final String? dispatchDateTime;
  final String? dispatchOfficerName;
  final String? dispatchOfficerRank;
  
  // Confirmation
  final bool? isFirReadOverAndAdmittedCorrect;
  final bool? isFirCopyGivenFreeOfCost;
  final bool? isRoacRecorded;
  final String? complainantSignatureNote;
  
  // Accused details (optional, as a list of maps)
  final List<dynamic>? accusedPersons;

  // AI-generated investigation report (court document)
  final String? investigationReportPdfUrl;
  final Timestamp? investigationReportGeneratedAt;
  
  CaseDoc({
    this.id,
    this.originalComplaintId,
    required this.status,
    required this.dateFiled,
    required this.lastUpdated,
    required this.title,
    this.userId,
    this.caseId,
    this.district,
    this.policeStation,
    this.year,
    required this.firNumber,
    this.date,
    this.firFiledTimestamp,
    this.complainantName,
    this.complainantFatherHusbandName,
    this.complainantGender,
    this.complainantMobileNumber,
    this.complainantNationality,
    this.complainantCaste,
    this.complainantOccupation,
    this.complainantDob,
    this.complainantAge,
    this.complainantAddress,
    this.complainantPassportNumber,
    this.complainantPassportPlaceOfIssue,
    this.complainantPassportDateOfIssue,
    this.victimName,
    this.victimAge,
    this.victimGender,
    this.victimFatherHusbandName,
    this.victimNationality,
    this.victimReligion,
    this.victimCaste,
    this.victimOccupation,
    this.victimDob,
    this.victimAddress,
    this.isComplainantAlsoVictim,
    this.occurrenceDay,
    this.occurrenceDateTimeFrom,
    this.occurrenceDateTimeTo,
    this.timePeriod,
    this.priorToDateTimeDetails,
    this.beatNumber,
    this.placeOfOccurrenceStreet,
    this.placeOfOccurrenceArea,
    this.placeOfOccurrenceCity,
    this.placeOfOccurrenceState,
    this.placeOfOccurrencePin,
    this.placeOfOccurrenceLatitude,
    this.placeOfOccurrenceLongitude,
    this.distanceFromPS,
    this.directionFromPS,
    this.informationReceivedDateTime,
    this.generalDiaryEntryNumber,
    this.informationType,
    this.isOutsideJurisdiction,
    this.actsAndSectionsInvolved,
    this.incidentDetails,
    this.complaintStatement,
    this.propertiesDetails,
    this.propertiesTotalValueInr,
    this.isDelayInReporting,
    this.inquestReportCaseNo,
    this.actionTakenDetails,
    this.investigatingOfficerName,
    this.investigatingOfficerRank,
    this.investigatingOfficerDistrict,
    this.dispatchDateTime,
    this.dispatchOfficerName,
    this.dispatchOfficerRank,
    this.isFirReadOverAndAdmittedCorrect,
    this.isFirCopyGivenFreeOfCost,
    this.isRoacRecorded,
    this.complainantSignatureNote,
    this.accusedPersons,
    this.investigationReportPdfUrl,
    this.investigationReportGeneratedAt,
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
      caseId: data['caseId'],
      district: data['district'],
      policeStation: data['policeStation'],
      year: data['year'],
      firNumber: data['firNumber'] ?? '',
      date: data['date'],
      firFiledTimestamp: data['firFiledTimestamp'] as Timestamp?,
      complainantName: data['complainantName'],
      complainantFatherHusbandName: data['complainantFatherHusbandName'],
      complainantGender: data['complainantGender'],
      complainantMobileNumber: data['complainantMobileNumber'],
      complainantNationality: data['complainantNationality'],
      complainantCaste: data['complainantCaste'],
      complainantOccupation: data['complainantOccupation'],
      complainantDob: data['complainantDob'],
      complainantAge: data['complainantAge'],
      complainantAddress: data['complainantAddress'],
      complainantPassportNumber: data['complainantPassportNumber'],
      complainantPassportPlaceOfIssue: data['complainantPassportPlaceOfIssue'],
      complainantPassportDateOfIssue: data['complainantPassportDateOfIssue'],
      victimName: data['victimName'],
      victimAge: data['victimAge'],
      victimGender: data['victimGender'],
      victimFatherHusbandName: data['victimFatherHusbandName'],
      victimNationality: data['victimNationality'],
      victimReligion: data['victimReligion'],
      victimCaste: data['victimCaste'],
      victimOccupation: data['victimOccupation'],
      victimDob: data['victimDob'],
      victimAddress: data['victimAddress'],
      isComplainantAlsoVictim: data['isComplainantAlsoVictim'] as bool?,
      occurrenceDay: data['occurrenceDay'],
      occurrenceDateTimeFrom: data['occurrenceDateTimeFrom'],
      occurrenceDateTimeTo: data['occurrenceDateTimeTo'],
      timePeriod: data['timePeriod'],
      priorToDateTimeDetails: data['priorToDateTimeDetails'],
      beatNumber: data['beatNumber'],
      placeOfOccurrenceStreet: data['placeOfOccurrenceStreet'],
      placeOfOccurrenceArea: data['placeOfOccurrenceArea'],
      placeOfOccurrenceCity: data['placeOfOccurrenceCity'],
      placeOfOccurrenceState: data['placeOfOccurrenceState'],
      placeOfOccurrencePin: data['placeOfOccurrencePin'],
      placeOfOccurrenceLatitude: data['placeOfOccurrenceLatitude'],
      placeOfOccurrenceLongitude: data['placeOfOccurrenceLongitude'],
      distanceFromPS: data['distanceFromPS'],
      directionFromPS: data['directionFromPS'],
      informationReceivedDateTime: data['informationReceivedDateTime'],
      generalDiaryEntryNumber: data['generalDiaryEntryNumber'],
      informationType: data['informationType'],
      isOutsideJurisdiction: data['isOutsideJurisdiction'] as bool?,
      actsAndSectionsInvolved: data['actsAndSectionsInvolved'],
      incidentDetails: data['incidentDetails'],
      complaintStatement: data['complaintStatement'],
      propertiesDetails: data['propertiesDetails'],
      propertiesTotalValueInr: data['propertiesTotalValueInr'],
      isDelayInReporting: data['isDelayInReporting'] as bool?,
      inquestReportCaseNo: data['inquestReportCaseNo'],
      actionTakenDetails: data['actionTakenDetails'],
      investigatingOfficerName: data['investigatingOfficerName'],
      investigatingOfficerRank: data['investigatingOfficerRank'],
      investigatingOfficerDistrict: data['investigatingOfficerDistrict'],
      dispatchDateTime: data['dispatchDateTime'],
      dispatchOfficerName: data['dispatchOfficerName'],
      dispatchOfficerRank: data['dispatchOfficerRank'],
      isFirReadOverAndAdmittedCorrect: data['isFirReadOverAndAdmittedCorrect'] as bool?,
      isFirCopyGivenFreeOfCost: data['isFirCopyGivenFreeOfCost'] as bool?,
      isRoacRecorded: data['isRoacRecorded'] as bool?,
      complainantSignatureNote: data['complainantSignatureNote'],
      accusedPersons: data['accusedPersons'] as List<dynamic>?,
      investigationReportPdfUrl: data['investigationReportPdfUrl'],
      investigationReportGeneratedAt:
          data['investigationReportGeneratedAt'] as Timestamp?,
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
      'caseId': caseId,
      'district': district,
      'policeStation': policeStation,
      'year': year,
      'firNumber': firNumber,
      'date': date,
      'firFiledTimestamp': firFiledTimestamp,
      'complainantName': complainantName,
      'complainantFatherHusbandName': complainantFatherHusbandName,
      'complainantGender': complainantGender,
      'complainantMobileNumber': complainantMobileNumber,
      'complainantNationality': complainantNationality,
      'complainantCaste': complainantCaste,
      'complainantOccupation': complainantOccupation,
      'complainantDob': complainantDob,
      'complainantAge': complainantAge,
      'complainantAddress': complainantAddress,
      'complainantPassportNumber': complainantPassportNumber,
      'complainantPassportPlaceOfIssue': complainantPassportPlaceOfIssue,
      'complainantPassportDateOfIssue': complainantPassportDateOfIssue,
      'victimName': victimName,
      'victimAge': victimAge,
      'victimGender': victimGender,
      'victimFatherHusbandName': victimFatherHusbandName,
      'victimNationality': victimNationality,
      'victimReligion': victimReligion,
      'victimCaste': victimCaste,
      'victimOccupation': victimOccupation,
      'victimDob': victimDob,
      'victimAddress': victimAddress,
      'isComplainantAlsoVictim': isComplainantAlsoVictim,
      'occurrenceDay': occurrenceDay,
      'occurrenceDateTimeFrom': occurrenceDateTimeFrom,
      'occurrenceDateTimeTo': occurrenceDateTimeTo,
      'timePeriod': timePeriod,
      'priorToDateTimeDetails': priorToDateTimeDetails,
      'beatNumber': beatNumber,
      'placeOfOccurrenceStreet': placeOfOccurrenceStreet,
      'placeOfOccurrenceArea': placeOfOccurrenceArea,
      'placeOfOccurrenceCity': placeOfOccurrenceCity,
      'placeOfOccurrenceState': placeOfOccurrenceState,
      'placeOfOccurrencePin': placeOfOccurrencePin,
      'placeOfOccurrenceLatitude': placeOfOccurrenceLatitude,
      'placeOfOccurrenceLongitude': placeOfOccurrenceLongitude,
      'distanceFromPS': distanceFromPS,
      'directionFromPS': directionFromPS,
      'informationReceivedDateTime': informationReceivedDateTime,
      'generalDiaryEntryNumber': generalDiaryEntryNumber,
      'informationType': informationType,
      'isOutsideJurisdiction': isOutsideJurisdiction,
      'actsAndSectionsInvolved': actsAndSectionsInvolved,
      'incidentDetails': incidentDetails,
      'complaintStatement': complaintStatement,
      'propertiesDetails': propertiesDetails,
      'propertiesTotalValueInr': propertiesTotalValueInr,
      'isDelayInReporting': isDelayInReporting,
      'inquestReportCaseNo': inquestReportCaseNo,
      'actionTakenDetails': actionTakenDetails,
      'investigatingOfficerName': investigatingOfficerName,
      'investigatingOfficerRank': investigatingOfficerRank,
      'investigatingOfficerDistrict': investigatingOfficerDistrict,
      'dispatchDateTime': dispatchDateTime,
      'dispatchOfficerName': dispatchOfficerName,
      'dispatchOfficerRank': dispatchOfficerRank,
      'isFirReadOverAndAdmittedCorrect': isFirReadOverAndAdmittedCorrect,
      'isFirCopyGivenFreeOfCost': isFirCopyGivenFreeOfCost,
      'isRoacRecorded': isRoacRecorded,
      'complainantSignatureNote': complainantSignatureNote,
      'accusedPersons': accusedPersons,
      'investigationReportPdfUrl': investigationReportPdfUrl,
      'investigationReportGeneratedAt': investigationReportGeneratedAt,
    };
  }
}
