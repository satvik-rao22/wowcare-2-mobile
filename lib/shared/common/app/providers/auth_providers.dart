import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static String username = '';
  static String password = '';
  static String refTable = '';
  static String role = 'a';
  static String accessToken = '';
  static int refTableId = 0;
  static int schoolId = 0;
  static bool isTokenRefreshed = false;

  Future<void> setAccessToken(String accesstoken) async {
    accessToken = accesstoken;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accesstoken);
    notifyListeners();
  }

  Future<void> setUsername(String username1) async {
    username = username1;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username1);
    notifyListeners();
  }

  Future<void> setPassword(String password1) async {
    password = password1;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', password1);
    notifyListeners();
  }

  Future<void> setRefTable(String refTable1) async {
    refTable = refTable1;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('refTable', refTable1);
    notifyListeners();
  }

  Future<void> setRole(String role1) async {
    role = role1;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role1);
    notifyListeners();
  }

  Future<void> setRefTableId(int refTableId1) async {
    refTableId = refTableId1;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('refTableId', refTableId1);
    notifyListeners();
  }

  Future<void> setSchoolId(int schoolId1) async {
    schoolId = schoolId1;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('schoolId', schoolId1);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();

    // Preserve onboarding flag so intro screens are not shown again
    // after a regular logout. This makes onboarding truly "first run only".
    final hasSeenOnboarding = prefs.getBool('onboardingSeen') ?? false;

    await prefs.clear();

    if (hasSeenOnboarding) {
      await prefs.setBool('onboardingSeen', true);
    }
    username = '';
    password = '';
    refTable = '';
    role = 'a';
    accessToken = '';
    refTableId = 0;
    schoolId = 0;
    isTokenRefreshed = false;
    notifyListeners();
  }

  Future<void> loadStoredData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    password = prefs.getString('password') ?? '';
    refTable = prefs.getString('refTable') ?? '';
    role = prefs.getString('role') ?? 'a';
    accessToken = prefs.getString('accessToken') ?? '';
    refTableId = prefs.getInt('refTableId') ?? 0;
    schoolId = prefs.getInt('schoolId') ?? 0;
    notifyListeners();
  }

  bool get isLoggedIn => accessToken.isNotEmpty;

  String get currentRole => role;

  String get currentUsername => username;
}
