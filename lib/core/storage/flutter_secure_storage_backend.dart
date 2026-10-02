import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wowcare/core/storage/secure_storage_backend.dart';

/// [SecureStorageBackend] over `flutter_secure_storage`: the iOS Keychain and
/// Android `EncryptedSharedPreferences` (AES under a hardware-backed Keystore
/// master key).
///
/// This is the only file in the app that imports the plugin. Replace the
/// registration in `configureDependencies` to swap it out.
///
/// Two plugin instances are used on purpose. On iOS the plugin puts the
/// keychain accessibility class into the query for `readAll`, `delete` and
/// `deleteAll` whenever one is configured, which means a class-scoped
/// instance cannot see or remove items written under a different class. The
/// token store that predates this backend wrote with the plugin default
/// (`unlocked`), so [_writer] carries the class new items should get, while
/// [_reader] carries none and therefore matches every class. On Android both
/// instances resolve to the same preferences file; the iOS options are
/// ignored there.
class FlutterSecureStorageBackend implements SecureStorageBackend {
  const FlutterSecureStorageBackend({
    FlutterSecureStorage writer = defaultWriter,
    FlutterSecureStorage reader = defaultReader,
  }) : _writer = writer,
       _reader = reader;

  /// Android: `EncryptedSharedPreferences` (AES-256-GCM values, AES-256-SIV
  /// keys, Keystore master key). The pre-existing token and "Remember me"
  /// stores were written with this option, and the plugin keeps a *different*
  /// file per option, so turning it off would orphan every existing value.
  ///
  /// `resetOnError`: the Keystore master key can be invalidated out from
  /// under the app (OS upgrade, vendor Keystore bug, lock-screen change on
  /// some OEMs). Without this flag every read and write then throws until
  /// the user reinstalls, and since this store now holds the whole session
  /// that is an app that can never sign in again. With it the plugin discards
  /// the unreadable file and starts clean: the user signs in once more.
  static const AndroidOptions androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );

  /// iOS, for writes: `first_unlock_this_device`. Items are readable from the
  /// first unlock after boot onwards, including while the phone is locked,
  /// which the WorkManager geofence task needs (the default `unlocked` fails
  /// with `errSecInteractionNotAllowed` from a background isolate on a locked
  /// device). `ThisDevice` keeps items out of iCloud Keychain and device
  /// backups, so a session can never be restored onto another phone;
  /// `synchronizable: false` for the same reason.
  static const IOSOptions iosWriteOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  /// iOS, for reads and deletes: no accessibility class, so the query matches
  /// items of every class (see the class doc).
  static const IOSOptions iosReadOptions = IOSOptions(
    accessibility: null,
    synchronizable: false,
  );

  static const FlutterSecureStorage defaultWriter = FlutterSecureStorage(
    aOptions: androidOptions,
    iOptions: iosWriteOptions,
  );

  static const FlutterSecureStorage defaultReader = FlutterSecureStorage(
    aOptions: androidOptions,
    iOptions: iosReadOptions,
  );

  final FlutterSecureStorage _writer;
  final FlutterSecureStorage _reader;

  @override
  Future<String?> read(String key) =>
      _guard('read', key, () => _reader.read(key: key));

  @override
  Future<void> write(String key, String value) =>
      _guard('write', key, () => _writer.write(key: key, value: value));

  @override
  Future<void> delete(String key) =>
      _guard('delete', key, () => _reader.delete(key: key));

  @override
  Future<Map<String, String>> readAll() =>
      _guard('readAll', null, () => _reader.readAll());

  @override
  Future<void> deleteAll() =>
      _guard('deleteAll', null, () => _reader.deleteAll());

  Future<T> _guard<T>(
    String operation,
    String? key,
    Future<T> Function() body,
  ) async {
    try {
      return await body();
    } on SecureStorageException {
      rethrow;
    } catch (e) {
      throw SecureStorageException(operation, key: key, cause: e);
    }
  }
}
