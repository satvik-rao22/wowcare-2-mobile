import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/newsletters/entities/newsletter_entity.dart';

import 'newsletter_attachment_model.dart';
import 'newsletter_component_model.dart';
import 'newsletter_recipient_model.dart';

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
  final List<NewsletterComponentModel> components;
  final List<NewsletterAttachmentModel> attachments;
  final List<NewsletterRecipientModel> recipients;
  final int recipientCount;

  factory NewsletterModel.fromJson(Map<String, dynamic> json) {
    final componentsJson = json['components'];
    final attachmentsJson = json['attachments'];
    final recipientsJson = json['recipients'];

    return NewsletterModel(
      id: json['id'] as int?,
      code: (json['code'] ?? '').toString().trim(),
      organizationCode: (json['organizationCode'] ?? '').toString().trim(),
      schoolCode: (json['schoolCode'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString().trim(),
      subtitle: (json['subtitle'] ?? '').toString().trim(),
      layoutJson: (json['layoutJson'] ?? '').toString(),
      backgroundPattern: (json['backgroundPattern'] ?? '').toString().trim(),
      colorTheme: (json['colorTheme'] ?? '').toString().trim(),
      assetCode: (json['assetCode'] as String?)?.trim(),
      status: (json['status'] ?? '').toString().trim(),
      createdBy: (json['createdBy'] ?? '').toString().trim(),
      createdByName: (json['createdByName'] ?? '').toString().trim(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      components: componentsJson is List
          ? componentsJson
              .whereType<Map>()
              .map((e) => NewsletterComponentModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
          : const <NewsletterComponentModel>[],
      attachments: attachmentsJson is List
          ? attachmentsJson
              .whereType<Map>()
              .map((e) => NewsletterAttachmentModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
          : const <NewsletterAttachmentModel>[],
      recipients: recipientsJson is List
          ? recipientsJson
              .whereType<Map>()
              .map((e) => NewsletterRecipientModel.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
          : const <NewsletterRecipientModel>[],
      recipientCount: json['recipientCount'] as int? ??
          (json['recipients'] is List ? (json['recipients'] as List).length : 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
      'title': title,
      'subtitle': subtitle,
      'layoutJson': layoutJson,
      'backgroundPattern': backgroundPattern,
      'colorTheme': colorTheme,
      'assetCode': assetCode,
      'status': status,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'components': components.map((e) => e.toJson()).toList(growable: false),
      'attachments': attachments.map((e) => e.toJson()).toList(growable: false),
      'recipients': recipients.map((e) => e.toJson()).toList(growable: false),
      'recipientCount': recipientCount,
    };
  }

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

