import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/dashboard/view/admin_dashboard.dart';
import 'package:wowcare/presentation/features/dashboard/view/parent_dashboard.dart';
import 'package:wowcare/presentation/features/dashboard/view/staff_dashboard.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Dispatches to the role-appropriate dashboard:
/// - staff (Lead/Associate/Assistant teacher, Floater, …) → [StaffDashboard]
/// - admin / director → [AdminDashboard]
/// - parent/guardian → placeholder until the parent dashboard is built
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/dashboard';

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();

    // Last-resort guard: kiosk users must never render dashboard content.
    // This catches notification deep-links, programmatic context.go('/dashboard'),
    // or any other route that bypasses the earlier kiosk checks.
    if (role.isKiosk) {
      SchedulerBinding.instance.addPostFrameCallback(
        (_) {
          if (context.mounted) context.go('/kiosk');
        },
      );
      return const SizedBox.shrink();
    }

    if (role.isParent) {
      return const ParentDashboard();
    }

    if (role.isStaff) {
      return const StaffDashboard();
    }

    return const AdminDashboard();
  }
}
