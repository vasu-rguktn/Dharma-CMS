import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility function to mask phone numbers for anonymous petitions
/// Format: Takes first 3 digits and masks the rest with 'x'
/// Example: 9876543210 -> 987xxxxxxx
String maskPhoneNumber(String? phoneNumber) {
  if (phoneNumber == null || phoneNumber.isEmpty) return 'N/A';
  
  // Remove any non-digit characters
  final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
  
  if (digitsOnly.length < 3) return digitsOnly;
  
  // Get first 3 digits and replace the rest with 'x'
  final firstThree = digitsOnly.substring(0, 3);
  final remaining = 'x' * (digitsOnly.length - 3);
  return firstThree + remaining;
}

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
      default:
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
  final String? caseId;

  final PetitionType type;
  final PetitionStatus status;
  final String petitionerName;
  final String? phoneNumber;
  final String? address;
  final String grounds;
  final String? prayerRelief;
  // ✅ INCIDENT & LOCATION DETAILS
  final String? incidentAddress;
  final Timestamp? incidentDate;
  final String? district;
  final String? stationName;

  final String? firNumber;
  final String? nextHearingDate;
  final String? filingDate;
  final String? orderDate;
  final String? orderDetails;

  /// 🔥 Police fields
  final String? policeStatus;
  final String? policeSubStatus;

  /// 🔐 Anonymous submission field
  final bool isAnonymous;

  /// 📱 Offline submission fields
  final String? submissionType; // 'online' or 'offline'
  final String? submittedBy; // Officer UID who submitted offline
  final String? submittedByName; // Officer name
  final String? submittedByRank; // Officer rank

  /// 👮 Assignment fields
  final String? assignmentType; // 'range', 'district', 'station'
  final String? assignedTo; // Officer UID assigned to
  final String? assignedToName; // Officer name
  final String? assignedToRank; // Officer rank
  final String? assignedToRange; // Range assigned to
  final String? assignedToDistrict; // District assigned to
  final String? assignedToStation; // Station assigned to
  final String? assignedBy; // UID of assigning officer
  final String? assignedByName; // Name of assigning officer
  final String? assignedByRank; // Rank of assigning officer
  final Timestamp? assignedAt; // Assignment timestamp
  final String? assignmentStatus; // 'pending', 'accepted', 'rejected'
  final String? assignmentNotes; // Optional notes during assignment

  final String? extractedText;
  final String? handwrittenDocumentUrl;
  final List<String>? proofDocumentUrls;

  final String userId;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  /// Returns true if the petition has been pending for more than 15 days
  bool get isEscalated {
    if (policeStatus?.toLowerCase() == 'closed' || 
        policeStatus?.toLowerCase() == 'rejected' ||
        policeStatus?.toLowerCase() == 'resolved' ||
        policeStatus?.toLowerCase() == 'in progress') {
      return false;
    }
    final now = DateTime.now();
    final difference = now.difference(createdAt.toDate()).inDays;
    return difference >= 15;
  }

  /// Returns 0 for no escalation, 1 for SP (15 days), 2 for IG (30 days), 3 for DGP (45 days)
  int get escalationLevel {
    if (policeStatus?.toLowerCase() == 'closed' || 
        policeStatus?.toLowerCase() == 'rejected' ||
        policeStatus?.toLowerCase() == 'resolved' ||
        policeStatus?.toLowerCase() == 'in progress') {
      return 0;
    }
    final now = DateTime.now();
    final difference = now.difference(createdAt.toDate()).inDays;
    
    if (difference >= 45) return 3; // DGP level
    if (difference >= 30) return 2; // IG level
    if (difference >= 15) return 1; // SP level
    return 0;
  }

  Petition({
    this.id,
    required this.title,
    this.type = PetitionType.other,
    this.status = PetitionStatus.draft,
    required this.petitionerName,
    this.caseId,
    this.phoneNumber,
    this.address,
    required this.grounds,
    this.prayerRelief,
    // ✅ NEW PARAMETERS
    this.incidentAddress,
    this.incidentDate,
    this.district,
    this.stationName,
    this.firNumber,
    this.nextHearingDate,
    this.filingDate,
    this.orderDate,
    this.orderDetails,
    this.policeStatus,
    this.policeSubStatus,
    // Offline submission parameters
    this.submissionType,
    this.submittedBy,
    this.submittedByName,
    this.submittedByRank,
    // Assignment parameters
    this.assignmentType,
    this.assignedTo,
    this.assignedToName,
    this.assignedToRank,
    this.assignedToRange,
    this.assignedToDistrict,
    this.assignedToStation,
    this.assignedBy,
    this.assignedByName,
    this.assignedByRank,
    this.assignedAt,
    this.assignmentStatus,
    this.assignmentNotes,
    this.extractedText,
    this.handwrittenDocumentUrl,
    this.proofDocumentUrls,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isAnonymous = false,
  });

  factory Petition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Petition(
      id: doc.id,
      caseId: data['case_id'],
      title: data['title'] ?? '',
      type: PetitionTypeExtension.fromString(data['type'] ?? 'other'),
      status: PetitionStatusExtension.fromString(data['status'] ?? 'draft'),
      petitionerName: data['petitionerName'] ?? '',
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      grounds: data['grounds'] ?? '',
      prayerRelief: data['prayerRelief'],
      incidentAddress: data['incidentAddress'],
      incidentDate: data['incidentDate'],
      district: data['district'],
      stationName: data['stationName'],
      firNumber: data['firNumber'],
      nextHearingDate: data['nextHearingDate'],
      filingDate: data['filingDate'],
      orderDate: data['orderDate'],
      orderDetails: data['orderDetails'],
      policeStatus: data['policeStatus'],
      policeSubStatus: data['policeSubStatus'],
      // Offline submission fields
      submissionType: data['submissionType'],
      submittedBy: data['submittedBy'],
      submittedByName: data['submittedByName'],
      submittedByRank: data['submittedByRank'],
      // Assignment fields
      assignmentType: data['assignmentType'],
      assignedTo: data['assignedTo'],
      assignedToName: data['assignedToName'],
      assignedToRank: data['assignedToRank'],
      assignedToRange: data['assignedToRange'],
      assignedToDistrict: data['assignedToDistrict'],
      assignedToStation: data['assignedToStation'],
      assignedBy: data['assignedBy'],
      assignedByName: data['assignedByName'],
      assignedByRank: data['assignedByRank'],
      assignedAt: data['assignedAt'] as Timestamp?,
      assignmentStatus: data['assignmentStatus'],
      assignmentNotes: data['assignmentNotes'],
      extractedText: data['extractedText'],
      handwrittenDocumentUrl: data['handwrittenDocumentUrl'],
      proofDocumentUrls: ((data['proofDocumentUrls'] ?? data['documentUrls']) as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      userId: data['userId'] ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      isAnonymous: (data['is_anonymous'] ?? data['isAnonymous'] ?? false) ||
          (data['petitionerName'] == 'Anonymous'),
    );
  }

  factory Petition.fromMap(Map<String, dynamic> data, String id) {
    return Petition(
      id: id,
      caseId: data['case_id'],
      title: data['title'] ?? '',
      type: PetitionTypeExtension.fromString(data['type'] ?? 'other'),
      status: PetitionStatusExtension.fromString(data['status'] ?? 'draft'),
      petitionerName: data['petitionerName'] ?? '',
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      grounds: data['grounds'] ?? '',
      prayerRelief: data['prayerRelief'],
      incidentAddress: data['incidentAddress'],
      incidentDate: data['incidentDate'] is Timestamp
          ? data['incidentDate']
          : (data['incidentDate'] != null
              ? Timestamp.fromMicrosecondsSinceEpoch(
                  (data['incidentDate'].seconds * 1000000 +
                      data['incidentDate'].nanoseconds) as int)
              : null), // Handle if it's not a direct Timestamp in some cases locally
      district: data['district'],
      stationName: data['stationName'],
      firNumber: data['firNumber'],
      nextHearingDate: data['nextHearingDate'],
      filingDate: data['filingDate'],
      orderDate: data['orderDate'],
      orderDetails: data['orderDetails'],
      policeStatus: data['policeStatus'],
      policeSubStatus: data['policeSubStatus'],
      // Offline submission fields
      submissionType: data['submissionType'],
      submittedBy: data['submittedBy'],
      submittedByName: data['submittedByName'],
      submittedByRank: data['submittedByRank'],
      // Assignment fields
      assignmentType: data['assignmentType'],
      assignedTo: data['assignedTo'],
      assignedToName: data['assignedToName'],
      assignedToRank: data['assignedToRank'],
      assignedToRange: data['assignedToRange'],
      assignedToDistrict: data['assignedToDistrict'],
      assignedToStation: data['assignedToStation'],
      assignedBy: data['assignedBy'],
      assignedByName: data['assignedByName'],
      assignedByRank: data['assignedByRank'],
      assignedAt: data['assignedAt'] is Timestamp ? data['assignedAt'] : null,
      assignmentStatus: data['assignmentStatus'],
      assignmentNotes: data['assignmentNotes'],
      extractedText: data['extractedText'],
      handwrittenDocumentUrl: data['handwrittenDocumentUrl'],
      proofDocumentUrls: ((data['proofDocumentUrls'] ?? data['documentUrls']) as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      userId: data['userId'] ?? '',
      createdAt:
          data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(),
      updatedAt:
          data['updatedAt'] is Timestamp ? data['updatedAt'] : Timestamp.now(),
      isAnonymous: (data['is_anonymous'] ?? data['isAnonymous'] ?? false) ||
          (data['petitionerName'] == 'Anonymous'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.displayName,
      'case_id': caseId,
      'status': status.displayName,
      'petitionerName': petitionerName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
      'grounds': grounds,
      if (prayerRelief != null) 'prayerRelief': prayerRelief,
      if (incidentAddress != null) 'incidentAddress': incidentAddress,
      if (incidentDate != null) 'incidentDate': incidentDate,
      if (district != null) 'district': district,
      if (stationName != null) 'stationName': stationName,
      if (firNumber != null) 'firNumber': firNumber,
      if (nextHearingDate != null) 'nextHearingDate': nextHearingDate,
      if (filingDate != null) 'filingDate': filingDate,
      if (orderDate != null) 'orderDate': orderDate,
      if (orderDetails != null) 'orderDetails': orderDetails,
      if (policeStatus != null) 'policeStatus': policeStatus,
      if (policeSubStatus != null) 'policeSubStatus': policeSubStatus,
      // Offline submission fields
      if (submissionType != null) 'submissionType': submissionType,
      if (submittedBy != null) 'submittedBy': submittedBy,
      if (submittedByName != null) 'submittedByName': submittedByName,
      if (submittedByRank != null) 'submittedByRank': submittedByRank,
      // Assignment fields
      if (assignmentType != null) 'assignmentType': assignmentType,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (assignedToName != null) 'assignedToName': assignedToName,
      if (assignedToRank != null) 'assignedToRank': assignedToRank,
      if (assignedToRange != null) 'assignedToRange': assignedToRange,
      if (assignedToDistrict != null) 'assignedToDistrict': assignedToDistrict,
      if (assignedToStation != null) 'assignedToStation': assignedToStation,
      if (assignedBy != null) 'assignedBy': assignedBy,
      if (assignedByName != null) 'assignedByName': assignedByName,
      if (assignedByRank != null) 'assignedByRank': assignedByRank,
      if (assignedAt != null) 'assignedAt': assignedAt,
      if (assignmentStatus != null) 'assignmentStatus': assignmentStatus,
      if (assignmentNotes != null) 'assignmentNotes': assignmentNotes,
      if (extractedText != null) 'extractedText': extractedText,
      if (handwrittenDocumentUrl != null)
        'handwrittenDocumentUrl': handwrittenDocumentUrl,
      if (proofDocumentUrls != null) 'proofDocumentUrls': proofDocumentUrls,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'is_anonymous': isAnonymous,
    };
  }
}
