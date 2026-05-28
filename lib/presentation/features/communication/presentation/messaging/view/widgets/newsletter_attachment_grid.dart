import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Displays newsletter attachment placeholders from list payload.
/// Image URLs will be wired when the document/media API is integrated.
class NewsletterAttachmentGrid extends StatelessWidget {
  const NewsletterAttachmentGrid({
    super.key,
    required this.newsletterId,
    required this.attachments,
    this.isLoading = false,
    this.showFileName = true,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.35,
  });

  final int newsletterId;
  final List<NewsletterAttachment> attachments;
  final bool isLoading;
  final bool showFileName;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: 2,
        itemBuilder: (BuildContext context, int index) {
          return const ShimmerLoaderCard(
            margin: EdgeInsets.zero,
            child: SizedBox(width: 75, height: 75),
          );
        },
      );
    }

    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments',
          style: TextStyle(
            color: AppColors.primaryColor.withValues(alpha: 0.85),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: attachments.length,
          itemBuilder: (BuildContext context, int index) {
            final NewsletterAttachment attachment = attachments[index];
            return _AttachmentTile(
              attachment: attachment,
              showFileName: showFileName,
            );
          },
        ),
      ],
    );
  }
}

class _AttachmentTile extends StatefulWidget {
  const _AttachmentTile({
    required this.attachment,
    required this.showFileName,
  });

  final NewsletterAttachment attachment;
  final bool showFileName;

  @override
  State<_AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends State<_AttachmentTile> {
  late final Future<String> _assetUrlFuture;

  @override
  void initState() {
    super.initState();
    _assetUrlFuture = _resolveAssetUrl();
  }

  Future<String> _resolveAssetUrl() async {
    final String code = widget.attachment.mediaCode.trim();
    if (code.isEmpty) return '';
    try {
      final ImageUploadService uploadService = serviceLocator<ImageUploadService>();
      return await uploadService.getMediaAssetUrlByCode(assetCode: code);
    } catch (_) {
      return '';
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final Uri? uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    final bool opened = await launchUrl(uri, mode: LaunchMode.inAppWebView);
    if (!opened) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _openAttachment({
    required String url,
    required bool isImage,
  }) async {
    if (isImage) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _NewsletterImageViewer(imageUrl: url),
        ),
      );
      return;
    }
    await _openExternalUrl(url);
  }

  IconData _documentIconForMimeType(String mimeType) {
    final String mime = mimeType.toLowerCase();
    if (mime.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mime.contains('word') || mime.contains('document')) {
      return Icons.description_outlined;
    }
    if (mime.contains('sheet') || mime.contains('excel') || mime.contains('csv')) {
      return Icons.table_chart_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final NewsletterAttachment attachment = widget.attachment;
    final String label = attachment.fileName.trim().isNotEmpty
        ? attachment.fileName
        : attachment.mediaCode;

    return FutureBuilder<String>(
      future: _assetUrlFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final bool hasUrl = (snapshot.data ?? '').trim().isNotEmpty;
        final String url = (snapshot.data ?? '').trim();
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: hasUrl
              ? () => _openAttachment(
                    url: url,
                    isImage: attachment.isImage,
                  )
              : null,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(244, 247, 254, 1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPreview(
                      attachment: attachment,
                      isLoading: isLoading,
                      hasUrl: hasUrl,
                      url: url,
                    ),
                  ),
                ),
                if (widget.showFileName) ...[
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primaryColor.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreview({
    required NewsletterAttachment attachment,
    required bool isLoading,
    required bool hasUrl,
    required String url,
  }) {
    if (isLoading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (attachment.isImage && hasUrl) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Image.asset(
          MediaRes.deafultNewsletterImage,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    if (attachment.isImage) {
      return Image.asset(
        MediaRes.deafultNewsletterImage,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    return Center(
      child: Icon(
        _documentIconForMimeType(attachment.mimeType),
        size: 36,
        color: AppColors.primaryColor.withValues(alpha: 0.6),
      ),
    );
  }
}

class _NewsletterImageViewer extends StatelessWidget {
  const _NewsletterImageViewer({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.6,
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white70,
              size: 56,
            ),
          ),
        ),
      ),
    );
  }
}
