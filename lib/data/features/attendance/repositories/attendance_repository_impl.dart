import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/attendance_classroom_scope.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/attendance/entities/student_attendance_daily.dart';
import '../../../../domain/features/attendance/entities/student_attendance_custom.dart';
import '../../../../domain/features/attendance/entities/student_attendance_expected_summary.dart';
import '../../../../domain/features/attendance/entities/staff_attendance_daily.dart';
import '../../../../domain/features/attendance/entities/staff_attendance_absent.dart'
    as staff_absent;
import '../../../../domain/features/attendance/entities/student_attendance_absent_form.dart'
    as student_absent;
import '../../../../domain/features/attendance/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/student_absence_record_models.dart';
import '../models/student_attendance_models.dart';
import '../models/staff_absence_record_models.dart';

class AttendanceRepositoryImpl
    implements AttendanceRepository, AttendanceRepositoryWithCache {
  AttendanceRepositoryImpl(this._remoteDataSource, StorageService storageService)
      : _storage = storageService,
        _cacheManager = CacheManager(storageService);

  final AttendanceRemoteDataSource _remoteDataSource;
  final StorageService _storage;
  final CacheManager _cacheManager;

  Future<List<String>> _attendanceAllowedClassroomCodes() =>
      resolveAttendanceAllowedClassroomCodes(storage: _storage);

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

  // Cache key for the student expected-attendance summary card.
  static String _studentAttendanceSummaryCacheKey() =>
      CacheManager.buildCacheKey(
        feature: 'attendance',
        resource: 'student_summary',
        identifier: 'default',
      );

  // Cache key for the staff expected-attendance summary card.
  static String _staffAttendanceSummaryCacheKey() =>
      CacheManager.buildCacheKey(
        feature: 'attendance',
        resource: 'staff_summary',
        identifier: 'default',
      );

  @override
  Future<StudentAttendanceDailyPage> getStudentAttendanceDaily({
    required String attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes();
    // 1. Call remote datasource
    final pageModel = await _remoteDataSource.getStudentAttendanceDaily(
      attendanceDate: attendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
    );

    // 2. Cache only first page (never store classroom-scoped staff payloads here).
    if (page == 0 && allowed.isEmpty) {
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
    final allowed = await _attendanceAllowedClassroomCodes();
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
      StudentAttendanceDailyPageModel model) {
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
      StudentAttendanceDailyItemModel model) {
    return StudentAttendanceDailyItem(
      attendanceRecordCode: model.attendanceRecordCode,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStudentAttendanceCustom(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
    );

    if (page == 0 && allowed.isEmpty) {
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
    final allowed = await _attendanceAllowedClassroomCodes();
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStudentSignInFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStudentSignOutFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStudentTransferFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStaffAttendanceDaily(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStaffAttendanceCustom(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStaffAttendanceAbsent(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStaffAbsentFormList(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStaffAttendanceAbsentToggleView(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStaffSignInFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStaffSignOutFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStaffTransferFormList(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
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
      absentDays: model.absentDays,
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
      absentDays: model.absentDays,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel = await _remoteDataSource.getStudentAbsentFormList(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
    );

    return _mapStudentAbsentFormPageModelToEntity(pageModel);
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
  }) async {
    final allowed = await _attendanceAllowedClassroomCodes();
    final response = await _remoteDataSource.markStudentsAbsent(
      request: MarkAbsentRequestModel(
        staffCode: staffCode,
        studentCodes: studentCodes,
        absenceFromDate: absenceFromDate,
        absenceToDate: absenceToDate,
        absenceReason: absenceReason,
        absenceNotes: absenceNotes,
        classroomCode: classroomCode,
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
    final allowed = await _attendanceAllowedClassroomCodes();
    final pageModel =
        await _remoteDataSource.getStudentAttendanceAbsentToggleView(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      allowedClassroomCodes: allowed,
    );

    return _mapStudentAbsentFormPageModelToEntity(pageModel);
  }

  @override
  Future<StudentAttendanceExpectedSummary>
      getStudentAttendanceExpectedSummary() async {
    final allowed = await _attendanceAllowedClassroomCodes();
    // 1. Try cache only when not classroom-scoped (empty allowed list).
    if (allowed.isEmpty) {
      final cached = await _cacheManager.loadCache(
        _studentAttendanceSummaryCacheKey(),
      );
      if (cached != null) {
        return StudentAttendanceExpectedSummary(
          expected: cached['expected'] as int? ?? 0,
          present: cached['present'] as int? ?? 0,
          absent: cached['absent'] as int? ?? 0,
          signOut: cached['signOut'] as int? ?? 0,
          notMarked: cached['notMarked'] as int? ?? 0,
        );
      }
    }

    // 2. Fallback to API and cache the result.
    final model =
        await _remoteDataSource.getStudentAttendanceExpectedSummaryCard(
      allowedClassroomCodes: allowed,
    );

    if (allowed.isEmpty) {
      await _cacheManager.saveCache(
        _studentAttendanceSummaryCacheKey(),
        {
          'expected': model.expected,
          'present': model.present,
          'absent': model.absent,
          'signOut': model.signOut,
          'notMarked': model.notMarked,
        },
      );
    }

    return StudentAttendanceExpectedSummary(
      expected: model.expected,
      present: model.present,
      absent: model.absent,
      signOut: model.signOut,
      notMarked: model.notMarked,
    );
  }

  @override
  Future<StudentAttendanceExpectedSummary>
      getStaffAttendanceExpectedSummary() async {
    final allowed = await _attendanceAllowedClassroomCodes();
    if (allowed.isEmpty) {
      final cached = await _cacheManager.loadCache(
        _staffAttendanceSummaryCacheKey(),
      );
      if (cached != null) {
        return StudentAttendanceExpectedSummary(
          expected: cached['expected'] as int? ?? 0,
          present: cached['present'] as int? ?? 0,
          absent: cached['absent'] as int? ?? 0,
          signOut: cached['signOut'] as int? ?? 0,
          notMarked: cached['notMarked'] as int? ?? 0,
        );
      }
    }

    // 2. Fallback to API and cache the result.
    final model =
        await _remoteDataSource.getStaffAttendanceExpectedSummaryCard(
      allowedClassroomCodes: allowed,
    );

    if (allowed.isEmpty) {
      await _cacheManager.saveCache(
        _staffAttendanceSummaryCacheKey(),
        {
          'expected': model.expected,
          'present': model.present,
          'absent': model.absent,
          'signOut': model.signOut,
          'notMarked': model.notMarked,
        },
      );
    }

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
    final codes = staffCodes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (codes.isEmpty) return <String, String>{};
    final allowed = await _attendanceAllowedClassroomCodes();
    return _remoteDataSource.getStaffSignInStatus(
      staffCodes: codes,
      allowedClassroomCodes: allowed,
    );
  }

  @override
  Future<String?> getStudentTodaySignInStatus(String studentCode) async {
    final allowed = await _attendanceAllowedClassroomCodes();
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
    final codes =
        studentCodes.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (codes.isEmpty) return <String, String>{};
    final allowed = await _attendanceAllowedClassroomCodes();
    return _remoteDataSource.getStudentSignInStatus(
      studentCodes: codes,
      allowedClassroomCodes: allowed,
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
    final payload = <String, dynamic>{
      'staffCode': staffCode,
      // Backend expects ISO8601 with timezone (e.g., "2026-03-04T16:31:09.002Z")
      'signedInAt': signedInAt?.toIso8601String(),
      'signedOutAt': signedOutAt?.toIso8601String(),
      'signedInMethod': 'APP',
      'signedOutMethod': 'APP',
      // Location/geofence fields are currently not captured in the UI.
      // Send defaults as per backend schema.
      'signedInLocationLat': 0,
      'signedInLocationLong': 0,
      'signedInWithinGeofence': true,
      'signedOutLocationLat': 0,
      'signedOutLocationLong': 0,
      'signedOutWithinGeofence': true,
      'originalClassroomCode': originalClassroomCode,
      'currentClassroomCode': currentClassroomCode,
      'notes': notes,
      'timeZone': timeZone,
    };

    final allowed = await _attendanceAllowedClassroomCodes();
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
      'timeZone': timeZone,
      'occurredAt': occurredAt?.toIso8601String(),
    };

    final allowed = await _attendanceAllowedClassroomCodes();
    return _remoteDataSource.createStudentSignInRecords(
      payload: payload,
      allowedClassroomCodes: allowed,
    );
  }
}
