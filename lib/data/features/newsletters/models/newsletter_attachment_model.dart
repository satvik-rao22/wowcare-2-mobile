import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/newsletters/entities/newsletter_attachment_entity.dart';

class NewsletterAttachmentModel extends Equatable {
  const NewsletterAttachmentModel({
    required this.id,
    required this.code,
    required this.name,
    required this.url,
    required this.mimeType,
    required this.sizeBytes,
  });

  final int? id;
  final String code;
  final String name;
  final String url;
  final String mimeType;
  final int? sizeBytes;

  factory NewsletterAttachmentModel.fromJson(Map<String, dynamic> json) {
    return NewsletterAttachmentModel(
      id: json['id'] as int?,
      code: (json['code'] ??
              json['mediaCode'] ??
              json['assetCode'] ??
              '')
          .toString()
          .trim(),
      name: (json['name'] ?? json['fileName'] ?? '').toString().trim(),
      url: (json['url'] ??
              json['assetUrl'] ??
              json['downloadUrl'] ??
              json['fileUrl'] ??
              json['publicUrl'] ??
              '')
          .toString()
          .trim(),
      mimeType: (json['mimeType'] ?? json['contentType'] ?? '').toString().trim(),
      sizeBytes: json['sizeBytes'] as int? ?? json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'url': url,
      'mimeType': mimeType,
      'sizeBytes': sizeBytes,
    };
  }

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

