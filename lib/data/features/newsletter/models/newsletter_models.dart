import 'dart:convert';

import 'package:equatable/equatable.dart';

class NewsletterComponentModel extends Equatable {
  const NewsletterComponentModel({
    this.id = 0,
    this.componentType = '',
    this.sortOrder = 0,
    this.contentJson = '',
  });

  final int id;
  final String componentType;
  final int sortOrder;
  final String contentJson;

  factory NewsletterComponentModel.fromJson(Map<String, dynamic> json) {
    return NewsletterComponentModel(
      id: json['id'] as int? ?? 0,
      componentType: (json['componentType'] as String? ?? '').trim(),
      sortOrder: json['sortOrder'] as int? ?? 0,
      contentJson: (json['contentJson'] as String? ?? '').trim(),
    );
  }

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

class NewsletterAttachmentModel extends Equatable {
  const NewsletterAttachmentModel({
    this.id = 0,
    this.mediaCode = '',
    this.fileName = '',
    this.mimeType = '',
    this.fileSize = 0,
    this.sortOrder = 0,
  });

  final int id;
  final String mediaCode;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final int sortOrder;

  factory NewsletterAttachmentModel.fromJson(Map<String, dynamic> json) {
    return NewsletterAttachmentModel(
      id: json['id'] as int? ?? 0,
      mediaCode: (json['mediaCode'] as String? ?? '').trim(),
      fileName: (json['fileName'] as String? ?? '').trim(),
      mimeType: (json['mimeType'] as String? ?? '').trim(),
      fileSize: json['fileSize'] as int? ?? 0,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [id, mediaCode, fileName, mimeType, fileSize, sortOrder];
}

class NewsletterRecipientModel extends Equatable {
  const NewsletterRecipientModel({
    this.id = 0,
    this.classroomCode = '',
    this.studentCode = '',
  });

  final int id;
  final String classroomCode;
  final String studentCode;

  factory NewsletterRecipientModel.fromJson(Map<String, dynamic> json) {
    return NewsletterRecipientModel(
      id: json['id'] as int? ?? 0,
      classroomCode: (json['classroomCode'] as String? ?? '').trim(),
      studentCode: (json['studentCode'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'classroomCode': classroomCode,
        'studentCode': studentCode,
      };

  @override
  List<Object?> get props => [id, classroomCode, studentCode];
}

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
    required this.recipients,
    required this.components,
    required this.attachments,
    this.layoutJson = '',
  });

  final int id;
  final String code;
  final String organizationCode;
  final String schoolCode;
  final String title;
  final String subtitle;
  final String layoutJson;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime? createdAt;
  final int recipientCount;
  final List<NewsletterRecipientModel> recipients;
  final List<NewsletterComponentModel> components;
  final List<NewsletterAttachmentModel> attachments;

  factory NewsletterModel.fromJson(Map<String, dynamic> json) {
    final recipientsJson = json['recipients'] as List<dynamic>? ?? const [];
    final componentsJson = json['components'] as List<dynamic>? ?? const [];
    final attachmentsJson = json['attachments'] as List<dynamic>? ?? const [];

    final components = componentsJson
        .map(
          (dynamic e) => NewsletterComponentModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final subtitle = (json['subtitle'] as String? ?? '').trim();

    return NewsletterModel(
      id: json['id'] as int? ?? 0,
      code: (json['code'] as String? ?? '').trim(),
      organizationCode: (json['organizationCode'] as String? ?? '').trim(),
      schoolCode: (json['schoolCode'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      subtitle: subtitle.isNotEmpty ? subtitle : _summaryFromComponents(components),
      layoutJson: (json['layoutJson'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      scheduledAt: _parseDateTime(json['scheduledAt']),
      sentAt: _parseDateTime(json['sentAt']),
      createdAt: _parseDateTime(json['createdAt']),
      recipientCount: json['recipientCount'] as int? ?? 0,
      recipients: recipientsJson
          .map(
            (dynamic e) => NewsletterRecipientModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      components: components,
      attachments: attachmentsJson
          .map(
            (dynamic e) => NewsletterAttachmentModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'title': title,
        'subtitle': subtitle,
        'layoutJson': layoutJson,
        'status': status,
        'scheduledAt': scheduledAt?.toIso8601String(),
        'sentAt': sentAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        'recipientCount': recipientCount,
        'recipients': recipients.map((e) => e.toJson()).toList(),
        'components': components
            .map(
              (NewsletterComponentModel c) => {
                'id': c.id,
                'componentType': c.componentType,
                'sortOrder': c.sortOrder,
                'contentJson': c.contentJson,
              },
            )
            .toList(),
        'attachments': attachments
            .map(
              (NewsletterAttachmentModel a) => {
                'id': a.id,
                'mediaCode': a.mediaCode,
                'fileName': a.fileName,
                'mimeType': a.mimeType,
                'fileSize': a.fileSize,
                'sortOrder': a.sortOrder,
              },
            )
            .toList(),
      };

  List<String> get classroomCodes {
    return recipients
        .map((NewsletterRecipientModel r) => r.classroomCode)
        .where((String c) => c.isNotEmpty)
        .toSet()
        .toList();
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
        status,
        scheduledAt,
        sentAt,
        createdAt,
        recipientCount,
        recipients,
        components,
        attachments,
      ];
}

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

class NewsletterPageModel extends Equatable {
  const NewsletterPageModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<NewsletterModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  factory NewsletterPageModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final Map<String, dynamic> data = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : <String, dynamic>{};

    final content = data['content'] as List<dynamic>? ?? const [];
    final pageableRaw = data['pageable'];
    final pageable = pageableRaw is Map
        ? Map<String, dynamic>.from(pageableRaw)
        : null;
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

  Map<String, dynamic> toJson() => {
        'items': items.map((NewsletterModel e) => e.toJson()).toList(),
        'page': page,
        'size': size,
        'totalPages': totalPages,
        'totalElements': totalElements,
        'hasMore': hasMore,
      };

  factory NewsletterPageModel.fromCacheJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return NewsletterPageModel(
      items: itemsJson
          .map(
            (dynamic e) => NewsletterModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? itemsJson.length,
      totalPages: json['totalPages'] as int? ?? 1,
      totalElements: json['totalElements'] as int? ?? itemsJson.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [items, page, size, totalPages, totalElements, hasMore];
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
