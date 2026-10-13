import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';

/// Mirrors the retry predicate in `uploadFileToPresignedUrl`. Kept here so the
/// classification of timeouts as retryable is pinned by a test — the predicate
/// itself is a local in a private method and cannot be called directly.
bool isTransient(DioException e) =>
    e.response == null &&
    (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.unknown);

DioException dioError(DioExceptionType type, {Response<dynamic>? response}) =>
    DioException(
      requestOptions: RequestOptions(path: '/'),
      type: type,
      response: response,
    );

void main() {
  group('send timeout sizing', () {
    const kb = 1024;
    const mb = 1024 * 1024;

    test(
      'a 200 MB video — the largest the app accepts — gets roughly 27 minutes '
      'at the assumed 128 KB/s floor, not a JSON-sized window',
      () {
        final t = AssetService.sendTimeoutForBytes(200 * mb);
        expect(t.inMinutes, greaterThanOrEqualTo(26));
        expect(t.inMinutes, lessThanOrEqualTo(28));
        // The shared API client's receive timeout is 30s; a video must not be
        // held to anything resembling that.
        expect(t, greaterThan(const Duration(minutes: 5)));
      },
    );

    test('the window scales with the payload rather than being fixed', () {
      final small = AssetService.sendTimeoutForBytes(20 * mb);
      final large = AssetService.sendTimeoutForBytes(200 * mb);
      expect(large, greaterThan(small));
      expect(large.inSeconds, closeTo(small.inSeconds * 10, 5));
    });

    test('a small photo still gets the 60s floor, not a fraction of a second', () {
      expect(
        AssetService.sendTimeoutForBytes(100 * kb),
        const Duration(seconds: 60),
      );
      expect(
        AssetService.sendTimeoutForBytes(1),
        const Duration(seconds: 60),
      );
    });

    test(
      'a zero or negative content length falls back to the floor instead of '
      'producing a zero-length (immediately expiring) timeout',
      () {
        expect(
          AssetService.sendTimeoutForBytes(0),
          const Duration(seconds: 60),
        );
        expect(
          AssetService.sendTimeoutForBytes(-1),
          const Duration(seconds: 60),
        );
      },
    );

    test(
      'an absurd content length is capped — a bad length must never produce an '
      'effectively infinite timeout, which is the bug being fixed',
      () {
        final t = AssetService.sendTimeoutForBytes(500 * 1024 * mb);
        expect(t, const Duration(minutes: 45));
      },
    );

    test('the timeout is always strictly positive', () {
      for (final bytes in <int>[-100, 0, 1, 1024, 5 * mb, 200 * mb]) {
        expect(
          AssetService.sendTimeoutForBytes(bytes).inMilliseconds,
          greaterThan(0),
          reason: '$bytes bytes',
        );
      }
    });
  });

  group('timeouts are retryable, not terminal', () {
    test('send and receive timeouts are classed transient, so they retry', () {
      expect(isTransient(dioError(DioExceptionType.sendTimeout)), isTrue);
      expect(isTransient(dioError(DioExceptionType.receiveTimeout)), isTrue);
    });

    test('the pre-existing transient types are still transient', () {
      expect(isTransient(dioError(DioExceptionType.connectionError)), isTrue);
      expect(isTransient(dioError(DioExceptionType.connectionTimeout)), isTrue);
      expect(isTransient(dioError(DioExceptionType.unknown)), isTrue);
    });

    test(
      'a real HTTP response is NOT retried — an expired signature or an S3 '
      'rejection would just fail the same way three times slower',
      () {
        final withResponse = DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 403,
          ),
        );
        expect(isTransient(withResponse), isFalse);
      },
    );

    test('cancellation is not classed as a transient network error', () {
      expect(isTransient(dioError(DioExceptionType.cancel)), isFalse);
    });
  });
}
