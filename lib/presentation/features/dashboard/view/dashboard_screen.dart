import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/presentation/features/dashboard/view/admin_dashboard.dart';
import 'package:wowcare/presentation/features/dashboard/view/parent_dashboard.dart';
import 'package:wowcare/presentation/features/dashboard/view/staff_dashboard.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_persona_loading.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';

/// Dispatches to the role-appropriate dashboard:
/// - parent/guardian → [ParentDashboard]
/// - staff (Lead/Associate/Assistant teacher, Floater, …) → [StaffDashboard]
/// - admin / director → [AdminDashboard]
///
/// Stateful so it can rebuild its child subtree on a school switch: the
/// dashboard is the kept-alive root of the shell's first branch, so without
/// this it would keep showing the previous school's ratio/summary data until a
/// manual pull-to-refresh.
///
/// Tab-return refresh is NOT handled here — see [AdminDashboard],
/// [StaffDashboard] and [ParentDashboard], each of which mixes in
/// `TabBecameVisibleMixin` itself and calls `refresh()` on the coordinator it
/// owns. Doing it here would mean re-keying the subtree, which re-resolves the
/// coordinator (a GetIt `registerFactory`) and re-runs the full cold-open
/// fan-out on every tab switch.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const String routeName = DashboardRoutes.root;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SchoolSwitchReloadMixin {
  // Re-keys the dispatched dashboard on a school switch so the whole subtree
  // (ratio monitoring + every summary card) is recreated and reloads fresh.
  // A school switch is the one case that genuinely needs recreation rather
  // than a refresh: the cubits hold the previous school's data.
  int _schoolReloadEpoch = 0;

  @override
  void onSchoolSwitched() {
    if (!mounted) return;
    setState(() => _schoolReloadEpoch++);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();

    // Last-resort guard: kiosk users must never render dashboard content.
    // This catches notification deep-links, programmatic context.go('/dashboard'),
    // or any other route that bypasses the earlier kiosk checks.
    if (role.isKiosk) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(KioskRoutes.root);
      });
      return const SizedBox.shrink();
    }

    // `RoleState.role` defaults to 'admin' — the most privileged persona — and
    // it holds that value until RoleCubit has actually emitted one, which also
    // happens again after `clearRole()`/`resetSessionForLogout()`. Dispatching
    // before then silently rendered [AdminDashboard] for a guardian or teacher
    // and fired ~26 admin-only requests they are not authorised for; every one
    // of those 403s lands in a card that renders zeros indistinguishable from
    // real data, so the wrong dashboard looked plausible rather than broken.
    //
    // Wait for a real persona instead. The window is short (RoleCubit resolves
    // from storage before the server round-trip) and the normal splash → login
    // path has already resolved it before this screen is reached.
    if (!role.isPersonaResolved) {
      return const DashboardPersonaLoading();
    }

    final Widget dashboard;
    if (role.isParent) {
      dashboard = const ParentDashboard();
    } else if (role.isStaff) {
      dashboard = const StaffDashboard();
    } else {
      // Admin/director. Explicit rather than a fallthrough so an unrecognised
      // role can never silently land on the most privileged dashboard.
      dashboard = const AdminDashboard();
    }

    return KeyedSubtree(
      key: ValueKey<int>(_schoolReloadEpoch),
      child: dashboard,
    );
  }
}
