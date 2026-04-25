import 'package:wowcare/core/storage/storage_service.dart';

import '../../../../core/util/activity_feed_invalidation.dart';
import '../../../../core/util/cache_manager.dart';
import '../../../../domain/features/activity/entities/activity_asset_presign.dart';
import '../../../../domain/features/activity/entities/activity_detail.dart';
import '../../../../domain/features/activity/entities/activity_feed_row.dart';
import '../../../../domain/features/activity/entities/activity_setting.dart';
import '../../../../domain/features/activity/entities/activity_type_details.dart';
import '../../../../domain/features/activity/entities/activity_type_summary.dart';
import '../../../../domain/features/activity/entities/activity_upload_session.dart';
import '../../../../domain/features/activity/repositories/activity_repository.dart';
import '../datasources/activity_remote_datasource.dart';
import '../models/activity_settings_models.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  ActivityRepositoryImpl(
    this._remoteDataSource,
    StorageService storageService,
  )   : _cacheManager = CacheManager(storageService),
        _storageService = storageService;

  final ActivityRemoteDataSource _remoteDataSource;
  final CacheManager _cacheManager;
  final StorageService _storageService;

  // Cache key helper: activity_settings_cache_{classroomCode}
  static String _activitySettingsCacheKey(String classroomCode) {
    return CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'settings',
      identifier: classroomCode,
    );
  }

  static String _activityTypesCacheKey(String schoolCode) {
    return CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'activity_types',
      identifier: schoolCode,
    );
  }

  @override
  Future<List<ActivityTypeSummary>> getActiveActivityTypesForSchool({
    required String schoolCode,
  }) async {
    final sc = schoolCode.trim();
    if (sc.isEmpty) return const [];

    // Try cache first.
    final cached = await _cacheManager.loadCache(_activityTypesCacheKey(sc));
    if (cached != null && cached['items'] is List) {
      final out = <ActivityTypeSummary>[];
      for (final raw in (cached['items'] as List).whereType<Map>()) {
        final code = (raw['code'] ?? '').toString().trim();
        final name = (raw['name'] ?? '').toString().trim();
        if (code.isEmpty || name.isEmpty) continue;
        out.add(ActivityTypeSummary(code: code, name: name));
      }
      if (out.isNotEmpty) return out;
    }

    // Fetch remote.
    final rows = await _remoteDataSource.getActiveActivityTypesForSchool(
      schoolCode: sc,
    );
    final items = rows
        .map((e) {
          final code = (e['code'] ?? '').toString().trim();
          final name = (e['name'] ?? '').toString().trim();
          return ActivityTypeSummary(code: code, name: name);
        })
        .where((e) => e.code.isNotEmpty && e.name.isNotEmpty)
        .toList();

    await _cacheManager.saveCache(_activityTypesCacheKey(sc), {
      'items': items.map((e) => {'code': e.code, 'name': e.name}).toList(),
    });
    return items;
  }

  @override
  Future<List<ActivitySetting>> getClassroomActivitySettings({
    required String classroomCode,
    bool refresh = false,
  }) async {
    if (!refresh) {
      // 1. Try cache first.
      final cachedPayload = await _cacheManager.loadCache(
        _activitySettingsCacheKey(classroomCode),
      );
      if (cachedPayload != null) {
        final listModel =
            ActivitySettingsListModel.fromCacheJson(cachedPayload);
        return listModel.items.map(_mapModelToEntity).toList();
      }
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
  Future<ActivityFeedPage> getDailyActivityFeed({
    required String classroomCode,
    required String date,
    String? studentCode,
    String? activityTypeCode,
    int page = 0,
    int size = 100,
  }) async {
    final model = await _remoteDataSource.getDailyActivityFeed(
      classroomCode: classroomCode,
      date: date,
      studentCode: studentCode,
      activityTypeCode: activityTypeCode,
      page: page,
      size: size,
    );
    return model.toEntity();
  }

  @override
  Future<ActivityFeedPage> getRangeActivityFeed({
    required String classroomCode,
    required String startDate,
    required String endDate,
    String? studentCode,
    String? activityTypeCode,
    int page = 0,
    int size = 100,
  }) async {
    final model = await _remoteDataSource.getRangeActivityFeed(
      classroomCode: classroomCode,
      startDate: startDate,
      endDate: endDate,
      studentCode: studentCode,
      activityTypeCode: activityTypeCode,
      page: page,
      size: size,
    );
    return model.toEntity();
  }

  @override
  Future<ActivityTypeDetails> getActivityTypeDetails({
    required String code,
  }) async {
    final model = await _remoteDataSource.getActivityTypeDetails(code: code);
    return model.toEntity();
  }

  @override
  Future<List<String>> getNapStartStudents({
    required String classroomCode,
  }) {
    return _remoteDataSource.getNapStartStudents(classroomCode: classroomCode);
  }

  @override
  Future<ActivityDetail> getActivity({required String code}) async {
    final data = await _remoteDataSource.getActivityByCode(
      cardGroupCode: code,
    );
    return ActivityDetail.fromApiData(data);
  }

  @override
  Future<String> updateActivity({
    required String code,
    List<String> studentCodes = const [],
    List<String> applyToStudentCodes = const [],
    required String staffCode,
    required String activityDate,
    required String description,
    List<Map<String, dynamic>> parameterValues = const [],
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final message = await _remoteDataSource.updateActivity(
      cardGroupCode: code,
      studentCodes: studentCodes,
      applyToStudentCodes: applyToStudentCodes,
      staffCode: staffCode,
      activityDate: activityDate,
      description: description,
      parameterValues: parameterValues,
      attachments: attachments,
    );
    await ActivityFeedInvalidation.invalidate(_storageService);
    return message;
  }

  @override
  Future<String> deleteActivity({required String code}) async {
    final message = await _remoteDataSource.deleteActivity(code: code);
    await ActivityFeedInvalidation.invalidate(_storageService);
    return message;
  }

  @override
  Future<String> approveActivity({required String code}) async {
    final message = await _remoteDataSource.approveActivity(
      cardGroupCode: code,
    );
    await ActivityFeedInvalidation.invalidate(_storageService);
    return message;
  }

  @override
  Future<String> rejectActivity({required String code}) async {
    final message = await _remoteDataSource.rejectActivity(
      cardGroupCode: code,
    );
    await ActivityFeedInvalidation.invalidate(_storageService);
    return message;
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
    bool? napStart,
    bool? napEnd,
    bool? requireAdminApproval,
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
      napStart: napStart,
      napEnd: napEnd,
      requireAdminApproval: requireAdminApproval,
      // v2 binding mode enum: PER_STUDENT (single), SHARED (multiple).
      bindingMode: studentCodes.length > 1 ? 'SHARED' : 'PER_STUDENT',
      parameterValues: parameterValues,
      attachments: attachments,
    );

    final message = await _remoteDataSource.createActivity(request: request);
    await ActivityFeedInvalidation.invalidate(_storageService);
    return message;
  }

  @override
  Future<List<Map<String, dynamic>>> createSharedActivities({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    bool? requireAdminApproval,
    required List<Map<String, dynamic>> attachments,
    List<Map<String, dynamic>> parameterValues = const [],
  }) async {
    final payload = <String, dynamic>{
      'activityTypeCode': activityTypeCode,
      'classroomCode': classroomCode,
      'studentCodes': studentCodes,
      'staffCode': staffCode,
      'schoolCode': schoolCode,
      'organizationCode': organizationCode,
      'activityDate': activityDate,
      'description': description,
      'bindingMode': 'SHARED',
      if (requireAdminApproval != null)
        'requireAdminApproval': requireAdminApproval,
      if (parameterValues.isNotEmpty) 'parameterValues': parameterValues,
      'attachments': attachments,
    };

    final cards = await _remoteDataSource.createSharedActivities(payload: payload);
    await ActivityFeedInvalidation.invalidate(_storageService);
    return cards;
  }

  @override
  Future<ActivityUploadSession> createActivityUploadSessions({
    required String organizationCode,
    required String schoolCode,
    required String classroomCode,
    required String activityTypeCode,
    required String bindingMode,
    required List<String> studentCodes,
  }) {
    return _remoteDataSource.createActivityUploadSessions(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      classroomCode: classroomCode,
      activityTypeCode: activityTypeCode,
      bindingMode: bindingMode,
      studentCodes: studentCodes,
    );
  }

  @override
  Future<ActivityAssetPresign> createActivityAssetPresign({
    required String sessionCode,
    required String documentApiBasePath,
    required String fileName,
    required String contentType,
    required int contentLengthBytes,
    required String mediaType,
    required String ownerType,
    required String ownerCode,
  }) {
    return _remoteDataSource.createActivityAssetPresign(
      sessionCode: sessionCode,
      documentApiBasePath: documentApiBasePath,
      fileName: fileName,
      contentType: contentType,
      contentLengthBytes: contentLengthBytes,
      mediaType: mediaType,
      ownerType: ownerType,
      ownerCode: ownerCode,
    );
  }
}


