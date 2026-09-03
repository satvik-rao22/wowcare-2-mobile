import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_header_bar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/destructive_key.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/account_row.dart';

/// 3M2. Every account row, and Logout.
///
/// Logout means leaving the app, and is never called Sign Out: Sign Out is a
/// student's day ending. It sits alone at the foot in the destructive key,
/// with nothing else near it.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final session = context.watch<SessionCubit>().state;
    final user = session.user;
    void later() => showAppToast(context, AppStrings.comingSoon);

    return ScreenScaffold(
      header: const AppHeaderBar(
        title: DashboardStrings.account,
        leading: BackKey(),
      ),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.moreGroupGap,
        children: <Widget>[
          Row(
            spacing: DashboardSizes.accountRowGap,
            children: <Widget>[
              AppAvatar(
                initials: user?.initials ?? '',
                size: DashboardSizes.accountAvatar,
                tone: AvatarTone.impact,
                textStyle: DashboardTextStyles.childAvatarText,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user?.fullName ?? '',
                      style: DashboardTextStyles.accountName.copyWith(
                        color: c.ink,
                      ),
                    ),
                    Text(
                      DashboardStrings.designationAt(
                        user?.designation ?? '',
                        user?.schoolName ?? '',
                      ),
                      style: DashboardTextStyles.moreRole.copyWith(
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          _Group(
            eyebrow: DashboardStrings.profileGroup,
            rows: <Widget>[
              AccountRow(
                title: DashboardStrings.myProfile,
                subtitle: DashboardStrings.myProfileSub,
                onTap: later,
              ),
              AccountRow(
                title: DashboardStrings.notificationSettings,
                subtitle: DashboardStrings.groups(10),
                onTap: later,
              ),
              AccountRow(
                title: DashboardStrings.signInPin,
                trailing: Text(
                  _pin(session),
                  style: DashboardTextStyles.accountPin.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
          _Group(
            eyebrow: DashboardStrings.accessGroup,
            rows: <Widget>[
              if (user?.canSwitchPersona ?? false)
                AccountRow(
                  title: DashboardStrings.switchProfile,
                  trailing: StatusPill(
                    label: DashboardStrings.rolesHere(
                      user?.personas.length ?? 0,
                    ),
                    small: true,
                  ),
                  onTap: () => unawaited(_showSwitchProfile(context)),
                ),
              AccountRow(
                title: DashboardStrings.switchSchool,
                subtitle: user?.schoolName,
                onTap: later,
              ),
              AccountRow(
                title: DashboardStrings.switchOrganization,
                subtitle: user?.organizationName,
                onTap: later,
              ),
              AccountRow(
                title: DashboardStrings.changePassword,
                onTap: () => unawaited(context.push(AppRoutes.forgotPassword)),
              ),
            ],
          ),
          _Group(
            eyebrow: DashboardStrings.supportGroup,
            rows: <Widget>[
              AccountRow(
                title: DashboardStrings.help,
                subtitle: DashboardStrings.helpHost,
                onTap: later,
              ),
            ],
          ),
          DestructiveKey(
            label: AppStrings.logout,
            padding: DashboardSizes.logoutPad,
            onTap: () => unawaited(_showLogout(context)),
          ),
        ],
      ),
    );
  }

  /// The signed-in staff member's own PIN. Fixture-side it comes off the demo
  /// world; Phase 5 reads it from the account.
  static String _pin(SessionState session) =>
      session.user?.id == 'dana' ? '5106' : '4821';

  static Future<void> _showSwitchProfile(BuildContext context) {
    final session = context.read<SessionCubit>();
    final personas = session.state.user?.personas ?? const [];

    return showAppSheet<void>(
      context,
      builder: (sheetContext) => AppBottomSheet(
        title: DashboardStrings.switchProfile,
        subtitle: DashboardStrings.switchProfileBody(
          personas.length,
          session.state.user?.schoolName ?? '',
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: DashboardSizes.personaListGap,
          children: <Widget>[
            for (final persona in personas)
              SecondaryKey(
                label: switch (persona.name) {
                  'admin' => DashboardStrings.personaAdmin,
                  'staff' => DashboardStrings.personaStaff,
                  _ => DashboardStrings.personaParent,
                },
                padding: DashboardSizes.personaCardPad,
                onTap: () {
                  session.switchPersona(persona);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showLogout(BuildContext context) {
    final session = context.read<SessionCubit>();

    return showAppSheet<void>(
      context,
      builder: (sheetContext) => AppBottomSheet(
        title: DashboardStrings.logoutTitle,
        subtitle: DashboardStrings.logoutBody,
        footer: <Widget>[
          SecondaryKey(
            label: AppStrings.cancel,
            onTap: () => Navigator.of(sheetContext).pop(),
          ),
          DestructiveKey(
            label: AppStrings.logout,
            onTap: () {
              Navigator.of(sheetContext).pop();
              unawaited(session.logout());
            },
          ),
        ],
        body: const SizedBox.shrink(),
      ),
    );
  }
}

/// One titled group of account rows.
class _Group extends StatelessWidget {
  const _Group({required this.eyebrow, required this.rows});

  final String eyebrow;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSizes.sectionGap,
    children: <Widget>[
      SectionEyebrow(label: eyebrow),
      for (final row in rows) row,
    ],
  );
}
