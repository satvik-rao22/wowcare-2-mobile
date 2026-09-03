import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/radio_card.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';

/// 3A3 and 3S3: the sheet that closes a staff member's own day.
///
/// The one difference between the two frames is who may correct the time. An
/// Admin can nudge it five minutes either way and the adjustment is logged
/// against their name; a Staff member sees the clock and a line saying who
/// can change it. Same sheet, one flag.
Future<void> showStaffSignOutSheet(
  BuildContext context, {
  required DashboardCubit cubit,
  bool canAdjustTime = false,
}) {
  final session = context.read<SessionCubit>();

  return showAppSheet<void>(
    context,
    builder: (sheetContext) => MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<DashboardCubit>.value(value: cubit),
        BlocProvider<SessionCubit>.value(value: session),
      ],
      child: _StaffSignOutSheet(canAdjustTime: canAdjustTime),
    ),
  );
}

class _StaffSignOutSheet extends StatefulWidget {
  const _StaffSignOutSheet({required this.canAdjustTime});

  final bool canAdjustTime;

  @override
  State<_StaffSignOutSheet> createState() => _StaffSignOutSheetState();
}

class _StaffSignOutSheetState extends State<_StaffSignOutSheet> {
  /// Minutes away from the clock. Only an Admin can move it.
  int _offset = 0;

  DateTime get _at =>
      DemoData.today.add(Duration(minutes: _offset));

  void _nudge(int steps) => setState(
    () => _offset += steps * DashboardSizes.adjustStepMinutes,
  );

  Future<void> _confirm() async {
    final cubit = context.read<DashboardCubit>();
    Navigator.of(context).pop();
    await cubit.signOutSelf(at: widget.canAdjustTime ? _at : null);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final user = context.read<SessionCubit>().state.user;
    final day = context.read<DashboardCubit>().state.snapshot.myDay;
    if (day == null || user == null) return const SizedBox.shrink();

    return AppBottomSheet(
      title: widget.canAdjustTime
          ? DashboardStrings.signOutPerson(user.fullName)
          : DashboardStrings.signOutForDay,
      subtitle: widget.canAdjustTime
          ? DashboardStrings.signedInAtOnClock(
              day.sinceLabel ?? '',
              day.onClockLabel ?? '',
            )
          : DashboardStrings.signOutForDayBody,
      footer: <Widget>[
        SecondaryKey(
          label: widget.canAdjustTime
              ? AppStrings.cancel
              : DashboardStrings.staySignedIn,
          onTap: () => Navigator.of(context).pop(),
        ),
        PrimaryKey(
          label: widget.canAdjustTime
              ? DashboardStrings.confirmSignOut
              : DashboardStrings.yesSignMeOut,
          padding: DashboardSizes.confirmKeyPad,
          onTap: () => unawaited(_confirm()),
        ),
      ],
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: DashboardSizes.sheetSectionGap,
          children: <Widget>[
            _timeCard(c),
            _person(c, name: user.fullName, initials: user.initials,
                subtitle: DashboardStrings.designationAt(
                  user.designation,
                  user.schoolName,
                )),
            if (!widget.canAdjustTime) ...<Widget>[
              _facts(c, day.sinceLabel ?? '', day.onClockLabel ?? '',
                  day.classroomName),
              _warning(c, day.classroomName),
            ],
          ],
        ),
      ),
    );
  }

  Widget _timeCard(Colourway c) => AppCard(
    padding: DashboardSizes.timeCardPad,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: DashboardSizes.timeCardGap,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                DashboardStrings.signOutTime.toUpperCase(),
                style: DashboardTextStyles.timeEyebrow.copyWith(color: c.ink3),
              ),
            ),
            if (widget.canAdjustTime && _offset != 0)
              const StatusPill(
                label: DashboardStrings.edited,
                tone: PillTone.staff,
                small: true,
              )
            else if (!widget.canAdjustTime)
              const StatusPill(label: DashboardStrings.now, small: true),
          ],
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _clock(_at),
                style: DashboardTextStyles.timeValue.copyWith(color: c.ink),
              ),
            ),
            if (widget.canAdjustTime)
              Row(
                spacing: DashboardSizes.adjustKeyGap,
                children: <Widget>[
                  _AdjustKey(
                    icon: AppIcons.chevronDown,
                    semanticLabel: DashboardStrings.adjustEarlier,
                    onTap: () => _nudge(-1),
                  ),
                  _AdjustKey(
                    icon: AppIcons.chevronUp,
                    semanticLabel: DashboardStrings.adjustLater,
                    onTap: () => _nudge(1),
                  ),
                ],
              ),
          ],
        ),
        Text(
          widget.canAdjustTime
              ? DashboardStrings.auditNote
              : DashboardStrings.onlyAdminAdjusts,
          style: DashboardTextStyles.timeNote.copyWith(color: c.ink3),
        ),
      ],
    ),
  );

  Widget _person(
    Colourway c, {
    required String name,
    required String initials,
    required String subtitle,
  }) => AppCard(
    padding: DashboardSizes.personCardPad,
    child: Row(
      spacing: DashboardSizes.accountRowGap,
      children: <Widget>[
        AppAvatar(
          initials: initials,
          size: DashboardSizes.personAvatar,
          tone: AvatarTone.impact,
          textStyle: DashboardTextStyles.reminderTitle,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name,
                style: DashboardTextStyles.personName.copyWith(color: c.ink),
              ),
              Text(
                subtitle,
                style: DashboardTextStyles.childMeta.copyWith(color: c.ink3),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _facts(
    Colourway c,
    String since,
    String onClock,
    String? classroom,
  ) => AppCard(
    padding: DashboardSizes.timeCardPad,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: DashboardSizes.statusBlockGap,
      children: <Widget>[
        _Fact(label: AppStrings.signedIn, value: since),
        _Fact(label: DashboardStrings.totalToday, value: onClock),
        if (classroom != null)
          _Fact(label: DashboardStrings.classroom, value: classroom),
      ],
    ),
  );

  Widget _warning(Colourway c, String? classroom) => Container(
    padding: DashboardSizes.warningPad,
    decoration: BoxDecoration(
      color: c.staffBg,
      borderRadius: AppRadii.cardR,
      border: Border.all(color: c.staffLine),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: DashboardSizes.warningGap,
      children: <Widget>[
        Icon(
          AppIcons.alertTriangle,
          size: DashboardSizes.warningGlyph,
          color: c.staffFg,
        ),
        Expanded(
          child: Text(
            DashboardStrings.dropsToOneStaff(classroom ?? ''),
            style: DashboardTextStyles.warningText.copyWith(color: c.staffFg),
          ),
        ),
      ],
    ),
  );

  static String _clock(DateTime at) {
    final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${at.hour < 12 ? 'AM' : 'PM'}';
  }
}

/// A labelled fact on a confirmation sheet.
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: DashboardTextStyles.factLabel.copyWith(color: c.ink2),
          ),
        ),
        Text(
          value,
          style: DashboardTextStyles.factValue.copyWith(color: c.ink),
        ),
      ],
    );
  }
}

