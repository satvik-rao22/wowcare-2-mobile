import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// 3P3. A guardian signing their own student out.
///
/// Everything here is a fact: the time is the clock's, and a guardian cannot
/// move it. What they can see is that the classroom will be told, and that
/// their own name goes on the record.
Future<void> showChildSignOutSheet(
  BuildContext context, {
  required DashboardCubit cubit,
  required ChildDay child,
}) {
  final guardianName =
      context.read<SessionCubit>().state.user?.fullName ?? '';

  return showAppSheet<void>(
    context,
    builder: (sheetContext) => AppBottomSheet(
      title: DashboardStrings.signOutPerson(child.firstName),
      subtitle: DashboardStrings.classroomToldLeaving(
        child.classroomName,
        child.firstName,
      ),
      footer: <Widget>[
        SecondaryKey(
          label: DashboardStrings.notYet,
          onTap: () => Navigator.of(sheetContext).pop(),
        ),
        PrimaryKey(
          label: DashboardStrings.confirmSignOut,
          padding: DashboardSizes.confirmKeyPad,
          onTap: () {
            Navigator.of(sheetContext).pop();
            unawaited(cubit.signOutChild());
          },
        ),
      ],
      body: _Body(child: child, guardianName: guardianName),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.child, required this.guardianName});

  final ChildDay child;
  final String guardianName;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.sheetSectionGap,
        children: <Widget>[
          AppCard(
            padding: DashboardSizes.personCardPad,
            child: Row(
              spacing: DashboardSizes.accountRowGap,
              children: <Widget>[
                AppAvatar(
                  initials: child.initials,
                  attendance: child.attendance,
                  textStyle: DashboardTextStyles.invoiceTitle,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        child.name,
                        style: DashboardTextStyles.sheetChildName.copyWith(
                          color: c.ink,
                        ),
                      ),
                      Text(
                        DashboardStrings.roomAndAge(
                          child.classroomName,
                          child.age,
                        ),
                        style: DashboardTextStyles.childMeta.copyWith(
                          color: c.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppCard(
            padding: DashboardSizes.timeCardPad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: DashboardSizes.statusBlockGap,
              children: <Widget>[
                _Fact(
                  label: DashboardStrings.signOutTime,
                  value: _now,
                  colours: c,
                ),
                _Fact(
                  label: AppStrings.signedIn,
                  value: child.inTimeLabel ?? '',
                  colours: c,
                ),
                _Fact(
                  label: DashboardStrings.by,
                  value: guardianName,
                  colours: c,
                ),
              ],
            ),
          ),
          SurfaceBox(
            surface: AppSurfaces.altWell(c),
            padding: const EdgeInsets.all(AppSizes.space3),
            child: Text(
              DashboardStrings.classroomToldLeft(
                child.classroomName,
                child.firstName,
              ),
              style: DashboardTextStyles.timeNote.copyWith(color: c.ink2),
            ),
          ),
        ],
      ),
    );
  }

  /// The demo world is frozen at the design's own clock.
  static String get _now {
    final at = DemoData.today;
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${at.hour < 12 ? 'AM' : 'PM'}';
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.colours,
  });

  final String label;
  final String value;
  final Colourway colours;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Text(
          label,
          style: DashboardTextStyles.factLabel.copyWith(color: colours.ink2),
        ),
      ),
      Text(
        value,
        style: DashboardTextStyles.factValue.copyWith(color: colours.ink),
      ),
    ],
  );
}
