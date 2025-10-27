import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? stationName;
  final String? district;
  final String? rank;
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
      role: data['role'] ?? 'citizen',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }
}