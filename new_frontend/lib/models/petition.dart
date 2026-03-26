/// Petition model — works with JSON from PostgreSQL backend.
/// NO Firestore dependency.

String maskPhoneNumber(String? phoneNumber) {
  if (phoneNumber == null || phoneNumber.isEmpty) return 'N/A';
  final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.length < 3) return digitsOnly;
  return '${digitsOnly.substring(0, 3)}${'x' * (digitsOnly.length - 3)}';
}

enum PetitionType { bail, anticipatoryBail, revision, appeal, writ, quashing, other }

extension PetitionTypeExt on PetitionType {
  String get displayName {
    switch (this) {
      case PetitionType.bail: return 'Bail Application';
      case PetitionType.anticipatoryBail: return 'Anticipatory Bail';
      case PetitionType.revision: return 'Revision Petition';
      case PetitionType.appeal: return 'Appeal';
      case PetitionType.writ: return 'Writ Petition';
      case PetitionType.quashing: return 'Quashing Petition';
      default: return 'Other';
    }
  }

  static PetitionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bail application': case 'bail': return PetitionType.bail;
      case 'anticipatory bail': return PetitionType.anticipatoryBail;
      case 'revision petition': case 'revision': return PetitionType.revision;
      case 'appeal': return PetitionType.appeal;
      case 'writ petition': case 'writ': return PetitionType.writ;
      case 'quashing petition': case 'quashing': return PetitionType.quashing;
      default: return PetitionType.other;
    }
  }
}

enum PetitionStatus { draft, filed, underReview, hearingScheduled, granted, rejected, withdrawn }

extension PetitionStatusExt on PetitionStatus {
  String get displayName {
    switch (this) {
      case PetitionStatus.draft: return 'Draft';
      case PetitionStatus.filed: return 'Filed';
      case PetitionStatus.underReview: return 'Under Review';
      case PetitionStatus.hearingScheduled: return 'Hearing Scheduled';
      case PetitionStatus.granted: return 'Granted';
      case PetitionStatus.rejected: return 'Rejected';
      case PetitionStatus.withdrawn: return 'Withdrawn';
    }
  }

  static PetitionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft': return PetitionStatus.draft;
      case 'filed': return PetitionStatus.filed;
      case 'under review': return PetitionStatus.underReview;
      case 'hearing scheduled': return PetitionStatus.hearingScheduled;
      case 'granted': return PetitionStatus.granted;
      case 'rejected': return PetitionStatus.rejected;
      case 'withdrawn': return PetitionStatus.withdrawn;
      default: return PetitionStatus.draft;
    }
  }
}

class Petition {
  final String? id;
  final String title;
  final String? caseId;
  final String? petitionNumber;
  final PetitionType type;
  final PetitionStatus status;
  final String petitionerName;
  final String? phoneNumber;
  final String? address;
  final String grounds;
  final String? prayerRelief;
  final String? incidentAddress;
  final DateTime? incidentDate;
  final String? district;
  final String? stationName;
  final String? firNumber;
  final String? nextHearingDate;
  final String? filingDate;
  final String? orderDate;
  final String? orderDetails;
  final String? policeStatus;
  final String? policeSubStatus;
  final bool isAnonymous;
  final String? accusedDetails;
  final String? stolenProperty;
  final String? witnesses;
  final String? evidenceStatus;
  final String? extractedText;
  final String? handwrittenDocumentUrl;
  final List<String>? proofDocumentUrls;
  final List<Map<String, dynamic>>? feedbacks;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEscalated {
    final ps = policeStatus?.toLowerCase() ?? '';
    if (ps.contains('close') || ps.contains('reject') || ps.contains('resolve') || ps.contains('progress')) return false;
    return DateTime.now().difference(createdAt).inDays >= 15;
  }

  int get escalationLevel {
    final ps = policeStatus?.toLowerCase() ?? '';
    if (ps.contains('close') || ps.contains('reject') || ps.contains('resolve') || ps.contains('progress')) return 0;
    final days = DateTime.now().difference(createdAt).inDays;
    if (days >= 45) return 3;
    if (days >= 30) return 2;
    if (days >= 15) return 1;
    return 0;
  }

