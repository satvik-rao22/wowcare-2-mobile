import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Answers every "asset by code" lookup with a delivery URL and counts calls.
class _FakeDocumentService implements HttpClientAdapter {
  int lookups = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lookups++;
    return ResponseBody.fromString(
      jsonEncode({
        'data': {'deliveryUrl': 'https://cdn.example/a.jpg?sig=$lookups'},
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
  late _FakeDocumentService server;
  late ImageUploadService service;

  setUp(() {
    server = _FakeDocumentService();
    final apiClient = ApiClient(baseUrl: 'https://example.invalid');
    apiClient.client.httpClientAdapter = server;
    service = ImageUploadService(apiClient);
  });

  test('a fresh URL is reused — one lookup for repeat requests', () async {
    final first = await service.getMediaAssetUrlByCode(assetCode: 'A1');
    final second = await service.getMediaAssetUrlByCode(assetCode: 'A1');

    expect(first, 'https://cdn.example/a.jpg?sig=1');
    expect(second, first);
    expect(service.cachedMediaAssetUrl('A1'), first);
    expect(server.lookups, 1);
  });

  test('requests at the same time share one lookup', () async {
    final results = await Future.wait([
      service.getMediaAssetUrlByCode(assetCode: 'A1'),
      service.getMediaAssetUrlByCode(assetCode: 'A1'),
      service.getMediaAssetUrlByCode(assetCode: 'A1'),
    ]);

    expect(results.toSet(), {'https://cdn.example/a.jpg?sig=1'});
    expect(server.lookups, 1);
  });

  test('an expired URL is resolved again, never served stale', () async {
    service.assetUrlCacheTtl = Duration.zero; // every cached URL is stale

    final first = await service.getMediaAssetUrlByCode(assetCode: 'A1');
    final second = await service.getMediaAssetUrlByCode(assetCode: 'A1');

    expect(server.lookups, 2);
    expect(second, isNot(first)); // a newly signed URL
    expect(service.cachedMediaAssetUrl('A1'), isNull);
  });
}
