import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_regularization/core/errors/reg_exceptions.dart';
import 'package:wowcare/modules/attendance_regularization/core/utils/reg_time_zone.dart';
import 'package:wowcare/modules/attendance_regularization/data/datasources/reg_remote_datasource.dart';
import 'package:wowcare/modules/attendance_regularization/data/mappers/reg_mappers.dart';
import 'package:wowcare/modules/attendance_regularization/data/reg_context.dart';
import 'package:wowcare/modules/attendance_regularization/data/repositories/regularization_repository_impl.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/reg_edit_input.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/reg_raise_input.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/regularization_request.dart';
import 'package:wowcare/modules/attendance_regularization/domain/repositories/regularization_repository.dart';

import 'support/fake_api.dart';

/// Data layer against the **real** datasource, mappers and repository, driven
/// by a Dio adapter replaying the contract's own JSON.
void main() {
  const zone = 'America/New_York';

  late FakeApi api;
  late RegularizationRepository repo;

  setUp(() {
    api = FakeApi();
    repo = RegularizationRepositoryImpl(
      RegRemoteDataSource(api.dio),
      const RegStaticContext(zone: zone),
    );
  });

  group('checkGate', () {
    test('a self-check sends an empty body', () async {
      api.onPost('/open-sessions/check', FakeApi.gateClear);
      final gate = await repo.checkGate();

      expect(api.lastBody, isEmpty);
      expect(gate.hasBlocked, isFalse);
      expect(gate.clear, ['STF_0008', 'STF_0009']);
    });

    test('a roster check names the staff', () async {
      api.onPost('/open-sessions/check', FakeApi.gateClear);
      await repo.checkGate(staffCodes: ['STF_A', 'STF_B']);

      expect(api.lastBody['staffCodes'], ['STF_A', 'STF_B']);
    });

    test('a blocked day maps every field the sheet needs', () async {
      api.onPost('/open-sessions/check', FakeApi.gateBlocked);
      final blocked = (await repo.checkGate()).blocked.single;

      expect(blocked.staffCode, 'STF_0007');
      expect(blocked.staffName, 'Mohan Sonone');
      expect(blocked.attendanceCode, 'SAR_10231');
      expect(blocked.attendanceDate, DateTime(2026, 6, 23));
      expect(blocked.classroomCode, 'CLS_0002');
      expect(blocked.hasPendingRequest, isFalse);
      expect(blocked.pendingRequestCode, isNull);
      expect(blocked.blocksSignIn, isTrue);
      // 13:30Z is 09:30 in New York on that date.
      expect(blocked.suggestedSignOutTime!.hour, 9);
      expect(blocked.suggestedSignOutTime!.minute, 30);
    });

    test('an already-raised day routes to edit, not a duplicate create',
        () async {
      api.onPost('/open-sessions/check', FakeApi.gateAlreadyRaised);
      final blocked = (await repo.checkGate()).blocked.single;

      expect(blocked.hasPendingRequest, isTrue);
      expect(blocked.blocksSignIn, isFalse);
      expect(blocked.resolvesByEdit, isTrue);
      expect(blocked.pendingRequestCode, 'SREG_0000001');
    });
  });

  group('raise', () {
    RegRaiseInput input({String reason = 'Stayed for parent meeting.'}) =>
        RegRaiseInput(
          staffCode: 'STF_0007',
          attendanceCode: 'SAR_10231',
          attendanceDate: DateTime(2026, 6, 23),
          signOutLocal: DateTime(2026, 6, 23, 9, 30),
          reason: reason,
        );

    test('sends the contract payload and no timeZone', () async {
      api.onPost('/staff-attendance-regularizations', FakeApi.raisedPending);
      await repo.raise(input());

      expect(api.lastBody, {
        'staffCode': 'STF_0007',
        'attendanceCode': 'SAR_10231',
        'attendanceDate': '2026-06-23',
        'requestedSignOutTime': '2026-06-23T13:30:00.000Z',
        'reason': 'Stayed for parent meeting.',
        'method': 'APP',
      });
    });

    test('staff-raised comes back PENDING', () async {
      api.onPost('/staff-attendance-regularizations', FakeApi.raisedPending);
      final request = await repo.raise(input());

      expect(request.status, RegStatus.pending);
      expect(request.autoApproved, isFalse);
      expect(request.isEditable, isTrue);
      expect(request.approvedSignOutTime, isNull);
    });

    test('admin-raised comes back APPROVED and auto-approved', () async {
      // Same call, same payload — only the token differed.
      api.onPost('/staff-attendance-regularizations', FakeApi.raisedApproved);
      final request = await repo.raise(input());

      expect(request.status, RegStatus.approved);
      expect(request.autoApproved, isTrue);
      expect(request.isEditable, isFalse);
      expect(request.approvedSignOutTime, isNotNull);
    });

    test('method is overridable for kiosk', () async {
      api.onPost('/staff-attendance-regularizations', FakeApi.raisedPending);
      await repo.raise(input(), method: 'KIOSK');
      expect(api.lastBody['method'], 'KIOSK');
    });

    test('a server validation failure surfaces', () async {
      api.onPostError('/staff-attendance-regularizations', 400,
          {'error': {'code': 'VALIDATION_ERROR'}});
      await expectLater(
          repo.raise(input(reason: '   ')), throwsA(isA<DioException>()));
    });
  });

  group('raiseBatch', () {
    RegRaiseInput item(String staff, String code, int hour, String reason) =>
        RegRaiseInput(
          staffCode: staff,
          attendanceCode: code,
          attendanceDate: DateTime(2026, 6, 23),
          signOutLocal: DateTime(2026, 6, 23, hour, 30),
          reason: reason,
        );

    test('a per-item reason is sent only when it differs from the shared one',
        () async {
      api.onPost('/raise-batch', FakeApi.batchApplied);
      await repo.raiseBatch(
        [
          item('STF_A', 'SAR_A', 9, 'Closed by admin.'),
          item('STF_B', 'SAR_B', 8, 'Left early for a site visit.'),
        ],
        sharedReason: 'Closed by admin.',
      );

      final items = api.lastBody['items'] as List;
      expect(api.lastBody['reason'], 'Closed by admin.');
      expect((items[0] as Map).containsKey('reason'), isFalse);
      expect((items[1] as Map)['reason'], 'Left early for a site visit.');
      expect(api.lastBody.containsKey('timeZone'), isFalse);
    });

    test('skipped items carry both identifiers', () async {
      api.onPost('/raise-batch', FakeApi.batchApplied);
      final result = await repo.raiseBatch(
        [item('STF_A', 'SAR_A', 9, 'r')],
        sharedReason: 'r',
      );

      expect(result.applied, 9);
      expect(result.skippedAttendanceCodes, {'SAR_10240'});
      expect(result.skippedCodes, {'SREG_0000031'});
      expect(result.summary, '9 approved · 1 skipped — already resolved');
    });

    test('an empty batch does not hit the network', () async {
      expect((await repo.raiseBatch([], sharedReason: 'r')).applied, 0);
      expect(api.calls, isEmpty);
    });
  });

  group('getRequests', () {
    test('staff send no scope at all — the token decides', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);
      await repo.getRequests();

      expect(api.lastQuery.containsKey('staffCode'), isFalse);
      expect(api.lastQuery.containsKey('schoolCode'), isFalse);
      expect(api.lastQuery['page'], 0);
      expect(api.lastQuery['sort'], 'createdAt,desc');
    });

    test('the inbox filters by status and can read oldest-first', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);
      await repo.getRequests(
        status: RegStatus.pending,
        sort: RegSortOrder.oldestFirst,
      );

      expect(api.lastQuery['status'], 'PENDING');
      expect(api.lastQuery['sort'], 'createdAt,asc');
    });

    test('maps the page and trusts the server hasNext', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);
      final page = await repo.getRequests();

      expect(page.items.length, 1);
      expect(page.total, 2);
      expect(page.hasMore, isFalse);
      expect(page.items.single.staffName, 'Mohan Sonone');
    });

    test('a name lookup failure leaves the code standing in', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listNoStaffName);
      // An approval queue must not go down because a name lookup did.
      expect((await repo.getRequests()).items.single.staffName, 'STF_0007');
    });
  });

  group('approve', () {
    test('an empty body approves as submitted', () async {
      api.onPost('/approve', FakeApi.approvedAsSubmitted);
      final request = await repo.approve('SREG_0000001');

      expect(api.lastBody, isEmpty);
      expect(request.status, RegStatus.approved);
      expect(request.wasModified, isFalse);
      expect(request.autoApproved, isFalse);
    });

    test('a modified time keeps both numbers', () async {
      api.onPost('/approve', FakeApi.approvedModified);
      final request = await repo.approve(
        'SREG_0000001',
        signOutLocal: DateTime(2026, 6, 23, 8, 15),
        note: 'Gate log shows 5:45 PM.',
      );

      expect(api.lastBody['signOutTime'], '2026-06-23T12:15:00.000Z');
      expect(api.lastBody['note'], 'Gate log shows 5:45 PM.');
      expect(request.wasModified, isTrue);
      expect(request.requestedSignOutTime.hour, 9);
      expect(request.approvedSignOutTime!.hour, 8);
      expect(request.approvalNote, 'Gate log shows 5:45 PM.');
    });
  });

  group('approveSelected', () {
    test('sends codes only', () async {
      api.onPost('/approve-selected', FakeApi.approveSelected);
      await repo.approveSelected(['SREG_0000001', 'SREG_0000004']);

      expect(api.lastBody, {
        'codes': ['SREG_0000001', 'SREG_0000004']
      });
    });

    test('already-decided items are skipped, not errors', () async {
      api.onPost('/approve-selected', FakeApi.approveSelected);
      final result = await repo.approveSelected(['SREG_0000001']);

      expect(result.applied, 1);
      expect(result.skippedCodes, {'SREG_0000004'});
    });

    test('an empty selection does not hit the network', () async {
      await repo.approveSelected([]);
      expect(api.calls, isEmpty);
    });
  });

  group('edit', () {
    RegEditInput edit({String? reason, DateTime? at}) => RegEditInput(
          code: 'SREG_0000001',
          attendanceDate: DateTime(2026, 6, 23),
          reason: reason,
          signOutLocal: at,
        );

    test('sends only the changed fields', () async {
      api.onPatch('/staff-attendance-regularizations', FakeApi.raisedPending);
      await repo.edit(edit(reason: 'Corrected.'));

      expect(api.lastBody, {'reason': 'Corrected.'});
    });

    test('a time-only edit sends no timeZone', () async {
      api.onPatch('/staff-attendance-regularizations', FakeApi.raisedPending);
      await repo.edit(edit(at: DateTime(2026, 6, 23, 9, 45)));

      expect(api.lastBody.keys, ['requestedSignOutTime']);
    });

    test('a 409 becomes a typed error the UI can state plainly', () async {
      api.onPatchError('/staff-attendance-regularizations', 409, {
        'error': {
          'code': 'REGULARIZATION_ALREADY_APPROVED',
          'rejectedValue': {'code': 'SREG_0000001', 'status': 'APPROVED'},
        }
      });

      await expectLater(repo.edit(edit(reason: 'Too late.')),
          throwsA(isA<RegAlreadyApprovedException>()));
    });

    test('an unrelated failure is not disguised as already-approved', () async {
      api.onPatchError('/staff-attendance-regularizations', 500, null);
      await expectLater(
          repo.edit(edit(reason: 'x')), throwsA(isA<DioException>()));
    });
  });

  group('RegTimeZone', () {
    test('UTC in, school-local wall clock out', () {
      final local = RegTimeZone.schoolLocal('2026-06-23T22:30:00Z', zone);
      expect(local!.hour, 18);
      expect(local.minute, 30);
      expect(local.day, 23);
    });

    test('round-trips a wall-clock time', () {
      final iso = RegTimeZone.toUtcIso(DateTime(2026, 6, 23, 18, 30), zone);
      expect(RegTimeZone.schoolLocal(iso, zone)!.hour, 18);
    });

    test('crosses the date boundary correctly', () {
      final local = RegTimeZone.schoolLocal('2026-06-24T02:00:00Z', zone);
      expect(local!.day, 23);
      expect(local.hour, 22);
    });

    test('uses the IANA database, not a fixed offset', () {
      expect(RegTimeZone.schoolLocal('2026-01-15T22:30:00Z', zone)!.hour, 17);
      expect(RegTimeZone.schoolLocal('2026-06-15T22:30:00Z', zone)!.hour, 18);
    });

    test('null and unparseable input yield null', () {
      expect(RegTimeZone.schoolLocal(null, zone), isNull);
      expect(RegTimeZone.schoolLocal('not-a-date', zone), isNull);
    });

    test('dates carry no time component', () {
      expect(RegTimeZone.dateOnly('2026-08-03'), DateTime(2026, 8, 3));
      expect(RegTimeZone.dateToWire(DateTime(2026, 8, 3)), '2026-08-03');
      expect(RegTimeZone.dateToWire(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });

  group('RegMappers envelopes', () {
    test('reads data.content and a bare data list', () {
      expect(
        RegMappers.listOf({
          'data': {'content': [{'code': 'A'}, {'code': 'B'}]}
        }).length,
        2,
      );
      expect(RegMappers.listOf({'data': [{'code': 'A'}]}).length, 1);
    });

    test('an unrecognised shape yields empty rather than throwing', () {
      expect(RegMappers.listOf({'data': 42}), isEmpty);
      expect(RegMappers.listOf(null), isEmpty);
    });

    test('an empty page never reports more, whatever hasNext says', () {
      final page = RegMappers.toPage({
        'data': {'content': [], 'totalElements': 99, 'hasNext': true}
      }, zone: zone, page: 0, size: 20);
      // Otherwise "load more" would loop forever.
      expect(page.hasMore, isFalse);
    });

    test('an unknown status throws rather than rendering an Approve button',
        () {
      expect(
        () => RegMappers.toRequest(FakeApi.rawRequest('CANCELLED'), zone: zone),
        throwsArgumentError,
      );
    });
  });
}
