import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import '../models/student_models.dart';
import '../models/student_document_models.dart';
import '../models/student_pickup_models.dart';

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

  Future<StudentProfileModel> getStudentProfile(String code);

  /// Adds a student document via POST /api/v1/student-documents.
  Future<StudentDocumentResponseModel> addStudentDocument({
    required StudentDocumentRequestModel request,
  });

  /// Updates a student document via PATCH /api/v1/student-documents/{code}.
  Future<StudentDocumentResponseModel> updateStudentDocument({
    required String code,
    required StudentDocumentRequestModel request,
  });

  /// Deletes a student document via DELETE /api/v1/student-documents/{code}.
  Future<String> deleteStudentDocument({
    required String code,
  });

  /// Fetches paginated student documents via GET /api/v1/student-documents.
  /// [ownerId] = student code (required).
  /// [expiredOnly] when true returns only expired documents.
  Future<StudentDocumentsPageModel> getStudentDocuments({
    required String ownerId,
    int page = 0,
    int size = 10,
    bool? expiredOnly,
  });

  Future<String> deactivateStudent(String code);

  Future<String> reactivateStudent(String code);

  Future<List<StudentPickupModel>> getStudentPickups({
    required String studentCode,
  });

  /// Creates a new authorized pickup for a student via `/api/v1/pickup`.
  ///
  /// Returns the backend `message` field.
  Future<String> addPickup({
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
  });

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

  /// Updates student profile via `/api/v1/student/{code}/profile`.
  ///
  /// The [body] should follow the backend contract, e.g.
  /// {
  ///   "firstName": "string",
  ///   "lastName": "string",
  ///   "status": "ACTIVE",
  ///   "classroom": "string",
  ///   "tags": ["string"],
  ///   "dob": "2026-02-17",
  ///   "notes": "string",
  ///   "subsidy": true,
  ///   "legalCustodians": ["string"],
  ///   "siblings": ["string"],
  ///   "fte": 0,
  ///   "upcomingMoves": "2026-02-17",
  ///   "line1": "string",
  ///   "city": "string",
  ///   "state": "string",
  ///   "country": "string",
  ///   "postalCode": "string",
  ///   ...
  /// }
  Future<String> updateStudentProfile({
    required String code,
    required Map<String, dynamic> body,
  });

  /// Creates / links a guardian user to a student via `/api/v1/guardian-user`.
  ///
  /// Returns the backend `message` field.
  Future<String> createGuardianUser({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String relationToStudent,
    required bool primaryContact,
    required bool legalCustody,
    String? profilePhotoUrl,
    String? userCode,
    String? organizationCode,
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
  Future<StudentDocumentResponseModel> addStudentDocument({
    required StudentDocumentRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentDocuments,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student document API response format');
    }

    return StudentDocumentResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StudentDocumentsPageModel> getStudentDocuments({
    required String ownerId,
    int page = 0,
    int size = 10,
    bool? expiredOnly,
  }) async {
    final queryParameters = <String, dynamic>{
      'ownerId': ownerId,
      'page': page,
      'size': size,
    };

    if (expiredOnly != null) {
      queryParameters['expiredOnly'] = expiredOnly;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentDocuments,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student documents API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    final dataPayload = data['data'] as Map<String, dynamic>?;
    if (dataPayload == null) {
      throw Exception('Missing data field in student documents response');
    }

    return StudentDocumentsPageModel.fromJson(dataPayload);
  }

  @override
  Future<StudentDocumentResponseModel> updateStudentDocument({
    required String code,
    required StudentDocumentRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.studentDocuments}/$code',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student document update API response format');
    }

    return StudentDocumentResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<String> deleteStudentDocument({
    required String code,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.studentDocuments}/$code',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.delete<dynamic>(endpoint);

    if (response.data == null) {
      return 'Document deleted successfully';
    }

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student document delete API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Document deleted successfully';
  }

  @override
  Future<StudentProfileModel> getStudentProfile(String code) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentProfile(code),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student profile API response format');
    }

    return StudentProfileModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<String> deactivateStudent(String code) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentDeactivate(code),
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
      ApiPaths.studentReactivate(code),
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
  Future<List<StudentPickupModel>> getStudentPickups({
    required String studentCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.pickup,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'studentCode': studentCode},
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected pickup API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! List) {
      return const <StudentPickupModel>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(StudentPickupModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<String> addPickup({
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.pickup,
      ApiConstants.studentBaseUrl,
    );

    final body = <String, dynamic>{
      'studentCode': studentCode,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'relation': relation,
    };

    final response = await _client.post<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected pickup create API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    return root['message']?.toString() ?? 'Pickup added successfully';
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

  @override
  Future<String> updateStudentProfile({
    required String code,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentProfileUpdate(code),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student profile update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Student profile updated successfully';
  }

  @override
  Future<String> createGuardianUser({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String relationToStudent,
    required bool primaryContact,
    required bool legalCustody,
    String? profilePhotoUrl,
    String? userCode,
    String? organizationCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.guardianUser,
      ApiConstants.studentBaseUrl,
    );

    final body = <String, dynamic>{
      'code': '', // let backend generate
      'schoolCode': schoolCode,
      'studentCode': studentCode,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'relationToStudent': relationToStudent,
      'primaryContact': primaryContact,
      'legalCustody': legalCustody,
      'profilePhotoUrl': profilePhotoUrl ?? '',
      'userCode': userCode ?? '',
      'organizationCode': organizationCode ?? '',
    };

    final response = await _client.post<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian-user API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Guardian user created successfully';
  }
}

