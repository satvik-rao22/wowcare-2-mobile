import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_json.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment_entity.dart';

part 'newsletter_attachment_model.g.dart';

// ── Alias chains ────────────────────────────────────────────────────────────
// Each of these was an inline `json['a'] ?? json['b'] ?? …` in the
// hand-written factory. They are top-level functions because an annotation
// cannot reference a closure. Key order is the original order — it is a
// backend contract, not a preference.

Object? _readAttachmentCode(Map<dynamic, dynamic> json, String key) =>
    jsonFirstNonNull(json, const ['code', 'mediaCode', 'assetCode']);

Object? _readAttachmentName(Map<dynamic, dynamic> json, String key) =>
    jsonFirstNonNull(json, const ['name', 'fileName']);

Object? _readAttachmentUrl(Map<dynamic, dynamic> json, String key) =>
    jsonFirstNonNull(
      json,
      const ['url', 'assetUrl', 'downloadUrl', 'fileUrl', 'publicUrl'],
    );

Object? _readAttachmentMimeType(Map<dynamic, dynamic> json, String key) =>
    jsonFirstNonNull(json, const ['mimeType', 'contentType']);

Object? _readAttachmentSize(Map<dynamic, dynamic> json, String key) =>
    jsonFirstNonNull(json, const ['sizeBytes', 'size']);

/// One file attached to a student-scoped newsletter.
@JsonSerializable()
class NewsletterAttachmentModel extends Equatable {
  const NewsletterAttachmentModel({
    required this.id,
    required this.code,
    required this.name,
    required this.url,
    required this.mimeType,
    required this.sizeBytes,
  });

  factory NewsletterAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$NewsletterAttachmentModelFromJson(json);

  final int? id;

  @JsonKey(readValue: _readAttachmentCode, fromJson: jsonTrimmedString)
  final String code;

  @JsonKey(readValue: _readAttachmentName, fromJson: jsonTrimmedString)
  final String name;

  @JsonKey(readValue: _readAttachmentUrl, fromJson: jsonTrimmedString)
  final String url;

  @JsonKey(readValue: _readAttachmentMimeType, fromJson: jsonTrimmedString)
  final String mimeType;

  @JsonKey(readValue: _readAttachmentSize)
  final int? sizeBytes;

  Map<String, dynamic> toJson() => _$NewsletterAttachmentModelToJson(this);

  NewsletterAttachmentEntity toEntity() {
    return NewsletterAttachmentEntity(
      id: id,
      code: code,
      name: name,
      url: url,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );
  }

  @override
  List<Object?> get props => [id, code, name, url, mimeType, sizeBytes];
}
