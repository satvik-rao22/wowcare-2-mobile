import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/domain/features/events/usecases/delete_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/get_holidays_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/save_holiday_usecase.dart';
import 'package:wowcare/domain/features/events/usecases/set_holiday_status_usecase.dart';

import 'helpers/event_test_fakes.dart';

Holiday _holiday({String code = 'HOL-1'}) => Holiday(
  code: code,
  name: 'Test',
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 1),
  type: HolidayType.school,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late FakeEventRepository repo;

  setUp(() => repo = FakeEventRepository());

  test('GetHolidaysUseCase forwards the year and returns the repo result', () async {
    repo.nextHolidays = [_holiday()];
    final result = await GetHolidaysUseCase(repo)(year: 2026);
    expect(result, repo.nextHolidays);
    expect(repo.lastGetYear, 2026);
  });

  test('CreateHolidayUseCase forwards every argument', () async {
    repo.nextCreate = (_holiday(), 'created');
    final start = DateTime(2026, 5, 1);
    final end = DateTime(2026, 5, 3);
    final (holiday, message) = await CreateHolidayUseCase(repo)(
      name: 'Field Trip',
      startDate: start,
      endDate: end,
      description: 'desc',
    );

    expect(message, 'created');
    expect(holiday.code, 'HOL-1');
    expect(repo.lastCreateArgs, {
      'name': 'Field Trip',
      'startDate': start,
      'endDate': end,
      'description': 'desc',
    });
  });

  test('UpdateHolidayUseCase forwards code, version and partial fields', () async {
    repo.nextUpdate = (_holiday(), 'updated');
    final (_, message) = await UpdateHolidayUseCase(repo)(
      code: 'HOL-9',
      version: 4,
      name: 'Renamed',
    );

    expect(message, 'updated');
    expect(repo.lastUpdateArgs!['code'], 'HOL-9');
    expect(repo.lastUpdateArgs!['version'], 4);
    expect(repo.lastUpdateArgs!['name'], 'Renamed');
    expect(repo.lastUpdateArgs!['startDate'], isNull);
  });

  test('SetHolidayStatusUseCase forwards the action', () async {
    repo.nextStatus = (_holiday(), 'status changed');
    final (_, message) = await SetHolidayStatusUseCase(repo)(
      code: 'FED-1',
      version: 2,
      action: HolidayStatusAction.approve,
    );

    expect(message, 'status changed');
    expect(repo.lastStatusArgs, {
      'code': 'FED-1',
      'version': 2,
      'action': HolidayStatusAction.approve,
    });
  });

  test('DeleteHolidayUseCase forwards the code and returns the message', () async {
    repo.nextDeleteMessage = 'gone';
    final message = await DeleteHolidayUseCase(repo)('HOL-1');
    expect(message, 'gone');
    expect(repo.lastDeletedCode, 'HOL-1');
  });

  test('use-cases propagate repository errors', () async {
    repo.error = Exception('boom');
    expect(() => GetHolidaysUseCase(repo)(), throwsA(isA<Exception>()));
    expect(() => DeleteHolidayUseCase(repo)('x'), throwsA(isA<Exception>()));
  });
}
