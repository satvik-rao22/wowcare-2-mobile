import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/usecases/cancel_occurrence_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/create_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/delete_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/delete_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_event_by_code_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_events_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_holidays_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/respond_to_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/save_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/set_holiday_status_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/update_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/update_occurrence_usecase.dart';
import 'package:wowcare/presentation/features/events/cubit/events_cubit.dart';

import 'helpers/event_test_fakes.dart';

Event _occurrence(String occ, {int daysFromNow = 1}) {
  final now = DateTime.now();
  return Event(
    code: 'EVT_$occ',
    occurrenceCode: 'OCC_$occ',
    type: EventType.school,
    name: 'Event $occ',
    date: DateTime(now.year, now.month, now.day + daysFromNow),
    allDay: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeEventRepository repo;
  late EventsCubit cubit;

  EventsCubit build() => EventsCubit(
    GetEventsUseCase(repo),
    GetEventByCodeUseCase(repo),
    CreateEventUseCase(repo),
    UpdateEventUseCase(repo),
    DeleteEventUseCase(repo),
    RespondToEventUseCase(repo),
    UpdateOccurrenceUseCase(repo),
    CancelOccurrenceUseCase(repo),
    GetHolidaysUseCase(repo),
    CreateHolidayUseCase(repo),
    UpdateHolidayUseCase(repo),
    SetHolidayStatusUseCase(repo),
    DeleteHolidayUseCase(repo),
    FakeStorageService(),
  );

  setUp(() {
    repo = FakeEventRepository();
    cubit = build();
  });

  tearDown(() => cubit.close());

  group('infinite scroll pagination', () {
    test('load fetches page 0; loadMoreEvents fetches the following pages',
        () async {
      repo.pageResults = [
        ([_occurrence('A'), _occurrence('B', daysFromNow: 2)], true),
        ([_occurrence('C', daysFromNow: 3)], true),
        ([_occurrence('D', daysFromNow: 4)], false),
      ];

      await cubit.load();
      expect(repo.requestedPages, [0]);
      expect(cubit.state.events.map((e) => e.occurrenceCode),
          containsAll(['OCC_A', 'OCC_B']));
      expect(cubit.state.hasMoreEvents, isTrue);

      await cubit.loadMoreEvents();
      expect(repo.requestedPages, [0, 1]);
      expect(cubit.state.events.map((e) => e.occurrenceCode),
          contains('OCC_C'));
      expect(cubit.state.hasMoreEvents, isTrue);
      expect(cubit.state.isLoadingMore, isFalse);

      await cubit.loadMoreEvents();
      expect(repo.requestedPages, [0, 1, 2]);
      expect(cubit.state.hasMoreEvents, isFalse);

      // Exhausted — no further requests.
      await cubit.loadMoreEvents();
      expect(repo.requestedPages, [0, 1, 2]);
    });

    test('page window starts today so pages deliver upcoming rows', () async {
      repo.pageResults = [
        ([_occurrence('A')], false),
      ];
      await cubit.load();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(repo.lastPageFrom, isNotNull);
      expect(repo.lastPageFrom!.isBefore(today), isFalse,
          reason: 'pages over past dates never grow the upcoming list');
    });

    test('pull-to-refresh resets pagination to page 0', () async {
      repo.pageResults = [
        ([_occurrence('A')], true),
        ([_occurrence('B', daysFromNow: 2)], true),
      ];
      await cubit.load();
      await cubit.loadMoreEvents();
      expect(repo.requestedPages, [0, 1]);

      await cubit.load(silent: true);
      expect(repo.requestedPages, [0, 1, 0]);
    });
  });
}
