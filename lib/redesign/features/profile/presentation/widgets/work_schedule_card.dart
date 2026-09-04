import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// The staff member's week: which days they work, the shift, and the break.
///
/// The header is where the refusal lives. An Admin gets the Edit key; a Staff
/// member gets the locked "Admin only" chip in its place, because a card that
/// says who may change it is more use than a card that is simply not there.
class WorkScheduleCard extends StatelessWidget {
  const WorkScheduleCard({
    required this.schedule,
    required this.canEdit,
    this.onEdit,
    super.key,
  });

  final WorkSchedule schedule;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final shift = schedule.primaryShift;
    final rest = schedule.primaryBreak;

    return AppCard(
      padding: ProfileSizes.detailCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ProfileSizes.scheduleGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  ProfileStrings.workSchedule,
                  style: ProfileTextStyles.cardHeading.copyWith(color: c.ink),
                ),
              ),
              if (canEdit) _EditKey(onTap: onEdit) else const _LockChip(),
            ],
          ),
          Row(
            spacing: ProfileSizes.dayChipGap,
            children: <Widget>[
              for (final day in schedule.displayDays)
                Expanded(
                  child: _DayChip(
                    label: ProfileStrings.dayShort[day.index],
                    isWorking: schedule.workingDays.contains(day),
                  ),
                ),
            ],
          ),
          AppWell(
            padding: ProfileSizes.hoursWellPad,
            child: Row(
              spacing: ProfileSizes.hoursGap,
              children: <Widget>[
                Expanded(
                  child: Text(
                    shift == null
                        ? ProfileStrings.noSchedule
                        : ProfileStrings.timeRange(shift.start, shift.end),
                    style: ProfileTextStyles.hoursValue.copyWith(
                      color: shift == null ? c.ink3 : c.ink,
                    ),
                  ),
                ),
                if (rest != null)
                  Text(
                    ProfileStrings.breakRange(
                      ProfileStrings.timeRange(rest.start, rest.end),
                    ),
                    style: ProfileTextStyles.breakValue.copyWith(
                      color: c.staffFg,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One weekday. Sun means staff, which is what a shift is.
class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.isWorking});

  final String label;
  final bool isWorking;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return SurfaceBox(
      surface: AppSurfaces.pill(fill: isWorking ? c.staffBg : c.well),
      padding: ProfileSizes.dayChipPad,
      alignment: Alignment.center,
      child: Text(
        label,
        style: ProfileTextStyles.dayChip.copyWith(
          color: isWorking ? c.staffFg : c.ink3,
        ),
      ),
    );
  }
}

/// The small pill key on the card's header. Not the screen's one action, so
/// it is a key's face rather than pink.
class _EditKey extends StatelessWidget {
  const _EditKey({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: AppStrings.edit,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: _pillKey(c),
          padding: ProfileSizes.pillKeyPad,
          child: Text(
            AppStrings.edit,
            style: ProfileTextStyles.pillKey.copyWith(color: c.ink),
          ),
        ),
      ),
    );
  }

  /// A secondary key's face at a pill's radius, which is what the frame draws
  /// on a card header.
  static Surface _pillKey(Colourway c) {
    final key = AppSurfaces.keySecondary(c);
    return AppSurfaces.pill(
      fill: c.key,
      line: c.keyBorder,
    ).copyWith(insets: key.insets);
  }
}

/// What a Staff member gets where the Edit key would be.
class _LockChip extends StatelessWidget {
  const _LockChip();

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return SurfaceBox(
      surface: AppSurfaces.pill(fill: c.neutralBg),
      padding: ProfileSizes.lockChipPad,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: ProfileSizes.lockChipGap,
        children: <Widget>[
          Icon(AppIcons.lock, size: ProfileSizes.lockGlyph, color: c.ink2),
          Text(
            ProfileStrings.adminOnly,
            style: ProfileTextStyles.roleChip.copyWith(color: c.ink2),
          ),
        ],
      ),
    );
  }
}
