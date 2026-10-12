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

    test('applies the privacy guardrails', () {
      final options = SentryFlutterOptions();

      Telemetry.configureOptions(options, config());

      expect(options.sendDefaultPii, isFalse);
      expect(options.enablePrintBreadcrumbs, isFalse);
      expect(options.tracePropagationTargets, isEmpty);
      expect(options.beforeSend, isNotNull);
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
      Telemetry.setKey('k', 1);
      await Telemetry.setSession(
        userCode: 'U1',
        persona: 'staff',
        organizationCode: 'ORG1',
        schoolCode: 'SCH1',
        kiosk: false,
      );
      await Telemetry.clearSession();
    });

    test('navigatorObserver is a plain observer', () {
      const config = TelemetryConfig(
        dsn: '',
        environment: 'DEV',
        isDebugBuild: false,
      );

      final observer = Telemetry.navigatorObserver(config: config);

      expect(observer, isNot(isA<SentryNavigatorObserver>()));
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

    test('captureError redacts paths and URLs in the reason', () async {
      await Telemetry.captureError(
        StateError('boom'),
        null,
        reason: 'upload failed for https://s3.example.com/a.mp4?sig=x',
      );

      expect(events.single.contexts['report'], {
        'reason': 'upload failed for <url>',
      });
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

    test('setSession labels the scope and clearSession undoes it', () async {
      await Telemetry.setSession(
        userCode: 'USR-1',
        persona: 'staff',
        organizationCode: 'ORG-1',
        schoolCode: '',
        kiosk: false,
      );
      late SentryUser? user;
      late Map<String, String> tags;
      await Sentry.configureScope((scope) {
        user = scope.user;
        tags = scope.tags;
      });
      expect(user!.id, 'USR-1');
      // An empty school (org picked, school not yet) sets no blank tag.
      expect(tags, {'persona': 'staff', 'org_code': 'ORG-1', 'kiosk': 'false'});

      await Telemetry.clearSession();
      await Sentry.configureScope((scope) {
        user = scope.user;
        tags = scope.tags;
      });
      expect(user, isNull);
      expect(tags, isEmpty);
    });

    test('navigatorObserver is Sentry\'s when enabled', () {
      const config = TelemetryConfig(
        dsn: dsn,
        environment: 'DEV',
        isDebugBuild: false,
      );

      final observer = Telemetry.navigatorObserver(config: config);

      expect(observer, isA<SentryNavigatorObserver>());
    });
  });

  group('Telemetry.screenName', () {
    test('templates record codes and drops the arguments', () {
      const settings = RouteSettings(
        name: '/events/EVT_99E594B6AC',
        arguments: {'code': 'EVT_99E594B6AC'},
      );

      final named = Telemetry.screenName(settings)!;

      expect(named.name, '/events/{id}');
      expect(named.arguments, isNull);
    });

    test('passes unnamed routes through', () {
      expect(Telemetry.screenName(null), isNull);
      const settings = RouteSettings();
      expect(Telemetry.screenName(settings), same(settings));
    });
  });

  group('Telemetry.setKey', () {
    final events = <SentryEvent>[];

    setUp(() async {
      events.clear();
      Telemetry.resetKeys();
      await Sentry.init(
        (options) {
          Telemetry.configureOptions(
            options as SentryFlutterOptions,
            const TelemetryConfig(
              dsn: dsn,
              environment: 'DEV',
              isDebugBuild: false,
            ),
          );
          options
            ..transport = _DiscardingTransport()
            ..beforeSend = (event, hint) {
              events.add(event);
              return event;
            };
        },
        // What SentryFlutter.init passes, so the Flutter options type holds.
        // ignore: invalid_use_of_internal_member
        options: SentryFlutterOptions(),
      );
    });

    tearDown(() async {
      Telemetry.resetKeys();
      await Sentry.close();
    });

    test('attaches the latest value of each key to error events', () async {
      Telemetry.setKey('upload.bytes_uploaded', 10);
      Telemetry.setKey('upload.bytes_uploaded', 20);
      Telemetry.setKey('upload.source', 'camera');
      Telemetry.setKey('upload.elapsed', const Duration(seconds: 1));

      await Telemetry.captureError(StateError('x'), null);

      expect(events.single.contexts['keys'], {
        'upload.bytes_uploaded': 20,
        'upload.source': 'camera',
        'upload.elapsed': '0:00:01.000000',
      });
    });

    test('adds no keys context when nothing was set', () async {
      await Telemetry.captureError(StateError('x'), null);

      expect(events.single.contexts.containsKey('keys'), isFalse);
    });
  });

  group('build tags', () {
    final events = <SentryEvent>[];
    final logs = <SentryLog>[];

    setUp(() async {
      events.clear();
      logs.clear();
      await Sentry.init(
        (options) {
          Telemetry.configureOptions(
            options as SentryFlutterOptions,
            const TelemetryConfig(
              dsn: dsn,
              environment: 'UAT',
              isDebugBuild: false,
              gitBranch: 'enhancements/sentry-integration',
              gitCommit: 'abc1234',
              buildMode: 'profile',
            ),
          );
          options
            ..transport = _DiscardingTransport()
            ..beforeSend = (event, hint) {
              events.add(event);
              return event;
            }
            ..beforeSendLog = (log) {
              logs.add(log);
              return log;
            };
        },
        // ignore: invalid_use_of_internal_member
        options: SentryFlutterOptions(),
      );
    });

    tearDown(Sentry.close);

    const expected = {
      'build_mode': 'profile',
      'git_branch': 'enhancements/sentry-integration',
      'git_commit': 'abc1234',
    };

    test('tag every error event with branch, commit and build mode', () async {
      await Telemetry.captureError(StateError('x'), null);

      expect(events.single.tags, containsPair('git_commit', 'abc1234'));
      expect(
        events.single.tags,
        allOf([
          for (final MapEntry(:key, :value) in expected.entries)
            containsPair(key, value),
        ]),
      );
    });

    test('ride on every log line as attributes', () async {
      await Telemetry.log('task.create.succeeded');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final attributes = {
        for (final MapEntry(:key, :value) in logs.single.attributes.entries)
          if (expected.containsKey(key)) key: value.value,
      };
      expect(attributes, expected);
    });
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
