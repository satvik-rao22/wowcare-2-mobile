import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';

/// Extracts the first HTTP/HTTPS URL from [text] and returns it, or null if
/// none is found.
String? extractFirstUrl(String text) {
  final preview = MessageContentProcessor.detectFirstPreview(text);
  if (preview == null || preview.kind != PreviewKind.url) return null;
  return preview.value;
}

/// Plain clickable link — shown for the first URL found in a message.
///
/// No Open Graph/metadata fetch, no async-loaded thumbnail: just the raw
/// URL as tappable, underlined text. A prior version fetched a rich
/// WhatsApp-style preview card via [AnyLinkPreview], but that card resizes
/// itself asynchronously once its fetch completes — the message bubble
/// wraps its content in IntrinsicWidth/IntrinsicHeight to shrink-fit, and a
/// descendant resizing itself after that ancestor's first layout pass
/// repeatedly tripped Flutter's relayout-boundary/semantics assertions
/// ('_debugRelayoutBoundaryAlreadyMarkedNeedsLayout',
/// '!semantics.parentDataDirty'). A static, fixed-size widget has no such
/// resize to trigger it.
///
/// Pass [isMe] = true to use the sender (purple gradient) colour scheme;
/// false for the receiver (light blue) scheme.
class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({super.key, required this.url, this.isMe = false});

  final String url;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    if (!AnyLinkPreview.isValidLink(url)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.xxs),
      child: GestureDetector(
        onTap: () => MessageContentProcessor.launchLink(url),
        child: Text(
          url,
          style: AppTextStyles.size14.copyWith(
            color: isMe ? AppColors.messagingOnAccent : AppColors.primaryColor,
            fontSize: 13,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

/// Composer link preview strip shown above [ChatInputBar] when the current
/// draft contains a URL.
///
/// Renders a dismissible preview card so the sender knows a link preview will
/// be attached to their message.
class PreviewCard extends StatelessWidget {
  const PreviewCard({super.key, required this.preview, this.isMe = false});

  final PreviewMatch preview;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return switch (preview.kind) {
      PreviewKind.url => LinkPreviewCard(url: preview.value, isMe: isMe),
      PreviewKind.email => _ContactPreviewChip(
        icon: Icons.email_outlined,
        title: AppStrings.email,
        value: preview.value,
        launchHref: 'mailto:${preview.value}',
        isMe: isMe,
      ),
      PreviewKind.phone => _ContactPreviewChip(
        icon: Icons.call_outlined,
        title: AppStrings.phone,
        value: preview.value,
        launchHref: 'tel:${preview.value.replaceAll(RegExp(r'\D'), '')}',
        isMe: isMe,
      ),
    };
  }

}

class ComposerLinkPreview extends StatelessWidget {
  const ComposerLinkPreview({
    super.key,
    required this.preview,
    required this.onDismiss,
  });

  final PreviewMatch preview;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final child = switch (preview.kind) {
      PreviewKind.url => AnyLinkPreview(
        link: preview.value,
        displayDirection: UIDirection.uiDirectionHorizontal,
        showMultimedia: true,
        bodyMaxLines: 1,
        bodyTextOverflow: TextOverflow.ellipsis,
        titleStyle: AppTextStyles.size14.copyWith(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        bodyStyle: AppTextStyles.size14.copyWith(
          color: AppColors.messagingCloseIcon,
          fontSize: 11,
        ),
        cache: const Duration(days: 1),
        backgroundColor: AppColors.transparentColor,
        borderRadius: 8,
        removeElevation: true,
        errorWidget: Text(
          preview.value,
          style: AppTextStyles.size14.copyWith(
            fontSize: 11,
            color: AppColors.primaryColor,
            decoration: TextDecoration.underline,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        placeholderWidget: SizedBox(
          height: 36,
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  preview.value,
                  style: AppTextStyles.size14.copyWith(
                    fontSize: 11,
                    color: AppColors.primaryColor.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      PreviewKind.email => _ComposerContactPreview(
        icon: Icons.email_outlined,
        title: AppStrings.email,
        value: preview.value,
        launchHref: 'mailto:${preview.value}',
      ),
      PreviewKind.phone => _ComposerContactPreview(
        icon: Icons.call_outlined,
        title: AppStrings.phone,
        value: preview.value,
        launchHref: 'tel:${preview.value.replaceAll(RegExp(r'\D'), '')}',
      ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.sm, 0, AppSizes.sm, 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.sm, AppSizes.xs, 0, AppSizes.xs),
              child: child,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            color: AppColors.messagingDismissIcon,
            onPressed: onDismiss,
            padding: const EdgeInsets.all(AppSizes.xs),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

}

/// Contact (email/phone) preview chip shown inside a message bubble.
class _ContactPreviewChip extends StatelessWidget {
  const _ContactPreviewChip({
    required this.icon,
    required this.title,
    required this.value,
    required this.launchHref,
    required this.isMe,
  });

  final IconData icon;
  final String title;
  final String value;
  final String launchHref;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final textColor = isMe
        ? AppColors.messagingOnAccent
        : AppColors.messagingTextStrong;
    final subColor = isMe
        ? AppColors.messagingOnAccent.withValues(alpha: 0.75)
        : AppColors.messagingCloseIcon;
    final chipColor = isMe
        ? AppColors.messagingOnAccent.withValues(alpha: 0.15)
        : AppColors.messagingContactChipBg;

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.xs),
      child: GestureDetector(
        onTap: () => MessageContentProcessor.launchLink(launchHref),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.messagingOnAccent.withValues(alpha: 0.18)
                      : AppColors.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isMe
                      ? AppColors.messagingOnAccent
                      : AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: AppSizes.xsPlus),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.size14.copyWith(
                        fontSize: 11,
                        color: subColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTextStyles.size14.copyWith(
                        fontSize: 12,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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

/// Contact (email/phone) preview shown in the composer's link-preview strip.
class _ComposerContactPreview extends StatelessWidget {
  const _ComposerContactPreview({
    required this.icon,
    required this.title,
    required this.value,
    required this.launchHref,
  });

  final IconData icon;
  final String title;
  final String value;
  final String launchHref;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => MessageContentProcessor.launchLink(launchHref),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 16),
          ),
          const SizedBox(width: AppSizes.xsPlus),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.size14.copyWith(
                    fontSize: 11,
                    color: AppColors.primaryColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.size14.copyWith(
                    fontSize: 12,
                    color: AppColors.messagingTextStrong,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
