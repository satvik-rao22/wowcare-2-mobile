// theme_provider.dart
import 'package:flutter/material.dart';

import '../../../util/app_themes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _currentTheme = lightTheme;

  ThemeData get currentTheme => _currentTheme;

  void toggleTheme() {
    print('theme toggle entered');
    _currentTheme = _currentTheme == lightTheme ? darkTheme : lightTheme;
    notifyListeners();
  }
}

// theme_bloc.dart
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter/material.dart';
// import '../../../util/app_themes.dart';
// import 'theme_event.dart';
// import 'theme_state.dart';

// class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
//   ThemeBloc() : super(ThemeState(themeData: lightTheme)) {
//     on<ToggleThemeEvent>((event, emit) {
//       final newTheme = state.themeData == lightTheme ? darkTheme : lightTheme;
//       emit(ThemeState(themeData: newTheme));
//     });
//   }
// }
