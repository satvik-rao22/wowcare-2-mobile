import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_router.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/badge_cubit.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_tab_bar.dart';

/// The five-slot shell.
///
/// Admin and Staff: Dashboard, Attendance, Classrooms, Activities, Messages.
/// Guardian: Dashboard, Attendance, Activities, Messages, Billing. More sits
/// behind the hamburger key in the dashboard header, not in the bar.
///
/// Slot state follows the app's own `_syncSelectedItemFromRoute` rule: a
/// drill-down under the Dashboard branch (Students, Staff, Reports, Profile…)
/// highlights nothing rather than falsely lighting Dashboard; a Classrooms or
/// Activities screen lights its own slot.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<ShellBranch> _schoolSlots = <ShellBranch>[
    ShellBranch.dashboard,
    ShellBranch.attendance,
    ShellBranch.classrooms,
    ShellBranch.activities,
    ShellBranch.messages,
  ];

  static const List<ShellBranch> _guardianSlots = <ShellBranch>[
    ShellBranch.dashboard,
    ShellBranch.attendance,
    ShellBranch.activities,
    ShellBranch.messages,
    ShellBranch.billing,
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final current = ShellBranch.values[navigationShell.currentIndex];
    final onDashboardDrillDown =
        current == ShellBranch.dashboard && location != AppRoutes.dashboard;

    return Scaffold(
      backgroundColor: context.colours.page,
      body: navigationShell,
      bottomNavigationBar: BlocSelector<SessionCubit, SessionState, Persona>(
        selector: (s) => s.persona,
        builder: (context, persona) {
          final slots = persona.isSchoolSide ? _schoolSlots : _guardianSlots;
          final index = slots.indexOf(current);
          final selected = onDashboardDrillDown || index < 0 ? null : index;

          return BlocBuilder<BadgeCubit, BadgeState>(
            builder: (context, badges) => AppTabBar(
              selectedIndex: selected,
              onSelect: (int i) => _goToSlot(slots[i]),
              items: <AppTabItem>[
                for (final slot in slots) _item(slot, badges),
              ],
            ),
          );
        },
      ),
    );
  }

  void _goToSlot(ShellBranch branch) {
    navigationShell.goBranch(
      branch.index,
      // Tapping the lit slot returns to its root, as the app does.
      initialLocation: branch.index == navigationShell.currentIndex,
    );
  }

  AppTabItem _item(ShellBranch branch, BadgeState badges) => switch (branch) {
    ShellBranch.dashboard => const AppTabItem(
      icon: AppIcons.dashboard,
      label: AppStrings.dashboard,
    ),
    ShellBranch.attendance => const AppTabItem(
      icon: AppIcons.attendance,
      label: AppStrings.attendance,
    ),
    ShellBranch.classrooms => const AppTabItem(
      icon: AppIcons.classrooms,
      label: AppStrings.classrooms,
    ),
    ShellBranch.activities => const AppTabItem(
      icon: AppIcons.activities,
      label: AppStrings.activities,
    ),
    ShellBranch.messages => AppTabItem(
      icon: AppIcons.messages,
      label: AppStrings.messages,
      badgeCount: badges.messages,
    ),
    ShellBranch.billing => const AppTabItem(
      icon: AppIcons.billing,
      label: AppStrings.billing,
    ),
  };
}
