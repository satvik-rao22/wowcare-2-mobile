import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../core/utils/av2_date_formatter.dart';
import '../../domain/entities/attendance_day.dart';
import 'av2_pill.dart';

/// Absent day, shown inline in the timeline with a red left accent.
class Av2AbsentDayCard extends StatelessWidget {
  const Av2AbsentDayCard({super.key, required this.day});

  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        Av2DateFormatter.monthDay(day.date),
                        style: Av2Text.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Av2Pill(
                      text: 'Absent',
                      fill: Av2Colors.dangerFill,
                      textColor: Av2Colors.danger,
                    ),
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
