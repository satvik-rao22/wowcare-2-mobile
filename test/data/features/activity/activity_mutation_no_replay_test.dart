import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/session_expired_interceptor.dart';
import 'package:wowcare/data/features/activity/datasources/activity_remote_datasource.dart';
import 'package:wowcare/data/features/activity/models/activity_settings_models.dart';

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
    'createActivity is flagged noAutoReplay so the 401 interceptor will not '
    'silently duplicate the activity after a token refresh',
    () async {
      final adapter = _CapturingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final ds = ActivityRemoteDataSourceImpl(dio);

      try {
        await ds.createActivity(
          request: ActivityCreateRequestModel(
            activityTypeCode: 'T',
            classroomCode: 'C',
            studentCodes: const ['STU-1'],
            staffCode: 'STAFF-1',
            schoolCode: 'SCH-1',
            organizationCode: 'ORG-1',
            activityDate: '2026-01-01T00:00:00Z',
            description: 'd',
          ),
        );
      } catch (_) {
        // Ignore parse/shape errors — the request is captured before any parse.
      }

      expect(adapter.captured, isNotNull);
      expect(adapter.captured!.extra[kNoAutoReplayExtraKey], isTrue);
    },
  );
}
