import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_recipient.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/newsletter_media_image.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/newsletter_recipients_dialog.dart';

class NewsletterListItemModel {
  const NewsletterListItemModel({
    required this.title,
    required this.classroom,
    required this.sentDate,
    required this.createdBy,
    required this.recipientCount,
    this.newsletterCode = '',
    this.recipients = const <NewsletterRecipient>[],
    this.cachedNewsletter,
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
  final String newsletterCode;
  final List<NewsletterRecipient> recipients;
  final Newsletter? cachedNewsletter;
  final String? primaryAttachmentAssetCode;
  final String? primaryAttachmentDirectUrl;
  final String? primaryAttachmentMimeType;
  final int additionalAttachmentCount;

  bool get showClassroomRow => classroom.trim().isNotEmpty;
}

class NewsletterSentListCard extends StatelessWidget {
  const NewsletterSentListCard({
    super.key,
    required this.newsLetter,
    required this.onTap,
    this.showRecipientCount = true,
  });

  final NewsletterListItemModel newsLetter;
  final VoidCallback onTap;

  /// Whether to show the recipient-count badge. Hidden for the guardian/parent
  /// persona, who should not see how many recipients a newsletter was sent to.
  final bool showRecipientCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 84,
                  height: 56,
                  child: _CardThumbnail(
                    key: ValueKey<String>(
                      '${newsLetter.primaryAttachmentAssetCode ?? ''}|${newsLetter.primaryAttachmentDirectUrl ?? ''}',
                    ),
                    assetCode: newsLetter.primaryAttachmentAssetCode,
                    directUrl: newsLetter.primaryAttachmentDirectUrl,
                    additionalAttachmentCount:
                        newsLetter.additionalAttachmentCount,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Text(
                      newsLetter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(6),
                    child: _AlignedMetaRow(
                      label: 'Created by',
                      value: newsLetter.createdBy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(6),
                          child: _DateMetaRow(date: newsLetter.sentDate),
                        ),
                      ),
                      if (showRecipientCount)
                        _RecipientCountBadge(
                          count: newsLetter.recipientCount,
                          newsletterCode: newsLetter.newsletterCode,
                          recipients: newsLetter.recipients,
                          cachedNewsletter: newsLetter.cachedNewsletter,
                        ),
                    ],
                  ),
                  if (newsLetter.showClassroomRow) ...[
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(6),
                      child: _AlignedMetaRow(
                        label: 'Classroom',
                        value: newsLetter.classroom,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.only(left: 2, top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryColor.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateMetaRow extends StatelessWidget {
  const _DateMetaRow({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            'Date',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.58),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          date,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: AppColors.primaryColor.withValues(alpha: 0.82),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RecipientCountBadge extends StatelessWidget {
  const _RecipientCountBadge({
    required this.count,
    required this.newsletterCode,
    this.recipients = const <NewsletterRecipient>[],
    this.cachedNewsletter,
  });

  final int count;
  final String newsletterCode;
  final List<NewsletterRecipient> recipients;
  final Newsletter? cachedNewsletter;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showNewsletterRecipientsDialog(
            context: context,
            newsletterCode: newsletterCode,
            recipients: recipients,
            cachedNewsletter: cachedNewsletter,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 18,
                color: AppColors.primaryColor.withValues(alpha: 0.62),
              ),
              const SizedBox(width: 3),
              Text(
                '$count',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: AppColors.primaryColor.withValues(alpha: 0.78),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlignedMetaRow extends StatelessWidget {
  const _AlignedMetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.58),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardThumbnail extends StatelessWidget {
  const _CardThumbnail({
    super.key,
    this.assetCode,
    this.directUrl,
    this.additionalAttachmentCount = 0,
  });

  final String? assetCode;
  final String? directUrl;
  final int additionalAttachmentCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: NewsletterMediaImage(
            assetCode: assetCode,
            directUrl: directUrl,
            fillParent: true,
            borderRadius: 6,
          ),
        ),
        if (additionalAttachmentCount > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+$additionalAttachmentCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

