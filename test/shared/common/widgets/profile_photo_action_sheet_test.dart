import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/shared/common/widgets/profile_photo_action_sheet.dart';

/// Pins the one rule the feature turns on: the delete row exists only when a
/// photo actually exists, and never fires without confirmation.
Future<void> _openSheet(
  WidgetTester tester, {
  required bool hasPhoto,
  required VoidCallback onChangePhoto,
  required Future<void> Function() onDelete,
  String subjectName = 'Jane Doe',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ProfilePhotoActionSheet.show(
              context,
              hasPhoto: hasPhoto,
              subjectName: subjectName,
              onChangePhoto: onChangePhoto,
              onDelete: onDelete,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('with no photo, only Change photo is offered', (tester) async {
    await _openSheet(
      tester,
      hasPhoto: false,
      onChangePhoto: () {},
      onDelete: () async {},
    );

    expect(find.text('Change photo'), findsOneWidget);
    expect(find.text('Delete photo'), findsNothing);
  });

  testWidgets('with a photo, Delete photo appears alongside it', (tester) async {
    await _openSheet(
      tester,
      hasPhoto: true,
      onChangePhoto: () {},
      onDelete: () async {},
    );

    expect(find.text('Change photo'), findsOneWidget);
    expect(find.text('Delete photo'), findsOneWidget);
  });

  testWidgets('Change photo runs the caller\'s picker, unchanged', (tester) async {
    var picked = 0;
    await _openSheet(
      tester,
      hasPhoto: true,
      onChangePhoto: () => picked++,
      onDelete: () async {},
    );

    await tester.tap(find.text('Change photo'));
    await tester.pumpAndSettle();

    expect(picked, 1);
    expect(find.text('Change photo'), findsNothing, reason: 'sheet should close');
  });

  testWidgets('Delete photo asks for confirmation before deleting anything', (
    tester,
  ) async {
    var deleted = 0;
    await _openSheet(
      tester,
      hasPhoto: true,
      onChangePhoto: () {},
      onDelete: () async => deleted++,
    );

    await tester.tap(find.text('Delete photo'));
    await tester.pumpAndSettle();

    // Confirmation is up, naming the subject — and nothing deleted yet.
    expect(find.textContaining('Jane Doe'), findsOneWidget);
    expect(find.textContaining('delete the profile photo'), findsOneWidget);
    expect(deleted, 0, reason: 'must not delete before the user confirms');
  });

  testWidgets('confirming runs the delete exactly once', (tester) async {
    var deleted = 0;
    await _openSheet(
      tester,
      hasPhoto: true,
      onChangePhoto: () {},
      onDelete: () async => deleted++,
    );

    await tester.tap(find.text('Delete photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleted, 1);
  });

  testWidgets('a failing delete still closes the sheet — no stuck spinner', (
    tester,
  ) async {
    // Error REPORTING is the caller's job by contract (all three screens catch
    // and snackbar), because DeleteConfirmationBottomSheet invokes onDelete
    // without awaiting it. What this sheet must guarantee is that a failure
    // cannot strand the user behind a loading confirm button — hence the
    // `finally` around the pop rather than a pop on the success path only.
    await _openSheet(
      tester,
      hasPhoto: true,
      onChangePhoto: () {},
      onDelete: () async => throw Exception('server said no'),
    );

    await tester.tap(find.text('Delete photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsNothing, reason: 'confirmation must close');
    expect(find.text('Delete photo'), findsNothing);
  });
}
