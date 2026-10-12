import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/scheduling/entities/staff_shift.dart';
import 'package:wowcare/domain/features/scheduling/repositories/staff_shift_repository.dart';
import 'package:wowcare/domain/features/scheduling/usecases/create_staff_shift_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/delete_staff_shift_series_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/publish_staff_shifts_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/update_staff_shift_usecase.dart';

const _createResult = StaffShiftCreateResult(
  createdCount: 3,
  skippedCount: 0,
  overriddenCount: 0,
);

final _shift = StaffShift(
  shiftCode: 'SHF-1',
  staffCode: 'STF-1',
  classroomCode: 'CLS-1',
  shiftDate: DateTime(2026, 10, 12),
  startTime: const TimeOfDay(hour: 8, minute: 0),
  endTime: const TimeOfDay(hour: 16, minute: 0),
);

class _FakeStaffShiftRepository implements StaffShiftRepository {
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final error = this.error;
    switch (invocation.memberName) {
      case #createStaffShift:
      case #updateStaffShiftSeries:
        return error == null
            ? Future.value(_createResult)
            : Future<StaffShiftCreateResult>.error(error);
      case #updateStaffShift:
        return error == null
            ? Future.value(_shift)
            : Future<StaffShift>.error(error);
      default:
        return error == null ? Future<void>.value() : Future<void>.error(error);
    }
  }
}

DioException _status(int code) {
  final request = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: code,
    requestOptions: request,
    response: Response<dynamic>(requestOptions: request, statusCode: code),
  );
}

void main() {
  final logs = <SentryLog>[];
  late _FakeStaffShiftRepository repo;

  setUp(() async {
    logs.clear();
    repo = _FakeStaffShiftRepository();
    await Sentry.init((options) {
      options
        ..dsn = 'https://key@o1.ingest.sentry.io/1'
        ..enableLogs = true
        ..transport = _DiscardingTransport()
        ..beforeSendLog = (log) {
          logs.add(log);
          return log;
        };
    });
  });

  tearDown(() => Sentry.close());

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  void expectNoPersonalData() {
    for (final log in logs) {
      // The SDK adds its own `os.*` and `sentry.*` attributes.
      expect(
        log.attributes.keys.where(
          (key) => !key.startsWith('os.') && !key.startsWith('sentry.'),
        ),
        everyElement(
          isIn(const ['event', 'outcome', 'failure', 'count', 'duration_ms']),
        ),
      );
      expect(
        log.attributes.values.map((a) => '${a.value}'),
        isNot(
          contains(
            anyOf(
              'SHF-1',
              'SRS-1',
              'STF-1',
              'STF-2',
              'CLS-1',
              'SCH-1',
              'ORG-1',
            ),
          ),
        ),
      );
    }
  }

  test('create logs success and hands the result back untouched', () async {
    final result = await CreateStaffShiftUseCase(repo)(
      StaffShiftCreateRequest(
        staffCode: 'STF-1',
        classroomCode: 'CLS-1',
        schoolCode: 'SCH-1',
        organizationCode: 'ORG-1',
        shiftDate: DateTime(2026, 10, 12),
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
      ),
    );
    await settle();

    expect(result, _createResult);
    expect(logs.single.body, 'scheduling.shift_create.succeeded');
    // The count comes from the result: shifts the repeat rule created.
    expect(logs.single.attributes['count']?.value, 3);
    expectNoPersonalData();
  });

  test('update logs success', () async {
    final result = await UpdateStaffShiftUseCase(repo)(
      StaffShiftUpdateRequest(
        shiftCode: 'SHF-1',
        staffCode: 'STF-1',
        schoolCode: 'SCH-1',
        organizationCode: 'ORG-1',
        classroomCode: 'CLS-1',
        shiftDate: DateTime(2026, 10, 12),
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
      ),
    );
    await settle();

    expect(result, _shift);
    expect(logs.single.body, 'scheduling.shift_update.succeeded');
    expectNoPersonalData();
  });

  test('a thrown error is bucketed and rethrown with its type', () async {
    repo.error = _status(403);

    await expectLater(
      DeleteStaffShiftSeriesUseCase(repo)(
        seriesCode: 'SRS-1',
        staffCode: 'STF-1',
      ),
      throwsA(isA<DioException>()),
    );
    await settle();

    expect(logs.single.body, 'scheduling.shift_series_delete.failed');
    expect(logs.single.attributes['failure']!.value, 'forbidden');
    expectNoPersonalData();
  });

  test('publish logs success without the staff selection', () async {
    await PublishStaffShiftsUseCase(repo)(
      schoolCode: 'SCH-1',
      organizationCode: 'ORG-1',
      dateRangeStart: DateTime(2026, 10, 12),
      publishAll: false,
      publishAllStaff: false,
      publishUntilDate: DateTime(2026, 10, 18),
      selectedStaffCodes: const ['STF-1', 'STF-2'],
    );
    await settle();

    expect(logs.single.body, 'scheduling.shift_publish.succeeded');
    expectNoPersonalData();
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
