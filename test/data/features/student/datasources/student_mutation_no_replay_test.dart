import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/session_expired_interceptor.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';

/// Captures the request it is asked to send and returns a benign JSON body.
class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? captured;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured = options;
    return ResponseBody.fromString(
      '{"data":{"message":"ok"}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'a create/add student mutation is flagged noAutoReplay so the 401 interceptor '
    'will not silently duplicate it after a token refresh',
    () async {
      final adapter = _CapturingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final ds = StudentRemoteDataSourceImpl(dio);

      // addStudentSibling is a create POST — parsing the canned body may not
      // fully succeed, but the request is captured before any parse, so the
      // flag assertion holds regardless.
      try {
        await ds.addStudentSibling(
          studentCode: 'STU-1',
          siblingCodes: const ['STU-2'],
        );
      } catch (_) {
        // ignore parse/shape errors — we only assert the outgoing request here
      }

      expect(adapter.captured, isNotNull);
      expect(adapter.captured!.method, 'POST');
      expect(adapter.captured!.extra[kNoAutoReplayExtraKey], isTrue);
    },
  );
}
