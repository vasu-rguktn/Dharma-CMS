// models/user_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? email;           // Now optional
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
    this.email,
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
      uid: doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      stationName: data['stationName'] as String?,
      district: data['district'] as String?,
      rank: data['rank'] as String?,
      badgeNumber: data['badgeNumber'] as String?,
      employeeId: data['employeeId'] as String?,
      houseNo: data['houseNo'] as String?,
      address: data['address'] as String?,
      state: data['state'] as String?,
      country: data['country'] as String?,
      pincode: data['pincode'] as String?,
      username: data['username'] as String?,
      dob: data['dob'] as String?,
      gender: data['gender'] as String?,
      role: data['role'] ?? 'citizen',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'stationName': stationName,
      'district': district,
      'rank': rank,
      'badgeNumber': badgeNumber,
      'employeeId': employeeId,
      'houseNo': houseNo,
      'address': address,
      'state': state,
      'country': country,
      'pincode': pincode,
      'username': username,
      'dob': dob,
      'gender': gender,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    }..removeWhere((key, value) => value == null);
  }
}