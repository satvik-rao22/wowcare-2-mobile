// ignore_for_file: avoid_print
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:wowcare/core/observability/telemetry.dart';

/// A centralized, environment-aware logging utility.
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
  // ANSI Color codes for console output formatting
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _cyan = '\x1B[36m';

  /// Logs a debug message (Cyan). Debug builds only; no-op in release.
  static void d(Object? message) {
    if (kDebugMode) {
      print('$_cyan[DEBUG] $message$_reset');
    }
    // Release/profile: intentionally no-op — never forward raw debug content
    // (may contain API bodies / PII) to any sink.
  }

  /// Logs an info message (Green). Debug builds only; no-op in release.
  static void i(Object? message) {
    if (kDebugMode) {
      print('$_green[INFO] $message$_reset');
    }
    // Release/profile: intentionally no-op — see [d].
  }

  /// Logs a warning message (Yellow). Debug builds only; no-op in release.
  static void w(Object? message) {
    if (kDebugMode) {
      print('$_yellow[WARNING] $message$_reset');
    }
    // Release/profile: intentionally no-op — see [d].
  }

  /// Logs an error message (Red)
  static void e(Object? message, [Object? error, StackTrace? stackTrace]) {
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
      print('$_red[ERROR] $message$_reset');
      if (error != null) {
        print('$_red[Error Detail] $error$_reset');
      }
      if (stackTrace != null) {
        print('$_red[Stack Trace]\n$stackTrace$_reset');
      }
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
    if (kDebugMode) {
      print('$_red[ERROR] $message$_reset');
      if (error != null) {
        print('$_red[Error Detail] $error$_reset');
      }
      if (stackTrace != null) {
        print('$_red[Stack Trace]\n$stackTrace$_reset');
      }
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
      print('$_cyan[TRAIL] $message$_reset');
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
      print('$_cyan[KEY] $key=$value$_reset');
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
      print('$_red[${fatal ? 'FATAL' : 'NON-FATAL'}] $reason$_reset');
      print('$_red[Error Detail] $error$_reset');
      if (stackTrace != null) {
        print('$_red[Stack Trace]\n$stackTrace$_reset');
      }
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
}
