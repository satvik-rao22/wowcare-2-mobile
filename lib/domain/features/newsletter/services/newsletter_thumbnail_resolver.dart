import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component_entity.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_entity.dart';

/// Thumbnail source for newsletter list cards.
class NewsletterThumbnailInfo {
  const NewsletterThumbnailInfo({
    this.assetCode = '',
    this.directUrl = '',
    this.mimeType = '',
  });

  final String assetCode;
  final String directUrl;
  final String mimeType;

  bool get hasSource => assetCode.trim().isNotEmpty || directUrl.trim().isNotEmpty;
}

NewsletterThumbnailInfo resolveNewsletterThumbnail(NewsletterEntity entity) {
  // Only ever use an *image* attachment as the thumbnail — a document
  // (PDF/Word/etc.) attachment must not block a real image, whether that
  // image lives elsewhere in the attachment list or in the body content.
  for (final attachment in entity.attachments) {
    final String code = _firstNonEmpty([
      attachment.code,
      entity.assetCode ?? '',
    ]);
    final String url = attachment.url.trim();
    if (code.isEmpty && url.isEmpty) continue;
    final String mimeType = resolveThumbnailMimeType(
      mimeType: attachment.mimeType,
      url: url,
      fileName: attachment.name,
      assetCode: code,
    );
    if (!mimeType.startsWith('image/')) continue;
    return NewsletterThumbnailInfo(
      assetCode: code,
      directUrl: url,
      mimeType: mimeType,
    );
  }

  final String entityAsset = (entity.assetCode ?? '').trim();
  if (entityAsset.isNotEmpty) {
    return NewsletterThumbnailInfo(
      assetCode: entityAsset,
      mimeType: 'image/*',
    );
  }

  for (final component in entity.components) {
    final NewsletterThumbnailInfo? fromComponent = _imageFromComponent(component);
    if (fromComponent != null) return fromComponent;
  }

  final RegExp codePattern = RegExp(r'AST_[A-Z0-9-]+', caseSensitive: false);
  final String text = '${entity.subtitle}\n${entity.layoutJson}';
  final RegExpMatch? match = codePattern.firstMatch(text);
  if (match != null) {
    final String code = (match.group(0) ?? '').trim();
    if (code.isNotEmpty) {
      return NewsletterThumbnailInfo(assetCode: code, mimeType: 'image/*');
    }
  }

  return const NewsletterThumbnailInfo();
}

/// Finds the first embedded image inside a newsletter body component.
///
/// Component content is stored as `{ "parts": [ {type: "IMAGE", ...}, ... ] }`
/// (see `parseComponentParts` in `newsletter_content_parser.dart`) rather than
/// as flat fields directly on the component, so `parts` must be inspected
/// first. A flat legacy shape is checked as a fallback for older payloads.
NewsletterThumbnailInfo? _imageFromComponent(
  NewsletterComponentEntity component,
) {
  for (final NewsletterComponentMedia part in component.body.parts) {
    if (!part.isImage) continue;
    if (!part.hasSource) continue;
    return _thumbnailFrom(part);
  }

  if (_isImageComponent(component.type)) {
    final NewsletterComponentMedia flat = component.body.flat;
    if (flat.hasSource) return _thumbnailFrom(flat);
  }

  return null;
}

NewsletterThumbnailInfo _thumbnailFrom(NewsletterComponentMedia media) {
  return NewsletterThumbnailInfo(
    assetCode: media.assetCode,
    directUrl: media.imageUrl,
    mimeType: resolveThumbnailMimeType(
      mimeType: media.mimeType,
      url: media.imageUrl,
      fileName: media.fileName,
      assetCode: media.assetCode,
    ),
  );
}

bool _isImageComponent(String type) {
  final normalized = type.trim().toLowerCase();
  return normalized.contains('image') || normalized == 'photo';
}

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

/// Best-effort mime-type detection shared by every newsletter thumbnail
/// resolver: trusts a known image/document mime type, otherwise sniffs the
/// URL/filename/assetCode extension, and finally assumes an image if only an
/// opaque assetCode is available (legacy asset-code-only payloads).
String resolveThumbnailMimeType({
  String? mimeType,
  String? url,
  String? fileName,
  String? assetCode,
}) {
  final mime = (mimeType ?? '').trim().toLowerCase();
  if (mime.startsWith('image/')) return mime;
  // A known non-image mime type (PDF/Word/etc.) is authoritative — never let
  // the extension/assetCode fallback below relabel a document as an image.
  if (mime.contains('pdf') ||
      mime.contains('word') ||
      mime.contains('document') ||
      mime.contains('sheet') ||
      mime.contains('excel') ||
      mime.contains('csv')) {
    return mime;
  }
  if (mime.isNotEmpty && !mime.startsWith('application/')) return mime;

  for (final source in <String>[url ?? '', fileName ?? '', assetCode ?? '']) {
    final lower = source.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.avif')) return 'image/avif';
  }

  if ((assetCode ?? '').trim().isNotEmpty) return 'image/*';
  return mime.isNotEmpty ? mime : 'image/*';
}

/// Resolves the thumbnail image for a sent-newsletter list card: an actual
/// image attachment, then an image embedded in the newsletter body, then a
/// legacy asset-code pattern in the text — never a non-image document, and
/// only empty (triggering the default thumbnail) when the newsletter truly
/// contains no image anywhere.
NewsletterThumbnailInfo resolveSentNewsletterThumbnail(Newsletter newsletter) {
  for (final attachment in newsletter.attachments) {
    final String code = attachment.mediaCode.trim();
    final String url = attachment.resolvedUrl;
    if (code.isEmpty && url.isEmpty) continue;
    final String mimeType = resolveThumbnailMimeType(
      mimeType: attachment.mimeType,
      url: url,
      fileName: attachment.fileName,
      assetCode: code,
    );
    if (!mimeType.startsWith('image/')) continue;
    return NewsletterThumbnailInfo(
      assetCode: code,
      directUrl: url,
      mimeType: mimeType,
    );
  }

  for (final component in newsletter.components) {
    for (final part in component.parts) {
      if (part.type != NewsletterPartType.image || !part.hasImage) continue;
      final String url = part.imageUrl.trim();
      final String code = part.assetCode.trim();
      return NewsletterThumbnailInfo(
        assetCode: code,
        directUrl: url,
        mimeType: resolveThumbnailMimeType(
          url: url,
          fileName: part.alt,
          assetCode: code,
        ),
      );
    }
  }

  final RegExp codePattern = RegExp(r'AST_[A-Z0-9-]+', caseSensitive: false);
  final String text = '${newsletter.subtitle}\n${newsletter.bodyHtml}';
  final RegExpMatch? match = codePattern.firstMatch(text);
  if (match != null) {
    final String code = (match.group(0) ?? '').trim();
    if (code.isNotEmpty) {
      return NewsletterThumbnailInfo(assetCode: code, mimeType: 'image/*');
    }
  }

  return const NewsletterThumbnailInfo();
}
