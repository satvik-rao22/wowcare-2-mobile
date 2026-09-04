import 'package:bloc/bloc.dart';

/// Minimal reusable cubit for a single boolean UI flag (expand/collapse,
/// highlight, etc.). Lets small billing card widgets stay free of `setState`.
class BoolToggleCubit extends Cubit<bool> {
  BoolToggleCubit({bool initial = false}) : super(initial);

  void toggle() => emit(!state);

  void set(bool value) {
    if (state == value) return;
    emit(value);
  }
}
