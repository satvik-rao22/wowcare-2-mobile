import '../../../../core/network/api_client.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/attendance_classroom_scope.dart';
import '../../../../core/util/attendance_events.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../core/util/school_timezone_resolver.dart';
import '../../../../domain/features/attendance/entities/attendance_action_result.dart';
import '../../../../domain/features/attendance/entities/student_transfer_request.dart';
import '../../../../domain/features/attendance/entities/staff_transfer_request.dart';
import '../../../../domain/features/attendance/entities/staff_attendance_daily_update_request.dart';
import '../../../../domain/features/attendance/entities/staff_sign_in_request.dart';
import '../../../../domain/features/attendance/entities/staff_sign_out_request.dart';
import '../../../../domain/features/attendance/entities/student_sign_in_request.dart';
import '../../../../domain/features/attendance/entities/student_sign_out_request.dart';
import '../../../../domain/features/attendance/entities/student_attendance_daily.dart';
import '../../../../domain/features/attendance/entities/student_attendance_custom.dart';
import '../../../../domain/features/attendance/entities/student_attendance_expected_summary.dart';
import '../../../../domain/features/attendance/entities/student_attendance_profile_response.dart';
import '../../../../domain/features/attendance/entities/staff_attendance_profile_response.dart';
import '../../../../domain/features/attendance/entities/student_attendance_profile_absent_toggle_response.dart';
import '../../../../domain/features/attendance/entities/staff_attendance_profile_absent_toggle_response.dart';
import '../../../../domain/features/attendance/entities/student_attendance_absent_view_response.dart';
import '../../../../domain/features/attendance/entities/attendance_profile_query.dart';
import '../../../../domain/features/attendance/entities/attendance_profile_absent_toggle_query.dart';
import '../../../../domain/features/attendance/entities/staff_attendance_daily.dart';
import '../../../../domain/features/attendance/entities/staff_attendance_absent.dart'
    as staff_absent;
import '../../../../domain/features/attendance/entities/student_attendance_absent_form.dart'
    as student_absent;
import '../../../../domain/features/attendance/repositories/attendance_repository.dart';
import '../../../../domain/features/attendance/entities/qr_validation_result.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/student_absence_record_models.dart';
import '../models/student_attendance_models.dart';
import '../models/staff_absence_record_models.dart';
import '../models/student_attendance_profile_response_model.dart';
import '../models/staff_attendance_profile_response_model.dart';
import '../models/student_attendance_profile_absent_toggle_response_model.dart';
import '../models/staff_attendance_profile_absent_toggle_response_model.dart';
import '../models/student_attendance_absent_view_response_model.dart';

