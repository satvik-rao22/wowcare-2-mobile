import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';

/// Fake [HttpClientAdapter] that replays a staged JSON body and counts how many
/// times the session endpoint was polled.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._body);

  final Map<String, dynamic> _body;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      jsonEncode(_body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({AssetService service, _FakeAdapter adapter}) _serviceReturning(
  Map<String, dynamic> body,
) {
  final client = ApiClient(baseUrl: 'http://localhost');
  final adapter = _FakeAdapter(body);
  client.client.httpClientAdapter = adapter;
  return (service: AssetService(client), adapter: adapter);
}

Map<String, dynamic> _session(List<Map<String, String>> assets) =>
    <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{'assets': assets},
    };

void main() {
  // Regression: attaching a PDF + two images failed after ~60 polls and two
  // minutes with "photo processing took too long", even though every asset had
  // uploaded successfully. document-ms reports these assets as `UPLOADED` and
  // never moves them to `READY`, so a gate that insisted on `READY` could never
  // pass. An attachment only needs the asset *code* — the delivery URL is
  // resolved lazily when it is rendered.
  group('awaitAssetsAttachable', () {
    test('UPLOADED is good enough to attach', () async {
      final t = _serviceReturning(
        _session([
          {'assetCode': 'AST_A', 'status': 'UPLOADED'},
        ]),
      );

      expect(
        await t.service.awaitAssetsAttachable(
          sessionCode: 'SES_1',
          expectedAssetCodes: const ['AST_A'],
        ),
        isTrue,
      );
      // Answered on the first poll — no storm of requests.
      expect(t.adapter.calls, 1);
    });

    test('READY is of course fine too', () async {
      final t = _serviceReturning(
        _session([
          {'assetCode': 'AST_A', 'status': 'READY'},
        ]),
      );
      expect(
        await t.service.awaitAssetsAttachable(
          sessionCode: 'SES_1',
          expectedAssetCodes: const ['AST_A'],
        ),
        isTrue,
      );
    });

    test('a mixed batch passes when every asset is at least uploaded', () async {
      final t = _serviceReturning(
        _session([
          {'assetCode': 'AST_PDF', 'status': 'UPLOADED'},
          {'assetCode': 'AST_IMG1', 'status': 'READY'},
          {'assetCode': 'AST_IMG2', 'status': 'UPLOADED'},
        ]),
      );

      expect(
        await t.service.awaitAssetsAttachable(
          sessionCode: 'SES_1',
          expectedAssetCodes: const ['AST_PDF', 'AST_IMG1', 'AST_IMG2'],
        ),
        isTrue,
      );
      expect(t.adapter.calls, 1);
    });

    test('a FAILED asset is the one case that blocks attaching', () async {
      final t = _serviceReturning(
        _session([
          {'assetCode': 'AST_A', 'status': 'UPLOADED'},
          {'assetCode': 'AST_B', 'status': 'FAILED'},
        ]),
      );

      expect(
        await t.service.awaitAssetsAttachable(
          sessionCode: 'SES_1',
          expectedAssetCodes: const ['AST_A', 'AST_B'],
        ),
        isFalse,
      );
    });

    test('an unrecognized session payload stops polling immediately', () async {
      // The old code read this as "not ready yet" and re-requested it until the
      // timeout — the "hell ton of GET requests" with nothing to show for it.
      final t = _serviceReturning(<String, dynamic>{'success': true});

      expect(
        await t.service.awaitAssetsAttachable(
          sessionCode: 'SES_1',
          expectedAssetCodes: const ['AST_A'],
          timeout: const Duration(seconds: 10),
        ),
        isTrue,
      );
      expect(t.adapter.calls, 1);
    });

    test('an asset missing from the session does not block the save', () async {
      final t = _serviceReturning(
        _session([
          {'assetCode': 'AST_SOMETHING_ELSE', 'status': 'READY'},
        ]),
      );

      expect(
        await t.service.awaitAssetsAttachable(
          sessionCode: 'SES_1',
          expectedAssetCodes: const ['AST_A'],
          timeout: const Duration(seconds: 10),
        ),
        isTrue,
      );
      expect(t.adapter.calls, 1);
    });

    test('a still-processing asset is waited on, then allowed through',
        () async {
      // PENDING is neither uploaded nor failed, so it polls — but a slow
      // pipeline must not fail an upload that already succeeded, so it gives up
      // in favour of proceeding rather than throwing.
      final t = _serviceReturning(
        _session([
          {'assetCode': 'AST_A', 'status': 'PENDING'},
        ]),
      );

      final stopwatch = Stopwatch()..start();
      final result = await t.service.awaitAssetsAttachable(
        sessionCode: 'SES_1',
        expectedAssetCodes: const ['AST_A'],
        pollEvery: const Duration(milliseconds: 10),
        timeout: const Duration(milliseconds: 60),
      );
      stopwatch.stop();

      expect(result, isTrue);
      expect(t.adapter.calls, greaterThan(1));
      // Bounded by the timeout, not by the number of assets or retries.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('nothing expected needs no request at all', () async {
      final t = _serviceReturning(_session(const []));
      expect(
        await t.service.awaitAssetsAttachable(
          sessionCode: 'SES_1',
          expectedAssetCodes: const [],
        ),
        isTrue,
      );
      expect(t.adapter.calls, 0);
    });

    test('a status-endpoint error never fails the upload', () async {
      final client = ApiClient(baseUrl: 'http://localhost');
      client.client.httpClientAdapter = _ThrowingAdapter();
      final service = AssetService(client);

      expect(
        await service.awaitAssetsAttachable(
          sessionCode: 'SES_1',
          expectedAssetCodes: const ['AST_A'],
        ),
        isTrue,
      );
    });
  });
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(requestOptions: options, message: 'boom');
  }

  @override
  void close({bool force = false}) {}
}
