class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final int refreshExpiresIn;
  final String tokenType;
  final String userCode;
  final String email;
  final String displayName;
  final bool firstLogin;
  final List<RoleModel> roles;

  LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.refreshExpiresIn,
    required this.tokenType,
    required this.userCode,
    required this.email,
    required this.displayName,
    required this.firstLogin,
    required this.roles,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to int (handles both int and string)
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return LoginResponseModel(
      accessToken:
          (json['accessToken'] ?? json['access_token']) as String? ?? '',
      refreshToken:
          (json['refreshToken'] ?? json['refresh_token']) as String? ?? '',
      expiresIn: _toInt(json['expiresIn']),
      refreshExpiresIn: _toInt(json['refreshExpiresIn']),
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      userCode: (json['userCode'] as String? ?? '').trim(),
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      firstLogin: json['firstLogin'] as bool? ?? false,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((role) => RoleModel.fromJson(role as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'refreshExpiresIn': refreshExpiresIn,
      'tokenType': tokenType,
      'userCode': userCode,
      'email': email,
      'displayName': displayName,
      'firstLogin': firstLogin,
      'roles': roles.map((role) => role.toJson()).toList(),
    };
  }
}

class RoleModel {
  final String role;
  final String organizationCode;
  final String schoolCode;
  final String schoolName;

  RoleModel({
    required this.role,
    required this.organizationCode,
    required this.schoolCode,
    required this.schoolName,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      role: json['role'] as String? ?? '',
      organizationCode: json['organizationCode'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
      'schoolName': schoolName,
    };
  }
}
