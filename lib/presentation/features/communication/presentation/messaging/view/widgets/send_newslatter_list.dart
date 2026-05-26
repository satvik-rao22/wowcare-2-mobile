import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';

class NewsletterListItemModel {
  const NewsletterListItemModel({
    required this.title,
    required this.classroom,
    required this.sentDate,
    required this.createdBy,
    required this.recipientCount,
    this.thumbnailUrl,
  });

  final String title;
  final String classroom;
  final String sentDate;
  final String createdBy;
  final int recipientCount;
  final String? thumbnailUrl;
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 84,
                  height: 56,
                  child: _CardThumbnail(imageUrl: newsLetter.thumbnailUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsLetter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _MetaText(
                      'Created by',
                      maxLines: 1,
                    ),
                    Text(
                      newsLetter.sentDate,
                      style: TextStyle(
                        color: AppColors.primaryColor.withValues(alpha: 0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _MetaText('Classroom'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 86,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                  Text(
                    newsLetter.createdBy,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.82),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 18,
                        color: AppColors.primaryColor.withValues(alpha: 0.62),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${newsLetter.recipientCount}',
                        style: TextStyle(
                          color: AppColors.primaryColor.withValues(alpha: 0.78),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    newsLetter.classroom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.78),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardThumbnail extends StatelessWidget {
  const _CardThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String url = (imageUrl ?? '').trim();
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _thumbnailPlaceholder();
        },
        errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
      );
    }
    return _thumbnailPlaceholder();
  }

  Widget _thumbnailPlaceholder() {
    return Image.asset(
      MediaRes.deafultNewsletterImage,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          color: AppColors.primaryColor.withValues(alpha: 0.5),
          size: 22,
        ),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(
    this.value, {
    this.maxLines = 2,
  });

  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.primaryColor.withValues(alpha: 0.58),
        fontSize: 13,
      ),
    );
  }
}
