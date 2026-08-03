import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/app/theme/colors.dart';
import '../../../../../../domain/features/communication/entities/message.dart';
import '../../../shared/utils/attachment_open_helper.dart';
import '../../../shared/utils/attachment_url_resolver.dart';
import 'show_full_screen_media_view.dart';

class FullAttachmentViewer extends StatelessWidget {
  final List<ChatAttachment> attachments;

  const FullAttachmentViewer({super.key, required this.attachments});

  List<ChatAttachment> get _images =>
      attachments.where((a) => a.isImage).toList();

  List<ChatAttachment> get _documents =>
      attachments.where((a) => !a.isImage).toList();

  Widget _buildImageGrid(BuildContext context) {
    final images = _images;
    if (images.isEmpty) return const SizedBox.shrink();

    // Instagram-style layouts based on image count
    if (images.length == 1) {
      return _buildSingleImageLayout(context, images[0]);
    } else if (images.length == 2) {
      return _buildTwoImageLayout(context, images);
    } else if (images.length == 3) {
      return _buildThreeImageLayout(context, images);
    } else {
      return _buildGridLayout(context, images);
    }
  }

  Widget _buildSingleImageLayout(BuildContext context, ChatAttachment att) {
    return GestureDetector(
      onTap: () => _openFullScreen(context, att),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImageWithPlaceholder(att),
        ),
      ),
    );
  }

  Widget _buildTwoImageLayout(
      BuildContext context, List<ChatAttachment> images) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(
          2,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 0 ? 4 : 0),
              child: GestureDetector(
                onTap: () => _openFullScreen(context, images[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildImageWithPlaceholder(images[index]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThreeImageLayout(
      BuildContext context, List<ChatAttachment> images) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _openFullScreen(context, images[0]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2,
                child: _buildImageWithPlaceholder(images[0]),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              2,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 0 ? 4 : 0),
                  child: GestureDetector(
                    onTap: () => _openFullScreen(context, images[index + 1]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _buildImageWithPlaceholder(images[index + 1]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context, List<ChatAttachment> images) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openFullScreen(context, images[index]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageWithPlaceholder(images[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageWithPlaceholder(ChatAttachment att) {
    return AttachmentUrlResolver(
      attachment: att,
      builder: (context, resolvedUrl, isLoading, isProcessing) {
        final resolved = (resolvedUrl != null && resolvedUrl.isNotEmpty)
            ? att.copyWith(remoteUrl: resolvedUrl)
            : att;
        final source = resolved.displaySource;
        if (source == null) {
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: isLoading
                  ? const PrimaryCircularLoader(size: 28, strokeWidth: 2.5)
                  : isProcessing
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PrimaryCircularLoader(
                          size: 28,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Processing…',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
            ),
          );
        }

        return resolved.remoteUrl.isNotEmpty
            ? _buildNetworkImageWithLQIP(resolved.remoteUrl)
            : Image.file(
                File(source),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
      },
    );
  }

  Widget _buildNetworkImageWithLQIP(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCards(BuildContext context) {
    final documents = _documents;
    if (documents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: CustomTextWidget(
            text: 'Documents (${documents.length})',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontColor: AppColors.primaryColor,
          ),
        ),
        ...documents.map((doc) => _buildDocumentCard(context, doc)),
      ],
    );
  }

  Widget _buildDocumentCard(
      BuildContext context, ChatAttachment document) {
    final iconData = Thumbnailer.getIconDataForMimeType(document.mimeType) ??
        FontAwesomeIcons.file;
    final isPdf = document.mimeType.contains('pdf') ||
        document.name.toLowerCase().endsWith('.pdf');
    final iconColor = isPdf
        ? Colors.red
        : iconData == FontAwesomeIcons.fileExcel
            ? Colors.green.shade700
            : iconData == FontAwesomeIcons.filePowerpoint
                ? Colors.orange.shade800
                : iconData == FontAwesomeIcons.fileWord
                    ? Colors.blue.shade700
                    : AppColors.primaryColor;
    final fileSize =
        (document.sizeBytes / 1024 / 1024).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => AttachmentOpenHelper.open(context, document),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: FaIcon(
                      iconData,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextWidget(
                        text: document.name,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      CustomTextWidget(
                        text: '$fileSize MB • ${document.type.toUpperCase()}',
                        fontSize: 12,
                        fontColor: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => AttachmentOpenHelper.open(context, document),
                  icon: const Icon(
                    Icons.download_outlined,
                    size: 20,
                  ),
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openFullScreen(BuildContext context, ChatAttachment att) async {
    final resolvedUrl = await resolveAttachmentUrl(att);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowFullScreenMediaView(
          imageUrl: (resolvedUrl != null && resolvedUrl.isNotEmpty)
              ? resolvedUrl
              : (att.remoteUrl.isNotEmpty ? att.remoteUrl : null),
          imageFile: att.localPath != null ? File(att.localPath!) : null,
          title: att.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = _images.isNotEmpty;
    final hasDocuments = _documents.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const CustomTextWidget(text: 'Attachments'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImages) _buildImageGrid(context),
            if (hasImages && hasDocuments)
              Divider(color: Colors.grey[300], height: 1),
            if (hasDocuments) _buildDocumentCards(context),
            if (!hasImages && !hasDocuments)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      CustomTextWidget(
                        text: 'No attachments',
                        fontSize: 16,
                        fontColor: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
