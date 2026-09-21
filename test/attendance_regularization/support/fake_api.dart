import 'dart:convert';

import 'package:dio/dio.dart';

/// A Dio adapter that replays the contract's JSON and records what was sent.
///
/// Routes are matched by path suffix, so a test names the endpoint the way the
/// contract does.
class FakeApi {
  FakeApi() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dio.httpClientAdapter = _Adapter(this);
  }

  late final Dio dio;

  final List<RequestOptions> calls = [];
  final Map<String, ({int status, Object? body})> _routes = {};

  void onPost(String suffix, Object body) =>
      _routes['POST $suffix'] = (status: 200, body: body);

  void onGet(String suffix, Object body) =>
      _routes['GET $suffix'] = (status: 200, body: body);

  void onPatch(String suffix, Object body) =>
      _routes['PATCH $suffix'] = (status: 200, body: body);

  void onPostError(String suffix, int status, Object? body) =>
      _routes['POST $suffix'] = (status: status, body: body);

  void onPatchError(String suffix, int status, Object? body) =>
      _routes['PATCH $suffix'] = (status: status, body: body);

  void onGetError(String suffix, int status, Object? body) =>
      _routes['GET $suffix'] = (status: status, body: body);

  Map<String, dynamic> get lastBody {
    final data = calls.last.data;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Map<String, dynamic> get lastQuery =>
      Map<String, dynamic>.from(calls.last.queryParameters);

  ({int status, Object? body})? _match(RequestOptions options) {
    final path = options.path.split('?').first;
    for (final entry in _routes.entries) {
      final parts = entry.key.split(' ');
      if (parts.first == options.method && path.endsWith(parts.last)) {
        return entry.value;
      }
    }
    // Suffix match is exact-tail; fall back to "contains" so a test can name a
    // mid-path segment like `/approve`.
    for (final entry in _routes.entries) {
      final parts = entry.key.split(' ');
      if (parts.first == options.method && path.contains(parts.last)) {
        return entry.value;
      }
    }
    return null;
  }

  // —— contract payloads ——

  static Object gateClear = {
    'success': true,
    'data': {'blocked': [], 'clear': ['STF_0008', 'STF_0009']},
  };

  static Object gateBlocked = {
    'success': true,
    'data': {
      'blocked': [
        {
          'staffCode': 'STF_0007',
          'staffName': 'Mohan Sonone',
          'attendanceCode': 'SAR_10231',
          'attendanceDate': '2026-06-23',
          'signedInAt': '2026-06-23T02:02:00Z',
          'signedInByCode': 'STF_0007',
          'suggestedSignOutTime': '2026-06-23T13:30:00Z',
          'classroomCode': 'CLS_0002',
          'hasPendingRequest': false,
          'pendingRequestCode': null,
        }
      ],
      'clear': <String>[],
    },
  };

  static Object gateAlreadyRaised = {
    'success': true,
    'data': {
      'blocked': [
        {
          'staffCode': 'STF_0007',
          'staffName': 'Mohan Sonone',
          'attendanceCode': 'SAR_10231',
          'attendanceDate': '2026-06-23',
          'suggestedSignOutTime': '2026-06-23T13:30:00Z',
          'hasPendingRequest': true,
          'pendingRequestCode': 'SREG_0000001',
        }
      ],
      'clear': <String>[],
    },
  };

  static Map<String, dynamic> rawRequest(String status) => {
        'code': 'SREG_0000001',
        'staffCode': 'STF_0007',
        'staffName': 'Mohan Sonone',
        'attendanceDate': '2026-06-23',
        'attendanceCode': 'SAR_10231',
        'requestedSignOutTime': '2026-06-23T13:30:00Z',
        'reason': 'Stayed for parent meeting, forgot to sign out.',
        'raisedByCode': 'USR_0044',
        'method': 'APP',
        'status': status,
        'approvedSignOutTime': null,
        'approvalByCode': null,
        'approvalAt': null,
        'approvalNote': null,
        'autoApproved': false,
        'createdAt': '2026-06-24T02:01:44Z',
      };

  static Object raisedPending = {'data': rawRequest('PENDING')};

  static Object raisedApproved = {
    'data': {
      ...rawRequest('APPROVED'),
      'code': 'SREG_0000002',
      'approvedSignOutTime': '2026-06-23T13:30:00Z',
      'approvalByCode': 'USR_0001',
      'approvalAt': '2026-06-24T02:05:10Z',
      'autoApproved': true,
    }
  };

  static Object approvedAsSubmitted = {
    'data': {
      ...rawRequest('APPROVED'),
      'approvedSignOutTime': '2026-06-23T13:30:00Z',
      'approvalByCode': 'USR_0001',
      'approvalAt': '2026-06-24T04:11:02Z',
      'autoApproved': false,
    }
  };

  static Object approvedModified = {
    'data': {
      ...rawRequest('APPROVED'),
      'approvedSignOutTime': '2026-06-23T12:15:00Z',
      'approvalByCode': 'USR_0001',
      'approvalAt': '2026-06-24T04:11:02Z',
      'approvalNote': 'Gate log shows 5:45 PM.',
      'autoApproved': false,
    }
  };

  static Object listPage = {
    'data': {
      'content': [rawRequest('PENDING')],
      'page': 0,
      'size': 20,
      'totalElements': 2,
      'totalPages': 1,
      'hasNext': false,
      'hasPrevious': false,
    }
  };

  static Object listNoStaffName = {
    'data': {
      'content': [
        Map<String, dynamic>.from(rawRequest('PENDING'))..remove('staffName')
      ],
      'page': 0,
      'size': 20,
      'totalElements': 1,
      'hasNext': false,
    }
  };

  static Object batchApplied = {
    'data': {
      'applied': 9,
      'skipped': [
        {
          'attendanceCode': 'SAR_10240',
          'code': 'SREG_0000031',
          'reason': 'already resolved',
        }
      ],
    }
  };

  static Object approveSelected = {
    'data': {
      'applied': 1,
      'skipped': [
        {
          'code': 'SREG_0000004',
          'attendanceCode': 'SAR_10240',
          'reason': 'already decided',
        }
      ],
    }
  };
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.api);

  final FakeApi api;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    api.calls.add(options);
    final route = api._match(options);
    if (route == null) {
      return ResponseBody.fromString('{}', 404,
          headers: _jsonHeaders);
    }
    return ResponseBody.fromString(
      jsonEncode(route.body ?? <String, dynamic>{}),
      route.status,
      headers: _jsonHeaders,
    );
  }

  static const _jsonHeaders = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  void close({bool force = false}) {}
}
