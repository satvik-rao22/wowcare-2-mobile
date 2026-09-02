import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/session_expired_interceptor.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
import 'package:wowcare/data/features/billing/datasources/invoice_remote_datasource.dart';
import 'package:wowcare/data/features/billing/models/invoice_request_models.dart';

/// Captures the outgoing request and returns a benign JSON body.
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
      '{"data":{}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

InvoicePaymentRequestModel _req() => InvoicePaymentRequestModel(
      schoolCode: 'SCH-1',
      amount: 100,
      date: DateTime.utc(2026, 1, 1),
    );

void main() {
  test(
    'createPayment sends the Idempotency-Key header and opts out of 401 replay '
    'so a retry/replay cannot double-charge',
    () async {
      final adapter = _CapturingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final ds = InvoiceRemoteDataSourceImpl(dio);

      try {
        await ds.createPayment(_req(), idempotencyKey: 'KEY-1');
      } catch (_) {
        // ignore parse/shape errors — the request is captured before parse
      }

      expect(adapter.captured, isNotNull);
      expect(adapter.captured!.headers[IdempotencyKey.headerName], 'KEY-1');
      expect(adapter.captured!.extra[kNoAutoReplayExtraKey], isTrue);
    },
  );

  test('createRefund and createCredit also carry the idempotency header + no-replay',
      () async {
    final adapter = _CapturingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final ds = InvoiceRemoteDataSourceImpl(dio);

    try {
      await ds.createRefund(_req(), idempotencyKey: 'KEY-R');
    } catch (_) {}
    expect(adapter.captured!.headers[IdempotencyKey.headerName], 'KEY-R');
    expect(adapter.captured!.extra[kNoAutoReplayExtraKey], isTrue);

    try {
      await ds.createCredit(
        const CreateCreditRequestModel(schoolCode: 'SCH-1', amount: 50),
        idempotencyKey: 'KEY-C',
      );
    } catch (_) {}
    expect(adapter.captured!.headers[IdempotencyKey.headerName], 'KEY-C');
    expect(adapter.captured!.extra[kNoAutoReplayExtraKey], isTrue);
  });
}
