import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/app_console.dart';

void main() {
  group('callerOf', () {
    test('skips the logging layer and returns the first app frame', () {
      final trace = StackTrace.fromString(
        '#0      AppConsole._line (package:wowcare/core/utils/app_console.dart:140:5)\n'
        '#1      AppLogger.event (package:wowcare/core/utils/logger_service.dart:220:7)\n'
        '#2      AppEvents.record (package:wowcare/core/observability/app_events.dart:240:5)\n'
        '<asynchronous suspension>\n'
        '#3      _rootRunUnary (dart:async/zone.dart:1538:47)\n'
        '#4      TasksCubit.createTask (package:wowcare/presentation/features/tasks/view_model/tasks_cubit.dart:88:9)\n'
        '#5      main (package:wowcare/main.dart:10:3)\n',
      );

      expect(
        AppConsole.callerOf(trace),
        'package:wowcare/presentation/features/tasks/view_model/tasks_cubit.dart:88:9',
      );
    });

    test('returns null when no app frame is outside the logging layer', () {
      final trace = StackTrace.fromString(
        '#0      AppConsole._line (package:wowcare/core/utils/app_console.dart:140:5)\n'
        '#1      Bloc.emit (package:bloc/src/bloc.dart:20:3)\n',
      );

      expect(AppConsole.callerOf(trace), isNull);
    });
  });

  group('chunk', () {
    const max = AppConsole.maxLineLength;

    test('leaves a short line alone', () {
      expect(AppConsole.chunk('hello'), ['hello']);
    });

    test('splits a long plain line without losing text', () {
      final line = 'a' * (max * 2 + 10);
      final pieces = AppConsole.chunk(line);

      expect(pieces, hasLength(3));
      expect(pieces.join(), line);
    });

    test('keeps the colour and the box edge on every piece', () {
      const color = '\x1B[38;5;39m';
      const reset = '\x1B[0m';
      final body = '│ ${'b' * (max + 5)}';
      final pieces = AppConsole.chunk('$color$body$reset');

      expect(pieces, hasLength(2));
      for (final piece in pieces) {
        expect(piece, startsWith(color));
        expect(piece, endsWith(reset));
      }
      expect(pieces.last, startsWith('$color│ '));
    });
  });
}
