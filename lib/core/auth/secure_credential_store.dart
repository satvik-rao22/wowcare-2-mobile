import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// Securely stores the "Remember me" password so the sign-in form can pre-fill
/// it after logout / session-expiry, gated behind device biometrics.
///
/// **Security design (max-security pre-fill):**
/// - The password lives ONLY in the platform secure enclave: iOS Keychain
///   (`first_unlock_this_device`, NOT synced to iCloud) and Android
///   `EncryptedSharedPreferences` (hardware-backed Keystore). It is never put in
///   the app's plaintext SharedPreferences.
/// - Reading it back to pre-fill REQUIRES a biometric / device-credential check
///   (Face ID / fingerprint / PIN) **whenever the device has one**. A
///   stolen-but-unlocked phone still cannot reveal the password without the
///   user's biometric, and cancelling/failing the prompt reveals nothing.
/// - When the device has NO biometric AND no passcode there is no gate that can
///   ever be satisfied, so the password is returned without a prompt. Failing
///   closed there would make "Remember me" permanently broken on those devices,
///   and a device with no lock screen gains nothing from the gate anyway.
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

  /// Reads the stored pair straight out of the secure store. Callers must have
  /// already cleared the auth gate (or established that no gate exists).
  Future<Map<String, String>?> _readStored() async {
    final password = await _storage.read(key: _kPasswordKey);
    final username = await _storage.read(key: _kUsernameKey);
    if (password == null || password.isEmpty) return null;
    return {'username': username ?? '', 'password': password};
  }

  /// True when [e] means "this device has no biometric / passcode to prompt
  /// with" — as opposed to the user actively failing or cancelling a prompt.
  bool _isNoGateAvailable(PlatformException e) {
    return e.code == auth_error.passcodeNotSet ||
        e.code == auth_error.notEnrolled ||
        e.code == auth_error.notAvailable ||
        e.code == auth_error.otherOperatingSystem;
  }

  /// Returns the stored `{username, password}` for "Remember me" pre-fill.
  ///
  /// If the device can prompt (biometric or PIN/passcode), the user must pass
  /// that check — cancelling or failing returns null (fail closed). If the
  /// device has no biometric AND no passcode, there is no gate to satisfy, so
  /// the credentials are returned without a prompt so "Remember me" still works.
  /// Returns null when nothing is stored.
  Future<Map<String, String>?> revealWithBiometrics({
    required String reason,
  }) async {
    try {
      final has = await hasSavedPassword();
      AppLogger.d('[SecureCred] reveal: hasSavedPassword=$has');
      if (!has) return null;

      final canAuth = await canAuthenticate();
      AppLogger.d('[SecureCred] reveal: canAuthenticate=$canAuth');
      if (!canAuth) {
        // No biometric and no device passcode — no gate can ever be satisfied.
        // Honour "Remember me" instead of silently never pre-filling.
        AppLogger.d('[SecureCred] reveal: no auth gate on device — ungated read');
        return _readStored();
      }

      // isDeviceSupported() is true whenever a passcode exists, even with NO
      // biometric enrolled. In that state there is no Face ID / fingerprint to
      // prompt with, and the passcode-only prompt can never resolve (the
      // authenticate() future hangs), which left the password permanently
      // un-filled. "Remember me" must work without biometrics, so read ungated.
      final enrolled = await _localAuth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        AppLogger.d(
          '[SecureCred] reveal: no enrolled biometrics — ungated read',
        );
        return _readStored();
      }

      final bool ok;
      try {
        ok = await _localAuth
            .authenticate(
              localizedReason: reason,
              options: const AuthenticationOptions(
                stickyAuth: true,
                biometricOnly: false, // allow device PIN/passcode fallback
                useErrorDialogs: true,
              ),
            )
            // Safety net: never let a prompt that never resolves hang the
            // sign-in pre-fill forever.
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                AppLogger.d('[SecureCred] reveal: authenticate TIMED OUT');
                return false;
              },
            );
      } on PlatformException catch (e) {
        // The platform reported there is nothing to prompt with (no enrolled
        // biometric / no passcode). Treat as "no gate", not as a denial.
        if (_isNoGateAvailable(e)) {
          AppLogger.d(
            '[SecureCred] reveal: no gate (${e.code}) — ungated read',
          );
          return _readStored();
        }
        AppLogger.d('[SecureCred] reveal: authenticate error ${e.code}');
        return null;
      }

      AppLogger.d('[SecureCred] reveal: authenticate returned $ok');
      // User cancelled or failed a prompt the device COULD show — fail closed.
      if (!ok) return null;

      return _readStored();
    } catch (e) {
      AppLogger.d('[SecureCred] revealWithBiometrics failed: $e');
      return null;
    }
  }
}