class AttendanceRepositoryImpl
    implements AttendanceRepository, AttendanceRepositoryWithCache {
  AttendanceRepositoryImpl(
    this._remoteDataSource,
    StorageService storageService,
    ApiClient apiClient,
  ) : _storage = storageService,
      _apiClient = apiClient,
      _cacheManager = CacheManager(storageService);

  final AttendanceRemoteDataSource _remoteDataSource;
  final StorageService _storage;
  final ApiClient _apiClient;
  final CacheManager _cacheManager;

  /// Permission scope for attendance list APIs — always the staff member's full
  /// allowed list (or empty for admin/parent personas).
  ///
  /// [studentCrossClass] must be true for STUDENT attendance calls: a scoped
  /// teacher is then relaxed to unscoped (all classrooms) when the active
  /// school has `allowTeacherCrossClassAttendance` enabled. Staff-attendance
  /// calls leave it false so their scoping is unchanged.
  Future<List<String>> _attendanceAllowedClassroomCodes({
    bool studentCrossClass = false,
  }) => studentCrossClass
      ? resolveStudentAttendanceAllowedClassroomCodes(storage: _storage)
      : resolveAttendanceAllowedClassroomCodes(storage: _storage);

  /// Builds attendance list query classroom params:
  /// - [classroomCodes]: user filter (intersected with allowed when scoped)
  /// - [allowedClassroomCodes]: full permission scope
  /// - [studentCrossClass]: see [_attendanceAllowedClassroomCodes].
  Future<({List<String>? classroomCodes, List<String> allowedClassroomCodes})>
  _resolveAttendanceClassroomQueryParams(
    List<String>? classroomCodes, {
    bool studentCrossClass = false,
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: studentCrossClass,
    );
    final effective = resolveAttendanceFilterClassroomCodes(
      selectedClassroomCodes: classroomCodes,
      allowedClassroomCodes: allowed,
    );
    return (
      classroomCodes: effective,
      allowedClassroomCodes: List<String>.from(allowed),
    );
  }

  Future<String> _effectiveSchoolTimeZone(String? override) async {
    final o = override?.trim() ?? '';
    if (o.isNotEmpty) return o;
    return SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: _storage,
      apiClient: _apiClient,
    );
  }

  // Cache key helpers - following the pattern: {feature}_{resource}_cache_{identifier}
  static String _studentAttendanceDailyCacheKey(
    String attendanceDate, {
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) {
    // Build identifier from filters
    final parts = <String>[attendanceDate];

    if (classroomCodes != null && classroomCodes.isNotEmpty) {
      parts.add('classrooms=${classroomCodes.join(',')}');
    }

    if (tagCodes != null && tagCodes.isNotEmpty) {
      parts.add('tags=${tagCodes.join(',')}');
    }

    if (search != null && search.isNotEmpty) {
      parts.add('search=${search.trim().toLowerCase()}');
    }

    final identifier = parts.join('|');

    return CacheManager.buildCacheKey(
      feature: 'attendance',
      resource: 'daily',
      identifier: identifier,
    );
  }

  static String _studentAttendanceCustomCacheKey(
    String fromAttendanceDate,
    String toAttendanceDate, {
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) {
    final parts = <String>[fromAttendanceDate, toAttendanceDate];

    if (classroomCodes != null && classroomCodes.isNotEmpty) {
      parts.add('classrooms=${classroomCodes.join(',')}');
    }

    if (tagCodes != null && tagCodes.isNotEmpty) {
      parts.add('tags=${tagCodes.join(',')}');
    }

    if (search != null && search.isNotEmpty) {
      parts.add('search=${search.trim().toLowerCase()}');
    }

    final identifier = parts.join('|');

    return CacheManager.buildCacheKey(
      feature: 'attendance',
      resource: 'custom',
      identifier: identifier,
    );
  }

  // Cache key for the student expected-attendance summary card (scoped by classroom).
  static String _studentAttendanceSummaryCacheKey(String? classroomCode) =>
      CacheManager.buildCacheKey(
        feature: 'attendance',
        resource: 'student_summary',
        identifier: (classroomCode == null || classroomCode.trim().isEmpty)
            ? 'school'
            : classroomCode.trim(),
      );

  // Cache key for the staff expected-attendance summary card.
  static String _staffAttendanceSummaryCacheKey(String? classroomCode) =>
      CacheManager.buildCacheKey(
        feature: 'attendance',
        resource: 'staff_summary',
        identifier: (classroomCode == null || classroomCode.trim().isEmpty)
            ? 'school'
            : classroomCode.trim(),
      );

  /// Single classroom code for summary/card APIs (query param `classroomCode`).
  String? _effectiveClassroomCodeForSummary(
    String? classroomCode,
    List<String> allowed,
  ) {
    final fromArg = classroomCode?.trim() ?? '';
    if (fromArg.isNotEmpty) return fromArg;
    if (allowed.isNotEmpty) return allowed.first;
    return null;
  }

  @override
  Future<StudentAttendanceDailyPage> getStudentAttendanceDaily({
    required String attendanceDate,
    String? fromAttendanceDate,
    String? toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
      studentCrossClass: true,
    );
    // 1. Call remote datasource
    final pageModel = await _remoteDataSource.getStudentAttendanceDaily(
      attendanceDate: attendanceDate,
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomQuery.classroomCodes,
      studentCodes: studentCodes,
      tagCodes: tagCodes,
      signInAtFilter: signInAtFilter,
      signOutAtFilter: signOutAtFilter,
      isExpectedNotMarked: isExpectedNotMarked,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    // 2. Cache only first page (never store classroom-scoped staff payloads here).
    if (page == 0 && classroomQuery.allowedClassroomCodes.isEmpty) {
      await _cacheManager.saveCache(
        _studentAttendanceDailyCacheKey(
          attendanceDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        ),
        pageModel.toJson(),
      );
    }

    // 3. Map model to entity
    return _mapPageModelToEntity(pageModel);
  }

  @override
  Future<StudentAttendanceDailyPage?> loadCachedStudentAttendanceDaily(
    String attendanceDate, {
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: true,
    );
    if (allowed.isNotEmpty) {
      return null;
    }
    final payload = await _cacheManager.loadCache(
      _studentAttendanceDailyCacheKey(
        attendanceDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
      ),
    );
    if (payload == null) return null;

    final model = StudentAttendanceDailyPageModel.fromCacheJson(payload);
    return _mapPageModelToEntity(model);
  }

  // Map model to entity
  StudentAttendanceDailyPage _mapPageModelToEntity(
    StudentAttendanceDailyPageModel model,
  ) {
    return StudentAttendanceDailyPage(
      items: model.items.map((m) => _mapItemModelToEntity(m)).toList(),
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  StudentAttendanceDailyItem _mapItemModelToEntity(
    StudentAttendanceDailyItemModel model,
  ) {
    return StudentAttendanceDailyItem(
      attendanceRecordCode: model.attendanceRecordCode,
      attendanceDate: model.attendanceDate,
      studentCode: model.studentCode,
      studentName: model.studentName,
      isExpectedToday: model.isExpectedToday,
      classroomName: model.classroomName,
      signedInAt: model.signedInAt,
      signedInTime: model.signedInTime != null
          ? StudentAttendanceTime(
              hour: model.signedInTime!.hour,
              minute: model.signedInTime!.minute,
              second: model.signedInTime!.second,
              nano: model.signedInTime!.nano,
            )
          : null,
      signedInBy: model.signedInBy,
      signedOutAt: model.signedOutAt,
      signedOutTime: model.signedOutTime != null
          ? StudentAttendanceTime(
              hour: model.signedOutTime!.hour,
              minute: model.signedOutTime!.minute,
              second: model.signedOutTime!.second,
              nano: model.signedOutTime!.nano,
            )
          : null,
      signedOutBy: model.signedOutBy,
      signedInMethod: model.signedInMethod,
      signedOutMethod: model.signedOutMethod,
      classroomCode: model.classroomCode,
      tagCodes: model.tagCodes,
      tagNames: model.tagNames,
      duration: model.duration,
      // Transfer-related fields
      isTransfer: model.isTransfer,
      sequenceNumber: model.sequenceNumber,
      totalSequenceCount: model.totalSequenceCount,
      hasNextTransfer: model.hasNextTransfer,
      isLastSequenceEntry: model.isLastSequenceEntry,
      fromClassroomCode: model.fromClassroomCode,
      fromClassroomName: model.fromClassroomName,
      toClassroomCode: model.toClassroomCode,
      toClassroomName: model.toClassroomName,
      transferTime: model.transferTime != null
          ? StudentAttendanceTime(
              hour: model.transferTime!.hour,
              minute: model.transferTime!.minute,
              second: model.transferTime!.second,
              nano: model.transferTime!.nano,
            )
          : null,
      nextActionTime: model.nextActionTime != null
          ? StudentAttendanceTime(
              hour: model.nextActionTime!.hour,
              minute: model.nextActionTime!.minute,
              second: model.nextActionTime!.second,
              nano: model.nextActionTime!.nano,
            )
          : null,
      transferredBy: model.transferredBy,
      transferReason: model.transferReason,
      notExpectedComment: model.notExpectedComment,
    );
  }

  @override
  Future<StudentAttendanceCustomPage> getStudentAttendanceCustom({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
      studentCrossClass: true,
    );
    final pageModel = await _remoteDataSource.getStudentAttendanceCustom(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    if (page == 0 && classroomQuery.allowedClassroomCodes.isEmpty) {
      await _cacheManager.saveCache(
        _studentAttendanceCustomCacheKey(
          fromAttendanceDate,
          toAttendanceDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        ),
        pageModel.toJson(),
      );
    }

    return _mapCustomPageModelToEntity(pageModel);
  }

  @override
  Future<StudentAttendanceCustomPage?> loadCachedStudentAttendanceCustom(
    String fromAttendanceDate,
    String toAttendanceDate, {
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: true,
    );
    if (allowed.isNotEmpty) {
      return null;
    }
    final payload = await _cacheManager.loadCache(
      _studentAttendanceCustomCacheKey(
        fromAttendanceDate,
        toAttendanceDate,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: search,
      ),
    );
    if (payload == null) return null;

    final model = StudentAttendanceCustomPageModel.fromCacheJson(payload);
    return _mapCustomPageModelToEntity(model);
  }

  StudentAttendanceCustomPage _mapCustomPageModelToEntity(
    StudentAttendanceCustomPageModel model,
  ) {
    return StudentAttendanceCustomPage(
      items: model.items.map(_mapCustomItemModelToEntity).toList(),
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  StudentAttendanceCustomItem _mapCustomItemModelToEntity(
    StudentAttendanceCustomItemModel model,
  ) {
    return StudentAttendanceCustomItem(
      studentCode: model.studentCode,
      studentName: model.studentName,
      isExpectedToday: model.isExpectedToday,
      classroomName: model.classroomName,
      classroomCode: model.classroomCode,
      attendedDays: model.attendedDays,
      attendedTime: model.attendedTime,
      attendedHours: model.attendedHours,
      attendedMinutes: model.attendedMinutes,
      signedInBy: model.signedInBy,
      signedInTime: model.signedInTime,
      signedOutBy: model.signedOutBy,
      signedOutTime: model.signedOutTime,
      tagCodes: model.tagCodes,
      tagNames: model.tagNames,
    );
  }

  @override
  Future<StudentAttendanceCustomPage> getStudentSignInFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
      studentCrossClass: true,
    );
    final pageModel = await _remoteDataSource.getStudentSignInFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    // For now we don't cache this list; it's a transient sign-in selection.
    return _mapCustomPageModelToEntity(pageModel);
  }

  @override
  Future<StudentAttendanceCustomPage> getStudentSignOutFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
      studentCrossClass: true,
    );
    final pageModel = await _remoteDataSource.getStudentSignOutFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    // No caching for this transient selection list.
    return _mapCustomPageModelToEntity(pageModel);
  }

  @override
  Future<StudentAttendanceCustomPage> getStudentTransferFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
      studentCrossClass: true,
    );
    final pageModel = await _remoteDataSource.getStudentTransferFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    // No caching for this transient selection list.
    return _mapCustomPageModelToEntity(pageModel);
  }

  @override
  Future<StaffAttendanceDailyPage> getStaffAttendanceDaily({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
    );
    final pageModel = await _remoteDataSource.getStaffAttendanceDaily(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      signInAtFilter: signInAtFilter,
      signOutAtFilter: signOutAtFilter,
      isExpectedNotMarked: isExpectedNotMarked,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    return _mapStaffDailyPageModelToEntity(pageModel);
  }

  StaffAttendanceDailyPage _mapStaffDailyPageModelToEntity(
    StaffAttendanceDailyPageModel model,
  ) {
    return StaffAttendanceDailyPage(
      items: model.items.map(_mapStaffItemModelToEntity).toList(),
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  StaffAttendanceDailyItem _mapStaffItemModelToEntity(
    StaffAttendanceDailyItemModel model,
  ) {
    return StaffAttendanceDailyItem(
      attendanceRecordCode: model.attendanceRecordCode,
      staffCode: model.staffCode,
      staffName: model.staffName,
      isExpectedToday: model.isExpectedToday,
      classroomName: model.classroomName,
      classroomCode: model.classroomCode,
      attendedDays: model.attendedDays,
      signedInBy: model.signedInBy,
      signedInTime: model.signedInTime != null
          ? StaffAttendanceTime(
              hour: model.signedInTime!.hour,
              minute: model.signedInTime!.minute,
              second: model.signedInTime!.second,
              nano: model.signedInTime!.nano,
            )
          : null,
      signedOutBy: model.signedOutBy,
      signedOutTime: model.signedOutTime != null
          ? StaffAttendanceTime(
              hour: model.signedOutTime!.hour,
              minute: model.signedOutTime!.minute,
              second: model.signedOutTime!.second,
              nano: model.signedOutTime!.nano,
            )
          : null,
      designation: model.designation,
      attendedTime: model.attendedTime,
      attendedHours: model.attendedHours,
      attendedMinutes: model.attendedMinutes,
      signedInMethod: model.signedInMethod,
      signedOutMethod: model.signedOutMethod,
      isTransfer: model.isTransfer,
      sequenceNumber: model.sequenceNumber,
      totalSequenceCount: model.totalSequenceCount,
      hasNextTransfer: model.hasNextTransfer,
      isLastSequenceEntry: model.isLastSequenceEntry,
      fromClassroomCode: model.fromClassroomCode,
      fromClassroomName: model.fromClassroomName,
      toClassroomCode: model.toClassroomCode,
      toClassroomName: model.toClassroomName,
      transferTime: model.transferTime != null
          ? StaffAttendanceTime(
              hour: model.transferTime!.hour,
              minute: model.transferTime!.minute,
              second: model.transferTime!.second,
              nano: model.transferTime!.nano,
            )
          : null,
      nextActionTime: model.nextActionTime != null
          ? StaffAttendanceTime(
              hour: model.nextActionTime!.hour,
              minute: model.nextActionTime!.minute,
              second: model.nextActionTime!.second,
              nano: model.nextActionTime!.nano,
            )
          : null,
      transferredBy: model.transferredBy,
      transferReason: model.transferReason,
      notExpectedComment: model.notExpectedComment,
    );
  }

  @override
  Future<StaffAttendanceDailyPage> getStaffAttendanceCustom({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
    );
    final pageModel = await _remoteDataSource.getStaffAttendanceCustom(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    return _mapStaffDailyPageModelToEntity(pageModel);
  }

  @override
  Future<staff_absent.StaffAttendanceAbsentPage> getStaffAttendanceAbsent({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
    );
    final pageModel = await _remoteDataSource.getStaffAttendanceAbsent(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    return _mapStaffAbsentPageModelToEntity(pageModel);
  }

  @override
  Future<staff_absent.StaffAttendanceAbsentPage> getStaffAbsentFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
    );
    final pageModel = await _remoteDataSource.getStaffAbsentFormList(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    return _mapStaffAbsentPageModelToEntity(pageModel);
  }

  @override
  Future<staff_absent.StaffAttendanceAbsentPage>
  getStaffAttendanceAbsentToggleView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
    );
    final pageModel = await _remoteDataSource
        .getStaffAttendanceAbsentToggleView(
          fromAbsenceDate: fromAbsenceDate,
          toAbsenceDate: toAbsenceDate,
          classroomCodes: classroomQuery.classroomCodes,
          tagCodes: tagCodes,
          search: search,
          page: page,
          size: size,
          allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
        );

    return _mapStaffAbsentPageModelToEntity(pageModel);
  }

  staff_absent.StaffAttendanceAbsentPage _mapStaffAbsentPageModelToEntity(
    StaffAttendanceAbsentPageModel model,
  ) {
    return staff_absent.StaffAttendanceAbsentPage(
      items: model.items.map(_mapStaffAbsentItemModelToEntity).toList(),
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  @override
  Future<StaffAttendanceDailyPage> getStaffSignInFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
    );
    final pageModel = await _remoteDataSource.getStaffSignInFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    // No caching for this transient selection list.
    return _mapStaffDailyPageModelToEntity(pageModel);
  }

  @override
  Future<StaffAttendanceDailyPage> getStaffSignOutFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
    );
    final pageModel = await _remoteDataSource.getStaffSignOutFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    // No caching for this transient selection list.
    return _mapStaffDailyPageModelToEntity(pageModel);
  }

  @override
  Future<StaffAttendanceDailyPage> getStaffTransferFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
    );
    final pageModel = await _remoteDataSource.getStaffTransferFormList(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    // No caching for this transient selection list.
    return _mapStaffDailyPageModelToEntity(pageModel);
  }

  staff_absent.StaffAttendanceAbsentItem _mapStaffAbsentItemModelToEntity(
    StaffAttendanceAbsentItemModel model,
  ) {
    return staff_absent.StaffAttendanceAbsentItem(
      staffCode: model.staffCode,
      staffName: model.staffName,
      classroomCode: model.classroomCode,
      classroomName: model.classroomName,
      absenceDate: model.absenceDate,
      markedAbsentTime: model.markedAbsentTime != null
          ? staff_absent.StaffAttendanceTime(
              hour: model.markedAbsentTime!.hour,
              minute: model.markedAbsentTime!.minute,
              second: model.markedAbsentTime!.second,
              nano: model.markedAbsentTime!.nano,
            )
          : null,
      markedAbsentByName: model.markedAbsentByName,
      absenceNote: model.absenceNote,
      markAbsentMethod: model.markAbsentMethod,
      absentDays: model.absentDays,
      absenceRecordCode: model.absenceRecordCode,
    );
  }

  student_absent.StudentAttendanceAbsentFormPage
  _mapStudentAbsentFormPageModelToEntity(
    StudentAttendanceAbsentFormPageModel model,
  ) {
    return student_absent.StudentAttendanceAbsentFormPage(
      items: model.items.map(_mapStudentAbsentFormItemModelToEntity).toList(),
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  student_absent.StudentAttendanceAbsentFormItem
  _mapStudentAbsentFormItemModelToEntity(
    StudentAttendanceAbsentFormItemModel model,
  ) {
    return student_absent.StudentAttendanceAbsentFormItem(
      studentCode: model.studentCode,
      studentName: model.studentName,
      classroomCode: model.classroomCode,
      classroomName: model.classroomName,
      absenceDate: model.absenceDate,
      markedAbsentTime: model.markedAbsentTime != null
          ? student_absent.StudentAttendanceTime(
              hour: model.markedAbsentTime!.hour,
              minute: model.markedAbsentTime!.minute,
              second: model.markedAbsentTime!.second,
              nano: model.markedAbsentTime!.nano,
            )
          : null,
      markedAbsentByName: model.markedAbsentByName,
      absenceNote: model.absenceNote,
      markAbsentMethod: model.markAbsentMethod,
      absentDays: model.absentDays,
      absenceRecordCode: model.absenceRecordCode,
    );
  }

  @override
  Future<student_absent.StudentAttendanceAbsentFormPage>
  getStudentAbsentFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
      studentCrossClass: true,
    );
    final pageModel = await _remoteDataSource.getStudentAbsentFormList(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    return _mapStudentAbsentFormPageModelToEntity(pageModel);
  }

  @override
  Future<student_absent.StudentAttendanceAbsentFormPage>
  getStudentAbsentRecordsActivity({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? studentCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
      studentCrossClass: true,
    );
    final pageModel = await _remoteDataSource.getStudentAbsentRecordsActivity(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomQuery.classroomCodes,
      tagCodes: tagCodes,
      studentCodes: studentCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
    );

    return _mapStudentAbsentFormPageModelToEntity(pageModel);
  }

  @override
  Future<void> deleteStudentAbsenceRecord({
    required String absenceRecordCode,
    required String staffCode,
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: true,
    );
    await _remoteDataSource.deleteStudentAbsenceRecord(
      absenceRecordCode: absenceRecordCode,
      staffCode: staffCode,
      allowedClassroomCodes: allowed,
    );
  }

  @override
  Future<void> deleteStudentAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: true,
    );
    await _remoteDataSource.deleteStudentAttendanceRecord(
      attendanceRecordCode: attendanceRecordCode,
      staffCode: staffCode,
      allowedClassroomCodes: allowed,
    );
  }

  @override
  Future<void> deleteStaffAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes();
    await _remoteDataSource.deleteStaffAttendanceRecord(
      attendanceRecordCode: attendanceRecordCode,
      staffCode: staffCode,
      allowedClassroomCodes: allowed,
    );
  }

  @override
  Future<void> deleteStaffAbsenceRecord({
    required String absenceRecordCode,
    required String staffCode,
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes();
    await _remoteDataSource.deleteStaffAbsenceRecord(
      absenceRecordCode: absenceRecordCode,
      staffCode: staffCode,
      allowedClassroomCodes: allowed,
    );
  }

  @override
  Future<String> markStudentsAbsent({
    required String staffCode,
    required List<String> studentCodes,
    required String absenceFromDate,
    required String absenceToDate,
    required String absenceReason,
    required Map<String, String> absenceNotes,
    required String classroomCode,
    required Map<String, bool> isExpectedTodayByStudentCode,
    String markAbsentMethod = 'APP',
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: true,
    );
    final response = await _remoteDataSource.markStudentsAbsent(
      request: MarkAbsentRequestModel(
        staffCode: staffCode,
        studentCodes: studentCodes,
        absenceFromDate: absenceFromDate,
        absenceToDate: absenceToDate,
        absenceReason: absenceReason,
        absenceNotes: absenceNotes,
        classroomCode: classroomCode,
        isExpectedTodayByStudentCode: isExpectedTodayByStudentCode,
        markAbsentMethod: markAbsentMethod,
      ),
      allowedClassroomCodes: allowed,
    );

    return response.message.isNotEmpty
        ? response.message
        : 'Marked absent successfully';
  }

  @override
  Future<String> markStaffAbsent({
    required String staffCode,
    required List<String> staffCodes,
    required String absenceFromDate,
    required String absenceToDate,
    required String absenceReason,
    required String absenceType,
    required Map<String, String> absenceNotes,
    required Map<String, bool> isExpectedTodayByStaffCode,
    String markAbsentMethod = 'APP',
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes();
    final response = await _remoteDataSource.markStaffAbsent(
      request: StaffMarkAbsentRequestModel(
        staffCode: staffCode,
        staffCodes: staffCodes,
        absenceFromDate: absenceFromDate,
        absenceToDate: absenceToDate,
        absenceReason: absenceReason,
        absenceType: absenceType,
        absenceNotes: absenceNotes,
        isExpectedTodayByStaffCode: isExpectedTodayByStaffCode,
        markAbsentMethod: markAbsentMethod,
      ),
      allowedClassroomCodes: allowed,
    );

    return response.message.isNotEmpty
        ? response.message
        : 'Staff marked absent successfully';
  }

  @override
  Future<student_absent.StudentAttendanceAbsentFormPage>
  getStudentAttendanceAbsentToggleView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
      studentCrossClass: true,
    );
    final pageModel = await _remoteDataSource
        .getStudentAttendanceAbsentToggleView(
          fromAbsenceDate: fromAbsenceDate,
          toAbsenceDate: toAbsenceDate,
          classroomCodes: classroomQuery.classroomCodes,
          tagCodes: tagCodes,
          search: search,
          page: page,
          size: size,
          allowedClassroomCodes: classroomQuery.allowedClassroomCodes,
        );

    return _mapStudentAbsentFormPageModelToEntity(pageModel);
  }

  @override
  Future<StudentAttendanceExpectedSummary> getStudentAttendanceExpectedSummary({
    String? classroomCode,
    bool schoolWide = false,
    bool forceRefresh = false,
  }) async {
    if (schoolWide) {
      final cacheKey = _studentAttendanceSummaryCacheKey('school_wide');
      final cached = forceRefresh
          ? null
          : await _cacheManager.loadCache(cacheKey);
      if (cached != null) {
        return StudentAttendanceExpectedSummary(
          expected: cached['expected'] as int? ?? 0,
          present: cached['present'] as int? ?? 0,
          absent: cached['absent'] as int? ?? 0,
          signOut: cached['signOut'] as int? ?? 0,
          notMarked: cached['notMarked'] as int? ?? 0,
        );
      }

      final model = await _remoteDataSource
          .getStudentAttendanceExpectedSummaryCard(classroomCode: null);

      await _cacheManager.saveCache(cacheKey, {
        'expected': model.expected,
        'present': model.present,
        'absent': model.absent,
        'signOut': model.signOut,
        'notMarked': model.notMarked,
      });

      return StudentAttendanceExpectedSummary(
        expected: model.expected,
        present: model.present,
        absent: model.absent,
        signOut: model.signOut,
        notMarked: model.notMarked,
      );
    }

    final fromArg = classroomCode?.trim() ?? '';
    if (fromArg.isNotEmpty) {
      final cacheKey = _studentAttendanceSummaryCacheKey(fromArg);
      final cached = forceRefresh
          ? null
          : await _cacheManager.loadCache(cacheKey);
      if (cached != null) {
        return StudentAttendanceExpectedSummary(
          expected: cached['expected'] as int? ?? 0,
          present: cached['present'] as int? ?? 0,
          absent: cached['absent'] as int? ?? 0,
          signOut: cached['signOut'] as int? ?? 0,
          notMarked: cached['notMarked'] as int? ?? 0,
        );
      }

      final model = await _remoteDataSource
          .getStudentAttendanceExpectedSummaryCard(classroomCode: fromArg);

      await _cacheManager.saveCache(cacheKey, {
        'expected': model.expected,
        'present': model.present,
        'absent': model.absent,
        'signOut': model.signOut,
        'notMarked': model.notMarked,
      });

      return StudentAttendanceExpectedSummary(
        expected: model.expected,
        present: model.present,
        absent: model.absent,
        signOut: model.signOut,
        notMarked: model.notMarked,
      );
    }

    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: true,
    );
    final effective = _effectiveClassroomCodeForSummary(null, allowed);
    final cacheKey = _studentAttendanceSummaryCacheKey(effective);

    final cached = forceRefresh
        ? null
        : await _cacheManager.loadCache(cacheKey);
    if (cached != null) {
      return StudentAttendanceExpectedSummary(
        expected: cached['expected'] as int? ?? 0,
        present: cached['present'] as int? ?? 0,
        absent: cached['absent'] as int? ?? 0,
        signOut: cached['signOut'] as int? ?? 0,
        notMarked: cached['notMarked'] as int? ?? 0,
      );
    }

    final model = await _remoteDataSource
        .getStudentAttendanceExpectedSummaryCard(classroomCode: effective);

    await _cacheManager.saveCache(cacheKey, {
      'expected': model.expected,
      'present': model.present,
      'absent': model.absent,
      'signOut': model.signOut,
      'notMarked': model.notMarked,
    });

    return StudentAttendanceExpectedSummary(
      expected: model.expected,
      present: model.present,
      absent: model.absent,
      signOut: model.signOut,
      notMarked: model.notMarked,
    );
  }

  @override
  Future<StudentAttendanceExpectedSummary> getStaffAttendanceExpectedSummary({
    String? classroomCode,
    bool schoolWide = false,
    bool forceRefresh = false,
  }) async {
    if (schoolWide) {
      final cacheKey = _staffAttendanceSummaryCacheKey('school_wide');
      final cached = forceRefresh
          ? null
          : await _cacheManager.loadCache(cacheKey);
      if (cached != null) {
        return StudentAttendanceExpectedSummary(
          expected: cached['expected'] as int? ?? 0,
          present: cached['present'] as int? ?? 0,
          absent: cached['absent'] as int? ?? 0,
          signOut: cached['signOut'] as int? ?? 0,
          notMarked: cached['notMarked'] as int? ?? 0,
        );
      }

      final model = await _remoteDataSource
          .getStaffAttendanceExpectedSummaryCard(classroomCode: null);

      await _cacheManager.saveCache(cacheKey, {
        'expected': model.expected,
        'present': model.present,
        'absent': model.absent,
        'signOut': model.signOut,
        'notMarked': model.notMarked,
      });

      return StudentAttendanceExpectedSummary(
        expected: model.expected,
        present: model.present,
        absent: model.absent,
        signOut: model.signOut,
        notMarked: model.notMarked,
      );
    }

    final fromArg = classroomCode?.trim() ?? '';
    if (fromArg.isNotEmpty) {
      final cacheKey = _staffAttendanceSummaryCacheKey(fromArg);
      final cached = forceRefresh
          ? null
          : await _cacheManager.loadCache(cacheKey);
      if (cached != null) {
        return StudentAttendanceExpectedSummary(
          expected: cached['expected'] as int? ?? 0,
          present: cached['present'] as int? ?? 0,
          absent: cached['absent'] as int? ?? 0,
          signOut: cached['signOut'] as int? ?? 0,
          notMarked: cached['notMarked'] as int? ?? 0,
        );
      }

      final model = await _remoteDataSource
          .getStaffAttendanceExpectedSummaryCard(classroomCode: fromArg);

      await _cacheManager.saveCache(cacheKey, {
        'expected': model.expected,
        'present': model.present,
        'absent': model.absent,
        'signOut': model.signOut,
        'notMarked': model.notMarked,
      });

      return StudentAttendanceExpectedSummary(
        expected: model.expected,
        present: model.present,
        absent: model.absent,
        signOut: model.signOut,
        notMarked: model.notMarked,
      );
    }

    final allowed = await _attendanceAllowedClassroomCodes();
    final effective = _effectiveClassroomCodeForSummary(null, allowed);
    final cacheKey = _staffAttendanceSummaryCacheKey(effective);

    final cached = forceRefresh
        ? null
        : await _cacheManager.loadCache(cacheKey);
    if (cached != null) {
      return StudentAttendanceExpectedSummary(
        expected: cached['expected'] as int? ?? 0,
        present: cached['present'] as int? ?? 0,
        absent: cached['absent'] as int? ?? 0,
        signOut: cached['signOut'] as int? ?? 0,
        notMarked: cached['notMarked'] as int? ?? 0,
      );
    }

    final model = await _remoteDataSource.getStaffAttendanceExpectedSummaryCard(
      classroomCode: effective,
    );

    await _cacheManager.saveCache(cacheKey, {
      'expected': model.expected,
      'present': model.present,
      'absent': model.absent,
      'signOut': model.signOut,
      'notMarked': model.notMarked,
    });

    return StudentAttendanceExpectedSummary(
      expected: model.expected,
      present: model.present,
      absent: model.absent,
      signOut: model.signOut,
      notMarked: model.notMarked,
    );
  }

  @override
  Future<String?> getStaffTodaySignInStatus(String staffCode) async {
    final allowed = await _attendanceAllowedClassroomCodes();
    final map = await _remoteDataSource.getStaffSignInStatus(
      staffCodes: <String>[staffCode],
      allowedClassroomCodes: allowed,
    );
    return map[staffCode];
  }

  @override
  Future<Map<String, String>> getStaffTodaySignInStatusMap(
    List<String> staffCodes,
  ) async {
    final codes = staffCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (codes.isEmpty) return <String, String>{};
    final allowed = await _attendanceAllowedClassroomCodes();
    return _remoteDataSource.getStaffSignInStatus(
      staffCodes: codes,
      allowedClassroomCodes: allowed,
    );
  }

  @override
  Future<String?> getStudentTodaySignInStatus(String studentCode) async {
    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: true,
    );
    final map = await _remoteDataSource.getStudentSignInStatus(
      studentCodes: <String>[studentCode],
      allowedClassroomCodes: allowed,
    );
    return map[studentCode];
  }

  @override
  Future<Map<String, String>> getStudentTodaySignInStatusMap(
    List<String> studentCodes,
  ) async {
    final codes = studentCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (codes.isEmpty) return <String, String>{};
    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: true,
    );
    return _remoteDataSource.getStudentSignInStatus(
      studentCodes: codes,
      allowedClassroomCodes: allowed,
    );
  }

  @override
  Future<Map<String, bool>> getStudentSignInStatusAtTime({
    required String classroomCode,
    required List<String> studentCodes,
    required DateTime instantUtc,
  }) {
    return _remoteDataSource.getStudentSignInStatusAtTime(
      classroomCode: classroomCode,
      studentCodes: studentCodes,
      instantUtc: instantUtc,
    );
  }

  @override
  Future<Map<String, bool>> getStaffSignInStatusAtTime({
    required String classroomCode,
    required List<String> staffCodes,
    required DateTime instantUtc,
  }) {
    return _remoteDataSource.getStaffSignInStatusAtTime(
      classroomCode: classroomCode,
      staffCodes: staffCodes,
      instantUtc: instantUtc,
    );
  }

  @override
  Future<String> updateStudentAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
    DateTime? signedInAt,
    DateTime? signedOutAt,
    String? originalClassroomCode,
    String? currentClassroomCode,
    String? notes,
    String? timeZone,
  }) async {
    final tz = await _effectiveSchoolTimeZone(timeZone);
    final recordCode = attendanceRecordCode.trim().toUpperCase();
    final isTransferRecord = recordCode.startsWith('SCTR_');
    final payload = <String, dynamic>{
      'staffCode': staffCode,
      'timeZone': tz,
      if (signedInAt != null)
        'signedInAt': signedInAt.toUtc().toIso8601String(),
      if (signedOutAt != null)
        'signedOutAt': signedOutAt.toUtc().toIso8601String(),
      if (!isTransferRecord && signedInAt != null) 'signedInMethod': 'APP',
      if (!isTransferRecord && signedOutAt != null) 'signedOutMethod': 'APP',
      if (originalClassroomCode != null &&
          originalClassroomCode.trim().isNotEmpty)
        'originalClassroomCode': originalClassroomCode.trim(),
      if (currentClassroomCode != null &&
          currentClassroomCode.trim().isNotEmpty)
        'currentClassroomCode': currentClassroomCode.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    // The backend validates the editing teacher's classroom assignment
    // against this list (mirrors markStudentsAbsent/markStaffAbsent).
    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: true,
    );

    return _remoteDataSource.updateStudentAttendanceRecord(
      attendanceRecordCode: attendanceRecordCode,
      payload: payload,
      allowedClassroomCodes: allowed,
    );
  }

  @override
  Future<String> createStudentSignInRecords({
    required String attendanceDate,
    required String staffCode,
    required List<String> studentCodes,
    String? classroomCode,
    Map<String, String>? classroomCodeByStudentCode,
    String method = 'APP',
    bool isExpected = true,
    double latitude = 0,
    double longitude = 0,
    bool withinGeofence = false,
    String? timeZone,
    DateTime? occurredAt,
  }) async {
    final tz = await _effectiveSchoolTimeZone(timeZone);
    final payload = <String, dynamic>{
      'attendanceDate': attendanceDate,
      'staffCode': staffCode,
      'studentCodes': studentCodes,
      'classroomCode': classroomCode,
      if (classroomCodeByStudentCode != null &&
          classroomCodeByStudentCode.isNotEmpty)
        'classroomCodeByStudentCode': classroomCodeByStudentCode,
      'method': method,
      'isExpected': isExpected,
      'latitude': latitude,
      'longitude': longitude,
      'withinGeofence': withinGeofence,
      'timeZone': tz,
      'occurredAt': occurredAt?.toUtc().toIso8601String(),
    };

    final allowed = await _attendanceAllowedClassroomCodes(
      studentCrossClass: true,
    );
    return _remoteDataSource.createStudentSignInRecords(
      payload: payload,
      allowedClassroomCodes: allowed,
    );
  }

  /// Parses a raw attendance-mutation response into an [AttendanceActionResult].
  ///
  /// Also opportunistically extracts `currentClassroomCode`/
  /// `primaryClassroomCode` when the backend includes them (e.g. on a
  /// transfer response) so callers like the transfer form can read the
  /// staff's post-mutation classroom straight from this same response
  /// instead of inferring it from the request payload. Both stay null for
  /// action types that don't return them (sign-in/out, mark-absent).
  AttendanceActionResult _attendanceActionResult(
    Map<String, dynamic>? data, {
    required String defaultMessage,
  }) {
    var success = false;
    var message = defaultMessage;
    String? currentClassroomCode;
    String? primaryClassroomCode;
    if (data != null) {
      success = data['success'] as bool? ?? false;
      if (data['message'] != null) {
        message = data['message'].toString();
      }
      currentClassroomCode = (data['currentClassroomCode'] as String?)?.trim();
      primaryClassroomCode = (data['primaryClassroomCode'] as String?)?.trim();
    }
    if (success) {
      AttendanceEvents.notifyChanged();
    }
    return AttendanceActionResult(
      success: success,
      message: message,
      currentClassroomCode: currentClassroomCode?.isNotEmpty == true
          ? currentClassroomCode
          : null,
      primaryClassroomCode: primaryClassroomCode?.isNotEmpty == true
          ? primaryClassroomCode
          : null,
    );
  }

  @override
  Future<AttendanceActionResult> submitStudentSignIn({
    required StudentSignInRequest request,
    required bool isParent,
    String? idempotencyKey,
  }) async {
    final body = request.toPayload();
    Map<String, dynamic>? queryParameters;
    if (isParent) {
      final g = (body['guardianCode'] ?? '').toString().trim();
      if (g.isNotEmpty) {
        // Send in both query param (backend requirement) and request body (API schema).
        queryParameters = {'guardianCode': g};
        body['guardianCode'] = g;
      }
    }
    // Skip classroom codes for kiosk mode
    final method = (body['method'] ?? '').toString().trim();
    if (method != 'KIOSK') {
      await applyStudentAllowedClassroomCodesToAttendanceBody(body, _storage);
    }
    final data = await _remoteDataSource.postStudentSignIn(
      body: body,
      queryParameters: queryParameters,
      isParent: isParent,
      idempotencyKey: idempotencyKey,
    );
    return _attendanceActionResult(
      data,
      defaultMessage: 'Signed-In successfully',
    );
  }

  @override
  Future<AttendanceActionResult> submitStudentSignOut({
    required StudentSignOutRequest request,
    required bool isParent,
    String? idempotencyKey,
  }) async {
    final body = request.toPayload();
    Map<String, dynamic>? queryParameters;
    if (isParent) {
      final g = (body['guardianCode'] ?? '').toString().trim();
      if (g.isNotEmpty) {
        // Send in both query param (backend requirement) and request body (API schema).
        queryParameters = {'guardianCode': g};
        body['guardianCode'] = g;
      }
    }
    // Skip classroom codes for kiosk mode
    final method = (body['method'] ?? '').toString().trim();
    if (method != 'KIOSK') {
      await applyStudentAllowedClassroomCodesToAttendanceBody(body, _storage);
    }
    final data = await _remoteDataSource.postStudentSignOut(
      body: body,
      queryParameters: queryParameters,
      isParent: isParent,
      idempotencyKey: idempotencyKey,
    );
    return _attendanceActionResult(
      data,
      defaultMessage: 'Signed-Out successfully',
    );
  }

  @override
  Future<AttendanceActionResult> submitStudentTransfer({
    required StudentTransferRequest request,
    String? idempotencyKey,
  }) async {
    final body = request.toPayload();
    await applyStudentAllowedClassroomCodesToAttendanceBody(body, _storage);
    final data = await _remoteDataSource.postStudentTransfer(
      body: body,
      idempotencyKey: idempotencyKey,
    );
    return _attendanceActionResult(
      data,
      defaultMessage: 'Transfer successfully',
    );
  }

  @override
  Future<AttendanceActionResult> submitStaffSignIn({
    required StaffSignInRequest request,
    required bool isSelf,
    String? idempotencyKey,
  }) async {
    final body = request.toPayload();
    // The self sign-in endpoint does not accept allowedClassroomCodes — only
    // the admin bulk endpoint uses that field for classroom-scoped authorization.
    if (!isSelf) {
      await applyAllowedClassroomCodesToAttendanceBody(body, _storage);
    }
    final data = await _remoteDataSource.postStaffSignIn(
      body: body,
      isSelf: isSelf,
      idempotencyKey: idempotencyKey,
    );
    return _attendanceActionResult(
      data,
      defaultMessage: 'Signed-In successfully',
    );
  }

  @override
  Future<AttendanceActionResult> submitStaffSignOut({
    required StaffSignOutRequest request,
    bool isSelf = false,
    String? idempotencyKey,
  }) async {
    final body = request.toPayload();
    // The self sign-out endpoint does not accept allowedClassroomCodes — only
    // the admin bulk endpoint uses that field for classroom-scoped authorization.
    if (!isSelf) {
      await applyAllowedClassroomCodesToAttendanceBody(body, _storage);
    }
    final data = await _remoteDataSource.postStaffSignOut(
      body: body,
      isSelf: isSelf,
      idempotencyKey: idempotencyKey,
    );
    return _attendanceActionResult(
      data,
      defaultMessage: 'Signed-Out successfully',
    );
  }

  @override
  Future<AttendanceActionResult> submitStaffTransfer({
    required StaffTransferRequest request,
    String? idempotencyKey,
  }) async {
    final body = request.toPayload();
    await applyAllowedClassroomCodesToAttendanceBody(body, _storage);
    final data = await _remoteDataSource.postStaffTransfer(
      body: body,
      idempotencyKey: idempotencyKey,
    );
    return _attendanceActionResult(
      data,
      defaultMessage: 'Transferred successfully',
    );
  }

  @override
  Future<void> updateStaffAttendanceDailyRecord({
    required String attendanceCode,
    required StaffAttendanceDailyUpdateRequest request,
  }) async {
    // The datasource still returns the raw response map, but no caller consumes
    // it — the patch succeeding (no throw) is the only signal callers use.
    await _remoteDataSource.patchStaffAttendanceDailyRecord(
      rowCode: attendanceCode,
      body: request.toPayload(),
    );
  }

  @override
  Future<StudentAttendanceProfileResponse?> fetchStudentAttendanceProfile({
    required AttendanceProfileQuery query,
  }) async {
    final raw = await _remoteDataSource.getStudentAttendanceProfileRaw(
      queryParameters: query.toQueryParameters(),
    );
    return raw == null
        ? null
        : StudentAttendanceProfileResponseModel.fromJson(raw).toEntity();
  }

  @override
  Future<StudentAttendanceProfileAbsentToggleResponse?>
  fetchStudentAttendanceProfileAbsentToggle({
    required AttendanceProfileAbsentToggleQuery query,
  }) async {
    final raw = await _remoteDataSource
        .getStudentAttendanceProfileAbsentToggleRaw(
          queryParameters: query.toQueryParameters(),
        );
    return raw == null
        ? null
        : StudentAttendanceProfileAbsentToggleResponseModel.fromJson(
            raw,
          ).toEntity();
  }

  @override
  Future<StaffAttendanceProfileResponse?> fetchStaffAttendanceProfile({
    required AttendanceProfileQuery query,
  }) async {
    final raw = await _remoteDataSource.getStaffAttendanceProfileRaw(
      queryParameters: query.toQueryParameters(),
    );
    return raw == null
        ? null
        : StaffAttendanceProfileResponseModel.fromJson(raw).toEntity();
  }

  @override
  Future<StaffAttendanceProfileAbsentToggleResponse?>
  fetchStaffAttendanceProfileAbsentToggle({
    required AttendanceProfileAbsentToggleQuery query,
  }) async {
    final raw = await _remoteDataSource
        .getStaffAttendanceProfileAbsentToggleRaw(
          queryParameters: query.toQueryParameters(),
        );
    return raw == null
        ? null
        : StaffAttendanceProfileAbsentToggleResponseModel.fromJson(
            raw,
          ).toEntity();
  }

  @override
  Future<StudentAttendanceAbsentViewResponse?> getStudentAttendanceAbsentView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    final classroomQuery = await _resolveAttendanceClassroomQueryParams(
      classroomCodes,
      studentCrossClass: true,
    );

    final queryParameters = <String, dynamic>{
      'fromAbsenceDate': fromAbsenceDate,
      'toAbsenceDate': toAbsenceDate,
      'page': page,
      'size': size,
      'sort': sort ?? <String>['studentName,asc'],
    };

    if (classroomQuery.classroomCodes != null &&
        classroomQuery.classroomCodes!.isNotEmpty) {
      queryParameters['classroomCodes'] = classroomQuery.classroomCodes;
    }
    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (classroomQuery.allowedClassroomCodes.isNotEmpty) {
      queryParameters['allowedClassroomCodes'] =
          classroomQuery.allowedClassroomCodes;
    }

    queryParameters['pageable.page'] = page;
    queryParameters['pageable.size'] = size;
    queryParameters['pageable.sort'] =
        sort ?? const <String>['studentName,asc'];

    final raw = await _remoteDataSource.getStudentAttendanceAbsentViewRaw(
      queryParameters: queryParameters,
    );
    return raw == null
        ? null
        : StudentAttendanceAbsentViewResponseModel.fromJson(raw).toEntity();
  }

  @override
  Future<QrValidationResult> validateQrCode({
    required String schoolCode,
    required String qrToken,
    required String useCase,
  }) async {
    final model = await _remoteDataSource.validateQrCode(
      schoolCode: schoolCode,
      qrToken: qrToken,
      useCase: useCase,
    );
    return model.toEntity();
  }
}
