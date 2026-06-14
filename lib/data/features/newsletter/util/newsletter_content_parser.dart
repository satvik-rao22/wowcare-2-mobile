import 'dart:convert';

import 'package:wowcare/data/features/newsletter/models/newsletter_models.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';

final RegExp _assetCodePattern = RegExp(r'AST_[A-Z0-9-]+', caseSensitive: false);

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
  if (data['parts'] is List) {
    return _parsePartsList(data['parts'] as List<dynamic>);
  }

  final raw = contentJson.trim();
  if (raw.isEmpty) return const <NewsletterContentPart>[];

  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map && decoded['parts'] is List) {
      return _parsePartsList(decoded['parts'] as List<dynamic>);
    }
  } catch (_) {}

  return const <NewsletterContentPart>[];
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
      final imageUrl = _firstNonEmpty(<dynamic>[
        map['imageUrl'],
        map['url'],
        map['src'],
        map['downloadUrl'],
        map['publicUrl'],
      ]);
      final assetCode = _firstNonEmpty(<dynamic>[
        map['assetCode'],
        map['mediaCode'],
        map['code'],
      ]);
      final resolvedCode = assetCode.isNotEmpty
          ? assetCode
          : _extractAssetCode(imageUrl);
      final alt = (map['alt'] ?? map['fileName'] ?? 'Newsletter image')
          .toString()
          .trim();
      if (imageUrl.isNotEmpty || resolvedCode.isNotEmpty) {
        parts.add(
          NewsletterContentPart.image(
            imageUrl: imageUrl,
            alt: alt,
            assetCode: resolvedCode,
          ),
        );
      }
    }
  }
  return parts;
}

String _extractAssetCode(String value) {
  final match = _assetCodePattern.firstMatch(value.trim());
  return (match?.group(0) ?? '').trim();
}

String _firstNonEmpty(List<dynamic> values) {
  for (final dynamic value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}
