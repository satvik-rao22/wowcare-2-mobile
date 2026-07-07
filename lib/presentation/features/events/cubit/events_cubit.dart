import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/domain/features/events/usecases/create_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/delete_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/delete_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_events_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_holidays_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/respond_to_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/save_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/set_holiday_status_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/update_event_usecase.dart';

part 'events_state.dart';

class EventsCubit extends Cubit<EventsState> {
  EventsCubit(
    this._getEvents,
    this._createEvent,
    this._updateEvent,
    this._deleteEvent,
    this._respondToEvent,
    this._getHolidays,
    this._createHoliday,
    this._updateHoliday,
    this._setHolidayStatus,
    this._deleteHoliday,
    this._storageService,
  ) : super(EventsState.initial());

  final GetEventsUseCase _getEvents;
  final CreateEventUseCase _createEvent;
  final UpdateEventUseCase _updateEvent;
  final DeleteEventUseCase _deleteEvent;
  final RespondToEventUseCase _respondToEvent;
  final GetHolidaysUseCase _getHolidays;
  final CreateHolidayUseCase _createHoliday;
  final UpdateHolidayUseCase _updateHoliday;
  final SetHolidayStatusUseCase _setHolidayStatus;
  final DeleteHolidayUseCase _deleteHoliday;
  final StorageService _storageService;

  /// The "My Events" default is derived from the persona once per cubit
  /// lifetime so later loads don't clobber the user's own toggle choice.
  bool _audienceDefaultApplied = false;

