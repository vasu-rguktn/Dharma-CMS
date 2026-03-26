/// Case model — maps to backend /cases endpoints.
/// Backend schema: CaseOut has police_station, incident_details, complaint_statement, acts_and_sections_text
class CaseDoc {
  final String id;
  final String? caseReference;
  final String? firNumber;
  final String? title;
  final String? description; // maps to incident_details
  final String status;
  final String? stationName; // maps to police_station
  final String? district;
  final String? actsAndSections; // maps to acts_and_sections_text
  final String? complaintStatement;
  final String? petitionId;
  final String? dateFiled;
  final String? createdAt;
  final String? updatedAt;

  CaseDoc({
    required this.id,
    this.caseReference,
    this.firNumber,
    this.title,
    this.description,
    this.status = 'open',
    this.stationName,
    this.district,
    this.actsAndSections,
    this.complaintStatement,
    this.petitionId,
    this.dateFiled,
    this.createdAt,
    this.updatedAt,
  });

  factory CaseDoc.fromJson(Map<String, dynamic> json) {
    return CaseDoc(
      id: (json['id'] ?? '').toString(),
      caseReference: json['case_reference'] ?? json['caseReference'],
      firNumber: json['fir_number'] ?? json['firNumber'],
      title: json['title'],
      description: json['incident_details'] ?? json['description'],
      status: json['status'] ?? 'open',
      stationName: json['police_station'] ?? json['station_name'] ?? json['stationName'],
      district: json['district'],
      actsAndSections: json['acts_and_sections_text'] ?? json['actsAndSections'],
      complaintStatement: json['complaint_statement'] ?? json['complaintStatement'],
      petitionId: json['petition_id']?.toString(),
      dateFiled: json['date_filed'] ?? json['dateFiled'],
      createdAt: json['created_at'] ?? json['createdAt'],
      updatedAt: json['updated_at'] ?? json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'fir_number': firNumber,
    'title': title,
    'incident_details': description,
    'status': status,
    'police_station': stationName,
    'district': district,
    'acts_and_sections_text': actsAndSections,
    'complaint_statement': complaintStatement,
    'petition_id': petitionId,
    'case_reference': caseReference,
    'date_filed': dateFiled,
  }..removeWhere((_, v) => v == null);
}
