import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/presentation/features/dashboard/viewmodels/admin_dashboard_viewmodel.dart';

part 'admin_dashboard_state.dart';

/// Owns the admin dashboard card list and drag-and-drop reorder logic.
///
/// Replaces [AdminDashboardViewModel] (ChangeNotifier) with a proper Cubit so
/// the dashboard strictly follows Cubit / BLoC + Clean Architecture.
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit()
      : super(
          AdminDashboardState(
            cards: List<AdminDashboardCard>.of(AdminDashboardCard.values),
          ),
        );

  /// Moves the card at [oldIndex] to [newIndex].
  ///
  /// Accepts raw indices from [SliverReorderableList] and applies the standard
  /// downward-move adjustment before mutating the list.
  void reorderCard(int oldIndex, int newIndex) {
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (oldIndex == target) return;
    final updated = List<AdminDashboardCard>.of(state.cards);
    final card = updated.removeAt(oldIndex);
    updated.insert(target, card);
    emit(state.copyWith(cards: updated));
  }
}
