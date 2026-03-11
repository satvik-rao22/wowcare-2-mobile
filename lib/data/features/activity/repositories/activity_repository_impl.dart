import 'package:wowcare/core/storage/storage_service.dart';

import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../domain/features/activity/repositories/activity_repository.dart';
import '../datasources/activity_remote_datasource.dart';
import '../models/activity_settings_models.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl(
    this._remoteDataSource,
    StorageService storageService,
  ) : _cacheManager = CacheManager(storageService);

  final ActivityRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;

  // Cache key helper: activity_settings_cache_{classroomCode}
  static String _activitySettingsCacheKey(String classroomCode) {
    return CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'settings',
      identifier: classroomCode,
    );
  }

  @override
  Future<List<ActivitySetting>> getClassroomActivitySettings({
    required String classroomCode,
  }) async {
    // 1. Try cache first.
    final cachedPayload = await _cacheManager.loadCache(
      _activitySettingsCacheKey(classroomCode),
    );
    if (cachedPayload != null) {
      final listModel =
          ActivitySettingsListModel.fromCacheJson(cachedPayload);
      return listModel.items.map(_mapModelToEntity).toList();
    }

    // 2. Load from remote.
    final models = await _remoteDataSource.getClassroomActivitySettings(
      classroomCode: classroomCode,
    );

    // 3. Cache result (non-paginated; cache full list).
    final listModel = ActivitySettingsListModel(items: models);
    await _cacheManager.saveCache(
      _activitySettingsCacheKey(classroomCode),
      listModel.toJson(),
    );

    // 4. Map to entities.
    return models.map(_mapModelToEntity).toList();
  }

  ActivitySetting _mapModelToEntity(ActivitySettingModel model) {
    return ActivitySetting(
      activityTypeCode: model.activityTypeCode,
      activityTypeName: model.activityTypeName,
      description: model.description,
      category: model.category,
      icon: model.icon,
      color: model.color,
      isSystem: model.isSystem,
      isMultiStudent: model.isMultiStudent,
      requiresStaff: model.requiresStaff,
      requiresPhoto: model.requiresPhoto,
      requiresVideo: model.requiresVideo,
      allowsAttachments: model.allowsAttachments,
      maxAttachments: model.maxAttachments,
      isEnabled: model.isEnabled,
      isFavorite: model.isFavorite,
      displayOrder: model.displayOrder,
    );
  }

  @override
  Future<String> createActivity({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    List<Map<String, dynamic>> parameterValues = const [],
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final request = ActivityCreateRequestModel(
      activityTypeCode: activityTypeCode,
      classroomCode: classroomCode,
      studentCodes: studentCodes,
      staffCode: staffCode,
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      activityDate: activityDate,
      description: description,
      parameterValues: parameterValues,
      attachments: attachments,
    );

    return _remoteDataSource.createActivity(request: request);
  }
}


