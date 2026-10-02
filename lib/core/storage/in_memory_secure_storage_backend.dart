import 'package:wowcare/core/storage/secure_storage_backend.dart';

/// Map-backed [SecureStorageBackend]. Nothing is encrypted or persisted.
///
/// For tests, and as the explicit stand-in when a target has no secure store
/// at all. Never register it in a production build.
class InMemorySecureStorageBackend implements SecureStorageBackend {
  InMemorySecureStorageBackend([Map<String, String>? seed])
    : _data = <String, String>{...?seed};

  final Map<String, String> _data;

  /// Read-only view of the current contents, for assertions.
  Map<String, String> get snapshot => Map<String, String>.unmodifiable(_data);

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<Map<String, String>> readAll() async => Map<String, String>.of(_data);

  @override
  Future<void> deleteAll() async => _data.clear();
}
