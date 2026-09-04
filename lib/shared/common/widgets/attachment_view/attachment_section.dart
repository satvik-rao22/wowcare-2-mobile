import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/attachment_view/attachment_tiles.dart';
import 'package:wowcare/shared/common/widgets/attachment_view/attachment_viewer.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset_service.dart';

/// How a list of attachments is laid out.
enum AttachmentLayout {
  /// Images get a full-width preview big enough to read without opening
  /// anything; documents stay compact rows. The default for detail screens.
  preview,

  /// Everything is a compact row with a small thumbnail — for cards and dense
  /// lists where vertical space is scarce.
  compact,
}

/// Shows the attachments for a list of asset codes.
///
/// The one widget any screen needs: hand it asset codes and it resolves them in a
/// single request, renders images large, documents as rows, and opens a
/// full-screen zoomable viewer on tap. Task detail and event detail pass exactly
/// the same thing.
class AttachmentSection extends StatefulWidget {
  /// Resolves [assetCodes] through [AttachmentAssetService] — for callers that
  /// only have codes, which is how tasks arrive.
  const AttachmentSection({
    required this.assetCodes,
    this.layout = AttachmentLayout.preview,
    this.onRemove,
    this.previewHeight = 200,
    this.service,
    super.key,
  }) : resolved = null;

  /// Renders attachments the caller already has, with no network call at all.
  ///
  /// Events take this path: their occurrence payload returns `attachments[]`
  /// with `deliveryUrl` and `thumbnailUrl` inline, so there is nothing to
  /// resolve. Same rendering, same viewer — only the source differs.
  const AttachmentSection.resolved({
    required List<AttachmentAsset> attachments,
    this.layout = AttachmentLayout.preview,
    this.onRemove,
    this.previewHeight = 200,
    super.key,
  })  : resolved = attachments,
        assetCodes = const <String>[],
        service = null;

  final List<String> assetCodes;

  /// Non-null when the caller supplied resolved attachments.
  final List<AttachmentAsset>? resolved;
  final AttachmentLayout layout;

  /// Shows a remove control per attachment when provided.
  final void Function(String assetCode)? onRemove;

  /// Height of an image preview in [AttachmentLayout.preview].
  final double previewHeight;

  /// Injectable for tests; defaults to the registered singleton.
  final AttachmentAssetService? service;

  @override
  State<AttachmentSection> createState() => _AttachmentSectionState();
}

class _AttachmentSectionState extends State<AttachmentSection> {
  late Future<List<AttachmentAsset>> _future;

  AttachmentAssetService get _service =>
      widget.service ?? serviceLocator<AttachmentAssetService>();

  @override
  void initState() {
    super.initState();
    _future = _resolve();
  }

  @override
  void didUpdateWidget(AttachmentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compared by content, not identity: a parent rebuild often hands over an
    // equal-but-new list, and identity comparison would re-resolve every frame.
    String key(AttachmentSection w) => [
          ...w.assetCodes,
          ...?w.resolved?.map((a) => a.assetCode),
        ].join(',');

    if (key(oldWidget) != key(widget)) {
      // Block body, not an arrow: `_future = _resolve()` evaluates to the Future
      // itself, so an arrow closure would return it and setState asserts that a
      // callback must not return a Future.
      setState(() {
        _future = _resolve();
      });
    }
  }

  /// One request for the whole list — not one per row, which is what the resolve
  /// endpoint's array parameter exists to avoid.
  Future<List<AttachmentAsset>> _resolve({bool forceRefresh = false}) {
    final supplied = widget.resolved;
    if (supplied != null) return Future.value(supplied);
    return _service.resolveAll(widget.assetCodes, forceRefresh: forceRefresh);
  }

  void _retry() {
    setState(() {
      _future = _resolve(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assetCodes.isEmpty && (widget.resolved?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    // A FutureBuilder rather than hand-rolled loading flags: there is no way for
    // it to get stuck in a loading state that never clears.
    return FutureBuilder<List<AttachmentAsset>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _placeholders();
        }
        if (snapshot.hasError) {
          debugPrint('AttachmentSection: resolve failed — ${snapshot.error}');
          return _Shell(
            borderColor: AppColors.errorColor.withValues(alpha: 0.35),
            child: _UnavailableRow(
              label: "Couldn't load attachments",
              onRetry: _retry,
            ),
          );
        }

        final assets = snapshot.data ?? const <AttachmentAsset>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < assets.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _entry(context, assets, i),
            ],
          ],
        );
      },
    );
  }

  Widget _placeholders() {
    final height =
        widget.layout == AttachmentLayout.preview ? widget.previewHeight : 64.0;
    final count = widget.resolved?.length ?? widget.assetCodes.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _Shell(
            child:
                SizedBox(height: height, child: const AttachmentLoadingTile()),
          ),
        ],
      ],
    );
  }

  Widget _entry(
    BuildContext context,
    List<AttachmentAsset> assets,
    int index,
  ) {
    final asset = assets[index];

    if (asset.unavailableLabel.isNotEmpty) {
      return _Shell(
        borderColor: AppColors.errorColor.withValues(alpha: 0.35),
        child: _UnavailableRow(
          label: asset.unavailableLabel,
          fileName: asset.fileName,
          onRetry: _retry,
        ),
      );
    }

    void open() => openAttachmentViewer(
          context,
          assets: assets,
          initialIndex: index,
        );

    final onRemove = widget.onRemove;
    final remove = onRemove == null ? null : () => onRemove(asset.assetCode);

    if (widget.layout == AttachmentLayout.preview && asset.isImage) {
      return _PreviewCard(
        asset: asset,
        height: widget.previewHeight,
        onTap: open,
        onRemove: remove,
      );
    }
    return _Row(asset: asset, onTap: open, onRemove: remove);
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

/// Full-width image preview — legible without opening anything, tappable for the
/// zoomable viewer.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.asset,
    required this.height,
    required this.onTap,
    this.onRemove,
  });

  final AttachmentAsset asset;
  final double height;
  final VoidCallback onTap;
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
                // Full artifact, not the 256px thumbnail: at this size the
                // thumbnail would visibly soften.
                AttachmentImage(asset: asset, fullSize: true),
                const Positioned(
                  right: 8,
                  bottom: 8,
                  child: _Pill(icon: Icons.zoom_out_map_rounded, label: 'View'),
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
  const _Row({required this.asset, required this.onTap, this.onRemove});

  final AttachmentAsset asset;
  final VoidCallback onTap;
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
                child: AttachmentImage(asset: asset),
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

/// The state that used to be an endless spinner: says what is wrong, offers a way
/// out.
class _UnavailableRow extends StatelessWidget {
  const _UnavailableRow({
    required this.label,
    required this.onRetry,
    this.fileName = '',
  });

  final String label;
  final String fileName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(
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
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorColor,
                  ),
                ),
                if (fileName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
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
