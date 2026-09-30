import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_color_theme.dart';

/// Newsletter title bar, on its theme's flat fill.
class NewsletterThemedTitleBar extends StatelessWidget {
  const NewsletterThemedTitleBar({
    super.key,
    required this.title,
    required this.theme,
  });

  final String title;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final String displayTitle = title.trim();
    if (displayTitle.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
      decoration: BoxDecoration(
        color: theme.titleBarColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        displayTitle,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        // Chrome from AppTextStyles; the colour is the author's
        // `titleTextColor`, which is data (§4).
        style: AppTextStyles.newsletterTitleBar.copyWith(
          color: theme.titleTextColor,
        ),
      ),
    );
  }
}
