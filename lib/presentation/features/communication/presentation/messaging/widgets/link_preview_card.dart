import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';

/// Extracts the first HTTP/HTTPS URL from [text] and returns it, or null if
/// none is found.
String? extractFirstUrl(String text) {
  // Strip HTML tags first so we don't match href= attributes twice.
  final plain = text.replaceAll(RegExp(r'<[^>]*>'), '');
  final match = RegExp(
    r"""https?://[^\s<>()"']+""",
    caseSensitive: false,
  ).firstMatch(plain);
  return match?.group(0);
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
  const LinkPreviewCard({
    super.key,
    required this.url,
    this.isMe = false,
  });

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
class ComposerLinkPreview extends StatelessWidget {
  const ComposerLinkPreview({
    super.key,
    required this.url,
    required this.onDismiss,
  });

  final String url;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!AnyLinkPreview.isValidLink(url)) return const SizedBox.shrink();

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
              child: AnyLinkPreview(
                link: url,
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
                  url,
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
                          url,
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
}
