import 'package:flutter/material.dart';
import '../../core/responsive/av2_breakpoints.dart';
import '../../core/theme/av2_spacing.dart';
import '../../domain/entities/staff_overtime_profile.dart';
import '../controllers/av2_day_filter.dart';
import '../controllers/av2_period.dart';
import '../controllers/day_detail_loader.dart';
import '../widgets/av2_action_sheet.dart';
import '../widgets/av2_day_table.dart';
import '../widgets/av2_day_timeline.dart';
import '../widgets/av2_filter_chips.dart';
import '../widgets/av2_hero_card.dart';
import '../widgets/av2_identity_row.dart';
import '../widgets/av2_period_sheet.dart';

/// Pure presentation of a loaded [StaffOvertimeProfile]. Day sessions load
/// lazily through [loadDetail] when a row expands. Responsive: card timeline on
/// mobile/tablet, data table on desktop.
class StaffDetailView extends StatefulWidget {
  const StaffDetailView({
    super.key,
    required this.profile,
    required this.period,
    required this.loadDetail,
    this.onPeriodChanged,
  });

  final StaffOvertimeProfile profile;
  final Av2Period period;
  final DayDetailLoader loadDetail;
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

  Future<void> _editSession(String recordCode) async {
    final action = await showAv2ActionSheet(context, title: 'Edit attendance');
    if (action == null || !mounted) return;
    final verb = action == Av2RecordAction.edit ? 'Edit' : 'Delete';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$verb · $recordCode')),
    );
  }

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

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Av2Spacing.contentMaxWidth),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                loadDetail: widget.loadDetail,
                emptyMessage: _emptyMessage(),
                onSessionAction: _editSession,
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
      physics: const AlwaysScrollableScrollPhysics(),
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
                Av2DayTimeline(
                  days: filtered,
                  loadDetail: widget.loadDetail,
                  emptyMessage: _emptyMessage(),
                )
              else
                Av2DayTable(
                  days: filtered,
                  loadDetail: widget.loadDetail,
                  onSessionAction: _editSession,
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
