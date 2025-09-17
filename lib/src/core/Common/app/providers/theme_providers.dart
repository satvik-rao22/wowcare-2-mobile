// // theme_provider.dart
// import 'package:flutter/material.dart';
// import '../../../util/app_themes.dart';

// class ThemeProvider with ChangeNotifier {
//   ThemeData _currentTheme = lightTheme;

//   ThemeData get currentTheme => _currentTheme;

//   void toggleTheme() {
//     print('theme toggle entered');
//     _currentTheme = _currentTheme == lightTheme ? darkTheme : lightTheme;
//     notifyListeners();
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../util/app_themes.dart';

class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(lightTheme);

  void toggleTheme() {
    print('theme toggle entered');
    emit(state == lightTheme ? darkTheme : lightTheme);
  }
}
