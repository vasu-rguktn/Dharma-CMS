/// User profile model — works with JSON from PostgreSQL backend.
/// NO Firestore dependency.
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
  final String? aadharNumber;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    this.aadharNumber,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['firebase_uid'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? json['displayName'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      stationName: json['station_name'] ?? json['stationName'],
      district: json['district'],
      rank: json['rank'],
      badgeNumber: json['badge_number'] ?? json['badgeNumber'],
      employeeId: json['employee_id'] ?? json['employeeId'],
      houseNo: json['house_no'] ?? json['houseNo'],
      address: json['address_line1'] ?? json['address'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      username: json['username'],
      dob: json['dob'],
      gender: json['gender'],
      aadharNumber: json['aadhaar_number'] ?? json['aadharNumber'],
      role: json['role'] ?? 'citizen',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        if (displayName != null) 'displayName': displayName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (stationName != null) 'stationName': stationName,
        if (district != null) 'district': district,
        if (houseNo != null) 'houseNo': houseNo,
        if (address != null) 'address': address,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        if (pincode != null) 'pincode': pincode,
        if (username != null) 'username': username,
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender,
        if (aadharNumber != null) 'aadharNumber': aadharNumber,
        'role': role,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? stationName,
    String? district,
    String? houseNo,
    String? address,
    String? pincode,
    String? username,
    String? dob,
    String? gender,
    String? aadharNumber,
    String? role,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      stationName: stationName ?? this.stationName,
      district: district ?? this.district,
      rank: rank,
      badgeNumber: badgeNumber,
      employeeId: employeeId,
      houseNo: houseNo ?? this.houseNo,
      address: address ?? this.address,
      state: state,
      country: country,
      pincode: pincode ?? this.pincode,
      username: username ?? this.username,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      role: role ?? this.role,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return dt;
    }
    return DateTime.now();
  }
}
