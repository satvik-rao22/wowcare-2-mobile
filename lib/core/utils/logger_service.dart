import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:wowcare/core/observability/telemetry.dart';
import 'package:wowcare/core/utils/app_console.dart';

/// A centralized, environment-aware logging utility.
///
/// In debug builds every call prints to the console through [AppConsole]:
/// coloured by level, timestamped, and with the calling `file:line`, so a
/// line leads back to its code. Errors also show their stack trace.
///
/// Debug/info/warning messages print to the console in debug builds only and
/// are **NOT** emitted in release/profile builds. This is deliberate: callers
/// routinely pass unsanitized content (full API request/response bodies,
/// tokens, PINs, student/staff identifiers) to these methods, so forwarding
/// them anywhere in production would exfiltrate sensitive/PII data. Genuine
/// error reporting still reaches Crashlytics via [e]/[c] (which take an
/// explicit error object), keeping crash observability intact.
///
/// [e], [recordError], [trail] and [setKey] also feed Sentry through
/// [Telemetry], which is a no-op unless Sentry is on for this build. Sentry
/// never gets a fatal: Crashlytics owns those.
class AppLogger {
  /// Logs a debug message (cyan). Debug builds only; no-op in release.
  static void d(Object? message) {
    if (kDebugMode) {
      AppConsole.debug(message);
    }
    // Release/profile: intentionally no-op — never forward raw debug content
    // (may contain API bodies / PII) to any sink.
  }

  /// Logs an info message (green). Debug builds only; no-op in release.
  static void i(Object? message) {
    if (kDebugMode) {
      AppConsole.info(message);
    }
    // Release/profile: intentionally no-op — see [d].
  }

  /// Logs a warning message (orange). Debug builds only; no-op in release.
  static void w(Object? message) {
    if (kDebugMode) {
      AppConsole.warning(message);
    }
    // Release/profile: intentionally no-op — see [d].
  }

  /// Logs an error message (red) and reports it as a non-fatal to
  /// Crashlytics (release) and Sentry.
  ///
  /// A [StackTrace] passed as [error] (`AppLogger.e('…', stack)`) is taken as
  /// the stack trace, so the report carries the message plus that trace.
  static void e(Object? message, [Object? error, StackTrace? stackTrace]) {
    if (error is StackTrace) {
      stackTrace ??= error;
      error = null;
    }
    final reported = error ?? message;
    if (reported != null) {
      unawaited(
        Telemetry.captureError(
          reported,
          stackTrace,
          reason: error == null ? null : '$message',
        ),
      );
    }
    if (kDebugMode) {
      AppConsole.error(message, cause: error, stackTrace: stackTrace);
    } else {
      try {
        FirebaseCrashlytics.instance.recordError(
          error ?? message,
          stackTrace,
          reason: message,
          fatal: false,
        );
      } catch (_) {}
    }
  }

  /// Logs a console-only error message (Red) and a Crashlytics breadcrumb.
  /// Does NOT trigger a Crashlytics non-fatal error event.
  static void c(Object? message, [Object? error, StackTrace? stackTrace]) {
    if (error is StackTrace) {
      stackTrace ??= error;
      error = null;
    }
    if (kDebugMode) {
      AppConsole.error(message, cause: error, stackTrace: stackTrace);
    } else {
      try {
        FirebaseCrashlytics.instance.log('[ERROR] $message');
        if (error != null) {
          FirebaseCrashlytics.instance.log('[Error Detail] $error');
        }
      } catch (_) {}
    }
  }

  /// Records a **breadcrumb that survives release builds**.
  ///
  /// [d]/[i]/[w] are deliberately release no-ops because callers hand them raw
  /// API bodies, tokens and PII. That safety rule left flows whose breadcrumbs
  /// were written with [d] completely dark in production: a crash arrives with
  /// no trace of the stage it died in. This is the opposite contract — the
  /// caller guarantees the message is a short, PII-free stage marker, and in
  /// exchange it reaches Crashlytics.
  ///
  /// **Never interpolate a file path, user/student/staff code, name, email or
  /// any API payload into [message].** Facts belong in [setKey], which is held
  /// to the same rule. Prefer a fixed vocabulary over free text.
  ///
  /// Unlike [c] this is not styled as an error, so a normal stage transition is
  /// not mislabelled in the Crashlytics timeline.
  ///
  /// Crashlytics retains only the most recent ~64 log entries per report, so
  /// this is for stage transitions — anything high-frequency (upload progress,
  /// poll ticks) belongs in [setKey], which overwrites instead of accumulating.
  static void trail(String message) {
    unawaited(Telemetry.breadcrumb(message, category: 'trail'));
    if (kDebugMode) {
      AppConsole.trail(message);
      return;
    }
    try {
      FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  /// Attaches a fact to any crash report produced from here on, in release.
  ///
  /// Overwrites on repeat, so it is safe to call at high frequency (upload
  /// progress) where [trail] would blow the breadcrumb budget. Crashlytics
  /// caps custom keys at 64 per report.
  ///
  /// Same PII rule as [trail]: sizes, counts, durations, enum-ish labels and
  /// booleans only — never a path, identifier or name. [value] must be a
  /// String, num or bool; anything else is stringified, so do not pass an
  /// object whose `toString()` could carry user data.
  static void setKey(String key, Object? value) {
    if (value == null) return;
    Telemetry.setKey(key, value);
    if (kDebugMode) {
      AppConsole.key(key, value);
      return;
    }
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      if (value is String || value is num || value is bool) {
        crashlytics.setCustomKey(key, value);
      } else {
        crashlytics.setCustomKey(key, value.toString());
      }
    } catch (_) {}
  }

  /// Reports a caught exception with an explicit [fatal] flag.
  ///
  /// [e] hardcodes `fatal: false`, which is right for a handled error but wrong
  /// for one that leaves the feature unusable. Use this where the distinction
  /// matters; `fatal: true` marks the report as crash-equivalent and counts
  /// against the crash-free-users metric, so reserve it for genuinely
  /// unrecoverable states.
  ///
  /// [reason] follows the same PII rule as [trail].
  static void recordError(
    Object error,
    StackTrace? stackTrace, {
    required String reason,
    bool fatal = false,
  }) {
    unawaited(Telemetry.captureError(error, stackTrace, reason: reason));
    if (kDebugMode) {
      AppConsole.error(
        '${fatal ? 'FATAL' : 'NON-FATAL'}: $reason',
        cause: error,
        stackTrace: stackTrace,
        fatal: fatal,
      );
      return;
    }
    try {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {}
  }

  /// The console, breadcrumb and crash-report side of an `AppEvents` line.
  /// Only `AppEvents` calls this; feature code records events through it.
  ///
  /// [attributes] are the event's own, which `AppEvents` guarantees carry no
  /// personal data. They ride on the Sentry breadcrumb, so an error report
  /// shows each step's outcome and failure bucket, not just its name.
  static void event(
    String name, {
    required bool succeeded,
    Map<String, Object> attributes = const {},
  }) {
    unawaited(Telemetry.breadcrumb(name, category: 'event', data: attributes));
    if (kDebugMode) {
      AppConsole.event(name, attributes, succeeded: succeeded);
      return;
    }
    try {
      FirebaseCrashlytics.instance.log(name);
    } catch (_) {}
  }

  /// Ties later Crashlytics reports to [id], an opaque user code (never a
  /// name or email). Pass an empty string to clear it on logout.
  static void setUserIdentifier(String id) {
    if (kDebugMode) return;
    try {
      FirebaseCrashlytics.instance.setUserIdentifier(id);
    } catch (_) {}
  }
}
