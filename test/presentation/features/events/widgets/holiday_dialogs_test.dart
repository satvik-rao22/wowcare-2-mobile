import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_dialogs.dart';

Holiday _holiday({String name = 'Spring Break'}) => Holiday(
  code: 'H1',
  name: name,
  startDate: DateTime(2026, 3, 16),
  endDate: DateTime(2026, 3, 20),
  type: HolidayType.school,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// Pumps a screen with a button that opens the confirmation dialog and
/// stores its result, then taps the button.
Future<bool?> Function() _openDialog(
  WidgetTester tester,
  Holiday holiday,
) {
  bool? result;
  return () async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDeleteHolidayConfirmation(context, holiday);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return result;
  };
}

void main() {
  testWidgets('shows the holiday name and confirm/cancel actions', (
    tester,
  ) async {
    await _openDialog(tester, _holiday(name: 'Spring Break'))();
    expect(find.text('Delete holiday?'), findsOneWidget);
    expect(find.textContaining('Spring Break'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('Delete returns true, Cancel returns false', (tester) async {
    // Delete → true
    bool? deleteResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                deleteResult = await showDeleteHolidayConfirmation(
                  context,
                  _holiday(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleteResult, isTrue);

    // Cancel → false
    bool? cancelResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                cancelResult = await showDeleteHolidayConfirmation(
                  context,
                  _holiday(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(cancelResult, isFalse);
  });

  testWidgets('an over-long holiday name does not overflow the dialog', (
    tester,
  ) async {
    final longName = 'Extremely Long Holiday Name ' * 30;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDeleteHolidayConfirmation(
                context,
                _holiday(name: longName),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Delete holiday?'), findsOneWidget);
  });
}
