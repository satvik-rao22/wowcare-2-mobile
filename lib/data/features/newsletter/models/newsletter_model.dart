import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_attachment_model.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_component_model.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_json.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_recipient_model.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_entity.dart';

part 'newsletter_model.g.dart';

// ── Nested lists ────────────────────────────────────────────────────────────
// The generator's default for `List<Model>` is
// `(v as List).map((e) => Model.fromJson(e as Map<String, dynamic>))`, which
// THROWS on a non-map element. The hand-written parser used `.whereType<Map>()`
// and SKIPPED such elements. That difference only shows up on malformed input,
// which is exactly where §8 says behaviour must not change — so each list gets
// an explicit `fromJson` that keeps the skip.

List<NewsletterComponentModel> _componentsFromJson(Object? value) => value
        is List
    ? value
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> e) =>
              NewsletterComponentModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList(growable: false)
    : const <NewsletterComponentModel>[];

List<NewsletterAttachmentModel> _attachmentsFromJson(Object? value) => value
        is List
    ? value
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> e) =>
              NewsletterAttachmentModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList(growable: false)
    : const <NewsletterAttachmentModel>[];

List<NewsletterRecipientModel> _recipientsFromJson(Object? value) => value
        is List
    ? value
        .whereType<Map>()
        .map(
          (Map<dynamic, dynamic> e) =>
              NewsletterRecipientModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList(growable: false)
    : const <NewsletterRecipientModel>[];

/// `recipientCount`, falling back to the length of the recipients array.
///
/// A `fromJson:` sees one key; this needs two, so it is a `readValue`.
Object? _readRecipientCount(Map<dynamic, dynamic> json, String key) {
  final Object? declared = json['recipientCount'];
  if (declared != null) return declared;
  final Object? recipients = json['recipients'];
  return recipients is List ? recipients.length : 0;
}

/// A student-scoped newsletter, as returned by
/// `GET /api/v1/newsletters/student/{studentCode}`.
@JsonSerializable(explicitToJson: true)
class NewsletterModel extends Equatable {
  const NewsletterModel({
    required this.id,
    required this.code,
    required this.organizationCode,
    required this.schoolCode,
    required this.title,
    required this.subtitle,
    required this.layoutJson,
    required this.backgroundPattern,
    required this.colorTheme,
    required this.assetCode,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    required this.components,
    required this.attachments,
    required this.recipients,
    required this.recipientCount,
  });

  factory NewsletterModel.fromJson(Map<String, dynamic> json) =>
      _$NewsletterModelFromJson(json);

  final int? id;

  @JsonKey(fromJson: jsonTrimmedString)
  final String code;

  @JsonKey(fromJson: jsonTrimmedString)
  final String organizationCode;

  @JsonKey(fromJson: jsonTrimmedString)
  final String schoolCode;

  @JsonKey(fromJson: jsonTrimmedString)
  final String title;

  @JsonKey(fromJson: jsonTrimmedString)
  final String subtitle;

  /// NOT trimmed — this is raw JSON or HTML handed to the content parser, and
  /// the hand-written factory deliberately did not trim it either.
  @JsonKey(fromJson: _layoutJsonFromJson)
  final String layoutJson;

  @JsonKey(fromJson: jsonTrimmedString)
  final String backgroundPattern;

  @JsonKey(fromJson: jsonTrimmedString)
  final String colorTheme;

  @JsonKey(fromJson: jsonTrimmedStringOrNull)
  final String? assetCode;

  @JsonKey(fromJson: jsonTrimmedString)
  final String status;

  @JsonKey(fromJson: jsonTrimmedString)
  final String createdBy;

  @JsonKey(fromJson: jsonTrimmedString)
  final String createdByName;

  @JsonKey(fromJson: jsonDateTimeNoTrim)
  final DateTime? createdAt;

  @JsonKey(fromJson: jsonDateTimeNoTrim)
  final DateTime? updatedAt;

  @JsonKey(fromJson: _componentsFromJson)
  final List<NewsletterComponentModel> components;

  @JsonKey(fromJson: _attachmentsFromJson)
  final List<NewsletterAttachmentModel> attachments;

  @JsonKey(fromJson: _recipientsFromJson)
  final List<NewsletterRecipientModel> recipients;

  @JsonKey(readValue: _readRecipientCount)
  final int recipientCount;

  Map<String, dynamic> toJson() => _$NewsletterModelToJson(this);

  NewsletterEntity toEntity() {
    return NewsletterEntity(
      id: id,
      code: code,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      title: title,
      subtitle: subtitle,
      layoutJson: layoutJson,
      backgroundPattern: backgroundPattern,
      colorTheme: colorTheme,
      assetCode: assetCode,
      status: status,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      components: components.map((e) => e.toEntity()).toList(growable: false),
      attachments: attachments.map((e) => e.toEntity()).toList(growable: false),
      recipients: recipients.map((e) => e.toEntity()).toList(growable: false),
      recipientCount: recipientCount,
    );
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
        backgroundPattern,
        colorTheme,
        assetCode,
        status,
        createdBy,
        createdByName,
        createdAt,
        updatedAt,
        components,
        attachments,
        recipients,
        recipientCount,
      ];
}

String _layoutJsonFromJson(Object? value) => (value ?? '').toString();
