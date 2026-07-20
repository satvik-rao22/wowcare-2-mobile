import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/domain/features/events/usecases/cancel_occurrence_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/create_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/delete_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/delete_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_event_by_code_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_events_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_holidays_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/update_occurrence_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/respond_to_event_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/save_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/set_holiday_status_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/update_event_usecase.dart';
import 'package:wowcare/presentation/features/events/cubit/events_cubit.dart';

import 'helpers/event_test_fakes.dart';

void main() {
  final int year = DateTime.now().year;

  Holiday holiday({
    required String code,
    required HolidayType type,
    HolidayStatus? status,
    int version = 0,
    DateTime? start,
  }) => Holiday(
    code: code,
    name: code,
    startDate: start ?? DateTime(year, 6, 1),
    endDate: start ?? DateTime(year, 6, 1),
    type: type,
    status: status,
    version: version,
    createdAt: DateTime(year),
    updatedAt: DateTime(year),
  );

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

  group('refreshHolidays', () {
    test('populates state and clears any error', () async {
      repo.nextHolidays = [holiday(code: 'SCH-1', type: HolidayType.school)];
      await cubit.refreshHolidays();
      expect(cubit.state.holidays.map((h) => h.code), ['SCH-1']);
      expect(cubit.state.errorMessage, isNull);
      expect(repo.lastGetYear, year);
    });

    test('records an error message on failure', () async {
      repo.error = Exception('offline');
      await cubit.refreshHolidays();
      expect(cubit.state.errorMessage, contains('Failed to load holidays'));
    });
  });

  group('saveHoliday', () {
    test('empty code routes to create and upserts the result', () async {
      final saved = holiday(code: 'SCH-NEW', type: HolidayType.school);
      repo.nextCreate = (saved, 'School holiday created successfully');

      final draft = holiday(code: '', type: HolidayType.school);
      final (ok, message) = await cubit.saveHoliday(draft);

      expect(ok, isTrue);
      expect(message, 'School holiday created successfully');
      expect(repo.lastCreateArgs, isNotNull);
      expect(repo.lastUpdateArgs, isNull);
      expect(cubit.state.holidays.map((h) => h.code), contains('SCH-NEW'));
      expect(cubit.state.isSaving, isFalse);
    });

    test('non-empty code routes to update with version', () async {
      final saved = holiday(code: 'SCH-1', type: HolidayType.school, version: 3);
      repo.nextUpdate = (saved, 'updated');

      final draft = holiday(code: 'SCH-1', type: HolidayType.school, version: 3);
      final (ok, message) = await cubit.saveHoliday(draft);

      expect(ok, isTrue);
      expect(message, 'updated');
      expect(repo.lastUpdateArgs!['code'], 'SCH-1');
      expect(repo.lastUpdateArgs!['version'], 3);
      expect(repo.lastCreateArgs, isNull);
    });

    test('returns a friendly failure message and resets isSaving', () async {
      repo.error = Exception('500');
      final (ok, message) = await cubit.saveHoliday(
        holiday(code: '', type: HolidayType.school),
      );
      expect(ok, isFalse);
      expect(message, 'Could not save the holiday. Please try again.');
      expect(cubit.state.isSaving, isFalse);
    });
  });

  group('setHolidayStatus', () {
    Future<void> seed(Holiday h) async {
      repo.nextHolidays = [h];
      await cubit.refreshHolidays();
    }

    test('approve maps CONSIDERED to the APPROVE action', () async {
      final pending = holiday(
        code: 'FED-1',
        type: HolidayType.federal,
        status: HolidayStatus.pending,
        version: 2,
      );
      await seed(pending);
      repo.nextStatus = (
        pending.copyWith(status: () => HolidayStatus.considered),
        'approved',
      );

      final (ok, message) = await cubit.setHolidayStatus(
        'FED-1',
        HolidayStatus.considered,
      );

      expect(ok, isTrue);
      expect(message, 'approved');
      expect(repo.lastStatusArgs!['action'], HolidayStatusAction.approve);
      expect(repo.lastStatusArgs!['version'], 2);
      expect(
        cubit.state.holidayByCode('FED-1')!.status,
        HolidayStatus.considered,
      );
    });

    test('reject maps REJECTED to the REJECT action', () async {
      final pending = holiday(
        code: 'FED-1',
        type: HolidayType.federal,
        status: HolidayStatus.pending,
      );
      await seed(pending);
      repo.nextStatus = (
        pending.copyWith(status: () => HolidayStatus.rejected),
        'rejected',
      );

      await cubit.setHolidayStatus('FED-1', HolidayStatus.rejected);
      expect(repo.lastStatusArgs!['action'], HolidayStatusAction.reject);
    });

    test('rejects a status change on a non-federal holiday', () async {
      await seed(holiday(code: 'SCH-1', type: HolidayType.school));
      final (ok, message) = await cubit.setHolidayStatus(
        'SCH-1',
        HolidayStatus.considered,
      );
      expect(ok, isFalse);
      expect(message, 'Holiday not found');
      expect(repo.lastStatusArgs, isNull);
    });

    test('rejects an unknown holiday code', () async {
      final (ok, message) = await cubit.setHolidayStatus(
        'GHOST',
        HolidayStatus.considered,
      );
      expect(ok, isFalse);
      expect(message, 'Holiday not found');
    });

    test('rejects PENDING as a target status', () async {
      await seed(
        holiday(
          code: 'FED-1',
          type: HolidayType.federal,
          status: HolidayStatus.considered,
        ),
      );
      final (ok, message) = await cubit.setHolidayStatus(
        'FED-1',
        HolidayStatus.pending,
      );
      expect(ok, isFalse);
      expect(message, 'Invalid holiday status change');
    });
  });

  group('deleteHoliday', () {
    test('removes the holiday from state on success', () async {
      repo.nextHolidays = [holiday(code: 'SCH-1', type: HolidayType.school)];
      await cubit.refreshHolidays();
      repo.nextDeleteMessage = 'Holiday deleted successfully';

      final (ok, message) = await cubit.deleteHoliday('SCH-1');

      expect(ok, isTrue);
      expect(message, 'Holiday deleted successfully');
      expect(cubit.state.holidays, isEmpty);
      expect(repo.lastDeletedCode, 'SCH-1');
    });

    test('returns a friendly failure message', () async {
      repo.error = Exception('conflict');
      final (ok, message) = await cubit.deleteHoliday('SCH-1');
      expect(ok, isFalse);
      expect(message, 'Could not delete the holiday. Please try again.');
    });
  });

  group('setSelectedYear', () {
    test('reloads holidays scoped to the new year', () async {
      repo.nextHolidays = [
        Holiday(
          code: 'SCH-2028',
          name: 'x',
          startDate: DateTime(2028, 1, 5),
          endDate: DateTime(2028, 1, 5),
          type: HolidayType.school,
          createdAt: DateTime(2028),
          updatedAt: DateTime(2028),
        ),
      ];

      await cubit.setSelectedYear(2028);

      expect(cubit.state.selectedYear, 2028);
      expect(repo.lastGetYear, 2028);
      expect(cubit.state.holidays.map((h) => h.code), contains('SCH-2028'));
      expect(cubit.state.isLoading, isFalse);
    });

    test('is a no-op when the year is unchanged', () async {
      await cubit.setSelectedYear(cubit.state.selectedYear);
      expect(repo.getHolidaysCalls, 0);
    });

    test('failure surfaces an error and stops loading', () async {
      repo.error = Exception('offline');
      await cubit.setSelectedYear(year + 1);
      expect(cubit.state.selectedYear, year + 1);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, contains('Failed to load holidays'));
    });
  });

  group('holiday year caching', () {
    test('load marks the selected year as fetched', () async {
      repo.nextHolidays = [holiday(code: 'SCH-1', type: HolidayType.school)];
      await cubit.load();
      expect(cubit.state.holidays.map((h) => h.code), ['SCH-1']);

      final calls = repo.getHolidaysCalls;
      await cubit.ensureHolidaysForYear(year);
      expect(
        repo.getHolidaysCalls,
        calls,
        reason: 'an already-loaded year must not refetch',
      );
    });

    test('ensureHolidaysForYear fetches a new year once, keeping loaded '
        'years', () async {
      repo.nextHolidays = [holiday(code: 'CUR', type: HolidayType.school)];
      await cubit.refreshHolidays();

      repo.nextHolidays = [
        holiday(
          code: 'NEXT',
          type: HolidayType.school,
          start: DateTime(year + 1, 1, 5),
        ),
      ];
      await cubit.ensureHolidaysForYear(year + 1);

      expect(
        cubit.state.holidays.map((h) => h.code),
        containsAll(['CUR', 'NEXT']),
      );

      final calls = repo.getHolidaysCalls;
      await cubit.ensureHolidaysForYear(year + 1);
      expect(repo.getHolidaysCalls, calls);
    });

    test('ensureHolidaysForYear fails silently and retries on the next call',
        () async {
      repo.error = Exception('offline');
      await cubit.ensureHolidaysForYear(year + 2);
      // Background pre-fetch: no error banner.
      expect(cubit.state.errorMessage, isNull);

      // The failed year was not marked loaded, so the next call refetches.
      repo.error = null;
      repo.nextHolidays = [
        holiday(
          code: 'LATER',
          type: HolidayType.school,
          start: DateTime(year + 2, 1, 5),
        ),
      ];
      await cubit.ensureHolidaysForYear(year + 2);
      expect(cubit.state.holidays.map((h) => h.code), contains('LATER'));
    });

    test('refreshHolidays replaces only the selected year', () async {
      repo.nextHolidays = [
        holiday(
          code: 'NEXT',
          type: HolidayType.school,
          start: DateTime(year + 1, 1, 5),
        ),
      ];
      await cubit.ensureHolidaysForYear(year + 1);

      repo.nextHolidays = [holiday(code: 'CUR', type: HolidayType.school)];
      await cubit.refreshHolidays();
      expect(
        cubit.state.holidays.map((h) => h.code),
        containsAll(['NEXT', 'CUR']),
      );

      // An empty refetch clears the selected year but keeps other years.
      repo.nextHolidays = const [];
      await cubit.refreshHolidays();
      expect(cubit.state.holidays.map((h) => h.code).toList(), ['NEXT']);
    });

    test('saveHoliday keeps the list sorted by start date (FR-HL-09)',
        () async {
      repo.nextHolidays = [
        holiday(
          code: 'DEC',
          type: HolidayType.school,
          start: DateTime(year, 12, 10),
        ),
        holiday(
          code: 'JAN',
          type: HolidayType.school,
          start: DateTime(year, 1, 10),
        ),
      ];
      await cubit.refreshHolidays();

      repo.nextCreate = (
        holiday(
          code: 'JUN',
          type: HolidayType.school,
          start: DateTime(year, 6, 10),
        ),
        'created',
      );
      await cubit.saveHoliday(holiday(code: '', type: HolidayType.school));

      expect(
        cubit.state.holidays.map((h) => h.code).toList(),
        ['JAN', 'JUN', 'DEC'],
      );
    });
  });
}
