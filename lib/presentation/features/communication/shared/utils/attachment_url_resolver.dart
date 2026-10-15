import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wowcare/app/di/messaging_resolvers.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';

/// Resolves a [ChatAttachment] to a URL it can actually be displayed/opened
/// from.
///
/// Attachments that still carry a local file ([ChatAttachment.localPath])
/// or an already-known [ChatAttachment.remoteUrl] (e.g. right after upload)
/// need no network call — [ChatAttachment.displaySource] already covers
/// them. Attachments loaded from conversation history only carry the
/// document-service asset [ChatAttachment.code]: the messaging service's
/// message-list response never includes a delivery URL for those
/// (`fileUrl`/`thumbnailUrl` come back null even once the asset is READY),
/// so the URL has to be resolved against the document service separately —
/// mirrors the web app's media-assets/resolve flow. [AssetService]
/// caches the result so repeat renders (list scrolling, rebuilds) don't
/// re-hit the network.
Future<String?> resolveAttachmentUrl(ChatAttachment attachment) async {
  final direct = attachment.displaySource;
  if (direct != null && direct.isNotEmpty) return direct;

  final assetCode = attachment.code?.trim() ?? '';
  if (assetCode.isEmpty) return null;

  final uploadService = resolveAssetService();
  final cached = uploadService.cachedMediaAssetUrl(assetCode);
  if (cached != null && cached.isNotEmpty) return cached;

  try {
    final url = await uploadService.getMediaAssetUrlByCode(
      assetCode: assetCode,
    );
    return url.isEmpty ? null : url;
  } catch (_) {
    return null;
  }
}

/// Widget form of [resolveAttachmentUrl] for eagerly rendering a thumbnail —
/// hands [builder] the resolved url (or null), whether resolution is still
/// in flight, and whether the backend reported the asset as still
/// processing (rather than a hard failure), so callers can show a distinct
/// "still processing" state instead of a premature "broken image"
/// placeholder.
class AttachmentUrlResolver extends StatefulWidget {
  const AttachmentUrlResolver({
    super.key,
    required this.attachment,
    required this.builder,
  });

  final ChatAttachment attachment;
  final Widget Function(
    BuildContext context,
    String? url,
    bool isLoading,
    bool isProcessing,
  )
  builder;

  @override
  State<AttachmentUrlResolver> createState() => _AttachmentUrlResolverState();
}

class _AttachmentUrlResolverState extends State<AttachmentUrlResolver> {
  // The in-flight resolution future (Mandate 2). A ValueNotifier rather than
  // `setState` so a processing-retry swaps the future the FutureBuilder watches
  // without rebuilding anything else.
  final ValueNotifier<Future<String?>> _future = ValueNotifier<Future<String?>>(
    Future<String?>.value(null),
  );
  Timer? _retryTimer;

  /// How long to wait before re-checking an asset that's still backend-side
  /// processing. Without this, once [AssetService]'s own 15s poll times
  /// out, the "Processing…" placeholder is stuck until some UNRELATED widget
  /// rebuild (scroll, a different message arriving, …) happens to re-create
  /// this State and re-trigger resolution — which may never happen while the
  /// user just sits on the thread. [AssetService.getMediaAssetUrlByCode]
  /// already has its own 30s failure cooldown, so retrying here on a shorter
  /// cadence is cheap: most retries just re-read that cache with no network
  /// call, until the cooldown passes and a fresh poll actually runs.
  static const Duration _processingRetryDelay = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _startResolving(widget.attachment);
  }

  @override
  void didUpdateWidget(covariant AttachmentUrlResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.attachment;
    final next = widget.attachment;
    if (old.code != next.code || old.displaySource != next.displaySource) {
      _startResolving(next);
    }
  }

  void _startResolving(ChatAttachment attachment) {
    _retryTimer?.cancel();
    final future = resolveAttachmentUrl(attachment);
    _future.value = future;
    future.then((url) {
      if (!mounted || (url != null && url.isNotEmpty)) return;
      // Still unresolved. Only keep retrying when the backend reported this
      // specific asset as still processing (not a hard failure) — a genuine
      // failure should fall through to the broken-image state, not retry
      // forever.
      final assetCode = attachment.code?.trim() ?? '';
      if (assetCode.isEmpty) return;
      if (!resolveAssetService().isAssetProcessing(assetCode)) {
        return;
      }
      _retryTimer = Timer(_processingRetryDelay, () {
        if (!mounted) return;
        _startResolving(attachment);
      });
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _future.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Future<String?>>(
      valueListenable: _future,
      builder: (context, future, _) => FutureBuilder<String?>(
        future: future,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final url = snapshot.data;
          final assetCode = widget.attachment.code?.trim() ?? '';
          final isProcessing =
              !isLoading &&
              (url == null || url.isEmpty) &&
              assetCode.isNotEmpty &&
              resolveAssetService().isAssetProcessing(assetCode);
          return widget.builder(context, url, isLoading, isProcessing);
        },
      ),
    );
  }
}
