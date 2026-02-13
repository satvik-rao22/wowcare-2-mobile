import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import '../models/student_document_models.dart';
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

  Future<StudentDocumentPageModel> getStudentDocuments({
    required String ownerId,
    required int page,
    required int size,
    required String sort,
    String? name,
    String? type,
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
  Future<StudentDocumentPageModel> getStudentDocuments({
    required String ownerId,
    int page = 0,
    int size = 10,
    String sort = 'name,asc',
    String? name,
    String? type,
    bool? expired,
  }) async {
    final queryParameters = <String, dynamic>{
      'ownerType': 'STUDENT',
      'ownerId': ownerId,
      'page': page,
      'size': size,
      'sort': sort,
    };

    if (name != null) {
      queryParameters['name'] = name;
    }

    if (type != null) {
      queryParameters['type'] = type;
    }

    if (expired != null) {
      queryParameters['expired'] = expired;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentDocuments,
      ApiConstants.studentBaseUrl,
    );

    print('🔵 [REMOTE] Calling Student Documents API');
    print('Endpoint: $endpoint');
    print('Query Params: $queryParameters');

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    print('🔵 [REMOTE] Status Code: ${response.statusCode}');
    print('🔵 [REMOTE] Raw Response: ${response.data}');


    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student documents API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    final dataPayload = data['data'] as Map<String, dynamic>?;

    if (dataPayload == null) {
      throw Exception('Missing data field in student documents response');
    }

    final model = StudentDocumentPageModel.fromJson(dataPayload);

    print('🔵 [REMOTE] Parsed items count: ${model.items.length}');
    print('🔵 [REMOTE] Page: ${model.page}');
    print('🔵 [REMOTE] HasMore: ${model.hasMore}');

    return model;


    //return StudentDocumentPageModel.fromJson(dataPayload);
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
    // Backend expects ISO-style date strings: yyyy-MM-dd
    final dateFormatter = DateFormat('yyyy-MM-dd');

    if (dob != null) {
      body['dob'] = dateFormatter.format(dob);
    }
    if (schoolStartDate != null) {
      body['schoolStartDate'] = dateFormatter.format(schoolStartDate);
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

