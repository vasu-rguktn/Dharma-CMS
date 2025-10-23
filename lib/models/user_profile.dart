import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final String? stationName;
  final String? district;
  final String? rank;
  final String? badgeNumber;
  final String? employeeId;
  final String role; // 'officer', 'supervisor', 'admin'
  final UserProfileAddress? address;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.profilePhotoUrl,
    this.stationName,
    this.district,
    this.rank,
    this.badgeNumber,
    this.employeeId,
    required this.role,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      profilePhotoUrl: data['profilePhotoUrl'],
      stationName: data['stationName'],
      district: data['district'],
      rank: data['rank'],
      badgeNumber: data['badgeNumber'],
      employeeId: data['employeeId'],
      role: data['role'] ?? 'officer',
      address: data['address'] != null
          ? UserProfileAddress.fromMap(data['address'])
          : null,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'profilePhotoUrl': profilePhotoUrl,
      'stationName': stationName,
      'district': district,
      'rank': rank,
      'badgeNumber': badgeNumber,
      'employeeId': employeeId,
      'role': role,
      'address': address?.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class UserProfileAddress {
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  UserProfileAddress({
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  factory UserProfileAddress.fromMap(Map<String, dynamic> map) {
    return UserProfileAddress(
      street: map['street'],
      city: map['city'],
      state: map['state'],
      postalCode: map['postalCode'],
      country: map['country'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }
}
