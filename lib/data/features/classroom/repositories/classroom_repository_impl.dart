import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/entities/classroom_details.dart';
import '../../../../domain/features/classroom/entities/ratio_monitoring_classroom.dart';
import '../../../../domain/features/classroom/entities/school_capacity.dart';
import '../../../../domain/features/classroom/entities/classroom_count.dart';
import '../../../../domain/features/classroom/entities/school_fte.dart';
import '../../../../domain/features/classroom/repositories/classroom_repository.dart';
import '../../../../domain/features/student_classroom/entities/student_classroom_item.dart';
import '../../../../domain/features/student_classroom/repositories/student_classroom_repository.dart';
import '../datasources/classroom_remote_datasource.dart';

class ClassroomRepositoryImpl implements ClassroomRepository {
  ClassroomRepositoryImpl(
    this._remoteDataSource,
    this._studentClassroomRepository,
    StorageService storageService,
  ) : _cacheManager = CacheManager(storageService);

  final ClassroomRemoteDataSource _remoteDataSource;
  final StudentClassroomRepository _studentClassroomRepository;
  final CacheManager _cacheManager;

  @override
  Future<List<Classroom>> getActiveClassrooms({
    required String schoolCode,
    bool onlyTypeClassroom = true,
    String? typeOverride,
  }) async {
    final response = await _remoteDataSource.getActiveClassrooms(
      schoolCode: schoolCode,
      onlyTypeClassroom: onlyTypeClassroom,
      typeOverride: typeOverride,
    );

    return response.items
        .map(
          (model) => Classroom(
            code: model.code,
            name: model.name,
          ),
        )
        .toList();
  }

  @override
  Future<ClassroomDetails> getClassroomByCode({
    required String code,
  }) async {
    final response = await _remoteDataSource.getClassroomByCode(code: code);
    final details = response.data;

    if (details == null) {
      throw Exception('Classroom details not found');
    }

    return ClassroomDetails(
      code: details.code,
      name: details.name,
      capacity: details.capacity,
      studentsPerTeacher: details.studentsPerTeacher,
      minAgeTotalMonths: details.minAgeTotalMonths,
      maxAgeTotalMonths: details.maxAgeTotalMonths,
      type: details.type,
      school: details.school,
      status: details.status,
      createdBy: details.createdBy,
      createdAt: details.createdAt,
      updatedBy: details.updatedBy,
      updatedAt: details.updatedAt,
    );
  }

  @override
  Future<List<StudentClassroomItem>> getClassroomStudents({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? status,
    String? attendanceStatus,
    bool refresh = false,
  }) {
    return _studentClassroomRepository.getStudentClassroomList(
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      firstName: firstName,
      lastName: lastName,
      search: search,
      tagCodes: tagCodes,
      guardianCodes: guardianCodes,
      status: status,
      attendanceStatus: attendanceStatus,
      refresh: refresh,
    );
  }

  @override
  Future<SchoolCapacity> getSchoolCapacity({
    required String schoolCode,
  }) async {
    final key = CacheManager.buildCacheKey(
      feature: 'classroom',
      resource: 'school_capacity',
      identifier: schoolCode,
    );

    final cached = await _cacheManager.loadCache(key);
    if (cached != null) {
      return SchoolCapacity(
        capacity: cached['capacity'] as int? ?? 0,
        minAgeMonths: cached['minAgeMonths'] as int? ?? 0,
        maxAgeMonths: cached['maxAgeMonths'] as int? ?? 0,
      );
    }

    final model = await _remoteDataSource.getSchoolCapacity(schoolCode: schoolCode);
    await _cacheManager.saveCache(key, {
      'capacity': model.capacity,
      'minAgeMonths': model.minAgeMonths,
      'maxAgeMonths': model.maxAgeMonths,
    });

    return SchoolCapacity(
      capacity: model.capacity,
      minAgeMonths: model.minAgeMonths,
      maxAgeMonths: model.maxAgeMonths,
    );
  }

  @override
  Future<ClassroomCount> getClassroomCount({
    required String schoolCode,
    required String status,
  }) async {
    final key = CacheManager.buildCacheKey(
      feature: 'classroom',
      resource: 'classroom_count',
      identifier: '${schoolCode}_$status',
    );

    final cached = await _cacheManager.loadCache(key);
    if (cached != null) {
      return ClassroomCount(
        total: cached['total'] as int? ?? 0,
        adminCount: cached['adminCount'] as int? ?? 0,
        classroomCount: cached['classroomCount'] as int? ?? 0,
      );
    }

    final model = await _remoteDataSource.getClassroomCount(
      schoolCode: schoolCode,
      status: status,
    );
    await _cacheManager.saveCache(key, {
      'total': model.total,
      'adminCount': model.adminCount,
      'classroomCount': model.classroomCount,
    });

    return ClassroomCount(
      total: model.total,
      adminCount: model.adminCount,
      classroomCount: model.classroomCount,
    );
  }

  @override
  Future<SchoolFte> getSchoolFte({
    required String schoolCode,
    required int capacity,
  }) async {
    final key = CacheManager.buildCacheKey(
      feature: 'classroom',
      resource: 'school_fte',
      identifier: '${schoolCode}_$capacity',
    );

    final cached = await _cacheManager.loadCache(key);
    if (cached != null) {
      return SchoolFte(
        schoolCode: cached['schoolCode'] as String? ?? '',
        schoolFte: (cached['schoolFte'] as num?)?.toDouble() ?? 0.0,
      );
    }

    final model = await _remoteDataSource.getSchoolFte(
      schoolCode: schoolCode,
      capacity: capacity,
    );
    await _cacheManager.saveCache(key, {
      'schoolCode': model.schoolCode,
      'schoolFte': model.schoolFte,
    });

    return SchoolFte(
      schoolCode: model.schoolCode,
      schoolFte: model.schoolFte,
    );
  }

