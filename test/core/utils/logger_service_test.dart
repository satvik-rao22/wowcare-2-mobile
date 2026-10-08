import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/observability/telemetry.dart';
import 'package:wowcare/core/observability/telemetry_config.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// AppLogger's Sentry side. The Crashlytics side is release-only and is not
/// reachable from a test.
void main() {
  final events = <SentryEvent>[];

  setUp(() async {
    events.clear();
    Telemetry.resetKeys();
    await Sentry.init(
      (options) {
        Telemetry.configureOptions(
          options as SentryFlutterOptions,
          const TelemetryConfig(
            dsn: 'https://key@o1.ingest.sentry.io/1',
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
      // ignore: invalid_use_of_internal_member
      options: SentryFlutterOptions(),
    );
  });

  tearDown(() async {
    Telemetry.resetKeys();
    await Sentry.close();
  });

  // AppLogger is synchronous and hands Sentry a future it does not await.
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('e reports the error with the message as its reason', () async {
    AppLogger.e('[ATTENDANCE] sign-in failed', StateError('boom'));
    await settle();

    final event = events.single;
    expect(event.exceptions!.single.type, 'StateError');
    expect(event.contexts['report'], {'reason': '[ATTENDANCE] sign-in failed'});
  });

  test('e without an error reports the message itself', () async {
    AppLogger.e('[REPORTS] load failed');
    await settle();

    expect(events.single.exceptions!.single.value, '[REPORTS] load failed');
  });

  test('recordError never reaches Sentry as a fatal', () async {
    AppLogger.recordError(
      StateError('boom'),
      StackTrace.current,
      reason: 'media.upload',
      fatal: true,
    );
    await settle();

    final event = events.single;
    expect(event.level, isNot(SentryLevel.fatal));
    expect(event.contexts['report'], {'reason': 'media.upload'});
  });

  test(
    'trail becomes a breadcrumb and setKey rides on the next event',
    () async {
      AppLogger.trail('media.picker_opened');
      AppLogger.setKey('media.attempt', 2);
      AppLogger.e('[MEDIA] upload failed', StateError('boom'));
      await settle();

      final event = events.single;
      final crumb = event.breadcrumbs!.singleWhere(
        (b) => b.category == 'trail',
      );
      expect(crumb.message, 'media.picker_opened');
      expect(event.contexts['keys'], {'media.attempt': 2});
    },
  );
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
