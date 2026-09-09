part of 'message_bubble_widget.dart';

// Private helper widgets for [MessageBubble], split out of
// message_bubble_widget.dart to keep that file within the size ceiling
// (Mandate 6). A `part` file so these stay library-private with no renames
// and share the parent's imports — pure move, no behaviour change.

/// Renders a chat-bubble image thumbnail directly (bypassing the
/// `thumbnailer` package's `Thumbnail` widget, which has no error handling
/// of its own): a resolver failure returned empty bytes as a "successful"
/// result, which `Thumbnail` then handed to an internal `Image.memory` with
/// no `errorBuilder`, throwing an uncaught "Invalid image data" exception
/// and leaving the tile blank. Explicitly guards on empty bytes before ever
/// calling [Image.memory], and gives that call its own `errorBuilder` too —
/// mirrors [FullAttachmentViewer]'s `_ResilientImage`. Uses the app's
/// standard [PrimaryCircularLoader] instead of `Thumbnail`'s raw
/// `CircularProgressIndicator` while [bytesResolver] is in flight.
class _BubbleImageThumbnail extends StatefulWidget {
  const _BubbleImageThumbnail({
    super.key,
    required this.bytesResolver,
    required this.size,
    required this.errorIconSize,
  });

  final Future<Uint8List> Function() bytesResolver;
  final double size;
  final double errorIconSize;

  @override
  State<_BubbleImageThumbnail> createState() => _BubbleImageThumbnailState();
}

class _BubbleImageThumbnailState extends State<_BubbleImageThumbnail> {
  late final Future<Uint8List> _bytesFuture = widget.bytesResolver();

  Widget _broken() => Container(
    color: AppColors.messagingThumbPlaceholderBg,
    child: Icon(Icons.image, size: widget.errorIconSize, color: AppColors.messagingIconMuted),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: AppColors.cardColor,
            child: Center(
              child: PrimaryCircularLoader(
                size: widget.size < 60 ? 22 : 28,
                strokeWidth: widget.size < 60 ? 2 : 2.5,
              ),
            ),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return _broken();
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          errorBuilder: (context, error, stackTrace) => _broken(),
        );
      },
    );
  }
}

/// Shown instead of the broken-image icon when the backend has reported the
/// attachment's asset as still `PROCESSING` (no delivery URL yet) rather
/// than an outright failure — tells the user it's still on its way instead
/// of looking like a load error.
/// Semi-transparent scrim + spinner drawn over an already-visible local
/// image preview while the attachment hasn't finished uploading/registering
/// yet (no delivery URL). Distinct from [_AttachmentProcessingPlaceholder],
/// which replaces the whole tile when there's no local preview to show at
/// all (a cached/history message with only a still-processing remote asset)
/// — here the picked photo is already on screen, this just signals "still
/// going" on top of it, the way a chat app overlays an in-flight send.
class _UploadingOverlay extends StatelessWidget {
  const _UploadingOverlay({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blackColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: PrimaryCircularLoader(
          size: compact ? 20 : 26,
          strokeWidth: 2.5,
          color: AppColors.messagingOnAccent,
        ),
      ),
    );
  }
}

class _AttachmentProcessingPlaceholder extends StatelessWidget {
  const _AttachmentProcessingPlaceholder({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 28.0 : 40.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryCircularLoader(size: iconSize, strokeWidth: 2.5),
        SizedBox(height: compact ? 6 : 8),
        Text(
          AppStrings.processing,
          style: AppTextStyles.size14.copyWith(
            fontSize: compact ? 11 : 13,
            color: AppColors.messagingMetaStrong,
          ),
        ),
      ],
    );
  }
}

/// Small tappable status shown next to a sent message's timestamp instead of
/// the normal delivery tick — either "Failed · Retry" (the send itself
/// errored: attachment upload or the API call) or "Processing" (sent fine,
/// but an attachment is still waiting on the document service; tapping just
/// re-polls, it does not re-send). No-op decoration (not a real button) when
/// [onTap] is null, e.g. a cached/legacy message with no retry wired up.
class _RetryAffordance extends StatelessWidget {
  const _RetryAffordance({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.size14.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
