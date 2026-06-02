import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:wowcare/core/util/logger_service.dart';

/// Securely stores the "Remember me" password so the sign-in form can pre-fill
/// it after logout / session-expiry, gated behind device biometrics.
///
/// **Security design (max-security pre-fill):**
/// - The password lives ONLY in the platform secure enclave: iOS Keychain
///   (`first_unlock_this_device`, NOT synced to iCloud) and Android
///   `EncryptedSharedPreferences` (hardware-backed Keystore). It is never put in
///   the app's plaintext SharedPreferences.
/// - Reading it back to pre-fill REQUIRES a biometric / device-credential check
///   (Face ID / fingerprint / PIN). A stolen-but-unlocked phone still cannot
///   reveal the password without the user's biometric.
/// - It is written only when "Remember me" is checked on a successful login, and
///   wiped the moment "Remember me" is unchecked or a login fails (wrong
///   password). It deliberately SURVIVES logout and session-expiry so the form
///   can pre-fill — that is the product requirement.
class SecureCredentialStore {
  SecureCredentialStore({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
                synchronizable: false,
              ),
            ),
        _localAuth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const String _kPasswordKey = 'remember_me_password_v1';
  static const String _kUsernameKey = 'remember_me_username_v1';

  /// Persist the credentials for biometric-gated pre-fill. Call only when the
  /// user checked "Remember me" on a successful login.
  Future<void> save({
    required String username,
    required String password,
  }) async {
    try {
      await _storage.write(key: _kUsernameKey, value: username);
      await _storage.write(key: _kPasswordKey, value: password);
      AppLogger.d(
        '[SecureCred] saved user="$username" pwLen=${password.length}',
      );
    } catch (e) {
      AppLogger.d('[SecureCred] save failed: $e');
    }
  }

  /// Remove the stored password (and the secure-store username copy). Call when
  /// "Remember me" is unchecked or a login fails.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _kPasswordKey);
      await _storage.delete(key: _kUsernameKey);
    } catch (e) {
      AppLogger.d('[SecureCred] clear failed: $e');
    }
  }

  /// Whether a saved password exists (no biometric needed — just presence).
  Future<bool> hasSavedPassword() async {
    try {
      final v = await _storage.read(key: _kPasswordKey);
      return v != null && v.isNotEmpty;
    } catch (e) {
      AppLogger.d('[SecureCred] hasSavedPassword failed: $e');
      return false;
    }
  }

  /// True when the device can actually perform a biometric / device-credential
  /// check. If false, callers MUST NOT reveal the password (fail closed).
  Future<bool> canAuthenticate() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final enrolled = await _localAuth.getAvailableBiometrics();
      AppLogger.d(
        '[SecureCred] canAuth: deviceSupported=$supported '
        'canCheckBiometrics=$canCheck enrolled=$enrolled',
      );
      // isDeviceSupported() is true when a device credential (PIN/pattern/
      // passcode) OR biometrics exist — that's our gate (we allow PIN fallback).
      return supported;
    } catch (e) {
      AppLogger.d('[SecureCred] canAuthenticate failed: $e');
      return false;
    }
  }

  /// Prompts for biometrics / device credential and, only on success, returns
  /// the stored `{username, password}`. Returns null on cancel, failure, no
  /// stored value, or if the device can't authenticate (fail closed).
  Future<Map<String, String>?> revealWithBiometrics({
    required String reason,
  }) async {
    try {
      final has = await hasSavedPassword();
      AppLogger.d('[SecureCred] reveal: hasSavedPassword=$has');
      if (!has) return null;
      final canAuth = await canAuthenticate();
      AppLogger.d('[SecureCred] reveal: canAuthenticate=$canAuth');
      if (!canAuth) return null;

      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow device PIN/passcode fallback
          useErrorDialogs: true,
        ),
      );
      AppLogger.d('[SecureCred] reveal: authenticate returned $ok');
      if (!ok) return null;

      final password = await _storage.read(key: _kPasswordKey);
      final username = await _storage.read(key: _kUsernameKey);
      if (password == null || password.isEmpty) return null;
      return {'username': username ?? '', 'password': password};
    } catch (e) {
      AppLogger.d('[SecureCred] revealWithBiometrics failed: $e');
      return null;
    }
  }
}
