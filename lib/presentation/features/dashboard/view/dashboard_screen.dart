import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/dashboard/view/admin_dashboard.dart';
import 'package:wowcare/presentation/features/dashboard/view/parent_dashboard.dart';
import 'package:wowcare/presentation/features/dashboard/view/staff_dashboard.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Entry point for the `/dashboard` route.
///
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

    if (role.isParent) {
      return const ParentDashboard();
    }

    if (role.isStaff) {
      return const StaffDashboard();
    }

    return const AdminDashboard();
  }
}
