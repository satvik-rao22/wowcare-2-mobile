import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/shared/common/widgets/attachment_view/attachment_section.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';

/// `.resolved` takes assets the caller already has, so these tests need no
/// service and no DI — which is exactly how the event detail screen uses it.
AttachmentAsset _image(String code, {String name = 'photo.jpg'}) =>
    AttachmentAsset(
      assetCode: code,
      fileName: name,
      contentType: 'image/jpeg',
      mediaType: 'IMAGE',
      sizeBytes: 80084,
      status: 'READY',
      thumbnailUrl: 'https://cdn.test/$code/thumb_256.webp',
      deliveryUrl: 'https://cdn.test/$code/primary.webp',
    );

AttachmentAsset _pdf(String code) => AttachmentAsset(
      assetCode: code,
      fileName: 'consent.pdf',
      contentType: 'application/pdf',
      mediaType: 'DOCUMENT',
      sizeBytes: 2 * 1024 * 1024,
      status: 'READY',
      deliveryUrl: 'https://cdn.test/$code/consent.pdf',
    );

Future<void> pump(
  WidgetTester tester,
  List<AttachmentAsset> assets, {
  AttachmentLayout layout = AttachmentLayout.preview,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: AttachmentSection.resolved(
              attachments: assets,
              layout: layout,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('rebuilding with a new list does not throw', (tester) async {
    // Regression: `setState(() => _future = _resolve())` returned the Future from
    // the arrow closure, and Flutter asserts a setState callback must not. It
    // crashed the screen on any parent rebuild.
    await pump(tester, [_image('AST_1')]);
    expect(tester.takeException(), isNull);

    await pump(tester, [_image('AST_1'), _image('AST_2', name: 'second.jpg')]);

    expect(tester.takeException(), isNull);
    expect(find.text('second.jpg'), findsOneWidget);
  });

  testWidgets('an equal-but-new list is not treated as a change', (
    tester,
  ) async {
    await pump(tester, [_image('AST_1')]);
    // Same contents, different list instance — identity comparison would have
    // re-resolved on every frame.
    await pump(tester, [_image('AST_1')]);

    expect(tester.takeException(), isNull);
    expect(find.text('photo.jpg'), findsOneWidget);
  });

  testWidgets('images render as previews with name and size', (tester) async {
    await pump(tester, [_image('AST_1')]);

    expect(find.text('photo.jpg'), findsOneWidget);
    expect(find.text('JPG · 78 KB'), findsOneWidget);
    // The affordance that tells the user the preview opens a viewer.
    expect(find.text('View'), findsOneWidget);
  });

  testWidgets('documents render as rows, not previews', (tester) async {
    await pump(tester, [_pdf('AST_PDF')]);

    expect(find.text('consent.pdf'), findsOneWidget);
    expect(find.text('PDF · 2.0 MB'), findsOneWidget);
    // No preview chrome for something with nothing to preview.
    expect(find.text('View'), findsNothing);
  });

  testWidgets('a processing asset shows why, with a retry', (tester) async {
    await pump(tester, [
      const AttachmentAsset(
        assetCode: 'AST_WAIT',
        fileName: 'later.jpg',
        contentType: 'image/jpeg',
        mediaType: 'IMAGE',
        status: 'PROCESSING',
      ),
    ]);

    expect(find.text('Still processing — check back shortly'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping Retry does not throw', (tester) async {
    await pump(tester, [AttachmentAsset.missing('AST_GONE')]);
    expect(find.text('This file is no longer available'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    // Covers the second arrow-setState site.
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty list renders nothing', (tester) async {
    await pump(tester, const []);

    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact layout keeps images as rows', (tester) async {
    await pump(tester, [_image('AST_1')], layout: AttachmentLayout.compact);

    expect(find.text('photo.jpg'), findsOneWidget);
    expect(find.text('View'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('several attachments render in order without overflowing', (
    tester,
  ) async {
    await pump(tester, [
      _image('AST_1', name: 'first.jpg'),
      _pdf('AST_2'),
      _image('AST_3', name: 'third.jpg'),
    ]);

    expect(find.text('first.jpg'), findsOneWidget);
    expect(find.text('consent.pdf'), findsOneWidget);
    expect(find.text('third.jpg'), findsOneWidget);
    // Overflow is reported as a test failure, so this guards the layout.
    expect(tester.takeException(), isNull);
  });
}
