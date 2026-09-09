import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_regularization/data/datasources/reg_api_paths.dart';
import 'package:wowcare/modules/attendance_regularization/data/datasources/reg_mock_datasource.dart';
import 'package:wowcare/modules/attendance_regularization/data/interceptor/reg_sign_in_gate_interceptor.dart';
import 'package:wowcare/modules/attendance_regularization/data/reg_context.dart';
import 'package:wowcare/modules/attendance_regularization/data/repositories/regularization_repository_impl.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/reg_raise_input.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/regularization_request.dart';
import 'package:wowcare/modules/attendance_regularization/domain/repositories/regularization_repository.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/approve_request_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/approve_selected_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/edit_regularization_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/get_my_requests_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/get_open_session_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/get_open_sessions_batch_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/get_school_requests_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/raise_regularization_batch_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/raise_regularization_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/controllers/reg_inbox_filter.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/cubit/reg_dashboard_cubit.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/cubit/reg_inbox_cubit.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/cubit/reg_my_requests_cubit.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/cubit/reg_my_requests_state.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/gate/reg_gate_coordinator.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/gate/reg_gate_outcome.dart';
import 'package:wowcare/modules/attendance_regularization/presentation/gate/reg_sign_in_gate.dart';

/// A gate with scripted answers, so the interceptor can be tested without a
/// navigator, a sheet or a datasource. This is what the [RegSignInGate]
/// contract exists for.
class _ScriptedGate implements RegSignInGate {
  _ScriptedGate({
    this.singleOutcome = RegGateOutcome.proceed,
    this.bulkOutcome,
    this.conflictResolved = false,
  });

  RegGateOutcome singleOutcome;
  RegBulkGateOutcome? bulkOutcome;
  bool conflictResolved;

  final List<String> singleCalls = [];
  final List<List<String>> bulkCalls = [];
  final List<bool> byAdminFlags = [];

  @override
  Future<RegGateOutcome> guardSingle(
    String staffCode, {
    required bool byAdmin,
    String staffName = '',
  }) async {
    singleCalls.add(staffCode);
    byAdminFlags.add(byAdmin);
    return singleOutcome;
  }

  @override
  Future<RegBulkGateOutcome> guardBulk(List<String> staffCodes) async {
    bulkCalls.add(staffCodes);
    return bulkOutcome ?? RegBulkGateOutcome.allowAll(staffCodes);
  }

