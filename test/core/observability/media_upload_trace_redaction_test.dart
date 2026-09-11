import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/observability/media_upload_trace.dart';

/// The redaction in [MediaUploadTrace.failure] is the flow's PII guarantee:
/// the exceptions this flow actually throws are precisely the ones that carry
/// sensitive text in their own message, so it is asserted here rather than
/// assumed. If someone loosens the regexes, these fail.
void main() {
  group('MediaUploadTrace redaction', () {
    test(
      'strips the absolute path out of a dart:io file exception, keeping the '
      'exception type and errno that make the report diagnosable',
      () {
        const raw =
            "PathNotFoundException: Cannot open file, path = "
            "'/data/user/0/com.wiseowl.wowcareapp/cache/REC_20260910_Emma_Watson.mp4' "
            '(OS Error: No such file or directory, errno = 2)';

        final redacted = MediaUploadTrace.debugRedact(raw);

        expect(redacted, contains('PathNotFoundException'));
        expect(redacted, contains('errno = 2'));
        expect(redacted, contains('<path>'));
        // A recorded video's basename routinely carries a child's name.
        expect(redacted, isNot(contains('Emma')));
        expect(redacted, isNot(contains('wowcareapp')));
      },
    );

    test('strips an iOS container path, whose UUID identifies the install', () {
      const raw =
          'FileSystemException: Cannot open file, path = '
          "'/var/mobile/Containers/Data/Application/8B3F-AA11/tmp/trim.A1B2.MOV'";

      final redacted = MediaUploadTrace.debugRedact(raw);

      expect(redacted, contains('FileSystemException'));
      expect(redacted, isNot(contains('8B3F-AA11')));
      expect(redacted, isNot(contains('trim.A1B2')));
    });

    test(
      'strips the whole presigned S3 URL — it is a bearer credential, so the '
      'signature and key id must never reach a crash report',
      () {
        const raw =
            'DioException [connection error]: '
            'https://wowcare-media.s3.eu-central-1.amazonaws.com/org/school/child-emma.mp4'
            '?X-Amz-Algorithm=AWS4-HMAC-SHA256'
            '&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20260910'
            '&X-Amz-Signature=deadbeefcafe';

        final redacted = MediaUploadTrace.debugRedact(raw);

        expect(redacted, contains('DioException'));
        expect(redacted, contains('connection error'));
        expect(redacted, isNot(contains('X-Amz-Signature')));
        expect(redacted, isNot(contains('AKIAIOSFODNN7EXAMPLE')));
        expect(redacted, isNot(contains('amazonaws')));
        expect(redacted, isNot(contains('emma')));
      },
    );

    test('leaves a message with nothing sensitive in it untouched', () {
      const raw = 'Failed to upload file to storage';
      expect(MediaUploadTrace.debugRedact(raw), raw);
    });
  });
}
