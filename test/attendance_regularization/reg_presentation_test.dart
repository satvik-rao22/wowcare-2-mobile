import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_regularization/core/config/reg_config.dart';
import 'package:wowcare/modules/attendance_regularization/data/datasources/reg_api_paths.dart';
import 'package:wowcare/modules/attendance_regularization/data/datasources/reg_remote_datasource.dart';
import 'package:wowcare/modules/attendance_regularization/data/interceptor/reg_sign_in_gate_interceptor.dart';
import 'package:wowcare/modules/attendance_regularization/data/reg_context.dart';
import 'package:wowcare/modules/attendance_regularization/data/repositories/regularization_repository_impl.dart';
import 'package:wowcare/modules/attendance_regularization/domain/entities/regularization_request.dart';
import 'package:wowcare/modules/attendance_regularization/domain/repositories/regularization_repository.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/approve_request_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/approve_selected_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/check_gate_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/edit_regularization_usecase.dart';
import 'package:wowcare/modules/attendance_regularization/domain/usecases/get_requests_usecase.dart';
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

import 'support/fake_api.dart';

/// A gate with scripted answers, so the interceptor can be tested without a
/// navigator, a sheet or a datasource.
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
  Future<RegGateOutcome> guardSingle(String staffCode,
      {required bool byAdmin, String staffName = ''}) async {
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
  Future<bool> handleConflict(Object error,
      {required bool byAdmin, String staffCode = ''}) async {
    byAdminFlags.add(byAdmin);
    return conflictResolved;
  }

  List<String> resolveBlockedReturns = const [];
  final List<List<Map<String, dynamic>>> blockedCalls = [];

  @override
  Future<List<String>> resolveBlocked(List<Map<String, dynamic>> blocked,
      {required bool byAdmin}) async {
    blockedCalls.add(blocked);
    byAdminFlags.add(byAdmin);
    return resolveBlockedReturns;
  }
}

class _ThrowingGate implements RegSignInGate {
  @override
  Future<RegGateOutcome> guardSingle(String staffCode,
          {required bool byAdmin, String staffName = ''}) async =>
      throw Exception('gate exploded');

  @override
  Future<RegBulkGateOutcome> guardBulk(List<String> codes) async =>
      throw Exception('gate exploded');

  @override
  Future<bool> handleConflict(Object error,
          {required bool byAdmin, String staffCode = ''}) async =>
      throw Exception('gate exploded');

