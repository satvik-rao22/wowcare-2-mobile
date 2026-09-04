import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

/// One person over a range of days (4f).
///
/// Closed it is a name and a classroom. Open it is the two figures the range
/// call already returns, Attended Time and Attended Days, and the key that
/// opens the record behind them.
class RangeRow extends StatelessWidget {
  const RangeRow({
    required this.entry,
    required this.isExpanded,
    required this.onTap,
    required this.onView,
    super.key,
  });

  final RangeEntry entry;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: EdgeInsets.zero,
      clipContent: true,
      lineColor: isExpanded
          ? (entry.audience.isStudents ? c.studentLine : c.staffLine)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Pressable.surface(
            onTap: onTap,
            child: Padding(
              padding: AttendanceSizes.rangeRowPad,
              child: Row(
                spacing: AttendanceSizes.rangeRowGap,
                children: <Widget>[
                  _avatar(c),
                  Expanded(
                    child: Text(
                      entry.fullName,
                      style: AttendanceTextStyles.rangeName.copyWith(
                        color: c.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    entry.classroomName,
                    style: AttendanceTextStyles.rangeScope.copyWith(
                      color: c.ink2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AnimatedRotation(
                    duration: AppMotion.fast,
                    curve: AppMotion.ease,
                    turns: isExpanded ? .5 : 0,
                    child: Icon(
                      AppIcons.chevronDown,
                      size: AttendanceSizes.rangeChevron,
                      color: c.ink3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) _totals(c),
        ],
      ),
    );
  }

  Widget _avatar(Colourway c) => SurfaceBox(
    surface: AppSurfaces.avatar(
      c,
      fill: entry.audience.isStudents ? c.studentBg : c.staffBg,
      size: AttendanceSizes.rangeAvatar,
    ),
    width: AttendanceSizes.rangeAvatar,
    height: AttendanceSizes.rangeAvatar,
    alignment: Alignment.center,
    child: Text(
      entry.initials,
      style: AttendanceTextStyles.smallInitials.copyWith(
        color: entry.audience.isStudents ? c.student : c.staffFg,
      ),
    ),
  );

  Widget _totals(Colourway c) => Padding(
    padding: AttendanceSizes.rangeOpenPad,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AttendanceSizes.rangeOpenGap,
      children: <Widget>[
        Container(height: AppSizes.hairline, color: c.divider),
        _line(
          c,
          AttendanceStrings.attendedTime,
          AttendanceFormats.longSpan(
            entry.attendedHours,
            entry.attendedMinutes,
          ),
        ),
        _line(c, AttendanceStrings.attendedDays, '${entry.attendedDays}'),
        SecondaryKey(label: AttendanceStrings.viewKey, onTap: onView),
      ],
    ),
  );

  /// The label is measured first and the total takes what is left, so a long
  /// figure shortens rather than running past the card.
  Widget _line(Colourway c, String label, String value) => Row(
    spacing: AppSizes.rowGap,
    children: <Widget>[
      Flexible(
        child: Text(
          label,
          style: AttendanceTextStyles.totalLabel.copyWith(color: c.ink2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: AttendanceTextStyles.totalValue.copyWith(color: c.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
