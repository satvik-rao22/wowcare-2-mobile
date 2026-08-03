import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_cubit.dart';
import 'package:wowcare/presentation/features/communication/cubit/unread_badge_state.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/shared/common/app/cubit/bottom_navigation_item.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

class BottomNavigationState extends Equatable {
  const BottomNavigationState({
    this.isParent = false,
    this.visibleItems = const <BottomNavigationItem>[],
    this.selectedItem,
    this.unreadBadgeCount = 0,
    this.pendingNavigationItem,
    this.pendingNavigationSeq = 0,
  });

  /// True for the parent/guardian persona — determines item order, labels
  /// (e.g. "Communication" vs "Messages") and which items can appear at all
  /// (Classrooms is staff/admin-only, Billing is parent-only).
  final bool isParent;

  /// Ordered items visible for the current persona + module access.
  final List<BottomNavigationItem> visibleItems;

  /// The item that should render highlighted. `null` means nothing is
  /// highlighted (e.g. a dashboard-branch drill-down screen).
  final BottomNavigationItem? selectedItem;

  /// Aggregate unread count shown on the Communication/Messages badge.
  final int unreadBadgeCount;

  /// One-shot navigation intent set by [BottomNavigationCubit.selectItem].
  /// Consumed by the `BlocListener` in `CustomNavigationBar` (the View layer
  /// owns the actual go_router call — a Cubit must not hold a BuildContext)
  /// and never touched by [BottomNavigationCubit.syncFromRoute], so passive
  /// route observation can never re-trigger a stale navigation intent.
  final BottomNavigationItem? pendingNavigationItem;
  final int pendingNavigationSeq;

  BottomNavigationState withRoleDerived({
    required bool isParent,
    required List<BottomNavigationItem> visibleItems,
    required int unreadBadgeCount,
  }) {
    return BottomNavigationState(
      isParent: isParent,
      visibleItems: visibleItems,
      selectedItem: selectedItem,
      unreadBadgeCount: unreadBadgeCount,
      pendingNavigationItem: pendingNavigationItem,
      pendingNavigationSeq: pendingNavigationSeq,
    );
  }

  BottomNavigationState withSelectedItem(BottomNavigationItem? item) {
    return BottomNavigationState(
      isParent: isParent,
      visibleItems: visibleItems,
      selectedItem: item,
      unreadBadgeCount: unreadBadgeCount,
      pendingNavigationItem: pendingNavigationItem,
      pendingNavigationSeq: pendingNavigationSeq,
    );
  }

  BottomNavigationState withPendingNavigation(
    BottomNavigationItem item,
    int seq,
  ) {
    return BottomNavigationState(
      isParent: isParent,
      visibleItems: visibleItems,
      selectedItem: selectedItem,
      unreadBadgeCount: unreadBadgeCount,
      pendingNavigationItem: item,
      pendingNavigationSeq: seq,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isParent,
    visibleItems,
    selectedItem,
    unreadBadgeCount,
    pendingNavigationItem,
    pendingNavigationSeq,
  ];
}

/// Single source of truth for the bottom navigation bar: which items are
/// visible for the signed-in persona/module access, which one is currently
/// selected, and the aggregate unread badge count. Reacts to [RoleCubit] and
/// [UnreadBadgeCubit] so callers never need to re-derive visibility rules.
///
/// MVVM golden rule (same as [RoleCubit]): this ViewModel has no View
/// dependency (no BuildContext, widgets, navigation). [selectItem] only
/// records a one-shot navigation intent; the actual go_router transition is
/// performed by a `BlocListener` in `CustomNavigationBar`, which does have a
/// BuildContext.
class BottomNavigationCubit extends Cubit<BottomNavigationState> {
  BottomNavigationCubit({
    required RoleCubit roleCubit,
    required UnreadBadgeCubit unreadBadgeCubit,
  }) : _roleCubit = roleCubit,
       _unreadBadgeCubit = unreadBadgeCubit,
       super(const BottomNavigationState()) {
    _recompute();
    _roleSub = _roleCubit.stream.listen((_) => _recompute());
    _badgeSub = _unreadBadgeCubit.stream.listen((_) => _recompute());
  }

