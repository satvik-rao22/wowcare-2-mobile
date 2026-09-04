import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset_service.dart';

/// Serves canned `media-assets/resolve` responses and records the codes each
/// request asked for, so batching and cache hits can be asserted directly.
///
/// Stubs Dio at the adapter level: the service builds absolute URLs against the
/// document-service host, and an interceptor added after `ApiClient` is built
/// still lets the request reach the socket.
class _StubAdapter implements HttpClientAdapter {
  int calls = 0;

  /// The `assetCodes` array of every request, in order.
  final List<List<String>> requestedBatches = [];

  /// assetCode → asset object to return.
  Map<String, Map<String, Object?>> assets = {};

  /// Codes to report under `missingAssetCodes` instead of `assets`.
  Set<String> missing = {};

  /// When set, the request fails outright.
  bool fail = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    final body = options.data as Map<dynamic, dynamic>;
    final codes = (body['assetCodes'] as List).cast<String>();
    requestedBatches.add(codes);

    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'offline',
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'assets': [
            for (final code in codes)
              if (assets.containsKey(code) && !missing.contains(code))
                assets[code]!,
          ],
          'missingAssetCodes': [
            for (final code in codes)
              if (missing.contains(code) || !assets.containsKey(code)) code,
          ],
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
  late _StubAdapter stub;
  late AttachmentAssetService service;

  setUp(() {
    stub = _StubAdapter();
    final client = ApiClient(baseUrl: 'http://localhost');
    client.client.httpClientAdapter = stub;
    service = AttachmentAssetService(client);
  });

  /// Shaped after the real resolve payload.
  Map<String, Object?> imageAsset(
    String code, {
    String fileName = 'download.jpg',
    int sizeBytes = 75818,
    String status = 'READY',
  }) =>
      {
        'assetCode': code,
        'mediaType': 'IMAGE',
        'status': status,
        'fileName': fileName,
        'contentType': 'image/jpeg',
        'sizeBytes': sizeBytes,
        'thumbnailUrl': 'https://cdn.test/$code/thumb_256.webp',
        'deliveryUrl': 'https://cdn.test/$code/primary.webp',
        'downloadUrl': 'https://s3.test/$code/original.jpg?X-Amz-Signature=abc',
        'variants': [
          {
            'variantName': 'primary',
            'defaultVariant': true,
            'width': 736,
            'height': 414,
          },
          {'variantName': 'thumb', 'defaultVariant': false, 'width': 256},
        ],
      };

  test('resolves a batch in one request', () async {
    stub.assets = {
      'AST_1': imageAsset('AST_1', fileName: 'one.jpg'),
      'AST_2': imageAsset('AST_2', fileName: 'two.jpg'),
      'AST_3': imageAsset('AST_3', fileName: 'three.jpg'),
    };

    final results = await service.resolveAll(['AST_1', 'AST_2', 'AST_3']);

    // The whole point of the resolve endpoint: three codes, one round trip.
    expect(stub.calls, 1);
    expect(stub.requestedBatches.single, ['AST_1', 'AST_2', 'AST_3']);
    expect(results.map((a) => a.fileName), ['one.jpg', 'two.jpg', 'three.jpg']);
  });

  test('maps every field the UI needs', () async {
    stub.assets = {'AST_1': imageAsset('AST_1')};

    final asset = await service.resolve('AST_1');

    expect(asset.isReady, isTrue);
    expect(asset.fileName, 'download.jpg');
    expect(asset.isImage, isTrue);
    expect(asset.displaySubtitle, 'JPG · 74 KB');
    // Small tiles take the thumbnail, the viewer takes the full artifact.
    expect(asset.previewUrl, endsWith('thumb_256.webp'));
    expect(asset.fullUrl, endsWith('primary.webp'));
    // Dimensions come off the default variant, so a preview can reserve space.
    expect(asset.aspectRatio, closeTo(736 / 414, 0.001));
  });

  test('results keep the caller order regardless of response order', () async {
    stub.assets = {
      'AST_1': imageAsset('AST_1', fileName: 'a.jpg'),
      'AST_2': imageAsset('AST_2', fileName: 'b.jpg'),
    };

    final results = await service.resolveAll(['AST_2', 'AST_1']);

    expect(results.map((a) => a.assetCode), ['AST_2', 'AST_1']);
  });

  test('a cached code is not re-requested', () async {
    stub.assets = {'AST_1': imageAsset('AST_1')};

    await service.resolve('AST_1');
    await service.resolve('AST_1');

    expect(stub.calls, 1);
    expect(service.cached('AST_1'), isNotNull);
  });

  test('a mixed list only asks for the codes it is missing', () async {
    stub.assets = {
      'AST_1': imageAsset('AST_1'),
      'AST_2': imageAsset('AST_2'),
      'AST_3': imageAsset('AST_3'),
    };
    await service.resolveAll(['AST_1']);

    final results = await service.resolveAll(['AST_1', 'AST_2', 'AST_3']);

    expect(stub.calls, 2);
    // AST_1 came from cache, so the second request carried only the other two.
    expect(stub.requestedBatches.last, ['AST_2', 'AST_3']);
    expect(results, hasLength(3));
    expect(results.every((a) => a.isReady), isTrue);
  });