/// The minus and plus keys an Admin nudges a recorded time with.
class _AdjustKey extends StatelessWidget {
  const _AdjustKey({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.keySecondary(c),
          width: DashboardSizes.adjustKey,
          height: DashboardSizes.adjustKey,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: DashboardSizes.adjustGlyph,
            color: c.ink,
          ),
        ),
      ),
    );
  }
}

/// The classroom a staff member is moving to for the rest of the shift.
Future<void> showTransferSheet(
  BuildContext context, {
  required DashboardCubit cubit,
}) => showAppSheet<void>(
  context,
  builder: (sheetContext) => AppBottomSheet(
    title: DashboardStrings.transferTitle,
    subtitle: DashboardStrings.transferSubtitle,
    body: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.sheetGap,
        children: <Widget>[
          for (final name in DemoData.classroomNames)
            RadioCard(
              title: name,
              selected:
                  cubit.state.snapshot.myDay?.classroomName == name,
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(cubit.transfer(name));
              },
            ),
        ],
      ),
    ),
  ),
);

/// Mark yourself absent for today, or undo it.
Future<void> showMarkAbsentSheet(
  BuildContext context, {
  required DashboardCubit cubit,
}) {
  final isAbsent = cubit.state.snapshot.myDay?.isAbsent ?? false;

  return showAppSheet<void>(
    context,
    builder: (sheetContext) => AppBottomSheet(
      title: isAbsent
          ? DashboardStrings.undoAbsent
          : DashboardStrings.markAbsentTitle,
      subtitle: DashboardStrings.markAbsentBody,
      footer: <Widget>[
        SecondaryKey(
          label: AppStrings.cancel,
          onTap: () => Navigator.of(sheetContext).pop(),
        ),
        PrimaryKey(
          label: isAbsent
              ? DashboardStrings.undoAbsent
              : DashboardStrings.markAbsent,
          onTap: () {
            Navigator.of(sheetContext).pop();
            unawaited(cubit.setAbsent(isAbsent: !isAbsent));
          },
        ),
      ],
      body: const SizedBox.shrink(),
    ),
  );
}
