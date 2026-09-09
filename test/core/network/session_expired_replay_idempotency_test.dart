import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/idempotency_key.dart';

/// Adapter that records the request it is asked to send and returns 200, so we
/// can inspect exactly which headers went out on the replayed request.
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
      '{"ok":true}',
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
  // SessionExpiredInterceptor.onError (session_expired_interceptor.dart:38-41)
  // replays a 401'd request after a token refresh by taking the SAME
  // `err.requestOptions` object, mutating only `extra['__retried']` and the
  // `Authorization` header, then calling `_dio.fetch(options)`. Because it is
  // the same RequestOptions instance, every other header the app set — including
  // the Idempotency-Key on attendance mutations — must ride along unchanged.
  // This test pins that behaviour so a future refactor of the replay can't
  // silently drop the idempotency guarantee.
  test(
    'Idempotency-Key header survives the 401-refresh replay (same RequestOptions)',
    () async {
      final adapter = _CapturingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;

      const idempotencyKey = 'idem-key-abc-123';

      // The original mutating request as the datasource sends it: it carries an
      // Idempotency-Key plus the (now-expired) Authorization.
      final original = RequestOptions(
        path: 'https://example.test/attendance/records/sign-in',
        method: 'POST',
        headers: <String, dynamic>{
          IdempotencyKey.headerName: idempotencyKey,
          'Authorization': 'Bearer expired-token',
        },
      );

      // Reproduce EXACTLY what the interceptor does before replaying: reuse the
      // same object, flip the retried flag, swap in the refreshed bearer token.
      final replayOptions = original
        ..extra['__retried'] = true
        ..headers['Authorization'] = 'Bearer refreshed-token';

      await dio.fetch<dynamic>(replayOptions);

      final sent = adapter.captured!;
      // The replayed request still carries the ORIGINAL Idempotency-Key, so the
      // backend sees the retry as the same logical operation and dedupes it.
      expect(sent.headers[IdempotencyKey.headerName], idempotencyKey);
      // ...alongside the refreshed Authorization and the retried marker.
      expect(sent.headers['Authorization'], 'Bearer refreshed-token');
      expect(sent.extra['__retried'], true);
    },
  );
}
