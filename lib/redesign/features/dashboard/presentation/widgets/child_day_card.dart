import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_toggle.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/day_key.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/dot_pill.dart';

/// One student's day, as their guardian sees it (3P1).
///
/// A guardian gets exactly two actions: scan the kiosk code, and sign their
/// own student out. Everything else on this card is a fact, because a
/// guardian cannot change a record the school keeps.
class ChildDayCard extends StatelessWidget {
  const ChildDayCard({
    required this.child,
    required this.onScanQr,
    required this.onSignOut,
    required this.onReminderChanged,
    super.key,
  });

  final ChildDay child;
  final VoidCallback onScanQr;
  final VoidCallback onSignOut;
  final ValueChanged<bool> onReminderChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.cardContentGap,
        children: <Widget>[
          Row(
            spacing: DashboardSizes.childHeaderGap,
            children: <Widget>[
              AppAvatar(
                initials: child.initials,
                size: DashboardSizes.childAvatar,
                attendance: child.attendance,
                textStyle: DashboardTextStyles.childAvatarText,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      child.name,
                      style: DashboardTextStyles.childName.copyWith(
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
              DotPill(
                label: _statusWord,
                fill: _statusFill(c),
                ink: _statusInk(c),
                dot: child.attendance.colour(c),
              ),
            ],
          ),
          Row(
            spacing: DashboardSizes.dayTileGap,
            children: <Widget>[
              Expanded(
                child: _Fact(
                  label: child.isSignedIn
                      ? AppStrings.signedIn
                      : AppStrings.notMarked,
                  value: child.inTimeLabel ?? '',
                  valueColor: child.isSignedIn ? c.successFg : c.ink3,
                ),
              ),
              Expanded(
                child: _Fact(
                  label: DashboardStrings.dayEnds,
                  value: child.dayEndsLabel,
                  valueColor: c.ink,
                ),
              ),
            ],
          ),
          _reminder(c),
          Row(
            spacing: DashboardSizes.dayKeyGap,
            children: <Widget>[
              Expanded(
                child: DayKey(
                  label: AppStrings.scanQr,
                  icon: AppIcons.scanQr,
                  onTap: onScanQr,
                ),
              ),
              Expanded(
                child: DayKey(
                  label: AppStrings.signOut,
                  isPrimary: true,
                  onTap: child.isSignedIn ? onSignOut : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reminder(Colourway c) => SurfaceBox(
    surface: AppSurfaces.altWell(c),
    padding: DashboardSizes.reminderRowPad,
    child: Row(
      spacing: DashboardSizes.messageRowGap,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                DashboardStrings.reminder,
                style: DashboardTextStyles.reminderTitle.copyWith(
                  color: c.ink,
                ),
              ),
              Text(
                DashboardStrings.reminderSub,
                style: DashboardTextStyles.reminderSub.copyWith(
                  color: c.ink3,
                ),
              ),
            ],
          ),
        ),
        AppToggle(value: child.isReminderOn, onChanged: onReminderChanged),
      ],
    ),
  );

  String get _statusWord => switch (child.attendance) {
    AttendanceStatus.signedIn => AppStrings.signedIn,
    AttendanceStatus.signedOut => AppStrings.signedOut,
    AttendanceStatus.absent => AppStrings.absent,
    AttendanceStatus.notMarked => AppStrings.notMarked,
  };

  Color _statusFill(Colourway c) => switch (child.attendance) {
    AttendanceStatus.signedIn => c.successBg,
    AttendanceStatus.absent => c.dangerBg,
    _ => c.altWell,
  };

  Color _statusInk(Colourway c) => switch (child.attendance) {
    AttendanceStatus.signedIn => c.successFg,
    AttendanceStatus.absent => c.dangerFg,
    _ => c.ink2,
  };
}

/// A labelled fact in a well: when the day started, when it ends.
class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.well(c),
      padding: DashboardSizes.dayTilePad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: DashboardSizes.dayTileTextGap,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: DashboardTextStyles.dayTileLabel.copyWith(color: c.ink3),
          ),
          Text(
            value,
            style: DashboardTextStyles.dayTileTime.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