  Petition({
    this.id,
    required this.title,
    this.caseId,
    this.petitionNumber,
    this.type = PetitionType.other,
    this.status = PetitionStatus.draft,
    required this.petitionerName,
    this.phoneNumber,
    this.address,
    required this.grounds,
    this.prayerRelief,
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
    this.isAnonymous = false,
    this.accusedDetails,
    this.stolenProperty,
    this.witnesses,
    this.evidenceStatus,
    this.extractedText,
    this.handwrittenDocumentUrl,
    this.proofDocumentUrls,
    this.feedbacks,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });
  factory Petition.fromJson(Map<String, dynamic> data, [String? docId]) {
    return Petition(
      id: docId ?? data['id']?.toString(),
      caseId: data['case_id'],
      petitionNumber: data['petition_number'],
      title: data['title'] ?? '',
      type: PetitionTypeExt.fromString(data['petition_type'] ?? data['type'] ?? 'other'),
      status: PetitionStatusExt.fromString(data['lifecycle_status'] ?? data['status'] ?? 'draft'),
      petitionerName: data['petitioner_name'] ?? data['petitionerName'] ?? '',
      phoneNumber: data['phone_number'] ?? data['phoneNumber'],
      address: data['address'],
      grounds: data['grounds'] ?? data['description'] ?? '',
      prayerRelief: data['prayer_relief'] ?? data['prayerRelief'],
      incidentAddress: data['incident_address'] ?? data['incidentAddress'],
      incidentDate: _parseDT(data['incident_at'] ?? data['incidentDate']),
      district: data['district'],
      stationName: data['station_name'] ?? data['stationName'],
      firNumber: data['fir_number'] ?? data['firNumber'],
      nextHearingDate: data['next_hearing_date'] ?? data['nextHearingDate'],
      filingDate: data['filing_date'] ?? data['filingDate'],
      orderDate: data['order_date'] ?? data['orderDate'],
      orderDetails: data['order_details'] ?? data['orderDetails'],
      policeStatus: data['police_status'] ?? data['policeStatus'],
      policeSubStatus: data['police_sub_status'] ?? data['policeSubStatus'],
      extractedText: data['extracted_text'] ?? data['extractedText'],
      handwrittenDocumentUrl: data['handwritten_document_url'] ?? data['handwrittenDocumentUrl'],
      proofDocumentUrls: (data['proof_document_urls'] ?? data['proofDocumentUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      feedbacks: (data['feedbacks'] as List<dynamic>?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      accusedDetails: data['accused_details'] ?? data['accusedDetails'],
      stolenProperty: data['stolen_property'] ?? data['stolenProperty'],
      witnesses: data['witnesses'],
      evidenceStatus: data['evidence_status'] ?? data['evidenceStatus'],
      userId: data['created_by_account_id']?.toString() ?? data['userId'] ?? '',
      createdAt: _parseDT(data['created_at'] ?? data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDT(data['updated_at'] ?? data['updatedAt']) ?? DateTime.now(),
      isAnonymous: (data['is_anonymous'] ?? data['isAnonymous'] ?? false) == true || data['petitioner_name'] == 'Anonymous' || data['petitionerName'] == 'Anonymous',
    );
  }
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'petition_type': type.displayName,
        if (caseId != null) 'case_id': caseId,
        'lifecycle_status': status.displayName,
        'petitioner_name': petitionerName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (address != null) 'address': address,
        'grounds': grounds,
        if (prayerRelief != null) 'prayer_relief': prayerRelief,
        if (incidentAddress != null) 'incident_address': incidentAddress,
        if (incidentDate != null) 'incident_at': incidentDate!.toIso8601String(),
        if (district != null) 'district': district,
        if (stationName != null) 'station_name': stationName,
        if (policeStatus != null) 'police_status': policeStatus,
        if (policeSubStatus != null) 'police_sub_status': policeSubStatus,
        if (extractedText != null) 'extracted_text': extractedText,
        if (handwrittenDocumentUrl != null) 'handwritten_document_url': handwrittenDocumentUrl,
        if (proofDocumentUrls != null) 'proof_document_urls': proofDocumentUrls,
        if (accusedDetails != null) 'accused_details': accusedDetails,
        if (stolenProperty != null) 'stolen_property': stolenProperty,
        if (witnesses != null) 'witnesses': witnesses,
        if (evidenceStatus != null) 'evidence_status': evidenceStatus,
        'is_anonymous': isAnonymous,
      };

  static DateTime? _parseDT(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
