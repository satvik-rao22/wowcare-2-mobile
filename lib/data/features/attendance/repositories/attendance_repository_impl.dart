import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/attendance/entities/student_attendance_daily.dart';
import '../../../../domain/features/attendance/entities/student_attendance_custom.dart';
import '../../../../domain/features/attendance/entities/staff_attendance_daily.dart';
import '../../../../domain/features/attendance/entities/staff_attendance_absent.dart'
    as staff_absent;
import '../../../../domain/features/attendance/entities/student_attendance_absent_form.dart'
    as student_absent;
import '../../../../domain/features/attendance/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/student_absence_record_models.dart';
import '../models/student_attendance_models.dart';

class AttendanceRepositoryImpl
    implements AttendanceRepository, AttendanceRepositoryWithCache {
  AttendanceRepositoryImpl(
    this._remoteDataSource,
    StorageService storageService,
  ) : _cacheManager = CacheManager(storageService);

  final AttendanceRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

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

  @override
  Future<StudentAttendanceDailyPage> getStudentAttendanceDaily({
    required String attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    // 1. Call remote datasource
    final pageModel = await _remoteDataSource.getStudentAttendanceDaily(
      attendanceDate: attendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
    );

    // 2. Cache only first page
    if (page == 0) {
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
      signedOutAt: model.signedOutAt,
      signedOutTime: model.signedOutTime != null
          ? StudentAttendanceTime(
              hour: model.signedOutTime!.hour,
              minute: model.signedOutTime!.minute,
              second: model.signedOutTime!.second,
              nano: model.signedOutTime!.nano,
            )
          : null,
      classroomCode: model.classroomCode,
      tagCodes: model.tagCodes,
      tagNames: model.tagNames,
      duration: model.duration,
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
    final pageModel = await _remoteDataSource.getStudentAttendanceCustom(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
    );

    if (page == 0) {
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
    final pageModel = await _remoteDataSource.getStudentSignInFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
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
    final pageModel = await _remoteDataSource.getStudentSignOutFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
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
    final pageModel = await _remoteDataSource.getStudentTransferFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
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
    final pageModel = await _remoteDataSource.getStaffAttendanceDaily(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
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
    final pageModel = await _remoteDataSource.getStaffAttendanceCustom(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
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
    final pageModel = await _remoteDataSource.getStaffAttendanceAbsent(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
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
    final pageModel = await _remoteDataSource.getStaffSignInFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
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
    final pageModel = await _remoteDataSource.getStaffSignOutFormList(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
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
    final pageModel = await _remoteDataSource.getStaffTransferFormList(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
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
    final pageModel = await _remoteDataSource.getStudentAbsentFormList(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
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
    );

    return response.message.isNotEmpty
        ? response.message
        : 'Marked absent successfully';
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
    final pageModel = await _remoteDataSource
        .getStudentAttendanceAbsentToggleView(
          fromAbsenceDate: fromAbsenceDate,
          toAbsenceDate: toAbsenceDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
          page: page,
          size: size,
        );

    return _mapStudentAbsentFormPageModelToEntity(pageModel);
  }
}
