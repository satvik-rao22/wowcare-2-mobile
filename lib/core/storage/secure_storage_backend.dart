/// The single seam between the app and whatever actually persists its data.
///
/// Everything above this interface — [SecureStorage], `StorageServiceImpl`,
/// the auth stores — is backend-agnostic. Swapping the persistence layer (a
/// different plugin, a native module, an encrypted file) means implementing
/// these five string-in/string-out methods and changing one registration in
/// `configureDependencies`. Nothing else in the app imports a storage plugin.
///
/// Contract:
///  * Values are opaque UTF-8 strings; typed encoding lives in [SecureStorage].
///  * [read] returns `null` for a missing key and never throws for "absent".
///  * Any platform failure surfaces as a [SecureStorageException], so callers
///    can tell "no value" apart from "could not reach the store".
///  * Implementations must be safe to call from any isolate that has plugins
///    registered (the WorkManager isolate builds its own instance).
abstract interface class SecureStorageBackend {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  /// Deleting a key that does not exist is a successful no-op.
  Future<void> delete(String key);

  /// Every key/value this backend can see. Used once to prime the in-memory
  /// cache and for namespace-wide operations (`keys()`, `clear()`).
  Future<Map<String, String>> readAll();

  /// Removes every entry. Fresh-install wipe only.
  Future<void> deleteAll();
}

/// Raised by a [SecureStorageBackend] when the platform store rejects an
/// operation. [cause] is the underlying platform error, kept for logging.
class SecureStorageException implements Exception {
  const SecureStorageException(this.operation, {this.key, this.cause});

  /// The backend operation that failed (`read`, `write`, ...).
  final String operation;

  /// The key involved, when the operation had one.
  final String? key;

  /// The underlying error, typically a `PlatformException`.
  final Object? cause;

  @override
  String toString() {
    final target = key == null ? '' : ' key=$key';
    return 'SecureStorageException($operation$target): $cause';
  }
}
