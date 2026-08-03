import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_attachment_thumbnail.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// The service is only consulted for attachments that need a URL resolved by
/// asset code. Every case here supplies its own URL (or none at all), so nothing
/// reaches the network.
final _service = ImageUploadService(ApiClient(baseUrl: 'http://localhost'));

Future<void> _pump(WidgetTester tester, TaskAttachment attachment) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskAttachmentThumbnail(
            attachment: attachment,
            uploadService: _service,
            size: 44,
          ),
        ),
      ),
    );

CachedNetworkImage _imageWidget(WidgetTester tester) =>
    tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

void main() {
  // The regression this guards: an attachment known only by asset code has no
  // type, and its pre-signed delivery URL carries no file extension — so any
  // "only paint if it's an image" rule showed a spinner forever for exactly the
  // attachments that came from a task's `assetCodes`.
  group('an attachment of unknown type is painted, not skipped', () {
    testWidgets('paints the URL even though nothing says it is an image',
        (tester) async {
      const attachment = TaskAttachment(
        assetCode: 'AST_A',
        url: 'https://cdn.example.com/deliver/9f2a1b3c',
      );
      expect(attachment.hasKnownType, isFalse);

      await _pump(tester, attachment);

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(_imageWidget(tester).imageUrl,
          'https://cdn.example.com/deliver/9f2a1b3c');
    });

    testWidgets('does not spin forever when there is nothing to resolve',
        (tester) async {
      // No URL and no asset code: resolution can't even start, so this must
      // settle on the neutral placeholder instead of a permanent spinner.
      await _pump(tester, const TaskAttachment(assetCode: ''));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });
  });

  group('cache key — two tasks must never share a thumbnail', () {
    testWidgets('keys the disk cache by asset code, not by URL',
        (tester) async {
      // Delivery URLs are short-lived and change per resolution, so a URL-keyed
      // cache would both miss constantly and be the wrong identity for the file.
      await _pump(
        tester,
        const TaskAttachment(assetCode: 'AST_A', url: 'https://x.test/a?sig=1'),
      );
      expect(_imageWidget(tester).cacheKey, 'AST_A');
    });

    testWidgets('different assets get different keys', (tester) async {
      await _pump(
        tester,
        const TaskAttachment(assetCode: 'AST_A', url: 'https://x.test/same'),
      );
      final first = _imageWidget(tester).cacheKey;

      await _pump(
        tester,
        const TaskAttachment(assetCode: 'AST_B', url: 'https://x.test/same'),
      );
      final second = _imageWidget(tester).cacheKey;

      // Same URL, different assets — the keys must still differ, or one task's
      // thumbnail would be served for another's attachment.
      expect(first, 'AST_A');
      expect(second, 'AST_B');
      expect(first, isNot(second));
    });

    testWidgets('falls back to URL keying when there is no asset code',
        (tester) async {
      // A payload-supplied link with no asset behind it has no stable identity
      // to key on; null lets the package use the URL.
      await _pump(
        tester,
        const TaskAttachment(assetCode: '   ', url: 'https://x.test/a'),
      );
      expect(_imageWidget(tester).cacheKey, isNull);
    });

    testWidgets('recycling onto another attachment repaints the new asset',
        (tester) async {
      // A list reuses this element across cards. Without dropping the resolved
      // URL, the tile would keep showing the previous file's image.
      await _pump(
        tester,
        const TaskAttachment(assetCode: 'AST_A', url: 'https://x.test/a'),
      );
      expect(_imageWidget(tester).imageUrl, 'https://x.test/a');

      await _pump(
        tester,
        const TaskAttachment(assetCode: 'AST_B', url: 'https://x.test/b'),
      );
      expect(_imageWidget(tester).imageUrl, 'https://x.test/b');
      expect(_imageWidget(tester).cacheKey, 'AST_B');
    });
  });

  group('types the payload does describe', () {
    testWidgets('a known document never attempts an image load',
        (tester) async {
      await _pump(
        tester,
        const TaskAttachment(
          assetCode: 'AST_A',
          fileName: 'brief.pdf',
          contentType: 'application/pdf',
          url: 'https://x.test/brief.pdf',
        ),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('a declared image is painted', (tester) async {
      await _pump(
        tester,
        const TaskAttachment(
          assetCode: 'AST_A',
          mediaType: 'IMAGE',
          url: 'https://x.test/p.png',
        ),
      );
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('a video with a poster shows the frame under a play badge',
        (tester) async {
      await _pump(
        tester,
        const TaskAttachment(
          assetCode: 'AST_A',
          mediaType: 'VIDEO',
          thumbnailUrl: 'https://x.test/poster.jpg',
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(_imageWidget(tester).imageUrl, 'https://x.test/poster.jpg');
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    });

    testWidgets('a video with no poster shows the play glyph alone',
        (tester) async {
      await _pump(
        tester,
        const TaskAttachment(assetCode: 'AST_A', mediaType: 'VIDEO'),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    });

    testWidgets('an attachment still processing resolves nothing and rests',
        (tester) async {
      // Not showable yet: no URL would work, so it must not try to load and must
      // not sit on a spinner either — the row's subtitle says "processing…".
      // (`UPLOADED` is deliberately NOT this case; see isReady.)
      await _pump(
        tester,
        const TaskAttachment(assetCode: 'AST_A', status: 'PENDING'),
      );
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    });
  });
}
