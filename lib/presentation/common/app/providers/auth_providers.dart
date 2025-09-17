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
  static double targetLatitude = 0;
  static double targetLongitude = 0;
  static int userCount = 0;

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

  Future<void> setTargetLocation(double latitude, double longitude) async {
    targetLatitude = latitude;
    targetLongitude = longitude;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('targetLatitude', latitude);
    await prefs.setDouble('targetLongitude', longitude);
    notifyListeners();
  }

  Future<void> setUserCount(int userCount1) async {
    userCount = userCount1;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userCount', userCount1);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    username = '';
    password = '';
    refTable = '';
    role = 'a';
    accessToken = '';
    refTableId = 0;
    schoolId = 0;
    isTokenRefreshed = false;
    targetLatitude = 0;
    targetLongitude = 0;
    userCount = 0;
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
    targetLatitude = prefs.getDouble('targetLatitude') ?? 0;
    targetLongitude = prefs.getDouble('targetLongitude') ?? 0;
    userCount = prefs.getInt('userCount') ?? 0;
    notifyListeners();
  }

  bool get isLoggedIn => accessToken.isNotEmpty;

  String get currentRole => role;

  String get currentUsername => username;
}