// theme_provider.dart
import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = lightTheme;

  ThemeData get currentTheme => _currentTheme;

  void toggleTheme() {
    print('theme toggle entered');
    _currentTheme = _currentTheme == lightTheme ? darkTheme : lightTheme;
    notifyListeners();
  }
}