  @override
  Future<List<RatioMonitoringClassroom>> getRatioMonitoringClassrooms({
    required String schoolCode,
  }) async {
    final key = CacheManager.buildCacheKey(
      feature: 'classroom',
      resource: 'ratio_classrooms',
      identifier: schoolCode,
    );

    // ── Serve from cache if available ────────────────────────────────────────
    final cached = await _cacheManager.loadCache(key);
    if (cached != null) {
      final list = cached['items'] as List<dynamic>? ?? const [];
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return RatioMonitoringClassroom(
          code: m['code'] as String? ?? '',
          name: m['name'] as String? ?? '',
          capacity: m['capacity'] as int? ?? 0,
          allowedRatio: m['allowedRatio'] as int? ?? 0,
          studentPresent: 0,
          staffPresent: 0,
        );
      }).toList();
    }

    // ── Try the new paginated API (returns studentsTeacherRatio) ─────────────
    try {
      final model = await _remoteDataSource.getRatioMonitoringClassrooms(
        schoolCode: schoolCode,
      );

      if (model.items.isNotEmpty) {
        final result = model.items
            .map(
              (e) => RatioMonitoringClassroom(
                code: e.code,
                name: e.name,
                capacity: e.capacity,
                allowedRatio: e.studentsTeacherRatio,
                studentPresent: 0,
                staffPresent: 0,
              ),
            )
            .toList();

        await _cacheManager.saveCache(key, {
          'items': result.map((e) => {
            'code': e.code,
            'name': e.name,
            'capacity': e.capacity,
            'allowedRatio': e.allowedRatio,
          }).toList(),
        });

        return result;
      }
    } catch (_) {
      // Paginated API unavailable — fall through to the reliable fallback.
    }

    // ── Fallback: use the existing /classroom/all endpoint (always works) ────
    // This endpoint does not return studentsTeacherRatio, so allowedRatio
    // defaults to 0 which resolves to GREEN (no restriction) per entity logic.
    final fallback = await _remoteDataSource.getActiveClassrooms(
      schoolCode: schoolCode,
    );

    final result = fallback.items
        .map(
          (e) => RatioMonitoringClassroom(
            code: e.code,
            name: e.name,
            capacity: 0,
            allowedRatio: 0,
            studentPresent: 0,
            staffPresent: 0,
          ),
        )
        .toList();

    if (result.isNotEmpty) {
      await _cacheManager.saveCache(key, {
        'items': result.map((e) => {
          'code': e.code,
          'name': e.name,
          'capacity': e.capacity,
          'allowedRatio': e.allowedRatio,
        }).toList(),
      });
    }

    return result;
  }

  @override
  Future<Map<String, ClassroomAttendanceSummaryEntry>>
  getStudentAttendanceSummaryByClassrooms({
    required List<String> classroomCodes,
    DateTime? date,
  }) async {
    if (classroomCodes.isEmpty) return <String, ClassroomAttendanceSummaryEntry>{};

    final raw = await _remoteDataSource.getStudentAttendanceSummaryByClassrooms(
      classroomCodes: classroomCodes,
      date: date,
    );

    return raw.map(
      (code, value) => MapEntry(
        code,
        ClassroomAttendanceSummaryEntry.fromJson(
          value is Map<String, dynamic> ? value : <String, dynamic>{},
        ),
      ),
    );
  }

  @override
  Future<Map<String, ClassroomAttendanceSummaryEntry>>
  getStaffAttendanceSummaryByClassrooms({
    required List<String> classroomCodes,
    DateTime? date,
  }) async {
    if (classroomCodes.isEmpty) return <String, ClassroomAttendanceSummaryEntry>{};

    final raw = await _remoteDataSource.getStaffAttendanceSummaryByClassrooms(
      classroomCodes: classroomCodes,
      date: date,
    );

    return raw.map(
      (code, value) => MapEntry(
        code,
        ClassroomAttendanceSummaryEntry.fromJson(
          value is Map<String, dynamic> ? value : <String, dynamic>{},
        ),
      ),
    );
  }

  @override
  Future<Map<String, dynamic>?> getStudentClassroomEnrolledCount({
    required String classroomCode,
    String? organizationCode,
    String? schoolCode,
  }) {
    return _remoteDataSource.getStudentClassroomEnrolledCount(
      classroomCode: classroomCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }

  @override
  Future<Map<String, dynamic>?> getClassroomLogoAssetCodes({
    required String classroomCode,
    required String schoolCode,
  }) {
    return _remoteDataSource.getClassroomLogoAssetCodes(
      classroomCode: classroomCode,
      schoolCode: schoolCode,
    );
  }

  @override
  Future<Map<String, dynamic>?> createClassroomLogoUploadSession({
    required String classroomCode,
    required String organizationCode,
    required String schoolCode,
  }) {
    return _remoteDataSource.createClassroomLogoUploadSession(
      classroomCode: classroomCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }

  @override
  Future<Map<String, dynamic>?> finalizeClassroomLogo({
    required String classroomCode,
    required String assetCode,
  }) {
    return _remoteDataSource.finalizeClassroomLogo(
      classroomCode: classroomCode,
      assetCode: assetCode,
    );
  }
}

