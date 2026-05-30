import 'package:flutter/foundation.dart';

/// Cards rendered on the staff dashboard, declared in default display order.
enum StaffDashboardCard {
  myDay,
  ratioMonitoring,
  // events,
  // todo,
  myShifts,
  myAttendance,
  // classroomProgress,
}

/// View-model for [StaffDashboard].
///
/// UI-only for now: it owns the (re-orderable) list of dashboard cards, the
/// greeting name, and the pull-to-refresh hook. This is the single seam for
/// real data wiring later — card visibility can be derived here from the
/// signed-in staff member's authorities without the view needing any change.
class StaffDashboardViewModel extends ChangeNotifier {
  /// Live, user-reorderable card order. Seeded from the enum's default order.
  final List<StaffDashboardCard> _cards = List<StaffDashboardCard>.of(
    StaffDashboardCard.values,
  );

  bool _isRefreshing = false;

  /// Whether a refresh cycle is currently in flight.
  bool get isRefreshing => _isRefreshing;

  /// Name shown in the "Welcome {name}" header. Mock data for now.
  String get userName => 'Sarah Johnson';

  /// Cards currently visible on the dashboard, in render order.
  List<StaffDashboardCard> get visibleCards =>
      List<StaffDashboardCard>.unmodifiable(_cards);

  /// Moves the card at [oldIndex] to [newIndex] (drag-and-drop reorder).
  ///
  /// Accepts the raw indices reported by `SliverReorderableList` and applies
  /// the standard downward-move adjustment.
  void reorderCard(int oldIndex, int newIndex) {
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (oldIndex == target) return;
    final card = _cards.removeAt(oldIndex);
    _cards.insert(target, card);
    notifyListeners();
  }

  /// Pull-to-refresh hook. UI-only — simulates a refresh round-trip so the
  /// indicator behaves naturally. Replace the delay with real fetches later.
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _isRefreshing = false;
    notifyListeners();
  }
}
