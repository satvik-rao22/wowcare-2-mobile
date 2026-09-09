import 'package:flutter/material.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/entities/staff_shift.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classroom/view/filters/designation_display_utils.dart';
import 'package:wowcare/presentation/features/scheduling/model/shift_models.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_route_args.dart';
import 'package:wowcare/presentation/features/scheduling/view_model/staff_scheduling_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/view/edit_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/publish_shifts_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/view_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view_model/scheduling_staff_list_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/utils/scheduling_cache_gate.dart';
import 'package:wowcare/domain/features/scheduling/services/scheduling_school_time.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_day_schedule_calendar.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_schedule_tile.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_scheduling_staff_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Staff Scheduling — single-day view with staff picker, profile summary,
/// hour totals, and day timeline. Staff dropdown is fed by [StaffCubit] (with
/// disk cache); pull-to-refresh re-pulls staff + classroom data. Shift list
/// remains placeholder until the shift-API cubit is wired in.
class StaffSchedulingScreen extends StatelessWidget {
  const StaffSchedulingScreen({
    super.key,
    this.initialDate,
    this.initialStaffCode,
    this.highlightShiftCode,
  });

  static const String routeName = DashboardRoutes.staffScheduling;

  /// Notification deep-link: jump to this day on open (shift's date).
  final DateTime? initialDate;

  /// Notification deep-link: pre-select this staff member once the roster loads.
  final String? initialStaffCode;

  /// Notification deep-link: flash the shift block with this code.
  final String? highlightShiftCode;

  @override
  Widget build(BuildContext context) {
    return _StaffSchedulingView(
      initialDate: initialDate,
      initialStaffCode: initialStaffCode,
      highlightShiftCode: highlightShiftCode,
    );
  }
}

class _StaffSchedulingView extends StatefulWidget {
  const _StaffSchedulingView({
    this.initialDate,
    this.initialStaffCode,
    this.highlightShiftCode,
  });

  final DateTime? initialDate;
  final String? initialStaffCode;
  final String? highlightShiftCode;

  @override
  State<_StaffSchedulingView> createState() => _StaffSchedulingViewState();
}

class _StaffSchedulingViewState extends State<_StaffSchedulingView> {
  /// Persists across screen instances so an edit that happened while this
  /// screen was off-stack still triggers a silent staff-list refresh on
  /// the next visit.
  static int _lastConsumedRevision = 0;

  /// Tracks the device-local "today" used by [StaffSchedulingState.initial]
  /// before the school zone resolved, so we can re-seed the cubit only when
  /// the user hasn't already picked a different day.
  DateTime? _initialDeviceToday;