  /// Years whose holidays have already been fetched, so the Events tab
  /// calendar can lazily load holidays as the user navigates between years
  /// without re-fetching or losing previously loaded years.
  final Set<int> _loadedHolidayYears = {};

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(isLoading: true, errorMessage: () => null));
    }
    try {
      final userCode =
          (await _storageService.getString(StorageKeys.userCode) ?? '').trim();
      final userName =
          (await _storageService.getString(StorageKeys.displayName) ?? '')
              .trim();
      // Cached by the staff-code resolver elsewhere; empty for guardians
      // or before first resolution — access checks degrade gracefully.
      final staffCode =
          (await _storageService.getString(StorageKeys.staffCode) ?? '').trim();
      var showMineOnly = state.showMineOnly;
      if (!_audienceDefaultApplied) {
        _audienceDefaultApplied = true;
        // Staff/teacher personas default to "My Events" (PRD FR-SC-07);
        // admins and guardians default to all events.
        final role =
            (await _storageService.getString(StorageKeys.activeSchoolRole) ??
                    '')
                .toUpperCase();
        showMineOnly = role.contains('STAFF') || role.contains('TEACHER');
      }
      final events = await _getEvents();
      final holidays = await _getHolidays(year: state.selectedYear);
      _loadedHolidayYears.add(state.selectedYear);
      emit(
        state.copyWith(
          showMineOnly: showMineOnly,
          events: events,
          holidays: holidays,
          isLoading: false,
          currentUserCode: userCode,
          currentUserName: userName,
          currentStaffCode: staffCode,
          errorMessage: () => null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: () => 'Failed to load events: $e',
        ),
      );
    }
  }

  // ------------------------------------------------------ search & filters

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query.trim()));
  }

  /// "All Events" vs "My Events" scope (FR-SC-07).
  void setShowMineOnly(bool mineOnly) {
    emit(state.copyWith(showMineOnly: mineOnly));
  }

  void toggleTypeFilter(EventType type) {
    final next = Set<EventType>.from(state.typeFilter);
    if (!next.remove(type)) next.add(type);
    emit(state.copyWith(typeFilter: next));
  }

  void toggleClassroomFilter(String classroomCode) {
    final next = Set<String>.from(state.classroomFilter);
    if (!next.remove(classroomCode)) next.add(classroomCode);
    emit(state.copyWith(classroomFilter: next));
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    emit(state.copyWith(dateFrom: () => from, dateTo: () => to));
  }

  void clearTypeFilter() {
    emit(state.copyWith(typeFilter: const <EventType>{}));
  }

  void clearAllFilters() {
    emit(
      state.copyWith(
        typeFilter: const <EventType>{},
        classroomFilter: const <String>{},
        dateFrom: () => null,
        dateTo: () => null,
      ),
    );
  }

  // --------------------------------------------------------------- events

  /// Persists a new event built by the form. Assigns the code and
  /// audit fields here so the form only deals with user input.
  /// Returns [bool] success only — the caller shows its own toast (fixed
  /// copy, since the events API is a stub with no server-provided message).
  /// [errorMessage] is left untouched here: it's reserved for background
  /// fetches ([load], [refreshHolidays], [setSelectedYear]) that have no
  /// call site to show a toast directly.
  Future<bool> create(Event draft) async {
    emit(state.copyWith(isSaving: true));
    try {
      final now = DateTime.now();
      final event = draft.copyWith(
        code: 'EVT-${const Uuid().v4().substring(0, 8).toUpperCase()}',
        createdBy: state.currentUserCode,
        createdByName: state.currentUserName,
        createdAt: now,
        updatedAt: now,
      );
      await _createEvent(event);
      emit(
        state.copyWith(
          events: _sorted([...state.events, event]),
          isSaving: false,
        ),
      );
      return true;
    } catch (e) {
      emit(state.copyWith(isSaving: false));
      return false;
    }
  }

  Future<bool> update(Event event) async {
    emit(state.copyWith(isSaving: true));
    try {
      final updated = await _updateEvent(event);
      emit(state.copyWith(events: _replace(updated), isSaving: false));
      return true;
    } catch (e) {
      emit(state.copyWith(isSaving: false));
      return false;
    }
  }

  Future<bool> delete(String code) async {
    try {
      await _deleteEvent(code);
      emit(
        state.copyWith(
          events: state.events.where((e) => e.code != code).toList(),
        ),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Records the current user's RSVP. [userType] comes from the caller
  /// because the role lives in RoleCubit (presentation scope), not here.
  /// Returns a fixed success/failure message for the caller to show as a
  /// toast, mirroring the holiday save/delete/status-change methods.
  Future<(bool success, String message)> respond({
    required String eventCode,
    required EventRsvpStatus status,
    required String userType,
  }) async {
    if (state.currentUserCode.isEmpty) {
      return (false, 'Unable to identify the current user');
    }
    try {
      final updated = await _respondToEvent(
        eventCode: eventCode,
        rsvp: EventRsvp(
          userCode: state.currentUserCode,
          userName: state.currentUserName,
          userType: userType,
          status: status,
          respondedAt: DateTime.now(),
        ),
      );
      emit(state.copyWith(events: _replace(updated)));
      return (true, 'RSVP saved');
    } catch (e) {
      return (false, 'Could not save your RSVP. Please try again.');
    }
  }

  // ------------------------------------------------------------- holidays

  /// Fetches holidays for the current [EventsState.selectedYear] without
  /// touching events. Called when the Holidays tab is opened so the list is
  /// always live from the scheduler API.
  Future<void> refreshHolidays() async {
    try {
      final holidays = await _getHolidays(year: state.selectedYear);
      _loadedHolidayYears.add(state.selectedYear);
      _mergeHolidaysForYear(state.selectedYear, holidays);
      emit(state.copyWith(errorMessage: () => null));
    } catch (e) {
      emit(state.copyWith(errorMessage: () => 'Failed to load holidays: $e'));
    }
  }

  /// Year selector on the Holiday List (FR-HL-07/08). Reloads holidays
  /// scoped to [year].
  Future<void> setSelectedYear(int year) async {
    if (year == state.selectedYear) return;
    emit(state.copyWith(selectedYear: year, isLoading: true));
    try {
      final holidays = await _getHolidays(year: year);
      _loadedHolidayYears.add(year);
      _mergeHolidaysForYear(year, holidays);
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: () => 'Failed to load holidays: $e',
        ),
      );
    }
  }

  /// Lazily fetches holidays for [year] if it hasn't been loaded yet. Used
  /// by the Events tab calendar so holidays keep showing as the user
  /// navigates to a different year, without discarding other loaded years.
  Future<void> ensureHolidaysForYear(int year) async {
    if (_loadedHolidayYears.contains(year)) return;
    try {
      final holidays = await _getHolidays(year: year);
      _loadedHolidayYears.add(year);
      _mergeHolidaysForYear(year, holidays);
    } catch (_) {
      // Silent: the calendar simply won't show holidays for this year until
      // the next successful fetch; a banner error here would be noisy for a
      // background pre-fetch triggered by page swipes.
    }
  }

  /// Creates a new school holiday (empty [draft] code) or updates an existing
  /// one. Codes and versions are assigned by the scheduler API. Returns the
  /// API's success message so the caller can show it as a toast.
  Future<(bool success, String message)> saveHoliday(Holiday draft) async {
    emit(state.copyWith(isSaving: true));
    try {
      final (saved, message) = draft.code.isEmpty
          ? await _createHoliday(
              name: draft.name,
              startDate: draft.startDate,
              endDate: draft.endDate,
              description: draft.description,
            )
          : await _updateHoliday(
              code: draft.code,
              version: draft.version,
              name: draft.name,
              startDate: draft.startDate,
              endDate: draft.endDate,
              description: draft.description,
            );
      _upsertHoliday(saved);
      emit(state.copyWith(isSaving: false));
      return (true, message);
    } catch (e) {
      emit(state.copyWith(isSaving: false));
      return (false, 'Could not save the holiday. Please try again.');
    }
  }

  /// Approves/rejects/re-approves a federal holiday (FR-HL-03/04/05).
  /// [status] is the desired end state: [HolidayStatus.considered] maps to
  /// APPROVE (and re-approve from rejected), [HolidayStatus.rejected] to
  /// REJECT.
  Future<(bool success, String message)> setHolidayStatus(
    String code,
    HolidayStatus status,
  ) async {
    final holiday = state.holidayByCode(code);
    if (holiday == null || holiday.type != HolidayType.federal) {
      return (false, 'Holiday not found');
    }
    if (status == HolidayStatus.pending) {
      return (false, 'Invalid holiday status change');
    }
    final action = status == HolidayStatus.considered
        ? HolidayStatusAction.approve
        : HolidayStatusAction.reject;
    try {
      final (saved, message) = await _setHolidayStatus(
        code: code,
        version: holiday.version,
        action: action,
      );
      _upsertHoliday(saved);
      return (true, message);
    } catch (e) {
      return (false, 'Could not update the holiday status. Please try again.');
    }
  }

  Future<(bool success, String message)> deleteHoliday(String code) async {
    try {
      final message = await _deleteHoliday(code);
      emit(
        state.copyWith(
          holidays: state.holidays.where((h) => h.code != code).toList(),
        ),
      );
      return (true, message);
    } catch (e) {
      return (false, 'Could not delete the holiday. Please try again.');
    }
  }

  /// Replaces (or inserts) [saved] in the holiday list, keeping it sorted
  /// ascending by start date (FR-HL-09).
  void _upsertHoliday(Holiday saved) {
    final others = state.holidays.where((h) => h.code != saved.code).toList();
    emit(
      state.copyWith(
        holidays: [...others, saved]
          ..sort((a, b) => a.startDate.compareTo(b.startDate)),
      ),
    );
  }

  /// Replaces every holiday starting in [year] with [fetched], leaving
  /// holidays from other years untouched.
  void _mergeHolidaysForYear(int year, List<Holiday> fetched) {
    final others = state.holidays
        .where((h) => h.startDate.year != year)
        .toList();
    emit(
      state.copyWith(
        holidays: [...others, ...fetched]
          ..sort((a, b) => a.startDate.compareTo(b.startDate)),
      ),
    );
  }

  // -------------------------------------------------------------- helpers

  List<Event> _replace(Event updated) {
    return state.events
        .map((e) => e.code == updated.code ? updated : e)
        .toList();
  }

  static List<Event> _sorted(List<Event> events) {
    return events..sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return a.startTime.compareTo(b.startTime);
    });
  }
}
