import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_json.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component_entity.dart';

part 'newsletter_component_model.g.dart';

Object? _readComponentType(Map<dynamic, dynamic> json, String key) =>
    jsonFirstNonNull(json, const ['type', 'componentType']);

Object? _readComponentOrder(Map<dynamic, dynamic> json, String key) =>
    jsonFirstNonNull(json, const ['order', 'sortOrder']);

/// The component body, from `data` or — when that is absent or empty — decoded
/// out of the `contentJson` STRING the backend sometimes sends instead.
///
/// This needs two different keys and a `jsonDecode` that must not throw, so it
/// is a `readValue` (which receives the whole map) rather than a `fromJson`
/// (which would only see one key). The `catch (_)` is the pre-existing
/// behaviour: an unparseable `contentJson` yields an empty body, never an
/// error.
Object? _readComponentData(Map<dynamic, dynamic> json, String key) {
  final Object? rawData = json['data'];
  Map<String, dynamic> data = rawData is Map<String, dynamic>
      ? rawData
      : rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

  if (data.isEmpty) {
    final Object? contentJson = json['contentJson'];
    if (contentJson is String && contentJson.trim().isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(contentJson);
        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
  }
  return data;
}

/// One layout component of a student-scoped newsletter.
@JsonSerializable()
class NewsletterComponentModel extends Equatable {
  const NewsletterComponentModel({
    required this.id,
    required this.type,
    required this.data,
    required this.order,
  });

  factory NewsletterComponentModel.fromJson(Map<String, dynamic> json) =>
      _$NewsletterComponentModelFromJson(json);

  final int? id;

  @JsonKey(readValue: _readComponentType, fromJson: jsonTrimmedString)
  final String type;

  @JsonKey(readValue: _readComponentData)
  final Map<String, dynamic> data;

  @JsonKey(readValue: _readComponentOrder)
  final int? order;

  Map<String, dynamic> toJson() => _$NewsletterComponentModelToJson(this);

  NewsletterComponentEntity toEntity() {
    return NewsletterComponentEntity(
      id: id,
      type: type,
      body: _bodyFromData(data),
      order: order,
      // Exactly what the mapper used to compute itself from `entity.data`.
      contentJson: data.isNotEmpty ? jsonEncode(data) : '',
    );
  }

  @override
  List<Object?> get props => [id, type, data, order];
}

// ── Raw body map -> typed domain body ──────────────────────────────────────
// The wire shape stays a map inside the data layer (§8: "maps stop at the
// datasource"). The alias digging that `newsletter_thumbnail_resolver` used to
// do at READ time, against an untyped entity field, happens here once instead.
// Key orders and the `??` / first-non-empty distinction are unchanged.

NewsletterComponentBody _bodyFromData(Map<String, dynamic> data) {
  final Object? rawParts = data['parts'];
  final List<NewsletterComponentMedia> parts = <NewsletterComponentMedia>[];
  if (rawParts is List) {
    for (final Object? rawPart in rawParts) {
      if (rawPart is! Map) continue;
      parts.add(
        _mediaFrom(
          Map<String, dynamic>.from(rawPart),
          type: (rawPart['type'] ?? '').toString().trim().toUpperCase(),
          urlKeys: const ['imageUrl', 'url', 'src', 'downloadUrl', 'publicUrl'],
        ),
      );
    }
  }

  return NewsletterComponentBody(
    parts: parts,
    flat: _mediaFrom(
      data,
      type: '',
      urlKeys: const ['url', 'imageUrl', 'src', 'downloadUrl'],
    ),
  );
}

NewsletterComponentMedia _mediaFrom(
  Map<String, dynamic> map, {
  required String type,
  required List<String> urlKeys,
}) {
  return NewsletterComponentMedia(
    type: type,
    imageUrl: _firstNonEmpty(map, urlKeys),
    assetCode: _firstNonEmpty(map, const ['assetCode', 'mediaCode', 'code']),
    // `?.toString() ?? …` skipped only NULLS, so a present-but-empty
    // `mimeType` beats a populated `contentType`. Not the same as
    // _firstNonEmpty, and preserved as such.
    mimeType: (jsonFirstNonNull(map, const ['mimeType', 'contentType']) ?? '')
        .toString(),
    fileName:
        (jsonFirstNonNull(map, const ['fileName', 'name']) ?? '').toString(),
  );
}

String _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
  for (final String key in keys) {
    final String text = (map[key] ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}