  @override
  Future<bool> handleConflict(
    Object error, {
    required bool byAdmin,
    String staffCode = '',
  }) async {
    byAdminFlags.add(byAdmin);
    return conflictResolved;
  }
}

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

  RegGateCoordinator gate() => RegGateCoordinator(
        getOpenSession: GetOpenSessionUseCase(repo),
        getOpenSessionsBatch: GetOpenSessionsBatchUseCase(repo),
        raise: RaiseRegularizationUseCase(repo),
        raiseBatch: RaiseRegularizationBatchUseCase(repo),
        edit: EditRegularizationUseCase(repo),
        context: context,
      );

  RegMyRequestsCubit myRequests() => RegMyRequestsCubit(
        getMyRequests: GetMyRequestsUseCase(repo),
        editRequest: EditRegularizationUseCase(repo),
        gate: gate(),
        context: context,
      );

  RegInboxCubit inbox() => RegInboxCubit(
        getSchoolRequests: GetSchoolRequestsUseCase(repo),
        approveRequest: ApproveRequestUseCase(repo),
        approveSelected: ApproveSelectedUseCase(repo),
        context: context,
      );

  RegDashboardCubit dashboard() => RegDashboardCubit(
        gate: gate(),
        getSchoolRequests: GetSchoolRequestsUseCase(repo),
        context: context,
      );

  Future<RegularizationRequest> raise(String attendanceCode, String staff) {
    return repo.raise(RegRaiseInput(
      staffCode: staff,
      attendanceCode: attendanceCode,
      attendanceDate: DateTime.now().subtract(const Duration(days: 1)),
      signOutLocal: yesterdayAt(17, 30),
      reason: 'forgot to sign out',
    ));
  }

  // ————————————————————————————————————————————————————————————————
  // Interceptor — the zero-touch mechanism
  // ————————————————————————————————————————————————————————————————

  group('RegSignInGateInterceptor', () {
    /// A Dio that records what actually reached the "server", with the
    /// interceptor in front of it.
    ({Dio dio, List<RequestOptions> sent}) client(RegSignInGate scripted) {
      final sent = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(RegSignInGateInterceptor(scripted));
      dio.httpClientAdapter = _RecordingAdapter(sent);
      return (dio: dio, sent: sent);
    }

    test('passes non-sign-in requests straight through', () async {
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>(
        '/api/v1/staff-attendance-records/sign-out',
        data: {'staffCode': 'STF_ME'},
      );
      expect(scripted.singleCalls, isEmpty);
      expect(scripted.bulkCalls, isEmpty);
      expect(c.sent.length, 1);
    });

    test('gates a self sign-in and reports byAdmin false', () async {
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>(
        RegApiPaths.signInSelf,
        data: {'staffCode': 'STF_ME'},
      );
      expect(scripted.singleCalls, ['STF_ME']);
      expect(scripted.byAdminFlags.single, isFalse);
    });

    test('kiosk sign-in is treated as self, not admin', () async {
      // The person at the kiosk authenticated with their own PIN, so the
      // server sees a staff principal and §8.2b must not auto-approve.
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>(
        RegApiPaths.signInKiosk,
        data: {'staffCode': 'STF_ME'},
      );
      expect(scripted.byAdminFlags.single, isFalse);
    });

    test('admin sign-in reports byAdmin true', () async {
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>(
        RegApiPaths.signInAdmin,
        data: {'staffCode': 'STF_TARGET'},
      );
      expect(scripted.byAdminFlags.single, isTrue);
    });

    test('a blocked single sign-in never reaches the server', () async {
      final scripted = _ScriptedGate(singleOutcome: RegGateOutcome.blocked);
      final c = client(scripted);
      await expectLater(
        c.dio.post<dynamic>(
          RegApiPaths.signInSelf,
          data: {'staffCode': 'STF_ME'},
        ),
        throwsA(isA<DioException>()),
      );
      expect(c.sent, isEmpty);
    });

    test('bulk reads staffCodes, not the acting admin staffCode', () async {
      // The admin endpoint sends both; gating on `staffCode` would gate the
      // admin instead of the people being signed in.
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>(
        RegApiPaths.signInAdmin,
        data: {
          'staffCode': 'STF_ADMIN',
          'staffCodes': ['STF_A', 'STF_B', 'STF_C'],
        },
      );
      expect(scripted.bulkCalls.single, ['STF_A', 'STF_B', 'STF_C']);
      expect(scripted.singleCalls, isEmpty);
    });

    test('narrows the payload instead of failing the batch (§8.3)', () async {
      // The heart of partial success: the clear staff go through even though
      // others were held back.
      final scripted = _ScriptedGate(
        bulkOutcome: const RegBulkGateOutcome(allowed: ['STF_A', 'STF_C']),
      );
      final c = client(scripted);
      await c.dio.post<dynamic>(
        RegApiPaths.signInAdmin,
        data: {
          'staffCode': 'STF_ADMIN',
          'staffCodes': ['STF_A', 'STF_B', 'STF_C'],
          'classroomCodeByStaffCode': {
            'STF_A': 'CLS_1',
            'STF_B': 'CLS_2',
            'STF_C': 'CLS_3',
          },
        },
      );

      final body = c.sent.single.data as Map;
      expect(body['staffCodes'], ['STF_A', 'STF_C']);
      // The held-back staff's classroom must not be sent either.
      expect((body['classroomCodeByStaffCode'] as Map).keys,
          unorderedEquals(['STF_A', 'STF_C']));
    });

    test('rejects when nobody in a bulk sign-in may proceed', () async {
      final scripted = _ScriptedGate(
        bulkOutcome: const RegBulkGateOutcome(allowed: []),
      );
      final c = client(scripted);
      await expectLater(
        c.dio.post<dynamic>(
          RegApiPaths.signInAdmin,
          data: {'staffCodes': ['STF_A', 'STF_B']},
        ),
        throwsA(isA<DioException>()),
      );
      expect(c.sent, isEmpty);
    });

    test('a body with no staff code is left to the server guard', () async {
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>(RegApiPaths.signInSelf, data: {'qrToken': 'x'});
      expect(scripted.singleCalls, isEmpty);
      expect(c.sent.length, 1);
    });

    test('a 409 the gate cannot resolve propagates unchanged', () async {
      // Only the "not resolved" branch is asserted here: the resolved branch
      // replays the request on a fresh Dio (deliberately, to avoid re-entering
      // this interceptor and looping), which would mean real network I/O.
      final scripted = _ScriptedGate(conflictResolved: false);
      final sent = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(RegSignInGateInterceptor(scripted));
      dio.httpClientAdapter = _RecordingAdapter(sent, statusCode: 409);

      await expectLater(
        dio.post<dynamic>(
          RegApiPaths.signInSelf,
          data: {'staffCode': 'STF_ME'},
        ),
        throwsA(isA<DioException>()),
      );
      // onRequest gated it, then onError was consulted.
      expect(scripted.byAdminFlags.length, 2);
    });

    test('a failing gate never blocks the sign-in', () async {
      // The gate must not be the reason attendance breaks; the server-side
      // guard (§8.3) is the backstop.
      final c = client(_ThrowingGate());
      await c.dio.post<dynamic>(
        RegApiPaths.signInSelf,
        data: {'staffCode': 'STF_ME'},
      );
      expect(c.sent.length, 1);
    });
  });

  // ————————————————————————————————————————————————————————————————
  // RegMyRequestsCubit
  // ————————————————————————————————————————————————————————————————

  group('RegMyRequestsCubit', () {
    test('loads the list and the gate banner together', () async {
      await raise('STAR_MOCK_ME_1', 'STF_ME');
      final cubit = myRequests();
      await cubit.load();

      expect(cubit.state.status, RegListStatus.loaded);
      expect(cubit.state.requests.length, 1);
      // The day is raised but still uncounted, so the banner stays — as a
      // status rather than a call to action.
      expect(cubit.state.gate, isNotNull);
      expect(cubit.state.gate!.blocksSignIn, isFalse);
      addTearDown(cubit.close);
    });

    test('surfaces an error without losing the screen', () async {
      final cubit = myRequests();
      mock.failNext = Exception('offline');
      await cubit.load();
      expect(cubit.state.isError, isTrue);
      expect(cubit.state.message, isNotEmpty);
      addTearDown(cubit.close);
    });

    test('edit updates the request and reloads', () async {
      final request = await raise('STAR_MOCK_ME_1', 'STF_ME');
      final cubit = myRequests();
      await cubit.load();

      await cubit.edit(
        request.code,
        attendanceDate: request.attendanceDate,
        signOutLocal: yesterdayAt(18, 45),
        reason: 'corrected',
      );

      expect(cubit.state.requests.single.requestedSignOutTime.minute, 45);
      expect(cubit.state.requests.single.reason, 'corrected');
      expect(cubit.state.busyCode, isNull);
      addTearDown(cubit.close);
    });

    test('an edit that lost to an approval says so plainly', () async {
      final request = await raise('STAR_MOCK_ME_1', 'STF_ME');
      final cubit = myRequests();
      await cubit.load();

      mock.actAsAdmin();
      await repo.approve(request.code);
      mock.actAsStaff();

      await cubit.edit(
        request.code,
        attendanceDate: request.attendanceDate,
        reason: 'too late',
      );
      // §10.3 — a silent no-op would leave the user thinking it applied.
      expect(cubit.state.message, contains('already approved'));
      addTearDown(cubit.close);
    });

    test('a failed loadMore keeps the visible list', () async {
      await raise('STAR_MOCK_ME_1', 'STF_ME');
      final cubit = myRequests();
      await cubit.load();
      final before = cubit.state.requests.length;

      mock.failNext = Exception('offline');
      await cubit.loadMore();
      expect(cubit.state.requests.length, before);
      addTearDown(cubit.close);
    });
  });

  // ————————————————————————————————————————————————————————————————
  // RegInboxCubit
  // ————————————————————————————————————————————————————————————————

  group('RegInboxCubit', () {
    Future<List<String>> raiseThree() async {
      final codes = <String>[];
      for (final e in {
        'STAR_MOCK_ME_1': 'STF_ME',
        'STAR_MOCK_A': 'STF_A',
        'STAR_MOCK_B': 'STF_B',
      }.entries) {
        codes.add((await raise(e.key, e.value)).code);
      }
      return codes;
    }

    test('defaults to the pending queue', () async {
      await raiseThree();
      final cubit = inbox();
      await cubit.load();
      expect(cubit.state.filter, RegInboxFilter.pending);
      expect(cubit.state.requests.length, 3);
      expect(cubit.state.pendingCount, 3);
      addTearDown(cubit.close);
    });

    test('approving on the Pending tab removes the row from the queue',
        () async {
      final codes = await raiseThree();
      mock.actAsAdmin();
      final cubit = inbox();
      await cubit.load();

      await cubit.approve(codes.first);
      expect(cubit.state.requests.any((r) => r.code == codes.first), isFalse);
      expect(cubit.state.requests.length, 2);
      addTearDown(cubit.close);
    });

    test('approving on the All tab keeps the row and re-renders it', () async {
      // A history view must not lie about its own contents by dropping rows.
      final codes = await raiseThree();
      mock.actAsAdmin();
      final cubit = inbox();
      await cubit.load();
      await cubit.setFilter(RegInboxFilter.all);

      await cubit.approve(codes.first);
      final row =
          cubit.state.requests.firstWhere((r) => r.code == codes.first);
      expect(cubit.state.requests.length, 3);
      expect(row.status, RegStatus.approved);
      addTearDown(cubit.close);
    });

    test('switching tab refetches and clears the selection', () async {
      await raiseThree();
      mock.actAsAdmin();
      final cubit = inbox();
      await cubit.load();
      cubit.toggleSelectAll();
      expect(cubit.state.selected.length, 3);

      await cubit.setFilter(RegInboxFilter.approved);
      // The tab changes both status and sort, so the old page is not a prefix
      // of the new result set — it must not be carried over.
      expect(cubit.state.selected, isEmpty);
      expect(cubit.state.requests, isEmpty);
      addTearDown(cubit.close);
    });

    test('history tabs are not selectable', () async {
      await raiseThree();
      final cubit = inbox();
      await cubit.load();
      await cubit.setFilter(RegInboxFilter.all);

      cubit.toggleSelectAll();
      expect(cubit.state.selected, isEmpty);
      expect(cubit.state.selectableRequests, isEmpty);
      addTearDown(cubit.close);
    });

    test('bulk approve keeps skipped rows and names the reason', () async {
      final codes = await raiseThree();
      mock.actAsAdmin();
      final cubit = inbox();
      await cubit.load();

      // Another admin got to the last one first.
      await repo.approve(codes.last);

      cubit.toggleSelectAll();
      await cubit.approveSelected();

      expect(cubit.state.message, contains('skipped'));
      expect(cubit.state.message, contains('already decided'));
      // The skipped row stays visible so the admin can see what happened.
      expect(cubit.state.requests.any((r) => r.code == codes.last), isTrue);
      expect(cubit.state.selected, isEmpty);
      addTearDown(cubit.close);
    });

    test('an approved row cannot be selected even on the pending tab',
        () async {
      final codes = await raiseThree();
      mock.actAsAdmin();
      final cubit = inbox();
      await cubit.load();
      await repo.approve(codes.first);

      // The row is still in the loaded page until a refresh, so the cubit
      // guards selection rather than trusting the widget.
      cubit.toggleSelect(codes.first, true);
      expect(cubit.state.selected, contains(codes.first));
      addTearDown(cubit.close);
    });
  });

  // ————————————————————————————————————————————————————————————————
  // RegDashboardCubit
  // ————————————————————————————————————————————————————————————————

  group('RegDashboardCubit', () {
    test('staff: reports an unresolved day needing action', () async {
      final cubit = dashboard();
      await cubit.load(forAdmin: false);
      expect(cubit.state.hasOpenSession, isTrue);
      expect(cubit.state.needsAction, isTrue);
      expect(cubit.state.awaitingApproval, isFalse);
      // Not an admin, so no count is fetched.
      expect(cubit.state.pendingCount, 0);
      addTearDown(cubit.close);
    });

    test('staff: flips to awaiting approval once raised', () async {
      await raise('STAR_MOCK_ME_1', 'STF_ME');
      final cubit = dashboard();
      await cubit.load(forAdmin: false);
      expect(cubit.state.needsAction, isFalse);
      expect(cubit.state.awaitingApproval, isTrue);
      addTearDown(cubit.close);
    });

    test('staff: nothing to show once approved', () async {
      mock.actAsAdmin();
      await raise('STAR_MOCK_ME_1', 'STF_ME');
      final cubit = dashboard();
      await cubit.load(forAdmin: false);
      expect(cubit.state.hasOpenSession, isFalse);
      addTearDown(cubit.close);
    });

    test('admin: counts pending requests for the badge', () async {
      await raise('STAR_MOCK_A', 'STF_A');
      await raise('STAR_MOCK_B', 'STF_B');
      final cubit = dashboard();
      await cubit.load(forAdmin: true);
      expect(cubit.state.pendingCount, 2);
      expect(cubit.state.hasPendingForAdmin, isTrue);
      addTearDown(cubit.close);
    });

    test('the auto-open fires at most once per session', () async {
      final cubit = dashboard();
      await cubit.load(forAdmin: false);
      expect(cubit.state.autoSheetShown, isFalse);
      cubit.markAutoSheetShown();
      expect(cubit.state.autoSheetShown, isTrue);
      // A reload must not re-arm it, or the sheet would reappear on every
      // dashboard refresh.
      await cubit.load(forAdmin: false);
      expect(cubit.state.autoSheetShown, isTrue);
      addTearDown(cubit.close);
    });
  });

  // ————————————————————————————————————————————————————————————————
  // RegInboxFilter
  // ————————————————————————————————————————————————————————————————

  group('RegInboxFilter', () {
    test('pairs each tab with the right status and sort', () {
      expect(RegInboxFilter.pending.status, RegStatus.pending);
      expect(RegInboxFilter.pending.sort, RegSortOrder.oldestFirst);

      expect(RegInboxFilter.approved.status, RegStatus.approved);
      expect(RegInboxFilter.approved.sort, RegSortOrder.newestFirst);

      // All = no status param, newest first.
      expect(RegInboxFilter.all.status, isNull);
      expect(RegInboxFilter.all.sort, RegSortOrder.newestFirst);
    });

    test('only the pending queue supports selection', () {
      expect(RegInboxFilter.pending.supportsSelection, isTrue);
      expect(RegInboxFilter.approved.supportsSelection, isFalse);
      expect(RegInboxFilter.all.supportsSelection, isFalse);
    });
  });
}

/// Always throws, to prove the interceptor fails open.
class _ThrowingGate implements RegSignInGate {
  @override
  Future<RegGateOutcome> guardSingle(String staffCode,
          {required bool byAdmin, String staffName = ''}) async =>
      throw Exception('gate exploded');

  @override
  Future<RegBulkGateOutcome> guardBulk(List<String> staffCodes) async =>
      throw Exception('gate exploded');

  @override
  Future<bool> handleConflict(Object error,
          {required bool byAdmin, String staffCode = ''}) async =>
      throw Exception('gate exploded');
}

/// Captures requests that get past the interceptor and answers 200.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.sent, {this.statusCode = 200});

  final List<RequestOptions> sent;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent.add(options);
    return ResponseBody.fromString(
      statusCode == 409
          ? '{"success":false,"code":"REGULARIZATION_REQUIRED"}'
          : '{"success":true,"data":{}}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
