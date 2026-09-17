
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/attachment_view/attachment_asset_builder.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';

/// Opens the full-screen attachment viewer at [initialIndex].
///
/// Takes asset codes rather than resolved assets so any screen holding a
/// `List<String>` can call it directly.
Future<void> openAttachmentViewer(
  BuildContext context, {
  required List<String> assetCodes,
  int initialIndex = 0,
}) {
  if (assetCodes.isEmpty) return Future<void>.value();
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => AttachmentViewer(
        assetCodes: assetCodes,
        initialIndex: initialIndex.clamp(0, assetCodes.length - 1),
      ),
    ),
  );
}

/// Downloads [asset] and hands it to whichever app on the device owns the type.
///
/// A delivery URL can't be passed to another app directly, so the bytes land in
/// the cache directory under the original file name — the receiving app then
/// shows something recognisable.
Future<void> openAttachmentExternally(
  BuildContext context,
  AttachmentAsset asset,
) async {
  if (asset.url.isEmpty) return;
  try {
    final dir = await getTemporaryDirectory();
    final safeName = asset.displayName.replaceAll(RegExp(r'[\\/]'), '_');
    final path = '${dir.path}/$safeName';
    // Bare Dio: the URL is presigned, so an auth header would break it.
    await Dio().download(asset.url, path);
    final result = await OpenFilex.open(path);
    if (!context.mounted || result.type == ResultType.done) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: result.type == ResultType.noAppToOpen
          ? 'No app on this device can open ${asset.extension.toUpperCase()} files'
          : 'Could not open this file',
      isWarning: true,
    );
  } catch (_) {
    if (!context.mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Could not download this file',
      isError: true,
    );
  }
}

/// Full-screen, zoomable attachment viewer with swipe between attachments.
///
/// Exists because a 44px thumbnail is unreadable: an image opens fitted to the
/// screen (no pinching needed to see it), and pinch-zoom is there for detail.
/// Anything not previewable in-app offers an explicit "Open" that hands off to
/// the OS.
class AttachmentViewer extends StatefulWidget {
  const AttachmentViewer({
    required this.assetCodes,
    this.initialIndex = 0,
    super.key,
  });

  final List<String> assetCodes;
  final int initialIndex;

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.assetCodes.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          total == 1 ? 'Attachment' : '${_index + 1} of $total',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        actions: [
          AttachmentAssetBuilder(
            assetCode: widget.assetCodes[_index],
            builder: (context, snapshot) {
              final asset = snapshot.asset;
              if (asset == null || !asset.isReady) return const SizedBox();
              return IconButton(
                tooltip: 'Open outside the app',
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: () => openAttachmentExternally(context, asset),
              );
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: total,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => _Page(assetCode: widget.assetCodes[i]),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.assetCode});

  final String assetCode;

  @override
  Widget build(BuildContext context) {
    return AttachmentAssetBuilder(
      assetCode: assetCode,
      builder: (context, snapshot) {
        if (snapshot.isLoading) {
          return const Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          );
        }
        final asset = snapshot.asset;
        if (asset == null || asset.hasFailed) {
          return _Failure(
            asset: asset,
            onRetry: snapshot.retry,
          );
        }
        if (asset.isImage) {
          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  maxScale: 5,
                  // Fitted to the screen first; zoom is for detail, not for
                  // making the image legible in the first place.
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: asset.url,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                      errorWidget: (_, __, ___) => _Failure(
                        asset: asset,
                        onRetry: snapshot.retry,
                      ),
                    ),
                  ),
                ),
              ),
              _Caption(asset: asset),
            ],
          );
        }
        return _NonPreviewable(asset: asset);
      },
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.asset});

  final AttachmentAsset asset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        children: [
          Text(
            asset.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          if (asset.displaySubtitle.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              asset.displaySubtitle,
              style: TextStyle(color: Colors.grey[400], fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// PDFs, docs and spreadsheets — shown as an identity card with an explicit
/// hand-off, rather than a blank screen.
class _NonPreviewable extends StatelessWidget {
  const _NonPreviewable({required this.asset});

  final AttachmentAsset asset;

  @override
  Widget build(BuildContext context) {
    final glyph = attachmentGlyph(asset);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: glyph.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(glyph.icon, size: 44, color: glyph.color),
            ),
            const SizedBox(height: 18),
            Text(
              asset.displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (asset.displaySubtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                asset.displaySubtitle,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => openAttachmentExternally(context, asset),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Open'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.asset, required this.onRetry});

  final AttachmentAsset? asset;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final retryable = asset?.isRetryable ?? true;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.white70,
            ),
            const SizedBox(height: 14),
            Text(
              asset?.failureLabel ?? "Couldn't load this file",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            if (retryable) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
