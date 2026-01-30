import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../datasources/staff_remote_datasource.dart';
import '../models/staff_models.dart';

class StaffRepositoryImpl implements StaffRepository, StaffRepositoryWithCache {
  StaffRepositoryImpl(this._remoteDataSource, this._storageService);

  final StaffRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  static String _cacheKey(String schoolCode) =>
      'staff_list_cache_$schoolCode';

  @override
  Future<StaffPage> getStaffPage({
    required String schoolCode,
    int page = 0,
    int size = 10,
    String? status,
    String? designation,
    String? search,
  }) async {
    final staffPageModel = await _remoteDataSource.getStaffPage(
      schoolCode: schoolCode,
      page: page,
      size: size,
      status: status,
      designation: designation,
      search: search,
    );

    // Cache only the first page for simplicity
    if (page == 0) {
      final cache = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'payload': staffPageModel.toJson(),
      };
      await _storageService.saveJson(_cacheKey(schoolCode), cache);
    }

    return _mapPageModelToEntity(staffPageModel);
  }

  Future<StaffPage?> loadCachedStaffPage(String schoolCode) async {
    final cache = await _storageService.getJson(_cacheKey(schoolCode));
    if (cache == null) return null;

    final timestampMillis = cache['timestamp'] as int?;
    if (timestampMillis == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final age = DateTime.now().difference(cachedAt);
    if (age > StorageKeys.cacheValidDuration) {
      return null;
    }

    final payload = cache['payload'] as Map<String, dynamic>?;
    if (payload == null) return null;

    final model = StaffPageModel.fromCacheJson(payload);
    return _mapPageModelToEntity(model);
  }

  StaffPage _mapPageModelToEntity(StaffPageModel model) {
    final items = model.items
        .map(
          (m) => StaffMember(
            code: m.code,
            name: m.name,
            classroomCodes: m.classroomCodes,
            designation: m.designation,
            phoneNumber: m.phoneNumber,
            status: m.status,
          ),
        )
        .toList();

    return StaffPage(
      items: items,
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }
}


