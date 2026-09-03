import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_toast.dart';
import 'package:wowcare/redesign/core/widgets/back_key.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/screen_scaffold.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/more_tile.dart';

/// 3M. Everything the five nav slots could not carry, in three groups.
///
/// One page for Admin and Staff. A Staff member simply sees fewer tiles;
/// nothing is greyed out, because a tile that cannot be opened is not a tile.
/// A Guardian never gets here: the hamburger takes them to their account.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final user = session.user;

    return ScreenScaffold(
      header: _ProfileRow(
        name: user?.fullName ?? '',
        initials: user?.initials ?? '',
        role: DashboardStrings.designationAt(
          user?.designation ?? '',
          session.isStaff && user?.classroomName != null
              ? user!.classroomName!
              : user?.schoolName ?? '',
        ),
        onTap: () => unawaited(context.push(AppRoutes.account)),
      ),
      bodyPadding: DashboardSizes.moreBodyPad,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.moreGroupGap,
        children: <Widget>[
          for (final group in _groups(context, session.persona))
            _Group(group: group),
        ],
      ),
    );
  }

  /// The three groups, and which tiles each persona sees inside them. An
  /// Admin sees everything; a Staff member sees what they can act on.
  static List<_TileGroup> _groups(BuildContext context, Persona persona) {
    final c = context.colours;
    final isAdmin = persona == Persona.admin;
    void later() => showAppToast(context, AppStrings.comingSoon);

    return <_TileGroup>[
      _TileGroup(
        eyebrow: DashboardStrings.studentsGroup,
        color: c.student,
        tiles: <Widget>[
          MoreTile(
            label: AppStrings.students,
            icon: AppIcons.students,
            tint: c.studentBg,
            glyphColor: c.student,
            badge: isAdmin ? '2' : '1',
            onTap: later,
          ),
          MoreTile(
            label: AppStrings.classrooms,
            icon: AppIcons.classrooms,
            tint: c.studentBg,
            glyphColor: c.student,
            onTap: later,
          ),
          MoreTile(
            label: AppStrings.activities,
            icon: AppIcons.activities,
            tint: c.studentBg,
            glyphColor: c.student,
            badge: isAdmin ? '2' : null,
            onTap: later,
          ),
          if (isAdmin)
            MoreTile(
              label: DashboardStrings.availability,
              icon: AppIcons.calendar,
              tint: c.studentBg,
              glyphColor: c.student,
              onTap: later,
            ),
        ],
      ),
      _TileGroup(
        eyebrow: DashboardStrings.staffGroup,
        color: c.staffFg,
        tiles: <Widget>[
          if (isAdmin)
            MoreTile(
              label: AppStrings.staff,
              icon: AppIcons.staff,
              tint: c.staffBg,
              glyphColor: c.staffFg,
              onTap: later,
            ),
          MoreTile(
            label: DashboardStrings.scheduling,
            icon: AppIcons.scheduling,
            tint: c.staffBg,
            glyphColor: c.staffFg,
            badge: isAdmin ? '1' : null,
            badgeFill: c.staffBg,
            badgeInk: c.staffFg,
            onTap: later,
          ),
        ],
      ),
      _TileGroup(
        eyebrow: DashboardStrings.centerGroup,
        color: c.ink2,
        tiles: <Widget>[
          MoreTile(
            label: DashboardStrings.events,
            icon: AppIcons.events,
            tint: c.altWell,
            glyphColor: c.ink,
            onTap: later,
          ),
          MoreTile(
            label: DashboardStrings.tasks,
            icon: AppIcons.tasks,
            tint: c.taskBg,
            glyphColor: c.task,
            onTap: later,
          ),
          if (isAdmin)
            MoreTile(
              label: AppStrings.billing,
              icon: AppIcons.billing,
              tint: c.altWell,
              glyphColor: c.ink,
              onTap: later,
            ),
          MoreTile(
            label: DashboardStrings.newsletter,
            icon: AppIcons.newsletter,
            tint: c.altWell,
            glyphColor: c.ink,
            onTap: later,
          ),
          if (isAdmin) ...<Widget>[
            MoreTile(
              label: DashboardStrings.reportsTile,
              icon: AppIcons.reports,
              tint: c.altWell,
              glyphColor: c.ink,
              onTap: later,
            ),
            MoreTile(
              label: DashboardStrings.settings,
              icon: AppIcons.settings,
              tint: c.altWell,
              glyphColor: c.ink,
              onTap: later,
            ),
          ],
          MoreTile(
            label: DashboardStrings.kioskMode,
            icon: AppIcons.scanQr,
            tint: c.altWell,
            glyphColor: c.ink,
            onTap: () {
              context.read<SessionCubit>().enterKiosk();
              context.go(AppRoutes.kiosk);
            },
          ),
        ],
      ),
    ];
  }
}

/// One group of tiles, under its eyebrow.
class _TileGroup {
  const _TileGroup({
    required this.eyebrow,
    required this.color,
    required this.tiles,
  });

  final String eyebrow;
  final Color color;
  final List<Widget> tiles;
}

class _Group extends StatelessWidget {
  const _Group({required this.group});

  final _TileGroup group;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSizes.sectionGap,
    children: <Widget>[
      SectionEyebrow(label: group.eyebrow, color: group.color),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: group.tiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: DashboardSizes.moreColumns,
          crossAxisSpacing: DashboardSizes.moreTileGap,
          mainAxisSpacing: DashboardSizes.moreTileGap,
          // A fixed height rather than an aspect ratio: the tile's content is
          // a known stack, and a ratio that fits one screen width overflows
          // the next.
          mainAxisExtent: DashboardSizes.moreTileExtent,
        ),
        itemBuilder: (context, index) => group.tiles[index],
      ),
    ],
  );
}

/// The account card at the top of More, which opens 3M2.
class _ProfileRow extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileRow({
    required this.name,
    required this.initials,
    required this.role,
    required this.onTap,
  });

  final String name;
  final String initials;
  final String role;
  final VoidCallback onTap;

  @override
  Size get preferredSize => const Size.fromHeight(
    DashboardSizes.moreAvatar + 26,
  );

  @override
  Widget build(BuildContext context) {
    final Colourway c = context.colours;

    return Padding(
      padding: DashboardSizes.moreHeaderPad,
      child: Row(
        spacing: DashboardSizes.moreHeaderGap,
        children: <Widget>[
          const BackKey(),
          Expanded(
            child: Semantics(
              button: true,
              label: DashboardStrings.account,
              child: Pressable.surface(
                onTap: onTap,
                child: Row(
                  spacing: DashboardSizes.moreHeaderGap,
                  children: <Widget>[
                    AppAvatar(
                      initials: initials,
                      tone: AvatarTone.impact,
                      textStyle: DashboardTextStyles.childChipText,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            name,
                            style: DashboardTextStyles.moreName.copyWith(
                              color: c.ink,
                            ),
                          ),
                          Text(
                            role,
                            style: DashboardTextStyles.moreRole.copyWith(
                              color: c.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      AppIcons.chevronRight,
                      size: DashboardSizes.moreChevron,
                      color: c.ink3,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
