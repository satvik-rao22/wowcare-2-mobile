// ignore_for_file: avoid_print
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// A centralized logging utility to manage console output.
/// Suppression is handled automatically via [kDebugMode].
class AppLogger {
  // ANSI Color codes for console output formatting
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _cyan = '\x1B[36m';

  /// Logs a debug message (Cyan)
  static void d(Object? message) {
    if (kDebugMode) {
      print('$_cyan[DEBUG] $message$_reset');
    } else {
      try {
        FirebaseCrashlytics.instance.log('[DEBUG] $message');
      } catch (_) {}
    }
  }

  /// Logs an info message (Green)
  static void i(Object? message) {
    if (kDebugMode) {
      print('$_green[INFO] $message$_reset');
    } else {
      try {
        FirebaseCrashlytics.instance.log('[INFO] $message');
      } catch (_) {}
    }
  }

  /// Logs a warning message (Yellow)
  static void w(Object? message) {
    if (kDebugMode) {
      print('$_yellow[WARNING] $message$_reset');
    } else {
      try {
        FirebaseCrashlytics.instance.log('[WARNING] $message');
      } catch (_) {}
    }
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
