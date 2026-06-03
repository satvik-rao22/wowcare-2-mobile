import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/dashboard/constants/dashboard_constants.dart';

part 'admin_dashboard_state.dart';

/// Owns the admin dashboard card list, drag-and-drop reorder logic, and the
/// logged-in user's display name shown in the welcome header.
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit()
      : super(
          AdminDashboardState(
            cards: List<AdminDashboardCard>.of(AdminDashboardCard.values),
          ),
        );

  /// Reads the logged-in user's display name from local storage and emits it
  /// so the welcome header shows the correct name immediately.
  Future<void> loadUserName() async {
    final storage = serviceLocator<StorageService>();
    final name = (await storage.getString(StorageKeys.displayName) ?? '').trim();
    if (!isClosed) {
      emit(state.copyWith(userName: name.isNotEmpty ? name : null));
    }
  }

  /// Moves the card at [oldIndex] to [newIndex].
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
