import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';

/// Shown by `DashboardScreen` while `RoleCubit` has not yet emitted a persona.
///
/// Before this existed the screen dispatched on `RoleState.role`, which
/// defaults to `admin`, so an unresolved user briefly got the full admin
/// dashboard and its admin-only requests. This is the neutral state that
/// window renders instead.
///
/// Deliberately chrome-free — no scaffold, no nav bar. The persona decides
/// which navigation bar is correct (parent's differs from staff/admin), so
/// rendering one here would guarantee a flicker as it swaps. The window is
/// normally zero-length: the splash resolves the persona before this route is
/// reached, and `RoleCubit` resolves from storage before its server round-trip.
class DashboardPersonaLoading extends StatelessWidget {
  const DashboardPersonaLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.cardColor,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }
}
