import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../core/utils/av2_date_formatter.dart';
import '../../domain/entities/attendance_day.dart';
import 'av2_pill.dart';

/// Absent day, shown inline in the timeline with a red left accent.
class Av2AbsentDayCard extends StatelessWidget {
  const Av2AbsentDayCard({super.key, required this.day, this.onAction});

  final AttendanceDay day;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppSurfaces.card(radius: Av2Spacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              width: 3,
              child: ColoredBox(color: Av2Colors.danger),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _dateBlock(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Av2Pill(
                            text: 'Absent',
                            fill: Av2Colors.dangerFill,
                            textColor: Av2Colors.danger,
                          ),
                          if (day.absenceMarkedByName?.trim().isNotEmpty ??
                              false)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'marked by ${day.absenceMarkedByName!.trim()}',
                                style: Av2Text.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (onAction != null) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onAction,
                        borderRadius: BorderRadius.circular(
                          Av2Spacing.radiusSm,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: Av2Colors.textTertiary,
                          ),
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

  Widget _dateBlock() {
    return Column(
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
          Av2DateFormatter.weekday(day.date),
          style: Av2Text.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
