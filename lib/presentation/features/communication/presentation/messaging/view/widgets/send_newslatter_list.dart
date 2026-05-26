import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class NewsletterListItemModel {
  const NewsletterListItemModel({
    required this.title,
    required this.classroom,
    required this.sentDate,
    required this.summary,
  });

  final String title;
  final String classroom;
  final String sentDate;
  final String summary;
}

class NewsletterSentListCard extends StatelessWidget {
  const NewsletterSentListCard({
    super.key,
    required this.newsLetter,
    required this.onTap,
  });

  final NewsletterListItemModel newsLetter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsLetter.title,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${newsLetter.classroom} · ${newsLetter.sentDate}',
                      style: TextStyle(
                        color: AppColors.primaryColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    if (newsLetter.summary.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        newsLetter.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.primaryColor.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.primaryColor.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
