import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_api_envelope.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_json.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';

part 'newsletter_models.g.dart';

/// Models for the STAFF/ADMIN sent-newsletter endpoints
/// (`GET /api/v1/newsletters/school/{schoolCode}` and
/// `GET /api/v1/newsletters/{code}`).
///
/// These class names are duplicated by the student-scoped stack in
/// `newsletter_model.dart` — see the migration report. The two are never
/// imported into the same library, and their payload shapes genuinely differ,
/// so they are converted separately rather than merged.

@JsonSerializable()
class NewsletterComponentModel extends Equatable {
  const NewsletterComponentModel({
    this.id = 0,
    this.componentType = '',
    this.sortOrder = 0,
    this.contentJson = '',
  });

  factory NewsletterComponentModel.fromJson(Map<String, dynamic> json) =>
      _$NewsletterComponentModelFromJson(json);

  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String componentType;

  @JsonKey(defaultValue: 0)
  final int sortOrder;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String contentJson;

  Map<String, dynamic> toJson() => _$NewsletterComponentModelToJson(this);

  String get plainText {
    final raw = contentJson.trim();
    if (raw.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        for (final key in ['text', 'content', 'body', 'value', 'html']) {
          final value = decoded[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString().trim();
          }
        }
      }
    } catch (_) {}
    return raw;
  }

  @override
  List<Object?> get props => [id, componentType, sortOrder, contentJson];
}

Object? _readSentAttachmentMediaCode(Map<dynamic, dynamic> json, String key) =>
    jsonFirstNonNull(json, const ['mediaCode', 'assetCode']);

Object? _readSentAttachmentAssetUrl(Map<dynamic, dynamic> json, String key) =>
    jsonFirstNonNull(
      json,
      const ['assetUrl', 'url', 'downloadUrl', 'fileUrl', 'publicUrl'],
    );

@JsonSerializable()
class NewsletterAttachmentModel extends Equatable {
  const NewsletterAttachmentModel({
    this.id = 0,
    this.mediaCode = '',
    this.fileName = '',
    this.mimeType = '',
    this.fileSize = 0,
    this.sortOrder = 0,
    this.assetUrl = '',
  });

  factory NewsletterAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$NewsletterAttachmentModelFromJson(json);

  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(readValue: _readSentAttachmentMediaCode, fromJson: jsonTrimmedString)
  final String mediaCode;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String fileName;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String mimeType;

  @JsonKey(defaultValue: 0)
  final int fileSize;

  @JsonKey(defaultValue: 0)
  final int sortOrder;

  @JsonKey(readValue: _readSentAttachmentAssetUrl, fromJson: jsonTrimmedString)
  final String assetUrl;

  Map<String, dynamic> toJson() => _$NewsletterAttachmentModelToJson(this);

  @override
  List<Object?> get props =>
      [id, mediaCode, fileName, mimeType, fileSize, sortOrder, assetUrl];
}

Object? _readRecipientStudentCode(Map<dynamic, dynamic> json, String key) =>
    jsonFirstNonNull(json, const ['studentCode', 'userCode']);

/// `userName`, falling through five aliases and finally to a name composed
/// from `firstName` + `lastName`.
///
/// The composed fallback is why this is a `readValue`: it needs two other keys
/// that are not fields on this model at all.
Object? _readRecipientUserName(Map<dynamic, dynamic> json, String key) {
  final Object? named = jsonFirstNonNull(
    json,
    const [
      'userName',
      'studentName',
      'recipientName',
      'guardianName',
      'name',
    ],
  );
  if (named != null) return named;

  final String firstName = (json['firstName'] ?? '').toString().trim();
  final String lastName = (json['lastName'] ?? '').toString().trim();
  return <String>[firstName, lastName]
      .where((String part) => part.isNotEmpty)
      .join(' ');
}

@JsonSerializable()
class NewsletterRecipientModel extends Equatable {
  const NewsletterRecipientModel({
    this.id = 0,
    this.classroomCode = '',
    this.studentCode = '',
    this.userName = '',
  });

  factory NewsletterRecipientModel.fromJson(Map<String, dynamic> json) =>
      _$NewsletterRecipientModelFromJson(json);

  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String classroomCode;

  @JsonKey(readValue: _readRecipientStudentCode, fromJson: jsonTrimmedString)
  final String studentCode;

  @JsonKey(readValue: _readRecipientUserName, fromJson: jsonTrimmedString)
  final String userName;

  Map<String, dynamic> toJson() => _$NewsletterRecipientModelToJson(this);

  @override
  List<Object?> get props => [id, classroomCode, studentCode, userName];
}

// ── Nested lists, sorted ────────────────────────────────────────────────────
// The generator maps a list element-by-element and cannot order the result.
// The sort was part of the hand-written parse, and the preview renders in this
// order, so it moves into the field's own `fromJson` rather than being lost.

