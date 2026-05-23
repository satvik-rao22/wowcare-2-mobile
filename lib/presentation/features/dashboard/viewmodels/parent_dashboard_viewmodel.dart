import 'package:flutter/foundation.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';

/// Cards rendered on the parent/guardian dashboard, in default display order.
enum ParentDashboardCard {
  myChildsDay,
  studentAttendance,
  studentBilling,
  studentNewsletters,
}

/// View-model for [ParentDashboard].
///
/// UI-only for now: it owns the (re-orderable) list of dashboard cards, the
/// greeting name, and the pull-to-refresh hook. This is the single seam for
/// real data wiring later — card visibility can be derived here from the
/// signed-in guardian's authorities without the view needing any change.
class ParentDashboardViewModel extends ChangeNotifier {
  ParentDashboardViewModel() {
    _loadLoggedInUserName();
  }

  /// Live, user-reorderable card order. Seeded from the enum's default order.
  final List<ParentDashboardCard> _cards = List<ParentDashboardCard>.of(
    ParentDashboardCard.values,
  );

  bool _isRefreshing = false;
  String _userName = 'there';

  /// Whether a refresh cycle is currently in flight.
  bool get isRefreshing => _isRefreshing;

  /// Name shown in the "Welcome {name}" header.
  String get userName => _userName;

  /// Cards currently visible on the dashboard, in render order.
  List<ParentDashboardCard> get visibleCards =>
      List<ParentDashboardCard>.unmodifiable(_cards);

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

  Future<void> _loadLoggedInUserName() async {
    try {
      final storage = serviceLocator<StorageService>();

      final displayName =
          (await storage.getString(StorageKeys.displayName) ?? '').trim();
      if (displayName.isNotEmpty) {
        _setUserName(displayName);
        return;
      }

      final firstName =
          (await storage.getString(StorageKeys.guardianProfileFirstName) ?? '')
              .trim();
      final lastName =
          (await storage.getString(StorageKeys.guardianProfileLastName) ?? '')
              .trim();
      final combined = [
        firstName,
        lastName,
      ].where((p) => p.isNotEmpty).join(' ');
      if (combined.isNotEmpty) {
        _setUserName(combined);
        return;
      }

      final email = (await storage.getString(StorageKeys.email) ?? '').trim();
      if (email.isNotEmpty) {
        _setUserName(email);
      }
    } catch (_) {
      // Non-blocking: keep the fallback "there".
    }
  }

  void _setUserName(String value) {
    final next = value.trim();
    if (next.isEmpty || next == _userName) return;
    _userName = next;
    notifyListeners();
  }
}
