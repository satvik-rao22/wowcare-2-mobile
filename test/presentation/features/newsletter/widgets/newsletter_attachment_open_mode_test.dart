import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_attachment_open_mode.dart';

const String _xlsxMime =
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

NewsletterAttachment _attachment({required String mimeType}) =>
    NewsletterAttachment(
      id: 1,
      mediaCode: 'AST_1',
      fileName: 'term-report.xlsx',
      mimeType: mimeType,
      assetUrl: 'https://cdn.example.com/term-report.xlsx',
    );

void main() {
  group('resolveNewsletterAttachmentOpenMode: documents', () {
    test('an .xlsx goes to an external app — NOT an in-app WebView, which is '
        'what painted the blank screen', () {
      final attachment = _attachment(mimeType: _xlsxMime);
      expect(attachment.isImage, isFalse);

      expect(
        resolveNewsletterAttachmentOpenMode(
          isImage: attachment.isImage,
          url: attachment.resolvedUrl,
        ),
        NewsletterAttachmentOpenMode.externalApp,
      );
    });

    test('the other formats a WebView cannot render go external too', () {
      const mimeTypes = <String>[
        _xlsxMime,
        'application/vnd.ms-excel',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'application/pdf',
        'application/zip',
        'text/csv',
        '',
      ];

      for (final mime in mimeTypes) {
        expect(
          resolveNewsletterAttachmentOpenMode(
            isImage: _attachment(mimeType: mime).isImage,
            url: 'https://cdn.example.com/file',
          ),
          NewsletterAttachmentOpenMode.externalApp,
          reason: 'mimeType "$mime" must not open in an in-app WebView',
        );
      }
    });

    test('http is accepted as well as https', () {
      expect(
        resolveNewsletterAttachmentOpenMode(
          isImage: false,
          url: 'http://cdn.example.com/a.xlsx',
        ),
        NewsletterAttachmentOpenMode.externalApp,
      );
    });
  });

  group('resolveNewsletterAttachmentOpenMode: images keep the overlay', () {
    test('an image opens the in-app preview, unchanged', () {
      final attachment = _attachment(mimeType: 'image/png');
      expect(attachment.isImage, isTrue);

      expect(
        resolveNewsletterAttachmentOpenMode(
          isImage: attachment.isImage,
          url: attachment.resolvedUrl,
        ),
        NewsletterAttachmentOpenMode.imagePreview,
      );
    });

    test('images are not subject to the scheme allowlist, exactly as before — '
        'the overlay fails safely on its own', () {
      expect(
        resolveNewsletterAttachmentOpenMode(isImage: true, url: 'nonsense'),
        NewsletterAttachmentOpenMode.imagePreview,
      );
    });
  });

  group('resolveNewsletterAttachmentOpenMode: refusals', () {
    test('a non-http(s) scheme is refused, never launched', () {
      const urls = <String>[
        'file:///etc/passwd',
        'javascript:alert(1)',
        'mailto:someone@example.com',
        'tel:+15551234',
        'wowcare://open',
      ];

      for (final url in urls) {
        expect(
          resolveNewsletterAttachmentOpenMode(isImage: false, url: url),
          NewsletterAttachmentOpenMode.refused,
          reason: '"$url" must not be launched from an attachment tile',
        );
      }
    });

    test('a schemeless or empty URL is refused', () {
      for (final url in <String>['', '   ', 'cdn.example.com/a.xlsx']) {
        expect(
          resolveNewsletterAttachmentOpenMode(isImage: false, url: url),
          NewsletterAttachmentOpenMode.refused,
        );
      }
    });

    test('surrounding whitespace does not defeat the allowlist', () {
      expect(
        resolveNewsletterAttachmentOpenMode(
          isImage: false,
          url: '  https://cdn.example.com/a.xlsx  ',
        ),
        NewsletterAttachmentOpenMode.externalApp,
      );
    });
  });
}
