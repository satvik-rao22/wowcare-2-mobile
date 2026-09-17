import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset_service.dart';

/// What [AttachmentAssetBuilder] hands its builder on every rebuild.
class AttachmentAssetSnapshot {
  const AttachmentAssetSnapshot({
    required this.isLoading,
    required this.retry,
    this.asset,
  });

  /// True until the first resolution settles, and again during a retry.
  final bool isLoading;

  /// Null while [isLoading]; otherwise always set — a failure is a value, so
  /// this is non-null even when the asset could not be fetched.
  final AttachmentAsset? asset;

  /// Re-resolves, bypassing the cache.
  final VoidCallback retry;

  bool get isReady => asset?.isReady ?? false;
  bool get hasFailed => asset?.hasFailed ?? false;
}

/// Resolves one asset code and rebuilds as it settles.
///
/// The single entry point for showing an attachment anywhere in the app: pass an
/// asset code, get back loading / ready / failed plus a retry. Resolution,
/// caching and de-duplication live in [AttachmentAssetService], so ten rows
/// sharing a code cost one request and a cached asset paints on the first frame
/// with no loading flash.
class AttachmentAssetBuilder extends StatefulWidget {
  const AttachmentAssetBuilder({
    required this.assetCode,
    required this.builder,
    this.service,
    super.key,
  });

  final String assetCode;

  final Widget Function(BuildContext context, AttachmentAssetSnapshot snapshot)
      builder;

  /// Injectable for tests; defaults to the registered singleton so callers do
  /// not have to thread it through.
  final AttachmentAssetService? service;

  @override
  State<AttachmentAssetBuilder> createState() =>
      _AttachmentAssetBuilderState();
}

class _AttachmentAssetBuilderState extends State<AttachmentAssetBuilder> {
  AttachmentAssetService get _service =>
      widget.service ?? serviceLocator<AttachmentAssetService>();

  AttachmentAsset? _asset;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AttachmentAssetBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetCode != widget.assetCode) _load();
  }

  void _load({bool forceRefresh = false}) {
    // A fresh cache hit means no loading state at all — important for lists,
    // where a spinner per row on every scroll would read as broken.
    final cached = forceRefresh ? null : _service.cached(widget.assetCode);
    if (cached != null) {
      setState(() {
        _asset = cached;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      if (forceRefresh) _asset = null;
    });
    _service.resolve(widget.assetCode, forceRefresh: forceRefresh).then((asset) {
      if (!mounted) return;
      setState(() {
        _asset = asset;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      AttachmentAssetSnapshot(
        isLoading: _loading,
        asset: _asset,
        retry: () => _load(forceRefresh: true),
      ),
    );
  }
}

/// Icon + tint for a file type, so a document reads as its kind at a glance.
({IconData icon, Color color}) attachmentGlyph(AttachmentAsset asset) {
  if (asset.isVideo) {
    return (icon: Icons.videocam_rounded, color: AppPalette.dataPurple);
  }
  if (asset.isPdf) {
    return (icon: Icons.picture_as_pdf_rounded, color: AppPalette.statusError);
  }
  switch (asset.extension) {
    case 'doc':
    case 'docx':
      return (icon: Icons.article_rounded, color: AppPalette.statusInfo);
    case 'xls':
    case 'xlsx':
      return (icon: Icons.table_chart_rounded, color: AppPalette.statusSuccess);
    default:
      if (asset.isImage) {
        return (icon: Icons.image_outlined, color: AppColors.themeColor);
      }
      return (
        icon: Icons.insert_drive_file_rounded,
        color: AppColors.themeColor,
      );
  }
}

/// Tinted glyph tile for anything without a visual preview.
class AttachmentGlyphTile extends StatelessWidget {
  const AttachmentGlyphTile({
    required this.asset,
    this.size,
    this.showLabel = true,
    super.key,
  });

  final AttachmentAsset asset;

  /// Null fills the parent — use inside a sized box or an aspect ratio.
  final double? size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final glyph = attachmentGlyph(asset);
    final iconSize = size == null ? 30.0 : (size! * 0.42).clamp(16.0, 40.0);
    return Container(
      width: size,
      height: size,
      color: glyph.color.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(glyph.icon, size: iconSize, color: glyph.color),
          if (showLabel && asset.extension.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              asset.extension.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: glyph.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The image itself for pictures, a glyph for everything else.
///
/// On a decode failure the cached URL is invalidated and re-resolved once — a
/// presigned link that expired mid-session is the most common cause, and a
/// silent broken-image box was the old symptom.
class AttachmentImage extends StatelessWidget {
  const AttachmentImage({
    required this.asset,
    required this.onExpired,
    this.fit = BoxFit.cover,
    super.key,
  });

  final AttachmentAsset asset;
  final VoidCallback onExpired;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (!asset.isImage || asset.url.isEmpty) {
      return AttachmentGlyphTile(asset: asset);
    }
    return CachedNetworkImage(
      imageUrl: asset.url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (_, __) => const AttachmentLoadingTile(),
      errorWidget: (_, __, ___) {
        onExpired();
        return AttachmentGlyphTile(asset: asset);
      },
    );
  }
}

/// Neutral placeholder while a resolve or a decode is in flight.
class AttachmentLoadingTile extends StatelessWidget {
  const AttachmentLoadingTile({this.size, super.key});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppPalette.surfaceMuted,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.themeColor,
        ),
      ),
    );
  }
}

/// Visible failure state with a Retry — replaces the indefinite spinner that
/// made a failed fetch indistinguishable from a slow one.
class AttachmentErrorTile extends StatelessWidget {
  const AttachmentErrorTile({
    required this.asset,
    required this.onRetry,
    this.size,
    this.compact = false,
    super.key,
  });

  final AttachmentAsset asset;
  final VoidCallback onRetry;
  final double? size;

  /// Icon only — for thumbnails too small to fit a label.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: size,
      height: size,
      color: AppColors.errorColor.withValues(alpha: 0.07),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: compact
          ? Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: AppColors.errorColor,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 24,
                  color: AppColors.errorColor,
                ),
                const SizedBox(height: 6),
                Text(
                  asset.failureLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (asset.isRetryable) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to retry',
                    style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
                  ),
                ],
              ],
            ),
    );
    if (!asset.isRetryable) return tile;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onRetry,
      child: tile,
    );
  }
}
