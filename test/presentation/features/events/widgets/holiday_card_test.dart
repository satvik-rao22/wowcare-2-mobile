import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_card.dart';

Holiday _holiday({
  String name = 'Winter Break',
  String description = '',
  DateTime? start,
  DateTime? end,
  HolidayType type = HolidayType.school,
  HolidayStatus? status,
}) => Holiday(
  code: 'H1',
  name: name,
  description: description,
  startDate: start ?? DateTime(2026, 12, 20),
  endDate: end ?? start ?? DateTime(2026, 12, 20),
  type: type,
  status: status,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Widget _host(Widget child, {double width = 360}) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: width, child: child)),
  ),
);

void main() {
  testWidgets('renders name, single-day date and description', (tester) async {
    await tester.pumpWidget(
      _host(
        HolidayCard(
          holiday: _holiday(
            name: 'Diwali',
            description: 'Festival of lights',
            start: DateTime(2026, 11, 8),
          ),
        ),
      ),
    );

    expect(find.text('Diwali'), findsOneWidget);
    expect(find.text('Festival of lights'), findsOneWidget);
    // Single-day range shows just one formatted date (no "days" suffix).
    expect(find.textContaining('Nov 8, 2026'), findsOneWidget);
    expect(find.textContaining('days'), findsNothing);
  });

  testWidgets('multi-day range shows an inclusive day count', (tester) async {
    await tester.pumpWidget(
      _host(
        HolidayCard(
          holiday: _holiday(
            start: DateTime(2026, 12, 20),
            end: DateTime(2026, 12, 24),
          ),
        ),
      ),
    );
    // 20th → 24th inclusive = 5 days.
    expect(find.textContaining('5 days'), findsOneWidget);
  });

  testWidgets('an over-long name and description do not overflow', (tester) async {
    final longName = 'Really Long Holiday Name ' * 20; // ~500 chars
    final longDesc = 'Lorem ipsum dolor sit amet ' * 40; // ~1000 chars

    await tester.pumpWidget(
      _host(
        HolidayCard(holiday: _holiday(name: longName, description: longDesc)),
        width: 200, // deliberately cramped
      ),
    );

    // No RenderFlex/text overflow exception was thrown during layout.
    expect(tester.takeException(), isNull);
    expect(find.byType(HolidayCard), findsOneWidget);
  });

  group('federal observance actions', () {
    testWidgets('pending shows Approve and Reject', (tester) async {
      HolidayStatus? changed;
      await tester.pumpWidget(
        _host(
          HolidayCard(
            holiday: _holiday(
              type: HolidayType.federal,
              status: HolidayStatus.pending,
            ),
            onStatusChanged: (s) => changed = s,
          ),
        ),
      );

      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      await tester.tap(find.text('Approve'));
      expect(changed, HolidayStatus.considered);
    });

    testWidgets('considered shows only Reject', (tester) async {
      await tester.pumpWidget(
        _host(
          HolidayCard(
            holiday: _holiday(
              type: HolidayType.federal,
              status: HolidayStatus.considered,
            ),
            onStatusChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Approve'), findsNothing);
      // Status chip surfaces the human label.
      expect(find.text('Observed'), findsOneWidget);
    });

    testWidgets('rejected shows Re-Approve', (tester) async {
      HolidayStatus? changed;
      await tester.pumpWidget(
        _host(
          HolidayCard(
            holiday: _holiday(
              type: HolidayType.federal,
              status: HolidayStatus.rejected,
            ),
            onStatusChanged: (s) => changed = s,
          ),
        ),
      );
      expect(find.text('Re-Approve'), findsOneWidget);
      await tester.tap(find.text('Re-Approve'));
      expect(changed, HolidayStatus.considered);
    });
  });

  group('school holiday admin actions', () {
    testWidgets('Edit and Delete fire their callbacks', (tester) async {
      var edited = false;
      var deleted = false;
      await tester.pumpWidget(
        _host(
          HolidayCard(
            holiday: _holiday(),
            onEdit: () => edited = true,
            onDelete: () => deleted = true,
          ),
        ),
      );

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.tap(find.text('Delete'));
      expect(edited, isTrue);
      expect(deleted, isTrue);
    });

    testWidgets('no action row when callbacks are absent (read-only)', (
      tester,
    ) async {
      await tester.pumpWidget(_host(HolidayCard(holiday: _holiday())));
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });
  });
}
