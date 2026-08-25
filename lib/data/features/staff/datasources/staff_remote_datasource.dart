import 'package:wowcare/core/util/logger_service.dart';
import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/core/util/api_paths.dart';
import '../models/staff_models.dart';
import '../models/staff_count_models.dart';
import '../models/staff_document_models.dart';
import '../models/staff_important_dates_models.dart';
import '../models/school_user_models.dart';
import '../models/school_regular_schedule_models.dart';

abstract class StaffRemoteDataSource {
  Future<StaffCountModel> getStaffCount({
    required String organizationCode,
    required String schoolCode,
  });

  Future<StaffPageModel> getStaffPage({
    required String organizationCode,
    required String schoolCode,
    String? code,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
    List<String>? attendanceStatuses,
  });

  /// Fetches the entire staff list in one call — no pagination loop — with
  /// support for multiple `status` values (sent as repeated query keys, e.g.
  /// `status=ACTIVE&status=UPCOMING`). [size] caps how many records to
  /// return in the single page (defaults to 200, enough for any school).
  Future<List<StaffListItemModel>> getAllStaff({
    required String organizationCode,
    required String schoolCode,
    List<String>? statuses,
    int size = 200,
  });

  Future<StaffDocumentResponseModel> addStaffDocument({
    required String staffCode,
    required StaffDocumentRequestModel request,
  });

  Future<StaffDocumentResponseModel> updateStaffDocument({
    required String documentUuid,
    required StaffDocumentRequestModel request,
  });

  Future<StaffDocumentResponseModel> deleteStaffDocument({
    required String documentUuid,
  });

  Future<StaffDocumentsPageModel> getStaffDocuments({
    required String staffCode,
    int page = 0,
    int size = 10,
    bool? expired,
  });

  /// Fetches staff profile. Uses `staff/my-profile/{staffCode}` when [forEditStaff] is
  /// false (logged-in user's profile), or `staff/{staffCode}/profile` when true (edit staff).
  Future<StaffProfileModel> getStaffProfile({
    required String staffCode,
    bool forEditStaff = false,
  });

