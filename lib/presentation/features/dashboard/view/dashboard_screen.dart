import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/dashboard/view/admin_dashboard.dart';
import 'package:wowcare/presentation/features/dashboard/view/staff_dashboard.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

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
    final role = context.watch<RoleProvider>();

    if (role.isParent) {
      // TODO: replace with ParentDashboard once it is built.
      return const GlobalScaffold(
        showCustomNavigationBar: true,
        body: Center(
          child: Text(
            'Dashboard module goes here',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (role.isStaff) {
      return const StaffDashboard();
    }

    return const AdminDashboard();
  }
}
