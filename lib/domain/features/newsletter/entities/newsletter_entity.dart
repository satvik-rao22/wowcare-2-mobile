import 'package:equatable/equatable.dart';

import 'newsletter_attachment_entity.dart';
import 'newsletter_component_entity.dart';
import 'newsletter_recipient_entity.dart';

class NewsletterEntity extends Equatable {
  const NewsletterEntity({
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

  final int? id;
  final String code;
  final String organizationCode;
  final String schoolCode;
  final String title;
  final String subtitle;
  final String layoutJson;
  final String backgroundPattern;
  final String colorTheme;
  final String? assetCode;
  final String status;
  final String createdBy;
  final String createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<NewsletterComponentEntity> components;
  final List<NewsletterAttachmentEntity> attachments;
  final List<NewsletterRecipientEntity> recipients;
  final int recipientCount;

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
