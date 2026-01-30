import '../../core/storage/storage_service.dart';
import 'storage_keys.dart';

/// Global cache manager for handling cached data with timestamps and expiration.
class CacheManager {
  CacheManager(this._storageService);

  final StorageService _storageService;

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
  /// Returns the cached payload if valid, null otherwise
  Future<Map<String, dynamic>?> loadCache(String key) async {
    final cache = await _storageService.getJson(key);
    if (cache == null) return null;

    final timestampMillis = cache['timestamp'] as int?;
    if (timestampMillis == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final age = DateTime.now().difference(cachedAt);
    if (age > StorageKeys.cacheValidDuration) {
      return null; // Cache expired
    }

    final payload = cache['payload'] as Map<String, dynamic>?;
    return payload;
  }

  /// Checks if cache exists and is valid (not expired).
  Future<bool> isCacheValid(String key) async {
    final cache = await _storageService.getJson(key);
    if (cache == null) return false;

    final timestampMillis = cache['timestamp'] as int?;
    if (timestampMillis == null) return false;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    final age = DateTime.now().difference(cachedAt);
    return age <= StorageKeys.cacheValidDuration;
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
}

