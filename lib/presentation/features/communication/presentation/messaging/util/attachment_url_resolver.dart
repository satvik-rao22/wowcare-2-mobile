import 'package:flutter/widgets.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

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
/// mirrors the web app's media-assets/resolve flow. [ImageUploadService]
/// caches the result so repeat renders (list scrolling, rebuilds) don't
/// re-hit the network.
Future<String?> resolveAttachmentUrl(ChatAttachment attachment) async {
  final direct = attachment.displaySource;
  if (direct != null && direct.isNotEmpty) return direct;

  final assetCode = attachment.code?.trim() ?? '';
  if (assetCode.isEmpty) return null;

  final uploadService = serviceLocator<ImageUploadService>();
  final cached = uploadService.cachedMediaAssetUrl(assetCode);
  if (cached != null && cached.isNotEmpty) return cached;

  try {
    final url = await uploadService.getMediaAssetUrlByCode(assetCode: assetCode);
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
  late Future<String?> _future;

  @override
  void initState() {
    super.initState();
    _future = resolveAttachmentUrl(widget.attachment);
  }

  @override
  void didUpdateWidget(covariant AttachmentUrlResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.attachment;
    final next = widget.attachment;
    if (old.code != next.code || old.displaySource != next.displaySource) {
      _future = resolveAttachmentUrl(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final url = snapshot.data;
        final assetCode = widget.attachment.code?.trim() ?? '';
        final isProcessing =
            !isLoading &&
            (url == null || url.isEmpty) &&
            assetCode.isNotEmpty &&
            serviceLocator<ImageUploadService>().isAssetProcessing(assetCode);
        return widget.builder(context, url, isLoading, isProcessing);
      },
    );
  }
}
