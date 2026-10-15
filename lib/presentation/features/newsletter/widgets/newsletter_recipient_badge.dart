import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

/// The recipient-count badge on a newsletter list card, and the bottom sheet
/// it opens.
///
/// Split out of `send_newsletter_list.dart` (§6's 400-line ceiling). The cut
/// is by cohesive unit, not at an arbitrary line: the badge, the recipient
/// de-duplication it does before opening, the sheet, and the sheet's row are
/// one feature and nothing else in the card file touches them.
class NewsletterRecipientCountBadge extends StatelessWidget {
  const NewsletterRecipientCountBadge({
    required this.count,
    required this.recipientNames,
    required this.recipients,
  });

  final int count;
  final List<String> recipientNames;
  final List<NewsletterRecipientSummary> recipients;

  List<NewsletterRecipientSummary> _recipientItems() {
    if (recipients.isNotEmpty) {
      final seen = <String>{};
      final items =
          recipients.where((NewsletterRecipientSummary recipient) {
            final displayName = recipient.displayName.trim();
            if (displayName.isEmpty) return false;
            final code = recipient.userCode.trim();
            final key = code.isNotEmpty ? code : displayName.toLowerCase();
            return seen.add(key);
          }).toList()..sort(
            (NewsletterRecipientSummary a, NewsletterRecipientSummary b) => a
                .displayName
                .toLowerCase()
                .compareTo(b.displayName.toLowerCase()),
          );
      return items;
    }

    return recipientNames
        .map((String name) => name.trim())
        .where((String name) => name.isNotEmpty)
        .toSet()
        .map(
          (String name) =>
              NewsletterRecipientSummary(displayName: name, userCode: ''),
        )
        .toList()
      ..sort(
        (NewsletterRecipientSummary a, NewsletterRecipientSummary b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
  }

  void _showRecipients(BuildContext context) {
    final items = _recipientItems();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.sm,
                    AppSizes.sm,
                    AppSizes.md,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.brandSoftColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.18,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.whiteColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryColor.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            child: Icon(
                              Icons.groups_2_outlined,
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.78,
                              ),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  AppStrings.newsletterRecipients,
                                  style: AppTextStyles.newsletterRecipientCount,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$count '
                                  '${count == 1 ? AppStrings.newsletterRecipientSingular : AppStrings.newsletterRecipientPlural}',
                                  style: AppTextStyles
                                      .newsletterRecipientCountCaption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // §7.6: `sizeOf`, not `of`. Same value, but the
                      // sheet no longer rebuilds when only the insets change.
                      maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.55,
                    ),
                    child: items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 30,
                              horizontal: AppSizes.lg,
                            ),
                            child: Center(
                              child: Text(
                                AppStrings.newsletterRecipientsUnavailable,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.newsletterRecipientName,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(
                              AppSizes.lg,
                              AppSizes.sm,
                              AppSizes.lg,
                              AppSizes.lg,
                            ),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.08,
                              ),
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final recipient = items[index];
                              return _RecipientListTile(recipient: recipient);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSizes.xs),
      child: Material(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _showRecipients(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  size: 18,
                  color: AppColors.primaryColor.withValues(alpha: 0.68),
                ),
                const SizedBox(width: 3),
                Text(
                  '$count',
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.newsletterRecipientBadge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipientListTile extends StatelessWidget {
  const _RecipientListTile({required this.recipient});

  final NewsletterRecipientSummary recipient;

  @override
  Widget build(BuildContext context) {
    final name = recipient.displayName.trim();
    final code = recipient.userCode.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xsPlus),
      child: Row(
        children: [
          ProfileAvatar(
            name: name,
            studentCode: code.isNotEmpty ? code : null,
            size: 40,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.newsletterSheetTitle,
            ),
          ),
        ],
      ),
    );
  }
}
