import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageService {
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<void> saveInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> saveBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> saveJson(String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> getJson(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class StorageServiceImpl implements StorageService {
  StorageServiceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) {
    return Future.value(_prefs.getString(key));
  }

  @override
  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<int?> getInt(String key) {
    return Future.value(_prefs.getInt(key));
  }

  @override
  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<bool?> getBool(String key) {
    return Future.value(_prefs.getBool(key));
  }

  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    await _prefs.setString(key, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
