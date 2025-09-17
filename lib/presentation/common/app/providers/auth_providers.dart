import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:wowcare/core/errors/exceptions.dart';
import 'package:wowcare/core/errors/failure.dart';
import 'package:wowcare/core/util/constants.dart';
import 'package:wowcare/core/util/typedefs.dart';
import 'package:wowcare/features/authentication/domain/entities/user.dart';
import 'package:wowcare/features/authentication/presentation/cubit/cubit/access_cubit.dart';
import 'package:wowcare/features/guardian/data/model/guardianDataModel.dart';
import 'package:wowcare/features/guardian/domain/entities/guardianData.dart';
import 'package:wowcare/features/school/data/model/schoolDataModel.dart';
import 'package:wowcare/features/user/data/model/staffModel.dart';
import 'package:wowcare/features/user/domain/entities/staff.dart';
import 'package:wowcare/main.dart';
import 'package:wowcare/src/auth/data/Models/user_model.dart';
import 'package:wowcare/src/auth/presentation/views/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wowcare/core/util/geofencing_service.dart'; // For LocationService

class AuthProvider extends ChangeNotifier {
  static AccessUser accessUser = AccessUser.empty();
  static SecurityUserModel securityUser = SecurityUserModel.empty();
  static SchoolDataModel userSchool = SchoolDataModel.empty();
  static Staff staff = StaffModel.empty;
  static GuardianEntity guardian = GuardianDataModel.empty;
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

  Future<void> setAccessUser(AccessUser accessUser1) async {
    accessUser = accessUser1;
    accessToken = accessUser1.accessToken;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessUser1.accessToken);
    notifyListeners();
  }

  static void setAccessToken(String accesstoken) async {
    accessToken = '';
    accessToken = accesstoken;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
  }

  Future<void> setSecurityUser(SecurityUserModel securityUser1) async {
    securityUser = securityUser1;
    notifyListeners();
  }

  Future<void> setUserSchool(SchoolDataModel schoolDataModel) async {
    userSchool = schoolDataModel;
    targetLatitude = schoolDataModel.latitude;
    targetLongitude = schoolDataModel.longitude;
    print(
        "This is the Lat :- ${targetLatitude} and Long :- ${targetLongitude}");
    // NEW: Update LocationService with new coordinates
    LocationService().setTargetLocation(targetLatitude, targetLongitude);
    notifyListeners();
  }

  Future<void> setUserRole(String role) async {
    role = role;
    notifyListeners();
  }

  Future<void> setStaff(Staff staff1) async {
    staff = staff1;
    notifyListeners();
  }

  Future<void> setGuardian(GuardianEntity guardian1) async {
    guardian = guardian1;
    notifyListeners();
  }

  Staff getStaff() {
    return staff;
  }

  String getUserRole() {
    return role;
  }

  SecurityUserModel getSecurityUser() {
    return securityUser;
  }

  AccessUser getAccesseUser() {
    return accessUser;
  }

  SchoolDataModel getUserSchool() {
    return userSchool;
  }

  static SchoolDataModel getUserSchoolForLogin() {
    return userSchool;
  }

  Future<void> setUserName(String username) async {
    username = username;
    notifyListeners();
  }

  Future<void> setPassword(String password) async {
    password = password;
    notifyListeners();
  }

  Future<void> setSchoolId(int id) async {
    schoolId = id;
    notifyListeners();
  }

  Future<void> setUserCount(int id) async {
    userCount = id;
    notifyListeners();
  }

  int getUserCount() {
    return userCount;
  }

  Future<bool> isAccessTokenExpired() async {
    return accessUser.accessToken.isEmpty;
  }

  ResultFuture<AccessUser> refreshTokenIfExpired(
      BuildContext context, AccessCubit accessCubit) async {
    final authProvider = context.read<AuthProvider>();

    if (await authProvider.isAccessTokenExpired()) {
      try {
        final newToken = await accessCubit.getAccesseUser(
            username: username, password: password);
        print(newToken);
        print(username);
        print(password);

        authProvider.setAccessUser(newToken);
        return Right(newToken);
      } on ApiException catch (e) {
        return Left(ApiFailure.fromApiException(e));
      }
    }

    return Right(AccessUser.empty());
  }

  static Future<bool> getRefreshToken() async {
    final refreshTokenEndpoint = Uri.parse('$accessTokenUrl');

    final payload = {
      'grant_type': 'refresh_token',
      'refresh_token': '${AuthProvider.accessUser.refreshToken}',
      'client_id': 'erp_mobile',
    };

    try {
      final response = await http.post(
        refreshTokenEndpoint,
        body: payload,
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );

      if (response.statusCode == 200) {
        var accessTokenJson = response.body;
        var accessTokenMap = jsonDecode(accessTokenJson);
        var accessToken = accessTokenMap['access_token'];
        setAccessToken(accessToken);
        return true;
      } else {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthScreen(),
          ),
          (route) => false,
        );
        return false;
      }
    } catch (e) {
      print('Error: $e');
      throw ApiException(
          message: 'Exception occurred while refreshing token: $e',
          statusCode: 500);
    }
  }
}

