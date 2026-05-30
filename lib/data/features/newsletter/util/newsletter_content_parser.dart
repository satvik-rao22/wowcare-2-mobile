import 'dart:convert';

import 'package:wowcare/data/features/newsletter/models/newsletter_models.dart';
import 'package:wowcare/data/features/newsletter/util/newsletter_image_url_resolver.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';

/// Builds ordered preview components from API `components` or `layoutJson`.
List<NewsletterComponent> parseNewsletterComponents({
  required List<NewsletterComponentModel> components,
  required String layoutJson,
}) {
  if (components.isNotEmpty) {
    final parsed = components
        .map(
          (NewsletterComponentModel model) => NewsletterComponent(
            id: model.id,
            componentType: model.componentType,
            sortOrder: model.sortOrder,
            parts: parseComponentParts(contentJson: model.contentJson),
          ),
        )
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return parsed;
  }

  return _parseComponentsFromLayoutJson(layoutJson);
}

/// Fills missing [NewsletterContentPart.assetUrl] on image parts using the
/// newsletter attachments list (same `assetUrl` field that powers the grid).
List<NewsletterComponent> enrichNewsletterComponentsWithAttachments({
  required List<NewsletterComponent> components,
  required List<NewsletterAttachment> attachments,
}) {
  if (components.isEmpty) return components;

  final Map<String, String> deliveryUrlByCode = <String, String>{};
  for (final NewsletterAttachment attachment in attachments) {
    final String code = attachment.mediaCode.trim();
    final String url = attachment.assetUrl.trim();
    if (code.isNotEmpty && url.isNotEmpty) {
      deliveryUrlByCode[code] = url;
    }
  }

  return components
      .map(
        (NewsletterComponent component) => NewsletterComponent(
          id: component.id,
          componentType: component.componentType,
          sortOrder: component.sortOrder,
          parts: component.parts
              .map(
                (NewsletterContentPart part) =>
                    _enrichImagePart(part, deliveryUrlByCode, attachments),
              )
              .toList(growable: false),
        ),
      )
      .toList(growable: false);
}

NewsletterContentPart _enrichImagePart(
  NewsletterContentPart part,
  Map<String, String> deliveryUrlByCode,
  List<NewsletterAttachment> attachments,
) {
  if (part.type != NewsletterPartType.image) return part;

  var normalized = normalizeNewsletterImagePart(
    part,
    attachments: attachments,
  );
  if (isNewsletterHttpUrl(normalized.assetUrl)) return normalized;

  final String code = normalized.assetCode.trim();
  if (code.isEmpty) return normalized;

  final String? fromMap = deliveryUrlByCode[code];
  if (fromMap == null || !isNewsletterHttpUrl(fromMap)) return normalized;

  return NewsletterContentPart.image(
    imageUrl: normalized.imageUrl,
    assetUrl: fromMap.trim(),
    alt: normalized.alt,
    assetCode: code,
  );
}

List<NewsletterComponent> _parseComponentsFromLayoutJson(String layoutJson) {
  final raw = layoutJson.trim();
  if (raw.isEmpty) return const <NewsletterComponent>[];

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <NewsletterComponent>[];

    final List<NewsletterComponent> items = <NewsletterComponent>[];
    for (int i = 0; i < decoded.length; i++) {
      final dynamic entry = decoded[i];
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final content = map['content'];
      final List<NewsletterContentPart> parts = content is Map
          ? parseComponentParts(data: Map<String, dynamic>.from(content))
          : const <NewsletterContentPart>[];

      items.add(
        NewsletterComponent(
          id: map['id'] is int ? map['id'] as int : i,
          componentType: (map['type'] ?? map['componentType'] ?? '').toString(),
          sortOrder: map['sortOrder'] as int? ?? i,
          parts: parts,
        ),
      );
    }
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  } catch (_) {
    return const <NewsletterComponent>[];
  }
}

