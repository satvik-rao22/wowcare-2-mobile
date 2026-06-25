import 'package:flutter/material.dart';
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

/// Mobile day card. Collapsed = per-day summary (date, OT chip, total — all
/// from the overview). Expanding lazily loads the day's sessions + breaks.
class Av2AttendedDayCard extends StatefulWidget {
  const Av2AttendedDayCard({
    super.key,
    required this.day,
    required this.loadDetail,
    this.reloadId = 0,
    this.initiallyExpanded = false,
    this.onSessionAction,
  });

  final AttendanceDay day;
  final DayDetailLoader loadDetail;
  final int reloadId;
  final bool initiallyExpanded;
  final ValueChanged<AttendanceSession>? onSessionAction;

  @override
  State<Av2AttendedDayCard> createState() => _Av2AttendedDayCardState();
}

class _Av2AttendedDayCardState extends State<Av2AttendedDayCard> {
  late bool _expanded = widget.initiallyExpanded;
  Future<DayDetail>? _future;

  @override
  void initState() {
    super.initState();
    if (_expanded) _future = widget.loadDetail(widget.day.date);
  }

  @override
  void didUpdateWidget(covariant Av2AttendedDayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // After an edit/delete the data reloaded (reloadId bumped); the cached
    // sessions are stale, so re-fetch if this card is currently expanded.
    if (widget.reloadId != oldWidget.reloadId && _expanded) {
      _future = widget.loadDetail(widget.day.date);
    }
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) _future ??= widget.loadDetail(widget.day.date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Av2Colors.surface,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
        border: Border.all(color: Av2Colors.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _header(widget.day),
          if (_expanded) _expandedBody(),
        ],
      ),
    );
  }

  Widget _header(AttendanceDay day) {
    return Material(
      color: _expanded ? Av2Colors.surfaceMuted : Av2Colors.surface,
      child: InkWell(
        onTap: _toggle,
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
              Text(Av2DurationFormatter.hm(day.totalMinutes), style: Av2Text.bodyMedium),
              const SizedBox(width: 2),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18, color: Av2Colors.textSecondary),
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
        Text(Av2DateFormatter.monthDay(day.date),
            style: Av2Text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(Av2DateFormatter.weekday(day.date),
            style: Av2Text.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _expandedBody() {
    return FutureBuilder<DayDetail>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Av2Colors.theme),
              ),
            ),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Av2Colors.textTertiary),
                const SizedBox(width: 8),
                Expanded(child: Text('Couldn’t load details', style: Av2Text.caption)),
                TextButton(
                  onPressed: () => setState(
                      () => _future = widget.loadDetail(widget.day.date)),
                  child: Text('Retry',
                      style: Av2Text.caption.copyWith(color: Av2Colors.theme)),
                ),
              ],
            ),
          );
        }
        return _detail(snap.data!);
      },
    );
  }

  Widget _detail(DayDetail d) {
    final sessions = d.sessions;
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Text('No sessions for this day', style: Av2Text.caption),
      );
    }
    final breakByStart = {
      for (final b in d.breaks) b.start.millisecondsSinceEpoch: b,
    };
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
                  : () => widget.onSessionAction!(sessions[i]),
            ),
            if (i < sessions.length - 1 && sessions[i].signOutAt != null)
              ...(() {
                final b = breakByStart[sessions[i].signOutAt!.millisecondsSinceEpoch];
                return b == null
                    ? const <Widget>[]
                    : [Av2BreakRow(minutes: b.minutes, start: b.start, end: b.end)];
              })(),
          ],
          if (widget.day.hasBreaks) _totalBreak(),
        ],
      ),
    );
  }

  Widget _totalBreak() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Av2Colors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.free_breakfast_outlined, size: 15, color: Av2Colors.breakTime),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Total break',
                style: Av2Text.caption.copyWith(color: Av2Colors.breakTime)),
          ),
          Text(
            Av2DurationFormatter.hm(widget.day.breakMinutes),
            style: Av2Text.bodyMedium.copyWith(fontSize: 13, color: Av2Colors.breakTime),
          ),
        ],
      ),
    );
  }
}
