import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? stationName;
  final String? district;
  final String? rank;
  final String? range;
  final String? badgeNumber;
  final String? employeeId;
  final String? houseNo;
  final String? address;
  final String? state;
  final String? country;
  final String? pincode;
  final String? username;
  final String? dob;
  final String? gender;
  final String? aadharNumber;

  final String role;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.stationName,
    this.district,
    this.rank,
    this.range,
    this.badgeNumber,
    this.employeeId,
    this.houseNo,
    this.address,
    this.state,
    this.country,
    this.pincode,
    this.username,
    this.dob,
    this.gender,
    this.aadharNumber,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      stationName: data['stationName'],
      district: data['district'],
      rank: data['rank'],
      range: data['range'],
      badgeNumber: data['badgeNumber'],
      employeeId: data['employeeId'],
      houseNo: data['houseNo'],
      address: data['address'],
      state: data['state'],
      country: data['country'],
      pincode: data['pincode'],
      username: data['username'],
      dob: data['dob'],
      gender: data['gender'],
      aadharNumber: data['aadharNumber'],
      role: data['role'] ?? 'citizen',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? stationName,
    String? district,
    String? rank,
    String? range,
    String? badgeNumber,
    String? employeeId,
    String? houseNo,
    String? address,
    String? state,
    String? country,
    String? pincode,
    String? username,
    String? dob,
    String? gender,
    String? aadharNumber,
    String? role,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      stationName: stationName ?? this.stationName,
      district: district ?? this.district,
      rank: rank ?? this.rank,
      range: range ?? this.range,
      badgeNumber: badgeNumber ?? this.badgeNumber,
      employeeId: employeeId ?? this.employeeId,
      houseNo: houseNo ?? this.houseNo,
      address: address ?? this.address,
      state: state ?? this.state,
      country: country ?? this.country,
      pincode: pincode ?? this.pincode,
      username: username ?? this.username,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}