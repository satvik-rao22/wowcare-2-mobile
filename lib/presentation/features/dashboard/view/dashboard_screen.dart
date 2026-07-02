import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/core/util/school_switch_events.dart';
import 'package:wowcare/presentation/features/dashboard/view/admin_dashboard.dart';
import 'package:wowcare/presentation/features/dashboard/view/parent_dashboard.dart';
import 'package:wowcare/presentation/features/dashboard/view/staff_dashboard.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Dispatches to the role-appropriate dashboard:
/// - staff (Lead/Associate/Assistant teacher, Floater, …) → [StaffDashboard]
/// - admin / director → [AdminDashboard]
/// - parent/guardian → placeholder until the parent dashboard is built
///
/// Stateful so it can rebuild its child subtree on a school switch: the
/// dashboard is the kept-alive root of the shell's first branch, so without
/// this it would keep showing the previous school's ratio/summary data until a
/// manual pull-to-refresh.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SchoolSwitchReloadMixin {
  // Re-keys the dispatched dashboard on a school switch so the whole subtree
  // (ratio monitoring + every summary card) is recreated and reloads fresh.
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
        if (context.mounted) context.go('/kiosk');
      });
      return const SizedBox.shrink();
    }

    final Widget dashboard = role.isParent
        ? const ParentDashboard()
        : role.isStaff
        ? const StaffDashboard()
        : const AdminDashboard();

    return KeyedSubtree(
      key: ValueKey<int>(_schoolReloadEpoch),
      child: dashboard,
    );
  }
}
