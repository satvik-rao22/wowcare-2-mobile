import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/domain/features/events/usecases/cancel_occurrence_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/create_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/delete_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/delete_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_calendar_feed_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_event_by_code_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_events_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_holidays_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/respond_to_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/save_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/set_holiday_status_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/update_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/update_occurrence_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/upload_event_attachments_usecase.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_models.dart';

part 'events_state.dart';

class EventsCubit extends Cubit<EventsState> {
  EventsCubit(
    this._getEvents,
    this._getEventByCode,
    this._getCalendarFeed,
    this._createEvent,
    this._updateEvent,
    this._deleteEvent,
    this._respondToEvent,
    this._updateOccurrence,
    this._cancelOccurrence,
    this._getHolidays,
    this._createHoliday,
    this._updateHoliday,
    this._setHolidayStatus,
    this._deleteHoliday,
    this._storageService,
    this._uploadAttachments,
  ) : super(EventsState.initial());

  final GetEventsUseCase _getEvents;
  final GetEventByCodeUseCase _getEventByCode;
  final GetCalendarFeedUseCase _getCalendarFeed;
  final CreateEventUseCase _createEvent;
  final UpdateEventUseCase _updateEvent;
  final DeleteEventUseCase _deleteEvent;
  final RespondToEventUseCase _respondToEvent;
  final UpdateOccurrenceUseCase _updateOccurrence;
  final CancelOccurrenceUseCase _cancelOccurrence;
  final GetHolidaysUseCase _getHolidays;
  final CreateHolidayUseCase _createHoliday;
  final UpdateHolidayUseCase _updateHoliday;
  final SetHolidayStatusUseCase _setHolidayStatus;
  final DeleteHolidayUseCase _deleteHoliday;
  final UploadEventAttachmentsUseCase _uploadAttachments;
  final StorageService _storageService;

  /// The "My Events" default is derived from the persona once per cubit
  /// lifetime so later loads don't clobber the user's own toggle choice.
  bool _audienceDefaultApplied = false;

  /// Calendar months already fetched (the calendar loads exactly the
  /// visible month; swiping fetches the new month on demand).
  final Set<String> _loadedMonths = {};

  /// Unified-calendar-feed months already fetched, keyed by 'y-m|scope'
  /// (scope in the key so an admin's My/All toggle refetches).
  final Set<String> _loadedFeedMonths = {};

  /// Grid/list infinite scroll: next page to fetch over a wide window
  /// (the API requires a date range; views paginate rather than filter).
  int _listPage = 0;
  bool _fetchingMore = false;

  static String _monthKey(DateTime d) => '${d.year}-${d.month}';
  static String _rowKey(Event e) =>
      e.occurrenceCode.isNotEmpty ? e.occurrenceCode : '${e.code}@${e.date}';

  /// In-flight [load] — concurrent triggers (route builder re-runs,
  /// pull-to-refresh, window expansion) join it instead of firing a
  /// duplicate request burst.
  Future<void>? _inFlightLoad;

  /// Years whose holidays have already been fetched, so the Events tab
  /// calendar can lazily load holidays as the user navigates between years
  /// without re-fetching or losing previously loaded years.
  final Set<int> _loadedHolidayYears = {};

  Future<void> load({bool silent = false}) {
    final pending = _inFlightLoad;
    if (pending != null) return pending;
    final run = _doLoad(silent: silent).whenComplete(() {
      _inFlightLoad = null;
    });
    _inFlightLoad = run;
    return run;
  }

