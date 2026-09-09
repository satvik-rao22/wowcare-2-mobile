import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/auth/secure_credential_store.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';

/// On a fresh install, clears the Keychain-backed secure credential store so
/// "Remember me" data from a previous install (which survives uninstall on iOS)
/// doesn't leak into the new install. Detected via a SharedPreferences marker,
/// which IS cleared on uninstall.
Future<void> resetSecureStoreOnFreshInstall() async {
  try {
    final storage = serviceLocator<StorageService>();
    final alreadyInstalled =
        await storage.getBool(StorageKeys.appInstalledMarker) ?? false;
    if (!alreadyInstalled) {
      await SecureCredentialStore().clear();
      await storage.saveBool(StorageKeys.appInstalledMarker, true);
      AppLogger.d('[FreshInstall] Wiped Keychain secure store on fresh install');
    }
  } catch (e) {
    AppLogger.d('[FreshInstall] reset failed (non-fatal): $e');
  }
}
