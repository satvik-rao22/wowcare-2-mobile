import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/dashboard/view/admin_dashboard.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

/// Entry point for the `/dashboard` route.
///
/// Dispatches to the role-appropriate dashboard. Only the admin dashboard is
/// built so far; parent/staff/kiosk dashboards fall back to a placeholder.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const String routeName = '/dashboard';

  @override
  Widget build(BuildContext context) {
    final isParent = context.watch<RoleProvider>().isParent;

    // Admin / staff roles → the admin dashboard.
    if (!isParent) {
      return const AdminDashboard();
    }

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
}
