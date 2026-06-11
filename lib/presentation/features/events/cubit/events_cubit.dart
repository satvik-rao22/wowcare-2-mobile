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
    this._saveHoliday,
    this._deleteHoliday,
    this._storageService,
  ) : super(const EventsState.initial());

  final GetEventsUseCase _getEvents;
  final CreateEventUseCase _createEvent;
  final UpdateEventUseCase _updateEvent;
  final DeleteEventUseCase _deleteEvent;
  final RespondToEventUseCase _respondToEvent;
  final GetHolidaysUseCase _getHolidays;
  final SaveHolidayUseCase _saveHoliday;
  final DeleteHolidayUseCase _deleteHoliday;
  final StorageService _storageService;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(isLoading: true, errorMessage: () => null));
    }
    try {
      final userCode =
          (await _storageService.getString(StorageKeys.userCode) ?? '')
              .trim();
      final userName =
          (await _storageService.getString(StorageKeys.displayName) ?? '')
              .trim();
      final events = await _getEvents();
      final holidays = await _getHolidays();
      emit(state.copyWith(
        events: events,
        holidays: holidays,
        isLoading: false,
        currentUserCode: userCode,
        currentUserName: userName,
        errorMessage: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => 'Failed to load events: $e',
      ));
    }
  }

  // ------------------------------------------------------ search & filters

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query.trim()));
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
    emit(state.copyWith(
      typeFilter: const <EventType>{},
      classroomFilter: const <String>{},
      dateFrom: () => null,
      dateTo: () => null,
    ));
  }

  // --------------------------------------------------------------- events

  /// Persists a new event built by the form. Assigns the code and
  /// audit fields here so the form only deals with user input.
  Future<bool> create(Event draft) async {
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
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
      emit(state.copyWith(
        events: _sorted([...state.events, event]),
        isSaving: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Failed to create event: $e',
      ));
      return false;
    }
  }

  Future<bool> update(Event event) async {
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      final updated = await _updateEvent(event);
      emit(state.copyWith(
        events: _replace(updated),
        isSaving: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Failed to update event: $e',
      ));
      return false;
    }
  }

  Future<bool> delete(String code) async {
    try {
      await _deleteEvent(code);
      emit(state.copyWith(
        events: state.events.where((e) => e.code != code).toList(),
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: () => 'Failed to delete event: $e'));
      return false;
    }
  }

  /// Records the current user's RSVP. [userType] comes from the caller
  /// because the role lives in RoleCubit (presentation scope), not here.
  Future<void> respond({
    required String eventCode,
    required EventRsvpStatus status,
    required String userType,
  }) async {
    if (state.currentUserCode.isEmpty) return;
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
    } catch (e) {
      emit(state.copyWith(errorMessage: () => 'Failed to save RSVP: $e'));
    }
  }

  // ------------------------------------------------------------- holidays

  /// Creates (empty code) or updates a holiday.
  Future<bool> saveHoliday(Holiday draft) async {
    try {
      final isNew = draft.code.isEmpty;
      final holiday = isNew
          ? draft.copyWith(
              code:
                  'HOL-${const Uuid().v4().substring(0, 8).toUpperCase()}',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : draft;
      final saved = await _saveHoliday(holiday);
      final others =
          state.holidays.where((h) => h.code != saved.code).toList();
      emit(state.copyWith(
        holidays: [...others, saved]
          ..sort((a, b) => a.startDate.compareTo(b.startDate)),
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: () => 'Failed to save holiday: $e'));
      return false;
    }
  }

  /// Sets the school's observance decision on a federal holiday.
  Future<void> setHolidayStatus(String code, HolidayStatus status) async {
    final holiday = state.holidayByCode(code);
    if (holiday == null || holiday.type != HolidayType.federal) return;
    await saveHoliday(
      holiday.copyWith(status: () => status, updatedAt: DateTime.now()),
    );
  }

  Future<bool> deleteHoliday(String code) async {
    try {
      await _deleteHoliday(code);
      emit(state.copyWith(
        holidays: state.holidays.where((h) => h.code != code).toList(),
      ));
      return true;
    } catch (e) {
      emit(
        state.copyWith(errorMessage: () => 'Failed to delete holiday: $e'),
      );
      return false;
    }
  }

  // -------------------------------------------------------------- helpers

  List<Event> _replace(Event updated) {
    return state.events
        .map((e) => e.code == updated.code ? updated : e)
        .toList();
  }

  static List<Event> _sorted(List<Event> events) {
    return events
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.startTime.compareTo(b.startTime);
      });
  }
}
