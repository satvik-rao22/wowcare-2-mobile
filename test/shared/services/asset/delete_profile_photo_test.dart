import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/api_paths_uat.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';

/// Hand-written fake — the project has no mocktail/mockito dev dependency and
/// its existing tests use hand-rolled fakes ("Fakes (hand-written, no
/// mocktail)" in activity_feed_cubit_test.dart), so this swaps Dio's transport
/// rather than mocking [ApiClient]. Everything above the adapter — BaseOptions,
/// interceptors, `validateStatus`, DioException construction — stays real, so
/// what the tests observe is what the app would actually send and receive.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;

  /// Every request this adapter saw, in order.
  final List<RequestOptions> captured = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(options);
    return _respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, int statusCode) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );

/// Builds a service whose transport is [adapter]. A bare [ApiClient] with no
/// interceptors is used deliberately: auth/context headers are the
/// interceptor's job and are explicitly out of scope for this method.
({AssetService service, _FakeAdapter adapter}) buildService(
  ResponseBody Function(RequestOptions options) respond,
) {
  final adapter = _FakeAdapter(respond);
  final apiClient = ApiClient(baseUrl: 'https://example.invalid');
  apiClient.client.httpClientAdapter = adapter;
  return (service: AssetService(apiClient), adapter: adapter);
}

