
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/attachment_view/attachment_tiles.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';

/// Opens the full-screen attachment viewer at [initialIndex].
///
/// Takes asset codes rather than resolved assets so any screen holding a
/// `List<String>` can call it directly.
Future<void> openAttachmentViewer(
  BuildContext context, {
  required List<AttachmentAsset> assets,
  int initialIndex = 0,
}) {
  if (assets.isEmpty) return Future<void>.value();
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => AttachmentViewer(
        assets: assets,
        initialIndex: initialIndex.clamp(0, assets.length - 1),
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
  // The presigned original when available, else the processed artifact.
  final source =
      asset.downloadUrl.isNotEmpty ? asset.downloadUrl : asset.fullUrl;
  if (source.isEmpty) return;
  try {
    final dir = await getTemporaryDirectory();
    final safeName = asset.displayName.replaceAll(RegExp(r'[\\/]'), '_');
    final path = '${dir.path}/$safeName';
    // Bare Dio: the URL is presigned, so an auth header would break it.
    await Dio().download(source, path);
    final result = await OpenFile.open(path);
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
    required this.assets,
    this.initialIndex = 0,
    super.key,
  });

  /// Already resolved by the caller — the viewer does no fetching of its own.
  final List<AttachmentAsset> assets;
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
    final total = widget.assets.length;
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
          if (widget.assets[_index].isReady)
            IconButton(
              tooltip: 'Open outside the app',
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () =>
                  openAttachmentExternally(context, widget.assets[_index]),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: total,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => _Page(asset: widget.assets[i]),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.asset});

  final AttachmentAsset asset;

  @override
  Widget build(BuildContext context) {
    if (asset.unavailableLabel.isNotEmpty) {
      return _Unavailable(label: asset.unavailableLabel);
    }
    if (!asset.isImage) return _NonPreviewable(asset: asset);

    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            maxScale: 5,
            // Fitted to the screen first; zoom is for detail, not for making the
            // image legible in the first place.
            child: Center(
              child: Image.network(
                 asset.fullUrl,
                fit: BoxFit.contain,
                // placeholder: (_, __) => const Center(
                //   child: SizedBox(
                //     width: 26,
                //     height: 26,
                //     child: CircularProgressIndicator(strokeWidth: 2.4),
                //   ),
                // ),
                // errorWidget: (_, url, error) {
                //   debugPrint('AttachmentViewer: $url failed — $error');
                //   return const _Unavailable(label: "Couldn't load this image");
                // },
              ),
            ),
          ),
        ),
        _Caption(asset: asset),
      ],
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

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
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
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
