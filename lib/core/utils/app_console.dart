// ignore_for_file: avoid_print
import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// The debug console behind `AppLogger`: a colour and emoji per level, the
/// time with time since launch, and the calling `file:line` on every entry,
/// so a line in the debug console leads straight back to the code that wrote
/// it.
///
/// Debug builds only. Every caller checks [kDebugMode] before calling in, so
/// none of this runs, or survives tree shaking, in release or profile.
///
/// Three shapes:
/// - boxed entries for `d`/`i`/`w`/`e` with the two calling frames, or the
///   error's own stack trace,
/// - boxed network blocks without frames (the caller is always Dio),
/// - one-line entries for events, trails and keys, which are frequent and
///   short.
abstract final class AppConsole {
  AppConsole._();

  /// Frames from the logging layer itself, skipped so the first frame shown
  /// is the code that called it. `dart:async` frames are zone plumbing.
  static const List<String> _wrappers = [
    'package:wowcare/core/utils/logger_service.dart',
    'package:wowcare/core/utils/app_console.dart',
    'package:wowcare/core/network/api_logger.dart',
    'package:wowcare/core/observability/app_events.dart',
    'dart:async',
  ];

  // xterm-256 colours: readable on both light and dark consoles.
  static const AnsiColor _cyan = AnsiColor.fg(45);
  static const AnsiColor _green = AnsiColor.fg(78);
  static const AnsiColor _blue = AnsiColor.fg(39);
  static const AnsiColor _orange = AnsiColor.fg(214);
  static const AnsiColor _red = AnsiColor.fg(196);
  static const AnsiColor _magenta = AnsiColor.fg(199);
  static final AnsiColor _grey = AnsiColor.fg(AnsiColor.grey(0.55));

  static final Logger _boxed = Logger(
    filter: _AlwaysFilter(),
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 12,
      lineLength: 80,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      excludePaths: _wrappers,
      levelColors: {
        Level.debug: _cyan,
        Level.info: _green,
        Level.warning: _orange,
        Level.error: _red,
        Level.fatal: _magenta,
      },
      levelEmojis: const {
        Level.debug: '🐛',
        Level.info: '💡',
        Level.warning: '⚠️',
        Level.error: '⛔',
        Level.fatal: '💀',
      },
    ),
    output: _ChunkedConsoleOutput(),
  );

  static final Logger _network = Logger(
    filter: _AlwaysFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 0,
      lineLength: 80,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      levelColors: {
        Level.info: _blue,
        Level.warning: _orange,
        Level.error: _red,
      },
      levelEmojis: const {
        Level.info: '🌐',
        Level.warning: '🌐',
        Level.error: '🌐',
      },
    ),
    output: _ChunkedConsoleOutput(),
  );

  static void debug(Object? message) =>
      _guard(message, () => _boxed.d(message));

  static void info(Object? message) => _guard(message, () => _boxed.i(message));

  static void warning(Object? message) =>
      _guard(message, () => _boxed.w(message));

  /// [fatal] only changes the colour; nothing here reports anything.
  static void error(
    Object? message, {
    Object? cause,
    StackTrace? stackTrace,
    bool fatal = false,
  }) {
    // The package refuses a StackTrace as the error.
    if (cause is StackTrace) {
      stackTrace ??= cause;
      cause = null;
    }
    _guard(message, () {
      if (fatal) {
        _boxed.f(message, error: cause, stackTrace: stackTrace);
      } else {
        _boxed.e(message, error: cause, stackTrace: stackTrace);
      }
    });
  }

  /// Logging must never be why a feature fails: if the printer throws, the
  /// plain message is printed instead.
  static void _guard(Object? message, void Function() log) {
    try {
      log();
    } catch (error) {
      print('$message  (console logger failed: $error)');
    }
  }

  /// One request, response or failure. [status] picks the colour: blue for
  /// a request or a 2xx/3xx, orange for a 4xx, red for a 5xx or no response.
  static void http(String block, {int? status, bool failed = false}) {
    final level = switch (status) {
      null => failed ? Level.error : Level.info,
      >= 500 => Level.error,
      >= 400 => Level.warning,
      _ => Level.info,
    };
    _guard(block, () => _network.log(level, block));
  }

  /// An `AppEvents` line: green when it succeeded, orange otherwise, with its
  /// attributes and the code that recorded it.
  static void event(
    String name,
    Map<String, Object> attributes, {
    required bool succeeded,
  }) {
    final details = [
      for (final MapEntry(:key, :value) in attributes.entries)
        if (key != 'event' && key != 'outcome')
          key == 'duration_ms' ? '$value ms' : '$key=$value',
    ].join(' · ');
    _line(
      succeeded ? _green : _orange,
      '📊 EVENT',
      details.isEmpty ? name : '$name  $details',
    );
  }

  static void trail(String message) => _line(_grey, '🧭 TRAIL', message);

  static void key(String key, Object value) =>
      _line(_grey, '🔑 KEY', '$key = $value');

  static void _line(AnsiColor color, String label, String message) {
    _guard(message, () {
      final time = DateTimeFormat.onlyTime(DateTime.now());
      final caller = callerOf(StackTrace.current);
      final where = caller == null ? '' : '  ${_grey('($caller)')}';
      for (final line in chunk('${color('$time $label')} $message$where')) {
        print(line);
      }
    });
  }

  static final RegExp _frame = RegExp(r'^#\d+\s+.+ \((\S+)\)$');

  /// The location (`package:wowcare/...dart:line:col`) of the first app
  /// frame in [stackTrace] that is not the logging layer, or null.
  @visibleForTesting
  static String? callerOf(StackTrace stackTrace) {
    for (final line in stackTrace.toString().split('\n')) {
      final location = _frame.firstMatch(line.trim())?.group(1);
      if (location == null || !location.startsWith('package:wowcare/')) {
        continue;
      }
      if (_wrappers.any(location.startsWith)) continue;
      return location;
    }
    return null;
  }

  static final RegExp _leadingAnsi = RegExp('^(\x1B\\[[0-9;]*m)');

  /// The longest line printed in one go. Android's logcat cuts a line at
  /// about 4 KB, and long lines are hard to read anyway.
  @visibleForTesting
  static const int maxLineLength = 900;

  /// Splits [line] into [maxLineLength] pieces, carrying a leading ANSI
  /// colour (and a box edge) onto every piece so each prints in colour.
  @visibleForTesting
  static List<String> chunk(String line) {
    if (line.length <= maxLineLength) return [line];
    final color = _leadingAnsi.firstMatch(line)?.group(1) ?? '';
    var body = line.substring(color.length);
    const reset = AnsiColor.ansiDefault;
    if (color.isNotEmpty && body.endsWith(reset)) {
      body = body.substring(0, body.length - reset.length);
    }
    final edge = body.startsWith('${PrettyPrinter.verticalLine} ')
        ? '${PrettyPrinter.verticalLine} '
        : '';
    return [
      for (var start = 0; start < body.length; start += maxLineLength)
        [
          color,
          if (start > 0) edge,
          body.substring(start, min(start + maxLineLength, body.length)),
          if (color.isNotEmpty) reset,
        ].join(),
    ];
  }
}

/// Every caller already gates on [kDebugMode]; the package's default filter
/// would only repeat that check through asserts.
class _AlwaysFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _ChunkedConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      AppConsole.chunk(line).forEach(print);
    }
  }
}
