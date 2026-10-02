import 'package:wowcare/core/storage/flutter_secure_storage_backend.dart';
import 'package:wowcare/core/storage/secure_storage.dart';
import 'package:wowcare/core/storage/secure_storage_backend.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// The app-wide key/value store. Backed by the platform secure store via
/// [SecureStorage]; see [StorageServiceImpl] for the contract.
abstract class StorageService {
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<void> saveInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> saveBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> saveDouble(String key, double value);
  Future<double?> getDouble(String key);
  Future<void> saveJson(String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> remove(String key);

  /// Removes every entry in this store. Does not touch the auth tokens or the
  /// "Remember me" credentials, which live outside it (see
  /// [SecureStorage.appNamespace]).
  Future<void> clear();

  /// All keys currently stored. Used for prefix/pattern-based bulk clears
  /// (e.g. wiping every `*_cache_*` entry on school switch).
  Future<Set<String>> getKeys();
}

/// [StorageService] over a namespaced [SecureStorage] view.
///
/// Contract, kept identical to the `SharedPreferences`-backed implementation
/// this replaced so none of the ~60 call sites needed to change:
///  * reads of a missing key return `null`;
///  * a value of the wrong type reads back as `null` (where
///    `SharedPreferences` would have thrown a `TypeError`);
///  * nothing here throws for a platform failure. The failure is logged and
///    the call behaves as "no value" / "not saved". Callers that need to know
///    (the auth stores) use [SecureStorage] directly and catch
///    [SecureStorageException] themselves.
class StorageServiceImpl implements StorageService {
  StorageServiceImpl(this._secure);

  final SecureStorage _secure;

  @override
  Future<void> saveString(String key, String value) =>
      _write('saveString', key, () => _secure.writeString(key, value));

  @override
  Future<String?> getString(String key) =>
      _read('getString', key, () => _secure.readString(key));

  @override
  Future<void> saveInt(String key, int value) =>
      _write('saveInt', key, () => _secure.writeInt(key, value));

  @override
  Future<int?> getInt(String key) =>
      _read('getInt', key, () => _secure.readInt(key));

  @override
  Future<void> saveBool(String key, bool value) =>
      _write('saveBool', key, () => _secure.writeBool(key, value));

  @override
  Future<bool?> getBool(String key) =>
      _read('getBool', key, () => _secure.readBool(key));

  @override
  Future<void> saveDouble(String key, double value) =>
      _write('saveDouble', key, () => _secure.writeDouble(key, value));

  @override
  Future<double?> getDouble(String key) =>
      _read('getDouble', key, () => _secure.readDouble(key));

  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) =>
      _write('saveJson', key, () => _secure.writeJson(key, value));

  @override
  Future<Map<String, dynamic>?> getJson(String key) =>
      _read('getJson', key, () => _secure.readJson(key));

  @override
  Future<void> remove(String key) =>
      _write('remove', key, () => _secure.delete(key));

  @override
  Future<void> clear() => _write('clear', null, _secure.clear);

  @override
  Future<Set<String>> getKeys() async =>
      await _read('getKeys', null, _secure.keys) ?? const <String>{};

  Future<T?> _read<T>(
    String operation,
    String? key,
    Future<T?> Function() body,
  ) async {
    try {
      return await body();
    } on SecureStorageException catch (e, stackTrace) {
      _log(operation, key, e, stackTrace);
      return null;
    }
  }

  Future<void> _write(
    String operation,
    String? key,
    Future<void> Function() body,
  ) async {
    try {
      await body();
    } on SecureStorageException catch (e, stackTrace) {
      _log(operation, key, e, stackTrace);
    }
  }

  static void _log(
    String operation,
    String? key,
    SecureStorageException error,
    StackTrace stackTrace,
  ) {
    final target = key == null ? '' : ' key=$key';
    AppLogger.e('[StorageService] $operation failed$target', error, stackTrace);
  }
}

/// The production [StorageService] for code that runs outside the DI
/// container (WorkManager background isolates). Mirrors the registration in
/// `configureDependencies`, so both read and write the same store.
StorageService createStandaloneStorageService() => StorageServiceImpl(
  SecureStorage(
    const FlutterSecureStorageBackend(),
  ).namespaced(SecureStorage.appNamespace),
);
