import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/user_details_school_roles.dart';
import 'package:wowcare/domain/features/communication/services/messaging_session.dart';

/// [MessagingSession] backed by the app's [StorageService] — the one place the
/// forbidden `StorageService` type is allowed to appear for messaging (the data
/// layer). Each method forwards to the exact same read the cubits used before.
class MessagingSessionImpl implements MessagingSession {
  MessagingSessionImpl(this._storage);

  final StorageService _storage;

  @override
  Future<String?> userCode() => _storage.getString(StorageKeys.userCode);

  @override
  Future<String?> schoolCode() => _storage.getString(StorageKeys.schoolCode);

  @override
  Future<String?> organizationCode() =>
      _storage.getString(StorageKeys.organizationCode);

  @override
  Future<String?> staffCode() => _storage.getString(StorageKeys.staffCode);

  @override
  Future<String?> displayName() => _storage.getString(StorageKeys.displayName);

  @override
  Future<String?> activeSchoolRole() =>
      _storage.getString(StorageKeys.activeSchoolRole);

  @override
  Future<String> activeBackendRole() => resolveActiveBackendRole(_storage);

  @override
  Future<String?> readComposerDraft(String key) => _storage.getString(key);

  @override
  Future<void> saveComposerDraft(String key, String text) =>
      _storage.saveString(key, text);

  @override
  Future<void> removeComposerDraft(String key) => _storage.remove(key);
}
