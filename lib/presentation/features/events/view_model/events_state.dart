part of 'events_cubit.dart';

class EventsState extends Equatable {
  const EventsState({
    required this.events,
    required this.holidays,
    required this.isLoading,
    required this.isSaving,
    required this.typeFilter,
    required this.classroomFilter,
    required this.selectedYear,
    this.showMineOnly = false,
    this.dateFrom,
    this.dateTo,
    required this.searchQuery,
    required this.currentUserCode,
    required this.currentUserName,
    this.currentStaffCode = '',
    this.currentGuardianCode = '',
    this.schoolName = '',
    this.isLoadingMore = false,
    this.hasMoreEvents = true,
    this.calendarItems = const <CalendarFeedItem>[],
    this.calendarLoading = false,
    this.calendarKindFilter = const <CalendarFeedKind>{},
    this.errorMessage,
  });

  EventsState.initial()
      : events = const [],
        holidays = const [],
        isLoading = true,
        isSaving = false,
        typeFilter = const <EventType>{},
        classroomFilter = const <String>{},
        selectedYear = DateTime.now().year,
        showMineOnly = false,
        dateFrom = null,
        dateTo = null,
        searchQuery = '',
        currentUserCode = '',
        currentUserName = '',
        currentStaffCode = '',
        currentGuardianCode = '',
        schoolName = '',
        isLoadingMore = false,
        hasMoreEvents = true,
        calendarItems = const <CalendarFeedItem>[],
        calendarLoading = false,
        calendarKindFilter = const <CalendarFeedKind>{},
        errorMessage = null;

  final List<Event> events;
  final List<Holiday> holidays;

  /// Year selected on the Holiday List (FR-HL-07). Holidays are fetched and
  /// filtered against this year.
  final int selectedYear;
  final bool isLoading;
  final bool isSaving;

  /// Empty sets mean "show all".
  final Set<EventType> typeFilter;

  /// Classroom codes; an event matches when it targets any of them.
  final Set<String> classroomFilter;

  /// "My Events" scope (FR-SC-07): only events the current user created,
  /// is a staff attendee of, or that are school-wide. Defaults to true for
  /// staff personas, false otherwise.
  final bool showMineOnly;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String searchQuery;
  final String currentUserCode;
  final String currentUserName;

  /// Staff code of the logged-in user (differs from [currentUserCode]);
  /// empty for guardians or when not resolved yet. Used to match the user
  /// against event staff attendees / `createdBy`.
  final String currentStaffCode;

  /// Guardian record code of the logged-in parent; empty for staff/admin
  /// personas. RSVP roster rows are keyed by party code (staff or
  /// guardian), so "my RSVP" lookups check these identities.
  final String currentGuardianCode;

  /// Display name of the active school — shown as the audience of
  /// school-wide events. Empty until resolved from storage.
  final String schoolName;

  /// Grid/list infinite scroll: a next page is being fetched (bottom
  /// spinner) / more pages exist.
  final bool isLoadingMore;
  final bool hasMoreEvents;

  /// Unified calendar-feed rows (events + tasks + holidays) for the
  /// calendar view. Distinct from [events] (rich occurrences) which back
  /// the grid/list views.
  final List<CalendarFeedItem> calendarItems;
  final bool calendarLoading;

  /// Calendar "Show" filter — which feed kinds are visible. Empty = all.
  final Set<CalendarFeedKind> calendarKindFilter;

  final String? errorMessage;

  /// Whether [item] passes the calendar filters (module access + kind + search
  /// + the event-type filter, which only constrains EVENT rows so tasks and
  /// holidays aren't hidden by an event-only choice).
  ///
  /// [allowedKinds] is the caller's module permission (see
  /// `EventAccess.readableCalendarKinds`) and is checked first: a row the user
  /// has no module for must never render, whatever the UI filters say.
  bool _passesCalendarFilters(
    CalendarFeedItem item,
    Set<CalendarFeedKind> allowedKinds,
  ) {
    if (!allowedKinds.contains(item.kind)) return false;
    if (calendarKindFilter.isNotEmpty &&
        !calendarKindFilter.contains(item.kind)) {
      return false;
    }
    if (isSearching) {
      final q = searchQuery.toLowerCase();
      if (!item.name.toLowerCase().contains(q) &&
          !item.description.toLowerCase().contains(q)) {
        return false;
      }
    }
    if (typeFilter.isNotEmpty && item.isEvent) {
      final type = EventType.fromValue(item.eventType);
      if (!typeFilter.contains(type)) return false;
    }
    return true;
  }

