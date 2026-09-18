import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';
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
import 'package:wowcare/presentation/features/events/view_model/events_cubit.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_manager.dart';

import '../helpers/event_test_fakes.dart';

/// `loadCalendarFeed` caches by month + scope and returns early for a month it
/// has already fetched. That cache is why a newly created event never appeared
/// on the calendar: the form refreshed the occurrence lists, the feed skipped
/// its refetch, and the day list kept rendering the stale month.
///
/// `resetCalendarFeed()` is the only way out, so these lock in that it really
/// drops the cache — if the dedupe ever stops honouring the reset, the bug is
/// back and no screen-level change will save it.
class _FakeUploadManager implements AttachmentUploadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CalendarFeedItem _row(String code, DateTime date) => CalendarFeedItem(
  kind: CalendarFeedKind.event,
  code: code,
  name: code,
  date: date,
  allDay: true,
);

void main() {
  late FakeEventRepository repo;
  late EventsCubit cubit;

  EventsCubit build() => EventsCubit(
    GetEventsUseCase(repo),
    GetEventByCodeUseCase(repo),
    GetCalendarFeedUseCase(repo),
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
    UploadEventAttachmentsUseCase(repo, _FakeUploadManager()),
  );

  final month = DateTime(2026, 9, 1);
  final day = DateTime(2026, 9, 18);

  setUp(() {
    repo = FakeEventRepository();
    cubit = build();
  });

  tearDown(() => cubit.close());

  test('the same month is fetched once, however often it is asked for',
      () async {
    await cubit.loadCalendarFeed(month, scope: 'ALL_ITEMS');
    await cubit.loadCalendarFeed(month, scope: 'ALL_ITEMS');
    await cubit.loadCalendarFeed(DateTime(2026, 9, 30), scope: 'ALL_ITEMS');

    expect(repo.calendarFeedCalls, 1,
        reason: 'the month cache is what makes a stale calendar possible');
  });

  test('a different scope is a different cache key', () async {
    await cubit.loadCalendarFeed(month, scope: 'ALL_ITEMS');
    await cubit.loadCalendarFeed(month, scope: 'MY_ITEMS');

    expect(repo.calendarFeedCalls, 2);
  });

  test('resetCalendarFeed makes the next load refetch the same month',
      () async {
    await cubit.loadCalendarFeed(month, scope: 'ALL_ITEMS');
    expect(repo.calendarFeedCalls, 1);

    // What the screen does after creating or editing an event.
    cubit.resetCalendarFeed();
    await cubit.loadCalendarFeed(month, scope: 'ALL_ITEMS');

    expect(repo.calendarFeedCalls, 2,
        reason: 'without this a new event never reaches the calendar');
  });

  test('an event created after the month was cached shows up once reset',
      () async {
    await cubit.loadCalendarFeed(month, scope: 'ALL_ITEMS');
    expect(cubit.state.calendarItemsOn(day,
        allowedKinds: const {CalendarFeedKind.event}), isEmpty);

    // The backend now has the row, but the cached month hides it.
    repo.calendarFeedRows = [_row('EVT_NEW', day)];
    await cubit.loadCalendarFeed(month, scope: 'ALL_ITEMS');
    expect(
      cubit.state.calendarItemsOn(day,
          allowedKinds: const {CalendarFeedKind.event}),
      isEmpty,
      reason: 'this is the bug, reproduced: the cache swallows the refetch',
    );

    cubit.resetCalendarFeed();
    await cubit.loadCalendarFeed(month, scope: 'ALL_ITEMS');
    expect(
      cubit.state
          .calendarItemsOn(day, allowedKinds: const {CalendarFeedKind.event})
          .map((i) => i.code),
      <String>['EVT_NEW'],
    );
  });

  test('a failed fetch does not poison the cache', () async {
    repo.error = Exception('feed unavailable');
    await cubit.loadCalendarFeed(month, scope: 'ALL_ITEMS');
    expect(cubit.state.calendarLoading, isFalse);

    // The month must still be retryable — the key is released on failure.
    repo.error = null;
    repo.calendarFeedRows = [_row('EVT_RETRY', day)];
    await cubit.loadCalendarFeed(month, scope: 'ALL_ITEMS');

    expect(
      cubit.state
          .calendarItemsOn(day, allowedKinds: const {CalendarFeedKind.event})
          .map((i) => i.code),
      <String>['EVT_RETRY'],
    );
  });
}
