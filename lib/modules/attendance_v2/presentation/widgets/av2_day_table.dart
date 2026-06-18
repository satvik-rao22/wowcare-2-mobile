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

/// Desktop/tablet presentation of the same days as a table with
/// expandable session sub-rows. Column widths use flex so it never overflows.
class Av2DayTable extends StatefulWidget {
  const Av2DayTable({super.key, required this.days, this.onSessionAction});

  final List<AttendanceDay> days;
  final ValueChanged<String>? onSessionAction;

  @override
  State<Av2DayTable> createState() => _Av2DayTableState();
}

class _Av2DayTableState extends State<Av2DayTable> {
  final Set<int> _expanded = {};

  static const _flexDate = 3;
  static const _flexReg = 2;
  static const _flexOt = 2;
  static const _flexTotal = 2;
  static const _flexBreak = 2;
  static const _flexAction = 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Av2Colors.surface,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
        border: Border.all(color: Av2Colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _headerRow(),
          for (var i = 0; i < widget.days.length; i++) _dayRow(i, widget.days[i]),
        ],
      ),
    );
  }

  Widget _headerRow() {
    final headerStyle = Av2Text.label.copyWith(
      fontWeight: FontWeight.w700,
      color: Av2Colors.textPrimary,
    );
    Widget h(String t, int flex,
            {TextAlign align = TextAlign.left, Color? color}) =>
        Expanded(
          flex: flex,
          child: Text(
            t,
            style: color == null ? headerStyle : headerStyle.copyWith(color: color),
            textAlign: align,
          ),
        );
    return Container(
      color: Av2Colors.surfaceMuted,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          h('Date', _flexDate),
          h('Regular', _flexReg),
          h('Overtime', _flexOt, color: Av2Colors.overtime),
          h('Total', _flexTotal),
          h('Break', _flexBreak),
          h('', _flexAction, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _dayRow(int index, AttendanceDay day) {
    final isExpanded = _expanded.contains(index);
    final canExpand = !day.isAbsent && day.sessions.isNotEmpty;
    return Column(
      children: [
        Material(
          color: isExpanded ? Av2Colors.surfaceMuted : Av2Colors.surface,
          child: InkWell(
            onTap: canExpand
                ? () => setState(() {
                      isExpanded ? _expanded.remove(index) : _expanded.add(index);
                    })
                : null,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Av2Colors.border, width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: day.isAbsent ? _absentCells(day) : _attendedCells(day, canExpand, isExpanded),
            ),
          ),
        ),
        if (isExpanded) _sessionSubRows(day),
      ],
    );
  }

  Widget _attendedCells(AttendanceDay day, bool canExpand, bool isExpanded) {
    return Row(
      children: [
        Expanded(
          flex: _flexDate,
          child: Text(Av2DateFormatter.monthDay(day.date),
              style: Av2Text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: _flexReg,
          child: Text(Av2DurationFormatter.hm(day.regularMinutes), style: Av2Text.body),
        ),
        Expanded(
          flex: _flexOt,
          child: Text(
            day.hasOvertime ? Av2DurationFormatter.hm(day.overtimeMinutes) : '—',
            style: Av2Text.body.copyWith(
              color: day.hasOvertime ? Av2Colors.overtime : Av2Colors.textTertiary,
            ),
          ),
        ),
        Expanded(
          flex: _flexTotal,
          child: Text(Av2DurationFormatter.hm(day.totalMinutes), style: Av2Text.bodyMedium),
        ),
        Expanded(
          flex: _flexBreak,
          child: Text(
            day.hasBreaks ? Av2DurationFormatter.hm(day.totalBreakMinutes) : '—',
            style: Av2Text.body.copyWith(color: Av2Colors.textSecondary),
          ),
        ),
        Expanded(
          flex: _flexAction,
          child: Align(
            alignment: Alignment.centerRight,
            child: canExpand
                ? Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16, color: Av2Colors.textSecondary)
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _absentCells(AttendanceDay day) {
    final markedBy = day.absenceMarkedBy?.trim();
    return Row(
      children: [
        Expanded(
          flex: _flexDate,
          child: Text(Av2DateFormatter.monthDay(day.date),
              style: Av2Text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: _flexReg + _flexOt + _flexTotal + _flexBreak,
          child: Row(
            children: [
              const Av2Pill(
                text: 'Absent',
                fill: Av2Colors.dangerFill,
                textColor: Av2Colors.danger,
              ),
              if (markedBy != null && markedBy.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text('marked by $markedBy',
                      style: Av2Text.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
        ),
        const Expanded(flex: _flexAction, child: SizedBox.shrink()),
      ],
    );
  }

  Widget _sessionSubRows(AttendanceDay day) {
    return Container(
      width: double.infinity,
      color: Av2Colors.surfaceMuted,
      padding: const EdgeInsets.fromLTRB(28, 0, 14, 8),
      child: Column(
        children: [
          for (var i = 0; i < day.sessions.length; i++) ...[
            Av2SessionTile(
              session: day.sessions[i],
              showDivider: false,
              onAction: widget.onSessionAction == null
                  ? null
                  : () => widget.onSessionAction!(day.sessions[i].recordCode),
            ),
            if (day.breakAfterMinutes(i) > 0)
              Av2BreakRow(
                minutes: day.breakAfterMinutes(i),
                start: day.sessions[i].signOutAt!,
                end: day.sessions[i + 1].signInAt,
              ),
          ],
        ],
      ),
    );
  }
}