  /// Filtered feed rows on [day], sorted all-day-first then by time.
  List<CalendarFeedItem> calendarItemsOn(
    DateTime day, {
    required Set<CalendarFeedKind> allowedKinds,
  }) {
    final matches = calendarItems
        .where(
          (i) => i.occursOn(day) && _passesCalendarFilters(i, allowedKinds),
        )
        .toList()
      ..sort((a, b) {
        if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
        return a.startTime.compareTo(b.startTime);
      });
    return matches;
  }

  bool calendarHasItems(
    DateTime day, {
    required Set<CalendarFeedKind> allowedKinds,
  }) => calendarItems.any(
    (i) => i.occursOn(day) && _passesCalendarFilters(i, allowedKinds),
  );

  /// Calendar filters count for the filter badge (kind + event type +
  /// classrooms + date range).
  int get calendarFilterCount =>
      calendarKindFilter.length + typeFilter.length;

  /// Whether the current user is on [occurrence]'s participant roster
  /// (staff or parent — students never RSVP). The roster comes fully
  /// hydrated with every occurrence row, so this is a local check.
  bool isParticipant(Event occurrence) {
    final staffCode = currentStaffCode.trim();
    if (staffCode.isNotEmpty &&
        occurrence.staff.any((s) => s.code == staffCode)) {
      return true;
    }
    final guardianCode = currentGuardianCode.trim();
    return guardianCode.isNotEmpty &&
        occurrence.parents.any((p) => p.code == guardianCode);
  }

  /// The occurrence row with [occurrenceCode]; falls back to the first
  /// row of [eventCode] (e.g. optimistic rows without occurrence codes).
  Event? eventByOccurrence(String occurrenceCode, {String eventCode = ''}) {
    final trimmed = occurrenceCode.trim();
    for (final event in events) {
      if (trimmed.isNotEmpty && event.occurrenceCode == trimmed) return event;
    }
    return eventCode.trim().isEmpty ? null : eventByCode(eventCode);
  }

  bool get isSearching => searchQuery.length >= 2;

  int get activeFilterCount =>
      typeFilter.length +
      classroomFilter.length +
      (dateFrom != null || dateTo != null ? 1 : 0);

  /// Events passing the type / classroom / date-range filters (search is
  /// applied separately by [searchResults] so the calendar can stay
  /// filter-aware while a query is being typed).
  List<Event> get filteredEvents {
    return events.where((event) {
      if (showMineOnly && !_isMine(event)) return false;
      if (typeFilter.isNotEmpty && !typeFilter.contains(event.type)) {
        return false;
      }
      if (classroomFilter.isNotEmpty &&
          !event.classrooms.any((c) => classroomFilter.contains(c.code))) {
        return false;
      }
      // Occurrence rows carry their own concrete date — range-match it
      // directly (no series expansion involved).
      if (dateFrom != null && event.date.isBefore(dateFrom!)) return false;
      if (dateTo != null && event.date.isAfter(dateTo!)) return false;
      return true;
    }).toList();
  }

