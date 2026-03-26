/// Case model — matches PostgreSQL backend CaseOut schema.
class CaseModel {
  final String id;
  final String? petitionId;
  final String? caseReference;
  final String? firNumber;
  final String? title;
  final String? district;
  final String? policeStation;
  final String status;
  final String? dateFiled;
  final String? firFiledAt;
  final String? complaintStatement;
  final String? incidentDetails;
  final String? actsAndSectionsText;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaseModel({
    required this.id,
    this.petitionId,
    this.caseReference,
    this.firNumber,
    this.title,
    this.district,
    this.policeStation,
    this.status = 'open',
    this.dateFiled,
    this.firFiledAt,
    this.complaintStatement,
    this.incidentDetails,
    this.actsAndSectionsText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] ?? '',
      petitionId: json['petition_id'],
      caseReference: json['case_reference'],
      firNumber: json['fir_number'],
      title: json['title'],
      district: json['district'],
      policeStation: json['police_station'],
      status: json['status'] ?? 'open',
      dateFiled: json['date_filed'],
      firFiledAt: json['fir_filed_at'],
      complaintStatement: json['complaint_statement'],
      incidentDetails: json['incident_details'],
      actsAndSectionsText: json['acts_and_sections_text'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (petitionId != null) 'petition_id': petitionId,
        if (caseReference != null) 'case_reference': caseReference,
        if (firNumber != null) 'fir_number': firNumber,
        if (title != null) 'title': title,
        if (district != null) 'district': district,
        if (policeStation != null) 'police_station': policeStation,
        'status': status,
        if (dateFiled != null) 'date_filed': dateFiled,
        if (complaintStatement != null) 'complaint_statement': complaintStatement,
        if (incidentDetails != null) 'incident_details': incidentDetails,
        if (actsAndSectionsText != null) 'acts_and_sections_text': actsAndSectionsText,
      };

  String get displayTitle => title ?? caseReference ?? firNumber ?? 'Case $id';

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
}
