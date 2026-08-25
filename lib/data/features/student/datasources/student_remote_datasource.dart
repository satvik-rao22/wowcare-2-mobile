import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/domain/features/student/entities/student_settings.dart';
import '../models/student_models.dart';
import '../models/student_document_models.dart';
import '../models/student_pickup_models.dart';
import '../models/student_physician_models.dart';
import '../models/vaccine_model.dart';
import '../../../../core/util/logger_service.dart';

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
    List<String>? attendanceStatuses,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? allowedClassroomCodes,
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
  Future<String> deleteStudentDocument({required String code});

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

  Future<String> deleteStudent(String code);

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
    String? relationshipDescription,
    required String pickupType,
    String? carpoolId,
  });

  Future<String> updatePickup({
    required String code,
    required Map<String, dynamic> body,
  });

  Future<String> deletePickup({required String code});

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

  /// [classroom] must be the backend classroom **code** (e.g. `CLS_...`), not the display name.
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

  /// Updates the student's siblings via `PUT /api/v1/student/student/{studentCode}/siblings`.
  Future<String> updateStudentSiblings({
    required String studentCode,
    required List<String> siblingCodes,
  });

  /// Links siblings onto a newly created student via
  /// `POST /api/v1/student/{newStudentCode}/add-sibling`.
  ///
  /// Used by the add-student dialog flow; edit-profile keeps using
  /// [updateStudentSiblings].
  Future<String> addStudentSibling({
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

  /// `POST /api/v1/student-tags/activity-filter`
  Future<List<String>> postStudentTagsActivityFilter({
    required String schoolCode,
    required String classroomCode,
    required List<String> tagCodes,
  });

  /// Creates / links a guardian user to a student via `/api/v1/guardian-user`.
  ///
  /// Returns the backend `message` plus the newly created `guardianCode`
  /// (parsed from the response `data`, null if the backend didn't include it) —
  /// the caller needs the code to upload the guardian's profile photo.
  Future<({String message, String? guardianCode})> createGuardianUser({
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

  /// Logged-in guardian profile via `GET /api/v1/guardian/profile`.
  ///
  /// Query params: schoolCode, userCode. Returns the API `data` map (`code`,
  /// `firstName`, `userCode`, etc.).
  Future<Map<String, dynamic>> getGuardianProfile({
    required String schoolCode,
    required String userCode,
  });

  /// School-level student settings via `GET /api/v1/student-settings`.
  Future<StudentSettings> getStudentSettings({required String schoolCode});

  /// Immunization settings (available vaccines) via
  /// `GET /api/v1/student/settings/immunization?schoolCode={schoolCode}`.
  Future<List<VaccineModel>> getImmunizationSettings({
    required String schoolCode,
  });

  /// Fetches children linked to a guardian via
  /// `GET /api/v1/guardian/children`.
  ///
  /// Query params: guardianCode, schoolCode, userCode
  /// Returns raw response `data` list.
  Future<List<Map<String, dynamic>>> getGuardianChildren({
    required String guardianCode,
    required String schoolCode,
    required String userCode,
  });

  /// Links an existing guardian to a student via `POST /api/v1/guardian/existing`.
  ///
  /// Query params: guardianCode, studentCode
  /// Returns the backend `message` field.
  Future<String> linkExistingGuardian({
    required String guardianCode,
    required String studentCode,
    String? relation,
    String? relationDescription,
  });

  /// Updates a guardian via `PATCH /api/v1/guardian/{code}`.
  Future<String> updateGuardian({
    required String code,
    required Map<String, dynamic> body,
  });

  /// Updates the logged-in guardian's own profile via
  /// `PATCH /api/v1/guardian/my-profile`. The guardian is identified by the
  /// `code` field inside [body].
  Future<String> updateGuardianMyProfile({required Map<String, dynamic> body});

  /// Deletes a guardian via `DELETE /api/v1/guardian/{code}`.
  Future<String> deleteGuardian({
    required String code,
    required String studentCode,
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

  /// Fetches a student's regular schedules via `GET /api/v1/regular-schedules?studentCode={studentCode}`.
  ///
  /// Returns a list of raw schedule maps each containing:
  /// { "dayOfWeek": "MONDAY", "startTime": {"hour":8,"minute":0}, "endTime": {"hour":17,"minute":0} }
  Future<List<Map<String, dynamic>>> getStudentRegularSchedules({
    required String studentCode,
  });

  /// Updates a student's regular schedules via `PATCH /api/v1/regular-schedules`.
  ///
  /// Expected body shape:
  /// {
  ///   "schoolCode": "string",
  ///   "studentCode": "string",
  ///   "schedule": [
  ///     {
  ///       "dayOfWeek": "MONDAY",
  ///       "startTime": { "hour": 9, "minute": 0, "second": 0, "nano": 0 },
  ///       "halfDay":  { "hour": 13, "minute": 0, "second": 0, "nano": 0 },
  ///       "endTime":  { "hour": 17, "minute": 0, "second": 0, "nano": 0 }
  ///     }
  ///   ]
  /// }
  Future<String> updateStudentRegularSchedules({
    required String schoolCode,
    required String studentCode,
    required List<Map<String, dynamic>> schedule,
  });

  /// Fetches student health record via
  /// `GET /api/v1/student/{code}/health`.
  Future<StudentHealthModel> getStudentHealth({required String code});

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

  /// Partially updates a single immunization dose record via
  /// `PATCH /api/v1/student/{studentCode}/immunization/{recordCode}`.
  Future<StudentImmunizationModel> updateStudentImmunizationRecord({
    required String studentCode,
    required String recordCode,
    required Map<String, dynamic> body,
  });

  /// Fetches all physical-exam records for a student via
  /// `GET /api/v1/student/{studentCode}/physical-exam`.
  Future<List<StudentPhysicalExamModel>> getStudentPhysicalExams({
    required String code,
  });

  /// Creates a new physical exam record for a student via
  /// `POST /api/v1/student/{studentCode}/physical-exam`.
  Future<StudentPhysicalExamModel> addStudentPhysicalExam({
    required String code,
    required Map<String, dynamic> body,
  });

  /// Partially updates an existing physical exam record via
  /// `PATCH /api/v1/student/{studentCode}/physical-exam/{examCode}`.
  Future<StudentPhysicalExamModel> updateStudentPhysicalExam({
    required String studentCode,
    required String examCode,
    required Map<String, dynamic> body,
  });

  /// Updates student important dates via
  /// `PATCH /api/v1/student/{code}/important-dates`.
  Future<String> updateStudentImportantDates({
    required String code,
    required StudentImportantDatesModel dates,
  });

  /// Fetches student counts (active, upcoming, enrolled) for a school via
  /// `GET /api/v1/student/count`.
  Future<Map<String, int>> getStudentCounts({required String schoolCode});

  /// `GET /api/v1/student/student-documents/expiry-count`
  Future<
    ({
      int expiredDocumentCount,
      int expiringWithinWeekCount,
      int totalDocumentsWithExpiry,
    })
  >
  getStudentDocumentExpiryCount({required String schoolCode});

  /// `GET /api/v1/student/student/physical-checkup-count/{schoolCode}`
  Future<({int overdueExamCount, int studentsWithoutActiveExamCount})>
  getStudentPhysicalCheckupCount({required String schoolCode});
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
    List<String>? attendanceStatuses,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? allowedClassroomCodes,
  }) async {
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'page': page,
      'size': size,
      'sort': 'firstName,asc',
    };

    // Hard security scope for a restricted staff/teacher persona — sent as
    // its own param (distinct from classroomCodes, the optional user-chosen
    // filter) so the backend enforces it regardless of what's selected.
    // Mirrors the attendance module's proven allowedClassroomCodes contract.
    final allowedCodes = allowedClassroomCodes
        ?.where((c) => c.trim().isNotEmpty)
        .toList();
    if (allowedCodes != null && allowedCodes.isNotEmpty) {
      queryParameters['allowedClassroomCodes'] = allowedCodes;
    }

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
    // API expects underscored codes, e.g. attendanceStatus=SIGNED_IN&attendanceStatus=ABSENT.
    final normalizedAttendanceStatuses = attendanceStatuses
        ?.map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
    if (normalizedAttendanceStatuses != null &&
        normalizedAttendanceStatuses.isNotEmpty) {
      queryParameters['attendanceStatus'] = normalizedAttendanceStatuses;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentList,
      ApiConstants.studentBaseUrl,
    );

    // Spring expects repeated query keys for collections, e.g.
    // tagCodes=T1&tagCodes=T2 — not bracket or CSV serialization.
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: Options(listFormat: ListFormat.multi),
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
  Future<String> deleteStudentDocument({required String code}) async {
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

    return StudentProfileModel.fromJson(response.data! as Map<String, dynamic>);
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

    final response = await _client.post<dynamic>(endpoint, data: body);

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

    final response = await _client.put<dynamic>(endpoint, data: body);

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
  Future<String> deleteStudent(String code) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentDelete(code),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.delete<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student delete API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Student deleted successfully';
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
    String? relationshipDescription,
    required String pickupType,
    String? carpoolId,
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
      if (relationshipDescription != null &&
          relationshipDescription.trim().isNotEmpty)
        'relationshipDescription': relationshipDescription.trim(),
      'pickupType': pickupType,
      if (carpoolId != null && carpoolId.trim().isNotEmpty)
        'carpoolId': carpoolId.trim(),
    };

    final response = await _client.post<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected pickup create API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    return root['message']?.toString() ?? 'Pickup added successfully';
  }

  @override
  Future<String> updatePickup({
    required String code,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.pickup}/$code',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected pickup update API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    return root['message']?.toString() ?? 'Pickup updated successfully';
  }

  @override
  Future<String> deletePickup({required String code}) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.pickup}/$code',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.delete<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected pickup delete API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    return root['message']?.toString() ?? 'Pickup deleted successfully';
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

    final response = await _client.post<dynamic>(endpoint, data: body);

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

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student profile update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ??
        'Student profile updated successfully';
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

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student address update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ??
        'Student address updated successfully';
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
      data: <String, dynamic>{'siblingCodes': siblingCodes},
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student siblings update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ??
        'Student siblings updated successfully';
  }

  @override
  Future<String> addStudentSibling({
    required String studentCode,
    required List<String> siblingCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAddSibling(studentCode),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{'siblingCodes': siblingCodes},
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected add-sibling API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Sibling added successfully';
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

  static List<String> _studentCodesFromActivityFilterBody(
    Map<String, dynamic> body,
  ) {
    Map<String, dynamic> payload = body;
    final nested = body['data'];
    if (nested is Map<String, dynamic>) {
      payload = nested;
    }
    final raw = payload['studentCodes'];
    if (raw is! List) return const <String>[];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<List<String>> postStudentTagsActivityFilter({
    required String schoolCode,
    required String classroomCode,
    required List<String> tagCodes,
  }) async {
    final normTags = tagCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (normTags.isEmpty) return const <String>[];

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentTagsActivityFilter,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'schoolCode': schoolCode.trim(),
        'classroomCode': classroomCode.trim(),
        'tagCodes': normTags,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected activity-filter API response format');
    }
    final body = response.data! as Map<String, dynamic>;
    if (body['success'] == false) {
      final message = (body['message'] ?? '').toString().trim();
      throw Exception(
        message.isNotEmpty ? message : 'Activity tag filter failed',
      );
    }
    return _studentCodesFromActivityFilterBody(body);
  }

  /// Fetches tags for a specific student via `GET /api/v1/student-tags/{studentCode}`.
  ///
  /// Returns the raw `data` list from the backend response, each item being
  /// a map with keys like `code`, `name`, `defaultTag`.
  @override
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

    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<({String message, String? guardianCode})> createGuardianUser({
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
      ApiConstants.baseUrl,
    );

    final body = <String, dynamic>{
      'schoolCode': schoolCode,
      'studentCode': studentCode,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'relationToStudent': relationToStudent,
      'primaryContact': primaryContact,
      'legalCustody': legalCustody,
    };
    if (profilePhotoUrl != null && profilePhotoUrl.trim().isNotEmpty) {
      body['profilePhotoUrl'] = profilePhotoUrl.trim();
    }
    if (userCode != null && userCode.trim().isNotEmpty) {
      body['userCode'] = userCode.trim();
    }
    if (organizationCode != null && organizationCode.trim().isNotEmpty) {
      body['organizationCode'] = organizationCode.trim();
    }

    final response = await _client.post<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian-user API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    final message =
        data['message']?.toString() ?? 'Guardian user created successfully';

    // The created guardian's code can arrive either at the top level or nested
    // under `data` — check both, and accept a few common field names.
    String? extractCode(dynamic node) {
      if (node is! Map) return null;
      for (final key in const ['guardianCode', 'code', 'guardianId']) {
        final v = (node[key] ?? '').toString().trim();
        if (v.isNotEmpty) return v;
      }
      return null;
    }

    final guardianCode = extractCode(data['data']) ?? extractCode(data);
    return (message: message, guardianCode: guardianCode);
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

    return list.whereType<Map<String, dynamic>>().toList(growable: false);
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
      queryParameters: <String, dynamic>{'schoolCode': schoolCode},
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian list API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! List) {
      return const <Map<String, dynamic>>[];
    }

    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> getGuardianProfile({
    required String schoolCode,
    required String userCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.guardianProfile,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
        'userCode': userCode,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian profile API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  @override
  Future<StudentSettings> getStudentSettings({
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentSettings,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'schoolCode': schoolCode},
    );

    final root = response.data;
    final data = root is Map<String, dynamic> ? root['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected student settings API response format');
    }
    bool asBool(dynamic v) => v == true;
    return StudentSettings(
      code: (data['code'] ?? '').toString(),
      schoolCode: (data['schoolCode'] ?? '').toString(),
      organizationCode: (data['organizationCode'] ?? '').toString(),
      canParentEditChildHealthRecords: asBool(
        data['canParentEditChildHealthRecords'],
      ),
      canStaffEditTheirOwnHealthRecords: asBool(
        data['canStaffEditTheirOwnHealthRecords'],
      ),
    );
  }

  @override
  Future<List<VaccineModel>> getImmunizationSettings({
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentImmunizationSettings,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'schoolCode': schoolCode},
    );

    AppLogger.d(
      '[IMMUNIZATION_API] Raw immunization API response: ${response.data}',
    );

    final root = response.data;
    List<dynamic> list = const [];
    if (root is List) {
      list = root;
    } else if (root is Map<String, dynamic>) {
      final data = root['data'];
      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        final inner =
            data['items'] ??
            data['vaccines'] ??
            data['immunizations'] ??
            data['list'] ??
            data['settings'];
        if (inner is List) {
          list = inner;
        }
      } else if (root['items'] is List) {
        list = root['items'] as List;
      } else if (root['vaccines'] is List) {
        list = root['vaccines'] as List;
      } else if (root['immunizations'] is List) {
        list = root['immunizations'] as List;
      }
    }

    final vaccines = <VaccineModel>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        final model = VaccineModel.fromJson(item);
        if (model.name.isNotEmpty || model.code.isNotEmpty) {
          vaccines.add(model);
        }
      }
    }

    AppLogger.d('[IMMUNIZATION_API] Parsed vaccine models: $vaccines');
    return vaccines;
  }

  @override
  Future<List<Map<String, dynamic>>> getGuardianChildren({
    required String guardianCode,
    required String schoolCode,
    required String userCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.guardianChildren,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'guardianCode': guardianCode,
        'schoolCode': schoolCode,
        'userCode': userCode,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian children API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! List) {
      return const <Map<String, dynamic>>[];
    }

    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<String> linkExistingGuardian({
    required String guardianCode,
    required String studentCode,
    String? relation,
    String? relationDescription,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.guardianExisting,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'guardianCode': guardianCode,
        'studentCode': studentCode,
        if (relation != null && relation.trim().isNotEmpty)
          'relation': relation.trim().toUpperCase(),
        if (relationDescription != null &&
            relationDescription.trim().isNotEmpty)
          'relationDescription': relationDescription.trim(),
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian existing API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Guardian linked successfully';
  }

  @override
  Future<String> updateGuardian({
    required String code,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.guardian}/$code',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Guardian updated successfully';
  }

  @override
  Future<String> updateGuardianMyProfile({
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.guardianMyProfile,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected guardian my-profile update API response format',
      );
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Profile updated successfully';
  }

  @override
  Future<String> deleteGuardian({
    required String code,
    required String studentCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.guardian}/$code',
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.delete<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'studentCode': studentCode},
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected guardian delete API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Guardian deleted successfully';
  }

  @override
  Future<List<Map<String, dynamic>>> getTagsBySchool({
    required String schoolCode,
  }) async {
    // Page through the FULL tag list. This was previously capped at a single
    // page (page 0, size 100), so a school with more than 100 tags silently
    // lost every tag past the first 100 in the filter — hence "all tags not
    // showing". Loop until the server reports the last page.
    const pageSize = 200;
    final all = <Map<String, dynamic>>[];
    var page = 0;
    while (true) {
      // Full [Uri] so Dio does not merge with [BaseOptions.baseUrl]
      // (which would incorrectly yield …/api/v1/user/tags on the user host).
      final uri = Uri.parse(ApiPaths.url(ApiPaths.tags)).replace(
        queryParameters: <String, String>{
          'schoolCode': schoolCode,
          'page': '$page',
          'size': '$pageSize',
        },
      );

      final response = await _client.getUri<dynamic>(uri);

      if (response.data is! Map<String, dynamic>) {
        throw Exception('Unexpected tags API response format');
      }

      final root = response.data! as Map<String, dynamic>;
      final data = root['data'];
      if (data is! Map<String, dynamic>) break;

      final content = data['content'];
      if (content is! List) break;

      final pageItems = content.whereType<Map<String, dynamic>>().toList();
      all.addAll(pageItems);

      // Stop at the last page. Prefer the server's paging flags; fall back to
      // "a short page means no more".
      final last = data['last'];
      final totalPages = data['totalPages'];
      final isLast =
          (last is bool && last) ||
          (totalPages is int && page >= totalPages - 1) ||
          pageItems.length < pageSize;
      if (isLast) break;

      page++;
      if (page > 50) break; // safety cap (>10k tags) — never loop unbounded
    }

    return all.toList(growable: false);
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
  Future<List<Map<String, dynamic>>> getStudentRegularSchedules({
    required String studentCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentRegularSchedules,
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'studentCode': studentCode},
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student regular schedules GET response format',
      );
    }

    final root = response.data! as Map<String, dynamic>;
    final dataList = root['data'] as List<dynamic>? ?? [];
    return dataList.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<String> updateStudentRegularSchedules({
    required String schoolCode,
    required String studentCode,
    required List<Map<String, dynamic>> schedule,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentRegularSchedules,
      ApiConstants.studentBaseUrl,
    );

    final body = <String, dynamic>{
      'schoolCode': schoolCode,
      'studentCode': studentCode,
      'schedule': schedule,
    };

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student regular schedules API response format',
      );
    }

    final root = response.data! as Map<String, dynamic>;
    return root['message']?.toString() ??
        'Student schedule updated successfully';
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
      throw Exception(
        'Unexpected student important dates update API response format',
      );
    }

    final root = response.data! as Map<String, dynamic>;
    return root['message']?.toString() ??
        'Important dates updated successfully';
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
      queryParameters: <String, dynamic>{'schoolCode': schoolCode},
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
  Future<StudentHealthModel> getStudentHealth({required String code}) async {
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

    final response = await _client.put<dynamic>(endpoint, data: body);

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

  @override
  Future<StudentImmunizationModel> updateStudentImmunizationRecord({
    required String studentCode,
    required String recordCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentImmunizationRecord(studentCode, recordCode),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected update immunization API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data payload for update immunization');
    }

    return StudentImmunizationModel.fromJson(data);
  }

  @override
  Future<List<StudentPhysicalExamModel>> getStudentPhysicalExams({
    required String code,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentPhysicalExams(code),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student physical exam API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! List) {
      return const <StudentPhysicalExamModel>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(StudentPhysicalExamModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<StudentPhysicalExamModel> addStudentPhysicalExam({
    required String code,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentPhysicalExams(code),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.post<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected add physical exam API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data payload for add physical exam');
    }

    return StudentPhysicalExamModel.fromJson(data);
  }

  @override
  Future<StudentPhysicalExamModel> updateStudentPhysicalExam({
    required String studentCode,
    required String examCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentPhysicalExam(studentCode, examCode),
      ApiConstants.studentBaseUrl,
    );

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected update physical exam API response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Missing data payload for update physical exam');
    }

    return StudentPhysicalExamModel.fromJson(data);
  }

  @override
  Future<
    ({
      int expiredDocumentCount,
      int expiringWithinWeekCount,
      int totalDocumentsWithExpiry,
    })
  >
  getStudentDocumentExpiryCount({required String schoolCode}) async {
    final endpoint = ApiPaths.url(ApiPaths.studentDocumentExpiryCount);
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'schoolCode': schoolCode},
    );
    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student document expiry count response format',
      );
    }
    final root = response.data! as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>? ?? {};
    return (
      expiredDocumentCount:
          (data['expiredDocumentCount'] as num?)?.toInt() ?? 0,
      expiringWithinWeekCount:
          (data['expiringWithinWeekCount'] as num?)?.toInt() ?? 0,
      totalDocumentsWithExpiry:
          (data['totalDocumentsWithExpiry'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<({int overdueExamCount, int studentsWithoutActiveExamCount})>
  getStudentPhysicalCheckupCount({required String schoolCode}) async {
    final endpoint = ApiPaths.url(
      ApiPaths.studentPhysicalCheckupCount(schoolCode),
    );
    final response = await _client.get<dynamic>(endpoint);
    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student physical checkup count response format',
      );
    }
    final root = response.data! as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>? ?? {};
    return (
      overdueExamCount: (data['overdueExamCount'] as num?)?.toInt() ?? 0,
      studentsWithoutActiveExamCount:
          (data['studentsWithoutActiveExamCount'] as num?)?.toInt() ?? 0,
    );
  }
}
