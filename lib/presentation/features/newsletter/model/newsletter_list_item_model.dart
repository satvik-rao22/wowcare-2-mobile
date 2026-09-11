import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';

/// UI configuration for [NewsletterSentListCard] — the shape a newsletter
/// list row is rendered from.
///
/// Lives in `model/` per §3's canonical layout ("screen params, UI config,
/// route arg classes"). It is deliberately NOT the [Newsletter] entity: the
/// two list screens build it from different sources (the staff list from
/// [Newsletter], the parent list from `NewsletterEntity`), and it carries
/// pre-formatted display values such as [sentDate] as a String.
class NewsletterListItemModel {
  const NewsletterListItemModel({
    required this.title,
    required this.classroom,
    required this.sentDate,
    required this.createdBy,
    required this.recipientCount,
    this.recipientNames = const <String>[],
    this.recipients = const <NewsletterRecipientSummary>[],
    this.primaryAttachmentAssetCode,
    this.primaryAttachmentDirectUrl,
    this.primaryAttachmentMimeType,
    this.additionalAttachmentCount = 0,
  });

  final String title;
  final String classroom;
  final String sentDate;
  final String createdBy;
  final int recipientCount;
  final List<String> recipientNames;
  final List<NewsletterRecipientSummary> recipients;
  final String? primaryAttachmentAssetCode;
  final String? primaryAttachmentDirectUrl;
  final String? primaryAttachmentMimeType;
  final int additionalAttachmentCount;
}
