import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/api_error_handler.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/scheduling/entities/staff_shift.dart'
    as sched;
import '../../../../domain/features/scheduling/entities/staff_shift_hours_entry.dart';
import '../../../../domain/features/scheduling/usecases/get_school_staff_shifts_usecase.dart';
import '../../../../domain/features/scheduling/usecases/get_staff_shift_hours_range_usecase.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/entities/staff_shift.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../utils/classroom_name_resolver.dart';
import '../utils/school_hours_resolver.dart';
import '../utils/scheduling_school_time.dart';
import '../utils/staff_hours_aggregator.dart';
import 'scheduling_staff_list_cubit.dart';

part 'staff_scheduling_state.dart';

class StaffSchedulingCubit extends Cubit<StaffSchedulingState> {
  StaffSchedulingCubit({
    required SchedulingStaffListCubit schedulingStaffListCubit,
    required GetSchoolStaffShiftsUseCase getSchoolStaffShiftsUseCase,
    required GetStaffShiftHoursRangeUseCase getStaffShiftHoursRangeUseCase,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StaffRepository staffRepository,
    required StorageService storageService,
  })  : _schedulingStaffListCubit = schedulingStaffListCubit,
        _getSchoolStaffShiftsUseCase = getSchoolStaffShiftsUseCase,
        _getStaffShiftHoursRangeUseCase = getStaffShiftHoursRangeUseCase,
        _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
        _staffRepository = staffRepository,
        _storageService = storageService,
        super(StaffSchedulingState.initial());

  final SchedulingStaffListCubit _schedulingStaffListCubit;
  // Uses the school-wide non-paginated `/api/v1/staff-shifts` endpoint and
  // filters by the selected staff + day client-side. Mirrors what the
  // Classroom Schedule screen does so we hit the same endpoint everywhere.
  final GetSchoolStaffShiftsUseCase _getSchoolStaffShiftsUseCase;
  final GetStaffShiftHoursRangeUseCase _getStaffShiftHoursRangeUseCase;
  final GetActiveClassroomsUseCase _getActiveClassroomsUseCase;
  final StaffRepository _staffRepository;
  final StorageService _storageService;

  String? _schoolCode;
  String? _organizationCode;
  SchoolHoursResolver? _schoolHoursResolver;

  /// When true, the screen only shows the logged-in staff member (no roster).
  /// Resolved from active-school role + cached staffCode in storage.
  bool _isStaffPersonaScope = false;
  String? _loggedInStaffCode;

  bool get isStaffPersonaScope => _isStaffPersonaScope;

  Future<String> _resolveSchoolCode() async {
    if (_schoolCode != null) return _schoolCode!;
    _schoolCode = await _storageService.getString(StorageKeys.schoolCode) ?? '';
    return _schoolCode!;
  }

  Future<String> _resolveOrganizationCode() async {
    if (_organizationCode != null) return _organizationCode!;
    _organizationCode =
        await _storageService.getString(StorageKeys.organizationCode) ?? '';
    return _organizationCode!;
  }