  /// Upcoming filtered occurrences ordered date-wise (every occurrence is
  /// its own card on the list/grid views, like the calendar).
  List<Event> get upcomingEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return filteredEvents.where((e) => !e.date.isBefore(today)).toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.startTime.compareTo(b.startTime);
      });
  }

  /// Past filtered occurrences, most recent first. Backs the collapsible
  /// "Completed Events" section.
  List<Event> get completedEvents {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return filteredEvents.where((e) => e.date.isBefore(today)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Whether [event] belongs to the current user's "My Events" scope:
  /// created by them, or they are on the occurrence roster (staff or
  /// parent — the server resolves audience expansion). Permissive when the
  /// user identity hasn't resolved yet.
  bool _isMine(Event event) {
    final codes = <String>{currentUserCode, currentStaffCode}
      ..removeWhere((code) => code.isEmpty);
    final guardianCode = currentGuardianCode.trim();
    if (codes.isEmpty && guardianCode.isEmpty) return true;
    if (event.type == EventType.school) return true;
    if (codes.contains(event.createdBy)) return true;
    if (event.staff.any((s) => codes.contains(s.code))) return true;
    return guardianCode.isNotEmpty &&
        event.parents.any((p) => p.code == guardianCode);
  }

  /// Filtered events matching the search query in name or description.
  List<Event> get searchResults {
    if (!isSearching) return filteredEvents;
    final query = searchQuery.toLowerCase();
    return filteredEvents
        .where((e) =>
            e.name.toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query))
        .toList();
  }

  /// Events landing on [day], including recurring expansions, sorted with
  /// all-day events first then by start time.
  List<Event> eventsOn(DateTime day) {
    final matches =
        filteredEvents.where((e) => e.occursOn(day)).toList()
          ..sort((a, b) {
            if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
            return a.startTime.compareTo(b.startTime);
          });
    return matches;
  }

  /// Observed holidays (school + accepted federal) covering [day].
  List<Holiday> holidaysOn(DateTime day) {
    return holidays
        .where((h) => h.isObserved && h.coversDay(day))
        .toList();
  }

  bool isHoliday(DateTime day) =>
      holidays.any((h) => h.isObserved && h.coversDay(day));

  // ------------------------------------------------------ holiday grouping

  /// Holidays whose start date falls in [selectedYear] (FR-HL-08). Applied as
  /// a client-side safety net on top of the API's `year` filter.
  List<Holiday> get _holidaysForYear => holidays
      .where((h) => h.startDate.year == selectedYear)
      .toList();

  /// School-defined holidays, sorted ascending by start date (FR-HL-01).
  List<Holiday> get schoolHolidays => (_holidaysForYear
          .where((h) => h.type == HolidayType.school)
          .toList())
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

  /// Considered federal holidays + all school holidays, sorted ascending by
  /// start date (FR-HL-09).
  List<Holiday> get activeHolidays => (_holidaysForYear
          .where((h) =>
              h.type == HolidayType.school ||
              h.status == HolidayStatus.considered)
          .toList())
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

  /// Pending federal holidays awaiting admin review (FR-HL-02).
  List<Holiday> get pendingFederalHolidays => (_holidaysForYear
          .where((h) =>
              h.type == HolidayType.federal &&
              h.status == HolidayStatus.pending)
          .toList())
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

  /// Rejected federal holidays (FR-HL-04).
  List<Holiday> get rejectedFederalHolidays => (_holidaysForYear
          .where((h) =>
              h.type == HolidayType.federal &&
              h.status == HolidayStatus.rejected)
          .toList())
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

  /// Distinct classrooms referenced by any event — offline-safe options
  /// for the classroom filter.
  List<EventAttendee> get classroomOptions {
    final byCode = <String, EventAttendee>{};
    for (final event in events) {
      for (final classroom in event.classrooms) {
        // API events carry codes without names — fall back to the code so
        // the filter sheet never shows a blank chip.
        byCode[classroom.code] = classroom.name.trim().isNotEmpty
            ? classroom
            : EventAttendee(code: classroom.code, name: classroom.code);
      }
    }
    final options = byCode.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return options;
  }

  Event? eventByCode(String code) {
    for (final event in events) {
      if (event.code == code) return event;
    }
    return null;
  }

  Holiday? holidayByCode(String code) {
    for (final holiday in holidays) {
      if (holiday.code == code) return holiday;
    }
    return null;
  }

  EventsState copyWith({
    List<Event>? events,
    List<Holiday>? holidays,
    bool? isLoading,
    bool? isSaving,
    Set<EventType>? typeFilter,
    Set<String>? classroomFilter,
    int? selectedYear,
    bool? showMineOnly,
    DateTime? Function()? dateFrom,
    DateTime? Function()? dateTo,
    String? searchQuery,
    String? currentUserCode,
    String? currentUserName,
    String? currentStaffCode,
    String? currentGuardianCode,
    String? schoolName,
    bool? isLoadingMore,
    bool? hasMoreEvents,
    List<CalendarFeedItem>? calendarItems,
    bool? calendarLoading,
    Set<CalendarFeedKind>? calendarKindFilter,
    String? Function()? errorMessage,
  }) {
    return EventsState(
      events: events ?? this.events,
      holidays: holidays ?? this.holidays,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      typeFilter: typeFilter ?? this.typeFilter,
      classroomFilter: classroomFilter ?? this.classroomFilter,
      selectedYear: selectedYear ?? this.selectedYear,
      showMineOnly: showMineOnly ?? this.showMineOnly,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      searchQuery: searchQuery ?? this.searchQuery,
      currentUserCode: currentUserCode ?? this.currentUserCode,
      currentUserName: currentUserName ?? this.currentUserName,
      currentStaffCode: currentStaffCode ?? this.currentStaffCode,
      currentGuardianCode: currentGuardianCode ?? this.currentGuardianCode,
      schoolName: schoolName ?? this.schoolName,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreEvents: hasMoreEvents ?? this.hasMoreEvents,
      calendarItems: calendarItems ?? this.calendarItems,
      calendarLoading: calendarLoading ?? this.calendarLoading,
      calendarKindFilter: calendarKindFilter ?? this.calendarKindFilter,
      errorMessage:
          errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        events,
        holidays,
        isLoading,
        isSaving,
        typeFilter,
        classroomFilter,
        selectedYear,
        showMineOnly,
        dateFrom,
        dateTo,
        searchQuery,
        currentUserCode,
        currentUserName,
        currentStaffCode,
        currentGuardianCode,
        schoolName,
        isLoadingMore,
        hasMoreEvents,
        calendarItems,
        calendarLoading,
        calendarKindFilter,
        errorMessage,
      ];
}
