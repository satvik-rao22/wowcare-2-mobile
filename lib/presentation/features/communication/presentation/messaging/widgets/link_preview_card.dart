import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/url_preview_resolver.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';

/// Extracts the first HTTP/HTTPS URL from [text] and returns it, or null if
/// none is found.
String? extractFirstUrl(String text) {
  final preview = MessageContentProcessor.detectFirstPreview(text);
  if (preview == null || preview.kind != PreviewKind.url) return null;
  return preview.value;
}

/// WhatsApp-style link preview for the first URL in a message bubble.
///
/// Shows the plain tappable URL while [UrlPreviewResolver] is working, and
/// forever if no metadata is found. Once resolved, swaps to a card.
///
/// Layout note: the bubble shrink-fits via IntrinsicWidth/IntrinsicHeight.
/// A widget that resizes *itself* after layout (the old AnyLinkPreview card)
/// tripped Flutter's relayout-boundary/semantics assertions. So the card has a
/// fixed width, a fixed-height image box, and no LayoutBuilder — its size is
/// known the moment it is built and never changes afterwards.
///
/// Pass [isMe] = true to use the sender (purple gradient) colour scheme;
/// false for the receiver (light blue) scheme.
class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({super.key, required this.url, this.isMe = false});

  final String url;
  final bool isMe;

  static const double _imageHeight = 140;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UrlPreviewResult>(
      future: UrlPreviewResolver.resolve(url),
      initialData: UrlPreviewResolver.cached(url),
      builder: (context, snapshot) => switch (snapshot.data) {
        UrlPreviewFound(:final data) => _buildCard(context, data),
        _ => _buildPlainLink(),
      },
    );
  }

  Widget _buildPlainLink() {
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

  Widget _buildCard(BuildContext context, UrlPreviewData data) {
    // Bubble max width (72% of screen) minus its horizontal padding.
    final cardWidth = MediaQuery.sizeOf(context).width * 0.72 - AppSizes.sm * 2;
    final textColor = isMe
        ? AppColors.messagingOnAccent
        : AppColors.messagingTextStrong;
    final subColor = isMe
        ? AppColors.messagingOnAccent.withValues(alpha: 0.75)
        : AppColors.messagingCloseIcon;
    final cardColor = isMe
        ? AppColors.messagingOnAccent.withValues(alpha: 0.15)
        : AppColors.messagingContactChipBg;

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.xxs),
      child: GestureDetector(
        onTap: () => MessageContentProcessor.launchLink(url),
        child: Container(
          width: cardWidth,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.imageUrl != null)
                SizedBox(
                  width: cardWidth,
                  height: _imageHeight,
                  child: Image.network(
                    data.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      child: Icon(Icons.link_rounded, color: subColor),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (data.siteName != null)
                      Text(
                        data.siteName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.size14.copyWith(
                          fontSize: 11,
                          color: subColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (data.title != null)
                      Text(
                        data.title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.size14.copyWith(
                          fontSize: 13,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (data.description != null)
                      Text(
                        data.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.size14.copyWith(
                          fontSize: 12,
                          color: subColor,
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
      PreviewKind.url => _ComposerUrlPreview(url: preview.value),
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
              padding: const EdgeInsets.fromLTRB(
                AppSizes.sm,
                AppSizes.xs,
                0,
                AppSizes.xs,
              ),
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
                        fontWeight: FontWeight.w700,
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
                    fontWeight: FontWeight.w700,
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

/// URL preview shown in the composer's link-preview strip: a compact
/// thumbnail + title row once resolved, the plain URL while loading or when
/// nothing is found.
class _ComposerUrlPreview extends StatelessWidget {
  const _ComposerUrlPreview({required this.url});

  final String url;

  static const double _thumbSize = 40;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UrlPreviewResult>(
      future: UrlPreviewResolver.resolve(url),
      initialData: UrlPreviewResolver.cached(url),
      builder: (context, snapshot) {
        if (snapshot.data case UrlPreviewFound(:final data)) {
          return _buildResolved(data);
        }
        return _buildPlainUrl(
          isLoading: snapshot.connectionState != ConnectionState.done,
        );
      },
    );
  }

  Widget _buildPlainUrl({required bool isLoading}) {
    return SizedBox(
      height: _thumbSize,
      child: Row(
        children: [
          if (isLoading) ...[
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: AppSizes.xs),
          ],
          Expanded(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.size14.copyWith(
                fontSize: 11,
                color: AppColors.primaryColor,
                decoration: isLoading ? null : TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolved(UrlPreviewData data) {
    return SizedBox(
      height: _thumbSize,
      child: Row(
        children: [
          if (data.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                data.imageUrl!,
                width: _thumbSize,
                height: _thumbSize,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: _thumbSize,
                  height: _thumbSize,
                  child: Icon(Icons.link_rounded, size: 18),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.xs),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title ?? data.siteName ?? url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.size14.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  data.description ?? url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.size14.copyWith(
                    color: AppColors.messagingCloseIcon,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
