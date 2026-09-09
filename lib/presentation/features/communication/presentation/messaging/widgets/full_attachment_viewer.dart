import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:thumbnailer/thumbnailer.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/core/theme/app_colors.dart';
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

        // `source` already reflects `displaySource`'s local-preferred
        // precedence — deciding the render path from `remoteUrl.isNotEmpty`
        // instead (as this used to) picks the network branch even when a
        // perfectly good local file is sitting right there (e.g. right
        // after sending, before the remote URL is reliably fetchable), and
        // a bare Image.network has no retry for transient CDN/auth hiccups.
        // Resolve from `source` itself and retry+validate remote fetches.
        return _ResilientImage(source: source, fit: BoxFit.cover);
      },
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

/// Renders a local file or remote URL (whichever `source` is) as an image,
/// retrying + decode-validating remote fetches so a transient CDN/auth
/// hiccup doesn't show as a permanently broken thumbnail.
class _ResilientImage extends StatefulWidget {
  const _ResilientImage({required this.source, required this.fit});

  final String source;
  final BoxFit fit;

  @override
  State<_ResilientImage> createState() => _ResilientImageState();
}

class _ResilientImageState extends State<_ResilientImage> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _resolveBytes(widget.source);
  }

  static bool _isRemote(String src) =>
      src.startsWith('http://') || src.startsWith('https://');

  static Future<Uint8List> _resolveBytes(String src) async {
    if (!_isRemote(src)) {
      try {
        return await File(src).readAsBytes();
      } catch (_) {
        return Uint8List(0);
      }
    }
    const attempts = 5;
    for (var i = 0; i < attempts; i++) {
      try {
        final r = await http.get(Uri.parse(src));
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
          try {
            final codec = await ui.instantiateImageCodec(r.bodyBytes);
            codec.dispose();
            return r.bodyBytes;
          } catch (_) {
            // Falls through to retry below.
          }
        }
      } catch (_) {}
      if (i < attempts - 1) {
        await Future.delayed(Duration(milliseconds: 600 * (i + 1)));
      }
    }
    return Uint8List(0);
  }

  Widget _broken() => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.grey,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: PrimaryCircularLoader(size: 28, strokeWidth: 2.5),
            ),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) return _broken();
        return Image.memory(
          bytes,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) => _broken(),
        );
      },
    );
  }
}
