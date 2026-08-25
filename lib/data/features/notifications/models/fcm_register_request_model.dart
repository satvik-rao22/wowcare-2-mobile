class FcmRegisterRequestModel {
  const FcmRegisterRequestModel({
    required this.userCode,
    required this.organizationCode,
    required this.schoolCode,
    required this.role,
    required this.fcmToken,
    required this.deviceType,
    required this.deviceId,
    this.deviceInfo,
    this.isActive = true,
  });

  final String userCode;
  final String organizationCode;
  final String schoolCode;
  final String role;
  final String fcmToken;
  final String deviceType;
  final String deviceId;
  final String? deviceInfo;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'userCode': userCode,
    'organizationCode': organizationCode,
    'schoolCode': schoolCode,
    'role': role,
    'fcmToken': fcmToken,
    'isActive': isActive,
    'deviceType': deviceType,
    'deviceId': deviceId,
    if (deviceInfo != null && deviceInfo!.isNotEmpty) 'deviceInfo': deviceInfo,
  };
}
