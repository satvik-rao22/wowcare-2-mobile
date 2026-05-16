class LogoutRequestModel {
  final String refreshToken;
  final String userCode;

  LogoutRequestModel({required this.refreshToken, required this.userCode});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken, 'userCode': userCode};
  }
}
