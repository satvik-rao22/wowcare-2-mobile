import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../core/utils/av2_date_formatter.dart';
import '../../core/utils/av2_duration_formatter.dart';
import '../../domain/entities/attendance_day.dart';
import 'av2_break_row.dart';
import 'av2_pill.dart';
import 'av2_session_tile.dart';

/// Mobile day card. Collapsed = the per-day summary (date, mini bar, OT chip,
/// total). Expanded = the day's sessions. Manages its own expansion state.
class Av2AttendedDayCard extends StatefulWidget {
  const Av2AttendedDayCard({
    super.key,
    required this.day,
    this.initiallyExpanded = false,
    this.onSessionAction,
  });

  final AttendanceDay day;
  final bool initiallyExpanded;
  final ValueChanged<String>? onSessionAction;

  @override
  State<Av2AttendedDayCard> createState() => _Av2AttendedDayCardState();
}

class _Av2AttendedDayCardState extends State<Av2AttendedDayCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    return Container(
      decoration: BoxDecoration(
        color: _expanded ? Av2Colors.surface : Av2Colors.surface,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
        border: Border.all(color: Av2Colors.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _header(day),
          if (_expanded) _sessions(day),
        ],
      ),
    );
  }

  Widget _header(AttendanceDay day) {
    return Material(
      color: _expanded ? Av2Colors.surfaceMuted : Av2Colors.surface,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(child: _dateBlock(day)),
              const SizedBox(width: 8),
              if (day.hasOvertime) ...[
                Av2Pill(
                  text: Av2DurationFormatter.overtimeChip(day.overtimeMinutes),
                  fill: Av2Colors.overtimeFill,
                  textColor: Av2Colors.overtime,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                Av2DurationFormatter.hm(day.totalMinutes),
                style: Av2Text.bodyMedium,
              ),
              const SizedBox(width: 2),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Av2Colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateBlock(AttendanceDay day) {
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

  Widget _sessions(AttendanceDay day) {
    final sessions = day.sessions;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: Column(
        children: [
          for (var i = 0; i < sessions.length; i++) ...[
            Av2SessionTile(
              session: sessions[i],
              showDivider: false,
              onAction: widget.onSessionAction == null
                  ? null
                  : () => widget.onSessionAction!(sessions[i].recordCode),
            ),
            if (day.breakAfterMinutes(i) > 0)
              Av2BreakRow(
                minutes: day.breakAfterMinutes(i),
                start: sessions[i].signOutAt!,
                end: sessions[i + 1].signInAt,
              ),
          ],
          if (day.hasBreaks) _totalBreak(day),
        ],
      ),
    );
  }

  Widget _totalBreak(AttendanceDay day) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Av2Colors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.free_breakfast_outlined,
              size: 15, color: Av2Colors.breakTime),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Total break',
                style: Av2Text.caption.copyWith(color: Av2Colors.breakTime)),
          ),
          Text(
            Av2DurationFormatter.hm(day.totalBreakMinutes),
            style: Av2Text.bodyMedium
                .copyWith(fontSize: 13, color: Av2Colors.breakTime),
          ),
        ],
      ),
    );
  }
}
