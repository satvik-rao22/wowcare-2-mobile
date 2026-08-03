import 'dart:convert';

import 'package:wowcare/data/features/newsletter/models/newsletter_models.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';
import 'package:wowcare/domain/features/newsletters/entities/newsletter_entity.dart';
import 'package:wowcare/data/features/newsletter/util/newsletter_content_parser.dart';
import 'package:wowcare/presentation/features/newsletter/util/newsletter_thumbnail_resolver.dart';

/// Maps student-newsletter API entities to the shared preview/list [Newsletter] model.
Newsletter mapNewsletterEntityToNewsletter(NewsletterEntity entity) {
  final components = entity.components
      .map(
        (c) => NewsletterComponentModel(
          id: c.id ?? 0,
          componentType: c.type,
          sortOrder: c.order ?? 0,
          contentJson: c.data.isNotEmpty ? jsonEncode(c.data) : '',
        ),
      )
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  final parsedComponents = parseNewsletterComponents(
    components: components,
    layoutJson: entity.layoutJson,
  );

  final attachments = entity.attachments
      .map(
        (a) => NewsletterAttachment(
          id: a.id ?? 0,
          mediaCode: _attachmentMediaCode(a.code, entity.assetCode),
          fileName: a.name,
          mimeType: a.mimeType,
          assetUrl: a.url,
        ),
      )
      .where(
        (a) =>
            a.mediaCode.trim().isNotEmpty || a.assetUrl.trim().isNotEmpty,
      )
      .toList();

  final assetCode = (entity.assetCode ?? '').trim();
  if (assetCode.isNotEmpty &&
      !attachments.any((a) => a.mediaCode.trim() == assetCode)) {
    attachments.insert(
      0,
      NewsletterAttachment(
        id: 0,
        mediaCode: assetCode,
        fileName: '',
        mimeType: 'image/*',
      ),
    );
  }

  return Newsletter(
    id: entity.id ?? 0,
    code: entity.code,
    schoolCode: entity.schoolCode,
    title: entity.title,
    subtitle: entity.subtitle,
    status: entity.status,
    sentAt: entity.updatedAt ?? entity.createdAt,
    createdAt: entity.createdAt,
    recipientCount: entity.recipientCount,
    recipientNames: entity.recipients
        .map((recipient) {
          final name = recipient.userName.trim();
          if (name.isNotEmpty) return name;
          return recipient.userCode.trim();
        })
        .where((String name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort(
        (String a, String b) => a.toLowerCase().compareTo(b.toLowerCase()),
      ),
    recipients: entity.recipients
        .map((recipient) {
          final name = recipient.userName.trim();
          final code = recipient.userCode.trim();
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
      ),
    classroomCodes: const <String>[],
    createdByName: entity.createdByName,
    bodyHtml: buildNewsletterBodyHtml(
      layoutJson: entity.layoutJson,
      subtitle: entity.subtitle,
      components: components,
    ),
    colorTheme: entity.colorTheme,
    backgroundPattern: entity.backgroundPattern,
    components: parsedComponents,
    attachments: attachments,
  );
}

String _attachmentMediaCode(String attachmentCode, String? entityAssetCode) {
  final code = attachmentCode.trim();
  if (code.isNotEmpty) return code;
  return (entityAssetCode ?? '').trim();
}

/// Resolves the thumbnail image for a sent-newsletter list card: an actual
/// image attachment, then an image embedded in the newsletter body, then a
/// legacy asset-code pattern in the text — never a non-image document, and
/// only empty (triggering the default thumbnail) when the newsletter truly
/// contains no image anywhere.
NewsletterThumbnailInfo resolveSentNewsletterThumbnail(Newsletter newsletter) {
  for (final attachment in newsletter.attachments) {
    final String code = attachment.mediaCode.trim();
    final String url = attachment.resolvedUrl;
    if (code.isEmpty && url.isEmpty) continue;
    final String mimeType = resolveThumbnailMimeType(
      mimeType: attachment.mimeType,
      url: url,
      fileName: attachment.fileName,
      assetCode: code,
    );
    if (!mimeType.startsWith('image/')) continue;
    return NewsletterThumbnailInfo(
      assetCode: code,
      directUrl: url,
      mimeType: mimeType,
    );
  }

  for (final component in newsletter.components) {
    for (final part in component.parts) {
      if (part.type != NewsletterPartType.image || !part.hasImage) continue;
      final String url = part.imageUrl.trim();
      final String code = part.assetCode.trim();
      return NewsletterThumbnailInfo(
        assetCode: code,
        directUrl: url,
        mimeType: resolveThumbnailMimeType(
          url: url,
          fileName: part.alt,
          assetCode: code,
        ),
      );
    }
  }

  final RegExp codePattern = RegExp(r'AST_[A-Z0-9-]+', caseSensitive: false);
  final String text = '${newsletter.subtitle}\n${newsletter.bodyHtml}';
  final RegExpMatch? match = codePattern.firstMatch(text);
  if (match != null) {
    final String code = (match.group(0) ?? '').trim();
    if (code.isNotEmpty) {
      return NewsletterThumbnailInfo(assetCode: code, mimeType: 'image/*');
    }
  }

  return const NewsletterThumbnailInfo();
}

List<String> extractAssetCodesFromNewsletterEntity(NewsletterEntity entity) {
  final newsletter = mapNewsletterEntityToNewsletter(entity);
  final RegExp codePattern = RegExp(r'AST_[A-Z0-9-]+', caseSensitive: false);
  final String text = '${newsletter.subtitle}\n${newsletter.bodyHtml}';
  final Set<String> codes = <String>{};
  for (final RegExpMatch match in codePattern.allMatches(text)) {
    final String code = (match.group(0) ?? '').trim();
    if (code.isNotEmpty) codes.add(code);
  }
  for (final attachment in newsletter.attachments) {
    final mediaCode = attachment.mediaCode.trim();
    if (mediaCode.isNotEmpty) codes.add(mediaCode);
  }
  final assetCode = (entity.assetCode ?? '').trim();
  if (assetCode.isNotEmpty) codes.add(assetCode);
  return codes.toList();
}
