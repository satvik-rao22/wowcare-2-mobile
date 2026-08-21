import 'package:flutter/material.dart';

import 'package:wowcare/domain/features/newsletter/entities/newsletter.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/presentation/features/newsletter/util/newsletter_color_theme.dart';
import 'package:wowcare/presentation/features/newsletter/view/widgets/newsletter_attachment_grid.dart';
import 'package:wowcare/presentation/features/newsletter/view/widgets/newsletter_component_view.dart';
import 'package:wowcare/presentation/features/newsletter/view/widgets/newsletter_rich_html_text.dart';
import 'package:wowcare/presentation/features/newsletter/view/widgets/newsletter_themed_title_bar.dart';

import '../../../../../app/theme/colors.dart';

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
    final List<NewsletterAttachment> items = List<NewsletterAttachment>.from(
      newsletter.attachments,
    );
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
    final NewsletterThemeAppColors theme = NewsletterThemeAppColors.fromKey(
      newsletter.colorTheme,
    );
    final String rawSubtitle = newsletter.subtitle.trim();
    final String subtitle = _looksLikeStructuredPayload(rawSubtitle)
        ? ''
        : rawSubtitle;
    final List<NewsletterAttachment> attachments = _sortedAttachments();
    final bool hasComponents = newsletter.components.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NewsletterThemedTitleBar(title: newsletter.title, theme: theme),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.divider.withValues(alpha: 0.55)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (subtitle.isNotEmpty) ...[
                  NewsletterRichHtmlText(htmlData: subtitle, theme: theme),
                  const SizedBox(height: 14),
                ],
                if (hasComponents)
                  NewsletterComponentList(
                    components: newsletter.components,
                    colorThemeKey: newsletter.colorTheme,
                  )
                else if (newsletter.bodyHtml.trim().isNotEmpty)
                  NewsletterRichHtmlText(
                    htmlData: newsletter.bodyHtml,
                    theme: theme,
                  )
                else
                  Text(
                    'No newsletter content available.',
                    style: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.65),
                      fontSize: 14,
                    ),
                  ),
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: theme.divider, height: 1),
                  const SizedBox(height: 16),
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
