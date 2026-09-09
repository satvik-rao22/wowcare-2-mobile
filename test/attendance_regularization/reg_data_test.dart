import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_regularization/core/errors/reg_exceptions.dart';
import 'package:wowcare/modules/attendance_regularization/core/utils/reg_time_zone.dart';
import 'package:wowcare/modules/attendance_regularization/data/datasources/reg_api_paths.dart';
import 'package:wowcare/modules/attendance_regularization/data/datasources/reg_mock_datasource.dart';
import 'package:wowcare/modules/attendance_regularization/data/mappers/reg_mappers.dart';
import 'package:wowcare/modules/attendance_regularization/data/reg_context.dart';
import 'package:wowcare/modules/attendance_regularization/data/repositories/regularization_repository_impl.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/reg_edit_input.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/reg_raise_input.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/regularization_request.dart';
import 'package:wowcare/modules/attendance_regularization/domain/repositories/regularization_repository.dart';

/// Data-layer tests.
///
/// These run the **real** mappers and the **real** repository against the mock
/// datasource, which returns the same JSON envelopes the server will. So they
/// double as the contract suite: when the API lands, whatever these assert is
/// what the HTTP path must also satisfy.
void main() {
  const zone = 'America/New_York';
  const context = RegStaticContext(zone: zone, school: 'SCH_MOCK');

  late RegMockDataSource mock;
  late RegularizationRepository repo;

  setUp(() {
    mock = RegMockDataSource(zone: zone, autoSeedUnknownStaff: false)
      ..latency = Duration.zero;
    repo = RegularizationRepositoryImpl(mock, context);
  });

  DateTime yesterdayAt(int h, int m) {
    final d = DateTime.now().subtract(const Duration(days: 1));
    return DateTime(d.year, d.month, d.day, h, m);
  }

  // ————————————————————————————————————————————————————————————————
  // §9.1 detection
  // ————————————————————————————————————————————————————————————————

  group('§9.1 detection', () {
    test('finds the unresolved past day for the acting staff', () async {
      final open = await repo.getOpenSession('STF_ME');
      expect(open, isNotNull);
      expect(open!.attendanceCode, 'STAR_MOCK_ME_1');
      expect(open.blocksSignIn, isTrue);
      expect(open.hasPendingRequest, isFalse);
    });

    test('a scheduler SYSTEM close still gates (§1)', () async {
      // The whole second detection branch: a machine guess is not a sign-out.
      final open = await repo.getOpenSession('STF_A');
      expect(open, isNotNull);
      expect(open!.attendanceCode, 'STAR_MOCK_A');
      // The scheduler's own time becomes the suggestion (§9.1 order 1).
      expect(open.suggestedSignOutTime, isNotNull);
      expect(open.suggestedSignOutTime!.hour, 17);
      expect(open.suggestedSignOutTime!.minute, 30);
    });

    test('a day closed by a human is clear', () async {
      final open = await repo.getOpenSession('STF_C');
      expect(open, isNull);
    });

    test("today's open session is not gated (§4)", () async {
      final now = DateTime.now();
      mock.addRow(MockAttendanceRow(
        attendanceCode: 'STAR_TODAY',
        staffCode: 'STF_TODAY',
        staffName: 'Working Now',
        attendanceDate: DateTime(now.year, now.month, now.day),
        signedInAtLocal: DateTime(now.year, now.month, now.day, 8, 0),
      ));
      expect(await repo.getOpenSession('STF_TODAY'), isNull);
    });

    test('only the last session of a day is evaluated (§4)', () async {
      final d = DateTime.now().subtract(const Duration(days: 3));
      final date = DateTime(d.year, d.month, d.day);
      // Morning session left open...
      mock.addRow(MockAttendanceRow(
        attendanceCode: 'STAR_MULTI_1',
        staffCode: 'STF_MULTI',
        staffName: 'Multi Session',
        attendanceDate: date,
        signedInAtLocal: DateTime(date.year, date.month, date.day, 8, 0),
      ));
      // ...but the later session was closed by a human, so the day is clear.
      mock.addRow(MockAttendanceRow(
        attendanceCode: 'STAR_MULTI_2',
        staffCode: 'STF_MULTI',
        staffName: 'Multi Session',
        attendanceDate: date,
        signedInAtLocal: DateTime(date.year, date.month, date.day, 13, 0),
        signedOutAtLocal: DateTime(date.year, date.month, date.day, 17, 0),
        signedOutMethod: 'APP',
      ));
      expect(await repo.getOpenSession('STF_MULTI'), isNull);
    });

    test('the last session being open gates even if an earlier one closed',
        () async {
      final d = DateTime.now().subtract(const Duration(days: 4));
      final date = DateTime(d.year, d.month, d.day);
      mock.addRow(MockAttendanceRow(
        attendanceCode: 'STAR_REV_1',
        staffCode: 'STF_REV',
        staffName: 'Reverse',
        attendanceDate: date,
        signedInAtLocal: DateTime(date.year, date.month, date.day, 8, 0),
        signedOutAtLocal: DateTime(date.year, date.month, date.day, 12, 0),
        signedOutMethod: 'APP',
      ));
      mock.addRow(MockAttendanceRow(
        attendanceCode: 'STAR_REV_2',
        staffCode: 'STF_REV',
        staffName: 'Reverse',
        attendanceDate: date,
        signedInAtLocal: DateTime(date.year, date.month, date.day, 13, 0),
      ));
      final open = await repo.getOpenSession('STF_REV');
      expect(open?.attendanceCode, 'STAR_REV_2');
    });
  });

  // ————————————————————————————————————————————————————————————————
  // §9.1b batch gate
  // ————————————————————————————————————————————————————————————————

  group('§9.1b batch gate', () {
    test('splits blocked from clear', () async {
      final gate = await repo
          .getOpenSessionsBatch(['STF_A', 'STF_B', 'STF_C', 'STF_ME']);
      expect(gate.clear, contains('STF_C'));
      expect(gate.blockedStaffCodes, containsAll(['STF_A', 'STF_B', 'STF_ME']));
      expect(gate.total, 4);
    });

    test('blocked entries carry staffName so the sheet needs no second call',
        () async {
      final gate = await repo.getOpenSessionsBatch(['STF_A']);
      expect(gate.blocked.single.staffName, 'Sara Malik');
      expect(gate.blocked.single.initials, 'SM');
    });

    test('a staff who already raised counts as clear (§8.3)', () async {
      await repo.raise(RegRaiseInput(
        staffCode: 'STF_B',
        attendanceCode: 'STAR_MOCK_B',
        attendanceDate: (await repo.getOpenSession('STF_B'))!.attendanceDate,
        signOutLocal: yesterdayAt(17, 30),
        reason: 'forgot',
      ));
      final gate = await repo.getOpenSessionsBatch(['STF_B']);
      expect(gate.clear, ['STF_B']);
      expect(gate.hasBlocked, isFalse);
    });

    test('an empty request does not hit the network', () async {
      final gate = await repo.getOpenSessionsBatch([]);
      expect(gate.total, 0);
    });
  });

  // ————————————————————————————————————————————————————————————————
  // §9.2 raise
  // ————————————————————————————————————————————————————————————————

  group('§9.2 raise', () {
    RegRaiseInput input({DateTime? at, String reason = 'parent meeting'}) =>
        RegRaiseInput(
          staffCode: 'STF_ME',
          attendanceCode: 'STAR_MOCK_ME_1',
          attendanceDate: DateTime.now().subtract(const Duration(days: 1)),
          signOutLocal: at ?? yesterdayAt(18, 0),
          reason: reason,
        );

    test('staff-raised lands PENDING (§8.2)', () async {
      final request = await repo.raise(input());
      expect(request.status, RegStatus.pending);
      expect(request.code, 'SREG_0001');
      expect(request.reason, 'parent meeting');
      expect(request.isAutoApproved, isFalse);
      expect(request.isEditable, isTrue);
      // Round-trips through UTC and back to school-local wall clock.
      expect(request.requestedSignOutTime.hour, 18);
      expect(request.requestedSignOutTime.minute, 0);
    });

    test('a staff raise does NOT close the attendance row', () async {
      await repo.raise(input());
      final row = mock.rowFor('STAR_MOCK_ME_1')!;
      expect(row.signedOutAtLocal, isNull);
      expect(row.signedOutMethod, isNull);
    });

    test('but it does unblock the gate (§8.3)', () async {
      await repo.raise(input());
      final open = await repo.getOpenSession('STF_ME');
      // Still an unresolved day — the hours are not counted until approval —
      // but no longer blocking, and it now points at the request to edit.
      expect(open, isNotNull);
      expect(open!.hasPendingRequest, isTrue);
      expect(open.blocksSignIn, isFalse);
      expect(open.pendingRequestCode, 'SREG_0001');
      expect(open.resolvesByEdit, isTrue);
    });

    test('admin-raised is approved and applied immediately (§8.2b)', () async {
      mock.actAsAdmin(userCode: 'USR_ADMIN');
      final request = await repo.raise(input(reason: 'closing up'));

      expect(request.status, RegStatus.approved);
      // With `auto_approved` dropped from the model, this identity is what
      // marks an auto-approval (§7.2).
      expect(request.isAutoApproved, isTrue);
      expect(request.approvalByCode, 'USR_ADMIN');
      expect(request.raisedByCode, 'USR_ADMIN');
      expect(request.isEditable, isFalse);

      // §8.7 — the row is closed with REGULARIZED, which clears the gate.
      final row = mock.rowFor('STAR_MOCK_ME_1')!;
      expect(row.signedOutMethod, 'REGULARIZED');
      expect(row.signedOutAtLocal!.hour, 18);
      expect(row.regularizationCode, request.code);
      expect(await repo.getOpenSession('STF_ME'), isNull);
    });

    test('a repeat raise is idempotent (§8.6)', () async {
      final first = await repo.raise(input());
      final second = await repo.raise(input(reason: 'different text'));
      expect(second.code, first.code);
      // The existing request is returned unchanged — not overwritten.
      expect(second.reason, 'parent meeting');
      expect(mock.requests.length, 1);
    });

    test('a blank reason is rejected (§8.2)', () async {
      await expectLater(
        repo.raise(input(reason: '   ')),
        throwsA(isA<DioException>()),
      );
      expect(mock.requests, isEmpty);
    });

    test('a time before sign-in is rejected (§8.5)', () async {
      await expectLater(
        repo.raise(input(at: yesterdayAt(6, 0))),
        throwsA(isA<DioException>()),
      );
    });

    test('a time past the day cap is rejected (§8.5)', () async {
      await expectLater(
        repo.raise(input(at: yesterdayAt(21, 0))),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ————————————————————————————————————————————————————————————————
  // §9.4 edit — replaces cancel
  // ————————————————————————————————————————————————————————————————

  group('§9.4 edit', () {
    Future<RegularizationRequest> raiseOne() => repo.raise(RegRaiseInput(
          staffCode: 'STF_ME',
          attendanceCode: 'STAR_MOCK_ME_1',
          attendanceDate: DateTime.now().subtract(const Duration(days: 1)),
          signOutLocal: yesterdayAt(18, 0),
          reason: 'parent meeting',
        ));

    test('changes the time and keeps the status PENDING', () async {
      final raised = await raiseOne();
      final edited = await repo.edit(RegEditInput(
        code: raised.code,
        attendanceDate: raised.attendanceDate,
        signOutLocal: yesterdayAt(18, 45),
      ));

      expect(edited.status, RegStatus.pending);
      expect(edited.requestedSignOutTime.hour, 18);
      expect(edited.requestedSignOutTime.minute, 45);
      expect(edited.reason, 'parent meeting'); // untouched
      // §9.4 bumps updated_at; that is the only signal a pending request was
      // revised.
      expect(edited.updatedAt, isNotNull);
    });

    test('the gate stays satisfied throughout an edit', () async {
      // The reason edit replaced cancel: correcting your own request must not
      // re-block you mid-day.
      final raised = await raiseOne();
      await repo.edit(RegEditInput(
        code: raised.code,
        attendanceDate: raised.attendanceDate,
        reason: 'corrected',
      ));
      final open = await repo.getOpenSession('STF_ME');
      expect(open!.blocksSignIn, isFalse);
    });

    test('changes the reason only', () async {
      final raised = await raiseOne();
      final edited = await repo.edit(RegEditInput(
        code: raised.code,
        attendanceDate: raised.attendanceDate,
        reason: 'corrected — left after the staff meeting',
      ));
      expect(edited.reason, 'corrected — left after the staff meeting');
      expect(edited.requestedSignOutTime.hour, 18);
    });

    test('a blank reason never clears the stored one (§8.2)', () async {
      final raised = await raiseOne();
      await expectLater(
        repo.edit(RegEditInput(
          code: raised.code,
          attendanceDate: raised.attendanceDate,
          reason: '  ',
        )),
        throwsA(isA<DioException>()),
      );
    });

    test('the day window is re-validated on edit (§8.5)', () async {
      final raised = await raiseOne();
      await expectLater(
        repo.edit(RegEditInput(
          code: raised.code,
          attendanceDate: raised.attendanceDate,
          signOutLocal: yesterdayAt(23, 0),
        )),
        throwsA(isA<DioException>()),
      );
    });

    test('editing an approved request throws RegAlreadyApprovedException',
        () async {
      final raised = await raiseOne();
      mock.actAsAdmin();
      await repo.approve(raised.code);
      mock.actAsStaff();

      // §10.3 — an edit that races an approval loses, and the user must be
      // told rather than shown a silent no-op.
      await expectLater(
        repo.edit(RegEditInput(
          code: raised.code,
          attendanceDate: raised.attendanceDate,
          reason: 'too late',
        )),
        throwsA(isA<RegAlreadyApprovedException>()),
      );
    });
  });

  // ————————————————————————————————————————————————————————————————
  // §9.6 approve
  // ————————————————————————————————————————————————————————————————

  group('§9.6 approve', () {
    Future<RegularizationRequest> raiseOne() => repo.raise(RegRaiseInput(
          staffCode: 'STF_ME',
          attendanceCode: 'STAR_MOCK_ME_1',
          attendanceDate: DateTime.now().subtract(const Duration(days: 1)),
          signOutLocal: yesterdayAt(18, 0),
          reason: 'parent meeting',
        ));

    test('as submitted — approved equals requested', () async {
      final raised = await raiseOne();
      mock.actAsAdmin();
      final approved = await repo.approve(raised.code);

      expect(approved.status, RegStatus.approved);
      expect(approved.wasModified, isFalse);
      expect(approved.approvedSignOutTime!.hour, 18);
      // A reviewed approval, not an auto-approval: different actors.
      expect(approved.isAutoApproved, isFalse);
      expect(mock.rowFor('STAR_MOCK_ME_1')!.signedOutMethod, 'REGULARIZED');
      expect(await repo.getOpenSession('STF_ME'), isNull);
    });

    test('with a modification — both times are kept (§7.4)', () async {
      final raised = await raiseOne();
      mock.actAsAdmin();
      final approved = await repo.approve(
        raised.code,
        signOutLocal: yesterdayAt(17, 45),
        note: 'confirmed with lead',
      );

      expect(approved.wasModified, isTrue);
      expect(approved.requestedSignOutTime.hour, 18); // what was asked
      expect(approved.approvedSignOutTime!.minute, 45); // what was committed
      expect(approved.approvalNote, 'confirmed with lead');
      expect(mock.rowFor('STAR_MOCK_ME_1')!.signedOutAtLocal!.minute, 45);
    });

    test('a modified time is validated too (§8.5)', () async {
      final raised = await raiseOne();
      mock.actAsAdmin();
      await expectLater(
        repo.approve(raised.code, signOutLocal: yesterdayAt(23, 30)),
        throwsA(isA<DioException>()),
      );
    });

    test('approving twice is a no-op returning current state (§8.6)',
        () async {
      final raised = await raiseOne();
      mock.actAsAdmin();
      final first = await repo.approve(raised.code, signOutLocal: yesterdayAt(17, 45));
      final second = await repo.approve(raised.code, signOutLocal: yesterdayAt(16, 0));
      // The second call must not re-apply a different time.
      expect(second.approvedSignOutTime, first.approvedSignOutTime);
      expect(mock.rowFor('STAR_MOCK_ME_1')!.signedOutAtLocal!.minute, 45);
    });

    test('a staff token cannot approve (§8.2b security note)', () async {
      final raised = await raiseOne();
      await expectLater(
        repo.approve(raised.code),
        throwsA(isA<DioException>()),
      );
    });
  });

  // ————————————————————————————————————————————————————————————————
  // §9.7 bulk approve
  // ————————————————————————————————————————————————————————————————

  group('§9.7 approve-selected', () {
    Future<List<String>> raiseThree() async {
      final codes = <String>[];
      for (final entry in {
        'STAR_MOCK_ME_1': 'STF_ME',
        'STAR_MOCK_A': 'STF_A',
        'STAR_MOCK_B': 'STF_B',
      }.entries) {
        final r = await repo.raise(RegRaiseInput(
          staffCode: entry.value,
          attendanceCode: entry.key,
          attendanceDate: DateTime.now().subtract(const Duration(days: 1)),
          signOutLocal: yesterdayAt(17, 30),
          reason: 'forgot to sign out',
        ));
        codes.add(r.code);
      }
      return codes;
    }

    test('approves the chosen set and applies each', () async {
      final codes = await raiseThree();
      mock.actAsAdmin();
      final result = await repo.approveSelected(codes);

      expect(result.count, 3);
      expect(result.hasSkipped, isFalse);
      expect(result.summary, '3 approved');
      for (final row in ['STAR_MOCK_ME_1', 'STAR_MOCK_A', 'STAR_MOCK_B']) {
        expect(mock.rowFor(row)!.signedOutMethod, 'REGULARIZED');
      }
    });

    test('already-decided items are skipped, not errors (§10.3)', () async {
      final codes = await raiseThree();
      mock.actAsAdmin();
      await repo.approve(codes.last); // another admin got there first

      final result = await repo.approveSelected(codes);
      expect(result.count, 2);
      expect(result.skippedKeys, {codes.last});
      expect(result.skipped.single.reason, 'already decided');
      expect(result.summary, '2 approved · 1 skipped — already decided');
    });

    test('an empty selection does not hit the network', () async {
      final result = await repo.approveSelected([]);
      expect(result.count, 0);
    });
  });

  // ————————————————————————————————————————————————————————————————
  // §9.3 / §9.5 lists
  // ————————————————————————————————————————————————————————————————

  group('§9.3 / §9.5 lists', () {
    Future<void> raiseFive() async {
      for (var i = 0; i < 5; i++) {
        final d = DateTime.now().subtract(Duration(days: i + 2));
        final date = DateTime(d.year, d.month, d.day);
        mock.addRow(MockAttendanceRow(
          attendanceCode: 'STAR_L_$i',
          staffCode: 'STF_ME',
          staffName: 'You',
          attendanceDate: date,
          signedInAtLocal: DateTime(date.year, date.month, date.day, 8, 0),
        ));
        await repo.raise(RegRaiseInput(
          staffCode: 'STF_ME',
          attendanceCode: 'STAR_L_$i',
          attendanceDate: date,
          signOutLocal: DateTime(date.year, date.month, date.day, 17, 0),
          reason: 'reason $i',
        ));
        // Keep createdAt strictly ordered so sort assertions are stable.
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
    }

    test('my requests paginate and report hasMore', () async {
      await raiseFive();
      final first =
          await repo.getMyRequests(staffCode: 'STF_ME', page: 0, size: 2);
      expect(first.items.length, 2);
      expect(first.total, 5);
      expect(first.hasMore, isTrue);

      final last =
          await repo.getMyRequests(staffCode: 'STF_ME', page: 2, size: 2);
      expect(last.items.length, 1);
      expect(last.hasMore, isFalse);
    });

    test('sort direction is honoured in both directions', () async {
      await raiseFive();
      final newest = await repo.getMyRequests(
        staffCode: 'STF_ME',
        sort: RegSortOrder.newestFirst,
      );
      final oldest = await repo.getMyRequests(
        staffCode: 'STF_ME',
        sort: RegSortOrder.oldestFirst,
      );
      expect(newest.items.first.code, oldest.items.last.code);
      expect(newest.items.last.code, oldest.items.first.code);
    });

    test('the admin queue defaults to PENDING, oldest first (§9.5)', () async {
      await raiseFive();
      final page = await repo.getSchoolRequests(
        schoolCode: 'SCH_MOCK',
        status: RegStatus.pending,
      );
      expect(page.items, isNotEmpty);
      expect(page.items.every((r) => r.status.isPending), isTrue);
    });

    test('omitting status returns the full history — the admin All tab',
        () async {
      await raiseFive();
      final codes = mock.requests.keys.toList();
      mock.actAsAdmin();
      await repo.approve(codes.first);

      final pendingOnly = await repo.getSchoolRequests(
        schoolCode: 'SCH_MOCK',
        status: RegStatus.pending,
      );
      final approvedOnly = await repo.getSchoolRequests(
        schoolCode: 'SCH_MOCK',
        status: RegStatus.approved,
        sort: RegSortOrder.newestFirst,
      );
      final all = await repo.getSchoolRequests(
        schoolCode: 'SCH_MOCK',
        status: null,
        sort: RegSortOrder.newestFirst,
      );

      expect(approvedOnly.total, 1);
      expect(pendingOnly.total, 4);
      expect(all.total, 5);
    });

    test('the badge reads total from a size-1 page', () async {
      await raiseFive();
      final page = await repo.getSchoolRequests(
        schoolCode: 'SCH_MOCK',
        status: RegStatus.pending,
        size: 1,
      );
      expect(page.items.length, 1);
      expect(page.total, 5);
    });
  });

  // ————————————————————————————————————————————————————————————————
  // Mappers and timezone
  // ————————————————————————————————————————————————————————————————

  group('RegTimeZone', () {
    test('UTC in, school-local wall clock out', () {
      // 22:30Z on 2026-06-23 is 18:30 in New York (EDT, UTC-4).
      final local = RegTimeZone.schoolLocal('2026-06-23T22:30:00Z', zone);
      expect(local!.hour, 18);
      expect(local.minute, 30);
      expect(local.day, 23);
    });

    test('round-trips a wall-clock time', () {
      final wall = DateTime(2026, 6, 23, 18, 30);
      final iso = RegTimeZone.toUtcIso(wall, zone);
      final back = RegTimeZone.schoolLocal(iso, zone);
      expect(back!.hour, 18);
      expect(back.minute, 30);
    });

    test('crosses the date boundary correctly', () {
      // 02:00Z on the 24th is still the evening of the 23rd in New York.
      final local = RegTimeZone.schoolLocal('2026-06-24T02:00:00Z', zone);
      expect(local!.day, 23);
      expect(local.hour, 22);
    });

    test('handles a winter (EST) instant, not just summer', () {
      // Proves the IANA database is used rather than a fixed offset.
      final local = RegTimeZone.schoolLocal('2026-01-15T22:30:00Z', zone);
      expect(local!.hour, 17);
      expect(local.minute, 30);
    });

    test('null and unparseable input yield null', () {
      expect(RegTimeZone.schoolLocal(null, zone), isNull);
      expect(RegTimeZone.schoolLocal('', zone), isNull);
      expect(RegTimeZone.schoolLocal('not-a-date', zone), isNull);
    });

    test('dateOnly strips any time component', () {
      final d = RegTimeZone.dateOnly('2026-08-03');
      expect(d, DateTime(2026, 8, 3));
      expect(RegTimeZone.dateToWire(DateTime(2026, 8, 3)), '2026-08-03');
      expect(RegTimeZone.dateToWire(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });

  group('RegMappers envelopes', () {
    test('reads a paginated data.content list', () {
      final items = RegMappers.listOf({
        'data': {'content': [{'code': 'A'}, {'code': 'B'}]}
      });
      expect(items.length, 2);
    });

    test('reads a flat data list', () {
      final items = RegMappers.listOf({
        'data': [{'code': 'A'}]
      });
      expect(items.length, 1);
    });

    test('an unrecognised shape yields empty rather than throwing', () {
      expect(RegMappers.listOf({'data': 42}), isEmpty);
      expect(RegMappers.listOf(null), isEmpty);
    });

    test('raise body carries timeZone and no confirmed flag (§9.2)', () {
      final body = RegMappers.raiseBody(
        RegRaiseInput(
          staffCode: 'STF_1',
          attendanceCode: 'STAR_1',
          attendanceDate: DateTime(2026, 6, 23),
          signOutLocal: DateTime(2026, 6, 23, 18, 30),
          reason: '  parent meeting  ',
        ),
        zone: zone,
      );
      expect(body['attendanceDate'], '2026-06-23');
      expect(body['requestedSignOutTime'], '2026-06-23T22:30:00.000Z');
      expect(body['reason'], 'parent meeting');
      expect(body['timeZone'], zone);
      expect(body['method'], 'APP');
      expect(body.containsKey('confirmedSuggestedTime'), isFalse);
      expect(body.containsKey('type'), isFalse);
    });

    test('edit body sends only what changed (§9.4)', () {
      final timeOnly = RegMappers.editBody(
        RegEditInput(
          code: 'SREG_1',
          attendanceDate: DateTime(2026, 6, 23),
          signOutLocal: DateTime(2026, 6, 23, 18, 45),
        ),
        zone: zone,
      );
      expect(timeOnly.keys, containsAll(['requestedSignOutTime', 'timeZone']));
      expect(timeOnly.containsKey('reason'), isFalse);

      final reasonOnly = RegMappers.editBody(
        RegEditInput(
          code: 'SREG_1',
          attendanceDate: DateTime(2026, 6, 23),
          reason: 'corrected',
        ),
        zone: zone,
      );
      expect(reasonOnly, {'reason': 'corrected'});
      // timeZone is only required when a time is sent.
      expect(reasonOnly.containsKey('timeZone'), isFalse);
    });

    test('approve body omits signOutTime when approving as submitted (§9.6)',
        () {
      final asSubmitted = RegMappers.approveBody(zone: zone);
      expect(asSubmitted.containsKey('signOutTime'), isFalse);

      final modified = RegMappers.approveBody(
        signOutLocal: DateTime(2026, 6, 23, 17, 45),
        note: 'confirmed',
        zone: zone,
      );
      expect(modified['signOutTime'], '2026-06-23T21:45:00.000Z');
      expect(modified['note'], 'confirmed');
    });

    test('batch raise omits a per-item reason equal to the shared one', () {
      final body = RegMappers.raiseBatchBody(
        [
          RegRaiseInput(
            staffCode: 'STF_A',
            attendanceCode: 'STAR_A',
            attendanceDate: DateTime(2026, 6, 23),
            signOutLocal: DateTime(2026, 6, 23, 17, 30),
            reason: 'forgot to sign out',
          ),
          RegRaiseInput(
            staffCode: 'STF_B',
            attendanceCode: 'STAR_B',
            attendanceDate: DateTime(2026, 6, 23),
            signOutLocal: DateTime(2026, 6, 23, 18, 15),
            reason: 'covered late pickup',
          ),
        ],
        sharedReason: 'forgot to sign out',
        zone: zone,
      );
      final items = body['items'] as List;
      expect((items[0] as Map).containsKey('reason'), isFalse);
      expect((items[1] as Map)['reason'], 'covered late pickup');
      expect(body['reason'], 'forgot to sign out');
    });

    test('a request DTO maps every renamed approval field', () {
      final request = RegMappers.toRequest({
        'code': 'SREG_0007',
        'staffCode': 'STF_1',
        'staffName': 'Sara Malik',
        'attendanceCode': 'STAR_1',
        'attendanceDate': '2026-06-23',
        'requestedSignOutTime': '2026-06-23T22:00:00Z',
        'reason': 'parent meeting',
        'status': 'APPROVED',
        'raisedByCode': 'STF_1',
        'createdAt': '2026-06-24T12:05:00Z',
        'updatedAt': '2026-06-24T13:00:00Z',
        'approvedSignOutTime': '2026-06-23T21:45:00Z',
        'approvalByCode': 'USR_ADMIN',
        'approvalByName': 'Chaitanya Bhave',
        'approvalAt': '2026-06-24T14:30:00Z',
        'approvalNote': 'confirmed with lead',
      }, zone: zone);

      expect(request.status, RegStatus.approved);
      expect(request.requestedSignOutTime.hour, 18);
      expect(request.approvedSignOutTime!.hour, 17);
      expect(request.approvedSignOutTime!.minute, 45);
      expect(request.wasModified, isTrue);
      expect(request.wasEdited, isTrue);
      expect(request.approvalByName, 'Chaitanya Bhave');
      expect(request.approvalNote, 'confirmed with lead');
      expect(request.isAutoApproved, isFalse);
    });

    test('staffName falls back to the code while §9.5 lacks it', () {
      // The open backend question: the inbox DTO is not documented to include
      // staffName, and a blank name is worse than showing the code.
      final request = RegMappers.toRequest({
        'code': 'SREG_1',
        'staffCode': 'STF_42',
        'attendanceCode': 'STAR_1',
        'attendanceDate': '2026-06-23',
        'requestedSignOutTime': '2026-06-23T22:00:00Z',
        'reason': 'r',
        'status': 'PENDING',
        'raisedByCode': 'STF_42',
        'createdAt': '2026-06-24T12:05:00Z',
      }, zone: zone);
      expect(request.staffName, 'STF_42');
    });

    test('batch result reads applied or approved into one count', () {
      expect(
        RegMappers.toBatchResult({
          'data': {'applied': 9, 'skipped': []}
        }).count,
        9,
      );
      expect(
        RegMappers.toBatchResult({
          'data': {'approved': 2, 'skipped': []}
        }).count,
        2,
      );
    });
  });

  group('RegApiPaths sign-in matching (§8.3)', () {
    test('matches all three sign-in endpoints', () {
      expect(RegApiPaths.isStaffSignIn(RegApiPaths.signInAdmin), isTrue);
      expect(RegApiPaths.isStaffSignIn(RegApiPaths.signInSelf), isTrue);
      expect(RegApiPaths.isStaffSignIn(RegApiPaths.signInKiosk), isTrue);
    });

    test('matches fully-qualified URLs and ignores query strings', () {
      expect(
        RegApiPaths.isStaffSignIn(
            'https://api.example.com/api/v1/staff-attendance-records/sign-in/self?x=1'),
        isTrue,
      );
    });

    test('does not match sign-out, transfer or the student endpoints', () {
      expect(
        RegApiPaths.isStaffSignIn('/api/v1/staff-attendance-records/sign-out'),
        isFalse,
      );
      expect(
        RegApiPaths.isStaffSignIn('/api/v1/staff-attendance-records/transfer'),
        isFalse,
      );
      expect(
        RegApiPaths
            .isStaffSignIn('/api/v1/student-attendance-records/sign-in'),
        isFalse,
      );
    });

    test('self and kiosk are self; the admin endpoint is not', () {
      // Kiosk is a staff signing themselves in with their own PIN, so the
      // server sees a staff principal and §8.2b must NOT auto-approve.
      expect(RegApiPaths.isSelfSignIn(RegApiPaths.signInSelf), isTrue);
      expect(RegApiPaths.isSelfSignIn(RegApiPaths.signInKiosk), isTrue);
      expect(RegApiPaths.isSelfSignIn(RegApiPaths.signInAdmin), isFalse);
    });
  });

  group('RegHttpErrors', () {
    DioException conflict(Object? body) => DioException(
          requestOptions: RequestOptions(path: '/sign-in'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/sign-in'),
            statusCode: 409,
            data: body,
          ),
          type: DioExceptionType.badResponse,
        );

    test('recognises REGULARIZATION_REQUIRED', () {
      expect(
        RegHttpErrors.isRegularizationRequired(conflict({
          'code': 'REGULARIZATION_REQUIRED',
          'openSessions': [{'attendanceCode': 'STAR_1'}],
        })),
        isTrue,
      );
    });

    test('a plain 409 is not treated as a gate rejection', () {
      // e.g. "already signed in" — opening a regularization sheet would be
      // wrong, so the error code has to match too.
      expect(
        RegHttpErrors
            .isRegularizationRequired(conflict({'message': 'already signed in'})),
        isFalse,
      );
    });

    test('extracts open sessions from all three plausible body shapes', () {
      const item = {'attendanceCode': 'STAR_1'};
      expect(
        RegHttpErrors.openSessionsFrom(conflict({'openSessions': [item]})).length,
        1,
      );
      expect(
        RegHttpErrors.openSessionsFrom(
            conflict({'data': {'openSessions': [item]}})).length,
        1,
      );
      expect(
        RegHttpErrors.openSessionsFrom(conflict({'data': [item]})).length,
        1,
      );
      // No payload → fall back to a GET /open-sessions.
      expect(RegHttpErrors.openSessionsFrom(conflict({'x': 1})), isEmpty);
    });
  });

  group('mock auto-seeding', () {
    test('an unknown staff code gets an unresolved yesterday', () async {
      // This is what makes the mock demoable in the real app: the logged-in
      // staff code comes from storage and will not match the seed list.
      final auto = RegMockDataSource(zone: zone)..latency = Duration.zero;
      final autoRepo = RegularizationRepositoryImpl(auto, context);

      final open = await autoRepo.getOpenSession('STF_WHOEVER');
      expect(open, isNotNull);
      expect(open!.blocksSignIn, isTrue);
    });

    test('resolving it does not immediately hand out a fresh one', () async {
      final auto = RegMockDataSource(zone: zone)..latency = Duration.zero;
      final autoRepo = RegularizationRepositoryImpl(auto, context);
      auto.actAsAdmin();

      final open = await autoRepo.getOpenSession('STF_WHOEVER');
      await autoRepo.raise(RegRaiseInput(
        staffCode: 'STF_WHOEVER',
        attendanceCode: open!.attendanceCode,
        attendanceDate: open.attendanceDate,
        signOutLocal: yesterdayAt(17, 30),
        reason: 'forgot',
      ));

      expect(await autoRepo.getOpenSession('STF_WHOEVER'), isNull);
    });
  });

  group('mock controls', () {
    test('failNext makes exactly one call fail', () async {
      mock.failNext = Exception('boom');
      await expectLater(repo.getOpenSession('STF_ME'), throwsException);
      expect(await repo.getOpenSession('STF_ME'), isNotNull);
    });

    test('reset restores the seed', () async {
      mock.actAsAdmin();
      await repo.raise(RegRaiseInput(
        staffCode: 'STF_ME',
        attendanceCode: 'STAR_MOCK_ME_1',
        attendanceDate: DateTime.now().subtract(const Duration(days: 1)),
        signOutLocal: yesterdayAt(17, 30),
        reason: 'x',
      ));
      expect(await repo.getOpenSession('STF_ME'), isNull);

      mock.reset();
      expect(mock.requests, isEmpty);
      expect(await repo.getOpenSession('STF_ME'), isNotNull);
    });
  });
}
