import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import '../../../../domain/features/scheduling/entities/staff_shift.dart'
    as sched;
import 'package:wowcare/domain/features/scheduling/entities/staff_shift_hours_entry.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/bootstrap_scheduling_school_timezone_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/delete_staff_shift_series_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/delete_staff_shift_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_school_staff_shifts_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shift_by_code_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shift_hours_range_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/entities/staff_shift.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/resolve_logged_in_staff_code_usecase.dart';
import 'package:wowcare/domain/features/classroom/services/classroom_name_resolver.dart';
import 'package:wowcare/domain/features/scheduling/services/school_hours_resolver.dart';
import 'scheduling_school_scope_mixin.dart';
import 'package:wowcare/domain/features/scheduling/services/scheduling_school_time.dart';
import 'package:wowcare/domain/features/scheduling/services/staff_hours_aggregator.dart';
import 'scheduling_staff_list_cubit.dart';

part 'staff_scheduling_state.dart';

class StaffSchedulingCubit extends Cubit<StaffSchedulingState>
    with SchedulingSchoolScopeMixin {
  StaffSchedulingCubit({
    required SchedulingStaffListCubit schedulingStaffListCubit,
    required GetSchoolStaffShiftsUseCase getSchoolStaffShiftsUseCase,
    required GetStaffShiftHoursRangeUseCase getStaffShiftHoursRangeUseCase,
    required GetActiveClassroomsUseCase getActiveClassroomsUseCase,
    required StaffRepository staffRepository,
    required StorageService storageService,
    required GetStaffTodaySignInStatusMapUseCase
        getStaffTodaySignInStatusMapUseCase,
    required GetStaffShiftByCodeUseCase getStaffShiftByCodeUseCase,
    required DeleteStaffShiftUseCase deleteStaffShiftUseCase,
    required DeleteStaffShiftSeriesUseCase deleteStaffShiftSeriesUseCase,
    required BootstrapSchedulingSchoolTimezoneUseCase
        bootstrapSchedulingSchoolTimezoneUseCase,
  }) : _schedulingStaffListCubit = schedulingStaffListCubit,
       _getSchoolStaffShiftsUseCase = getSchoolStaffShiftsUseCase,
       _getStaffShiftHoursRangeUseCase = getStaffShiftHoursRangeUseCase,
       _getActiveClassroomsUseCase = getActiveClassroomsUseCase,
       _staffRepository = staffRepository,
       _storageService = storageService,
       _getStaffTodaySignInStatusMapUseCase =
           getStaffTodaySignInStatusMapUseCase,
       _getStaffShiftByCodeUseCase = getStaffShiftByCodeUseCase,
       _deleteStaffShiftUseCase = deleteStaffShiftUseCase,
       _deleteStaffShiftSeriesUseCase = deleteStaffShiftSeriesUseCase,
       _bootstrapSchedulingSchoolTimezoneUseCase =
           bootstrapSchedulingSchoolTimezoneUseCase,
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
  final GetStaffTodaySignInStatusMapUseCase
      _getStaffTodaySignInStatusMapUseCase;
  final GetStaffShiftByCodeUseCase _getStaffShiftByCodeUseCase;
  final DeleteStaffShiftUseCase _deleteStaffShiftUseCase;
  final DeleteStaffShiftSeriesUseCase _deleteStaffShiftSeriesUseCase;
  final BootstrapSchedulingSchoolTimezoneUseCase
      _bootstrapSchedulingSchoolTimezoneUseCase;

  Future<String> bootstrapSchoolTimezone() =>
      _bootstrapSchedulingSchoolTimezoneUseCase();

  /// Single-shift detail lookup for the View/Edit shift screens — kept on
  /// the cubit (rather than resolved via serviceLocator in the view layer)
  /// so presentation only ever talks to its cubit.
  Future<sched.StaffShift> getShiftByCode(String shiftCode) =>
      _getStaffShiftByCodeUseCase(shiftCode);

  Future<void> deleteShift({
    required String shiftCode,
    String? staffCode,
  }) =>
      _deleteStaffShiftUseCase(shiftCode: shiftCode, staffCode: staffCode);

  Future<void> deleteShiftSeries({
    required String seriesCode,
    String? staffCode,
  }) =>
      _deleteStaffShiftSeriesUseCase(
        seriesCode: seriesCode,
        staffCode: staffCode,
      );

  /// Tracks the most recent set of staff codes requested via
  /// [refreshSignInStatusForRoster] so an unchanged roster doesn't refire
  /// the bulk POST on every rebuild.
  Set<String> _lastRequestedSignInStatusCodes = const <String>{};

  @override
  StorageService get storageService => _storageService;

  SchoolHoursResolver? _schoolHoursResolver;

  /// When true, the screen only shows the logged-in staff member (no roster).
  /// Resolved from active-school role + cached staffCode in storage.
  bool _isStaffPersonaScope = false;

  /// The logged-in user's own `staffCode`, resolved once per cubit lifetime.
  /// Used for two things: narrowing the roster under a STAFF persona, and —
  /// for every persona — picking the default dropdown selection so the screen
  /// opens on the logged-in user's own schedule rather than whoever happens to
  /// sort first in the roster. Null when the user has no staff mapping in the
  /// active org/school (e.g. a guardian, or an admin without a staff record).
  String? _loggedInStaffCode;
  bool _hasResolvedLoggedInStaffCode = false;

  late final ResolveLoggedInStaffCodeUseCase _resolveLoggedInStaffCodeUseCase =
      ResolveLoggedInStaffCodeUseCase(_storageService, _staffRepository);

  bool get isStaffPersonaScope => _isStaffPersonaScope;

  /// Resolves (and memoises) the logged-in user's `staffCode`. Prefers the
  /// validated storage cache and falls back to `/api/v1/staff/code`, so a
  /// session that hasn't visited an attendance screen yet still gets a code.
  /// Never throws — an unresolved code just means "no preferred default".
  Future<String?> _ensureLoggedInStaffCode() async {
    if (_hasResolvedLoggedInStaffCode) return _loggedInStaffCode;
    final resolved = (await _resolveLoggedInStaffCodeUseCase() ?? '').trim();
    _hasResolvedLoggedInStaffCode = true;
    _loggedInStaffCode = resolved.isNotEmpty ? resolved : null;
    return _loggedInStaffCode;
  }

  /// The staff row the screen should land on: the logged-in user's own row
  /// when they are in [visibleStaff], otherwise the first row (previous
  /// behavior). Returns null for an empty roster.
  String? _defaultStaffCodeFor(List<StaffMember> visibleStaff) {
    if (visibleStaff.isEmpty) return null;
    final own = _loggedInStaffCode;
    if (own != null && visibleStaff.any((s) => s.code == own)) return own;
    return visibleStaff.first.code;
  }

  /// Caller-driven persona scope. The screen reads [RoleCubit.isStaff] (the
  /// single source of truth used across the app) and feeds it in here; the
  /// logged-in user's `staffCode` is resolved from storage internally.
  /// Re-filters the roster + re-emits state whenever the scope flips so the
  /// UI reacts even if scope is set after the initial load.
  Future<void> applyPersonaScope({required bool isStaffPersona}) async {
    // Resolved for every persona (not just STAFF) — an admin's own staffCode
    // is what makes their own row the default dropdown selection.
    await _ensureLoggedInStaffCode();
    final scopeChanged = _isStaffPersonaScope != isStaffPersona;

    _isStaffPersonaScope = isStaffPersona;

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
    } else if (nextCode == null ||
        !visibleStaff.any((s) => s.code == nextCode)) {
      nextCode = _defaultStaffCodeFor(visibleStaff);
    }

    emit(
      state.copyWith(
        isStaffPersonaScope: _isStaffPersonaScope,
        staffList: visibleStaff,
        selectedStaffCode: nextCode,
        clearSelectedStaffCode: nextCode == null,
      ),
    );

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
      await Future.wait([_loadSchoolHours(), _loadClassroomNames()]);
      await _loadAllStaff(selectFirst: true);
    } finally {
      if (!isClosed) {
        emit(state.copyWith(hasAttemptedInitialLoad: true));
      }
    }
  }

  Future<void> refresh() async {
    await Future.wait([_loadSchoolHours(), _loadClassroomNames()]);
    await _loadAllStaff(selectFirst: false, force: true);
    await _loadShiftsForSelection();
  }

  Future<void> _loadClassroomNames() async {
    try {
      final schoolCode = await resolveSchoolCode();
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
    final fallbackRoom = staff != null ? resolver.resolveForStaff(staff) : '';

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
    final labeled = _labelShiftSummary(state.shiftSummary, state.selectedStaff);
    emit(state.copyWith(shiftSummary: labeled));
  }

  Future<void> _loadSchoolHours({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(isLoadingSchoolHours: true, clearError: true));
    }

    try {
      final schoolCode = await resolveSchoolCode();
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

      final days = await _staffRepository.getSchoolRegularSchedules(
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
      emit(state.copyWith(clearSchoolHours: true, hasSchoolHoursForDay: false));
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
      emit(state.copyWith(isLoadingStaff: true, clearError: true));
    }

    try {
      // Resolved before the roster is narrowed/selected so the default
      // selection below can prefer the logged-in user's own row. Memoised —
      // only the first load pays for it.
      await _ensureLoggedInStaffCode();

      // Delegated to SchedulingStaffListCubit which calls the staff API once
      // with `status=ACTIVE&status=UPCOMING` and no pagination. Singleton —
      // returns cached data on repeat calls unless [force] is set.
      final allStaff = await _schedulingStaffListCubit.load(force: force);

      if (isClosed) return;

      final listError = _schedulingStaffListCubit.state.errorMessage;
      if (listError != null) {
        emit(state.copyWith(isLoadingStaff: false, errorMessage: listError));
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
      } else if (selectFirst || nextCode == null) {
        // Initial entry: land on the logged-in user's own schedule when they
        // have a row in the roster, else the first row.
        nextCode = _defaultStaffCodeFor(visibleStaff);
      } else if (!visibleStaff.any((s) => s.code == nextCode)) {
        nextCode = _defaultStaffCodeFor(visibleStaff);
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
      final organizationCode = await resolveOrganizationCode();
      final schoolCode = await resolveSchoolCode();
      final staff = state.selectedStaff;
      final day = state.selectedDay;

      final shifts = await _getSchoolStaffShiftsUseCase(
        schoolCode: schoolCode,
        organizationCode: organizationCode,
        dateFrom: day,
        dateTo: day,
        // Published-only for every persona here (admin included) — this
        // per-staff shift summary should never show unpublished drafts,
        // matching the hours-range call below (`publishedOnly: true`,
        // already unconditional). Scoped to Staff Scheduling only; the
        // classroom-based Scheduling screen (scheduling_cubit.dart) is
        // intentionally untouched.
        shiftStatus: const <String>['PUBLISHED'],
      );

      if (isClosed) return;

      final filtered = shifts
          .where(
            (s) => s.staffCode == staffCode && _isSameDay(s.shiftDate, day),
          )
          .toList(growable: false);

      var totals = StaffHoursTotals.zero;
      try {
        final hourRows = await _getStaffShiftHoursRangeUseCase(
          schoolCode: schoolCode,
          organizationCode: organizationCode,
          startDate: day,
          endDate: day,
          publishedOnly: true,
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

      emit(state.copyWith(shiftSummary: enriched, isLoadingShifts: false));
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

  /// Fires the bulk POST `/staff-attendance/sign-in/status` for every staff
  /// in [staff]. Skips the call when the roster hasn't changed since the
  /// last request, unless [force] clears the dedupe guard first (used by
  /// pull-to-refresh, which needs the call to re-fire even for an unchanged
  /// roster).
  Future<void> refreshSignInStatusForRoster(
    List<StaffMember> staff, {
    bool force = false,
  }) async {
    if (force) _lastRequestedSignInStatusCodes = const <String>{};
    final codes = <String>{
      for (final s in staff)
        if (s.code.trim().isNotEmpty) s.code.trim(),
    };
    if (codes.isEmpty) {
      if (state.staffSignInStatusByCode.isNotEmpty ||
          _lastRequestedSignInStatusCodes.isNotEmpty) {
        _lastRequestedSignInStatusCodes = const <String>{};
        if (!isClosed) {
          emit(
            state.copyWith(staffSignInStatusByCode: const <String, String>{}),
          );
        }
      }
      return;
    }
    if (codes.length == _lastRequestedSignInStatusCodes.length &&
        codes.containsAll(_lastRequestedSignInStatusCodes)) {
      return;
    }
    _lastRequestedSignInStatusCodes = codes;
    try {
      final map = await _getStaffTodaySignInStatusMapUseCase(
        staffCodes: codes.toList(growable: false),
      );
      if (isClosed) return;
      emit(state.copyWith(staffSignInStatusByCode: map));
    } catch (_) {
      // Best-effort: a failed status fetch just keeps the previous dots.
    }
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
