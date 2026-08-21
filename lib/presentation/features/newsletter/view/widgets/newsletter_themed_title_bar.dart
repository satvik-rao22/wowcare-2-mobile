import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/newsletter/util/newsletter_color_theme.dart';

/// Newsletter title bar with a horizontal theme gradient background.
class NewsletterThemedTitleBar extends StatelessWidget {
  const NewsletterThemedTitleBar({
    super.key,
    required this.title,
    required this.theme,
  });

  final String title;
  final NewsletterThemeAppColors theme;

  @override
  Widget build(BuildContext context) {
    final String displayTitle = title.trim();
    if (displayTitle.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: theme.titleBarGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        displayTitle,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: theme.titleTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Manrope',
          height: 1.25,
        ),
      ),
    );
  }
}
