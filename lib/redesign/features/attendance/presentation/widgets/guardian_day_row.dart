import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

/// One past day on a guardian's list (4a, parent lens): the date, what
/// happened, and how long it came to.
class GuardianDayRow extends StatelessWidget {
  const GuardianDayRow({required this.day, super.key});

  final GuardianDay day;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: AttendanceSizes.guardianDayPad,
      child: Row(
        spacing: AppSizes.rowGap,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  day.dateLabel,
                  style: AttendanceTextStyles.dayName.copyWith(color: c.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  day.detail,
                  style: AttendanceTextStyles.daySub.copyWith(color: c.ink3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          StatusPill(
            label: day.trailing,
            tone: switch (day.status) {
              AttendanceStatus.signedIn => PillTone.success,
              AttendanceStatus.absent => PillTone.danger,
              _ => PillTone.neutral,
            },
            foreground: day.status == AttendanceStatus.signedOut ? c.ink : null,
            small: true,
          ),
        ],
      ),
    );
  }
}
