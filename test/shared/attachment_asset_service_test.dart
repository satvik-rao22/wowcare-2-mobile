import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset_service.dart';

/// Serves canned media-asset payloads and counts requests, so cache hits and
/// in-flight sharing can be asserted directly.
class _StubInterceptor extends Interceptor {
  _StubInterceptor();

  int calls = 0;

  /// assetCode → the `data` object the service should see.
  Map<String, Object?> payloads = {};

  /// assetCode → status code to fail with instead of returning a payload.
  Map<String, int> failures = {};

  /// Codes that should fail the first N times, then succeed.
  Map<String, int> flakyRemaining = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    calls++;
    final code = options.path.split('/').last;

    final remaining = flakyRemaining[code] ?? 0;
    if (remaining > 0) {
      flakyRemaining[code] = remaining - 1;
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'flaky',
        ),
        true,
      );
      return;
    }

    final status = failures[code];
    if (status != null) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: const {'message': 'nope'},
          ),
          type: DioExceptionType.badResponse,
        ),
        true,
      );
      return;
    }

    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true, 'data': payloads[code]},
      ),
      true,
    );
  }
}

void main() {
  late _StubInterceptor stub;
  late AttachmentAssetService service;

  setUp(() {
    stub = _StubInterceptor();
    final client = ApiClient(baseUrl: 'http://localhost');
    client.client.interceptors.clear();
    client.client.interceptors.add(stub);
    service = AttachmentAssetService(client);
  });

  Map<String, Object?> asset({
    String url = 'https://cdn.test/a.jpg?sig=1',
    String fileName = 'a.jpg',
    String contentType = 'image/jpeg',
    String mediaType = 'IMAGE',
    int sizeBytes = 80084,
    String status = 'UPLOADED',
  }) =>
      {
        'deliveryUrl': url,
        'fileName': fileName,
        'contentType': contentType,
        'mediaType': mediaType,
        'sizeBytes': sizeBytes,
        'status': status,
      };

  test('resolves a code into url plus metadata', () async {
    stub.payloads = {'AST_1': asset()};

    final result = await service.resolve('AST_1');

    expect(result.isReady, isTrue);
    expect(result.url, 'https://cdn.test/a.jpg?sig=1');
    expect(result.fileName, 'a.jpg');
    expect(result.sizeBytes, 80084);
    expect(result.isImage, isTrue);
    // Metadata comes back with the URL, so a row needs no second request.
    expect(result.displaySubtitle, 'JPG · 78 KB');
  });

  test('a second resolve is served from cache', () async {
    stub.payloads = {'AST_1': asset()};

    await service.resolve('AST_1');
    await service.resolve('AST_1');

    expect(stub.calls, 1);
    expect(service.cached('AST_1')?.isReady, isTrue);
  });

  test('concurrent resolves of one code share a single request', () async {
    stub.payloads = {'AST_1': asset()};

    final results = await Future.wait([
      service.resolve('AST_1'),
      service.resolve('AST_1'),
      service.resolve('AST_1'),
    ]);

    expect(stub.calls, 1);
    expect(results.every((r) => r.isReady), isTrue);
  });

  test('forceRefresh bypasses the cache — the Retry path', () async {
    stub.payloads = {'AST_1': asset()};
    await service.resolve('AST_1');

    stub.payloads = {'AST_1': asset(url: 'https://cdn.test/a.jpg?sig=2')};
    final again = await service.resolve('AST_1', forceRefresh: true);

    expect(stub.calls, 2);
    // A re-resolve is what recovers from an expired presigned URL.
    expect(again.url, endsWith('sig=2'));
  });

  test('invalidate drops the entry so the next read re-resolves', () async {
    stub.payloads = {'AST_1': asset()};
    await service.resolve('AST_1');
    expect(service.cached('AST_1'), isNotNull);

    service.invalidate('AST_1');

    expect(service.cached('AST_1'), isNull);
    await service.resolve('AST_1');
    expect(stub.calls, 2);
  });

  test('404 is reported as notFound and is not retryable', () async {
    stub.failures = {'AST_GONE': 404};

    final result = await service.resolve('AST_GONE');

    expect(result.hasFailed, isTrue);
    expect(result.failure, AttachmentAssetFailure.notFound);
    expect(result.isRetryable, isFalse);
    expect(result.failureLabel, 'This file is no longer available');
    // No point retrying a 404 — it must not burn the retry budget either.
    expect(stub.calls, 1);
  });

  test('a payload with no delivery URL reads as notReady, not as success',
      () async {
    stub.payloads = {
      'AST_1': asset(url: '', status: 'UPLOADED'),
    };

    final result = await service.resolve('AST_1');

    expect(result.isReady, isFalse);
    expect(result.failure, AttachmentAssetFailure.notReady);
    expect(result.isRetryable, isTrue);
    // Metadata still survives, so the row can name the file it can't show.
    expect(result.fileName, 'a.jpg');
  });

  test('a transient network error is retried, then succeeds', () async {
    stub.payloads = {'AST_1': asset()};
    stub.flakyRemaining = {'AST_1': 1};

    final result = await service.resolve('AST_1');

    expect(result.isReady, isTrue);
    expect(stub.calls, 2);
  });

  test('a persistent error is reported as retryable, never as empty', () async {
    stub.flakyRemaining = {'AST_1': 99};

    final result = await service.resolve('AST_1');

    expect(result.hasFailed, isTrue);
    expect(result.failure, AttachmentAssetFailure.error);
    expect(result.isRetryable, isTrue);
    expect(result.failureLabel, "Couldn't load this file");
    // The old resolver returned '' here, which the UI could not distinguish
    // from "still loading" — hence the endless spinner.
    expect(result.url, isEmpty);
  });

  test('failures are cached briefly so a bad row does not hammer the API',
      () async {
    stub.failures = {'AST_GONE': 404};

    await service.resolve('AST_GONE');
    await service.resolve('AST_GONE');

    expect(stub.calls, 1);
  });

  test('resolveAll returns results in the given order', () async {
    stub.payloads = {
      'AST_1': asset(fileName: 'one.jpg'),
      'AST_2': asset(fileName: 'two.pdf', contentType: 'application/pdf',
          mediaType: 'DOCUMENT'),
      'AST_3': asset(fileName: 'three.png', contentType: 'image/png'),
    };

    final results = await service.resolveAll(['AST_1', 'AST_2', 'AST_3']);

    expect(results.map((r) => r.fileName), ['one.jpg', 'two.pdf', 'three.png']);
    expect(results[1].isDocument, isTrue);
    expect(stub.calls, 3);
  });

  test('resolveAll reuses the cache and skips blanks', () async {
    stub.payloads = {'AST_1': asset(), 'AST_2': asset(fileName: 'b.jpg')};
    await service.resolve('AST_1');

    final results = await service.resolveAll(['AST_1', '  ', 'AST_2']);

    expect(results, hasLength(2));
    // AST_1 came from cache, so only AST_2 hit the network.
    expect(stub.calls, 2);
  });

  test('one failure in a batch does not sink the rest', () async {
    stub.payloads = {'AST_1': asset(), 'AST_3': asset(fileName: 'c.jpg')};
    stub.failures = {'AST_2': 404};

    final results = await service.resolveAll(['AST_1', 'AST_2', 'AST_3']);

    expect(results[0].isReady, isTrue);
    expect(results[1].hasFailed, isTrue);
    expect(results[2].isReady, isTrue);
  });

  test('an empty code fails fast without a request', () async {
    final result = await service.resolve('   ');

    expect(result.failure, AttachmentAssetFailure.notFound);
    expect(stub.calls, 0);
  });

  test('the url is read from a default variant when the asset has none',
      () async {
    stub.payloads = {
      'AST_1': {
        'fileName': 'scan.pdf',
        'contentType': 'application/pdf',
        'variants': [
          {'defaultVariant': false, 'url': 'https://cdn.test/thumb.jpg'},
          {'defaultVariant': true, 'deliveryUrl': 'https://cdn.test/full.pdf'},
        ],
      },
    };

    final result = await service.resolve('AST_1');

    expect(result.url, 'https://cdn.test/full.pdf');
    expect(result.isPdf, isTrue);
  });

  test('a PROCESSING asset is reported as processing, not as an error',
      () async {
    // Real payload shape: metadata, no URL, status PROCESSING.
    stub.payloads = {
      'AST_1': {
        'assetCode': 'AST_1',
        'mediaType': 'IMAGE',
        'status': 'PROCESSING',
        'fileName': 'photo.jpg',
        'contentType': 'image/jpeg',
        'sizeBytes': 80084,
      },
    };

    final result = await service.resolve('AST_1');

    expect(result.isReady, isFalse);
    expect(result.failure, AttachmentAssetFailure.notReady);
    expect(result.failureLabel, 'Still processing — try again in a moment');
    // Nothing to sign yet, so the resolve endpoint is not called: the GET
    // retries are the only requests.
    expect(stub.calls, lessThanOrEqualTo(3));
    // Metadata is still usable — the row can name the file it can't show yet.
    expect(result.fileName, 'photo.jpg');
    expect(result.displaySubtitle, 'JPG · 78 KB');
  });

  test('the resolve endpoint supplies the URL the GET lacks', () async {
    stub.payloads = {
      // Metadata only, as the real service returns.
      'AST_1': {
        'assetCode': 'AST_1',
        'mediaType': 'IMAGE',
        'status': 'READY',
        'fileName': 'photo.jpg',
        'contentType': 'image/jpeg',
        'sizeBytes': 80084,
      },
      // POST .../media-assets/resolve
      'resolve': [
        {'assetCode': 'AST_1', 'deliveryUrl': 'https://cdn.test/photo.jpg?sig=9'},
      ],
    };

    final result = await service.resolve('AST_1');

    expect(result.isReady, isTrue);
    expect(result.url, 'https://cdn.test/photo.jpg?sig=9');
    // Metadata from the GET survives alongside the URL from the resolve.
    expect(result.fileName, 'photo.jpg');
    expect(result.sizeBytes, 80084);
  });

  test('type is inferred from the url when the payload omits it', () async {
    stub.payloads = {
      'AST_1': {'deliveryUrl': 'https://cdn.test/photo.png?sig=1'},
    };

    final result = await service.resolve('AST_1');

    expect(result.isImage, isTrue);
    expect(result.extension, 'png');
    // Falls back to the code so a row is never unlabelled.
    expect(result.displayName, 'AST_1');
  });
}