  final RoleCubit _roleCubit;
  final UnreadBadgeCubit _unreadBadgeCubit;
  late final StreamSubscription<RoleState> _roleSub;
  late final StreamSubscription<UnreadBadgeState> _badgeSub;
  int _navSeq = 0;

  void _safeEmit(BottomNavigationState newState) {
    if (!isClosed) emit(newState);
  }

  void _recompute() {
    final isParent = _roleCubit.isParent;
    final isStaff = _roleCubit.isStaff;

    final showAttendance = isParent
        ? _roleCubit.canOpenModule(AppAccessModules.studentAttendance)
        : _roleCubit.canAccessAny([
            AppAccessModules.studentAttendance,
            AppAccessModules.staffAttendance,
          ]);
    final showClassrooms =
        !isParent && _roleCubit.canAccessAny([AppAccessModules.classroom]);
    final showActivities = _roleCubit.canReadModule(
      AppAccessModules.dailyActivity,
    );
    final showCommunication = isParent
        ? _roleCubit.canAccessAny([
            AppAccessModules.parentMessaging,
            AppAccessModules.newsletter,
          ])
        : _roleCubit.canAccessAny([
            AppAccessModules.staffMessaging,
            AppAccessModules.parentMessaging,
            AppAccessModules.newsletter,
          ]);
    final showBilling =
        isParent &&
        _roleCubit.canAccessAny([
          AppAccessModules.transaction,
          AppAccessModules.invoices,
          AppAccessModules.recurringPlans,
          AppAccessModules.billingSettings,
        ]);

    final items = <BottomNavigationItem>[
      BottomNavigationItem.dashboard,
      if (showAttendance) BottomNavigationItem.attendance,
      if (showClassrooms) BottomNavigationItem.classrooms,
      if (showActivities) BottomNavigationItem.activities,
      if (showCommunication) BottomNavigationItem.communication,
      if (showBilling) BottomNavigationItem.billing,
    ];

    // Mirrors the drawer's per-module badge rules: staffMessaging ->
    // STAFF_DIRECT, parentMessaging -> ROOM_CHAT, adminChat hidden for pure
    // staff — so the bottom-nav number always matches what the drawer shows.
    final showStaffMsg = _roleCubit.canReadModule(
      AppAccessModules.staffMessaging,
    );
    final showParentMsg = _roleCubit.canReadModule(
      AppAccessModules.parentMessaging,
    );
    final showAdminChat = !isStaff;
    final unread = _unreadBadgeCubit.state;
    final unreadTotal =
        (showStaffMsg ? unread.unreadFor(ConversationType.staffDirect) : 0) +
        (showParentMsg ? unread.unreadFor(ConversationType.roomChat) : 0) +
        (showAdminChat ? unread.unreadFor(ConversationType.adminChat) : 0);

    _safeEmit(
      state.withRoleDerived(
        isParent: isParent,
        visibleItems: items,
        unreadBadgeCount: unreadTotal,
      ),
    );
  }

  /// Records a one-shot intent to navigate to [item] — the single entry
  /// point for switching tabs from anywhere in the app, e.g.
  /// `context.read<BottomNavigationCubit>().selectItem(BottomNavigationItem.communication)`.
  /// The actual navigation is performed by `CustomNavigationBar`'s
  /// `BlocListener`.
  void selectItem(BottomNavigationItem item) {
    _navSeq++;
    _safeEmit(state.withPendingNavigation(item, _navSeq));
  }

  /// Passive sync from route changes (back navigation, deep links, or a
  /// forced branch switch performed as a side-effect of the Attendance
  /// popup) — updates the highlight only, never re-triggers navigation.
  void syncFromRoute(BottomNavigationItem? item) {
    if (item != state.selectedItem) {
      _safeEmit(state.withSelectedItem(item));
    }
  }

  @override
  Future<void> close() {
    _roleSub.cancel();
    _badgeSub.cancel();
    return super.close();
  }
}