void main() {
  // The identifiers from the captured UAT curls.
  const studentCode = 'STD_703E2987';
  const guardianCode = 'GUA_7367AD6C';
  const staffCode = 'STF_A31D9EF6-6';

  // Path components of those curl URLs, verbatim.
  //
  // These are NOT compared against the URL the service puts on the wire
  // directly: `ApiPaths.urlWithBase` only produces this doubled gateway form
  // when `ApiConstants.isGatewayEnv` is true, and under a plain `flutter test`
  // no isUat/isProd `--dart-define` is set, so the service correctly emits the
  // CANONICAL short path against a local dev host. Asserting the curl URL here
  // would only pass when the suite was run with the UAT defines — the trap
  // api_paths_uat_test.dart records having already been caught by once.
  //
  // Instead the tie to the curls runs the wire path back through
  // `ApiPathsUat.url`, which is what the app itself does on UAT. That rewrite
  // is idempotent, so this holds in BOTH environments.
  const studentUatPath =
      '/api/v1/student/student/delete-profile-photo/$studentCode';
  const guardianUatPath =
      '/api/v1/student/guardian/delete-profile-photo/$guardianCode';
  const staffUatPath =
      '/api/v1/staff/staff/my-profile/delete-profile-photo/$staffCode';

  ResponseBody ok(RequestOptions _) => _json(
    <String, dynamic>{'success': true, 'message': 'Deleted', 'data': null},
    200,
  );

  group('deleteProfilePhoto — request shape', () {
    test(
      'each owner POSTs to the path AND microservice base its switch selects',
      () async {
        // The full expected URL is built the same way the three finalize*
        // methods build theirs, so this pins BOTH halves of the switch: the
        // path, and the base (guardian must resolve to the STUDENT host, not a
        // guardian one — the thing most likely to be got wrong).
        for (final (owner, code, expectedUrl) in <
          (ProfilePhotoOwner, String, String)
        >[
          (
            ProfilePhotoOwner.student,
            studentCode,
            ApiPaths.urlWithBase(
              ApiPaths.studentDeleteProfilePhotoPath(studentCode),
              ApiConstants.studentBaseUrl,
            ),
          ),
          (
            ProfilePhotoOwner.guardian,
            guardianCode,
            ApiPaths.urlWithBase(
              ApiPaths.guardianDeleteProfilePhotoPath(guardianCode),
              ApiConstants.studentBaseUrl,
            ),
          ),
          (
            ProfilePhotoOwner.staff,
            staffCode,
            ApiPaths.urlWithBase(
              ApiPaths.staffDeleteProfilePhotoPath(staffCode),
              ApiConstants.staffBaseUrl,
            ),
          ),
        ]) {
          final t = buildService(ok);
          await t.service.deleteProfilePhoto(owner: owner, code: code);

          expect(t.adapter.captured, hasLength(1));
          final sent = t.adapter.captured.single;
          expect(sent.method, 'POST');
          expect(
            sent.uri.toString(),
            expectedUrl,
            reason: 'wrong endpoint for $owner',
          );
        }
      },
    );

    test('the guardian delete goes to the student host, not the staff one', () {
      // Explicit because the URLs above are env-derived: under the
      // single-gateway DEV/UAT/PROD shape, student and staff now share one
      // host, so a host/port comparison can no longer tell them apart — the
      // path prefix is what distinguishes them. Guards against the main test
      // above passing vacuously if the switch ever pointed guardian at the
      // staff path instead of the student one.
      expect(
        ApiPaths.urlWithBase(
          ApiPaths.guardianDeleteProfilePhotoPath(guardianCode),
          ApiConstants.studentBaseUrl,
        ),
        isNot(
          ApiPaths.urlWithBase(
            ApiPaths.staffDeleteProfilePhotoPath(staffCode),
            ApiConstants.staffBaseUrl,
          ),
        ),
        reason:
            'test premise: guardian and staff deletes must be distinguishable URLs',
      );
    });

    test('the wire path rewrites to the captured UAT curl URLs', () async {
      // Ties what the service actually sends to the real curls, in either
      // environment: in LOCAL/DEV the wire path is canonical and gets rewritten
      // here; under the UAT defines it is already the gateway form and the
      // rewrite is a no-op.
      for (final (owner, code, curlPath) in <
        (ProfilePhotoOwner, String, String)
      >[
        (ProfilePhotoOwner.student, studentCode, studentUatPath),
        (ProfilePhotoOwner.guardian, guardianCode, guardianUatPath),
        (ProfilePhotoOwner.staff, staffCode, staffUatPath),
      ]) {
        final t = buildService(ok);
        await t.service.deleteProfilePhoto(owner: owner, code: code);

        expect(
          ApiPathsUat.url(t.adapter.captured.single.uri.path),
          endsWith(curlPath),
          reason: 'wire path for $owner does not reach the curl URL on UAT',
        );
      }
    });

    test('the body is an empty map — not null, not an empty string', () async {
      final t = buildService(ok);
      await t.service.deleteProfilePhoto(
        owner: ProfilePhotoOwner.student,
        code: studentCode,
      );

      final data = t.adapter.captured.single.data;
      expect(data, isA<Map<String, dynamic>>());
      expect(data as Map<String, dynamic>, isEmpty);
      expect(data, isNot(isNull));
      expect(data, isNot(''));
    });

    test('the code is trimmed before it reaches the URL', () async {
      final t = buildService(ok);
      await t.service.deleteProfilePhoto(
        owner: ProfilePhotoOwner.staff,
        code: '  $staffCode  ',
      );
      expect(
        t.adapter.captured.single.uri.toString(),
        ApiPaths.urlWithBase(
          ApiPaths.staffDeleteProfilePhotoPath(staffCode),
          ApiConstants.staffBaseUrl,
        ),
      );
      expect(t.adapter.captured.single.uri.toString(), isNot(contains('%20')));
    });
  });

  group('deleteProfilePhoto — response ladder', () {
    test('2xx with success:true returns without throwing', () async {
      final t = buildService(ok);
      await expectLater(
        t.service.deleteProfilePhoto(
          owner: ProfilePhotoOwner.student,
          code: studentCode,
        ),
        completes,
      );
    });

    test(
      '2xx with success:false throws, carrying the server message verbatim',
      () async {
        final t = buildService(
          (_) => _json(<String, dynamic>{
            'success': false,
            'message': 'Profile photo is locked by an active enrollment',
            'data': null,
          }, 200),
        );

        await expectLater(
          t.service.deleteProfilePhoto(
            owner: ProfilePhotoOwner.guardian,
            code: guardianCode,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Profile photo is locked by an active enrollment'),
            ),
          ),
        );
      },
    );

    test('a success:false with no message still throws, with a fallback', () async {
      final t = buildService(
        (_) => _json(<String, dynamic>{'success': false, 'message': ''}, 200),
      );
      await expectLater(
        t.service.deleteProfilePhoto(
          owner: ProfilePhotoOwner.staff,
          code: staffCode,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Unable to delete profile photo'),
          ),
        ),
      );
    });

    test('404 returns without throwing — already deleted', () async {
      final t = buildService(
        (_) => _json(<String, dynamic>{
          'success': false,
          'message': 'Profile photo not found',
        }, 404),
      );

      await expectLater(
        t.service.deleteProfilePhoto(
          owner: ProfilePhotoOwner.student,
          code: studentCode,
        ),
        completes,
      );
    });

    test('403 propagates as a DioException, not a generic Exception', () async {
      final t = buildService(
        (_) => _json(<String, dynamic>{
          'success': false,
          'message': 'Forbidden',
        }, 403),
      );

      await expectLater(
        t.service.deleteProfilePhoto(
          owner: ProfilePhotoOwner.staff,
          code: staffCode,
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });

    test('401 propagates as a DioException so refresh-then-retry can run', () async {
      final t = buildService(
        (_) => _json(<String, dynamic>{'success': false}, 401),
      );

      await expectLater(
        t.service.deleteProfilePhoto(
          owner: ProfilePhotoOwner.guardian,
          code: guardianCode,
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });

    test('500 propagates as a DioException', () async {
      final t = buildService(
        (_) => _json(<String, dynamic>{
          'success': false,
          'message': 'Internal Server Error',
        }, 500),
      );

      await expectLater(
        t.service.deleteProfilePhoto(
          owner: ProfilePhotoOwner.student,
          code: studentCode,
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('a connection timeout propagates unchanged — no retry loop', () async {
      final adapter = _FakeAdapter((options) {
        throw DioException.connectionTimeout(
          timeout: const Duration(seconds: 1),
          requestOptions: options,
        );
      });
      final apiClient = ApiClient(baseUrl: 'https://example.invalid');
      apiClient.client.httpClientAdapter = adapter;
      final service = AssetService(apiClient);

      await expectLater(
        service.deleteProfilePhoto(
          owner: ProfilePhotoOwner.student,
          code: studentCode,
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionTimeout,
          ),
        ),
      );
      // Exactly one attempt: the method must not retry.
      expect(adapter.captured, hasLength(1));
    });
  });
}
