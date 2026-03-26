/// User profile model for police officers. Maps to backend Account + PoliceProfile.
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String role;
  final String? photoUrl;

  // Police-specific
  final String? rank;
  final String? district;
  final String? stationName;
  final String? rangeName;
  final String? circleName;
  final String? sdpoName;
  final bool isApproved;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.role = 'police',
    this.photoUrl,
    this.rank,
    this.district,
    this.stationName,
    this.rangeName,
    this.circleName,
    this.sdpoName,
    this.isApproved = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['firebase_uid'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? json['displayName'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      role: json['role'] ?? 'police',
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      rank: json['rank'],
      district: json['district'],
      stationName: json['station_name'] ?? json['stationName'],
      rangeName: json['range_name'] ?? json['rangeName'],
      circleName: json['circle_name'] ?? json['circleName'],
      sdpoName: json['sdpo_name'] ?? json['sdpoName'],
      isApproved: json['is_approved'] ?? json['isApproved'] ?? false,
    );
  }
}
