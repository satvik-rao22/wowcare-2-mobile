import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import '../models/student_models.dart';
import '../models/student_document_models.dart';
import '../models/student_pickup_models.dart';
import '../models/student_physician_models.dart';

abstract class StudentRemoteDataSource {
  Future<StudentPageModel> getStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
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

  /// Fetches physicians associated with a student via `/api/v1/physicians`.
  ///
  /// Uses pageable-style query params as per backend swagger.
  Future<List<StudentPhysicianModel>> getPhysicians({
    required String studentCode,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? address,
    String? search,
    int page = 0,
    int size = 20,
  });

  /// Creates a physician and links to a student via
  /// `POST /api/v1/physicians/{schoolCode}/add/{studentCode}`.
  Future<StudentPhysicianModel> addPhysician({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  });

  /// Updates a physician via `PUT /api/v1/physicians/{code}`.
  Future<StudentPhysicianModel> updatePhysician({
    required String code,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  });

  /// Deletes a physician via `DELETE /api/v1/physicians/{code}`.
  Future<String> deletePhysician(String code);

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

  /// Updates the student's address via `PATCH /api/v1/student/{studentCode}/address`.
  Future<String> updateStudentAddress({
    required String studentCode,
    required Map<String, dynamic> body,
  });

  /// Updates the student's siblings via `PUT /api/v1/student/{studentCode}/siblings`.
  Future<String> updateStudentSiblings({
    required String studentCode,
    required List<String> siblingCodes,
  });

