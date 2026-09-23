import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_regularization/regularization.dart';
import '../../core/responsive/av2_breakpoints.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/utils/av2_date_formatter.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/staff_overtime_profile.dart';
import '../controllers/av2_day_filter.dart';
import '../controllers/av2_period.dart';
import '../controllers/day_detail_loader.dart';
import '../widgets/av2_action_sheet.dart';
import '../widgets/av2_confirm_dialog.dart';
import '../widgets/av2_day_table.dart';
import '../widgets/av2_day_timeline.dart';
import '../widgets/av2_edit_absence_sheet.dart';
import '../widgets/av2_edit_attendance_sheet.dart';
import '../widgets/av2_filter_chips.dart';
import '../widgets/av2_hero_card.dart';
import '../widgets/av2_identity_row.dart';
import '../widgets/av2_period_sheet.dart';

/// Edits a session: returns true on success so the screen can toast.
typedef Av2EditSession = Future<void> Function({
  required String recordCode,
  required DateTime signInLocal,
  DateTime? signOutLocal,
});

/// Deletes a session by record code.
typedef Av2DeleteSession = Future<void> Function(String recordCode);

/// Edits an absence record.
typedef Av2EditAbsence = Future<void> Function({
  required String code,
  required DateTime fromDate,
  required DateTime toDate,
  required String reason,
  required String type,
  required String note,
});

/// Deletes an absence record by code.
typedef Av2DeleteAbsence = Future<void> Function(String code);

/// Pure presentation of a loaded [StaffOvertimeProfile]. Day sessions load
/// lazily through [loadDetail] when a row expands. Responsive: card timeline on
/// mobile/tablet, data table on desktop.
class StaffDetailView extends StatefulWidget {
  const StaffDetailView({
    super.key,
    required this.profile,
    required this.period,
    required this.loadDetail,
    this.reloadId = 0,
    this.onPeriodChanged,
    this.canEdit = false,
    this.onEditSession,
    this.onDeleteSession,
    this.onEditAbsence,
    this.onDeleteAbsence,
  });

  final StaffOvertimeProfile profile;
  final Av2Period period;
  final DayDetailLoader loadDetail;

  /// Bumped on every (re)load so expanded day rows re-fetch stale session
  /// detail after an edit/delete.
  final int reloadId;
  final ValueChanged<Av2Period>? onPeriodChanged;

  /// Admin-only: when false, no edit/delete affordance is shown on rows.
  final bool canEdit;
  final Av2EditSession? onEditSession;
  final Av2DeleteSession? onDeleteSession;
  final Av2EditAbsence? onEditAbsence;
  final Av2DeleteAbsence? onDeleteAbsence;

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

  Future<void> _onSessionAction(AttendanceSession session) async {
    final action = await showAv2ActionSheet(context, title: 'Edit attendance');
    if (action == null || !mounted) return;
    if (action == Av2RecordAction.edit) {
      await _editSession(session);
    } else {
      await _deleteSession(session);
    }
  }

  Future<void> _deleteSession(AttendanceSession session) async {
    final inStr = Av2DateFormatter.compactTime(session.signInAt);
    final outStr = session.signOutAt == null
        ? 'open'
        : Av2DateFormatter.compactTime(session.signOutAt!);
    final summary =
        '${Av2DateFormatter.monthDay(session.signInAt)} · ${session.classroomName} · $inStr → $outStr';

    final confirmed = await showAv2ConfirmDialog(
      context,
      title: 'Delete attendance?',
      message: '$summary\n\nThis removes the record and recalculates the day. '
          'This can’t be undone.',
    );
    if (!confirmed || !mounted) return;
    final del = widget.onDeleteSession;
    if (del == null) return;
    try {
      await del(session.recordCode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance deleted')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t delete attendance. Try again.')),
      );
    }
  }

  Future<void> _onAbsentAction(AttendanceDay day) async {
    if (!day.canEditAbsence) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Absence record id unavailable from server')),
      );
      return;
    }
    final action = await showAv2ActionSheet(context, title: 'Edit absence');
    if (action == null || !mounted) return;
    if (action == Av2RecordAction.edit) {
      await _editAbsence(day);
    } else {
      await _deleteAbsence(day);
    }
  }

  Future<void> _editAbsence(AttendanceDay day) async {
    final result = await showAv2EditAbsenceSheet(context, day: day);
    if (result == null || !mounted) return;
    final edit = widget.onEditAbsence;
    if (edit == null) return;
    try {
      await edit(
        code: day.absenceCode!,
        fromDate: result.fromDate,
        toDate: result.toDate,
        reason: result.reason,
        type: result.type,
        note: result.note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absence updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t update absence. Try again.')),
      );
    }
  }

  Future<void> _deleteAbsence(AttendanceDay day) async {
    final confirmed = await showAv2ConfirmDialog(
      context,
      title: 'Delete absence?',
      message: '${Av2DateFormatter.monthDay(day.date)} · Absent\n\nThis removes '
          'the absence and recalculates the day. This can’t be undone.',
    );
    if (!confirmed || !mounted) return;
    final del = widget.onDeleteAbsence;
    if (del == null) return;
    try {
      await del(day.absenceCode!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absence deleted')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t delete absence. Try again.')),
      );
    }
  }

  Future<void> _editSession(AttendanceSession session) async {
    final result = await showAv2EditAttendanceSheet(context, session: session);
    if (result == null || !mounted) return;
    final edit = widget.onEditSession;
    if (edit == null) return;
    try {
      await edit(
        recordCode: session.recordCode,
        signInLocal: result.signInLocal,
        signOutLocal: result.signOutLocal,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t update attendance. Try again.')),
      );
    }
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
        onTapNeedsAttention: () => _setFilter(Av2DayFilter.requests),
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
              if (_filter == Av2DayFilter.requests)
                Regularization.requestsList(staffCode: _profile.staffCode)
              else
                Av2DayTimeline(
                  days: filtered,
                  loadDetail: widget.loadDetail,
                  reloadId: widget.reloadId,
                  emptyMessage: _emptyMessage(),
                  onSessionAction: widget.canEdit ? _onSessionAction : null,
                  onAbsentAction: widget.canEdit ? _onAbsentAction : null,
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
              if (_filter == Av2DayFilter.requests)
                Regularization.requestsList(staffCode: _profile.staffCode)
              else if (filtered.isEmpty)
                Av2DayTimeline(
                  days: filtered,
                  loadDetail: widget.loadDetail,
                  emptyMessage: _emptyMessage(),
                )
              else
                Av2DayTable(
                  days: filtered,
                  loadDetail: widget.loadDetail,
                  reloadId: widget.reloadId,
                  onSessionAction: widget.canEdit ? _onSessionAction : null,
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
      case Av2DayFilter.requests:
        return 'No regularization requests';
      case Av2DayFilter.all:
        return 'No attendance records for this range';
    }
  }
}
