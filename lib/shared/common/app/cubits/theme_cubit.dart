import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Which of `MaterialApp`'s two themes is live.
///
/// Holds a [ThemeMode] rather than a [ThemeData] so the themes stay constant
/// and only the choice moves. Once a skin can be picked at runtime, the skin
/// id joins this state and nothing else in the tree changes.
///
/// Defaults to [ThemeMode.light] on purpose, not [ThemeMode.system]: dark mode
/// still renders the light palette, so following the OS would hand a
/// dark-mode phone a half-built theme. See the DARK THEME header in
/// `lib/core/utils/app_themes.dart`.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  void setMode(ThemeMode mode) => emit(mode);

  /// Kept for the planned dark mode. Nothing calls it yet.
  void toggleTheme() =>
      emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
