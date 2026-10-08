import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/observability/telemetry_config.dart';
import 'package:wowcare/core/observability/telemetry_privacy.dart';
import 'package:wowcare/core/observability/telemetry_redactor.dart';

/// Severity of a [Telemetry.log] line.
enum TelemetryLogLevel { debug, info, warn, error }

/// The app's only door to Sentry.
///
/// Feature code never imports `sentry_flutter`; it calls this, and the
/// methods here are the whole vocabulary. Crashlytics keeps ownership of fatal
/// crashes and crash-free users, so nothing here can mark a report fatal:
/// [captureError] is for handled, non-fatal errors.
///
/// Every method is a no-op when Sentry is off, which is every build without a
/// `SENTRY_DSN` define. See [TelemetryConfig.isEnabled].
///
/// The PII rule is the same as for `AppLogger.trail`: no path, name, email,
/// token, or user, student, staff, school or organisation code in a message,
/// breadcrumb or attribute. The hooks in [TelemetryPrivacy] are a safety net,
/// not a licence.
abstract final class Telemetry {
  Telemetry._();

  /// Replaces `WidgetsFlutterBinding.ensureInitialized()`. Sentry's binding
  /// is a plain `WidgetsFlutterBinding` plus frame-timing hooks that stay
  /// dormant unless the SDK is started.
  static void ensureBindingInitialized() {
    SentryWidgetsFlutterBinding.ensureInitialized();
  }

  /// Starts the SDK when [config] enables it, then runs [appRunner].
  ///
  /// Call this after the Crashlytics `FlutterError.onError` and
  /// `PlatformDispatcher.onError` handlers are installed: Sentry wraps whatever
  /// handlers exist at init and calls them after its own capture, so the
  /// order is what keeps a crash landing in Crashlytics exactly once.
  static Future<void> run(
    FutureOr<void> Function() appRunner, {
    TelemetryConfig config = TelemetryConfig.fromBuild,
  }) async {
    if (!config.isEnabled) {
      await appRunner();
      return;
    }
    await SentryFlutter.init(
      (options) => configureOptions(options, config),
      appRunner: appRunner,
    );
  }

  /// Wraps the root widget in Sentry's widget when the SDK is on, and returns
  /// [child] untouched otherwise, so a disabled build has an identical tree.
  static Widget wrapApp(
    Widget child, {
    TelemetryConfig config = TelemetryConfig.fromBuild,
  }) {
    return config.isEnabled ? SentryWidget(child: child) : child;
  }

  static bool get isEnabled => Sentry.isEnabled;

  @visibleForTesting
  static void configureOptions(
    SentryFlutterOptions options,
    TelemetryConfig config,
  ) {
    options
      ..dsn = config.dsn
      ..environment = config.sentryEnvironment
      ..tracesSampleRate = config.tracesSampleRate
      ..debug = config.isDebugBuild
      ..enableLogs = true
      // Crashlytics owns native crashes and ANRs. The manifest sets
      // `io.sentry.ndk.enable=false` for the same reason.
      ..enableNativeCrashHandling = false
      // Uncaught Dart errors are still captured for context, but as `error`,
      // not `fatal`: Sentry's crash-free numbers must not compete with
      // Crashlytics', which is the one the team reads.
      ..markAutomaticallyCollectedErrorsAsFatal = false;
    // Left to the SDK's package-info fallback when not overridden, which
    // yields `<bundle id>@<version>+<build>` and `<build>` respectively.
    final release = config.release;
    if (release != null) options.release = release;
    final dist = config.dist;
    if (dist != null) options.dist = dist;
    options.addEventProcessor(_KeysEventProcessor());
    TelemetryPrivacy.configure(options);
  }