List<NewsletterContentPart> parseComponentParts({
  String contentJson = '',
  Map<String, dynamic> data = const <String, dynamic>{},
}) {
  if (data.isNotEmpty) {
    if (data['parts'] is List) {
      return _parsePartsList(data['parts'] as List<dynamic>);
    }
    return _parseFlatContentMap(data);
  }

  final raw = contentJson.trim();
  if (raw.isEmpty) return const <NewsletterContentPart>[];

  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      if (map['parts'] is List) {
        return _parsePartsList(map['parts'] as List<dynamic>);
      }
      return _parseFlatContentMap(map);
    }
  } catch (_) {}

  return const <NewsletterContentPart>[];
}

List<NewsletterContentPart> _parseFlatContentMap(Map<String, dynamic> map) {
  final String type = (map['type'] ?? '').toString().trim().toUpperCase();
  if (type == 'TEXT' || type == 'TEXT_BLOCK') {
    final text = (map['text'] ?? map['html'] ?? map['content'] ?? '')
        .toString()
        .trim();
    if (text.isNotEmpty) {
      return <NewsletterContentPart>[NewsletterContentPart.text(text: text)];
    }
    return const <NewsletterContentPart>[];
  }

  if (type == 'IMAGE' || _mapHasImageFields(map)) {
    return <NewsletterContentPart>[_buildImagePart(map)];
  }

  return const <NewsletterContentPart>[];
}

bool _mapHasImageFields(Map<String, dynamic> map) {
  return _firstNonEmpty(<dynamic>[
        map['assetUrl'],
        map['deliveryUrl'],
        map['artifactUrl'],
        map['assetCode'],
        map['mediaCode'],
        map['imageUrl'],
        map['url'],
      ])
      .isNotEmpty;
}

List<NewsletterContentPart> _parsePartsList(List<dynamic> rawParts) {
  final List<NewsletterContentPart> parts = <NewsletterContentPart>[];
  for (final dynamic raw in rawParts) {
    if (raw is! Map) continue;
    final map = Map<String, dynamic>.from(raw);
    final type = (map['type'] ?? '').toString().trim().toUpperCase();
    if (type == 'TEXT') {
      final text = (map['text'] ?? map['html'] ?? map['content'] ?? '')
          .toString()
          .trim();
      if (text.isNotEmpty) {
        parts.add(NewsletterContentPart.text(text: text));
      }
      continue;
    }
    if (type == 'IMAGE') {
      parts.add(_buildImagePart(map));
    }
  }
  return parts;
}

NewsletterContentPart _buildImagePart(Map<String, dynamic> map) {
  final String assetUrl = _firstNonEmpty(<dynamic>[
    map['assetUrl'],
    map['deliveryUrl'],
    map['artifactUrl'],
    map['processedUrl'],
    map['thumbnailUrl'],
  ]);
  final String imageUrl = _firstNonEmpty(<dynamic>[
    map['imageUrl'],
    map['url'],
    map['src'],
    map['downloadUrl'],
    map['publicUrl'],
    map['fileUrl'],
  ]);
  final String explicitCode = _firstNonEmpty(<dynamic>[
    map['assetCode'],
    map['mediaCode'],
    map['code'],
  ]);
  final String resolvedCode = explicitCode.isNotEmpty
      ? explicitCode
      : extractNewsletterAssetCode(
          _firstNonEmpty(<dynamic>[assetUrl, imageUrl]),
        );
  final String resolvedDelivery = isNewsletterHttpUrl(assetUrl)
      ? assetUrl
      : (isNewsletterHttpUrl(imageUrl) ? imageUrl : '');
  final String alt = (map['alt'] ?? map['fileName'] ?? 'Newsletter image')
      .toString()
      .trim();

  return NewsletterContentPart.image(
    imageUrl: imageUrl,
    assetUrl: resolvedDelivery,
    alt: alt,
    assetCode: resolvedCode,
  );
}

String _firstNonEmpty(List<dynamic> values) {
  for (final dynamic value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}
