import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_color_theme.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_link_launcher.dart';

/// Renders newsletter HTML from `contentJson` text parts.
///
/// Inline CSS (colors, list-style-type, underline, alignment, etc.) is preserved.
/// Theme colors apply only as body-level defaults — not forced onto child tags.
class NewsletterRichHtmlText extends StatelessWidget {
  const NewsletterRichHtmlText({
    super.key,
    required this.htmlData,
    required this.theme,
    this.baseStyle,
    this.isHeading = false,
  });

  final String htmlData;
  final NewsletterThemeColors theme;
  final TextStyle? baseStyle;
  final bool isHeading;

  @override
  Widget build(BuildContext context) {
    final String data = htmlData.trim();
    if (data.isEmpty) return const SizedBox.shrink();

    // §4 split. Size / weight / line height are app chrome and come from
    // AppTextStyles. The COLOUR is the newsletter author's own palette
    // (`NewsletterThemeColors`), which is data on the record — it is applied
    // here with copyWith and is deliberately not a token.
    //
    // `fontFamily` is gone: it was 'Manrope', and the `?? Fonts.manrope`
    // fallback in the body style below produces exactly the same family.
    final TextStyle defaults = baseStyle ??
        (isHeading
                ? AppTextStyles.newsletterRichHeading
                : AppTextStyles.newsletterRichBody)
            .copyWith(color: isHeading ? theme.heading : theme.body);

    return html.Html(
      data: data,
      shrinkWrap: true,
      onLinkTap: (String? url, Map<String, String> attributes, _) {
        _handleLinkTap(context, url);
      },
      style: _richTextStyles(theme: theme, defaults: defaults),
    );
  }

  Future<void> _handleLinkTap(BuildContext context, String? url) async {
    final bool opened = await openNewsletterHyperlink(url);
    if (opened || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          url == null || url.trim().isEmpty
              ? AppStrings.newsletterLinkOpenFailed
              : '${AppStrings.newsletterLinkOpenFailedPrefix}${url.trim()}',
        ),
        backgroundColor: AppColors.warningColor,
      ),
    );
  }

  static Map<String, html.Style> _richTextStyles({
    required NewsletterThemeColors theme,
    required TextStyle defaults,
  }) {
    return <String, html.Style>{
      'body': html.Style(
        margin: html.Margins.zero,
        padding: html.HtmlPaddings.zero,
        fontSize: html.FontSize(defaults.fontSize ?? 15),
        // KEPT, unlike the other Manrope lines: flutter_html builds its own
        // text styles and does NOT inherit ThemeData.fontFamily, so deleting
        // this would silently change every newsletter's body font.
        fontFamily: defaults.fontFamily ?? Fonts.manrope,
        color: defaults.color,
        fontWeight: defaults.fontWeight,
        lineHeight: html.LineHeight(defaults.height ?? 1.45),
      ),
      'p': html.Style(
        margin: html.Margins.only(bottom: 6),
        padding: html.HtmlPaddings.zero,
      ),
      'span': html.Style(),
      'div': html.Style(
        margin: html.Margins.zero,
        padding: html.HtmlPaddings.zero,
      ),
      'br': html.Style(
        height: html.Height(6),
      ),
      'ol': html.Style(
        display: html.Display.block,
        margin: html.Margins.only(bottom: 8, top: 4),
        padding: html.HtmlPaddings.only(left: 24),
        listStyleType: html.ListStyleType.decimal,
      ),
      'ul': html.Style(
        display: html.Display.block,
        margin: html.Margins.only(bottom: 8, top: 4),
        padding: html.HtmlPaddings.only(left: 24),
        listStyleType: html.ListStyleType.disc,
      ),
      'li': html.Style(
        display: html.Display.listItem,
        margin: html.Margins.only(bottom: 4),
        lineHeight: html.LineHeight(1.45),
      ),
      'u': html.Style(
        textDecoration: TextDecoration.underline,
      ),
      'ins': html.Style(
        textDecoration: TextDecoration.underline,
      ),
      's': html.Style(
        textDecoration: TextDecoration.lineThrough,
      ),
      'strike': html.Style(
        textDecoration: TextDecoration.lineThrough,
      ),
      'del': html.Style(
        textDecoration: TextDecoration.lineThrough,
      ),
      'strong': html.Style(
        fontWeight: FontWeight.w700,
      ),
      'b': html.Style(
        fontWeight: FontWeight.w700,
      ),
      'em': html.Style(
        fontStyle: FontStyle.italic,
      ),
      'i': html.Style(
        fontStyle: FontStyle.italic,
      ),
      'h1': html.Style(
        fontSize: html.FontSize(24),
        fontWeight: FontWeight.w700,
        color: theme.heading,
        margin: html.Margins.only(bottom: 8),
      ),
      'h2': html.Style(
        fontSize: html.FontSize(22),
        fontWeight: FontWeight.w700,
        color: theme.heading,
        margin: html.Margins.only(bottom: 6),
      ),
      'h3': html.Style(
        fontSize: html.FontSize(20),
        fontWeight: FontWeight.w600,
        color: theme.heading,
        margin: html.Margins.only(bottom: 4),
      ),
      'h4': html.Style(
        fontSize: html.FontSize(18),
        fontWeight: FontWeight.w600,
        color: theme.heading,
        margin: html.Margins.only(bottom: 4),
      ),
      'h5': html.Style(
        fontSize: html.FontSize(16),
        fontWeight: FontWeight.w600,
        color: theme.heading,
        margin: html.Margins.only(bottom: 4),
      ),
      'h6': html.Style(
        fontSize: html.FontSize(15),
        fontWeight: FontWeight.w600,
        color: theme.heading,
        margin: html.Margins.only(bottom: 4),
      ),
      'a': html.Style(
        color: theme.accent,
        textDecoration: TextDecoration.underline,
      ),
      'blockquote': html.Style(
        margin: html.Margins.symmetric(vertical: 8),
        padding: html.HtmlPaddings.only(left: 12),
        border: Border(
          left: BorderSide(color: theme.divider, width: 3),
        ),
      ),
      'code': html.Style(
        fontFamily: 'monospace',
        backgroundColor: theme.divider.withValues(alpha: 0.25),
        padding: html.HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
      ),
      'pre': html.Style(
        fontFamily: 'monospace',
        whiteSpace: html.WhiteSpace.pre,
        margin: html.Margins.symmetric(vertical: 8),
        padding: html.HtmlPaddings.all(10),
        backgroundColor: theme.divider.withValues(alpha: 0.2),
      ),
      'sub': html.Style(
        fontSize: html.FontSize(12),
        verticalAlign: html.VerticalAlign.sub,
      ),
      'sup': html.Style(
        fontSize: html.FontSize(12),
        verticalAlign: html.VerticalAlign.sup,
      ),
      'hr': html.Style(
        margin: html.Margins.symmetric(vertical: 10),
        border: Border(
          top: BorderSide(color: theme.divider, width: 1),
        ),
      ),
    };
  }
}
