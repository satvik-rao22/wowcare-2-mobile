import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_card.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_highlight.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';

Holiday _holiday(String name) => Holiday(
  code: 'HOL_1',
  name: name,
  startDate: DateTime(2026, 12, 21),
  endDate: DateTime(2027, 1, 2),
  type: HolidayType.school,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: ListView(children: [SizedBox(width: 360, child: child)]),
  ),
);

/// [HolidayHighlight] is the notification deep-link target for holidays. The
/// payload carries no holiday code (see PUSH_CONTRACT_HOLIDAYS), so matching is
/// by NAME — these tests pin that behaviour, including the no-op default.
void main() {
  testWidgets('flashes the card whose holiday name matches', (tester) async {
    await tester.pumpWidget(
      _host(
        HolidayHighlight(
          holiday: _holiday('Winter Break'),
          highlightName: 'Winter Break',
          child: HolidayCard(holiday: _holiday('Winter Break')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final highlight = tester.widget<HighlightableCard>(
      find.byType(HighlightableCard),
    );
    expect(highlight.code, 'Winter Break');
    expect(highlight.highlightCode, 'Winter Break');
    // The card paints its own opaque background, so the flash must be drawn in
    // front of it to be visible at all.
    expect(highlight.foreground, isTrue);
    expect(highlight.scrollOnHighlight, isTrue);
  });

  testWidgets('matches case-insensitively and ignores surrounding space', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        HolidayHighlight(
          holiday: _holiday('Winter Break'),
          highlightName: '  winter break ',
          child: HolidayCard(holiday: _holiday('Winter Break')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // The flash renders a DecoratedBox wrapper around the child; a non-match
    // returns the child untouched (see HighlightableCard).
    expect(find.byType(HighlightableCard), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HighlightableCard),
        matching: find.byType(DecoratedBox),
      ),
      findsWidgets,
    );
  });

  testWidgets('renders the card unchanged when no holiday is targeted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        HolidayHighlight(
          holiday: _holiday('Winter Break'),
          highlightName: null,
          child: HolidayCard(holiday: _holiday('Winter Break')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Winter Break'), findsOneWidget);
    final highlight = tester.widget<HighlightableCard>(
      find.byType(HighlightableCard),
    );
    expect(highlight.highlightCode, isNull);
  });

  testWidgets('a different holiday is not flashed', (tester) async {
    await tester.pumpWidget(
      _host(
        HolidayHighlight(
          holiday: _holiday('Founders Day'),
          highlightName: 'Winter Break',
          child: HolidayCard(holiday: _holiday('Founders Day')),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Founders Day'), findsOneWidget);
    final highlight = tester.widget<HighlightableCard>(
      find.byType(HighlightableCard),
    );
    expect(highlight.code, 'Founders Day');
    expect(highlight.highlightCode, 'Winter Break');
  });
}
