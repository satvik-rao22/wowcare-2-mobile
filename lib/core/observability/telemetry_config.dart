import 'package:flutter/foundation.dart'
    show immutable, kDebugMode, kProfileMode, kReleaseMode;

/// Compile-time inputs that decide whether Sentry runs and how it labels what
/// it sends.
///
/// Every value comes from `--dart-define`, so a build with no `SENTRY_DSN`
/// never initialises the SDK at all. Kept as a plain value object so the
/// enablement rules in [isEnabled] can be unit tested without a Sentry hub.
@immutable
class TelemetryConfig {
  const TelemetryConfig({
    required this.dsn,
    required this.environment,
    required this.isDebugBuild,
    this.forceEnabled = false,
    this.releaseOverride = '',
    this.distOverride = '',
    this.gitBranch = '',
    this.gitCommit = '',
    this.buildMode = 'release',
  });

  /// The running build's values.
  ///
  /// `ENVIRONMENT` defaults to `LOCAL`, which is one of the disabled cases: a
  /// bare `flutter run` with no defines must never report to Sentry.
  static const TelemetryConfig fromBuild = TelemetryConfig(
    dsn: String.fromEnvironment('SENTRY_DSN'),
    environment: String.fromEnvironment('ENVIRONMENT', defaultValue: 'LOCAL'),
    isDebugBuild: kDebugMode,
    forceEnabled: bool.fromEnvironment('SENTRY_FORCE'),
    releaseOverride: String.fromEnvironment('SENTRY_RELEASE'),
    distOverride: String.fromEnvironment('SENTRY_DIST'),
    gitBranch: String.fromEnvironment('GIT_BRANCH'),
    gitCommit: String.fromEnvironment('GIT_COMMIT'),
    buildMode: kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
  );

  static const String _localEnvironment = 'LOCAL';
  static const String _productionEnvironment = 'PROD';

  /// Sample a fifth of production transactions; everything else is low volume
  /// enough to keep whole.
  static const double _productionTracesSampleRate = 0.2;
  static const double _nonProductionTracesSampleRate = 1.0;

  /// Project DSN. Empty means Sentry stays off.
  final String dsn;

  /// The `ENVIRONMENT` define as passed (`DEV`, `UAT`, `PROD`, ...).
  final String environment;

  /// `kDebugMode` of the running build.
  final bool isDebugBuild;

  /// `SENTRY_FORCE=true`: report from a debug or LOCAL build, for verifying
  /// the pipeline from a development machine.
  final bool forceEnabled;

  /// `SENTRY_RELEASE`. Empty means the SDK derives
  /// `<bundle id>@<version>+<build>` from the package info at runtime.
  final String releaseOverride;

  /// `SENTRY_DIST`. Empty means the SDK uses the build number.
  final String distOverride;

  /// `GIT_BRANCH`, set by the Makefile and CI. Empty when built without it.
  final String gitBranch;

  /// `GIT_COMMIT`, the short hash the build came from.
  final String gitCommit;

  /// `debug`, `profile` or `release`.
  final String buildMode;

  /// Labels on every event and log line, so production and test builds can
  /// be told apart beyond the environment and release: which branch and
  /// commit, and whether it was a debug build. Empty values are left out.
  Map<String, String> get buildTags => {
    'build_mode': buildMode,
    if (gitBranch.isNotEmpty) 'git_branch': gitBranch,
    if (gitCommit.isNotEmpty) 'git_commit': gitCommit,
  };

  bool get isLocal => environment.toUpperCase() == _localEnvironment;

  bool get isProduction => environment.toUpperCase() == _productionEnvironment;

  /// Sentry runs only with a DSN, and only in release or profile builds of a
  /// non-LOCAL environment unless [forceEnabled] overrides that.
  bool get isEnabled {
    if (dsn.isEmpty) return false;
    if (forceEnabled) return true;
    return !isDebugBuild && !isLocal;
  }

  /// Sentry's environment label. Always set explicitly: the SDK otherwise
  /// labels every release build `production`.
  String get sentryEnvironment => environment.toLowerCase();

  double get tracesSampleRate => isProduction
      ? _productionTracesSampleRate
      : _nonProductionTracesSampleRate;

  String? get release => releaseOverride.isEmpty ? null : releaseOverride;

  String? get dist => distOverride.isEmpty ? null : distOverride;
}
