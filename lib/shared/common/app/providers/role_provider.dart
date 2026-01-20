import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleProvider extends ChangeNotifier {
  static const String _roleKey = 'selected_role';
  String _role = 'admin'; // Default to admin

  RoleProvider() {
    _loadRole();
  }

  String get role => _role;
  bool get isParent => _role == 'parent';
  bool get isAdmin => _role == 'admin';

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    _role = prefs.getString(_roleKey) ?? 'admin';
    notifyListeners();
  }

  Future<void> setRole(String role) async {
    if (role != 'admin' && role != 'parent') {
      return;
    }
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role);
    notifyListeners();
  }

  Future<void> clearRole() async {
    _role = 'admin';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    notifyListeners();
  }
}
