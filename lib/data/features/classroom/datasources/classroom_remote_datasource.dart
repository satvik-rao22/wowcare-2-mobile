import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/data/features/classroom/models/classroom_all_models.dart';
import 'package:wowcare/data/features/classroom/models/classroom_details_models.dart';
import 'package:wowcare/data/features/classroom/models/dashboard_summary_models.dart';

/// Data source for Classroom-related remote APIs.
abstract class ClassroomRemoteDataSource {
  Future<ClassroomAllResponseModel> getActiveClassrooms({
    required String schoolCode,

    /// When true, restricts results to type=CLASSROOM.
    /// When false, omits the type filter so the backend
    /// can return all active locations (e.g. Office, etc.).
    bool onlyTypeClassroom,

    /// Overrides [onlyTypeClassroom] when non-null. Sets `type=<value>` on
    /// the request, used to fetch a specific non-CLASSROOM type (e.g. ADMIN).
    String? typeOverride,
  });

  Future<ClassroomDetailsResponseModel> getClassroomByCode({
    required String code,
  });

  Future<SchoolCapacityModel> getSchoolCapacity({required String schoolCode});

  Future<ClassroomCountModel> getClassroomCount({
    required String schoolCode,
    required String status,
  });

  Future<SchoolFteModel> getSchoolFte({
    required String schoolCode,
    required int capacity,
  });

  /// Paginated classroom list with capacity + ratio data.
  Future<RatioClassroomPageResponseModel> getRatioMonitoringClassrooms({
    required String schoolCode,
    int page = 0,
    int size = 200,
  });

  /// Per-classroom student attendance counts from by-classrooms summary API.
  Future<Map<String, dynamic>> getStudentAttendanceSummaryByClassrooms({
    required List<String> classroomCodes,
  });

  /// Per-classroom staff attendance counts from by-classrooms summary API.
  Future<Map<String, dynamic>> getStaffAttendanceSummaryByClassrooms({
    required List<String> classroomCodes,
  });
}

class ClassroomRemoteDataSourceImpl implements ClassroomRemoteDataSource {
  ClassroomRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<ClassroomAllResponseModel> getActiveClassrooms({
    required String schoolCode,
    bool onlyTypeClassroom = true,
    String? typeOverride,
  }) async {
    // Full [Uri] so Dio does not merge this with [BaseOptions.baseUrl]
    // (which would incorrectly produce …/classroom/classroom/all).
    final qp = <String, String>{
      'school': schoolCode,
      'status': 'ACTIVE',
      'sort': 'name,asc',
    };
    final overrideType = (typeOverride ?? '').trim();
    if (overrideType.isNotEmpty) {
      qp['type'] = overrideType;
    } else if (onlyTypeClassroom) {
      qp['type'] = 'CLASSROOM';
    }
    // Build query manually so the comma in `sort=name,asc` stays literal
    // instead of being percent-encoded to `%2C`.
    final query = qp.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value).replaceAll('%2C', ',')}',
        )
        .join('&');
    final uri = Uri.parse(
      ApiPaths.url(ApiPaths.classroomAll),
    ).replace(query: query);

    final response = await _client.getUri<dynamic>(uri);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected classroom(all) API response format');
    }

    return ClassroomAllResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<ClassroomDetailsResponseModel> getClassroomByCode({
    required String code,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.classroomByCode(code),
      ApiConstants.classroomBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected classroom(details) API response format');
    }

    return ClassroomDetailsResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<SchoolCapacityModel> getSchoolCapacity({
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.schoolCapacityAge(schoolCode),
      ApiConstants.schoolMs,
    );

    final response = await _client.get<dynamic>(endpoint);
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected school capacity API response format');
    }

    return SchoolCapacityModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<ClassroomCountModel> getClassroomCount({
    required String schoolCode,
    required String status,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.classroomCount,
      ApiConstants.classroomBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
        'status': status,
      },
    );
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected classroom count API response format');
    }

    return ClassroomCountModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<SchoolFteModel> getSchoolFte({
    required String schoolCode,
    required int capacity,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.classroomSchoolFte,
      ApiConstants.classroomBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
        'schoolLicensedCapacity': capacity,
      },
    );
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected school FTE API response format');
    }

    return SchoolFteModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<RatioClassroomPageResponseModel> getRatioMonitoringClassrooms({
    required String schoolCode,
    int page = 0,
    int size = 200,
  }) async {
    final qp = <String, String>{
      'schoolCode': schoolCode,
      'page': page.toString(),
      'size': size.toString(),
      'status': 'ACTIVE',
      'type': 'CLASSROOM',
    };
    // Keep comma literal in sort value (Dio would otherwise percent-encode it).
    final query = qp.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    final rawUrl = ApiPaths.url(ApiPaths.classroomPaginated);
    final uri = Uri.parse(rawUrl).replace(query: '$query&sort=name%2Casc');

    final response = await _client.getUri<dynamic>(uri);
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected ratio monitoring classrooms API response format');
    }
    return RatioClassroomPageResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, dynamic>> getStudentAttendanceSummaryByClassrooms({
    required List<String> classroomCodes,
  }) async {
    if (classroomCodes.isEmpty) return <String, dynamic>{};

    final endpoint = ApiPaths.url(
      ApiPaths.studentAttendanceExpectedSummaryCardByClassrooms,
    );
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'classroomCodes': classroomCodes.join(','),
      },
    );
    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student attendance by-classrooms API response format',
      );
    }
    final body = response.data! as Map<String, dynamic>;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getStaffAttendanceSummaryByClassrooms({
    required List<String> classroomCodes,
  }) async {
    if (classroomCodes.isEmpty) return <String, dynamic>{};

    final endpoint = ApiPaths.url(
      ApiPaths.staffAttendanceExpectedSummaryCardByClassrooms,
    );
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'classroomCodes': classroomCodes.join(','),
      },
    );
    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected staff attendance by-classrooms API response format',
      );
    }
    final body = response.data! as Map<String, dynamic>;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }
}
