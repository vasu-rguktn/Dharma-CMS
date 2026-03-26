/// Petition model — maps to backend /petitions endpoints.
class Petition {
  final String id;
  final String? petitionNumber;
  final String? subject;
  final String? description;
  final String status;
  final String? stationName;
  final String? district;
  final String? petitionerName;
  final String? createdAt;
  final String? assignedOfficerId;

  Petition({
    required this.id,
    this.petitionNumber,
    this.subject,
    this.description,
    this.status = 'pending',
    this.stationName,
    this.district,
    this.petitionerName,
    this.createdAt,
    this.assignedOfficerId,
  });

  factory Petition.fromJson(Map<String, dynamic> json) {
    return Petition(
      id: json['id'] ?? '',
      petitionNumber: json['petition_number'] ?? json['petitionNumber'],
      subject: json['subject'],
      description: json['description'],
      status: json['status'] ?? 'pending',
      stationName: json['station_name'] ?? json['stationName'],
      district: json['district'],
      petitionerName: json['petitioner_name'] ?? json['petitionerName'],
      createdAt: json['created_at'] ?? json['createdAt'],
      assignedOfficerId: json['assigned_officer_id'],
    );
  }

  Map<String, dynamic> toJson() => {
    'petition_number': petitionNumber,
    'subject': subject,
    'description': description,
    'status': status,
    'station_name': stationName,
    'district': district,
    'petitioner_name': petitionerName,
    'assigned_officer_id': assignedOfficerId,
  }..removeWhere((_, v) => v == null);
}
