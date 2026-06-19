import 'package:flutter/material.dart';
import '../../core/theme/av2_spacing.dart';
import '../../domain/entities/attendance_day.dart';
import '../controllers/day_detail_loader.dart';
import 'av2_absent_day_card.dart';
import 'av2_attended_day_card.dart';
import 'av2_empty_state.dart';

/// Mobile/tablet timeline: a vertical list of day cards (attended expandable,
/// absent inline). Renders an empty state when [days] is empty.
class Av2DayTimeline extends StatelessWidget {
  const Av2DayTimeline({
    super.key,
    required this.days,
    required this.loadDetail,
    this.emptyMessage = 'No days match this filter',
    this.onSessionAction,
  });

  final List<AttendanceDay> days;
  final DayDetailLoader loadDetail;
  final String emptyMessage;
  final ValueChanged<String>? onSessionAction;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Av2EmptyState(message: emptyMessage);
    }
    // Auto-expand the first day that needs attention so the issue is visible
    // without a tap.
    final attentionIndex =
        days.indexWhere((d) => !d.isAbsent && d.needsAttention);
    return Column(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i != 0) const SizedBox(height: Av2Spacing.xs + 2),
          _card(days[i], i == attentionIndex),
        ],
      ],
    );
  }

  Widget _card(AttendanceDay day, bool expand) {
    if (day.isAbsent) {
      return Av2AbsentDayCard(day: day);
    }
    return Av2AttendedDayCard(
      day: day,
      loadDetail: loadDetail,
      initiallyExpanded: expand,
      onSessionAction: onSessionAction,
    );
  }
}
