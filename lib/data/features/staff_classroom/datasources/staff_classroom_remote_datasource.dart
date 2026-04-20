import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/staff_classroom_models.dart';

abstract class StaffClassroomRemoteDataSource {
  Future<List<StaffClassroomItemModel>> getStaffClassrooms({
    required String schoolCode,
    List<String>? classCodes,
    List<String>? primaryClassroomCodes,
    String? excludeClassroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
    String? organizationCode,
    String? firstName,
    String? phoneNumber,
    String? code,
  });

  Future<StaffClassroomAssignResponseModel> assignStaffToClassroom({
    required String classroomCode,
    required List<String> staffCodes,
  });
}

class StaffClassroomRemoteDataSourceImpl implements StaffClassroomRemoteDataSource {
  StaffClassroomRemoteDataSourceImpl(this._client);
  final Dio _client;

  @override
  Future<List<StaffClassroomItemModel>> getStaffClassrooms({
    required String schoolCode,
    List<String>? classCodes,
    List<String>? primaryClassroomCodes,
    String? excludeClassroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
    String? organizationCode,
    String? firstName,
    String? phoneNumber,
    String? code,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffClassrooms,
      ApiConstants.staffBaseUrl,
    );

    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
    };

    if (code != null && code.trim().isNotEmpty) queryParameters['code'] = code.trim();
    if (organizationCode != null && organizationCode.trim().isNotEmpty) {
      queryParameters['organizationCode'] = organizationCode.trim();
    }
    if (firstName != null && firstName.trim().isNotEmpty) {
      queryParameters['firstName'] = firstName.trim();
    }
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      queryParameters['phoneNumber'] = phoneNumber.trim();
    }
    if (excludeClassroomCode != null && excludeClassroomCode.trim().isNotEmpty) {
      queryParameters['excludeClassroomCode'] = excludeClassroomCode.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final norm = (List<String>? v) =>
        (v ?? []).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final normStatus = norm(status);
    if (normStatus.isNotEmpty) queryParameters['status'] = normStatus;

    final normDesignation = norm(designation);
    if (normDesignation.isNotEmpty) queryParameters['designation'] = normDesignation;

    final normPrimary = norm(primaryClassroomCodes);
    if (normPrimary.isNotEmpty) queryParameters['primaryClassroomCodes'] = normPrimary;

    final normClassCodes = norm(classCodes);
    if (normClassCodes.isNotEmpty) queryParameters['classCodes'] = normClassCodes;

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected staff-classrooms API response format');
    }

    final data = body['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(StaffClassroomItemModel.fromJson)
        .toList();
  }

  @override
  Future<StaffClassroomAssignResponseModel> assignStaffToClassroom({
    required String classroomCode,
    required List<String> staffCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffClassroomsAssignStaff,
      ApiConstants.staffBaseUrl,
    );

    final normStaffCodes =
        staffCodes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final queryParameters = <String, dynamic>{
      'classroomCode': classroomCode.trim(),
      'staffCode': normStaffCodes,
    };

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected staff-classrooms(assign) response format');
    }

    return StaffClassroomAssignResponseModel.fromJson(body);
  }
}