  /// Resolves staffCode for a given userCode + organizationCode + schoolCode via
  /// `GET /api/v1/staff/code`.
  Future<String?> getStaffCodeByUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  });

  /// Updates core staff profile details via `/api/v1/staff/staff/my-profile/{staffCode}`.
  ///
  /// The [body] should follow the backend contract, e.g.
  /// {
  ///   "firstName": "string",
  ///   "lastName": "string",
  ///   "status": "ACTIVE",
  ///   "phoneNumber": "string",
  ///   "designation": "OWNER",
  ///   "jobTag": "FULL_TIME",
  ///   "birthdate": "2026-02-03T09:48:39.440Z",
  ///   "primaryClassroomCode": "string",
  ///   "allowedClassroomCodes": ["string"]
  /// }
  Future<String> updateStaffProfile({
    required String staffCode,
    required Map<String, dynamic> body,
  });

  /// Updates staff address via `/api/v1/staff-address/{staffCode}`.
  ///
  /// Expected body:
  /// {
  ///   "addressStreet": "string",
  ///   "addressLine2": "string",
  ///   "addressCity": "string",
  ///   "addressState": "string",
  ///   "addressZipCode": "string",
  ///   "addressCountry": "string"
  /// }
  Future<String> updateStaffAddress({
    required String staffCode,
    required Map<String, dynamic> body,
  });

  /// Updates a staff member's allowed classrooms via
  /// `PATCH /api/v1/staff-classrooms/{staffCode}/allowed-classrooms`.
  /// Body: `{ "classroomCodes": ["CLS_...", ...] }`.
  Future<String> updateStaffAllowedClassrooms({
    required String staffCode,
    required List<String> classroomCodes,
  });

  /// Updates a staff member's primary classroom via
  /// `PATCH /api/v1/staff-classrooms/{staffCode}/primary-classroom`.
  /// Body: `{ "classroomCode": "CLS_..." }`.
  Future<String> updateStaffPrimaryClassroom({
    required String staffCode,
    required String classroomCode,
  });

  /// Updates the *logged-in* staff member's basic profile + address via
  /// `PATCH /api/v1/staff/staff/my-profile/{staffCode}`.
  ///
  /// Expected [body] shape:
  /// {
  ///   "firstName": "string",
  ///   "lastName": "string",
  ///   "phoneNumber": "string",
  ///   "addressStreet": "string",
  ///   "addressLine2": "string",
  ///   "addressCity": "string",
  ///   "addressState": "string",
  ///   "addressZipCode": "string",
  ///   "addressCountry": "string"
  /// }
  Future<String> updateMyProfile({
    required String staffCode,
    required Map<String, dynamic> body,
  });

  /// Changes the login email for a user via
  /// `POST /api/v1/users/{userCode}/email-change`.
  ///
  /// Expects body:
  /// {
  ///   "oldEmail": "string",
  ///   "newEmail": "string",
  ///   "organizationCode": "string",
  ///   "schoolCode": "string"
  /// }
  Future<String> changeUserEmail({
    required String userCode,
    required String oldEmail,
    required String newEmail,
    required String organizationCode,
    required String schoolCode,
  });

  /// Fetches the staff sign-in PIN via
  /// `GET /api/v1/staff/staff/my-profile/{staffCode}/pin`.
  Future<String> getStaffSignInPin({required String staffCode});

  /// Fetches staff important dates via `GET /api/v1/staff-dates/{staffCode}`.
  ///
  /// Returns a list of [ImportantDateRequestModel]-shaped items:
  /// {
  ///   "importantDateType": "HIRE_DATE",
  ///   "dueDate": "2026-02-06",
  ///   "completedDate": "2026-02-06"
  /// }
  Future<List<ImportantDateRequestModel>> getImportantDates({
    required String staffCode,
  });

  Future<ImportantDatesResponseModel> updateImportantDates({
    required String staffCode,
    required List<ImportantDateRequestModel> dates,
  });

  /// Creates an Admin user (school admin) via `/api/v1/school-users`.
  Future<CreateSchoolUserResponseModel> createSchoolAdminUser({
    required CreateSchoolUserRequestModel request,
  });

  /// Creates a Staff user via `/api/v1/school-users/staff`.
  Future<CreateSchoolUserResponseModel> createStaffUser({
    required CreateStaffUserRequestModel request,
  });

  /// Deactivates a school user via `/api/v1/school-users/deactivate`.
  Future<String> deactivateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  });

  /// Activates a school user via `/api/v1/school-users/activate`.
  Future<String> activateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  });

  /// Permanently deletes a school user via `DELETE /api/v1/school-users`
  /// (UAT: `/api/v1/user/school-users`) with userCode/organizationCode/
  /// schoolCode/role query params.
  Future<String> deleteSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  });

  /// Deactivates an organization admin via
  /// `/api/v1/user/organization-admins/deactivate`.
  Future<String> deactivateOrganizationAdmin({
    required String userCode,
    required String organizationCode,
  });

  /// Activates an organization admin via
  /// `/api/v1/user/organization-admins/activate`.
  Future<String> activateOrganizationAdmin({
    required String userCode,
    required String organizationCode,
  });

  /// Updates staff work & break schedules via `/api/v1/staff-schedules/{staffCode}`.
  ///
  /// Expected [body] shape:
  /// {
  ///   "workSchedules": [
  ///     {
  ///       "dayOfWeek": "MONDAY",
  ///       "workStartTime": { "hour": 9, "minute": 0, "second": 0, "nano": 0 },
  ///       "workEndTime":   { "hour": 17, "minute": 0, "second": 0, "nano": 0 }
  ///     }
  ///   ],
  ///   "breakSchedules": [
  ///     {
  ///       "dayOfWeek": "MONDAY",
  ///       "breakType": "LUNCH",
  ///       "breakStartTime": { "hour": 12, "minute": 0, "second": 0, "nano": 0 },
  ///       "breakEndTime":   { "hour": 13, "minute": 0, "second": 0, "nano": 0 }
  ///     }
  ///   ]
  /// }
  Future<String> updateStaffSchedules({
    required String staffCode,
    required Map<String, dynamic> body,
  });

  /// `GET /api/v1/staff-schedules/{staffCode}`
  Future<
    ({
      List<StaffProfileWorkScheduleModel> workSchedules,
      List<StaffProfileBreakScheduleModel> breakSchedules,
    })
  >
  getStaffSchedules({required String staffCode});

  /// `GET /api/v1/organization/schools/{schoolCode}` (`data.childcareSchedule`).
  Future<SchoolRegularScheduleListModel> getSchoolRegularSchedules({
    required String schoolCode,
  });

  Future<StaffDocumentExpirySummaryModel> getStaffDocumentExpirySummary({
    required String schoolCode,
  });

  Future<PhysicalCheckupSummaryModel> getPhysicalCheckupSummary({
    required String schoolCode,
  });

  /// Updates work break reminder preference via
  /// `PATCH /api/v1/staff/staff/my-profile/{staffCode}/work-break-reminder`.
  ///
  /// Body: `{ "setWorkBreakRemainder": true/false }`
  Future<WorkBreakReminderResponseModel> updateWorkBreakReminder({
    required String staffCode,
    required bool enabled,
  });
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  StaffRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<StaffCountModel> getStaffCount({
    required String organizationCode,
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffCount,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff count API response format');
    }

    return StaffCountModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<StaffPageModel> getStaffPage({
    required String organizationCode,
    required String schoolCode,
    String? code,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
    List<String>? primaryClassroomCodes,
    List<String>? classCodes,
    String? sortBy,
    List<String>? attendanceStatuses,
  }) async {
    // UAT contract matches web: `schoolCode`, `page`, `size`, `status` (string),
    // `organizationCode` — no duplicate `pageable.*` keys.
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'page': page,
      'size': size,
      'sort': 'firstName,asc',
    };

    // New: send organizationCode so backend can scope staff list correctly.
    if (organizationCode.isNotEmpty) {
      queryParameters['organizationCode'] = organizationCode;
    }

    if (code != null && code.isNotEmpty) {
      queryParameters['code'] = code;
    }
    // ACTIVE | INACTIVE | ARCHIVE | UPCOMING — single string (same as browser query).
    if (status != null && status.isNotEmpty) {
      final normalized = status.trim().toUpperCase();
      if (normalized.isNotEmpty) {
        queryParameters['status'] = normalized;
      }
    }
    if (designation != null && designation.isNotEmpty) {
      queryParameters['designation'] = designation;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    // API expects primaryClassroomCodes and classCodes as array[string]
    final primaryCodes = primaryClassroomCodes
        ?.where((c) => (c.trim()).isNotEmpty)
        .toList();
    if (primaryCodes != null && primaryCodes.isNotEmpty) {
      queryParameters['primaryClassroomCodes'] = primaryCodes;
    }
    final allowedCodes = classCodes
        ?.where((c) => (c.trim()).isNotEmpty)
        .toList();
    if (allowedCodes != null && allowedCodes.isNotEmpty) {
      queryParameters['classCodes'] = allowedCodes;
    }
    // API expects underscore codes, e.g. attendanceStatus=SIGNED_IN&attendanceStatus=ABSENT.
    final normalizedAttendanceStatuses = attendanceStatuses
        ?.map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
    if (normalizedAttendanceStatuses != null &&
        normalizedAttendanceStatuses.isNotEmpty) {
      queryParameters['attendanceStatus'] = normalizedAttendanceStatuses;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffList,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      // Repeats keys: `attendanceStatus=SIGNED_IN&attendanceStatus=ABSENT`.
      options: Options(listFormat: ListFormat.multi),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff API response format');
    }

    return StaffPageModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<List<StaffListItemModel>> getAllStaff({
    required String organizationCode,
    required String schoolCode,
    List<String>? statuses,
    int size = 200,
  }) async {
    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      // Single large page so we get every staff member in one round trip.
      'page': 0,
      'size': size,
      'sort': 'firstName,asc',
    };
    if (organizationCode.isNotEmpty) {
      queryParameters['organizationCode'] = organizationCode;
    }
    final normalizedStatuses = statuses
        ?.map((s) => s.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
    if (normalizedStatuses != null && normalizedStatuses.isNotEmpty) {
      queryParameters['status'] = normalizedStatuses;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffList,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      // Repeats keys: `status=ACTIVE&status=UPCOMING`.
      options: Options(listFormat: ListFormat.multi),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    // Backend returns either a paged `data.content` array or a flat `data` array
    // when paging is disabled. Support both shapes.
    final inner = data['data'];
    final rawList = inner is List
        ? inner
        : (inner is Map<String, dynamic>
              ? (inner['content'] as List<dynamic>? ?? const [])
              : const <dynamic>[]);

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(StaffListItemModel.fromJson)
        .toList();
  }

  @override
  Future<StaffDocumentResponseModel> addStaffDocument({
    required String staffCode,
    required StaffDocumentRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffDocumentAdd}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff document API response format');
    }

    return StaffDocumentResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffDocumentResponseModel> updateStaffDocument({
    required String documentUuid,
    required StaffDocumentRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffDocumentUpdate}/$documentUuid',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff document update API response format');
    }

    return StaffDocumentResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffDocumentResponseModel> deleteStaffDocument({
    required String documentUuid,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffDocuments}/$documentUuid',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.delete<dynamic>(endpoint);

    // DELETE requests might return null data or empty response
    if (response.data == null) {
      // Return a success response if DELETE returns null (common for DELETE endpoints)
      return const StaffDocumentResponseModel(
        success: true,
        message: 'Document deleted successfully',
        data: null,
        timestamp: '',
      );
    }

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff document delete API response format');
    }

    return StaffDocumentResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffDocumentsPageModel> getStaffDocuments({
    required String staffCode,
    int page = 0,
    int size = 10,
    bool? expired,
  }) async {
    final queryParameters = <String, dynamic>{
      'staffCode': staffCode,
      'page': page,
      'size': size,
    };

    if (expired != null) {
      queryParameters['expired'] = expired;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffDocuments,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff documents API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    final dataPayload = data['data'] as Map<String, dynamic>?;
    if (dataPayload == null) {
      throw Exception('Missing data field in staff documents response');
    }

    return StaffDocumentsPageModel.fromJson(dataPayload);
  }

  @override
  Future<StaffProfileModel> getStaffProfile({
    required String staffCode,
    bool forEditStaff = false,
  }) async {
    final path = forEditStaff
        ? ApiPaths.staffProfileByCodePath(staffCode)
        : ApiPaths.staffProfilePath(staffCode);
    final endpoint = ApiPaths.urlWithBase(path, ApiConstants.staffBaseUrl);

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff profile API response format');
    }

    return StaffProfileModel.fromJson(response.data! as Map<String, dynamic>);
  }

  @override
  Future<String?> getStaffCodeByUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffCodeByUser,
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff code API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    final inner = data['data'];

    if (inner == null) return null;
    if (inner is String) {
      return inner.trim().isEmpty ? null : inner.trim();
    }
    if (inner is Map<String, dynamic>) {
      final code = (inner['staffCode'] ?? inner['code'] ?? '')
          .toString()
          .trim();
      return code.isEmpty ? null : code;
    }
    // Fallback: unknown shape
    return null;
  }

  @override
  Future<String> updateStaffProfile({
    required String staffCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffProfileByCodePath(staffCode),
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff profile update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Profile updated successfully';
  }

  @override
  Future<String> updateStaffAddress({
    required String staffCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffAddress}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff address update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Address updated successfully';
  }

  @override
  Future<String> updateStaffAllowedClassrooms({
    required String staffCode,
    required List<String> classroomCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAllowedClassroomsByStaffCodePath(staffCode),
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: <String, dynamic>{'classroomCodes': classroomCodes},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          'Allowed classrooms updated successfully';
    }
    return 'Allowed classrooms updated successfully';
  }

  @override
  Future<String> updateStaffPrimaryClassroom({
    required String staffCode,
    required String classroomCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffPrimaryClassroomByStaffCodePath(staffCode),
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: <String, dynamic>{'classroomCode': classroomCode},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          'Primary classroom updated successfully';
    }
    return 'Primary classroom updated successfully';
  }

  @override
  Future<String> updateMyProfile({
    required String staffCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffMyProfile}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff profile update API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Profile updated successfully';
  }

  @override
  Future<String> changeUserEmail({
    required String userCode,
    required String oldEmail,
    required String newEmail,
    required String organizationCode,
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.userEmailChange(userCode));

    final response = await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'oldEmail': oldEmail,
        'newEmail': newEmail,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected email-change API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Email updated successfully';
  }

  @override
  Future<String> getStaffSignInPin({required String staffCode}) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffMyProfilePinPath(staffCode),
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff pin API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    final pin = data['data']?.toString() ?? '';
    return pin;
  }

  @override
  Future<List<ImportantDateRequestModel>> getImportantDates({
    required String staffCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffDates}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected important dates API response format');
    }

    final data = (response.data! as Map<String, dynamic>)['data'];
    if (data is! List) {
      // Backend can return null/empty; normalize to empty list.
      return const <ImportantDateRequestModel>[];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => ImportantDateRequestModel(
            importantDateType: (json['importantDateType'] ?? '').toString(),
            dueDate: (json['dueDate'] ?? '').toString(),
            completedDate: json['completedDate']?.toString(),
            status: json['status']?.toString(),
          ),
        )
        .toList();
  }

  @override
  Future<ImportantDatesResponseModel> updateImportantDates({
    required String staffCode,
    required List<ImportantDateRequestModel> dates,
  }) async {
    final today = AppTime.today();

    // Absolute safety check at data-source layer.
    // Due/Scheduled must never be past; Completed must never be future.
    for (final date in dates) {
      final type = date.importantDateType.trim().toUpperCase();
      if (type != 'PHYSICAL_CHECKUP') continue;

      final status = (date.status ?? '').trim().toUpperCase();
      final dueDate = date.dueDate.trim();
      if (dueDate.isEmpty) continue;

      DateTime? parsed;
      try {
        parsed = DateTime.parse(dueDate);
      } catch (_) {
        parsed = null;
      }
      if (parsed == null) continue;

      final picked = DateTime(parsed.year, parsed.month, parsed.day);
      final isDueOrScheduled =
          status == 'DUE' || status == 'SCHEDULED' || status == 'OVERDUE';
      final isCompleted = status == 'COMPLETED';

      AppLogger.d(
        '[ImportantDates DS Guard] staffCode=$staffCode status=$status dueDate=$dueDate today=$today picked=$picked',
      );

      if (isDueOrScheduled && picked.isBefore(today)) {
        AppLogger.d(
          '[ImportantDates DS Guard] BLOCK: Due/Scheduled picked date is before today.',
        );
        throw Exception(
          'For Due/Scheduled status, Physical Checkup Date must be today or future',
        );
      }
      if (isCompleted && picked.isAfter(today)) {
        AppLogger.d(
          '[ImportantDates DS Guard] BLOCK: Completed picked date is after today.',
        );
        throw Exception(
          'For Completed status, Physical Checkup Date must be today or past',
        );
      }
    }

    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffDates}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final requestBody = dates.map((date) => date.toJson()).toList();

    final response = await _client.patch<dynamic>(endpoint, data: requestBody);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected important dates API response format');
    }

    return ImportantDatesResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<CreateSchoolUserResponseModel> createSchoolAdminUser({
    required CreateSchoolUserRequestModel request,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.schoolUsers);

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected create school admin user API response format',
      );
    }

    return CreateSchoolUserResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<CreateSchoolUserResponseModel> createStaffUser({
    required CreateStaffUserRequestModel request,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.schoolUsersStaff);

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected create staff user API response format');
    }

    return CreateSchoolUserResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<String> deactivateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.schoolUsersDeactivate);

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'role': role,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected deactivate school user API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'User deactivated successfully';
  }

  @override
  Future<String> activateSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.schoolUsersActivate);

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'role': role,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected activate school user API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'User activated successfully';
  }

  @override
  Future<String> deleteSchoolUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
    required String role,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.schoolUsers);

    final response = await _client.delete<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'role': role,
      },
    );

    // A successful DELETE may return an empty body, a plain string, or a
    // `{ "message": ... }` envelope — accept all and fall back to a default.
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? 'Staff deleted successfully';
    }
    final text = data?.toString().trim() ?? '';
    return text.isEmpty ? 'Staff deleted successfully' : text;
  }

  @override
  Future<String> deactivateOrganizationAdmin({
    required String userCode,
    required String organizationCode,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.organizationAdminsDeactivate);

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        'organizationCode': organizationCode,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected deactivate organization admin API response format',
      );
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ??
        'Organization admin deactivated successfully';
  }

  @override
  Future<String> activateOrganizationAdmin({
    required String userCode,
    required String organizationCode,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.organizationAdminsActivate);

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'userCode': userCode,
        'organizationCode': organizationCode,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected activate organization admin API response format',
      );
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ??
        'Organization admin activated successfully';
  }

  @override
  Future<String> updateStaffSchedules({
    required String staffCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffSchedules}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(endpoint, data: body);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff schedules API response format');
    }

    final data = response.data! as Map<String, dynamic>;
    return data['message']?.toString() ?? 'Schedule updated successfully';
  }

  @override
  Future<
    ({
      List<StaffProfileWorkScheduleModel> workSchedules,
      List<StaffProfileBreakScheduleModel> breakSchedules,
    })
  >
  getStaffSchedules({required String staffCode}) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.staffSchedules}/$staffCode',
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff schedules GET response format');
    }

    final root = response.data! as Map<String, dynamic>;
    final data = root['data'] as Map<String, dynamic>? ?? {};

    final workList = (data['workSchedules'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => StaffProfileWorkScheduleModel(
            dayOfWeek: (e['dayOfWeek'] ?? '').toString(),
            workStartTime: StaffProfileTimeModel.fromJson(e['workStartTime']),
            workEndTime: StaffProfileTimeModel.fromJson(e['workEndTime']),
          ),
        )
        .toList(growable: false);

    final breakList = (data['breakSchedules'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => StaffProfileBreakScheduleModel(
            dayOfWeek: (e['dayOfWeek'] ?? '').toString(),
            breakType: (e['breakType'] ?? '').toString(),
            breakStartTime: StaffProfileTimeModel.fromJson(e['breakStartTime']),
            breakEndTime: StaffProfileTimeModel.fromJson(e['breakEndTime']),
          ),
        )
        .toList(growable: false);

    return (workSchedules: workList, breakSchedules: breakList);
  }

  @override
  Future<SchoolRegularScheduleListModel> getSchoolRegularSchedules({
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.schoolByCode(schoolCode));

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected school settings API response format');
    }

    return SchoolRegularScheduleListModel.fromResponse(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffDocumentExpirySummaryModel> getStaffDocumentExpirySummary({
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.staffDocumentExpirySummary);
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'schoolCode': schoolCode},
    );
    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected staff document expiry summary response format',
      );
    }
    return StaffDocumentExpirySummaryModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<PhysicalCheckupSummaryModel> getPhysicalCheckupSummary({
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.staffDatesPhysicalCheckupSummary);
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'schoolCode': schoolCode},
    );
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected physical checkup summary response format');
    }
    return PhysicalCheckupSummaryModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<WorkBreakReminderResponseModel> updateWorkBreakReminder({
    required String staffCode,
    required bool enabled,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffWorkBreakReminderPath(staffCode),
      ApiConstants.staffBaseUrl,
    );

    final response = await _client.patch<dynamic>(
      endpoint,
      data: <String, dynamic>{'setWorkBreakRemainder': enabled},
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected work break reminder API response format');
    }

    return WorkBreakReminderResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }
}
