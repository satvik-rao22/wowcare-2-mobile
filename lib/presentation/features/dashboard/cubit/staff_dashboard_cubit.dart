import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/presentation/features/dashboard/viewmodels/staff_dashboard_viewmodel.dart';

part 'staff_dashboard_state.dart';

/// Owns the staff dashboard card list and drag-and-drop reorder logic.
///
/// Replaces [StaffDashboardViewModel] (ChangeNotifier).
class StaffDashboardCubit extends Cubit<StaffDashboardState> {
  StaffDashboardCubit()
    : super(
        StaffDashboardState(
          cards: List<StaffDashboardCard>.of(StaffDashboardCard.values),
        ),
      );

  void reorderCard(int oldIndex, int newIndex) {
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (oldIndex == target) return;
    final updated = List<StaffDashboardCard>.of(state.cards);
    final card = updated.removeAt(oldIndex);
    updated.insert(target, card);
    emit(state.copyWith(cards: updated));
  }
}
