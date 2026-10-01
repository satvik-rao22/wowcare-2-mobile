import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../core/utils/av2_date_formatter.dart';
import '../../core/utils/av2_duration_formatter.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/day_detail.dart';
import '../controllers/day_detail_loader.dart';
import 'av2_break_row.dart';
import 'av2_pill.dart';
import 'av2_session_tile.dart';

/// Desktop/tablet table of days with lazily-loaded session sub-rows. All
/// numeric columns (incl. Break) come from the overview; only the expanded
/// session detail is fetched on demand.
class Av2DayTable extends StatefulWidget {
  const Av2DayTable({
    super.key,
    required this.days,
    required this.loadDetail,
    this.reloadId = 0,
    this.onSessionAction,
  });

  final List<AttendanceDay> days;
  final DayDetailLoader loadDetail;
  final int reloadId;
  final ValueChanged<AttendanceSession>? onSessionAction;

  @override
  State<Av2DayTable> createState() => _Av2DayTableState();
}

class _Av2DayTableState extends State<Av2DayTable> {
  final Set<int> _expanded = {};
  final Map<int, Future<DayDetail>> _futures = {};

  static const _flexDate = 3,
      _flexReg = 2,
      _flexOt = 2,
      _flexTotal = 2,
      _flexBreak = 2,
      _flexAction = 1;

  void _toggle(int index, AttendanceDay day) {
    setState(() {
      if (_expanded.remove(index)) return;
      _expanded.add(index);
      _futures.putIfAbsent(index, () => widget.loadDetail(day.date));
    });
  }

  @override
  void didUpdateWidget(covariant Av2DayTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reloaded after edit/delete → cached session futures are stale; re-fetch
    // for any expanded rows.
    if (widget.reloadId != oldWidget.reloadId) {
      _futures.clear();
      for (final i in _expanded) {
        if (i < widget.days.length) {
          _futures[i] = widget.loadDetail(widget.days[i].date);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppSurfaces.card(radius: Av2Spacing.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _headerRow(),
          for (var i = 0; i < widget.days.length; i++)
            _dayRow(i, widget.days[i]),
        ],
      ),
    );
  }

  Widget _headerRow() {
    final hStyle = Av2Text.label.copyWith(
      fontWeight: FontWeight.w600,
      color: Av2Colors.textPrimary,
    );
    Widget h(
      String t,
      int flex, {
      TextAlign align = TextAlign.left,
      Color? color,
    }) => Expanded(
      flex: flex,
      child: Text(
        t,
        style: color == null ? hStyle : hStyle.copyWith(color: color),
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
    final canExpand = !day.isAbsent;
    return Column(
      children: [
        Material(
          color: isExpanded ? Av2Colors.surfaceMuted : Av2Colors.surface,
          child: InkWell(
            onTap: canExpand ? () => _toggle(index, day) : null,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Av2Colors.border, width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: day.isAbsent
                  ? _absentCells(day)
                  : _attendedCells(day, isExpanded),
            ),
          ),
        ),
        if (isExpanded) _sessionSubRows(index),
      ],
    );
  }

  Widget _attendedCells(AttendanceDay day, bool isExpanded) {
    return Row(
      children: [
        Expanded(
          flex: _flexDate,
          child: Text(
            Av2DateFormatter.monthDay(day.date),
            style: Av2Text.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: _flexReg,
          child: Text(
            Av2DurationFormatter.hm(day.regularMinutes),
            style: Av2Text.body,
          ),
        ),
        Expanded(
          flex: _flexOt,
          child: Text(
            day.hasOvertime
                ? Av2DurationFormatter.hm(day.overtimeMinutes)
                : '—',
            style: Av2Text.body.copyWith(
              color: day.hasOvertime
                  ? Av2Colors.overtime
                  : Av2Colors.textTertiary,
            ),
          ),
        ),
        Expanded(
          flex: _flexTotal,
          child: Text(
            Av2DurationFormatter.hm(day.totalMinutes),
            style: Av2Text.bodyMedium,
          ),
        ),
        Expanded(
          flex: _flexBreak,
          child: Text(
            day.hasBreaks ? Av2DurationFormatter.hm(day.breakMinutes) : '—',
            style: Av2Text.body.copyWith(color: Av2Colors.textSecondary),
          ),
        ),
        Expanded(
          flex: _flexAction,
          child: Align(
            alignment: Alignment.centerRight,
            child: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: Av2Colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _absentCells(AttendanceDay day) {
    return Row(
      children: [
        Expanded(
          flex: _flexDate,
          child: Text(
            Av2DateFormatter.monthDay(day.date),
            style: Av2Text.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Expanded(
          flex: _flexReg + _flexOt + _flexTotal + _flexBreak,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Av2Pill(
              text: 'Absent',
              fill: Av2Colors.dangerFill,
              textColor: Av2Colors.danger,
            ),
          ),
        ),
        const Expanded(flex: _flexAction, child: SizedBox.shrink()),
      ],
    );
  }

  Widget _sessionSubRows(int index) {
    return Container(
      width: double.infinity,
      color: Av2Colors.surfaceMuted,
      padding: const EdgeInsets.fromLTRB(28, 0, 14, 8),
      child: FutureBuilder<DayDetail>(
        future: _futures[index],
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: PrimaryCircularLoader(size: 18, strokeWidth: 2),
              ),
            );
          }
          final d = snap.data;
          if (snap.hasError || d == null || d.sessions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No session details', style: Av2Text.caption),
            );
          }
          final breakByStart = {
            for (final b in d.breaks) b.start.millisecondsSinceEpoch: b,
          };
          final sessions = d.sessions;
          return Column(
            children: [
              for (var i = 0; i < sessions.length; i++) ...[
                Av2SessionTile(
                  session: sessions[i],
                  showDivider: false,
                  onAction: widget.onSessionAction == null
                      ? null
                      : () => widget.onSessionAction!(sessions[i]),
                ),
                if (i < sessions.length - 1 && sessions[i].signOutAt != null)
                  ...(() {
                    final b =
                        breakByStart[sessions[i]
                            .signOutAt!
                            .millisecondsSinceEpoch];
                    return b == null
                        ? const <Widget>[]
                        : [
                            Av2BreakRow(
                              minutes: b.minutes,
                              start: b.start,
                              end: b.end,
                            ),
                          ];
                  })(),
              ],
            ],
          );
        },
      ),
    );
  }
}
