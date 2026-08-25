import 'dart:convert';

class LoginRequestModel {
  final String username;
  final String password;

  LoginRequestModel({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      // Backend expects password as base64-encoded string
      'password': base64Encode(password.codeUnits),
    };
  }
}
