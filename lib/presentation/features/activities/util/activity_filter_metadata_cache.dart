import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/activity/entities/activity_setting.dart';
import 'package:wowcare/domain/features/activity/entities/activity_type_summary.dart';
import 'package:wowcare/domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_active_activity_types_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';

/// Disk-backed helpers for activity filter dropdowns (tags + activity types per classroom).
class ActivityFilterMetadataCache {
  ActivityFilterMetadataCache._();

  static Future<Map<String, String>> loadTagNameCodeMap({
    required CacheManager cacheManager,
    required GetTagNameCodeMapForSchoolUseCase useCase,
    required String schoolCode,
    bool forceRefresh = false,
  }) async {
    final key = CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'tag_name_code_map',
      identifier: schoolCode,
    );
    if (!forceRefresh) {
      final cached = await cacheManager.loadCache(
        key,
        validFor: StorageKeys.cacheValidDuration,
      );
      if (cached != null && cached['entries'] is List) {
        final out = <String, String>{};
        for (final raw in (cached['entries'] as List).whereType<Map>()) {
          final name = (raw['name'] ?? '').toString().trim();
          final code = (raw['code'] ?? '').toString().trim();
          if (name.isNotEmpty && code.isNotEmpty) out[name] = code;
        }
        if (out.isNotEmpty) return out;
      }
    }
    final map = await useCase(schoolCode: schoolCode);
    await cacheManager.saveCache(key, {
      'entries': map.entries
          .map((e) => {'name': e.key, 'code': e.value})
          .toList(),
    });
    return map;
  }

  static ActivitySetting _settingFromMap(Map<dynamic, dynamic> e) {
    return ActivitySetting(
      activityTypeCode: (e['activityTypeCode'] ?? '').toString(),
      activityTypeName: (e['activityTypeName'] ?? '').toString(),
      description: (e['description'] ?? '').toString(),
      category: (e['category'] ?? '').toString(),
      icon: (e['icon'] ?? '').toString(),
      color: (e['color'] ?? '').toString(),
      isSystem: (e['isSystem'] as bool?) ?? false,
      isMultiStudent: (e['isMultiStudent'] as bool?) ?? false,
      requiresStaff: (e['requiresStaff'] as bool?) ?? false,
      requiresPhoto: (e['requiresPhoto'] as bool?) ?? false,
      requiresVideo: (e['requiresVideo'] as bool?) ?? false,
      allowsAttachments: (e['allowsAttachments'] as bool?) ?? false,
      maxAttachments: (e['maxAttachments'] as int?) ?? 0,
      isEnabled: (e['isEnabled'] as bool?) ?? true,
      isFavorite: (e['isFavorite'] as bool?) ?? false,
      displayOrder: (e['displayOrder'] as int?) ?? 0,
    );
  }

  static Map<String, dynamic> _settingToMap(ActivitySetting s) {
    return {
      'activityTypeCode': s.activityTypeCode,
      'activityTypeName': s.activityTypeName,
      'description': s.description,
      'category': s.category,
      'icon': s.icon,
      'color': s.color,
      'isSystem': s.isSystem,
      'isMultiStudent': s.isMultiStudent,
      'requiresStaff': s.requiresStaff,
      'requiresPhoto': s.requiresPhoto,
      'requiresVideo': s.requiresVideo,
      'allowsAttachments': s.allowsAttachments,
      'maxAttachments': s.maxAttachments,
      'isEnabled': s.isEnabled,
      'isFavorite': s.isFavorite,
      'displayOrder': s.displayOrder,
    };
  }

  /// Activity types for a classroom; refreshes when [classroomCode] changes.
  static Future<List<ActivitySetting>> loadClassroomActivitySettings({
    required CacheManager cacheManager,
    required GetClassroomActivitySettingsUseCase useCase,
    required String classroomCode,
    bool forceRefresh = false,
  }) async {
    final key = CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'settings',
      identifier: classroomCode,
    );
    if (!forceRefresh) {
      final cached = await cacheManager.loadCache(
        key,
        validFor: StorageKeys.cacheValidDuration,
      );
      if (cached != null && cached['settings'] is List) {
        final list = (cached['settings'] as List)
            .whereType<Map>()
            .map((e) => _settingFromMap(e))
            .where((e) =>
                e.activityTypeCode.isNotEmpty && e.activityTypeName.isNotEmpty)
            .toList();
        if (list.isNotEmpty) return list;
      }
    }
    final settings = await useCase(
      classroomCode: classroomCode,
      refresh: forceRefresh,
    );
    await cacheManager.saveCache(key, {
      'settings': settings.map(_settingToMap).toList(),
    });
    return settings;
  }

  /// School-wide active activity types via `GET /api/v1/activity-types?schoolCode=...`.
  static Future<List<ActivityTypeSummary>> loadActiveActivityTypesForSchool({
    required CacheManager cacheManager,
    required GetActiveActivityTypesForSchoolUseCase useCase,
    required String schoolCode,
    bool forceRefresh = false,
  }) async {
    final key = CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'activity_types',
      identifier: schoolCode,
    );
    if (!forceRefresh) {
      final cached = await cacheManager.loadCache(
        key,
        validFor: StorageKeys.cacheValidDuration,
      );
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
    }
    final items = await useCase(schoolCode: schoolCode);
    await cacheManager.saveCache(key, {
      'items': items.map((e) => {'code': e.code, 'name': e.name}).toList(),
    });
    return items;
  }
}
