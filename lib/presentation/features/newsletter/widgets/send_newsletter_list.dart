import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/presentation/features/newsletter/model/newsletter_list_item_model.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_card_thumbnail.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_recipient_badge.dart';

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
      color: AppColors.whiteColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xsPlus, vertical: AppSizes.xsPlus),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 84,
                  height: 56,
                  child: NewsletterCardThumbnail(
                    key: ValueKey<String>(
                      '${newsLetter.primaryAttachmentAssetCode ?? ''}|${newsLetter.primaryAttachmentDirectUrl ?? ''}',
                    ),
                    assetCode: newsLetter.primaryAttachmentAssetCode,
                    directUrl: newsLetter.primaryAttachmentDirectUrl,
                    mimeType: newsLetter.primaryAttachmentMimeType,
                    additionalAttachmentCount: newsLetter.additionalAttachmentCount,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsLetter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.newsletterCardTitle,
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    _AlignedMetaRow(
                      label: AppStrings.newsletterMetaCreatedBy,
                      value: newsLetter.createdBy,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _DateMetaRow(date: newsLetter.sentDate),
                        ),
                        if (showRecipientCount)
                          NewsletterRecipientCountBadge(
                            count: newsLetter.recipientCount,
                            recipientNames: newsLetter.recipientNames,
                            recipients: newsLetter.recipients,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.xxs),
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryColor.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
            ],
          ),
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
            AppStrings.newsletterMetaDate,
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.newsletterCardMetaLabel,
          ),
        ),
        Text(
          date,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: AppTextStyles.newsletterCardMetaValue,
        ),
      ],
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
            style: AppTextStyles.newsletterCardMetaLabel,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.newsletterCardMetaValue,
          ),
        ),
      ],
    );
  }
}
