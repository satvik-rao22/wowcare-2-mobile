import 'dart:convert';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/auth/models/login_response_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheLoginResponse(LoginResponseModel response);
  Future<LoginResponseModel?> getCachedLoginResponse();
  Future<bool> isCacheValid();
  Future<void> clearCache();
  Future<void> saveCredentials(String username, String password, bool rememberMe);
  Future<Map<String, String?>> getSavedCredentials();
  Future<void> clearCredentials();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this._storage);

  final StorageService _storage;

  @override
  Future<void> cacheLoginResponse(LoginResponseModel response) async {
    // Save cache with timestamp
    await _storage.saveJson(StorageKeys.loginCacheKey, response.toJson());
    await _storage.saveInt(
      StorageKeys.loginCacheTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );

    // Save individual fields for quick access
    await _storage.saveString(StorageKeys.accessToken, response.accessToken);
    await _storage.saveString(StorageKeys.refreshToken, response.refreshToken);
    await _storage.saveInt(StorageKeys.tokenExpiresIn, response.expiresIn);
    await _storage.saveInt(StorageKeys.refreshExpiresIn, response.refreshExpiresIn);
    await _storage.saveString(StorageKeys.tokenType, response.tokenType);
    await _storage.saveString(StorageKeys.userCode, response.userCode);
    await _storage.saveString(StorageKeys.email, response.email);
    await _storage.saveString(StorageKeys.displayName, response.displayName);
    await _storage.saveBool(StorageKeys.firstLogin, response.firstLogin);
    await _storage.saveString(
      StorageKeys.roles,
      jsonEncode(response.roles.map((r) => r.toJson()).toList()),
    );

    // Save organization code from first role (if available)
    if (response.roles.isNotEmpty && response.roles.first.organizationCode.isNotEmpty) {
      await _storage.saveString(
        StorageKeys.organizationCode,
        response.roles.first.organizationCode,
      );
    }
  }

  @override
  Future<LoginResponseModel?> getCachedLoginResponse() async {
    final cached = await _storage.getJson(StorageKeys.loginCacheKey);
    if (cached == null) return null;

    try {
      return LoginResponseModel.fromJson(cached);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isCacheValid() async {
    final timestamp = await _storage.getInt(StorageKeys.loginCacheTimestamp);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    return difference < StorageKeys.cacheValidDuration;
  }

  @override
  Future<void> clearCache() async {
    await _storage.remove(StorageKeys.loginCacheKey);
    await _storage.remove(StorageKeys.loginCacheTimestamp);
    await _storage.remove(StorageKeys.accessToken);
    await _storage.remove(StorageKeys.refreshToken);
    await _storage.remove(StorageKeys.tokenExpiresIn);
    await _storage.remove(StorageKeys.refreshExpiresIn);
    await _storage.remove(StorageKeys.tokenType);
    await _storage.remove(StorageKeys.userCode);
    await _storage.remove(StorageKeys.email);
    await _storage.remove(StorageKeys.displayName);
    await _storage.remove(StorageKeys.firstLogin);
    await _storage.remove(StorageKeys.roles);
    await _storage.remove(StorageKeys.organizationCode);
  }

  @override
  Future<void> saveCredentials(String username, String password, bool rememberMe) async {
    if (rememberMe) {
      await _storage.saveString(StorageKeys.username, username);
      await _storage.saveString(StorageKeys.password, password);
    } else {
      await _storage.remove(StorageKeys.username);
      await _storage.remove(StorageKeys.password);
    }
    await _storage.saveBool(StorageKeys.rememberMe, rememberMe);
  }

  @override
  Future<Map<String, String?>> getSavedCredentials() async {
    final username = await _storage.getString(StorageKeys.username);
    final password = await _storage.getString(StorageKeys.password);
    return {
      'username': username,
      'password': password,
    };
  }

  @override
  Future<void> clearCredentials() async {
    await _storage.remove(StorageKeys.username);
    await _storage.remove(StorageKeys.password);
    await _storage.remove(StorageKeys.rememberMe);
  }
}
