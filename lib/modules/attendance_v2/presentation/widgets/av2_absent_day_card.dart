import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../core/utils/av2_date_formatter.dart';
import '../../domain/entities/attendance_day.dart';
import 'av2_pill.dart';

/// Absent day, shown inline in the same timeline with a red left accent.
class Av2AbsentDayCard extends StatelessWidget {
  const Av2AbsentDayCard({super.key, required this.day, this.onAction});

  final AttendanceDay day;
  final ValueChanged<DateTime>? onAction;

  @override
  Widget build(BuildContext context) {
    final markedBy = day.absenceMarkedBy?.trim();
    final subtitle = (markedBy == null || markedBy.isEmpty)
        ? 'Absent'
        : 'Absent · marked by $markedBy';

    return Container(
      decoration: BoxDecoration(
        color: Av2Colors.surface,
        border: Border.all(color: Av2Colors.border),
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(width: 3, child: ColoredBox(color: Av2Colors.danger)),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Av2DateFormatter.monthDay(day.date),
                            style: Av2Text.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            subtitle,
                            style: Av2Text.caption
                                .copyWith(color: Av2Colors.danger),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Av2Pill(
                      text: 'Absent',
                      fill: Av2Colors.dangerFill,
                      textColor: Av2Colors.danger,
                    ),
                    if (onAction != null) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => onAction!(day.date),
                        borderRadius:
                            BorderRadius.circular(Av2Spacing.radiusSm),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.more_vert,
                              size: 16, color: Av2Colors.textTertiary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
