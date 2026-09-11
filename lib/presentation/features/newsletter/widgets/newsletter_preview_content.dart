import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_color_theme.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_attachment_grid.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_component_view.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_html_normalizer.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_rich_html_text.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_themed_title_bar.dart';

class NewsletterPreviewContent extends StatelessWidget {
  const NewsletterPreviewContent({super.key, required this.newsletter});

  final Newsletter newsletter;

  bool _looksLikeStructuredPayload(String value) {
    final String text = value.trim();
    if (text.isEmpty) return false;
    if ((text.startsWith('{') && text.endsWith('}')) ||
        (text.startsWith('[') && text.endsWith(']'))) {
      return true;
    }
    final lower = text.toLowerCase();
    return lower.contains('"parts"') ||
        lower.contains('"imageurl"') ||
        lower.contains('"type"');
  }

  List<NewsletterAttachment> _sortedAttachments() {
    final List<NewsletterAttachment> items =
        List<NewsletterAttachment>.from(newsletter.attachments);
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items
        .where(
          (NewsletterAttachment a) =>
              a.mediaCode.trim().isNotEmpty || a.resolvedUrl.isNotEmpty,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final NewsletterThemeColors theme =
        NewsletterThemeColors.fromKey(newsletter.colorTheme);
    final String rawSubtitle = newsletter.subtitle.trim();
    // Normalized for the emptiness decisions below, not just for display: a
    // subtitle or body made entirely of editor filler is non-empty as a string
    // but renders nothing, which would otherwise leave the subtitle's trailing
    // 14px spacer behind and let an empty body suppress the "no content"
    // fallback. See [normalizeNewsletterHtml].
    final String subtitle = _looksLikeStructuredPayload(rawSubtitle)
        ? ''
        : normalizeNewsletterHtml(rawSubtitle);
    final String bodyHtml = normalizeNewsletterHtml(newsletter.bodyHtml);
    final List<NewsletterAttachment> attachments = _sortedAttachments();
    // "Has components worth rendering", not merely "has components": a
    // newsletter whose components are all filler must fall through to the body
    // / no-content branches rather than render an empty card.
    final bool hasComponents =
        NewsletterComponentList.hasRenderableContent(newsletter.components);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.xsPlus, AppSizes.md, AppSizes.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NewsletterThemedTitleBar(
            title: newsletter.title,
            theme: theme,
          ),
          const SizedBox(height: AppSizes.xsPlus),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.divider.withValues(alpha: 0.55),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (subtitle.isNotEmpty) ...[
                  NewsletterRichHtmlText(
                    htmlData: subtitle,
                    theme: theme,
                  ),
                  const SizedBox(height: 14),
                ],
                if (hasComponents)
                  NewsletterComponentList(
                    components: newsletter.components,
                    colorThemeKey: newsletter.colorTheme,
                  )
                else if (bodyHtml.isNotEmpty)
                  NewsletterRichHtmlText(
                    htmlData: bodyHtml,
                    theme: theme,
                  )
                else
                  Text(
                    AppStrings.newsletterNoContent,
                    style: AppTextStyles.newsletterEmptyContent,
                  ),
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.lg),
                  Divider(color: theme.divider, height: 1),
                  const SizedBox(height: AppSizes.md),
                  NewsletterAttachmentGrid(
                    newsletterId: newsletter.id,
                    attachments: attachments,
                    crossAxisCount: 2,
                    childAspectRatio: 1.35,
                    showFileName: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