  test('concurrent callers all succeed; the cache absorbs the repeat', () async {
    stub.assets = {'AST_1': imageAsset('AST_1')};

    final results = await Future.wait([
      service.resolve('AST_1'),
      service.resolve('AST_1'),
      service.resolve('AST_1'),
    ]);

    expect(results.every((a) => a.isReady), isTrue);
    // There is deliberately no in-flight dedupe: the map that provided it was
    // where a self-awaiting `whenComplete` hung every resolve, and the simpler
    // code is worth more than saving a duplicate request that only happens when
    // two widgets mount with the same code in the same frame.
    expect(stub.calls, lessThanOrEqualTo(3));
    // Whatever happened above, the next read is free.
    final calls = stub.calls;
    await service.resolve('AST_1');
    expect(stub.calls, calls);
  });

  test('duplicate codes in one call are asked for once', () async {
    stub.assets = {'AST_1': imageAsset('AST_1')};

    final results = await service.resolveAll(['AST_1', 'AST_1']);

    expect(stub.requestedBatches.single, ['AST_1']);
    expect(results, hasLength(1));
  });

  test('missingAssetCodes surfaces as an unavailable asset', () async {
    stub.assets = {'AST_1': imageAsset('AST_1')};
    stub.missing = {'AST_GONE'};

    final results = await service.resolveAll(['AST_1', 'AST_GONE']);

    expect(results[0].isReady, isTrue);
    expect(results[1].isMissing, isTrue);
    expect(results[1].unavailableLabel, 'This file is no longer available');
  });

  test('a PROCESSING asset reads as processing, not as an error', () async {
    stub.assets = {
      'AST_1': {
        'assetCode': 'AST_1',
        'mediaType': 'IMAGE',
        'status': 'PROCESSING',
        'fileName': 'photo.jpg',
        'contentType': 'image/jpeg',
        'sizeBytes': 80084,
        // No URLs yet — nothing has been generated.
      },
    };

    final asset = await service.resolve('AST_1');

    expect(asset.isReady, isFalse);
    expect(asset.isMissing, isFalse);
    expect(asset.isProcessing, isTrue);
    expect(asset.unavailableLabel, 'Still processing — check back shortly');
    // Metadata is still usable, so the row can name what it cannot yet show.
    expect(asset.displaySubtitle, 'JPG · 78 KB');
  });

  test('a failed request is not cached, so Retry really re-asks', () async {
    stub.fail = true;
    final first = await service.resolve('AST_1');
    expect(first.isMissing, isTrue);
    expect(service.cached('AST_1'), isNull);

    stub.fail = false;
    stub.assets = {'AST_1': imageAsset('AST_1')};
    final second = await service.resolve('AST_1');

    expect(second.isReady, isTrue);
    expect(stub.calls, 2);
  });

  test('forceRefresh re-resolves a cached code', () async {
    stub.assets = {'AST_1': imageAsset('AST_1', fileName: 'old.jpg')};
    await service.resolve('AST_1');

    stub.assets = {'AST_1': imageAsset('AST_1', fileName: 'new.jpg')};
    final again = await service.resolve('AST_1', forceRefresh: true);

    expect(stub.calls, 2);
    expect(again.fileName, 'new.jpg');
  });

  test('a document asset is classified without a preview URL', () async {
    stub.assets = {
      'AST_PDF': {
        'assetCode': 'AST_PDF',
        'mediaType': 'DOCUMENT',
        'status': 'READY',
        'fileName': 'consent.pdf',
        'contentType': 'application/pdf',
        'sizeBytes': 2 * 1024 * 1024,
        'deliveryUrl': 'https://cdn.test/AST_PDF/original.pdf',
        'downloadUrl': 'https://s3.test/AST_PDF/original.pdf?X-Amz-Signature=z',
      },
    };

    final asset = await service.resolve('AST_PDF');

    expect(asset.isPdf, isTrue);
    expect(asset.isDocument, isTrue);
    expect(asset.isImage, isFalse);
    expect(asset.displaySubtitle, 'PDF · 2.0 MB');
  });

  test('the cache is bounded — the oldest entries are evicted', () async {
    // One more than the ceiling, resolved one at a time.
    final total = AttachmentAssetService.maxCacheEntries + 5;
    stub.assets = {
      for (var i = 0; i < total; i++) 'AST_$i': imageAsset('AST_$i'),
    };
    for (var i = 0; i < total; i++) {
      await service.resolve('AST_$i');
    }

    expect(service.cacheSize, AttachmentAssetService.maxCacheEntries);
    // Oldest gone, newest kept — so a long session cannot grow without bound.
    expect(service.cached('AST_0'), isNull);
    expect(service.cached('AST_${total - 1}'), isNotNull);
  });

  test('reading an entry keeps it from being evicted first', () async {
    final total = AttachmentAssetService.maxCacheEntries + 2;
    stub.assets = {
      for (var i = 0; i < total; i++) 'AST_$i': imageAsset('AST_$i'),
    };
    await service.resolve('AST_0');
    // Touch it, then fill the cache past its ceiling.
    for (var i = 1; i < total; i++) {
      service.cached('AST_0');
      await service.resolve('AST_$i');
    }

    // Least-recently-USED, not least-recently-added.
    expect(service.cached('AST_0'), isNotNull);
  });

  test('an empty list makes no request', () async {
    final results = await service.resolveAll(['', '   ']);

    expect(results, isEmpty);
    expect(stub.calls, 0);
  });

  test('clearCache empties it', () async {
    stub.assets = {'AST_1': imageAsset('AST_1')};
    await service.resolve('AST_1');

    service.clearCache();

    expect(service.cacheSize, 0);
    expect(service.cached('AST_1'), isNull);
  });
}
