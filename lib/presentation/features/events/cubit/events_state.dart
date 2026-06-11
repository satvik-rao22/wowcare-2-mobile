part of 'events_cubit.dart';

class EventsState extends Equatable {
  const EventsState({
    required this.events,
    required this.holidays,
    required this.isLoading,
    required this.isSaving,
    required this.typeFilter,
    required this.classroomFilter,
    this.dateFrom,
    this.dateTo,
    required this.searchQuery,
    required this.currentUserCode,
    required this.currentUserName,
    this.errorMessage,
  });

  const EventsState.initial()
      : events = const [],
        holidays = const [],
        isLoading = true,
        isSaving = false,
        typeFilter = const <EventType>{},
        classroomFilter = const <String>{},
        dateFrom = null,
        dateTo = null,
        searchQuery = '',
        currentUserCode = '',
        currentUserName = '',
        errorMessage = null;

  final List<Event> events;
  final List<Holiday> holidays;
  final bool isLoading;
  final bool isSaving;

  /// Empty sets mean "show all".
  final Set<EventType> typeFilter;

  /// Classroom codes; an event matches when it targets any of them.
  final Set<String> classroomFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String searchQuery;
  final String currentUserCode;
  final String currentUserName;
  final String? errorMessage;

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
      if (typeFilter.isNotEmpty && !typeFilter.contains(event.type)) {
        return false;
      }
      if (classroomFilter.isNotEmpty &&
          !event.classrooms.any((c) => classroomFilter.contains(c.code))) {
        return false;
      }
      if (dateFrom != null) {
        // Recurring events still match if any occurrence can fall in range.
        final lastDay = event.recurring
            ? (event.recurringEndDate ?? dateFrom!)
            : event.date;
        if (lastDay.isBefore(dateFrom!)) return false;
      }
      if (dateTo != null && event.date.isAfter(dateTo!)) return false;
      return true;
    }).toList();
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

  /// Distinct classrooms referenced by any event — offline-safe options
  /// for the classroom filter.
  List<EventAttendee> get classroomOptions {
    final byCode = <String, EventAttendee>{};
    for (final event in events) {
      for (final classroom in event.classrooms) {
        byCode[classroom.code] = classroom;
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
    DateTime? Function()? dateFrom,
    DateTime? Function()? dateTo,
    String? searchQuery,
    String? currentUserCode,
    String? currentUserName,
    String? Function()? errorMessage,
  }) {
    return EventsState(
      events: events ?? this.events,
      holidays: holidays ?? this.holidays,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      typeFilter: typeFilter ?? this.typeFilter,
      classroomFilter: classroomFilter ?? this.classroomFilter,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      searchQuery: searchQuery ?? this.searchQuery,
      currentUserCode: currentUserCode ?? this.currentUserCode,
      currentUserName: currentUserName ?? this.currentUserName,
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
        dateFrom,
        dateTo,
        searchQuery,
        currentUserCode,
        currentUserName,
        errorMessage,
      ];
}
