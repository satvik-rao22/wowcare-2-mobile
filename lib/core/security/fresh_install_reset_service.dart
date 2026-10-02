import 'package:wowcare/core/security/install_marker.dart';
import 'package:wowcare/core/storage/secure_storage.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// On a fresh install, wipes everything the secure store still holds from a
/// previous install.
///
/// The iOS Keychain survives app uninstall. In the SharedPreferences era that
/// only mattered for the "Remember me" credentials (the session itself was in
/// SharedPreferences, which the OS wiped); now that the whole session lives in
/// the secure store, a reinstall would otherwise come back signed in as the
/// previous owner. The [InstallMarker] file — which the OS does remove on
/// uninstall — is the fresh-install signal; when it is missing, everything is
/// wiped and the marker is created, which reproduces the observable behaviour
/// of the old code (session gone, remembered credentials gone).
///
/// The credentials are cleared through their owners as well as through
/// [SecureStorage.wipeAll]: on iOS a `deleteAll` is scoped to the configured
/// accessibility class, while the owners' key-by-key deletes match any class,
/// so tokens written by the pre-backend token code are covered too.
///
/// Wipe first, marker second: a crash in between costs nothing but a repeat
/// of an already-empty wipe on the next launch, whereas the opposite order
/// could leave a previous install's session behind for good.
class FreshInstallResetService {
  FreshInstallResetService({
    required InstallMarker installMarker,
    required SecureStorage secureStorage,
    required Future<void> Function() clearSecureCredentials,
  }) : _installMarker = installMarker,
       _secureStorage = secureStorage,
       _clearSecureCredentials = clearSecureCredentials;

  final InstallMarker _installMarker;
  final SecureStorage _secureStorage;

  /// Clears the auth tokens AND the "Remember me" credentials via their
  /// owners (TokenRefreshService, SecureCredentialStore).
  final Future<void> Function() _clearSecureCredentials;

  /// Returns true when this launch was a fresh install and the store was
  /// wiped. Throws on failure; the caller decides how loud to be.
  Future<bool> runIfFreshInstall() async {
    if (await _installMarker.exists()) return false;
    await _clearSecureCredentials();
    await _secureStorage.wipeAll();
    await _installMarker.create();
    AppLogger.i('[FreshInstall] fresh install: secure store wiped');
    return true;
  }
}
