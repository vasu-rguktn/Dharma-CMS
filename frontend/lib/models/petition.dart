// // lib/models/petition.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

// /// ---------------------------------------------------------------------------
// ///  ENUMS (kept for backend compatibility, but not shown in UI)
// /// ---------------------------------------------------------------------------

// enum PetitionType {
//   bail,
//   anticipatoryBail,
//   revision,
//   appeal,
//   writ,
//   quashing,
//   other,
// }

// extension PetitionTypeExtension on PetitionType {
//   String get displayName {
//     switch (this) {
//       case PetitionType.bail:
//         return 'Bail Application';
//       case PetitionType.anticipatoryBail:
//         return 'Anticipatory Bail';
//       case PetitionType.revision:
//         return 'Revision Petition';
//       case PetitionType.appeal:
//         return 'Appeal';
//       case PetitionType.writ:
//         return 'Writ Petition';
//       case PetitionType.quashing:
//         return 'Quashing Petition';
//       case PetitionType.other:
//         return 'Other';
//     }
//   }

//   static PetitionType fromString(String value) {
//     switch (value.toLowerCase()) {
//       case 'bail application':
//       case 'bail':
//         return PetitionType.bail;
//       case 'anticipatory bail':
//         return PetitionType.anticipatoryBail;
//       case 'revision petition':
//       case 'revision':
//         return PetitionType.revision;
//       case 'appeal':
//         return PetitionType.appeal;
//       case 'writ petition':
//       case 'writ':
//         return PetitionType.writ;
//       case 'quashing petition':
//       case 'quashing':
//         return PetitionType.quashing;
//       default:
//         return PetitionType.other;
//     }
//   }
// }

// enum PetitionStatus {
//   draft,
//   filed,
//   underReview,
//   hearingScheduled,
//   granted,
//   rejected,
//   withdrawn,
// }

// extension PetitionStatusExtension on PetitionStatus {
//   String get displayName {
//     switch (this) {
//       case PetitionStatus.draft:
//         return 'Draft';
//       case PetitionStatus.filed:
//         return 'Filed';
//       case PetitionStatus.underReview:
//         return 'Under Review';
//       case PetitionStatus.hearingScheduled:
//         return 'Hearing Scheduled';
//       case PetitionStatus.granted:
//         return 'Granted';
//       case PetitionStatus.rejected:
//         return 'Rejected';
//       case PetitionStatus.withdrawn:
//         return 'Withdrawn';
//     }
//   }

//   static PetitionStatus fromString(String value) {
//     switch (value.toLowerCase()) {
//       case 'draft':
//         return PetitionStatus.draft;
//       case 'filed':
//         return PetitionStatus.filed;
//       case 'under review':
//         return PetitionStatus.underReview;
//       case 'hearing scheduled':
//         return PetitionStatus.hearingScheduled;
//       case 'granted':
//         return PetitionStatus.granted;
//       case 'rejected':
//         return PetitionStatus.rejected;
//       case 'withdrawn':
//         return PetitionStatus.withdrawn;
//       default:
//         return PetitionStatus.draft;
//     }
//   }
// }

// /// ---------------------------------------------------------------------------
// ///  PETITION MODEL (Minimal UI fields + Optional court fields)
// /// ---------------------------------------------------------------------------

// class Petition {
//   final String? id;
//   final String title;
//   final PetitionType type; // default: other
//   final PetitionStatus status; // default: draft
//   final String petitionerName;
//   final String? phoneNumber;
//   final String? address;
//   final String grounds;
//   final String? prayerRelief;

//   // Optional court tracking fields (not in form, but shown in details)
//   final String? firNumber;
//   final String? nextHearingDate;
//   final String? filingDate;
//   final String? orderDate;
//   final String? orderDetails;

//   final String? extractedText;
//   final String? handwrittenDocumentUrl;
//   final List<String>? proofDocumentUrls;
//   final String userId;
//   final Timestamp createdAt;
//   final Timestamp updatedAt;

