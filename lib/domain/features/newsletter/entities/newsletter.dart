import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_recipient.dart';

class Newsletter {
  const Newsletter({
    required this.id,
    required this.code,
    required this.schoolCode,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.sentAt,
    required this.createdAt,
    required this.recipientCount,
    required this.classroomCodes,
    this.createdByName = '',
    this.bodyHtml = '',
    this.colorTheme = '',
    this.backgroundPattern = 'plain',
    this.components = const <NewsletterComponent>[],
    this.attachments = const <NewsletterAttachment>[],
    this.recipients = const <NewsletterRecipient>[],
  });

  final int id;
  final String code;
  final String schoolCode;
  final String title;
  final String subtitle;
  final String status;
  final DateTime? sentAt;
  final DateTime? createdAt;
  final int recipientCount;
  final List<String> classroomCodes;
  final String createdByName;
  final String bodyHtml;
  final String colorTheme;
  final String backgroundPattern;
  final List<NewsletterComponent> components;
  final List<NewsletterAttachment> attachments;
  final List<NewsletterRecipient> recipients;
}

class NewsletterPage {
  const NewsletterPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<Newsletter> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;
}
