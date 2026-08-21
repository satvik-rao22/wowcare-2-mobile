import 'package:wowcare/core/storage/storage_service.dart';

import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/student_classroom/entities/student_classroom_item.dart';
import '../../../../domain/features/student_classroom/repositories/student_classroom_repository.dart';
import '../datasources/student_classroom_remote_datasource.dart';
import '../models/student_classroom_models.dart';

class StudentClassroomRepositoryImpl implements StudentClassroomRepository {
  StudentClassroomRepositoryImpl(
    this._remoteDataSource,
    StorageService storageService,
  ) : _cacheManager = CacheManager(storageService);

  final StudentClassroomRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  // classroom_student_roster_cache_{schoolCode|classroomCode|filters...}
  static String _studentClassroomCacheKey({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? studentCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? status,
    String? attendanceStatus,
  }) {
    final parts = <String>[schoolCode.trim(), classroomCode.trim()];

    final normFirst = (firstName ?? '').trim().toLowerCase();
    final normLast = (lastName ?? '').trim().toLowerCase();
    final normSearch = (search ?? '').trim().toLowerCase();

    if (normFirst.isNotEmpty) {
      parts.add('first=$normFirst');
    }
    if (normLast.isNotEmpty) {
      parts.add('last=$normLast');
    }
    if (normSearch.isNotEmpty) {
      parts.add('search=$normSearch');
    }

    final normTags =
        (tagCodes ?? [])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    final normStudentCodes =
        (studentCodes ?? [])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    final normGuardians =
        (guardianCodes ?? [])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    final normStatus =
        (status ?? [])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList()
          ..sort();
    final normAttendance = (attendanceStatus ?? '').trim().toUpperCase();

    if (normTags.isNotEmpty) {
      parts.add('tags=${normTags.join(',')}');
    }
    if (normStudentCodes.isNotEmpty) {
      parts.add('studentCodes=${normStudentCodes.join(',')}');
    }
    if (normGuardians.isNotEmpty) {
      parts.add('guardians=${normGuardians.join(',')}');
    }
    if (normStatus.isNotEmpty) {
      parts.add('status=${normStatus.join(',')}');
    }
    if (normAttendance.isNotEmpty) {
      parts.add('attendance=$normAttendance');
    }

    final identifier = parts.join('|');

    return CacheManager.buildCacheKey(
      feature: 'classroom',
      resource: 'student_roster',
      identifier: identifier,
    );
  }

  @override
  Future<List<StudentClassroomItem>> getStudentClassroomList({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? studentCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? status,
    String? attendanceStatus,
    bool refresh = false,
  }) async {
    final cacheKey = _studentClassroomCacheKey(
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      firstName: firstName,
      lastName: lastName,
      search: search,
      studentCodes: studentCodes,
      tagCodes: tagCodes,
      guardianCodes: guardianCodes,
      status: status,
      attendanceStatus: attendanceStatus,
    );

    if (!refresh) {
      final cachedPayload = await _cacheManager.loadCache(cacheKey);
      if (cachedPayload != null) {
        final listModel = StudentClassroomListModel.fromCacheJson(
          cachedPayload,
        );
        return listModel.items.map(_mapModelToEntity).toList();
      }
    }

    final models = await _remoteDataSource.getStudentClassroomList(
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      firstName: firstName,
      lastName: lastName,
      search: search,
      studentCodes: studentCodes,
      tagCodes: tagCodes,
      guardianCodes: guardianCodes,
      status: status,
      attendanceStatus: attendanceStatus,
    );

    final listModel = StudentClassroomListModel(items: models);
    await _cacheManager.saveCache(cacheKey, listModel.toJson());

    return models.map(_mapModelToEntity).toList();
  }

  @override
  Future<String> assignStudentsToClassroom({
    required String schoolCode,
    required String classroomCode,
    required List<String> studentCodes,
  }) async {
    final response = await _remoteDataSource.assignStudentsToClassroom(
      classroomCode: classroomCode,
      studentCodes: studentCodes,
    );

    // Best-effort cache invalidation for the default (unfiltered) list.
    // Other filtered cache variants (tags/status/search) will naturally refresh
    // when requested with refresh=true.
    final defaultCacheKey = _studentClassroomCacheKey(
      schoolCode: schoolCode,
      classroomCode: classroomCode,
    );
    await _cacheManager.invalidateCache(defaultCacheKey);

    return response.message;
  }

  StudentClassroomItem _mapModelToEntity(StudentClassroomItemModel model) {
    return StudentClassroomItem(
      classroomCode: model.classroomCode,
      studentCode: model.studentCode,
      firstName: model.firstName,
      lastName: model.lastName,
      profilePictureUrl: model.profilePictureUrl,
      status: model.status,
      expectedToday: model.expectedToday,
      signedIn: model.signedIn,
      absent: model.absent,
      notMarked: model.notMarked,
      nap: model.nap,
      photoPermission: model.photoPermission,
      notes: model.notes,
      medication: model.medication,
      allergies: model.allergies,
      dietaryRestriction: model.dietaryRestriction,
      dob: model.dob,
    );
  }
}
