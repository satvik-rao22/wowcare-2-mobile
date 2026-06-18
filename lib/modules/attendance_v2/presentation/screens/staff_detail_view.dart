import 'package:flutter/material.dart';
import '../../core/responsive/av2_breakpoints.dart';
import '../../core/theme/av2_spacing.dart';
import '../../domain/entities/staff_overtime_profile.dart';
import '../controllers/av2_day_filter.dart';
import '../controllers/av2_period.dart';
import '../widgets/av2_action_sheet.dart';
import '../widgets/av2_day_table.dart';
import '../widgets/av2_day_timeline.dart';
import '../widgets/av2_filter_chips.dart';
import '../widgets/av2_hero_card.dart';
import '../widgets/av2_identity_row.dart';
import '../widgets/av2_period_sheet.dart';

/// Pure presentation of a loaded [StaffOvertimeProfile]. No data fetching — the
/// parent supplies the profile and the selected period, and is notified when
/// the user picks a new period. Responsive: card timeline on mobile/tablet,
/// data table on desktop.
class StaffDetailView extends StatefulWidget {
  const StaffDetailView({
    super.key,
    required this.profile,
    required this.period,
    this.onPeriodChanged,
  });

  final StaffOvertimeProfile profile;
  final Av2Period period;
  final ValueChanged<Av2Period>? onPeriodChanged;

  @override
  State<StaffDetailView> createState() => _StaffDetailViewState();
}

class _StaffDetailViewState extends State<StaffDetailView> {
  Av2DayFilter _filter = Av2DayFilter.all;

  StaffOvertimeProfile get _profile => widget.profile;

  void _setFilter(Av2DayFilter f) => setState(() => _filter = f);

  Future<void> _pickPeriod() async {
    final picked = await showAv2PeriodSheet(context, current: widget.period);
    if (picked != null) widget.onPeriodChanged?.call(picked);
  }

  Future<void> _editRecord(String recordCode, {bool isAbsence = false}) async {
    final action = await showAv2ActionSheet(
      context,
      title: isAbsence ? 'Edit absence' : 'Edit attendance',
    );
    if (action == null || !mounted) return;
    final verb = action == Av2RecordAction.edit ? 'Edit' : 'Delete';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$verb · $recordCode')),
    );
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Av2Breakpoints.ofContext(context) == Av2FormFactor.desktop
        ? _desktopBody(context)
        : _mobileBody(context);
  }

  Widget _hero() => Av2HeroCard(
        profile: _profile,
        periodLabel: widget.period.label,
        onPickRange: _pickPeriod,
        onTapNeedsAttention: () => _setFilter(Av2DayFilter.needsAttention),
      );

  Widget _mobileBody(BuildContext context) {
    final f = Av2Breakpoints.ofContext(context);
    final pad = Av2Breakpoints.screenPadding(f);
    final filtered = _filter.apply(_profile.days);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Av2Spacing.contentMaxWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, Av2Spacing.xs, pad, Av2Spacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Av2IdentityRow(profile: _profile),
              const SizedBox(height: Av2Spacing.md),
              _hero(),
              const SizedBox(height: Av2Spacing.md),
              Av2FilterChips(selected: _filter, onSelected: _setFilter),
              const SizedBox(height: Av2Spacing.sm),
              Av2DayTimeline(
                days: filtered,
                emptyMessage: _emptyMessage(),
                onSessionAction: (code) => _editRecord(code),
                onAbsentAction: (date) =>
                    _editRecord(_dateKey(date), isAbsence: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopBody(BuildContext context) {
    final filtered = _filter.apply(_profile.days);
    const pad = Av2Spacing.screenPadDesktop;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(pad, Av2Spacing.xs, pad, Av2Spacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Av2IdentityRow(profile: _profile),
              const SizedBox(height: Av2Spacing.md),
              _hero(),
              const SizedBox(height: Av2Spacing.md),
              Av2FilterChips(selected: _filter, onSelected: _setFilter),
              const SizedBox(height: Av2Spacing.sm),
              if (filtered.isEmpty)
                Av2DayTimeline(days: filtered, emptyMessage: _emptyMessage())
              else
                Av2DayTable(
                  days: filtered,
                  onSessionAction: (code) => _editRecord(code),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _emptyMessage() {
    switch (_filter) {
      case Av2DayFilter.overtime:
        return 'No overtime in this range';
      case Av2DayFilter.absent:
        return 'No absences in this range';
      case Av2DayFilter.needsAttention:
        return 'Nothing needs attention';
      case Av2DayFilter.all:
        return 'No attendance records for this range';
    }
  }
}
