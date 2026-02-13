import 'package:cloud_firestore/cloud_firestore.dart';

class ChargesheetModel {
  final String id;
  final String content;
  final String? caseId;
  final String? firNumber;
  final String officerId;
  final String title;
  final DateTime createdAt;

  ChargesheetModel({
    required this.id,
    required this.content,
    this.caseId,
    this.firNumber,
    required this.officerId,
    required this.title,
    required this.createdAt,
  });

  factory ChargesheetModel.fromMap(Map<String, dynamic> map, String id) {
    return ChargesheetModel(
      id: id,
      content: map['content'] ?? '',
      caseId: map['caseId'],
      firNumber: map['firNumber'],
      officerId: map['officerId'] ?? '',
      title: map['title'] ?? 'Untitled Chargesheet',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'caseId': caseId,
      'firNumber': firNumber,
      'officerId': officerId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