  /// Caller-driven persona scope. The screen reads [RoleCubit.isStaff] (the
  /// single source of truth used across the app) and feeds it in here, plus
  /// the logged-in user's `staffCode`. Re-filters the roster + re-emits state
  /// whenever the scope flips so the UI reacts even if scope is set after the
  /// initial load.
  Future<void> applyPersonaScope({
    required bool isStaffPersona,
    String? loggedInStaffCode,
  }) async {
    final code = (loggedInStaffCode ?? '').trim();
    final nextLoggedInStaffCode = code.isNotEmpty ? code : null;
    final scopeChanged = _isStaffPersonaScope != isStaffPersona ||
        _loggedInStaffCode != nextLoggedInStaffCode;

    _isStaffPersonaScope = isStaffPersona;
    _loggedInStaffCode = nextLoggedInStaffCode;

    if (!scopeChanged || isClosed) return;

    if (state.staffList.isEmpty) {
      // Nothing loaded yet — just publish the flag so the UI hides the right
      // controls; [_loadAllStaff] will apply the filter on the next load.
      emit(state.copyWith(isStaffPersonaScope: _isStaffPersonaScope));
      return;
    }

    // Roster already loaded under a different scope (e.g. cubit is a singleton
    // and persona resolved after the route's eager loadIfNeeded). Re-derive
    // the visible list synchronously so the dropdown updates without a refetch.
    final allStaff = _schedulingStaffListCubit.state.staff;
    List<StaffMember> visibleStaff = allStaff;
    if (_isStaffPersonaScope) {
      visibleStaff = (_loggedInStaffCode == null)
          ? const <StaffMember>[]
          : allStaff
              .where((s) => s.code == _loggedInStaffCode)
              .toList(growable: false);
    }

    final previousCode = state.selectedStaffCode;
    String? nextCode = previousCode;
    if (_isStaffPersonaScope) {
      nextCode = visibleStaff.isNotEmpty ? visibleStaff.first.code : null;
    } else if (nextCode != null &&
        !visibleStaff.any((s) => s.code == nextCode)) {
      nextCode = visibleStaff.isNotEmpty ? visibleStaff.first.code : null;
    }

    emit(state.copyWith(
      isStaffPersonaScope: _isStaffPersonaScope,
      staffList: visibleStaff,
      selectedStaffCode: nextCode,
      clearSelectedStaffCode: nextCode == null,
    ));

    if (nextCode != null && nextCode != previousCode) {
      await _loadShiftsForSelection();
    }
  }

  /// Called on every route entry. First call runs the full visible
  /// load (shimmer); subsequent entries do a silent background refresh —
  /// the previously-loaded staff / school hours / classrooms stay on screen
  /// and the new data swaps in once it arrives.
  Future<void> loadIfNeeded() async {
    if (!state.hasAttemptedInitialLoad) {
      await loadInitial();
      return;
    }
    await _silentRefresh();
  }

  /// Public entry point for the screen-level cache-gate listener — same
  /// behavior as [_silentRefresh] (staff API only, no loader, no rebuild).
  Future<void> silentRefreshStaff() => _silentRefresh();

  /// Re-pulls ONLY the no-pagination staff roster
  /// (`/staff/staff?...status=ACTIVE&status=UPCOMING`) into the singleton
  /// cache. Does NOT emit on this cubit — so the screen's BlocBuilder
  /// doesn't rebuild and the user sees no refresh. The fresh roster is
  /// picked up the next time `_loadAllStaff` runs (e.g. pull-to-refresh
  /// or a future entry that genuinely needs a reload).
  Future<void> _silentRefresh() async {
    try {
      await _schedulingStaffListCubit.load(force: true);
    } catch (_) {
      // Silent: ignore — the cached state stays on screen.
    }
  }

