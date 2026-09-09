// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// A centralized, environment-aware logging utility.
///
/// Debug/info/warning messages print to the console in debug builds only and
/// are **NOT** emitted in release/profile builds. This is deliberate: callers
/// routinely pass unsanitized content (full API request/response bodies,
/// tokens, PINs, student/staff identifiers) to these methods, so forwarding
/// them anywhere in production would exfiltrate sensitive/PII data. Genuine
/// error reporting still reaches Crashlytics via [e]/[c] (which take an
/// explicit error object), keeping crash observability intact.
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
}
