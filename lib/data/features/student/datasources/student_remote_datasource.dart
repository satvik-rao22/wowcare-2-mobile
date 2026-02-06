import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import '../models/student_models.dart';

abstract class StudentRemoteDataSource {
  Future<StudentPageModel> getStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    String? search,
    int page = 0,
    int size = 10,
  });

  Future<String> deactivateStudent(String code);

  Future<String> reactivateStudent(String code);

  Future<StudentListItemModel> createStudent({
    required String schoolCode,
    required String firstName,
    required String lastName,
    required String status,
    required String classroom,
    String? profilePhotoUrl,
    DateTime? dob,
    DateTime? schoolStartDate,
  });
}

class StudentRemoteDataSourceImpl implements StudentRemoteDataSource {
  StudentRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<StudentPageModel> getStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      // Backward-compatible pagination params
      'page': page,
      'size': size,
      'sort': 'desc',
      // Newer backend contract (pageable as required)
      'pageable.page': page,
      'pageable.size': size,
      'pageable.sort': <String>['desc'],
    };

    if (code != null && code.isNotEmpty) {
      queryParameters['code'] = code;
    }
    if (firstName != null && firstName.isNotEmpty) {
      queryParameters['firstName'] = firstName;
    }
    if (lastName != null && lastName.isNotEmpty) {
      queryParameters['lastName'] = lastName;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentList,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student API response format');
    }

    return StudentPageModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<String> deactivateStudent(String code) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.studentList}/$code/deactivate',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.post<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student deactivate API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Student deactivated successfully';
  }

  @override
  Future<String> reactivateStudent(String code) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.studentList}/$code/reactivate',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.post<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student reactivate API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Student reactivated successfully';
  }

  @override
  Future<StudentListItemModel> createStudent({
    required String schoolCode,
    required String firstName,
    required String lastName,
    required String status,
    required String classroom,
    String? profilePhotoUrl,
    DateTime? dob,
    DateTime? schoolStartDate,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentList,
      ApiConstants.studentBaseUrl,
    );

    final body = <String, dynamic>{
      'schoolCode': schoolCode,
      'firstName': firstName,
      'lastName': lastName,
      'status': status,
      'classroom': classroom,
    };

    if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
      body['profilePhotoUrl'] = profilePhotoUrl;
    }
    if (dob != null) {
      // Backend expects yyyy-MM-dd
      body['dob'] = '${dob.year.toString().padLeft(4, '0')}-'
          '${dob.month.toString().padLeft(2, '0')}-'
          '${dob.day.toString().padLeft(2, '0')}';
    }
    if (schoolStartDate != null) {
      body['schoolStartDate'] =
          '${schoolStartDate.year.toString().padLeft(4, '0')}-'
          '${schoolStartDate.month.toString().padLeft(2, '0')}-'
          '${schoolStartDate.day.toString().padLeft(2, '0')}';
    }

    final response = await _client.post<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected create student API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>? ?? const {};

    // Map schoolStartDate from API into movementDate used by list model.
    final mapped = Map<String, dynamic>.from(data);
    if (data.containsKey('schoolStartDate')) {
      mapped['movementDate'] = data['schoolStartDate'];
    }

    return StudentListItemModel.fromJson(mapped);
  }
}

