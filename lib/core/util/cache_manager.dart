import '../storage/storage_service.dart';
import 'storage_keys.dart';

/// Global cache manager for handling cached data with timestamps and expiration.
///
/// This is a generic cache manager that can be used for any API/feature.
/// Each repository should define its own cache keys following the pattern:
/// `{feature}_{resource}_cache_{identifier}`
///
/// Example:
/// - `staff_list_cache_$schoolCode`
/// - `staff_documents_cache_$staffCode`
/// - `students_list_cache_$schoolCode`
class CacheManager {
  CacheManager(this._storageService);

  final StorageService _storageService;

  /// Helper method to build a cache key following the standard pattern.
  ///
  /// [feature] - Feature/module name (e.g., 'staff', 'students', 'classes')
  /// [resource] - Resource type (e.g., 'list', 'documents', 'details')
  /// [identifier] - Unique identifier (e.g., schoolCode, staffCode, studentId)
  ///
  /// Returns: `{feature}_{resource}_cache_{identifier}`
  static String buildCacheKey({
    required String feature,
    required String resource,
    required String identifier,
  }) {
    return '${feature}_${resource}_cache_$identifier';
  }

  /// Saves data to cache with a timestamp.
  ///
  /// [key] - Unique cache key
  /// [payload] - Data to cache (must be JSON-serializable)
  Future<void> saveCache(String key, Map<String, dynamic> payload) async {
    final cache = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': payload,
    };
    await _storageService.saveJson(key, cache);
  }

  /// Loads cached data if it exists and is not expired.
  ///
  /// [key] - Unique cache key
  /// [validFor] - Max age for this entry; defaults to [StorageKeys.cacheValidDuration].
  /// Returns the cached payload if valid, null otherwise
  Future<Map<String, dynamic>?> loadCache(
    String key, {
    Duration? validFor,
  }) async {
    final cache = await _storageService.getJson(key);
    if (cache == null) return null;

    final timestampMillis = cache['timestamp'] as int?;
    if (timestampMillis == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final age = DateTime.now().difference(cachedAt);
    final maxAge = validFor ?? StorageKeys.cacheValidDuration;
    if (age > maxAge) {
      return null; // Cache expired
    }

    final payload = cache['payload'] as Map<String, dynamic>?;
    return payload;
  }

  /// Checks if cache exists and is valid (not expired).
  Future<bool> isCacheValid(String key, {Duration? validFor}) async {
    final cache = await _storageService.getJson(key);
    if (cache == null) return false;

    final timestampMillis = cache['timestamp'] as int?;
    if (timestampMillis == null) return false;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final age = DateTime.now().difference(cachedAt);
    final maxAge = validFor ?? StorageKeys.cacheValidDuration;
    return age <= maxAge;
  }

  /// Removes cached data.
  Future<void> invalidateCache(String key) async {
    await _storageService.remove(key);
  }

  /// Removes multiple cache entries.
  Future<void> invalidateCaches(List<String> keys) async {
    for (final key in keys) {
      await _storageService.remove(key);
    }
  }

  /// Invalidates cache using the standard key pattern.
  ///
  /// This is a convenience method that builds the key and invalidates it.
  /// Use this after any mutation (add/edit/delete) to ensure fresh data on next fetch.
  ///
  /// Example:
  /// ```dart
  /// await _cacheManager.invalidateCacheByKey(
  ///   feature: 'staff',
  ///   resource: 'documents',
  ///   identifier: staffCode,
  /// );
  /// ```
  Future<void> invalidateCacheByKey({
    required String feature,
    required String resource,
    required String identifier,
  }) async {
    final key = buildCacheKey(
      feature: feature,
      resource: resource,
      identifier: identifier,
    );
    await invalidateCache(key);
  }
}
