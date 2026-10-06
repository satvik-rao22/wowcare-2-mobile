import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/observability/telemetry_privacy.dart';

/// These hooks are the PROD gate: every payload class Sentry can send is
/// pushed through its hook here with the exact data the SDK's own
/// integrations attach (navigation arguments, split-off query strings, the
/// scope user's name and email on logs), and must come out clean.
void main() {
  final hint = Hint();

  group('TelemetryPrivacy.configure', () {
    test('turns off every automatic collector that gathers PII', () {
      final options = SentryFlutterOptions();

      TelemetryPrivacy.configure(options);

      expect(options.sendDefaultPii, isFalse);
      expect(options.enablePrintBreadcrumbs, isFalse);
      expect(options.attachScreenshot, isFalse);
      // ignore: experimental_member_use
      expect(options.attachViewHierarchy, isFalse);
      expect(options.tracePropagationTargets, isEmpty);
    });

    test('installs all four scrubbing hooks', () {
      final options = SentryFlutterOptions();

      TelemetryPrivacy.configure(options);

      expect(options.beforeSend, same(TelemetryPrivacy.beforeSend));
      expect(
        options.beforeSendTransaction,
        same(TelemetryPrivacy.beforeSendTransaction),
      );
      expect(options.beforeBreadcrumb, same(TelemetryPrivacy.beforeBreadcrumb));
      expect(options.beforeSendLog, same(TelemetryPrivacy.beforeSendLog));
    });
  });

  group('TelemetryPrivacy.beforeBreadcrumb', () {
    test('drops navigation arguments and keeps the route names', () {
      final crumb = Breadcrumb(
        category: 'navigation',
        data: {
          'state': 'didPush',
          'from': '/dashboard',
          'from_arguments': {'studentCode': 'S1'},
          'to': '/students/detail',
          'to_arguments': {'studentCode': 'S1', 'name': 'Emma'},
        },
      );

      final scrubbed = TelemetryPrivacy.beforeBreadcrumb(crumb, hint)!;

      expect(scrubbed.data, {
        'state': 'didPush',
        'from': '/dashboard',
        'to': '/students/detail',
      });
    });

    test('drops the split-off query and strips any query left in a URL', () {
      final crumb = Breadcrumb(
        category: 'http',
        data: {
          'url': 'https://api/v1/students?studentCode=S1',
          'http.query': 'studentCode=S1',
          'http.fragment': 'top',
          'method': 'GET',
          'status_code': 200,
        },
      );

      final scrubbed = TelemetryPrivacy.beforeBreadcrumb(crumb, hint)!;

      expect(scrubbed.data, {
        'url': 'https://api/v1/students',
        'method': 'GET',
        'status_code': 200,
      });
    });

    test('strips query strings from the message', () {
      final crumb = Breadcrumb(message: 'opened https://a/b?token=t');

      final scrubbed = TelemetryPrivacy.beforeBreadcrumb(crumb, hint)!;

      expect(scrubbed.message, 'opened https://a/b');
    });

    test('passes null through and leaves a crumb with no data alone', () {
      expect(TelemetryPrivacy.beforeBreadcrumb(null, hint), isNull);

      final crumb = Breadcrumb(message: 'plain');
      final scrubbed = TelemetryPrivacy.beforeBreadcrumb(crumb, hint)!;
      expect(scrubbed.message, 'plain');
      expect(scrubbed.data, isNull);
    });
  });

  group('TelemetryPrivacy.beforeSend', () {
    test('redacts paths and URLs in every exception value', () {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'DioException',
            value: 'https://s3/bucket/emma.mp4?X-Amz-Signature=abc failed',
          ),
          SentryException(
            type: 'FileSystemException',
            value: "Cannot open '/data/user/0/app/cache/emma.mp4'",
          ),
        ],
      );

      final scrubbed = TelemetryPrivacy.beforeSend(event, hint)!;

      expect(scrubbed.exceptions![0].value, '<url> failed');
      expect(scrubbed.exceptions![1].value, "Cannot open '<path>'");
    });

    test('redacts the message', () {
      final event = SentryEvent(
        message: SentryMessage(
          'failed https://a/b?x=1',
          template: 'failed %s',
          params: ['https://a/b?x=1'],
        ),
      );

      final scrubbed = TelemetryPrivacy.beforeSend(event, hint)!;

      expect(scrubbed.message!.formatted, 'failed <url>');
      expect(scrubbed.message!.template, 'failed %s');
    });

    test('reduces the request to method and query-less URL', () {
      final event = SentryEvent(
        request: SentryRequest(
          method: 'POST',
          url: 'https://api/v1/attendance?studentCode=S1',
          queryString: 'studentCode=S1',
          cookies: 'session=abc',
          headers: {'Authorization': 'Bearer t'},
          data: {'pin': '1234'},
        ),
      );

      final scrubbed = TelemetryPrivacy.beforeSend(event, hint)!;
      final request = scrubbed.request!;

      expect(request.method, 'POST');
      expect(request.url, 'https://api/v1/attendance');
      expect(request.queryString, isNull);
      expect(request.cookies, isNull);
      expect(request.headers, isEmpty);
      expect(request.data, isNull);
    });

    test('scrubs the breadcrumbs attached to the event', () {
      final event = SentryEvent(
        breadcrumbs: [
          Breadcrumb(data: {'to': '/x', 'to_arguments': 'secret'}),
        ],
      );

      final scrubbed = TelemetryPrivacy.beforeSend(event, hint)!;

      expect(scrubbed.breadcrumbs!.single.data, {'to': '/x'});
    });

    test('keeps an event with nothing to scrub intact', () {
      final event = SentryEvent(
        exceptions: [SentryException(type: 'StateError', value: 'Bad state')],
        transaction: '/dashboard/home',
      );

      final scrubbed = TelemetryPrivacy.beforeSend(event, hint)!;

      expect(scrubbed.exceptions!.single.value, 'Bad state');
      expect(scrubbed.transaction, '/dashboard/home');
    });
  });

  group('TelemetryPrivacy.beforeSendTransaction', () {
    // The tracer type is not exported, so the transaction is produced by the
    // real pipeline and intercepted by the hook under test.
    SentryTransaction? captured;

    setUp(() async {
      captured = null;
      await Sentry.init((options) {
        options
          ..dsn = 'https://key@o1.ingest.sentry.io/1'
          ..tracesSampleRate = 1.0
          ..transport = _DiscardingTransport()
          ..beforeSendTransaction = (transaction, hint) {
            captured = TelemetryPrivacy.beforeSendTransaction(
              transaction,
              hint,
            );
            return captured;
          };
      });
    });

    tearDown(() => Sentry.close());

    test(
      'drops route arguments and query data from the trace and spans',
      () async {
        final transaction = Sentry.startTransaction(
          '/students/detail',
          'navigation',
        );
        transaction.setData('route_settings_arguments', {'studentCode': 'S1'});
        final span = transaction.startChild(
          'http.client',
          description: 'GET https://api/v1/students',
        );
        span.setData('http.query', 'studentCode=S1');
        span.setData('http.response.status_code', 200);
        await span.finish();
        await transaction.finish();

        final scrubbed = captured!;
        expect(scrubbed.transaction, '/students/detail');
        // The SDK adds its own bookkeeping keys to the trace data, so only
        // the absence of the argument key is asserted.
        expect(
          scrubbed.contexts.trace!.data,
          isNot(contains('route_settings_arguments')),
        );
        // ignore: deprecated_member_use
        expect(scrubbed.extra, isNot(contains('route_settings_arguments')));
        final spanData = scrubbed.spans.single.data;
        expect(spanData, isNot(contains('http.query')));
        expect(spanData, containsPair('http.response.status_code', 200));
      },
    );
  });

  group('TelemetryPrivacy.beforeSendLog', () {
    SentryLog log({
      String body = 'attendance.sign_in.succeeded',
      Map<String, SentryAttribute> attributes = const {},
    }) {
      return SentryLog(
        timestamp: DateTime.utc(2026, 10, 6),
        level: SentryLogLevel.info,
        body: body,
        attributes: Map.of(attributes),
      );
    }

    test('drops the scope user name and email but keeps the id', () {
      final scrubbed = TelemetryPrivacy.beforeSendLog(
        log(
          attributes: {
            'user.id': SentryAttribute.string('U1'),
            'user.name': SentryAttribute.string('Emma'),
            'user.email': SentryAttribute.string('emma@example.com'),
            'count': SentryAttribute.int(3),
          },
        ),
      )!;

      expect(scrubbed.attributes.keys, unorderedEquals(['user.id', 'count']));
    });

    test('strips query strings from the body and string attributes', () {
      final scrubbed = TelemetryPrivacy.beforeSendLog(
        log(
          body: 'GET https://api/v1/x?code=1 failed',
          attributes: {
            'url': SentryAttribute.string('https://api/v1/x?code=1'),
            'ok': SentryAttribute.bool(false),
          },
        ),
      )!;

      expect(scrubbed.body, 'GET https://api/v1/x failed');
      expect(scrubbed.attributes['url']!.value, 'https://api/v1/x');
      expect(scrubbed.attributes['ok']!.value, isFalse);
    });
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
