import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/attachment_view/attachment_asset_builder.dart';
import 'package:wowcare/shared/common/widgets/attachment_view/attachment_viewer.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';

/// How a list of attachments is laid out.
enum AttachmentLayout {
  /// Images get a full-width preview big enough to read at a glance; documents
  /// stay as compact rows. The default for detail screens.
  preview,

  /// Everything is a compact row with a small thumbnail — for dense lists and
  /// cards where vertical space is scarce.
  compact,
}

/// Displays attachments for a list of asset codes.
///
/// The one widget every screen should use to show attachments: give it asset
/// codes and it resolves, caches, renders and handles failures. Tapping opens the
/// full-screen viewer, swipeable across the whole set.
///
/// Built for reuse — the task detail screen and the event detail screen pass the
/// same thing, and neither knows how resolution works.
class AttachmentSection extends StatelessWidget {
  const AttachmentSection({
    required this.assetCodes,
    this.layout = AttachmentLayout.preview,
    this.onRemove,
    this.previewHeight = 200,
    super.key,
  });

  final List<String> assetCodes;
  final AttachmentLayout layout;

  /// Shows a remove control per attachment when provided.
  final void Function(String assetCode)? onRemove;

  /// Height of an image preview in [AttachmentLayout.preview].
  final double previewHeight;

  @override
  Widget build(BuildContext context) {
    if (assetCodes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < assetCodes.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          AttachmentAssetBuilder(
            assetCode: assetCodes[i],
            builder: (context, snapshot) => _entry(
              context,
              snapshot: snapshot,
              index: i,
            ),
          ),
        ],
      ],
    );
  }

  Widget _entry(
    BuildContext context, {
    required AttachmentAssetSnapshot snapshot,
    required int index,
  }) {
    final asset = snapshot.asset;

    if (snapshot.isLoading || asset == null) {
      return _Shell(
        child: SizedBox(
          height: layout == AttachmentLayout.preview ? previewHeight : 64,
          child: const AttachmentLoadingTile(),
        ),
      );
    }

    if (asset.hasFailed) {
      return _Shell(
        borderColor: AppColors.errorColor.withValues(alpha: 0.35),
        child: _FailedRow(asset: asset, onRetry: snapshot.retry),
      );
    }

    final open = () => openAttachmentViewer(
          context,
          assetCodes: assetCodes,
          initialIndex: index,
        );

    // A picture is worth showing large — that is the whole point of the preview
    // layout. Everything else reads better as a titled row.
    if (layout == AttachmentLayout.preview && asset.isImage) {
      return _PreviewCard(
        asset: asset,
        height: previewHeight,
        onTap: open,
        onExpired: snapshot.retry,
        onRemove:
            onRemove == null ? null : () => onRemove!(asset.assetCode),
      );
    }

    return _Row(
      asset: asset,
      onTap: open,
      onExpired: snapshot.retry,
      onRemove: onRemove == null ? null : () => onRemove!(asset.assetCode),
    );
  }
}

/// Card chrome shared by every state so the section keeps one silhouette.
class _Shell extends StatelessWidget {
  const _Shell({required this.child, this.borderColor, this.onTap});

  final Widget child;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? Colors.grey.shade300),
      ),
      child: child,
    );
    if (onTap == null) return decorated;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: decorated,
    );
  }
}

/// Full-width image preview: legible without opening anything, tappable for the
/// zoomable viewer.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.asset,
    required this.height,
    required this.onTap,
    required this.onExpired,
    this.onRemove,
  });

  final AttachmentAsset asset;
  final double height;
  final VoidCallback onTap;
  final VoidCallback onExpired;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AttachmentImage(asset: asset, onExpired: onExpired),
                // Affordance for the viewer — without it a tappable image reads
                // as decoration.
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: _Pill(
                    icon: Icons.zoom_out_map_rounded,
                    label: 'View',
                  ),
                ),
                if (onRemove != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _RemoveButton(onTap: onRemove!),
                  ),
              ],
            ),
          ),
          _Caption(asset: asset),
        ],
      ),
    );
  }
}

/// Compact row for documents, and for the dense layout.
class _Row extends StatelessWidget {
  const _Row({
    required this.asset,
    required this.onTap,
    required this.onExpired,
    this.onRemove,
  });

  final AttachmentAsset asset;
  final VoidCallback onTap;
  final VoidCallback onExpired;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: asset.isImage
                    ? AttachmentImage(asset: asset, onExpired: onExpired)
                    : AttachmentGlyphTile(asset: asset, size: 52),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (asset.displaySubtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      asset.displaySubtitle,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            if (onRemove != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}

/// Name + type/size under a preview.
class _Caption extends StatelessWidget {
  const _Caption({required this.asset});

  final AttachmentAsset asset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (asset.displaySubtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    asset.displaySubtitle,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[500]),
        ],
      ),
    );
  }
}

/// The state that used to be an endless spinner: says what went wrong and offers
/// a way out.
class _FailedRow extends StatelessWidget {
  const _FailedRow({required this.asset, required this.onRetry});

  final AttachmentAsset asset;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 22,
            color: AppColors.errorColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.failureLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorColor,
                  ),
                ),
                if (asset.fileName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    asset.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
          if (asset.isRetryable)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.themeColor,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 34),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.58),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.4),
          ),
          child: const Icon(Icons.close_rounded, size: 15, color: Colors.white),
        ),
      ),
    );
  }
}