  Future<void> loadInitial() async {
    try {
      await Future.wait([
        _loadSchoolHours(),
        _loadClassroomNames(),
      ]);
      await _loadAllStaff(selectFirst: true);
    } finally {
      if (!isClosed) {
        emit(state.copyWith(hasAttemptedInitialLoad: true));
      }
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      _loadSchoolHours(),
      _loadClassroomNames(),
    ]);
    await _loadAllStaff(selectFirst: false, force: true);
    await _loadShiftsForSelection();
  }


  Future<void> _loadClassroomNames() async {
    try {
      final schoolCode = await _resolveSchoolCode();
      if (schoolCode.isEmpty) return;

      final classrooms = await _getActiveClassroomsUseCase(
        schoolCode: schoolCode,
        onlyTypeClassroom: false,
      );
      final map = <String, String>{};
      for (final c in classrooms) {
        final code = c.code.trim();
        if (code.isEmpty) continue;
        final name = c.name.trim();
        map[code] = name.isNotEmpty ? name : code;
      }
      if (isClosed) return;
      emit(state.copyWith(classroomNamesByCode: map));
      _reapplyShiftSummaryLabels();
    } catch (_) {
      // Non-fatal: fall back to staff API / codes when lookup fails.
    }
  }

  void _mergeClassroomNamesFromStaff(List<StaffMember> staff) {
    if (staff.isEmpty) return;
    final merged = Map<String, String>.from(state.classroomNamesByCode);
    for (final member in staff) {
      final primaryCode = member.primaryClassroomCode.trim();
      final primaryName = member.primaryClassroomName.trim();
      if (primaryCode.isNotEmpty && primaryName.isNotEmpty) {
        merged[primaryCode] = primaryName;
      }
      member.allowedClassroomNameByCode.forEach((code, name) {
        final c = code.trim();
        final n = name.trim();
        if (c.isNotEmpty && n.isNotEmpty) merged[c] = n;
      });
    }
    emit(state.copyWith(classroomNamesByCode: merged));
    _reapplyShiftSummaryLabels();
  }

  StaffShiftDaySummary _labelShiftSummary(
    StaffShiftDaySummary summary,
    StaffMember? staff,
  ) {
    final resolver = state.classroomResolver;
    final fallbackRoom =
        staff != null ? resolver.resolveForStaff(staff) : '';

    return StaffShiftDaySummary(
      availableHours: summary.availableHours,
      scheduledHours: summary.scheduledHours,
      unscheduledHours: summary.unscheduledHours,
      blocks: summary.blocks
          .map(
            (b) => StaffShiftTimelineBlock(
              room: b.isBreak
                  ? b.room
                  : (b.room.isNotEmpty
                      ? resolver.resolveShiftRoom(b.room)
                      : fallbackRoom),
              start: b.start,
              end: b.end,
              isBreak: b.isBreak,
              shiftCode: b.shiftCode,
            ),
          )
          .toList(),
    );
  }

  void _reapplyShiftSummaryLabels() {
    if (state.shiftSummary.blocks.isEmpty) return;
    final labeled = _labelShiftSummary(
      state.shiftSummary,
      state.selectedStaff,
    );
    emit(state.copyWith(shiftSummary: labeled));
  }

  Future<void> _loadSchoolHours({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(isLoadingSchoolHours: true, clearError: true));
    }

    try {
      final schoolCode = await _resolveSchoolCode();
      if (schoolCode.isEmpty) {
        emit(
          state.copyWith(
            isLoadingSchoolHours: false,
            clearSchoolHours: true,
            hasSchoolHoursForDay: false,
          ),
        );
        _applySchoolHoursForSelectedDay();
        return;
      }

      final days =
          await _staffRepository.getSchoolRegularSchedules(
        schoolCode: schoolCode,
      );
      _schoolHoursResolver = SchoolHoursResolver.fromDays(days);
      if (isClosed) return;

      emit(state.copyWith(isLoadingSchoolHours: false));
      _applySchoolHoursForSelectedDay();
    } catch (e) {
      if (isClosed) return;
      _schoolHoursResolver = null;
      emit(
        state.copyWith(
          isLoadingSchoolHours: false,
          clearSchoolHours: true,
          hasSchoolHoursForDay: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  void _applySchoolHoursForSelectedDay() {
    final resolver = _schoolHoursResolver;
    final hours = resolver?.hoursFor(state.selectedDay);

    if (hours == null) {
      emit(
        state.copyWith(
          clearSchoolHours: true,
          hasSchoolHoursForDay: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        schoolStartTime: hours.startTime,
        schoolEndTime: hours.endTime,
        hasSchoolHoursForDay: true,
      ),
    );
  }

  Future<void> _loadAllStaff({
    required bool selectFirst,
    bool force = false,
    bool silent = false,
  }) async {
    if (!silent) {
      emit(
        state.copyWith(
          isLoadingStaff: true,
          clearError: true,
        ),
      );
    }

    try {
      // Delegated to SchedulingStaffListCubit which calls the staff API once
      // with `status=ACTIVE&status=UPCOMING` and no pagination. Singleton —
      // returns cached data on repeat calls unless [force] is set.
      final allStaff =
          await _schedulingStaffListCubit.load(force: force);

      if (isClosed) return;

      final listError = _schedulingStaffListCubit.state.errorMessage;
      if (listError != null) {
        emit(
          state.copyWith(
            isLoadingStaff: false,
            errorMessage: listError,
          ),
        );
        return;
      }

      // STAFF persona only ever sees their own row — narrow the roster here so
      // the dropdown can't reveal coworkers and the rest of the cubit doesn't
      // need to special-case the persona.
      List<StaffMember> visibleStaff = allStaff;
      if (_isStaffPersonaScope) {
        final code = _loggedInStaffCode;
        visibleStaff = (code == null || code.isEmpty)
            ? const <StaffMember>[]
            : allStaff.where((s) => s.code == code).toList(growable: false);
      }

      String? nextCode = state.selectedStaffCode;
      if (_isStaffPersonaScope) {
        nextCode = visibleStaff.isNotEmpty ? visibleStaff.first.code : null;
      } else if (selectFirst && visibleStaff.isNotEmpty) {
        nextCode = visibleStaff.first.code;
      } else if (nextCode != null &&
          !visibleStaff.any((s) => s.code == nextCode)) {
        nextCode = visibleStaff.isNotEmpty ? visibleStaff.first.code : null;
      }

      emit(
        state.copyWith(
          staffList: visibleStaff,
          selectedStaffCode: nextCode,
          clearSelectedStaffCode: nextCode == null,
          isLoadingStaff: false,
          // Pre-flip so the inner body shimmer stays solid through the
          // handoff into _loadShiftsForSelection without a one-frame flash
          // of the actual (empty) summary tiles. Skip when silent so a
          // background refresh doesn't briefly hide the existing tiles.
          isLoadingShifts: (!silent && nextCode != null)
              ? true
              : state.isLoadingShifts,
        ),
      );

      _mergeClassroomNamesFromStaff(visibleStaff);

      if (nextCode != null) {
        await _loadShiftsForSelection(silent: silent);
      } else {
        emit(
          state.copyWith(
            shiftSummary: StaffShiftDaySummary.empty,
            isLoadingShifts: false,
          ),
        );
      }
    } catch (e) {
      if (isClosed) return;
      if (silent) return;
      emit(
        state.copyWith(
          isLoadingStaff: false,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  Future<void> _loadShiftsForSelection({bool silent = false}) async {
    final staffCode = state.selectedStaffCode;
    if (staffCode == null || staffCode.isEmpty) {
      emit(
        state.copyWith(
          shiftSummary: StaffShiftDaySummary.empty,
          isLoadingShifts: false,
        ),
      );
      return;
    }

    if (!silent) {
      emit(state.copyWith(isLoadingShifts: true, clearError: true));
    }

    try {
      final organizationCode = await _resolveOrganizationCode();
      final schoolCode = await _resolveSchoolCode();
      final staff = state.selectedStaff;
      final day = state.selectedDay;

      final shifts = await _getSchoolStaffShiftsUseCase(
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        dateFrom: day,
        dateTo: day,
        shiftStatus:
            _isStaffPersonaScope ? const <String>['PUBLISHED'] : const <String>[],
      );

      if (isClosed) return;

      final filtered = shifts
          .where((s) =>
              s.staffCode == staffCode && _isSameDay(s.shiftDate, day))
          .toList(growable: false);

      var totals = StaffHoursTotals.zero;
      try {
        final hourRows = await _getStaffShiftHoursRangeUseCase(
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          startDate: day,
          endDate: day,
          staffCodes: <String>[staffCode],
        );
        totals = StaffHoursAggregator.sumForStaffOnDay(
          entries: hourRows,
          staffCode: staffCode,
          day: day,
        );
      } catch (_) {
        totals = StaffHoursTotals.zero;
      }

      final raw = _buildSummaryFromShifts(filtered, totals: totals);
      final enriched = _labelShiftSummary(raw, staff);

      emit(
        state.copyWith(
          shiftSummary: enriched,
          isLoadingShifts: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      if (silent) return;
      emit(
        state.copyWith(
          isLoadingShifts: false,
          shiftSummary: StaffShiftDaySummary.empty,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }

  void selectStaffByName(String? name) {
    if (name == null || name.isEmpty || name == 'Select Staff') {
      emit(
        state.copyWith(
          clearSelectedStaffCode: true,
          shiftSummary: StaffShiftDaySummary.empty,
        ),
      );
      return;
    }

    StaffMember? match;
    for (final s in state.staffList) {
      if (s.name == name) {
        match = s;
        break;
      }
    }
    if (match == null) return;

    emit(state.copyWith(selectedStaffCode: match.code));
    _loadShiftsForSelection();
  }

  /// Selects a staff member by code (notification deep-link). No-op if the code
  /// is empty, already selected, or not present in the loaded roster (the screen
  /// retries once the roster finishes loading).
  void selectStaffByCode(String? code) {
    final wanted = (code ?? '').trim();
    if (wanted.isEmpty || wanted == state.selectedStaffCode) return;
    final exists = state.staffList.any((s) => s.code == wanted);
    if (!exists) return;
    emit(state.copyWith(selectedStaffCode: wanted));
    _loadShiftsForSelection();
  }

  void shiftSelectedDay(int deltaDays) {
    selectDay(state.selectedDay.add(Duration(days: deltaDays)));
  }

  void selectDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    emit(state.copyWith(selectedDay: normalized));
    _applySchoolHoursForSelectedDay();
    _loadShiftsForSelection();
  }

  /// Aggregates a list of single-staff single-day shifts (already filtered)
  /// into the [StaffShiftDaySummary] shape the screen consumes. Mirrors what
  /// `StaffShiftMapper.toDaySummary` does, but for the scheduling-domain
  /// [sched.StaffShift] entity returned by the school-wide endpoint.
  StaffShiftDaySummary _buildSummaryFromShifts(
    List<sched.StaffShift> shifts, {
    required StaffHoursTotals totals,
  }) {
    if (shifts.isEmpty && totals == StaffHoursTotals.zero) {
      return StaffShiftDaySummary.empty;
    }

    final blocks = <StaffShiftTimelineBlock>[];

    for (final s in shifts) {
      blocks.add(
        StaffShiftTimelineBlock(
          // Store the raw classroomCode here — [_labelShiftSummary] resolves
          // it to a display name via [classroomResolver].
          room: s.classroomCode.trim(),
          start: _formatTimeOfDay(s.startTime),
          end: _formatTimeOfDay(s.endTime),
          shiftCode: s.shiftCode,
        ),
      );
      final bs = s.breakStartTime;
      final be = s.breakEndTime;
      if (bs != null && be != null) {
        blocks.add(
          StaffShiftTimelineBlock(
            room: 'Lunch Break',
            start: _formatTimeOfDay(bs),
            end: _formatTimeOfDay(be),
            isBreak: true,
            shiftCode: s.shiftCode,
          ),
        );
      }
    }

    return StaffShiftDaySummary(
      availableHours: totals.availableHours,
      scheduledHours: totals.scheduledHours,
      unscheduledHours: totals.unscheduledHours,
      blocks: blocks,
    );
  }

  /// Formats a [TimeOfDay] as `hh:mm:ss a` (e.g. `09:00:00 AM`) — the format
  /// [StaffDayScheduleCalendar] parses. Seconds are always `00` since
  /// [TimeOfDay] doesn't carry them.
  static String _formatTimeOfDay(TimeOfDay t) {
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final h12 = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final mm = t.minute.toString().padLeft(2, '0');
    return '${h12.toString().padLeft(2, '0')}:$mm:00 $period';
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
