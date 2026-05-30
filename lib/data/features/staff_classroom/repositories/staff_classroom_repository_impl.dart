import 'package:wowcare/core/storage/storage_service.dart';

import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/staff_classroom/entities/staff_classroom_item.dart';
import '../../../../domain/features/staff_classroom/repositories/staff_classroom_repository.dart';
import '../datasources/staff_classroom_remote_datasource.dart';
import '../models/staff_classroom_models.dart';

class StaffClassroomRepositoryImpl implements StaffClassroomRepository {
  StaffClassroomRepositoryImpl(
    this._remoteDataSource,
    StorageService storageService,
  ) : _cacheManager = CacheManager(storageService);

  final StaffClassroomRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  static String _cacheKey({
    required String schoolCode,
    List<String>? classCodes,
    List<String>? primaryClassroomCodes,
    String? excludeClassroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
  }) {
    final parts = <String>[schoolCode.trim()];

    List<String> norm(List<String>? v, {bool upper = false}) {
      final list = (v ?? [])
          .map((e) => upper ? e.trim().toUpperCase() : e.trim())
          .where((e) => e.isNotEmpty)
          .toList()
        ..sort();
      return list;
    }

    final normClassCodes = norm(classCodes);
    if (normClassCodes.isNotEmpty) parts.add('class=${normClassCodes.join(',')}');

    final normPrimary = norm(primaryClassroomCodes);
    if (normPrimary.isNotEmpty) parts.add('primary=${normPrimary.join(',')}');

    final normStatus = norm(status, upper: true);
    if (normStatus.isNotEmpty) parts.add('status=${normStatus.join(',')}');

    final normDes = norm(designation, upper: true);
    if (normDes.isNotEmpty) parts.add('des=${normDes.join(',')}');

    final ex = (excludeClassroomCode ?? '').trim();
    if (ex.isNotEmpty) parts.add('exclude=$ex');

    final q = (search ?? '').trim().toLowerCase();
    if (q.isNotEmpty) parts.add('search=$q');

    return CacheManager.buildCacheKey(
      feature: 'classroom',
      resource: 'staff_roster',
      identifier: parts.join('|'),
    );
  }

  @override
  Future<List<StaffClassroomItem>> getStaffClassrooms({
    required String schoolCode,
    List<String>? classCodes,
    List<String>? primaryClassroomCodes,
    String? excludeClassroomCode,
    String? search,
    List<String>? status,
    List<String>? designation,
    String? organizationCode,
    String? firstName,
    String? phoneNumber,
    String? code,
    bool refresh = false,
  }) async {
    final key = _cacheKey(
      schoolCode: schoolCode,
      classCodes: classCodes,
      primaryClassroomCodes: primaryClassroomCodes,
      excludeClassroomCode: excludeClassroomCode,
      search: search,
      status: status,
      designation: designation,
    );

    if (!refresh) {
      final cached = await _cacheManager.loadCache(key);
      if (cached != null) {
        final listModel = StaffClassroomListModel.fromCacheJson(cached);
        return listModel.items.map(_mapModelToEntity).toList();
      }
    }

    final models = await _remoteDataSource.getStaffClassrooms(
      schoolCode: schoolCode,
      classCodes: classCodes,
      primaryClassroomCodes: primaryClassroomCodes,
      excludeClassroomCode: excludeClassroomCode,
      search: search,
      status: status,
      designation: designation,
      organizationCode: organizationCode,
      firstName: firstName,
      phoneNumber: phoneNumber,
      code: code,
    );

    final listModel = StaffClassroomListModel(items: models);
    await _cacheManager.saveCache(key, listModel.toJson());

    return models.map(_mapModelToEntity).toList();
  }

  @override
  Future<List<StaffClassroomItem>> getManageStaffList({
    required String schoolCode,
    required String excludeClassroomCode,
  }) async {
    final models = await _remoteDataSource.getManageStaffList(
      schoolCode: schoolCode,
      excludeClassroomCode: excludeClassroomCode,
    );
    return models.map(_mapModelToEntity).toList();
  }

  @override
  Future<String> assignStaffToClassroom({
    required String schoolCode,
    required String classroomCode,
    required List<String> staffCodes,
  }) async {
    final response = await _remoteDataSource.assignStaffToClassroom(
      classroomCode: classroomCode,
      staffCodes: staffCodes,
    );

    // Invalidate roster caches for this classroom (listing variants used by the app).
    await _cacheManager.invalidateCache(
      _cacheKey(schoolCode: schoolCode, classCodes: [classroomCode]),
    );
    await _cacheManager.invalidateCache(
      _cacheKey(schoolCode: schoolCode, primaryClassroomCodes: [classroomCode]),
    );
    await _cacheManager.invalidateCache(
      _cacheKey(
        schoolCode: schoolCode,
        excludeClassroomCode: classroomCode,
        status: const ['ACTIVE'],
      ),
    );

    return response.message;
  }

  StaffClassroomItem _mapModelToEntity(StaffClassroomItemModel m) {
    return StaffClassroomItem(
      classroomCode: m.classroomCode,
      staffCode: m.staffCode,
      firstName: m.firstName,
      lastName: m.lastName,
      profilePictureUrl: m.profilePictureUrl,
      status: m.status,
      designation: m.designation,
      expectedToday: m.expectedToday,
      signedIn: m.signedIn,
      absent: m.absent,
      notMarked: m.notMarked,
    );
  }
}

