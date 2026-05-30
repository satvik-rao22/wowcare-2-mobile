import 'package:wowcare/data/features/newsletter/util/newsletter_image_url_resolver.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';
import 'package:wowcare/domain/features/newsletters/entities/newsletter_entity.dart';

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
  for (final attachment in entity.attachments) {
    final String code = _firstNonEmpty([
      attachment.code,
      entity.assetCode ?? '',
    ]);
    final String url = attachment.url.trim();
    if (code.isNotEmpty || url.isNotEmpty) {
      return NewsletterThumbnailInfo(
        assetCode: code,
        directUrl: url,
        mimeType: _resolveMimeType(
          mimeType: attachment.mimeType,
          url: url,
          fileName: attachment.name,
          assetCode: code,
        ),
      );
    }
  }

  final String entityAsset = (entity.assetCode ?? '').trim();
  if (entityAsset.isNotEmpty) {
    return NewsletterThumbnailInfo(
      assetCode: entityAsset,
      mimeType: 'image/*',
    );
  }

  for (final component in entity.components) {
    if (!_isImageComponent(component.type)) continue;
    final data = component.data;
    final String url = _firstNonEmpty([
      data['assetUrl'],
      data['deliveryUrl'],
      data['artifactUrl'],
      data['url'],
      data['imageUrl'],
      data['src'],
      data['downloadUrl'],
    ]);
    final String code = _firstNonEmpty([
      data['assetCode'],
      data['mediaCode'],
      data['code'],
    ]);
    if (url.isNotEmpty || code.isNotEmpty) {
      return NewsletterThumbnailInfo(
        assetCode: code,
        directUrl: url,
        mimeType: _resolveMimeType(
          mimeType: data['mimeType']?.toString() ?? data['contentType']?.toString(),
          url: url,
          fileName: data['fileName']?.toString() ?? data['name']?.toString(),
          assetCode: code,
        ),
      );
    }
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

/// Resolves list/preview thumbnail for the shared [Newsletter] model.
NewsletterThumbnailInfo resolveNewsletterListThumbnail(Newsletter newsletter) {
  for (final attachment in newsletter.attachments) {
    final String code = attachment.mediaCode.trim();
    final String url = attachment.resolvedUrl;
    if (code.isNotEmpty || url.isNotEmpty) {
      return NewsletterThumbnailInfo(
        assetCode: code,
        directUrl: url,
        mimeType: _resolveMimeType(
          mimeType: attachment.mimeType,
          url: url,
          fileName: attachment.fileName,
          assetCode: code,
        ),
      );
    }
  }

  for (final NewsletterComponent component in newsletter.components) {
    for (final part in component.parts) {
      if (part.type != NewsletterPartType.image || !part.hasImage) continue;
      final String deliveryUrl = part.resolvedImageUrl.isNotEmpty
          ? part.resolvedImageUrl
          : resolveNewsletterImageDeliveryUrl(
              part: part,
              attachments: newsletter.attachments,
            );
      final String assetCode = part.assetCode.trim().isNotEmpty
          ? part.assetCode.trim()
          : extractNewsletterAssetCode(part.imageUrl);
      return NewsletterThumbnailInfo(
        assetCode: assetCode,
        directUrl: deliveryUrl,
        mimeType: _resolveMimeType(
          mimeType: '',
          url: deliveryUrl,
          fileName: part.alt,
          assetCode: part.assetCode,
        ),
      );
    }
  }

  final RegExp codePattern = RegExp(r'AST_[A-Z0-9-]+', caseSensitive: false);
  final StringBuffer searchBuffer = StringBuffer()
    ..writeln(newsletter.subtitle)
    ..writeln(newsletter.bodyHtml);
  for (final component in newsletter.components) {
    for (final part in component.parts) {
      if (part.type == NewsletterPartType.text) {
        searchBuffer.writeln(part.text);
      } else {
        searchBuffer
          ..writeln(part.assetUrl)
          ..writeln(part.imageUrl)
          ..writeln(part.assetCode);
      }
    }
  }
  final RegExpMatch? match = codePattern.firstMatch(searchBuffer.toString());
  if (match != null) {
    final String code = (match.group(0) ?? '').trim();
    if (code.isNotEmpty) {
      return NewsletterThumbnailInfo(assetCode: code, mimeType: 'image/*');
    }
  }

  return const NewsletterThumbnailInfo();
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

String _resolveMimeType({
  String? mimeType,
  String? url,
  String? fileName,
  String? assetCode,
}) {
  final mime = (mimeType ?? '').trim().toLowerCase();
  if (mime.startsWith('image/')) return mime;
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