//   Petition({
//     this.id,
//     required this.title,
//     this.type = PetitionType.other,
//     this.status = PetitionStatus.draft,
//     required this.petitionerName,
//     this.phoneNumber,
//     this.address,
//     required this.grounds,
//     this.prayerRelief,
//     this.firNumber,
//     this.nextHearingDate,
//     this.filingDate,
//     this.orderDate,
//     this.orderDetails,
//     this.extractedText,
//     this.handwrittenDocumentUrl,
//     this.proofDocumentUrls,
//     required this.userId,
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   /// Firestore → Model
//   factory Petition.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return Petition(
//       id: doc.id,
//       title: data['title'] ?? '',
//       type: PetitionTypeExtension.fromString(data['type'] ?? 'other'),
//       status: PetitionStatusExtension.fromString(data['status'] ?? 'draft'),
//       petitionerName: data['petitionerName'] ?? '',
//       phoneNumber: data['phoneNumber'],
//       address: data['address'],
//       grounds: data['grounds'] ?? '',
//       prayerRelief: data['prayerRelief'],
//       firNumber: data['firNumber'],
//       nextHearingDate: data['nextHearingDate'],
//       filingDate: data['filingDate'],
//       orderDate: data['orderDate'],
//       orderDetails: data['orderDetails'],
//       extractedText: data['extractedText'],
//       handwrittenDocumentUrl: data['handwrittenDocumentUrl'],
//       proofDocumentUrls: (data['proofDocumentUrls'] as List<dynamic>?)
//           ?.map((e) => e.toString())
//           .toList(),
//       userId: data['userId'] ?? '',
//       createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
//       updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
//     );
//   }

//   /// Model → Firestore
//   Map<String, dynamic> toMap() {
//     return {
//       'title': title,
//       'type': type.displayName,
//       'status': status.displayName,
//       'petitionerName': petitionerName,
//       if (phoneNumber != null) 'phoneNumber': phoneNumber,
//       if (address != null) 'address': address,
//       'grounds': grounds,
//       if (prayerRelief != null) 'prayerRelief': prayerRelief,
//       if (firNumber != null) 'firNumber': firNumber,
//       if (nextHearingDate != null) 'nextHearingDate': nextHearingDate,
//       if (filingDate != null) 'filingDate': filingDate,
//       if (orderDate != null) 'orderDate': orderDate,
//       if (orderDetails != null) 'orderDetails': orderDetails,
//       if (extractedText != null) 'extractedText': extractedText,
//       if (handwrittenDocumentUrl != null)
//         'handwrittenDocumentUrl': handwrittenDocumentUrl,
//       if (proofDocumentUrls != null) 'proofDocumentUrls': proofDocumentUrls,
//       'userId': userId,
//       'createdAt': createdAt,
//       'updatedAt': updatedAt,
//     };
//   }
// }


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
  final PetitionType type;
  final PetitionStatus status;
  final String petitionerName;
  final String? phoneNumber;
  final String? address;
  final String grounds;
  final String? prayerRelief;

  final String? firNumber;
  final String? nextHearingDate;
  final String? filingDate;
  final String? orderDate;
  final String? orderDetails;

  /// 🔥 Police fields
  final String? policeStatus;
  final String? policeSubStatus;

  final String? extractedText;
  final String? handwrittenDocumentUrl;
  final List<String>? proofDocumentUrls;

  final String userId;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Petition({
    this.id,
    required this.title,
    this.type = PetitionType.other,
    this.status = PetitionStatus.draft,
    required this.petitionerName,
    this.phoneNumber,
    this.address,
    required this.grounds,
    this.prayerRelief,
    this.firNumber,
    this.nextHearingDate,
    this.filingDate,
    this.orderDate,
    this.orderDetails,
    this.policeStatus,
    this.policeSubStatus,
    this.extractedText,
    this.handwrittenDocumentUrl,
    this.proofDocumentUrls,
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
      petitionerName: data['petitionerName'] ?? '',
      phoneNumber: data['phoneNumber'],
      address: data['address'],
      grounds: data['grounds'] ?? '',
      prayerRelief: data['prayerRelief'],
      firNumber: data['firNumber'],
      nextHearingDate: data['nextHearingDate'],
      filingDate: data['filingDate'],
      orderDate: data['orderDate'],
      orderDetails: data['orderDetails'],
      policeStatus: data['policeStatus'],
      policeSubStatus: data['policeSubStatus'],
      extractedText: data['extractedText'],
      handwrittenDocumentUrl: data['handwrittenDocumentUrl'],
      proofDocumentUrls: (data['proofDocumentUrls'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
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
      'petitionerName': petitionerName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
      'grounds': grounds,
      if (prayerRelief != null) 'prayerRelief': prayerRelief,
      if (firNumber != null) 'firNumber': firNumber,
      if (nextHearingDate != null) 'nextHearingDate': nextHearingDate,
      if (filingDate != null) 'filingDate': filingDate,
      if (orderDate != null) 'orderDate': orderDate,
      if (orderDetails != null) 'orderDetails': orderDetails,
      if (policeStatus != null) 'policeStatus': policeStatus,
      if (policeSubStatus != null) 'policeSubStatus': policeSubStatus,
      if (extractedText != null) 'extractedText': extractedText,
      if (handwrittenDocumentUrl != null)
        'handwrittenDocumentUrl': handwrittenDocumentUrl,
      if (proofDocumentUrls != null) 'proofDocumentUrls': proofDocumentUrls,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
