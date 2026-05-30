import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';

/// Matches `AST_XXXX` in storage paths, e.g. `.../assets/AST_C31F3BB9-D/original/...`
final RegExp newsletterAssetCodeInPathPattern = RegExp(
  r'assets/(AST_[A-Z0-9-]+)',
  caseSensitive: false,
);

final RegExp newsletterAssetCodePattern = RegExp(
  r'AST_[A-Z0-9-]+',
  caseSensitive: false,
);

/// Extracts a media asset code from API paths, URLs, or HTML snippets.
String extractNewsletterAssetCode(String value) {
  final String text = value.trim();
  if (text.isEmpty) return '';

  final RegExpMatch? pathMatch =
      newsletterAssetCodeInPathPattern.firstMatch(text);
  if (pathMatch != null) {
    return (pathMatch.group(1) ?? '').trim();
  }

  final RegExpMatch? codeMatch = newsletterAssetCodePattern.firstMatch(text);
  return (codeMatch?.group(0) ?? '').trim();
}

bool isNewsletterHttpUrl(String value) {
  final lower = value.trim().toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}

/// Builds a processed CloudFront URL from a `raw/orgs/.../assets/AST_xxx/...` path.
String? processedUrlFromRawStoragePath(
  String storagePath, {
  String processedBaseUrl = '',
}) {
  final String path = storagePath.trim();
  if (!path.startsWith('raw/')) return null;

  final String code = extractNewsletterAssetCode(path);
  if (code.isEmpty) return null;

  final String marker = '/assets/$code/';
  final int markerIndex = path.indexOf(marker);
  if (markerIndex < 0) return null;

  final String orgPath = path.substring(4, markerIndex);
  final String base = processedBaseUrl.trim().isNotEmpty
      ? (processedBaseUrl.endsWith('/')
          ? processedBaseUrl
          : '$processedBaseUrl/')
      : 'https://d2874we3w8kvch.cloudfront.net/processed/';

  return '${base}$orgPath/assets/$code/image/primary.webp';
}

String? cloudFrontProcessedBaseFromAttachments(
  List<NewsletterAttachment> attachments,
) {
  for (final NewsletterAttachment attachment in attachments) {
    final String url = attachment.assetUrl.trim();
    final RegExpMatch? match = RegExp(
      r'^(https://[^/]+/processed/)',
      caseSensitive: false,
    ).firstMatch(url);
    if (match != null) {
      return match.group(1);
    }
  }
  return null;
}

/// Resolves the best delivery URL for a layout image part using API fields only.
///
/// Priority:
/// 1. [NewsletterContentPart.assetUrl]
/// 2. [NewsletterContentPart.imageUrl] when it is already an http(s) URL from contentJson
/// 3. Attachment with the same asset code (exact match only)
/// 4. Raw storage path → processed CloudFront URL
String resolveNewsletterImageDeliveryUrl({
  required NewsletterContentPart part,
  List<NewsletterAttachment> attachments = const <NewsletterAttachment>[],
}) {
  final String delivery = part.assetUrl.trim();
  if (isNewsletterHttpUrl(delivery)) return delivery;

  final String contentUrl = part.imageUrl.trim();
  if (isNewsletterHttpUrl(contentUrl)) return contentUrl;

  final String code = part.assetCode.trim().isNotEmpty
      ? part.assetCode.trim()
      : extractNewsletterAssetCode(contentUrl);

  if (code.isNotEmpty) {
    for (final NewsletterAttachment attachment in attachments) {
      if (attachment.mediaCode.trim() == code) {
        final String url = attachment.assetUrl.trim();
        if (isNewsletterHttpUrl(url)) return url;
      }
    }
  }

  if (contentUrl.startsWith('raw/')) {
    final String? fromRaw = processedUrlFromRawStoragePath(
      contentUrl,
      processedBaseUrl:
          cloudFrontProcessedBaseFromAttachments(attachments) ?? '',
    );
    if (fromRaw != null && isNewsletterHttpUrl(fromRaw)) return fromRaw;
  }

  return '';
}

/// Normalizes an image part so [assetUrl] and [assetCode] are populated for display.
NewsletterContentPart normalizeNewsletterImagePart(
  NewsletterContentPart part, {
  List<NewsletterAttachment> attachments = const <NewsletterAttachment>[],
}) {
  if (part.type != NewsletterPartType.image) return part;

  final String code = part.assetCode.trim().isNotEmpty
      ? part.assetCode.trim()
      : extractNewsletterAssetCode(
          _firstNonEmpty(<String>[part.assetUrl, part.imageUrl]),
        );

  final String delivery = resolveNewsletterImageDeliveryUrl(
    part: part,
    attachments: attachments,
  );

  return NewsletterContentPart.image(
    imageUrl: part.imageUrl,
    assetUrl: delivery,
    alt: part.alt,
    assetCode: code,
  );
}

String _firstNonEmpty(List<String> values) {
  for (final String value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}
