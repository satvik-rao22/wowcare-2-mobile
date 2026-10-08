import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/observability/telemetry_redactor.dart';

void main() {
  group('TelemetryRedactor.redactPathsAndUrls', () {
    test('replaces a whole URL, query and signature included', () {
      const raw =
          'DioException: https://media.s3.amazonaws.com/org/child-emma.mp4'
          '?X-Amz-Signature=deadbeef (connection error)';

      final redacted = TelemetryRedactor.redactPathsAndUrls(raw);

      expect(redacted, 'DioException: <url> (connection error)');
    });

    test('replaces an absolute POSIX path', () {
      const raw =
          "PathNotFoundException: Cannot open file, path = "
          "'/data/user/0/com.wiseowl.wowcareapp/cache/REC_Emma.mp4' (errno = 2)";

      final redacted = TelemetryRedactor.redactPathsAndUrls(raw);

      expect(
        redacted,
        "PathNotFoundException: Cannot open file, path = '<path>' (errno = 2)",
      );
    });

    test('leaves text with nothing path- or URL-shaped untouched', () {
      const raw = 'Failed to upload file to storage';
      expect(TelemetryRedactor.redactPathsAndUrls(raw), raw);
    });
  });

  group('TelemetryRedactor.stripQueryString', () {
    test('cuts at the query', () {
      expect(
        TelemetryRedactor.stripQueryString('https://h/a/b?studentCode=S1'),
        'https://h/a/b',
      );
    });

    test('cuts at the fragment when there is no query', () {
      expect(
        TelemetryRedactor.stripQueryString('https://h/a#x'),
        'https://h/a',
      );
    });

    test('cuts at whichever of query and fragment comes first', () {
      expect(
        TelemetryRedactor.stripQueryString('https://h/a#x?y'),
        'https://h/a',
      );
      expect(
        TelemetryRedactor.stripQueryString('https://h/a?y#x'),
        'https://h/a',
      );
    });

    test('returns a URL without either unchanged', () {
      expect(
        TelemetryRedactor.stripQueryString('https://h/a/b'),
        'https://h/a/b',
      );
    });
  });

  group('TelemetryRedactor.stripQueryStrings', () {
    test('strips every URL in free text and keeps the rest', () {
      const raw =
          'GET https://api.example.com/v1/students?code=S1&page=2 then '
          'https://cdn.example.com/x.png#top done';

      expect(
        TelemetryRedactor.stripQueryStrings(raw),
        'GET https://api.example.com/v1/students then '
        'https://cdn.example.com/x.png done',
      );
    });

    test('does not treat a question mark outside a URL as a query', () {
      const raw = 'Did the sync finish? /dashboard/home';
      expect(TelemetryRedactor.stripQueryStrings(raw), raw);
    });
  });

  group('TelemetryRedactor.templatePath', () {
    test('replaces record codes and keeps the API version', () {
      expect(
        TelemetryRedactor.templatePath(
          '/api/v1/events/EVT_99E594B6AC/occurrences/OCC_DB3558B6C4/rsvps',
        ),
        '/api/v1/events/{id}/occurrences/{id}/rsvps',
      );
    });

    test('treats UUIDs and emails as ids', () {
      expect(
        TelemetryRedactor.templatePath(
          '/users/0b8f7c2e-4d1a-4e9b-a3f0-6c2d1e9f8a7b/invite/a@b.co',
        ),
        '/users/{id}/invite/{id}',
      );
    });

    test('leaves a static path alone and drops any query', () {
      expect(
        TelemetryRedactor.templatePath(
          '/api/v2/school-forte-configs/search?studentCode=STU-1',
        ),
        '/api/v2/school-forte-configs/search',
      );
      expect(
        TelemetryRedactor.templatePath('student/absent'),
        'student/absent',
      );
    });
  });
}