  /// Notification deep-link state: applied once each (date immediately, staff
  /// once the roster contains the wanted code).
  bool _deepLinkDateApplied = false;
  bool _deepLinkStaffApplied = false;

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _initialDeviceToday = DateTime(now.year, now.month, now.day);
    SchedulingCacheGate.revision.addListener(_onCacheInvalidated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyPersonaScope();
      _silentlyRefreshStaffIfDirty();
      _bootstrapSchoolZone();
      _applyDeepLink();
    });
  }

  /// Applies the notification deep-link (date + staff). Called from initState
  /// and again from the [BlocListener] so the staff selection lands as soon as
  /// the roster finishes loading. Each part applies at most once.
  void _applyDeepLink() {
    if (!mounted) return;
    final cubit = context.read<StaffSchedulingCubit>();
    final date = widget.initialDate;
    if (!_deepLinkDateApplied && date != null) {
      _deepLinkDateApplied = true;
      cubit.selectDay(date);
    }
    final code = widget.initialStaffCode?.trim() ?? '';
    if (!_deepLinkStaffApplied &&
        code.isNotEmpty &&
        cubit.state.staffList.any((s) => s.code == code)) {
      _deepLinkStaffApplied = true;
      cubit.selectStaffByCode(code);
    }
  }

  /// Forwards [RoleCubit]'s persona decision into the cubit so the roster +
  /// add/publish/edit/delete affordances stay in sync with the rest of the app
  /// (the cubit is a singleton — running this on every screen mount also
  /// covers persona switches that happened while the screen was off-stack).
  Future<void> _applyPersonaScope() async {
    final isStaff = context.read<RoleCubit>().isStaff;
    await context.read<StaffSchedulingCubit>().applyPersonaScope(
          isStaffPersona: isStaff,
        );
  }

  Future<void> _bootstrapSchoolZone() async {
    try {
      final cubit = context.read<StaffSchedulingCubit>();
      await cubit.bootstrapSchoolTimezone();
      if (!mounted) return;
      final schoolToday = schedulingSchoolToday();
      final selected = cubit.state.selectedDay;
      final initialToday = _initialDeviceToday;
      final stillOnInitialToday = initialToday != null &&
          selected.year == initialToday.year &&
          selected.month == initialToday.month &&
          selected.day == initialToday.day;
      if (stillOnInitialToday &&
          (selected.year != schoolToday.year ||
              selected.month != schoolToday.month ||
              selected.day != schoolToday.day)) {
        cubit.selectDay(schoolToday);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    SchedulingCacheGate.revision.removeListener(_onCacheInvalidated);
    super.dispose();
  }

  void _onCacheInvalidated() {
    if (!mounted) return;
    _silentlyRefreshStaffIfDirty();
  }

  /// Force-pull the staff roster (only) when the gate bumps. Uses the
  /// cubit's [StaffSchedulingCubit.silentRefreshStaff] so the dropdown
  /// updates in place — no shimmer, no shift/classroom refetch.
  void _silentlyRefreshStaffIfDirty() {
    final current = SchedulingCacheGate.revision.value;
    if (current == _lastConsumedRevision) return;
    _lastConsumedRevision = current;
    // ignore: discarded_futures
    context.read<StaffSchedulingCubit>().silentRefreshStaff();
  }

  /// Pull-to-refresh: re-fires every API this screen depends on. Refreshes
  /// the [StaffSchedulingCubit] (school hours + classroom names + roster +
  /// shifts), invalidates the [ClassroomCubit] cache, re-applies the persona
  /// scope, and force-refires the bulk `/staff-attendance/sign-in/status`
  /// POST (the dedupe guard would otherwise short-circuit it for an
  /// unchanged roster).
  Future<void> _onRefresh() async {
    final cubit = context.read<StaffSchedulingCubit>();
    final classroomCubit = context.read<ClassroomCubit>();
    await Future.wait<void>([
      cubit.refresh(),
      classroomCubit.loadActiveClassrooms(
        force: true,
        onlyTypeClassroom: false,
      ),
    ]);
    if (!mounted) return;
    await _applyPersonaScope();
    if (!mounted) return;
    await cubit.refreshSignInStatusForRoster(
      cubit.state.staffList,
      force: true,
    );
  }

  Future<void> _openAddShiftScreen(
    BuildContext context,
    StaffSchedulingState state, {
    String? initialStaffCode,
    String? initialClassroomCode,
    TimeOfDay? initialShiftStart,
    TimeOfDay? initialShiftEnd,
  }) async {
    final classroomCubit = context.read<ClassroomCubit>();
    final schedulingStaffListCubit =
        context.read<SchedulingStaffListCubit>();
    final schedulingCubit = context.read<StaffSchedulingCubit>();
    final saved = await context.push<bool>(
      SchedulingRoutes.addShift,
      extra: AddShiftRouteArgs(
        schedulingStaffListCubit: schedulingStaffListCubit,
        classroomCubit: classroomCubit,
        initialDate: state.selectedDay,
        initialClassroomCode: initialClassroomCode,
        initialStaffCode: initialStaffCode,
        initialShiftStart: initialShiftStart,
        initialShiftEnd: initialShiftEnd,
        prefillStaff: initialStaffCode != null,
      ),
    );
    if (saved == true && mounted) {
      await schedulingCubit.refresh();
    }
  }

  int _minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;

  TimeOfDay _timeFromMinutes(int minutes) {
    final normalized = minutes.clamp(0, (24 * 60) - 1);
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  String _formatTimeLabel(TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String? _defaultClassroomCodeForStaff(StaffMember? staff) {
    if (staff == null) return null;
    final primary = staff.primaryClassroomCode.trim();
    if (primary.isNotEmpty) return primary;
    for (final code in staff.allowedClassroomCodes) {
      final trimmed = code.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  TimeOfDay _defaultShiftEndForSlot(
    StaffSchedulingState state,
    TimeOfDay start,
  ) {
    final endLimit = state.schoolEndTime == null
        ? null
        : _parseClockTime(state.schoolEndTime!);
    final preferredEnd = _minutesOf(start) + 60;
    final limit = endLimit == null ? preferredEnd : _minutesOf(endLimit);
    return _timeFromMinutes(preferredEnd <= limit ? preferredEnd : limit);
  }

  Future<void> _openAddShiftForEmptySlot(
    BuildContext context,
    StaffSchedulingState state,
    TimeOfDay start,
  ) async {
    if (state.isStaffPersonaScope) return;
    final staffCode = state.selectedStaffCode;
    if (staffCode == null || staffCode.isEmpty) return;
    final end = _defaultShiftEndForSlot(state, start);
    if (_minutesOf(end) <= _minutesOf(start)) return;

    final shouldAdd = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add shift',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('EEE, MMM d').format(state.selectedDay)} '
                  '${_formatTimeLabel(start)} - ${_formatTimeLabel(end)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.buildPrimaryGradient(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(true),
                      child: const Text(
                        'Add Shift',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldAdd != true || !context.mounted) return;
    await _openAddShiftScreen(
      context,
      state,
      initialStaffCode: staffCode,
      initialClassroomCode: _defaultClassroomCodeForStaff(state.selectedStaff),
      initialShiftStart: start,
      initialShiftEnd: end,
    );
  }

  List<Shift> _shiftsFromSummary(StaffShiftDaySummary summary) {
    return summary.blocks
        .map(
          (b) => Shift(
            start: b.start,
            end: b.end,
            room: b.room,
            isBreakShift: b.isBreak,
            shiftCode: b.shiftCode,
          ),
        )
        .toList();
  }

  /// Parses `"hh:mm:ss a"` (the format used by `StaffShiftTimelineBlock`) into
  /// `TimeOfDay`. Returns null on any parse failure.
  TimeOfDay? _parseClockTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(' ');
    if (parts.length < 2) return null;
    final timePart = parts[0];
    final marker = parts[1].toUpperCase();
    final segments = timePart.split(':');
    if (segments.length < 2) return null;
    var hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    if (hour == null || minute == null) return null;
    final isPm = marker == 'PM';
    final isAm = marker == 'AM';
    if (!isAm && !isPm) return null;
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _openViewShiftScreen(
    BuildContext context,
    StaffSchedulingState state,
    Shift tappedShift,
  ) async {
    final schedulingCubit = context.read<StaffSchedulingCubit>();
    final shiftCode = tappedShift.shiftCode.trim();
    if (shiftCode.isEmpty) {
      // Fallback for legacy/mocked blocks that don't carry a shiftCode —
      // open the view screen with whatever the timeline block had.
      _pushViewShiftFromBlock(context, state, tappedShift);
      return;
    }

    try {
      final shift = await schedulingCubit.getShiftByCode(shiftCode);
      if (!context.mounted) return;
      final classroomName = shift.classroomName.trim().isNotEmpty
          ? shift.classroomName
          : (state.classroomNamesByCode[shift.classroomCode] ??
              shift.classroomCode);
      final staffName = shift.staffName.trim().isNotEmpty
          ? shift.staffName
          : (state.selectedStaff?.name ?? '');
      // Await the View screen so we can refresh the scheduling cubit when
      // the user returns from a successful edit / delete. The View screen
      // is popped programmatically from inside [_openEditShiftScreen] /
      // [_deleteStaffShift] which propagates `true` back here.
      final isReadOnly = state.isStaffPersonaScope;
      final mutated = await context.push<bool>(
        SchedulingRoutes.viewShift,
        extra: ViewShiftRouteArgs(
          date: shift.shiftDate,
          staff: staffName,
          classroom: classroomName,
          shiftStart: shift.startTime,
          shiftEnd: shift.endTime,
          breakStart: shift.breakStartTime,
          breakEnd: shift.breakEndTime,
          note: shift.notes,
          status: shift.isPublished
              ? ShiftStatus.published
              : ShiftStatus.draft,
          isRecurring: shift.isRecurring,
          readOnly: isReadOnly,
          onEditThis: isReadOnly
              ? null
              : () => _openEditShiftScreen(
                    context,
                    state,
                    shiftCode,
                    EditShiftMode.thisShift,
                  ),
          onEditSeries: isReadOnly
              ? null
              : () => _openEditShiftScreen(
                    context,
                    state,
                    shiftCode,
                    EditShiftMode.entireSeries,
                  ),
          onDeleteThis: isReadOnly
              ? null
              : () => _deleteStaffShift(
                    context,
                    shiftCode: shift.shiftCode,
                    staffCode: shift.staffCode,
                    isSeries: false,
                  ),
          onDeleteSeries: isReadOnly
              ? null
              : () => _deleteStaffShift(
                    context,
                    shiftCode: shift.shiftCode,
                    staffCode: shift.staffCode,
                    seriesCode: shift.seriesCode,
                    isSeries: true,
                  ),
        ),
      );
      if (mutated == true) {
        await schedulingCubit.refresh();
      }
    } catch (e) {
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  /// Same prefetch pattern as [_openViewShiftScreen] — fires
  /// `GET /api/v1/staff-shifts/{shiftCode}` so the Edit form lands with the
  /// freshest server-side data and not whatever was on screen in View.
  ///
  /// Returns `true` when the user saved their edit; the View screen pops
  /// itself in response so the source screen (this one) receives the
  /// mutation signal and refreshes.
  Future<bool> _openEditShiftScreen(
    BuildContext context,
    StaffSchedulingState state,
    String shiftCode,
    EditShiftMode mode,
  ) async {
    // Capture cubits BEFORE awaiting — once the GET resolves the original
    // BuildContext may be on a different element. EditShiftScreen needs both
    // the classroom dropdown source and the staff list (for availability
    // checks) provided above it via MultiBlocProvider.
    final classroomCubit = context.read<ClassroomCubit>();
    final schedulingStaffListCubit = context.read<SchedulingStaffListCubit>();
    final schedulingCubit = context.read<StaffSchedulingCubit>();
    try {
      final shift = await schedulingCubit.getShiftByCode(shiftCode);
      if (!context.mounted) return false;
      final classroomName = shift.classroomName.trim().isNotEmpty
          ? shift.classroomName
          : (state.classroomNamesByCode[shift.classroomCode] ??
              shift.classroomCode);
      final staffName = shift.staffName.trim().isNotEmpty
          ? shift.staffName
          : (state.selectedStaff?.name ?? '');
      // Backend stores `seriesRecurrenceDays` as 0-indexed (Mon=0..Sun=6) on
      // new shifts and 1-indexed (Mon=1..Sun=7) on some legacy ones, so the
      // numeric index alone isn't trustworthy. The one thing we always know
      // for sure is the shift's actual weekday from `shiftDate`. Use that as
      // the anchor: decode the recurrence list, and if it doesn't include
      // the shift's actual day, fall back to just the actual day (covers
      // single-occurrence series with a mis-encoded recurrence value).
      const weekdayName = <int, String>{
        DateTime.monday: 'Monday',
        DateTime.tuesday: 'Tuesday',
        DateTime.wednesday: 'Wednesday',
        DateTime.thursday: 'Thursday',
        DateTime.friday: 'Friday',
        DateTime.saturday: 'Saturday',
        DateTime.sunday: 'Sunday',
      };
      const dayNameByIndex = <int, String>{
        0: 'Monday',
        1: 'Tuesday',
        2: 'Wednesday',
        3: 'Thursday',
        4: 'Friday',
        5: 'Saturday',
        6: 'Sunday',
        7: 'Sunday',
      };
      final actualDay = weekdayName[shift.shiftDate.weekday];
      final decodedDays = <String>{
        for (final d in shift.seriesRecurrenceDays)
          if (dayNameByIndex[d] != null) dayNameByIndex[d]!,
      };
      final selectedDays = (actualDay != null && decodedDays.contains(actualDay))
          ? decodedDays
          : <String>{if (actualDay != null) actualDay};
      final saved = await context.push<bool>(
        SchedulingRoutes.editShift,
        extra: EditShiftRouteArgs(
          schedulingStaffListCubit: schedulingStaffListCubit,
          classroomCubit: classroomCubit,
          mode: mode,
          shiftCode: shift.shiftCode,
          seriesCode: shift.seriesCode,
          staffCode: shift.staffCode,
          classroomCode: shift.classroomCode,
          initialDate: shift.shiftDate,
          staff: staffName,
          classroom: classroomName,
          shiftStart: shift.startTime,
          shiftEnd: shift.endTime,
          breakStart: shift.breakStartTime,
          breakEnd: shift.breakEndTime,
          note: shift.notes,
          status: shift.isPublished
              ? ShiftStatus.published
              : ShiftStatus.draft,
          isPublished: shift.isPublished,
          selectedDays: selectedDays,
          // Fall back to the shift's own date when the series-end is
          // missing — covers single-occurrence series where the backend
          // omits seriesEndDate but the form still needs a value.
          untilDate: shift.seriesEndDate ?? shift.shiftDate,
        ),
      );
      // EditShiftScreen returns `true` from `_onSave` after the PUT succeeds.
      // Propagate that to the View screen so it can pop itself — this in turn
      // resolves the await in [_openViewShiftScreen] with `true`, which
      // triggers the staff-scheduling refresh and lands the user back on
      // this screen.
      return saved == true;
    } catch (e) {
      if (!context.mounted) return false;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  /// Fires the appropriate DELETE — `/api/v1/staff-shifts/{shiftCode}` for a
  /// single occurrence or `/api/v1/staff-shifts/series/{seriesCode}` for the
  /// whole series. Returns `true` on success; the View screen pops itself in
  /// response, which resolves the await in [_openViewShiftScreen] and
  /// triggers [StaffSchedulingCubit.refresh].
  Future<bool> _deleteStaffShift(
    BuildContext context, {
    required String shiftCode,
    required String staffCode,
    String? seriesCode,
    required bool isSeries,
  }) async {
    final cubit = context.read<StaffSchedulingCubit>();
    try {
      if (isSeries) {
        final code = (seriesCode ?? '').trim();
        if (code.isEmpty) {
          throw Exception('Missing series code');
        }
        await cubit.deleteShiftSeries(seriesCode: code, staffCode: staffCode);
      } else {
        await cubit.deleteShift(shiftCode: shiftCode, staffCode: staffCode);
      }
      if (!context.mounted) return true;
      CoreUtils.showTopSnackBar(
        context: context,
        message: isSeries
            ? 'Shift series deleted successfully'
            : 'Shift deleted successfully',
        isSuccess: true,
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
      return false;
    }
  }

  void _pushViewShiftFromBlock(
    BuildContext context,
    StaffSchedulingState state,
    Shift tappedShift,
  ) {
    final start = _parseClockTime(tappedShift.start);
    final end = _parseClockTime(tappedShift.end);
    if (start == null || end == null) return;

    TimeOfDay? breakStart;
    TimeOfDay? breakEnd;
    final shiftStartMin = start.hour * 60 + start.minute;
    final shiftEndMin = end.hour * 60 + end.minute;
    for (final block in state.shiftSummary.blocks) {
      if (!block.isBreak) continue;
      final bs = _parseClockTime(block.start);
      final be = _parseClockTime(block.end);
      if (bs == null || be == null) continue;
      final bsMin = bs.hour * 60 + bs.minute;
      final beMin = be.hour * 60 + be.minute;
      if (bsMin >= shiftStartMin && beMin <= shiftEndMin) {
        breakStart = bs;
        breakEnd = be;
        break;
      }
    }

    context.push<void>(
      SchedulingRoutes.viewShift,
      extra: ViewShiftRouteArgs(
        date: state.selectedDay,
        staff: state.selectedStaff?.name ?? '',
        classroom: tappedShift.room,
        shiftStart: start,
        shiftEnd: end,
        breakStart: breakStart,
        breakEnd: breakEnd,
        readOnly: state.isStaffPersonaScope,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StaffSchedulingCubit, StaffSchedulingState>(
      // Re-attempt the deep-link staff selection as the roster streams in.
      listener: (context, state) => _applyDeepLink(),
      builder: (context, state) {
        final cubit = context.read<StaffSchedulingCubit>();
        final staff = state.selectedStaff;
        final dayColumnLabel =
            DateFormat('EEE, MMM d').format(state.selectedDay);
        final calendarShifts = _shiftsFromSummary(state.shiftSummary);
        // Kick off the bulk sign-in status fetch whenever the roster shape
        // changes — the method itself short-circuits when the staff-code set
        // is unchanged.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          // ignore: discarded_futures
          cubit.refreshSignInStatusForRoster(state.staffList);
        });
        // Keep the shimmer up until the very first load attempt has settled,
        // OR while the staff list is being (re)loaded with nothing to show.
        // This avoids briefly flashing the "Select a staff" empty state before
        // `loadInitial()` flips the loading flag on.
        final isInitialLoad = !state.hasAttemptedInitialLoad ||
            (state.isLoadingStaff && state.staffList.isEmpty);
        final isProfileLoading = state.isLoadingStaff ||
            state.isLoadingShifts ||
            state.isLoadingSchoolHours;

        return GlobalScaffold(
          hasBackButton: false,
          body: CustomRefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Staff Schedule',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DateHeaderRow(
                    selectedDay: state.selectedDay,
                    staff: state.staffList,
                    initialPublishStaffCodes:
                        state.selectedStaffCode == null
                            ? const <String>[]
                            : <String>[state.selectedStaffCode!],
                    onDatePicked: cubit.selectDay,
                    onAddTap: () {
                      // ignore: discarded_futures
                      _openAddShiftScreen(context, state);
                    },
                    onPublished: cubit.refresh,
                    showActions: !state.isStaffPersonaScope,
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        color: AppColors.errorColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0x19162831)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: StaffSchedulingStaffDropdown(
                      staff: state.staffList,
                      selectedStaffCode: state.selectedStaffCode,
                      // Keep the dropdown visible during loads — the body shimmer
                      // is the loading indicator; a circular loader here is
                      // redundant (and hides the dropdown).
                      isLoading: false,
                      onSelected: cubit.selectStaffByCode,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isInitialLoad)
                    const StaffSchedulingShimmer()
                  else if (staff != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StaffProfileHeader(
                            staffCode: staff.code,
                            staffName: staff.name,
                            designation: formatDesignationForDisplay(
                              staff.designation,
                            ),
                            classroom:
                                state.classroomResolver.resolveForStaff(staff),
                            profilePhotoAssetCode: staff.profilePhotoAssetCode,
                            status: staff.status,
                            attendanceStatus:
                                state.staffSignInStatusByCode[staff.code],
                          ),
                          const SizedBox(height: 16),
                          if (isProfileLoading)
                            const StaffShiftsBodyShimmer()
                          else ...[
                            ShiftHoursTile(
                              bgColor: const Color.fromRGBO(255, 250, 234, 1),
                              label: 'Available Hours',
                              hours: formatSchedulingHours(
                                state.shiftSummary.availableHours,
                              ),
                              icon: MediaRes.availableHoursIcon,
                            ),
                            const SizedBox(height: 16),
                            ShiftHoursTile(
                              bgColor: const Color.fromRGBO(234, 255, 250, 1),
                              label: 'Scheduled Hours',
                              hours: formatSchedulingHours(
                                state.shiftSummary.scheduledHours,
                              ),
                              icon: MediaRes.scheduledHoursIcon,
                            ),
                            const SizedBox(height: 16),
                            ShiftHoursTile(
                              bgColor: const Color.fromRGBO(22, 40, 49, 0.01),
                              label: 'Unscheduled Hours',
                              hours: formatSchedulingHours(
                                state.shiftSummary.unscheduledHours,
                              ),
                              icon: MediaRes.unScheduledHoursIcon,
                            ),
                            const SizedBox(height: 20),
                            if (!state.hasSchoolHoursForDay)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No school hours configured for this day.',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              StaffDayScheduleCalendar(
                                key: ValueKey(
                                  '${staff.code}_${dayColumnLabel}_'
                                  '${state.schoolStartTime}_${state.schoolEndTime}_'
                                  '${state.classroomNamesByCode.length}_'
                                  '${widget.highlightShiftCode}',
                                ),
                                dayColumnLabel: dayColumnLabel,
                                schoolStartTime: state.schoolStartTime!,
                                schoolEndTime: state.schoolEndTime!,
                                classroomResolver: state.classroomResolver,
                                highlightShiftCode: widget.highlightShiftCode,
                                dailyRoomSchedule:
                                    DailyShifts(shifts: calendarShifts),
                                onShiftTap: (shift) => _openViewShiftScreen(
                                  context,
                                  state,
                                  shift,
                                ),
                                onEmptySlotTap: state.isStaffPersonaScope
                                    ? null
                                    : (time) => _openAddShiftForEmptySlot(
                                          context,
                                          state,
                                          time,
                                        ),
                              ),
                          ],
                        ],
                      ),
                    )
                  else if (!state.isLoadingStaff)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Select a staff member to view their schedule.',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateHeaderRow extends StatelessWidget {
  const _DateHeaderRow({
    required this.selectedDay,
    required this.onDatePicked,
    required this.onAddTap,
    this.staff = const <StaffMember>[],
    this.initialPublishStaffCodes = const <String>[],
    this.onPublished,
    this.showActions = true,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDatePicked;
  final VoidCallback onAddTap;
  final List<StaffMember> staff;
  final List<String> initialPublishStaffCodes;

  /// Fired after a successful publish so the caller can refresh the
  /// scheduling view — published shifts flip their isPublished flag and the
  /// stale UI would otherwise need a manual pull-to-refresh.
  final Future<void> Function()? onPublished;

  /// When false (STAFF persona), hides the Add and Publish buttons — staff can
  /// view but not mutate their own schedule.
  final bool showActions;

  Future<void> _openPublishScreen(BuildContext context) async {
    final result = await context.push<PublishShiftsResult>(
      SchedulingRoutes.publishShifts,
      extra: PublishShiftsRouteArgs(
        staff: staff,
        dateRangeStart: selectedDay,
        initialStaffCodes: initialPublishStaffCodes,
        initialUntilDate: selectedDay,
      ),
    );
    if (result != null) {
      await onPublished?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: CustomDateTimeField(
            key: ValueKey(selectedDay.toIso8601String()),
            hasLabel: false,
            fetchInitialTime: false,
            initialDate: selectedDay,
            onDateSelected: onDatePicked,
          ),
        ),
        if (showActions) ...[
          const SizedBox(width: 8),
          GradientAddButton(onTap: onAddTap),
          const SizedBox(width: 8),
          _GradientPublishButton(onTap: () => _openPublishScreen(context)),
        ],
      ],
    );
  }
}

class _GradientPublishButton extends StatelessWidget {
  const _GradientPublishButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const height = 40.0;
    const borderRadius = 8.0;

    final child = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.buildPrimaryGradient(),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'Publish',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (onTap == null) return child;

    return GestureDetector(onTap: onTap, child: child);
  }
}

class _StaffProfileHeader extends StatelessWidget {
  const _StaffProfileHeader({
    required this.staffCode,
    required this.staffName,
    required this.designation,
    required this.classroom,
    this.profilePhotoAssetCode,
    this.status,
    this.attendanceStatus,
  });

  final String staffCode;
  final String staffName;
  final String designation;
  final String classroom;
  final String? profilePhotoAssetCode;

  /// Employment status from `/staff/staff` (`ACTIVE`, `UPCOMING`, …). Forwarded
  /// to [DocumentImageWidget] which paints a mustard dot for `UPCOMING`; the
  /// [DocumentImageWidget.statusColor] fallback keeps the legacy green dot for
  /// every other status.
  final String? status;

  /// Today's sign-in status (SIGNED_IN / ABSENT / NOT_MARKED …) from the bulk
  /// POST `/staff-attendance/sign-in/status`. SIGNED_IN paints green, ABSENT
  /// paints red; NOT_MARKED (or any other status) renders no dot at all —
  /// UPCOMING-employment staff still get the mustard dot via
  /// [DocumentImageWidget.staffEmploymentStatus].
  final String? attendanceStatus;

  @override
  Widget build(BuildContext context) {
    final attendanceDot = schedulingAttendanceDotColor(attendanceStatus);
    final attendanceTooltip = schedulingAttendanceDotTooltip(attendanceStatus);
    return Row(
      children: [
        DocumentImageWidget(
          fileUuid: staffCode,
          name: staffName,
          mediaAssetCode: profilePhotoAssetCode,
          staffCode: staffCode,
          staffEmploymentStatus: status,
          statusColor: attendanceDot,
          statusTooltip: attendanceTooltip,
          size: 80,
          fontSize: 28,
          disableProfileLookupFallback: profilePhotoAssetCode != null &&
              profilePhotoAssetCode!.isNotEmpty,
          disableAttendanceStatusLookup: true,
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staffName,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (designation.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  designation,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                ),
              ],
              if (classroom.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  classroom,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