  /// Updates the student's tags via `POST /api/v1/student-tags`.
  ///
  /// Query params: studentCode, schoolCode
  /// Body: [ { "tagCode": "TAG_..." }, ... ]
  Future<String> updateStudentTags({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
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

  /// Fetches guardians/parents for a student via `GET /api/v1/guardian/{studentCode}`.
  Future<List<Map<String, dynamic>>> getStudentGuardians({
    required String studentCode,
  });

  /// Fetches all guardians/parents for a school via `GET /api/v1/guardian`.
  ///
  /// Returns the raw `data` list from the backend response, each item being a
  /// map with keys like `code`, `firstName`, `lastName`, `email`.
  Future<List<Map<String, dynamic>>> getGuardiansBySchool({
    required String schoolCode,
  });

  /// Fetches tags for a school via `GET /api/v1/tags`.
  ///
  /// Returns the `content` list from the paginated `data` payload, each item
  /// being a map with keys like `code`, `name`, `status`, etc.
  Future<List<Map<String, dynamic>>> getTagsBySchool({
    required String schoolCode,
  });

  /// Fetches tags for a specific student via `GET /api/v1/student-tags/{studentCode}`.
  ///
  /// Returns the raw `data` list from the backend response, each item being
  /// a map with keys like `code`, `name`, `defaultTag`.
  Future<List<Map<String, dynamic>>> getStudentTags({
    required String studentCode,
  });

  /// Fetches student important dates via
  /// `GET /api/v1/student/{code}/important-dates`.
  Future<StudentImportantDatesModel> getStudentImportantDates({
    required String code,
  });

  /// Fetches student health record via
  /// `GET /api/v1/student/{code}/health`.
  Future<StudentHealthModel> getStudentHealth({
    required String code,
  });

  /// Creates or updates student health record via
  /// `PUT /api/v1/student/{code}/health`.
  Future<StudentHealthModel> updateStudentHealth({
    required String code,
    required Map<String, dynamic> body,
  });

  /// Fetches all immunization records for a student via
  /// `GET /api/v1/student/{code}/immunization`.
  Future<List<StudentImmunizationModel>> getStudentImmunizations({
    required String code,
  });

  /// Updates student important dates via
  /// `PATCH /api/v1/student/{code}/important-dates`.
  Future<String> updateStudentImportantDates({
    required String code,
    required StudentImportantDatesModel dates,
  });

  /// Fetches student counts (active, upcoming, enrolled) for a school via
  /// `GET /api/v1/student/count`.
  Future<Map<String, int>> getStudentCounts({
    required String schoolCode,
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
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
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
    if (classroomCodes != null && classroomCodes.isNotEmpty) {
      queryParameters['classroomCodes'] = classroomCodes;
    }
    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }
    if (guardianCodes != null && guardianCodes.isNotEmpty) {
      queryParameters['guardianCodes'] = guardianCodes;
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
  Future<List<StudentPhysicianModel>> getPhysicians({
    required String studentCode,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? address,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      'studentCode': studentCode,
      'pageable.page': page,
      'pageable.size': size,
      'pageable.sort': <String>['lastName,asc'],
    };

    if (firstName != null && firstName.isNotEmpty) {
      queryParameters['firstName'] = firstName;
    }
    if (lastName != null && lastName.isNotEmpty) {
      queryParameters['lastName'] = lastName;
    }
    if (email != null && email.isNotEmpty) {
      queryParameters['email'] = email;
    }
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      queryParameters['phoneNumber'] = phoneNumber;
    }
    if (address != null && address.isNotEmpty) {
      queryParameters['address'] = address;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.physicians,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected physicians API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final content = root['content'];
    if (content is! List) {
      return const <StudentPhysicianModel>[];
    }

    return content
        .whereType<Map<String, dynamic>>()
        .map(StudentPhysicianModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<StudentPhysicianModel> addPhysician({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.physicians}/$schoolCode/add/$studentCode',
      ApiConstants.studentBaseUrl,
    );

    final body = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'specialty': specialty ?? '',
      'notes': notes ?? '',
    };

    final response = await _client.post<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected add physician API response format');
    }

    return StudentPhysicianModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StudentPhysicianModel> updatePhysician({
    required String code,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.physicians}/$code',
      ApiConstants.studentBaseUrl,
    );

    final body = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'specialty': specialty ?? '',
      'notes': notes ?? '',
    };

    final response = await _client.put<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected update physician API response format');
    }

    return StudentPhysicianModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<String> deletePhysician(String code) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.physicians}/$code',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.delete<dynamic>(endpoint);

    if (response.data == null) {
      return 'Physician deleted successfully';
    }

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected delete physician API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Physician deleted successfully';
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
  Future<String> updateStudentAddress({
    required String studentCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAddress(studentCode),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student address update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Student address updated successfully';
  }

  @override
  Future<String> updateStudentSiblings({
    required String studentCode,
    required List<String> siblingCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentSiblings(studentCode),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.put<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'siblingCodes': siblingCodes,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student siblings update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Student siblings updated successfully';
  }

  @override
  Future<String> updateStudentTags({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentTags,
      ApiConstants.studentBaseUrl,
    );

    final body = tagCodes
        .map((code) => <String, dynamic>{'tagCode': code})
        .toList(growable: false);

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'studentCode': studentCode,
        'schoolCode': schoolCode,
      },
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student tags update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Student tags updated successfully';
  }

  /// Fetches tags for a specific student via `GET /api/v1/student-tags/{studentCode}`.
  ///
  /// Returns the raw `data` list from the backend response, each item being
  /// a map with keys like `code`, `name`, `defaultTag`.
  Future<List<Map<String, dynamic>>> getStudentTags({
    required String studentCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.studentTags}/$studentCode',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student tags API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! List) {
      return const <Map<String, dynamic>>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
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

  @override
  Future<List<Map<String, dynamic>>> getStudentGuardians({
    required String studentCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.guardian}/$studentCode',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    // Backend returns: { "success": true, "message": "...", "data": [ {...}, ... ] }
    final raw = response.data;

    List<dynamic>? list;
    if (raw is List) {
      list = raw;
    } else if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) {
        list = data;
      }
    }

    if (list == null) {
      return const <Map<String, dynamic>>[];
    }

    return list
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> getGuardiansBySchool({
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.guardian,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian list API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! List) {
      return const <Map<String, dynamic>>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> getTagsBySchool({
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.tags,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
        // Load first page with a reasonable size; tags list is usually small.
        'pageable.page': 0,
        'pageable.size': 100,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected tags API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      return const <Map<String, dynamic>>[];
    }

    final content = data['content'];
    if (content is! List) {
      return const <Map<String, dynamic>>[];
    }

    return content
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  Future<StudentImportantDatesModel> getStudentImportantDates({
    required String code,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentImportantDates(code),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student important dates API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>?;

    // Backend returns `"data": null` when no important dates are set.
    // Treat this as an empty important-dates model instead of throwing.
    return StudentImportantDatesModel.fromJson(data);
  }

  @override
  Future<String> updateStudentImportantDates({
    required String code,
    required StudentImportantDatesModel dates,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentImportantDates(code),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: dates.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student important dates update API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    return root['message']?.toString() ?? 'Important dates updated successfully';
  }

  @override
  Future<Map<String, int>> getStudentCounts({
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.studentList}/count',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student count API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final active = root['activeCount'] as int? ?? 0;
    final upcoming = root['upcomingCount'] as int? ?? 0;
    final enrolled = root['enrolledCount'] as int? ?? 0;

    return <String, int>{
      'activeCount': active,
      'upcomingCount': upcoming,
      'enrolledCount': enrolled,
    };
  }

  @override
  Future<StudentHealthModel> getStudentHealth({
    required String code,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentHealth(code),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student health API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>?;

    return StudentHealthModel.fromJson(data);
  }

  @override
  Future<StudentHealthModel> updateStudentHealth({
    required String code,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentHealth(code),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.put<dynamic>(
      endpoint,
      data: body,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student health update API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>?;
    return StudentHealthModel.fromJson(data);
  }

  @override
  Future<List<StudentImmunizationModel>> getStudentImmunizations({
    required String code,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentImmunization(code),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student immunization API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! List) {
      return const <StudentImmunizationModel>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(StudentImmunizationModel.fromJson)
        .toList(growable: false);
  }
}

