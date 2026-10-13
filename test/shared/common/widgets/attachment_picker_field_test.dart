import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:wowcare/shared/common/widgets/attachment_picker_field.dart';

void main() {
  const photo = PickedFile(
    path: '/tmp/site-visit.jpg',
    name: 'site-visit.jpg',
    sizeBytes: 80084,
    extension: 'jpg',
    mimeType: 'image/jpeg',
  );
  const consent = PickedFile(
    path: '/tmp/consent-form.pdf',
    name: 'consent-form.pdf',
    sizeBytes: 2 * 1024 * 1024,
    extension: 'pdf',
    mimeType: 'application/pdf',
  );

  /// Pumps the field at a phone width and returns the latest list handed to
  /// `onChanged`, so tests assert on what the parent form would actually store.
  Future<List<PickedFile>?> pump(
    WidgetTester tester, {
    required List<PickedFile> files,
    bool enabled = true,
    int maxFiles = FilePickerUtils.defaultMaxFiles,
  }) async {
    List<PickedFile>? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(14),
            child: AttachmentPickerField(
              files: files,
              maxFiles: maxFiles,
              enabled: enabled,
              onChanged: (next) => changed = next,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return changed;
  }

  testWidgets('empty state invites a pick and states the limits', (
    tester,
  ) async {
    await pump(tester, files: const []);

    expect(find.text('Add attachments'), findsOneWidget);
    // Type list and per-file cap are surfaced up front rather than discovered
    // by hitting a rejection.
    expect(find.textContaining('10 MB each'), findsOneWidget);
    expect(find.textContaining('of 5 attached'), findsNothing);
  });

  testWidgets('renders one card per file with name, size and count', (
    tester,
  ) async {
    await pump(tester, files: const [photo, consent]);

    expect(find.text('2 of 5 attached'), findsOneWidget);
    expect(find.text('site-visit.jpg'), findsOneWidget);
    expect(find.text('consent-form.pdf'), findsOneWidget);
    expect(find.text('78 KB'), findsOneWidget);
    expect(find.text('2.0 MB'), findsOneWidget);
    // Non-images fall back to a glyph plus an extension badge.
    expect(find.text('PDF'), findsOneWidget);
  });

  testWidgets('remove drops only the tapped file', (tester) async {
    List<PickedFile>? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachmentPickerField(
            files: const [photo, consent],
            onChanged: (next) => changed = next,
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Remove site-visit.jpg'));
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed, const [consent]);
  });

  testWidgets('clear all empties the list', (tester) async {
    List<PickedFile>? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachmentPickerField(
            files: const [photo, consent],
            onChanged: (next) => changed = next,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Clear all'));
    await tester.pump();

    expect(changed, isEmpty);
  });

  testWidgets('add tile reports the cap once full', (tester) async {
    await pump(tester, files: const [photo, consent], maxFiles: 2);

    expect(find.text('Max 2'), findsOneWidget);
    expect(find.text('Add'), findsNothing);
    expect(find.bySemanticsLabel('Attachment limit reached'), findsOneWidget);
  });

  testWidgets('read-only mode hides add and remove controls', (tester) async {
    await pump(tester, files: const [photo], enabled: false);

    expect(find.text('site-visit.jpg'), findsOneWidget);
    expect(find.text('Add'), findsNothing);
    expect(find.text('Clear all'), findsNothing);
    expect(find.bySemanticsLabel('Remove site-visit.jpg'), findsNothing);
  });

  testWidgets('read-only mode with no files says so', (tester) async {
    await pump(tester, files: const [], enabled: false);

    expect(find.text('No attachments'), findsOneWidget);
    expect(find.text('Add attachments'), findsNothing);
  });

  testWidgets('long file names do not overflow the card', (tester) async {
    // Overflow is reported as a test failure, so this guards the fixed-width
    // card against the long names real uploads carry.
    await pump(
      tester,
      files: const [
        PickedFile(
          path: '/tmp/long.pdf',
          name: 'tuv-rheinland-advanced-training-for-working-professionals.pdf',
          sizeBytes: 512 * 1024,
          extension: 'pdf',
          mimeType: 'application/pdf',
        ),
      ],
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a full strip scrolls instead of overflowing', (tester) async {
    final many = List.generate(
      5,
      (i) => PickedFile(
        path: '/tmp/photo-$i.jpg',
        name: 'photo-$i.jpg',
        sizeBytes: 1024 * 1024,
        extension: 'jpg',
        mimeType: 'image/jpeg',
      ),
    );
    await pump(tester, files: many);

    expect(find.text('5 of 5 attached'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Later cards are off-screen until scrolled — proof the strip scrolls
    // rather than squeezing five cards into the viewport.
    expect(find.text('photo-0.jpg'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(-300, 0));
    await tester.pump();
    expect(find.text('photo-4.jpg'), findsOneWidget);
  });
}
