import 'package:equatable/equatable.dart';

class StudentPickupModel extends Equatable {
  const StudentPickupModel({
    this.code,
    this.studentCode,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.relation,
    this.clockPin,
    this.relationshipDescription,
    this.pickupType,
    this.carpoolId,
    this.profilePhotoUrl,
    this.profilePhotoAssetCode,
  });

  final String? code;
  final String? studentCode;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String relation;
  final String? clockPin;
  final String? relationshipDescription;
  final String? pickupType;
  final String? carpoolId;
  final String? profilePhotoUrl;
  final String? profilePhotoAssetCode;

  String get fullName => ('$firstName $lastName').trim();

  factory StudentPickupModel.fromJson(Map<String, dynamic> json) {
    String? firstNonEmpty(List<String> keys) {
      for (final k in keys) {
        final v = (json[k] as Object?)?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
      return null;
    }

    return StudentPickupModel(
      code:
          (json['code'] ?? json['pickupCode'] ?? json['pickup_code'])
              as String?,
      studentCode: json['studentCode'] as String?,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
      clockPin: json['clockPin'] as String?,
      relationshipDescription: json['relationshipDescription'] as String?,
      pickupType: json['pickupType'] as String?,
      carpoolId: (json['carpoolId'] ?? json['guardianCode']) as String?,
      profilePhotoUrl: firstNonEmpty(const [
        'profilePhotoUrl',
        'photoUrl',
        'profileImageUrl',
        'imageUrl',
      ]),
      profilePhotoAssetCode: firstNonEmpty(const [
        'profilePhotoAssetCode',
        'photoAssetCode',
        'mediaAssetCode',
      ]),
    );
  }

  @override
  List<Object?> get props => [
    code,
    studentCode,
    firstName,
    lastName,
    email,
    phoneNumber,
    relation,
    clockPin,
    relationshipDescription,
    pickupType,
    carpoolId,
    profilePhotoUrl,
    profilePhotoAssetCode,
  ];
}
