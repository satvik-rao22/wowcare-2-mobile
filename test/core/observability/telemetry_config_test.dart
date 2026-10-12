import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/observability/telemetry_config.dart';

/// The enablement matrix is the guarantee that no build reports to Sentry by
/// accident: a missing DSN, a debug build or a LOCAL environment each keep it
/// off on their own, and only an explicit force flag overrides the latter two.
void main() {
  const dsn = 'https://key@o1.ingest.sentry.io/1';

  TelemetryConfig config({
    String dsn = dsn,
    String environment = 'DEV',
    bool isDebugBuild = false,
    bool forceEnabled = false,
    String releaseOverride = '',
    String distOverride = '',
  }) {
    return TelemetryConfig(
      dsn: dsn,
      environment: environment,
      isDebugBuild: isDebugBuild,
      forceEnabled: forceEnabled,
      releaseOverride: releaseOverride,
      distOverride: distOverride,
    );
  }

  group('TelemetryConfig.isEnabled', () {
    test('is on for a release build of a non-LOCAL environment with a DSN', () {
      expect(config().isEnabled, isTrue);
      expect(config(environment: 'UAT').isEnabled, isTrue);
      expect(config(environment: 'PROD').isEnabled, isTrue);
    });

    test('is off without a DSN, whatever else is set', () {
      expect(config(dsn: '').isEnabled, isFalse);
      expect(config(dsn: '', forceEnabled: true).isEnabled, isFalse);
    });

    test('is off in a debug build', () {
      expect(config(isDebugBuild: true).isEnabled, isFalse);
    });

    test('is off for LOCAL, case-insensitively', () {
      expect(config(environment: 'LOCAL').isEnabled, isFalse);
      expect(config(environment: 'local').isEnabled, isFalse);
    });

    test('SENTRY_FORCE overrides the debug and LOCAL rules', () {
      expect(config(isDebugBuild: true, forceEnabled: true).isEnabled, isTrue);
      expect(
        config(environment: 'LOCAL', forceEnabled: true).isEnabled,
        isTrue,
      );
    });

    test('the build-time default is LOCAL, so a bare build stays off', () {
      // A bare `flutter test` has no SENTRY_DSN define either, so this also
      // pins the "no DSN" case for the real constant.
      expect(TelemetryConfig.fromBuild.environment, 'LOCAL');
      expect(TelemetryConfig.fromBuild.isEnabled, isFalse);
    });
  });

  group('TelemetryConfig labels', () {
    test('environment is lower-cased for Sentry', () {
      expect(config(environment: 'DEV').sentryEnvironment, 'dev');
      expect(config(environment: 'Prod').sentryEnvironment, 'prod');
    });

    test('production is recognised case-insensitively', () {
      expect(config(environment: 'PROD').isProduction, isTrue);
      expect(config(environment: 'prod').isProduction, isTrue);
      expect(config(environment: 'UAT').isProduction, isFalse);
    });

    test('traces are sampled at a fifth in production, whole elsewhere', () {
      expect(config(environment: 'PROD').tracesSampleRate, 0.2);
      expect(config(environment: 'UAT').tracesSampleRate, 1.0);
      expect(config(environment: 'DEV').tracesSampleRate, 1.0);
    });

    test('release and dist are null unless overridden', () {
      expect(config().release, isNull);
      expect(config().dist, isNull);
      expect(
        config(releaseOverride: 'com.example@1.0.0+7').release,
        'com.example@1.0.0+7',
      );
      expect(config(distOverride: '7').dist, '7');
    });
  });

  test('buildTags leave out what the build did not set', () {
    expect(
      const TelemetryConfig(
        dsn: '',
        environment: 'PROD',
        isDebugBuild: false,
      ).buildTags,
      {'build_mode': 'release'},
    );
    expect(
      const TelemetryConfig(
        dsn: '',
        environment: 'DEV',
        isDebugBuild: true,
        gitBranch: 'stage',
        gitCommit: 'abc1234',
        buildMode: 'debug',
      ).buildTags,
      {'build_mode': 'debug', 'git_branch': 'stage', 'git_commit': 'abc1234'},
    );
  });
}
