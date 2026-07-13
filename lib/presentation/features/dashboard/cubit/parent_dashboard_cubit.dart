import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/presentation/features/dashboard/viewmodels/parent_dashboard_viewmodel.dart';

part 'parent_dashboard_state.dart';

/// Owns the parent dashboard card list and drag-and-drop reorder logic.
///
/// Replaces [ParentDashboardViewModel] (ChangeNotifier).
class ParentDashboardCubit extends Cubit<ParentDashboardState> {
  ParentDashboardCubit()
    : super(
        ParentDashboardState(
          cards: List<ParentDashboardCard>.of(ParentDashboardCard.values),
        ),
      );

  void reorderCard(int oldIndex, int newIndex) {
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (oldIndex == target) return;
    final updated = List<ParentDashboardCard>.of(state.cards);
    final card = updated.removeAt(oldIndex);
    updated.insert(target, card);
    emit(state.copyWith(cards: updated));
  }
}