  /// Reports a handled error as a non-fatal event.
  ///
  /// [reason] names the operation that failed, in the fixed-vocabulary style
  /// of `AppLogger.recordError`. It is attached as a context so it stays
  /// searchable without becoming part of the event's grouping.
  static Future<void> captureError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    if (!isEnabled) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: reason == null
          ? null
          // Unlike the exception, contexts are not scrubbed on the way out,
          // and the reason is often a log line with a value interpolated.
          : (scope) => scope.setContexts(_reasonContextKey, {
              'reason': TelemetryRedactor.redactPathsAndUrls(reason),
            }),
    );
  }

  /// Adds a breadcrumb to the trail attached to the next event.
  static Future<void> breadcrumb(
    String message, {
    String? category,
    Map<String, Object?> data = const {},
  }) async {
    if (!isEnabled) return;
    await Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data.isEmpty ? null : Map<String, dynamic>.of(data),
      ),
    );
  }

  /// Emits a structured log line.
  ///
  /// [attributes] accept `String`, `int`, `double` and `bool`; anything else is
  /// stringified, so do not pass an object whose `toString()` carries user
  /// data.
  static FutureOr<void> log(
    String message, {
    TelemetryLogLevel level = TelemetryLogLevel.info,
    Map<String, Object> attributes = const {},
  }) {
    if (!isEnabled) return null;
    final sentryAttributes = {
      for (final MapEntry(:key, :value) in attributes.entries)
        key: _toAttribute(value),
    };
    final logger = Sentry.logger;
    return switch (level) {
      TelemetryLogLevel.debug => logger.debug(
        message,
        attributes: sentryAttributes,
      ),
      TelemetryLogLevel.info => logger.info(
        message,
        attributes: sentryAttributes,
      ),
      TelemetryLogLevel.warn => logger.warn(
        message,
        attributes: sentryAttributes,
      ),
      TelemetryLogLevel.error => logger.error(
        message,
        attributes: sentryAttributes,
      ),
    };
  }

  /// Identifies the session by an opaque id. Pass the user code, never a
  /// name or email.
  static FutureOr<void> setUser(String id) {
    if (!isEnabled) return null;
    return Sentry.configureScope((scope) => scope.setUser(SentryUser(id: id)));
  }

  static FutureOr<void> clearUser() {
    if (!isEnabled) return null;
    return Sentry.configureScope((scope) => scope.setUser(null));
  }

  /// Sets a low-cardinality, indexed label on every later event.
  static FutureOr<void> setTag(String key, String value) {
    if (!isEnabled) return null;
    return Sentry.configureScope((scope) => scope.setTag(key, value));
  }

  static FutureOr<void> removeTag(String key) {
    if (!isEnabled) return null;
    return Sentry.configureScope((scope) => scope.removeTag(key));
  }

  /// Records a fact for every later error event, like a Crashlytics custom
  /// key: overwrites on repeat, and is cheap enough for upload progress.
  ///
  /// Held here and attached when an event is sent, under the `keys` context,
  /// rather than written to the scope: every scope write is mirrored to the
  /// native SDK, which progress callbacks would flood.
  ///
  /// Same PII rule as [breadcrumb]. [value] should be a String, num or bool;
  /// anything else is stringified.
  static void setKey(String key, Object value) {
    if (!isEnabled) return;
    _keys[key] = value is String || value is num || value is bool
        ? value
        : value.toString();
  }

  static final Map<String, Object> _keys = {};

  @visibleForTesting
  static void resetKeys() => _keys.clear();

  static const String _reasonContextKey = 'report';
  static const String _keysContextKey = 'keys';

  static SentryAttribute _toAttribute(Object value) {
    return switch (value) {
      String() => SentryAttribute.string(value),
      bool() => SentryAttribute.bool(value),
      int() => SentryAttribute.int(value),
      double() => SentryAttribute.double(value),
      _ => SentryAttribute.string(value.toString()),
    };
  }
}

/// Attaches [Telemetry.setKey] facts to error events. Transactions skip them:
/// they describe a screen load, not the app's state at a failure.
class _KeysEventProcessor implements EventProcessor {
  @override
  SentryEvent? apply(SentryEvent event, Hint hint) {
    if (event is SentryTransaction || Telemetry._keys.isEmpty) return event;
    event.contexts[Telemetry._keysContextKey] = Map<String, Object>.of(
      Telemetry._keys,
    );
    return event;
  }
}