  @override
  Future<List<String>> resolveBlocked(List<Map<String, dynamic>> blocked,
          {required bool byAdmin}) async =>
      throw Exception('gate exploded');
}

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

  RegGateCoordinator gate() => RegGateCoordinator(
        checkGate: CheckGateUseCase(repo),
        raise: RaiseRegularizationUseCase(repo),
        raiseBatch: RaiseRegularizationBatchUseCase(repo),
        edit: EditRegularizationUseCase(repo),
        context: const RegStaticContext(zone: zone),
      );

  RegMyRequestsCubit myRequests() => RegMyRequestsCubit(
        getRequests: GetRequestsUseCase(repo),
        editRequest: EditRegularizationUseCase(repo),
        gate: gate(),
      );

  RegInboxCubit inbox() => RegInboxCubit(
        getRequests: GetRequestsUseCase(repo),
        approveRequest: ApproveRequestUseCase(repo),
        approveSelected: ApproveSelectedUseCase(repo),
      );

  RegDashboardCubit dashboard() => RegDashboardCubit(
        gate: gate(),
        getRequests: GetRequestsUseCase(repo),
      );

  // ——————————————————————————————————————————————————————————————
  // Interceptor
  // ——————————————————————————————————————————————————————————————

  group('RegSignInGateInterceptor', () {
    ({Dio dio, List<RequestOptions> sent}) client(
      RegSignInGate scripted, {
      int status = 200,
      List<Map<String, dynamic>> blocked = const [],
    }) {
      final sent = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.interceptors.add(RegSignInGateInterceptor(scripted, dio));
      dio.httpClientAdapter = _SignInAdapter(sent, status, blocked);
      return (dio: dio, sent: sent);
    }

    test('passes non-sign-in requests straight through', () async {
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>('/api/v1/staff-attendance-records/sign-out',
          data: {'staffCode': 'STF_ME'});

      expect(scripted.singleCalls, isEmpty);
      expect(c.sent.length, 1);
    });

    test('a self sign-in reports byAdmin false', () async {
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio
          .post<dynamic>(RegApiPaths.signInSelf, data: {'staffCode': 'STF_ME'});

      expect(scripted.singleCalls, ['STF_ME']);
      expect(scripted.byAdminFlags.single, isFalse);
    });

    test('kiosk is treated as self, so its corrections land PENDING', () async {
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>(RegApiPaths.signInKiosk,
          data: {'staffCode': 'STF_ME'});

      expect(scripted.byAdminFlags.single, isFalse);
    });

    test('an admin sign-in reports byAdmin true', () async {
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>(RegApiPaths.signInAdmin,
          data: {'staffCode': 'STF_TARGET'});

      expect(scripted.byAdminFlags.single, isTrue);
    });

    test('a blocked single sign-in never reaches the server', () async {
      final scripted = _ScriptedGate(singleOutcome: RegGateOutcome.blocked);
      final c = client(scripted);

      await expectLater(
        c.dio.post<dynamic>(RegApiPaths.signInSelf,
            data: {'staffCode': 'STF_ME'}),
        throwsA(isA<DioException>()),
      );
      expect(c.sent, isEmpty);
    });

    test('bulk reads staffCodes, not the acting admin', () async {
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>(RegApiPaths.signInAdmin, data: {
        'staffCode': 'STF_ADMIN',
        'staffCodes': ['STF_A', 'STF_B', 'STF_C'],
      });

      expect(scripted.bulkCalls.single, ['STF_A', 'STF_B', 'STF_C']);
      expect(scripted.singleCalls, isEmpty);
    });

    test('narrows the payload instead of failing the batch', () async {
      final scripted = _ScriptedGate(
        bulkOutcome: const RegBulkGateOutcome(allowed: ['STF_A', 'STF_C']),
      );
      final c = client(scripted);
      await c.dio.post<dynamic>(RegApiPaths.signInAdmin, data: {
        'staffCodes': ['STF_A', 'STF_B', 'STF_C'],
        'classroomCodeByStaffCode': {
          'STF_A': 'CLS_1',
          'STF_B': 'CLS_2',
          'STF_C': 'CLS_3',
        },
      });

      final body = c.sent.single.data as Map;
      expect(body['staffCodes'], ['STF_A', 'STF_C']);
      // The held-back staff's classroom must not travel either.
      expect((body['classroomCodeByStaffCode'] as Map).keys,
          unorderedEquals(['STF_A', 'STF_C']));
    });

    test('rejects when nobody may proceed', () async {
      final scripted =
          _ScriptedGate(bulkOutcome: const RegBulkGateOutcome(allowed: []));
      final c = client(scripted);

      await expectLater(
        c.dio.post<dynamic>(RegApiPaths.signInAdmin,
            data: {'staffCodes': ['STF_A', 'STF_B']}),
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
      final scripted = _ScriptedGate(conflictResolved: false);
      final c = client(scripted, status: 409);

      await expectLater(
        c.dio.post<dynamic>(RegApiPaths.signInSelf,
            data: {'staffCode': 'STF_ME'}),
        throwsA(isA<DioException>()),
      );
      // onRequest gated it, then onError consulted the gate again.
      expect(scripted.byAdminFlags.length, 2);
    });

    test('a blocked staff in the response is resolved, then signed in',
        () async {
      // The host reads only success/message, so without this the admin would
      // see a clean result while someone stayed out.
      final scripted = _ScriptedGate()..resolveBlockedReturns = ['STF_B'];
      final c = client(scripted, blocked: [
        {'staffCode': 'STF_B', 'attendanceCode': 'SAR_B'}
      ]);

      final response = await c.dio.post<dynamic>(RegApiPaths.signInAdmin,
          data: {'staffCodes': ['STF_A', 'STF_B']});

      expect(scripted.blockedCalls.single.single['staffCode'], 'STF_B');
      // Retried for just the newly-cleared staff.
      expect(c.sent.length, 2);
      expect((c.sent.last.data as Map)['staffCodes'], ['STF_B']);
      // Both responses' signedIn folded together.
      final data = (response.data as Map)['data'] as Map;
      expect((data['signedIn'] as List).length, 2);
      expect(data['blocked'], isEmpty);
    });

    test('skipping leaves a message rather than a clean success', () async {
      final scripted = _ScriptedGate()..resolveBlockedReturns = const [];
      final c = client(scripted, blocked: [
        {'staffCode': 'STF_B', 'attendanceCode': 'SAR_B'}
      ]);

      final response = await c.dio.post<dynamic>(RegApiPaths.signInAdmin,
          data: {'staffCodes': ['STF_A', 'STF_B']});

      expect(c.sent.length, 1);
      expect((response.data as Map)['message'],
          contains('still need yesterday closed'));
    });

    test('a clean response is passed straight through', () async {
      final scripted = _ScriptedGate();
      final c = client(scripted);
      await c.dio.post<dynamic>(RegApiPaths.signInAdmin,
          data: {'staffCodes': ['STF_A', 'STF_B']});

      expect(scripted.blockedCalls, isEmpty);
      expect(c.sent.length, 1);
    });

    test('bulk pre-check can be turned off without losing the gate', () async {
      // Option B: the server's blocked list drives the sheet instead.
      RegConfig.preCheckBulkSignIn = false;
      addTearDown(() => RegConfig.preCheckBulkSignIn = true);

      final scripted = _ScriptedGate()..resolveBlockedReturns = ['STF_B'];
      final c = client(scripted, blocked: [
        {'staffCode': 'STF_B', 'attendanceCode': 'SAR_B'}
      ]);

      await c.dio.post<dynamic>(RegApiPaths.signInAdmin,
          data: {'staffCodes': ['STF_A', 'STF_B']});

      expect(scripted.bulkCalls, isEmpty);
      expect(scripted.blockedCalls, hasLength(1));
    });

    test('a failing gate never blocks the sign-in', () async {
      // The gate must not be why attendance breaks; the server guard holds.
      final c = client(_ThrowingGate());
      await c.dio
          .post<dynamic>(RegApiPaths.signInSelf, data: {'staffCode': 'STF_ME'});

      expect(c.sent.length, 1);
    });
  });

  // ——————————————————————————————————————————————————————————————
  // Cubits
  // ——————————————————————————————————————————————————————————————

  group('RegMyRequestsCubit', () {
    test('loads the list and the gate banner together', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);
      api.onPost('/open-sessions/check', FakeApi.gateAlreadyRaised);

      final cubit = myRequests();
      await cubit.load();

      expect(cubit.state.status, RegListStatus.loaded);
      expect(cubit.state.requests.length, 1);
      // Raised but still uncounted, so the banner stays — as a status, not a
      // call to action.
      expect(cubit.state.gate, isNotNull);
      expect(cubit.state.gate!.blocksSignIn, isFalse);
      addTearDown(cubit.close);
    });

    test('a clear gate shows no banner', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);
      api.onPost('/open-sessions/check', FakeApi.gateClear);

      final cubit = myRequests();
      await cubit.load();

      expect(cubit.state.gate, isNull);
      addTearDown(cubit.close);
    });

    test('surfaces an error without losing the screen', () async {
      api.onGetError('/staff-attendance-regularizations', 500, null);
      api.onPost('/open-sessions/check', FakeApi.gateClear);

      final cubit = myRequests();
      await cubit.load();

      expect(cubit.state.isError, isTrue);
      expect(cubit.state.message, isNotEmpty);
      addTearDown(cubit.close);
    });

    test('an edit that lost to an approval says so plainly', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);
      api.onPost('/open-sessions/check', FakeApi.gateClear);
      api.onPatchError('/staff-attendance-regularizations', 409, {
        'error': {'code': 'REGULARIZATION_ALREADY_APPROVED'}
      });

      final cubit = myRequests();
      await cubit.load();
      await cubit.edit('SREG_0000001',
          attendanceDate: DateTime(2026, 6, 23), reason: 'too late');

      // A silent no-op would leave the user thinking it applied.
      expect(cubit.state.message, contains('already approved'));
      addTearDown(cubit.close);
    });
  });

  group('RegInboxCubit', () {
    test('defaults to the pending queue, oldest first', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);

      final cubit = inbox();
      await cubit.load();

      expect(cubit.state.filter, RegInboxFilter.pending);
      expect(api.lastQuery['status'], 'PENDING');
      expect(api.lastQuery['sort'], 'createdAt,asc');
      expect(cubit.state.requests.length, 1);
      addTearDown(cubit.close);
    });

    test('switching tab refetches with the new status and sort', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);

      final cubit = inbox();
      await cubit.load();
      cubit.toggleSelectAll();
      expect(cubit.state.selected, isNotEmpty);

      await cubit.setFilter(RegInboxFilter.all);

      // The tab changes both status and sort, so the old page is not a prefix
      // of the new one — selection cannot carry over either.
      expect(api.lastQuery.containsKey('status'), isFalse);
      expect(api.lastQuery['sort'], 'createdAt,desc');
      expect(cubit.state.selected, isEmpty);
      addTearDown(cubit.close);
    });

    test('history tabs are not selectable', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);

      final cubit = inbox();
      await cubit.load();
      await cubit.setFilter(RegInboxFilter.approved);
      cubit.toggleSelectAll();

      expect(cubit.state.selected, isEmpty);
      expect(cubit.state.selectableRequests, isEmpty);
      addTearDown(cubit.close);
    });

    test('approving on Pending removes the row from the queue', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);
      api.onPost('/approve', FakeApi.approvedAsSubmitted);

      final cubit = inbox();
      await cubit.load();
      await cubit.approve('SREG_0000001');

      expect(cubit.state.requests, isEmpty);
      expect(cubit.state.message, 'Approved');
      addTearDown(cubit.close);
    });

    test('approving on All keeps the row and re-renders it', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);
      api.onPost('/approve', FakeApi.approvedAsSubmitted);

      final cubit = inbox();
      await cubit.load();
      await cubit.setFilter(RegInboxFilter.all);
      await cubit.approve('SREG_0000001');

      // A history view must not lie about its own contents.
      expect(cubit.state.requests.single.status, RegStatus.approved);
      addTearDown(cubit.close);
    });

    test('bulk approve keeps skipped rows and names the reason', () async {
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);
      api.onPost('/approve-selected', FakeApi.approveSelected);

      final cubit = inbox();
      await cubit.load();
      cubit.toggleSelectAll();
      await cubit.approveSelected();

      expect(cubit.state.message, contains('skipped'));
      expect(cubit.state.message, contains('already decided'));
      expect(cubit.state.selected, isEmpty);
      addTearDown(cubit.close);
    });
  });

  group('RegDashboardCubit', () {
    test('staff: an unresolved day needs action', () async {
      api.onPost('/open-sessions/check', FakeApi.gateBlocked);

      final cubit = dashboard();
      await cubit.load(forAdmin: false);

      expect(cubit.state.needsAction, isTrue);
      expect(cubit.state.awaitingApproval, isFalse);
      // Not an admin, so no count is fetched.
      expect(cubit.state.pendingCount, 0);
      addTearDown(cubit.close);
    });

    test('staff: flips to awaiting approval once raised', () async {
      api.onPost('/open-sessions/check', FakeApi.gateAlreadyRaised);

      final cubit = dashboard();
      await cubit.load(forAdmin: false);

      expect(cubit.state.needsAction, isFalse);
      expect(cubit.state.awaitingApproval, isTrue);
      addTearDown(cubit.close);
    });

    test('staff: nothing to show when clear', () async {
      api.onPost('/open-sessions/check', FakeApi.gateClear);

      final cubit = dashboard();
      await cubit.load(forAdmin: false);

      expect(cubit.state.hasOpenSession, isFalse);
      addTearDown(cubit.close);
    });

    test('admin: the badge reads total from a size-1 page', () async {
      api.onPost('/open-sessions/check', FakeApi.gateClear);
      api.onGet('/staff-attendance-regularizations', FakeApi.listPage);

      final cubit = dashboard();
      await cubit.load(forAdmin: true);

      expect(api.lastQuery['size'], 1);
      expect(api.lastQuery['status'], 'PENDING');
      expect(cubit.state.pendingCount, 2);
      expect(cubit.state.hasPendingForAdmin, isTrue);
      addTearDown(cubit.close);
    });

    test('the auto-open fires at most once per session', () async {
      api.onPost('/open-sessions/check', FakeApi.gateBlocked);

      final cubit = dashboard();
      await cubit.load(forAdmin: false);
      cubit.markAutoSheetShown();
      await cubit.load(forAdmin: false);

      // A reload must not re-arm it, or the sheet reappears on every refresh.
      expect(cubit.state.autoSheetShown, isTrue);
      addTearDown(cubit.close);
    });
  });

  group('RegInboxFilter', () {
    test('pairs each tab with the right status and sort', () {
      expect(RegInboxFilter.pending.status, RegStatus.pending);
      expect(RegInboxFilter.pending.sort, RegSortOrder.oldestFirst);
      expect(RegInboxFilter.approved.status, RegStatus.approved);
      expect(RegInboxFilter.approved.sort, RegSortOrder.newestFirst);
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

/// Records sign-in requests that got past the interceptor.
class _SignInAdapter implements HttpClientAdapter {
  _SignInAdapter(this.sent, this.status, [this.blocked = const []]);

  final List<RequestOptions> sent;
  final int status;

  /// Returned on the FIRST call only, so a retry comes back clean.
  final List<Map<String, dynamic>> blocked;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isFirst = sent.isEmpty;
    sent.add(options);
    final body = status == 409
        ? '{"success":false,"error":{"code":"REGULARIZATION_REQUIRED"}}'
        : jsonEncode({
            'success': true,
            'data': {
              'signedIn': [
                {'code': 'SAR_1', 'staffCode': 'STF_CLEAR'}
              ],
              'blocked': isFirst ? blocked : const [],
            },
          });
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
