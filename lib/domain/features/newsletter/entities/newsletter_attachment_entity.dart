import 'package:equatable/equatable.dart';

class NewsletterAttachmentEntity extends Equatable {
  const NewsletterAttachmentEntity({
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

  @override
  List<Object?> get props => [id, code, name, url, mimeType, sizeBytes];
}
