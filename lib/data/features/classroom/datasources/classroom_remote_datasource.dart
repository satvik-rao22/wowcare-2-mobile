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
    DateTime? date,
  });

  /// Per-classroom staff attendance counts from by-classrooms summary API.
  Future<Map<String, dynamic>> getStaffAttendanceSummaryByClassrooms({
    required List<String> classroomCodes,
    DateTime? date,
  });

  /// GET student-classroom enrolled count (active/upcoming/enrolled) for a
  /// classroom. Org/school scoping headers are attached by AuthInterceptor.
  Future<Map<String, dynamic>?> getStudentClassroomEnrolledCount({
    required String classroomCode,
  });

  /// GET the logo asset codes list for a school's classrooms.
  Future<Map<String, dynamic>?> getClassroomLogoAssetCodes({
    required String classroomCode,
    required String schoolCode,
  });

  /// POST to create a classroom-logo upload session.
  Future<Map<String, dynamic>?> createClassroomLogoUploadSession({
    required String classroomCode,
    required String organizationCode,
    required String schoolCode,
  });

  /// POST to finalize a classroom logo with the uploaded [assetCode].
  Future<Map<String, dynamic>?> finalizeClassroomLogo({
    required String classroomCode,
    required String assetCode,
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
      'sortByName': 'asc',
    };
    final overrideType = (typeOverride ?? '').trim();
    if (overrideType.isNotEmpty) {
      qp['type'] = overrideType;
    } else if (onlyTypeClassroom) {
      qp['type'] = 'CLASSROOM';
    }
    final query = qp.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
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
    DateTime? date,
  }) async {
    if (classroomCodes.isEmpty) return <String, dynamic>{};

    final endpoint = ApiPaths.url(
      ApiPaths.studentAttendanceExpectedSummaryCardByClassrooms,
    );
    final qp = <String, dynamic>{
      'classroomCodes': classroomCodes.join(','),
    };
    if (date != null) {
      qp['date'] =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: qp,
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
    DateTime? date,
  }) async {
    if (classroomCodes.isEmpty) return <String, dynamic>{};

    final endpoint = ApiPaths.url(
      ApiPaths.staffAttendanceExpectedSummaryCardByClassrooms,
    );
    final qp = <String, dynamic>{
      'classroomCodes': classroomCodes.join(','),
    };
    if (date != null) {
      qp['date'] =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: qp,
      // Backend aggregates attendance for every requested classroom in one
      // pass; schools with many classrooms can exceed the default 30s.
      options: Options(receiveTimeout: const Duration(seconds: 60)),
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

  @override
  Future<Map<String, dynamic>?> getStudentClassroomEnrolledCount({
    required String classroomCode,
  }) async {
    final endpoint = ApiPaths.url(
      '/api/v1/student-classroom/enrolled-count/$classroomCode',
    );
    final response = await _client.get<dynamic>(endpoint);
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<Map<String, dynamic>?> getClassroomLogoAssetCodes({
    required String classroomCode,
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.classroomLogoAssetCodes);
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'classroomCode': classroomCode,
        'schoolCode': schoolCode,
      },
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<Map<String, dynamic>?> createClassroomLogoUploadSession({
    required String classroomCode,
    required String organizationCode,
    required String schoolCode,
  }) async {
    final endpoint =
        ApiPaths.url(ApiPaths.classroomLogoUploadSessionPath(classroomCode));
    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
      },
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<Map<String, dynamic>?> finalizeClassroomLogo({
    required String classroomCode,
    required String assetCode,
  }) async {
    final endpoint =
        ApiPaths.url(ApiPaths.classroomLogoFinalizePath(classroomCode));
    final response = await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{'assetCode': assetCode},
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }
}