import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/events/models/holiday_models.dart';
import 'package:wowcare/data/features/events/repositories/event_repository_impl.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';

import '../../../../presentation/features/events/helpers/event_test_fakes.dart';

HolidayModel _model({
  required String code,
  required DateTime start,
  String type = 'SCHOOL',
}) => HolidayModel(
  code: code,
  name: code,
  startDate: start,
  endDate: start,
  type: type,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late FakeHolidayRemoteDataSource holidayDs;
  late EventRepositoryImpl repo;

  setUp(() {
    holidayDs = FakeHolidayRemoteDataSource();
    repo = EventRepositoryImpl(StubEventRemoteDataSource(), holidayDs);
  });

  test('getHolidays maps models to entities and sorts by start date', () async {
    holidayDs.nextHolidays = [
      _model(code: 'C', start: DateTime(2026, 12, 1)),
      _model(code: 'A', start: DateTime(2026, 1, 1)),
      _model(code: 'B', start: DateTime(2026, 6, 1)),
    ];

    final result = await repo.getHolidays(year: 2026);

    expect(result.map((h) => h.code).toList(), ['A', 'B', 'C']);
    expect(result.first, isA<Holiday>());
    expect(holidayDs.lastGetYear, 2026);
  });

  test('getHolidays returns an empty list when the source is empty', () async {
    holidayDs.nextHolidays = const [];
    expect(await repo.getHolidays(), isEmpty);
  });

  test('createHoliday forwards args and maps the model + message', () async {
    holidayDs.nextCreate = (
      _model(code: 'NEW', start: DateTime(2026, 3, 1)),
      'School holiday created successfully',
    );

    final (holiday, message) = await repo.createHoliday(
      name: 'Founders Day',
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 3, 1),
      description: 'desc',
    );

    expect(holiday, isA<Holiday>());
    expect(holiday.code, 'NEW');
    expect(message, 'School holiday created successfully');
    expect(holidayDs.lastCreateArgs!['name'], 'Founders Day');
    expect(holidayDs.lastCreateArgs!['description'], 'desc');
  });

  test('updateHoliday forwards code/version and maps result', () async {
    holidayDs.nextUpdate = (
      _model(code: 'HOL-1', start: DateTime(2026, 4, 1)),
      'updated',
    );

    final (holiday, message) = await repo.updateHoliday(
      code: 'HOL-1',
      version: 2,
      name: 'Renamed',
    );

    expect(holiday.code, 'HOL-1');
    expect(message, 'updated');
    expect(holidayDs.lastUpdateArgs!['version'], 2);
  });

  test('setHolidayStatus forwards the action and maps result', () async {
    holidayDs.nextStatus = (
      _model(code: 'FED-1', start: DateTime(2026, 7, 4), type: 'FEDERAL'),
      'approved',
    );

    final (holiday, message) = await repo.setHolidayStatus(
      code: 'FED-1',
      version: 1,
      action: HolidayStatusAction.approve,
    );

    expect(holiday.type, HolidayType.federal);
    expect(message, 'approved');
    expect(holidayDs.lastStatusArgs!['action'], HolidayStatusAction.approve);
  });

  test('deleteHoliday trims the code before delegating', () async {
    holidayDs.nextDeleteMessage = 'removed';
    final message = await repo.deleteHoliday('  HOL-1  ');
    expect(message, 'removed');
    expect(holidayDs.lastDeletedCode, 'HOL-1');
  });
}
