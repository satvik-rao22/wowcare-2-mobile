import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_regularization/regularization.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import '../../core/responsive/av2_breakpoints.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/utils/av2_date_formatter.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/av2_staff_summary.dart';
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
import '../widgets/av2_staff_switcher_sheet.dart';

/// Edits a session: returns true on success so the screen can toast.
typedef Av2EditSession =
    Future<void> Function({
      required String recordCode,
      required DateTime signInLocal,
      DateTime? signOutLocal,
    });

/// Deletes a session by record code.
typedef Av2DeleteSession = Future<void> Function(String recordCode);

/// Edits an absence record (date + note; reason/type carried through).
typedef Av2EditAbsence =
    Future<void> Function({
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
///
/// Filtering + pagination are *controlled* when [onFilterSelected] is provided
/// (server-side): the parent supplies already-filtered [profile] days and a
/// page at a time, and [onLoadMore] fetches the next page on scroll. When
/// [onFilterSelected] is null the view filters [profile] days client-side (used
/// by the static preview / tests).
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
    this.filter = Av2DayFilter.all,
    this.onFilterSelected,
    this.onLoadMore,
    this.hasMore = false,
    this.loadingMore = false,
    this.staff = const [],
    this.onStaffSelected,
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

  /// Selected filter (for chip highlight in controlled mode).
  final Av2DayFilter filter;

  /// When non-null, filtering is server-side: the parent refetches on change.
  final ValueChanged<Av2DayFilter>? onFilterSelected;

  /// Fetches the next page (scroll pagination). No-op when null.
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool loadingMore;

  /// School staff + handler for the admin "switch staff" picker. When [staff]
  /// is non-empty and [onStaffSelected] is set, the identity row is tappable.
  final List<Av2StaffSummary> staff;
  final ValueChanged<Av2StaffSummary>? onStaffSelected;

  @override
  State<StaffDetailView> createState() => _StaffDetailViewState();
}

class _StaffDetailViewState extends State<StaffDetailView> {
  late Av2DayFilter _filter = widget.filter;

  bool get _controlled => widget.onFilterSelected != null;
  StaffOvertimeProfile get _profile => widget.profile;

  /// Days to show: server already filtered them in controlled mode; otherwise
  /// apply the chip filter locally.
  List<AttendanceDay> get _days =>
      _controlled ? _profile.days : _filter.apply(_profile.days);

  @override
  void didUpdateWidget(covariant StaffDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the chip in sync when the parent resets the filter (e.g. on reload).
    if (_controlled && widget.filter != oldWidget.filter) {
      _filter = widget.filter;
    }
  }

  void _onFilter(Av2DayFilter f) {
    setState(() => _filter = f);
    widget.onFilterSelected?.call(f);
  }

  bool _onScroll(ScrollNotification n) {
    if (widget.onLoadMore == null || !widget.hasMore || widget.loadingMore) {
      return false;
    }
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 320) {
      widget.onLoadMore!();
    }
    return false;
  }

  bool get _canSwitchStaff =>
      widget.onStaffSelected != null && widget.staff.isNotEmpty;

  Widget _identity() => Av2IdentityRow(
    profile: _profile,
    onTap: _canSwitchStaff ? _onSwitchStaff : null,
  );

  Future<void> _onSwitchStaff() async {
    final picked = await showAv2StaffSwitcherSheet(
      context,
      staff: widget.staff,
      currentCode: _profile.staffCode,
    );
    if (picked == null || !mounted || picked.code == _profile.staffCode) return;
    widget.onStaffSelected?.call(picked);
  }

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
      message:
          '$summary\n\nThis removes the record and recalculates the day. '
          'This can’t be undone.',
    );
    if (!confirmed || !mounted) return;
    final del = widget.onDeleteSession;
    if (del == null) return;
    try {
      await del(session.recordCode);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Attendance deleted',
        isSuccess: true,
      );
    } catch (e, st) {
      AppLogger.e('Av2 delete attendance failed', e, st);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: _failure(e, 'Couldn’t delete attendance. Try again.'),
        isError: true,
      );
    }
  }

  Future<void> _onAbsentAction(AttendanceDay day) async {
    if (!day.canEditAbsence) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Absence record id unavailable from server',
        isError: true,
      );
      return;
    }
    final action = await showAv2ActionSheet(context, title: 'Edit absent');
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
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Absence updated',
        isSuccess: true,
      );
    } catch (e, st) {
      AppLogger.e('Av2 update absence failed', e, st);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: _failure(e, 'Couldn’t update absence. Try again.'),
        isError: true,
      );
    }
  }

  Future<void> _deleteAbsence(AttendanceDay day) async {
    final confirmed = await showAv2ConfirmDialog(
      context,
      title: 'Delete absence?',
      message:
          '${Av2DateFormatter.monthDay(day.date)} · Absent\n\nThis removes '
          'the absence and recalculates the day. This can’t be undone.',
    );
    if (!confirmed || !mounted) return;
    final del = widget.onDeleteAbsence;
    if (del == null) return;
    try {
      await del(day.absenceCode!);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Absence deleted',
        isSuccess: true,
      );
    } catch (e, st) {
      AppLogger.e('Av2 delete absence failed', e, st);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: _failure(e, 'Couldn’t delete absence. Try again.'),
        isError: true,
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
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Attendance updated',
        isSuccess: true,
      );
    } catch (e, st) {
      AppLogger.e('Av2 update attendance failed', e, st);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: _failure(e, 'Couldn’t update attendance. Try again.'),
        isError: true,
      );
    }
  }

  /// The server's own reason when it gave one (e.g. a rejected overlap), so an
  /// admin can act on it; [fallback] only when there is nothing better than
  /// the generic "something went wrong".
  String _failure(Object error, String fallback) {
    final message = ApiErrorHandler.extractErrorMessage(error);
    return message.isEmpty || message == ApiErrorHandler.genericError
        ? fallback
        : message;
  }

  @override
  Widget build(BuildContext context) {
    final body = Av2Breakpoints.ofContext(context) == Av2FormFactor.desktop
        ? _desktopBody(context)
        : _mobileBody(context);
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: body,
    );
  }

  Widget _hero() => Av2HeroCard(
    profile: _profile,
    periodLabel: widget.period.label,
    onPickRange: _pickPeriod,
    onTapNeedsAttention: () => _onFilter(Av2DayFilter.requests),
  );

  Widget _bottomLoader() => const Padding(
    padding: EdgeInsets.symmetric(vertical: Av2Spacing.md),
    child: Center(child: PrimaryCircularLoader(size: 22, strokeWidth: 2)),
  );

  Widget _mobileBody(BuildContext context) {
    final f = Av2Breakpoints.ofContext(context);
    final pad = Av2Breakpoints.screenPadding(f);

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
              _identity(),
              const SizedBox(height: Av2Spacing.md),
              _hero(),
              const SizedBox(height: Av2Spacing.md),
              Av2FilterChips(selected: _filter, onSelected: _onFilter),
              const SizedBox(height: Av2Spacing.sm),
              if (_filter == Av2DayFilter.requests)
                Regularization.requestsList(
                  staffCode: _profile.staffCode,
                  from: widget.period.start,
                  to: widget.period.end,
                )
              else ...[
                Av2DayTimeline(
                  days: _days,
                  loadDetail: widget.loadDetail,
                  reloadId: widget.reloadId,
                  emptyMessage: _emptyMessage(),
                  onSessionAction: widget.canEdit ? _onSessionAction : null,
                  onAbsentAction: widget.canEdit ? _onAbsentAction : null,
                ),
                if (widget.loadingMore) _bottomLoader(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopBody(BuildContext context) {
    final days = _days;
    const pad = Av2Spacing.screenPadDesktop;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        pad,
        Av2Spacing.xs,
        pad,
        Av2Spacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _identity(),
              const SizedBox(height: Av2Spacing.md),
              _hero(),
              const SizedBox(height: Av2Spacing.md),
              Av2FilterChips(selected: _filter, onSelected: _onFilter),
              const SizedBox(height: Av2Spacing.sm),
              if (_filter == Av2DayFilter.requests)
                Regularization.requestsList(
                  staffCode: _profile.staffCode,
                  from: widget.period.start,
                  to: widget.period.end,
                )
              else if (days.isEmpty)
                Av2DayTimeline(
                  days: days,
                  loadDetail: widget.loadDetail,
                  emptyMessage: _emptyMessage(),
                )
              else
                Av2DayTable(
                  days: days,
                  loadDetail: widget.loadDetail,
                  reloadId: widget.reloadId,
                  onSessionAction: widget.canEdit ? _onSessionAction : null,
                ),
              if (_filter != Av2DayFilter.requests && widget.loadingMore)
                _bottomLoader(),
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
