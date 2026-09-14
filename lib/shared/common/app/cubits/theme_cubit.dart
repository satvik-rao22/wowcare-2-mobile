import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/app_themes.dart';

/// App theme state holder (Bloc replacement for the old `ThemeProvider`).
///
/// State is the active [ThemeData]. Defaults to [lightTheme]; [toggleTheme]
/// swaps between light and dark. Behaviour mirrors the previous ChangeNotifier
/// exactly.
class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(lightTheme);

  ThemeData get currentTheme => state;

  void toggleTheme() {
    emit(state == lightTheme ? darkTheme : lightTheme);
  }
}
