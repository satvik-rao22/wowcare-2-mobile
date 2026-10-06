import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/observability/telemetry.dart';
import 'package:wowcare/core/observability/telemetry_config.dart';

void main() {
  const dsn = 'https://key@o1.ingest.sentry.io/1';

  group('Telemetry.configureOptions', () {
    TelemetryConfig config({
      String environment = 'DEV',
      bool isDebugBuild = false,
      String releaseOverride = '',
      String distOverride = '',
    }) {
      return TelemetryConfig(
        dsn: dsn,
        environment: environment,
        isDebugBuild: isDebugBuild,
        releaseOverride: releaseOverride,
        distOverride: distOverride,
      );
    }

    test('labels, samples and keeps crash ownership with Crashlytics', () {
      final options = SentryFlutterOptions();

      Telemetry.configureOptions(options, config(environment: 'PROD'));

      expect(options.dsn, dsn);
      expect(options.environment, 'prod');
      expect(options.tracesSampleRate, 0.2);
      expect(options.enableNativeCrashHandling, isFalse);
      expect(options.markAutomaticallyCollectedErrorsAsFatal, isFalse);
      expect(options.enableLogs, isTrue);
      expect(options.debug, isFalse);
    });

    test('leaves release and dist to the SDK unless overridden', () {
      final options = SentryFlutterOptions();

      Telemetry.configureOptions(options, config());

      expect(options.release, isNull);
      expect(options.dist, isNull);
    });

    test('applies release and dist overrides', () {
      final options = SentryFlutterOptions();

      Telemetry.configureOptions(
        options,
        config(releaseOverride: 'com.example@1.2.3+9', distOverride: '9'),
      );

      expect(options.release, 'com.example@1.2.3+9');
      expect(options.dist, '9');
    });
  });

  group('Telemetry while Sentry is off', () {
    test('every call is a harmless no-op', () async {
      expect(Telemetry.isEnabled, isFalse);

      await Telemetry.captureError(StateError('x'), null, reason: 'r');
      await Telemetry.breadcrumb('b');
      await Telemetry.log('l');
      await Telemetry.setUser('U1');
      await Telemetry.setTag('k', 'v');
      await Telemetry.removeTag('k');
      await Telemetry.clearUser();
    });

    test(
      'run just runs the app and wrapApp returns the child itself',
      () async {
        const config = TelemetryConfig(
          dsn: '',
          environment: 'DEV',
          isDebugBuild: false,
        );
        var ran = false;

        await Telemetry.run(() => ran = true, config: config);

        expect(ran, isTrue);
        const child = SizedBox();
        expect(Telemetry.wrapApp(child, config: config), same(child));
      },
    );
  });

  group('Telemetry while Sentry is on', () {
    final events = <SentryEvent>[];
    final logs = <SentryLog>[];

    setUp(() async {
      events.clear();
      logs.clear();
      await Sentry.init((options) {
        options
          ..dsn = dsn
          ..enableLogs = true
          ..transport = _DiscardingTransport()
          ..beforeSend = (event, hint) {
            events.add(event);
            return event;
          }
          ..beforeSendLog = (log) {
            logs.add(log);
            return log;
          };
      });
    });

    tearDown(() => Sentry.close());

    test('captureError sends a non-fatal event carrying the reason', () async {
      await Telemetry.captureError(
        StateError('boom'),
        StackTrace.current,
        reason: 'attendance.sign_in',
      );

      final event = events.single;
      expect(event.level, isNot(SentryLevel.fatal));
      expect(event.exceptions!.single.type, 'StateError');
      expect(event.contexts['report'], {'reason': 'attendance.sign_in'});
    });

    test('breadcrumb lands on the scope with category and data', () async {
      await Telemetry.breadcrumb(
        'picker opened',
        category: 'media',
        data: {'source': 'camera'},
      );

      late List<Breadcrumb> crumbs;
      await Sentry.configureScope((scope) => crumbs = scope.breadcrumbs);
      final crumb = crumbs.single;
      expect(crumb.message, 'picker opened');
      expect(crumb.category, 'media');
      expect(crumb.data, {'source': 'camera'});
    });

    test('log emits a structured log with typed attributes', () async {
      await Telemetry.log(
        'attendance.sign_in.succeeded',
        level: TelemetryLogLevel.warn,
        attributes: {
          'count': 3,
          'ok': true,
          'ratio': 0.5,
          'kind': 'student',
          'other': Duration(seconds: 1),
        },
      );

      final log = logs.single;
      expect(log.body, 'attendance.sign_in.succeeded');
      expect(log.level, SentryLogLevel.warn);
      expect(log.attributes['count']!.value, 3);
      expect(log.attributes['ok']!.value, isTrue);
      expect(log.attributes['ratio']!.value, 0.5);
      expect(log.attributes['kind']!.value, 'student');
      expect(log.attributes['other']!.value, '0:00:01.000000');
    });

    test('setUser records the id alone and clearUser removes it', () async {
      await Telemetry.setUser('U1');
      late SentryUser? user;
      await Sentry.configureScope((scope) => user = scope.user);
      expect(user!.id, 'U1');
      expect(user!.name, isNull);
      expect(user!.email, isNull);

      await Telemetry.clearUser();
      await Sentry.configureScope((scope) => user = scope.user);
      expect(user, isNull);
    });

    test('setTag and removeTag edit the scope tags', () async {
      await Telemetry.setTag('persona', 'staff');
      late Map<String, String> tags;
      await Sentry.configureScope((scope) => tags = scope.tags);
      expect(tags, {'persona': 'staff'});

      await Telemetry.removeTag('persona');
      await Sentry.configureScope((scope) => tags = scope.tags);
      expect(tags, isEmpty);
    });
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
