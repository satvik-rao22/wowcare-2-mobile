import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';

/// Extracts the first HTTP/HTTPS URL from [text] and returns it, or null if
/// none is found.
String? extractFirstUrl(String text) {
  final preview = MessageContentProcessor.detectFirstPreview(text);
  if (preview == null || preview.kind != PreviewKind.url) return null;
  return preview.value;
}

/// WhatsApp-style link preview card.
///
/// Fetches Open Graph / Twitter Card metadata for [url] and renders a
/// compact horizontal card with thumbnail, title, description, and domain.
///
/// Uses [AnyLinkPreview] which caches responses for [_cacheDuration] so
/// subsequent renders within the same session are instant.
///
/// Pass [isMe] = true to use the sender (purple gradient) colour scheme;
/// false for the receiver (light blue) scheme.
class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({super.key, required this.url, this.isMe = false});

  final String url;
  final bool isMe;

  static const Duration _cacheDuration = Duration(days: 1);

  @override
  Widget build(BuildContext context) {
    // Validate URL before attempting to fetch.
    if (!AnyLinkPreview.isValidLink(url)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => MessageContentProcessor.launchLink(url),
        child: AnyLinkPreview(
          link: url,
          displayDirection: UIDirection.uiDirectionHorizontal,
          showMultimedia: true,
          bodyMaxLines: 2,
          bodyTextOverflow: TextOverflow.ellipsis,
          titleStyle: TextStyle(
            color: isMe ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFamily: 'Manrope',
          ),
          bodyStyle: TextStyle(
            color: isMe
                ? Colors.white.withValues(alpha: 0.75)
                : const Color(0xFF64748B),
            fontSize: 11,
            fontFamily: 'Manrope',
          ),
          cache: _cacheDuration,
          backgroundColor: isMe
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFF0F4FF),
          borderRadius: 10,
          removeElevation: true,
          // Error state: render nothing so the bubble is not broken.
          errorWidget: const SizedBox.shrink(),
          // Loading state: small spinner so the bubble height is stable.
          placeholderWidget: SizedBox(
            height: 54,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ),
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
      PreviewKind.email => _buildContactPreview(
        icon: Icons.email_outlined,
        title: 'Email',
        value: preview.value,
        launchHref: 'mailto:${preview.value}',
        isMe: isMe,
      ),
      PreviewKind.phone => _buildContactPreview(
        icon: Icons.call_outlined,
        title: 'Phone',
        value: preview.value,
        launchHref: 'tel:${preview.value.replaceAll(RegExp(r'\D'), '')}',
        isMe: isMe,
      ),
    };
  }

  Widget _buildContactPreview({
    required IconData icon,
    required String title,
    required String value,
    required String launchHref,
    required bool isMe,
  }) {
    final textColor = isMe ? Colors.white : const Color(0xFF1E293B);
    final subColor = isMe
        ? Colors.white.withValues(alpha: 0.75)
        : const Color(0xFF64748B);
    final chipColor = isMe
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFF0F4FF);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => MessageContentProcessor.launchLink(launchHref),
        child: Container(
          padding: const EdgeInsets.all(12),
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
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppColors.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isMe ? Colors.white : AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        color: subColor,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor,
                        fontFamily: 'Manrope',
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
        titleStyle: TextStyle(
          color: AppColors.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          fontFamily: 'Manrope',
        ),
        bodyStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontFamily: 'Manrope',
        ),
        cache: const Duration(days: 1),
        backgroundColor: Colors.transparent,
        borderRadius: 8,
        removeElevation: true,
        errorWidget: Text(
          preview.value,
          style: TextStyle(
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  preview.value,
                  style: TextStyle(
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
      PreviewKind.email => _buildContactPreview(
        icon: Icons.email_outlined,
        title: 'Email',
        value: preview.value,
        launchHref: 'mailto:${preview.value}',
      ),
      PreviewKind.phone => _buildContactPreview(
        icon: Icons.call_outlined,
        title: 'Phone',
        value: preview.value,
        launchHref: 'tel:${preview.value.replaceAll(RegExp(r'\D'), '')}',
      ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
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
              padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
              child: child,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            color: const Color(0xFF94A3B8),
            onPressed: onDismiss,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPreview({
    required IconData icon,
    required String title,
    required String value,
    required String launchHref,
  }) {
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1E293B),
                    fontFamily: 'Manrope',
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
