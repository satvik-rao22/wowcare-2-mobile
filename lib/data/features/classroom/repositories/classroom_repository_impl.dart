import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/repositories/classroom_repository.dart';
import '../datasources/classroom_remote_datasource.dart';
import '../models/classroom_models.dart';

class ClassroomRepositoryImpl implements ClassroomRepository {
  ClassroomRepositoryImpl(
    this._remoteDataSource,
    StorageService storageService,
  ) : _cacheManager = CacheManager(storageService);

  final ClassroomRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  static String _classroomListCacheKey(String schoolCode) =>
      CacheManager.buildCacheKey(
        feature: 'classroom',
        resource: 'list',
        identifier: schoolCode,
      );

  @override
  Future<ClassroomPage> getClassrooms({
    required String schoolCode,
    int page = 0,
    int size = 10,
  }) async {
    final pageModel = await _remoteDataSource.getClassrooms(
      schoolCode: schoolCode,
      page: page,
      size: size,
    );

    if (page == 0) {
      await _cacheManager.saveCache(
        _classroomListCacheKey(schoolCode),
        _pageModelToJson(pageModel),
      );
    }

    return _mapPageModelToEntity(pageModel);
  }

  ClassroomPage _mapPageModelToEntity(ClassroomPageModel model) {
    final items = model.items
        .map(
          (m) => Classroom(
            code: m.code,
            name: m.name,
            capacity: m.capacity,
            type: m.type,
            status: m.status,
          ),
        )
        .toList();

    return ClassroomPage(
      items: items,
      page: model.page,
      size: model.size,
      totalPages: model.totalPages,
      totalElements: model.totalElements,
      hasMore: model.hasMore,
    );
  }

  Map<String, dynamic> _pageModelToJson(ClassroomPageModel model) {
    return {
      'items': model.items
          .map((m) => {
                'code': m.code,
                'name': m.name,
                'capacity': m.capacity,
                'type': m.type,
                'status': m.status,
              })
          .toList(),
      'page': model.page,
      'size': model.size,
      'totalPages': model.totalPages,
      'totalElements': model.totalElements,
      'hasMore': model.hasMore,
    };
  }
}