List<NewsletterComponentModel> _sentComponentsFromJson(Object? value) {
  final List<dynamic> raw = value as List<dynamic>? ?? const [];
  return raw
      .map(
        (dynamic e) =>
            NewsletterComponentModel.fromJson(e as Map<String, dynamic>),
      )
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

List<NewsletterAttachmentModel> _sentAttachmentsFromJson(Object? value) {
  final List<dynamic> raw = value as List<dynamic>? ?? const [];
  return raw
      .map(
        (dynamic e) =>
            NewsletterAttachmentModel.fromJson(e as Map<String, dynamic>),
      )
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}

List<NewsletterRecipientModel> _sentRecipientsFromJson(Object? value) {
  final List<dynamic> raw = value as List<dynamic>? ?? const [];
  return raw
      .map(
        (dynamic e) =>
            NewsletterRecipientModel.fromJson(e as Map<String, dynamic>),
      )
      .toList();
}

@JsonSerializable(explicitToJson: true)
class NewsletterModel extends Equatable {
  const NewsletterModel({
    required this.id,
    required this.code,
    required this.organizationCode,
    required this.schoolCode,
    required this.title,
    required this.subtitle,
    required this.status,
    this.scheduledAt,
    this.sentAt,
    this.createdAt,
    required this.recipientCount,
    this.createdBy = '',
    this.createdByName = '',
    required this.recipients,
    required this.components,
    required this.attachments,
    this.layoutJson = '',
    this.colorTheme = '',
    this.backgroundPattern = 'plain',
  });

  /// The generated mapping, plus the ONE rule it cannot express.
  ///
  /// `subtitle` falls back to the first non-empty component text when the
  /// payload's own subtitle is blank — a value derived from ANOTHER field.
  /// `@JsonKey(fromJson:)` only ever sees one key's value, so the fallback is
  /// applied here, after the generator has built every field. Everything else
  /// on this class is annotation-driven.
  factory NewsletterModel.fromJson(Map<String, dynamic> json) {
    final NewsletterModel model = _$NewsletterModelFromJson(json);
    if (model.subtitle.isNotEmpty) return model;
    return model._withSubtitle(_summaryFromComponents(model.components));
  }

  @JsonKey(defaultValue: 0)
  final int id;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String code;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String organizationCode;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String schoolCode;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String title;

  /// Blank here means "derive it" — see [NewsletterModel.fromJson].
  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String subtitle;

  /// Trimmed on THIS endpoint, unlike the student one. Preserved as found.
  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String layoutJson;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String colorTheme;

  /// Defaults to `'plain'` BEFORE trimming, so a missing key and an explicit
  /// null both become `'plain'` — `@JsonKey(defaultValue:)` would apply after
  /// the converter, which is not the same thing.
  @JsonKey(fromJson: _backgroundPatternFromJson)
  final String backgroundPattern;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String status;

  @JsonKey(fromJson: jsonDateTime)
  final DateTime? scheduledAt;

  @JsonKey(fromJson: jsonDateTime)
  final DateTime? sentAt;

  @JsonKey(fromJson: jsonDateTime)
  final DateTime? createdAt;

  @JsonKey(defaultValue: 0)
  final int recipientCount;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String createdBy;

  @JsonKey(fromJson: jsonTrimmedStringStrict)
  final String createdByName;

  @JsonKey(fromJson: _sentRecipientsFromJson)
  final List<NewsletterRecipientModel> recipients;

  @JsonKey(fromJson: _sentComponentsFromJson)
  final List<NewsletterComponentModel> components;

  @JsonKey(fromJson: _sentAttachmentsFromJson)
  final List<NewsletterAttachmentModel> attachments;

  Map<String, dynamic> toJson() => _$NewsletterModelToJson(this);

  NewsletterModel _withSubtitle(String value) => NewsletterModel(
        id: id,
        code: code,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
        title: title,
        subtitle: value,
        status: status,
        scheduledAt: scheduledAt,
        sentAt: sentAt,
        createdAt: createdAt,
        recipientCount: recipientCount,
        createdBy: createdBy,
        createdByName: createdByName,
        recipients: recipients,
        components: components,
        attachments: attachments,
        layoutJson: layoutJson,
        colorTheme: colorTheme,
        backgroundPattern: backgroundPattern,
      );

  List<String> get classroomCodes {
    return recipients
        .map((NewsletterRecipientModel r) => r.classroomCode)
        .where((String c) => c.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> get recipientNames {
    return recipientSummaries
        .map((NewsletterRecipientSummary r) => r.displayName.trim())
        .where((String name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
  }

  List<NewsletterRecipientSummary> get recipientSummaries {
    final summaries = recipients
        .map((NewsletterRecipientModel r) {
          final name = r.userName.trim();
          final code = r.studentCode.trim();
          final displayName = name.isNotEmpty ? name : code;
          if (displayName.isEmpty) return null;
          return NewsletterRecipientSummary(
            displayName: displayName,
            userCode: code,
          );
        })
        .whereType<NewsletterRecipientSummary>()
        .toList()
      ..sort(
        (NewsletterRecipientSummary a, NewsletterRecipientSummary b) =>
            a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                ),
      );
    final seen = <String>{};
    return summaries.where((summary) {
      final key = summary.userCode.isNotEmpty
          ? summary.userCode
          : summary.displayName.toLowerCase();
      return seen.add(key);
    }).toList();
  }

  @override
  List<Object?> get props => [
        id,
        code,
        organizationCode,
        schoolCode,
        title,
        subtitle,
        layoutJson,
        colorTheme,
        backgroundPattern,
        status,
        scheduledAt,
        sentAt,
        createdAt,
        recipientCount,
        createdBy,
        createdByName,
        recipients,
        components,
        attachments,
      ];
}

String _backgroundPatternFromJson(Object? value) =>
    (value as String? ?? 'plain').trim();

String _summaryFromComponents(List<NewsletterComponentModel> components) {
  for (final component in components) {
    final text = component.plainText.trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

/// Builds HTML for preview from layout JSON, components, or subtitle.
String buildNewsletterBodyHtml({
  required String layoutJson,
  required String subtitle,
  required List<NewsletterComponentModel> components,
}) {
  final layout = layoutJson.trim();
  if (layout.isNotEmpty) {
    if (layout.startsWith('<')) return layout;
    try {
      final decoded = jsonDecode(layout);
      if (decoded is Map) {
        for (final key in ['html', 'body', 'content']) {
          final value = decoded[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString().trim();
          }
        }
      }
    } catch (_) {}
  }

  final htmlParts = <String>[];
  for (final component in components) {
    final text = component.plainText.trim();
    if (text.isEmpty) continue;
    if (text.startsWith('<')) {
      htmlParts.add(text);
    } else {
      htmlParts.add('<p>$text</p>');
    }
  }
  if (htmlParts.isNotEmpty) return htmlParts.join();

  final fallback = subtitle.trim();
  if (fallback.isEmpty) return '';
  if (fallback.startsWith('<')) return fallback;
  return '<p>$fallback</p>';
}

/// A page of sent newsletters.
///
/// **Asymmetric on purpose.** [toJson] and the generated [fromJson] describe
/// the FLAT shape this model is cached in. The API returns something else — an
/// envelope (`{success, message, data:{content, pageable, …}}`) whose
/// `hasMore` is not a field at all but a value computed from three others.
/// That is the one shape json_serializable cannot express, so it stays a
/// hand-written factory: [fromApiResponse].
@JsonSerializable(explicitToJson: true)
class NewsletterPageModel extends Equatable {
  const NewsletterPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  /// The cache shape — symmetric with [toJson]. Was `fromCacheJson`.
  factory NewsletterPageModel.fromJson(Map<String, dynamic> json) =>
      _$NewsletterPageModelFromJson(json);

  /// The API envelope. NOT generated: it unwraps `data`, falls back from
  /// `data.number`/`data.size` to `data.pageable.pageNumber`/`pageSize`, and
  /// derives `hasMore` from the page number, page size and totals.
  factory NewsletterPageModel.fromApiResponse(NewsletterApiEnvelope envelope) {
    final Map<String, dynamic> data = envelope.dataAsMap ?? <String, dynamic>{};

    final content = data['content'] as List<dynamic>? ?? const [];
    final pageableRaw = data['pageable'];
    final pageable =
        pageableRaw is Map ? Map<String, dynamic>.from(pageableRaw) : null;
    final pageNumber =
        data['number'] as int? ?? pageable?['pageNumber'] as int? ?? 0;
    final pageSize =
        data['size'] as int? ?? pageable?['pageSize'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .map((dynamic e) => NewsletterModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final hasMore = totalPages > 0
        ? (pageNumber + 1 < totalPages)
        : (totalElements > 0 &&
            pageSize > 0 &&
            (pageNumber + 1) * pageSize < totalElements);

    return NewsletterPageModel(
      items: items,
      page: pageNumber,
      size: pageSize,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  final List<NewsletterModel> items;

  @JsonKey(defaultValue: 0)
  final int page;

  @JsonKey(defaultValue: 0)
  final int size;

  @JsonKey(defaultValue: 1)
  final int totalPages;

  @JsonKey(defaultValue: 0)
  final int totalElements;

  @JsonKey(defaultValue: false)
  final bool hasMore;

  Map<String, dynamic> toJson() => _$NewsletterPageModelToJson(this);

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}
