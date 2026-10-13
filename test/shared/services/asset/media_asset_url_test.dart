import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';

class _FakeAdapter implements HttpClientAdapter {
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{
        'success': true,
        'data': <String, dynamic>{
          'status': 'READY',
          'deliveryUrl': 'https://cdn.example.com/a/primary.webp',
        },
      }),
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
  // Regression: the in-flight entry was cleared with
  // `whenComplete(() => _assetUrlInFlight.remove(code))`. The arrow returned
  // the removed value — the in-flight future itself — and whenComplete waits
  // for a returned future, so the future waited on itself forever. Every first
  // lookup of an asset (document "View", attachments) spun indefinitely.
  group('getMediaAssetUrlByCode', () {
    late AssetService service;
    late _FakeAdapter adapter;

    setUp(() {
      final client = ApiClient(baseUrl: 'http://localhost');
      adapter = _FakeAdapter();
      client.client.httpClientAdapter = adapter;
      service = AssetService(client);
    });

    test('first lookup completes with the delivery URL', () async {
      final url = await service
          .getMediaAssetUrlByCode(assetCode: 'AST_1')
          .timeout(const Duration(seconds: 5));
      expect(url, 'https://cdn.example.com/a/primary.webp');
    });

    test('concurrent lookups share one request and both complete', () async {
      final results = await Future.wait([
        service.getMediaAssetUrlByCode(assetCode: 'AST_2'),
        service.getMediaAssetUrlByCode(assetCode: 'AST_2'),
      ]).timeout(const Duration(seconds: 5));
      expect(results, everyElement('https://cdn.example.com/a/primary.webp'));
      expect(adapter.calls, 1);
    });

    test('later lookups are served from cache', () async {
      await service
          .getMediaAssetUrlByCode(assetCode: 'AST_3')
          .timeout(const Duration(seconds: 5));
      await service.getMediaAssetUrlByCode(assetCode: 'AST_3');
      expect(adapter.calls, 1);
    });
  });
}