  Future<void> _doLoad({required bool silent}) async {
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
      final guardianCode =
          (await _storageService.getString(StorageKeys.guardianCode) ?? '')
              .trim();
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
      final schoolName = await _resolveSchoolName();
      final (partyCode, _) = await _partyIdentity();
      // One list per all three views: the visible month (calendar) plus
      // the first infinite-scroll page (grid/list), merged by occurrence.
      _loadedMonths
        ..clear()
        ..add(_monthKey(DateTime.now()));
      _listPage = 0;
      final now = DateTime.now();
      final month = await _getEvents(
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 1, 0),
        partyCode: partyCode,
      );
      final (firstPage, hasMore) = await _getEvents.page(
        from: _listFrom,
        to: _listTo,
        page: 0,
        partyCode: partyCode,
      );
      _listPage = 1;
      final byKey = <String, Event>{
        for (final e in [...month, ...firstPage]) _rowKey(e): e,
      };
      final events = byKey.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final holidays = await _getHolidays(year: state.selectedYear);
      _loadedHolidayYears.add(state.selectedYear);
      emit(
        state.copyWith(
          showMineOnly: showMineOnly,
          events: events,
          hasMoreEvents: hasMore,
          isLoadingMore: false,
          holidays: holidays,
          isLoading: false,
          currentUserCode: userCode,
          currentUserName: userName,
          currentStaffCode: staffCode,
          currentGuardianCode: guardianCode,
          schoolName: schoolName,
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

  /// Display name of the active school, for school-wide event audiences.
  /// Prefers the explicitly selected school name; falls back to matching
  /// the active school code in the cached org/school list. Returns '' when
  /// neither is available — the UI shows a generic label then.
  Future<String> _resolveSchoolName() async {
    final schoolCode =
        (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();
    final selected =
        (await _storageService.getString(StorageKeys.selectedSchoolName) ?? '')
            .trim();
    // A stored "name" equal to the code is a placeholder, not a real name.
    if (selected.isNotEmpty && selected != schoolCode) return selected;

    final raw = (await _storageService
                .getString(StorageKeys.organizationsAndSchools) ??
            '')
        .trim();
    if (raw.isEmpty || schoolCode.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final entry in decoded.whereType<Map>()) {
          if ((entry['schoolCode'] ?? '').toString().trim() == schoolCode) {
            final name = (entry['schoolName'] ?? '').toString().trim();
            if (name.isNotEmpty && name != schoolCode) return name;
          }
        }
      }
    } catch (_) {
      // Malformed cache — fall through to the generic label.
    }
    return '';
  }

  // ------------------------------------------------------ search & filters

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query.trim()));
  }

  /// "All Events" vs "My Events" scope (FR-SC-07).
  void setShowMineOnly(bool mineOnly) {
    emit(state.copyWith(showMineOnly: mineOnly));
  }

  /// Calendar "Show" filter: Events / Tasks / Holidays.
  void toggleCalendarKindFilter(CalendarFeedKind kind) {
    final next = Set<CalendarFeedKind>.from(state.calendarKindFilter);
    if (!next.remove(kind)) next.add(kind);
    emit(state.copyWith(calendarKindFilter: next));
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
        calendarKindFilter: const <CalendarFeedKind>{},
        typeFilter: const <EventType>{},
        classroomFilter: const <String>{},
        dateFrom: () => null,
        dateTo: () => null,
      ),
    );
  }

  // --------------------------------------------------------------- events

  /// Persists a new event built by the form. Identity (code, version) and
  /// audit fields are assigned by the events API.
  /// Returns [bool] success only — the caller shows its own toast.
  /// [errorMessage] is left untouched here: it's reserved for background
  /// fetches ([load], [refreshHolidays], [setSelectedYear]) that have no
  /// call site to show a toast directly.
  /// Uploads every picked attachment in one batch and returns the outcome.
  ///
  /// Progress goes through [onProgress] rather than into [EventsState]: it
  /// belongs to the form mid-save, not to the calendar this cubit is shared
  /// with, and it changes many times a second.
  Future<AttachmentUploadState> uploadAttachments({
    required List<PickedFile> files,
    void Function(AttachmentUploadState state)? onProgress,
    CancelToken? cancelToken,
  }) {
    return _uploadAttachments(
      files: files,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<bool> create(
    Event draft, {
    List<String> assetCodes = const [],
  }) async {
    emit(state.copyWith(isSaving: true));
    try {
      final created = await _createEvent(draft, assetCodes: assetCodes);
      // The API echoes audiences as bare selector codes (no display
      // names), so keep the locally picked attendees and take only the
      // server-assigned identity + audit fields.
      final event = draft.copyWith(
        code: created.code,
        version: created.version,
        createdBy: created.createdBy.isNotEmpty
            ? created.createdBy
            : state.currentUserCode,
        createdByName: created.createdByName.isNotEmpty
            ? created.createdByName
            : state.currentUserName,
        createdAt: created.createdAt,
        updatedAt: created.updatedAt,
      );
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

  /// Updates the series; with [splitFromOccurrenceCode] it splits at that
  /// occurrence (THIS_AND_FUTURE). Display fields are patched onto the
  /// local rows without a refetch; date/recurrence changes and splits
  /// reshape the occurrence set, so those refresh from the server.
  Future<bool> update(
    Event event, {
    String splitFromOccurrenceCode = '',
    List<String>? assetCodes,
  }) async {
    emit(state.copyWith(isSaving: true));
    try {
      await _updateEvent(
        event,
        splitFromOccurrenceCode: splitFromOccurrenceCode,
        assetCodes: assetCodes,
      );
      emit(state.copyWith(isSaving: false));
      final original = state.eventByCode(event.code);
      final shapeChanged = splitFromOccurrenceCode.isNotEmpty ||
          (event.recurring &&
              (original == null || original.recurrence != event.recurrence));
      if (shapeChanged) {
        await refresh();
      } else {
        emit(
          state.copyWith(
            events: [
              for (final e in state.events)
                if (e.code != event.code)
                  e
                else
                  e.copyWith(
                    name: event.name,
                    description: event.description,
                    allDay: event.allDay,
                    startTime: event.startTime,
                    endTime: event.endTime,
                    includeParents: event.includeParents,
                    date: event.recurring ? null : event.date,
                  ),
            ],
          ),
        );
      }
      return true;
    } catch (e) {
      emit(state.copyWith(isSaving: false));
      return false;
    }
  }

  /// Full series event (audiences + recurrence rule) for the edit form —
  /// occurrence rows don't carry the rrule.
  Future<Event?> loadEventForEdit(String code) {
    return _getEventByCode(code);
  }

  /// Overrides one occurrence (name/description/date/times) and patches
  /// the local row — no refetch needed.
  Future<(bool success, String message)> updateOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String? overrideName,
    String? overrideDescription,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
  }) async {
    try {
      await _updateOccurrence(
        eventCode: eventCode,
        occurrenceCode: occurrenceCode,
        overrideName: overrideName,
        overrideDescription: overrideDescription,
        scheduledStartDate: scheduledStartDate,
        scheduledStartTime: scheduledStartTime,
        scheduledEndTime: scheduledEndTime,
      );
      String pick(String? next, String current) =>
          (next ?? '').trim().isNotEmpty ? next!.trim() : current;
      emit(
        state.copyWith(
          events: [
            for (final e in state.events)
              if (e.occurrenceCode != occurrenceCode)
                e
              else
                e.copyWith(
                  name: pick(overrideName, e.name),
                  description: pick(overrideDescription, e.description),
                  date: scheduledStartDate ?? e.date,
                  startTime: pick(scheduledStartTime, e.startTime),
                  endTime: pick(scheduledEndTime, e.endTime),
                ),
          ],
        ),
      );
      return (true, 'Event updated');
    } catch (_) {
      return (false, 'Could not update this event. Please try again.');
    }
  }

  /// Cancels one occurrence; the row disappears from the loaded window
  /// (cancelled occurrences are excluded by default).
  Future<(bool success, String message)> cancelOccurrence({
    required String eventCode,
    required String occurrenceCode,
    String reason = '',
  }) async {
    try {
      await _cancelOccurrence(
        eventCode: eventCode,
        occurrenceCode: occurrenceCode,
        reason: reason,
      );
      emit(
        state.copyWith(
          events: state.events
              .where((e) => e.occurrenceCode != occurrenceCode)
              .toList(),
        ),
      );
      return (true, 'Event cancelled');
    } catch (_) {
      return (false, 'Could not cancel this event. Please try again.');
    }
  }

  /// Cancels [occurrence] and every later one in its series
  /// (THIS_AND_FUTURE) — e.g. an admin stopping a weekly event from next
  /// month onward. Earlier occurrences stay.
  Future<(bool success, String message)> deleteFromOccurrence(
    Event occurrence,
  ) async {
    try {
      await _deleteEvent(
        occurrence.code,
        fromOccurrenceCode: occurrence.occurrenceCode,
      );
      final cutoff =
          DateTime(occurrence.date.year, occurrence.date.month, occurrence.date.day);
      emit(
        state.copyWith(
          events: state.events
              .where(
                (e) =>
                    e.code != occurrence.code || e.date.isBefore(cutoff),
              )
              .toList(),
        ),
      );
      return (true, 'Upcoming events cancelled');
    } catch (_) {
      return (false, 'Could not cancel the upcoming events. Please try again.');
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

  /// Records the current user's RSVP on [occurrence] (an occurrence-based
  /// event row). Only server-confirmed participants — people on the row's
  /// roster — may respond; the UI hides the bar for everyone else and this
  /// guard backstops it. Returns a fixed success/failure message for the
  /// caller's toast. [userType] is kept for caller compatibility; the
  /// identity is resolved from storage.
  Future<(bool success, String message)> respond({
    required Event occurrence,
    required EventRsvpStatus status,
    required String userType,
  }) async {
    final (partyCode, partyType) = await _partyIdentity();
    if (partyCode.isEmpty) {
      return (false, 'Unable to identify the current user');
    }
    if (!state.isParticipant(occurrence)) {
      return (false, 'Only invited participants can RSVP to this event');
    }
    try {
      await _respondToEvent(
        eventCode: occurrence.code,
        occurrenceCode: occurrence.occurrenceCode,
        partyCode: partyCode,
        partyType: partyType,
        status: status,
      );
      _applyMyRsvp(occurrence.occurrenceCode, status, partyType, partyCode);
      return (true, 'RSVP saved');
    } catch (e) {
      return (false, 'Could not save your RSVP. Please try again.');
    }
  }

  /// (partyCode, partyType) of the logged-in user: staff code when one is
  /// resolved, else the guardian record code for parents.
  Future<(String, String)> _partyIdentity() async {
    final staffCode = state.currentStaffCode.trim().isNotEmpty
        ? state.currentStaffCode.trim()
        : (await _storageService.getString(StorageKeys.staffCode) ?? '')
              .trim();
    if (staffCode.isNotEmpty) return (staffCode, 'STAFF');
    final guardianCode =
        (await _storageService.getString(StorageKeys.guardianCode) ?? '')
            .trim();
    if (guardianCode.isNotEmpty) return (guardianCode, 'PARENT');
    return ('', 'STAFF');
  }

  /// Reflects the RSVP on the occurrence row so the bar and summary
  /// update without a refetch.
  void _applyMyRsvp(
    String occurrenceCode,
    EventRsvpStatus status,
    String partyType,
    String partyCode,
  ) {
    final events = [
      for (final event in state.events)
        if (event.occurrenceCode != occurrenceCode)
          event
        else
          event.copyWith(
            myRsvpStatus: () => status,
            rsvps: [
              ...event.rsvps.where((r) => r.userCode != partyCode),
              EventRsvp(
                userCode: partyCode,
                userName: state.currentUserName,
                userType: partyType,
                status: status,
                respondedAt: DateTime.now(),
              ),
            ],
          ),
    ];
    emit(state.copyWith(events: events));
  }

  /// Range for grid/list pagination — the API requires a window, the views
  /// want plain pages. Starts TODAY: pages walk date_asc, so starting in
  /// the past would spend the first pages on old occurrences the upcoming
  /// list filters out (past events come from the month fetches instead).
  DateTime get _listFrom {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _listTo =>
      DateTime(DateTime.now().year + 2, DateTime.now().month, 0);

  /// Merges [rows] into state (occurrence-keyed) keeping date order.
  void _mergeRows(List<Event> rows, {bool? hasMore}) {
    final byKey = <String, Event>{
      for (final e in state.events) _rowKey(e): e,
    };
    for (final row in rows) {
      byKey[_rowKey(row)] = row;
    }
    final events = byKey.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    emit(
      state.copyWith(
        events: events,
        isLoadingMore: false,
        hasMoreEvents: hasMore,
      ),
    );
  }

  /// Calendar navigation: fetch the newly visible month once.
  Future<void> ensureMonth(DateTime month) async {
    final key = _monthKey(month);
    if (_loadedMonths.contains(key)) return;
    _loadedMonths.add(key);
    try {
      final (partyCode, _) = await _partyIdentity();
      final rows = await _getEvents(
        from: DateTime(month.year, month.month, 1),
        to: DateTime(month.year, month.month + 1, 0),
        partyCode: partyCode,
      );
      _mergeRows(rows);
    } catch (_) {
      _loadedMonths.remove(key); // retry on the next visit
    }
  }

  /// Loads the unified calendar feed (events + tasks + holidays) for
  /// [month] once per (month, scope). [scope] is 'ALL_ITEMS' (admin's All
  /// toggle) or 'MY_ITEMS'; non-admins must always pass 'MY_ITEMS'. Rows
  /// merge into [EventsState.calendarItems] keyed by code.
  Future<void> loadCalendarFeed(DateTime month, {required String scope}) async {
    final key = '${_monthKey(month)}|$scope';
    if (_loadedFeedMonths.contains(key)) return;
    _loadedFeedMonths.add(key);
    emit(state.copyWith(calendarLoading: true));
    try {
      final (partyCode, _) = await _partyIdentity();
      final rows = await _getCalendarFeed(
        from: DateTime(month.year, month.month, 1),
        to: DateTime(month.year, month.month + 1, 0),
        scope: scope,
        partyCode: partyCode,
      );
      final byCode = <String, CalendarFeedItem>{
        for (final item in state.calendarItems) item.code: item,
        for (final item in rows) item.code: item,
      };
      emit(
        state.copyWith(
          calendarItems: byCode.values.toList(),
          calendarLoading: false,
        ),
      );
    } catch (_) {
      _loadedFeedMonths.remove(key);
      emit(state.copyWith(calendarLoading: false));
    }
  }

  /// Clears cached feed months (e.g. when the admin flips the My/All
  /// toggle and the current month must refetch under the new scope).
  void resetCalendarFeed() {
    _loadedFeedMonths.clear();
    emit(state.copyWith(calendarItems: const []));
  }

  /// Grid/list infinite scroll: fetch the next page (10 rows) and append.
  Future<void> loadMoreEvents() async {
    if (_fetchingMore || !state.hasMoreEvents) return;
    _fetchingMore = true;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final (partyCode, _) = await _partyIdentity();
      final (rows, hasMore) = await _getEvents.page(
        from: _listFrom,
        to: _listTo,
        page: _listPage,
        partyCode: partyCode,
      );
      _listPage++;
      _mergeRows(rows, hasMore: hasMore);
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    } finally {
      _fetchingMore = false;
    }
  }

  /// Full reload that never joins an already-running (stale) load.
  Future<void> refresh() async {
    try {
      await _inFlightLoad;
    } catch (_) {}
    await load(silent: true);
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
