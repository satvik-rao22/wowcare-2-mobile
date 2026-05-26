import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';

/// Displays newsletter attachment placeholders from list payload.
/// Image URLs will be wired when the document/media API is integrated.
class NewsletterAttachmentGrid extends StatelessWidget {
  const NewsletterAttachmentGrid({
    super.key,
    required this.newsletterId,
    required this.attachments,
    this.isLoading = false,
  });

  final int newsletterId;
  final List<NewsletterAttachment> attachments;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: 2,
        itemBuilder: (BuildContext context, int index) {
          return const ShimmerLoaderCard(
            margin: EdgeInsets.zero,
            child: SizedBox(width: 75, height: 75),
          );
        },
      );
    }

    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: TextStyle(
            color: AppColors.primaryColor.withValues(alpha: 0.85),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: attachments.length,
          itemBuilder: (BuildContext context, int index) {
            final NewsletterAttachment attachment = attachments[index];
            return _AttachmentTile(attachment: attachment);
          },
        ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final NewsletterAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final String label = attachment.fileName.trim().isNotEmpty
        ? attachment.fileName
        : attachment.mediaCode;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(244, 247, 254, 1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                attachment.isImage
                    ? MediaRes.deafultNewsletterImage
                    : MediaRes.deafultNewsletterImage,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.insert_drive_file_outlined,
                  size: 36,
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
