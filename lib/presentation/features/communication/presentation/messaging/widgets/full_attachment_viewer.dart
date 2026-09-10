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
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/attachment_open_helper.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/attachment_url_resolver.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/communication/model/communication_route_args.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

/// Resolves [att] and opens the full-screen media viewer route. Top-level so
/// the extracted layout widgets can call it directly (Mandate 6 — the layout
/// `_buildXxx` methods became `StatelessWidget`s).
Future<void> _openFullScreen(BuildContext context, ChatAttachment att) async {
  final resolvedUrl = await resolveAttachmentUrl(att);
  if (!context.mounted) return;
  context.push(
    CommunicationRoutes.mediaViewer,
    extra: MediaViewerArgs(
      imageUrl: (resolvedUrl != null && resolvedUrl.isNotEmpty)
          ? resolvedUrl
          : (att.remoteUrl.isNotEmpty ? att.remoteUrl : null),
      imageFile: att.localPath != null ? File(att.localPath!) : null,
      title: att.name,
    ),
  );
}

class FullAttachmentViewer extends StatelessWidget {
  final List<ChatAttachment> attachments;

  const FullAttachmentViewer({super.key, required this.attachments});

  List<ChatAttachment> get _images =>
      attachments.where((a) => a.isImage).toList();

  List<ChatAttachment> get _documents =>
      attachments.where((a) => !a.isImage).toList();

  @override
  Widget build(BuildContext context) {
    final images = _images;
    final documents = _documents;
    final hasImages = images.isNotEmpty;
    final hasDocuments = documents.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const CustomTextWidget(text: AppStrings.attachments),
        elevation: 0,
        backgroundColor: AppColors.cardColor,
        foregroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImages) _ImageGrid(images: images),
            if (hasImages && hasDocuments)
              const Divider(color: AppColors.messagingBorderColor, height: 1),
            if (hasDocuments) _DocumentCards(documents: documents),
            if (!hasImages && !hasDocuments) const _EmptyAttachments(),
          ],
        ),
      ),
    );
  }
}

/// Instagram-style image layout, chosen by image count.
class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.images});

  final List<ChatAttachment> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    if (images.length == 1) return _SingleImageLayout(image: images[0]);
    if (images.length == 2) return _TwoImageLayout(images: images);
    if (images.length == 3) return _ThreeImageLayout(images: images);
    return _GridLayout(images: images);
  }
}

class _SingleImageLayout extends StatelessWidget {
  const _SingleImageLayout({required this.image});

  final ChatAttachment image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context, image),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _ImageWithPlaceholder(attachment: image),
        ),
      ),
    );
  }
}

class _TwoImageLayout extends StatelessWidget {
  const _TwoImageLayout({required this.images});

  final List<ChatAttachment> images;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: List.generate(
          2,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 0 ? AppSizes.xxs : 0),
              child: GestureDetector(
                onTap: () => _openFullScreen(context, images[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _ImageWithPlaceholder(attachment: images[index]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreeImageLayout extends StatelessWidget {
  const _ThreeImageLayout({required this.images});

  final List<ChatAttachment> images;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _openFullScreen(context, images[0]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2,
                child: _ImageWithPlaceholder(attachment: images[0]),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xxs),
          Row(
            children: List.generate(
              2,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 0 ? AppSizes.xxs : 0),
                  child: GestureDetector(
                    onTap: () => _openFullScreen(context, images[index + 1]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _ImageWithPlaceholder(
                          attachment: images[index + 1],
                        ),
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
}

class _GridLayout extends StatelessWidget {
  const _GridLayout({required this.images});

  final List<ChatAttachment> images;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.md),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSizes.xxs,
          mainAxisSpacing: AppSizes.xxs,
          childAspectRatio: 1,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openFullScreen(context, images[index]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _ImageWithPlaceholder(attachment: images[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ImageWithPlaceholder extends StatelessWidget {
  const _ImageWithPlaceholder({required this.attachment});

  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return AttachmentUrlResolver(
      attachment: attachment,
      builder: (context, resolvedUrl, isLoading, isProcessing) {
        final resolved = (resolvedUrl != null && resolvedUrl.isNotEmpty)
            ? attachment.copyWith(remoteUrl: resolvedUrl)
            : attachment;
        final source = resolved.displaySource;
        if (source == null) {
          return Container(
            color: AppColors.messagingSurfaceMuted,
            child: Center(
              child: isLoading
                  ? const PrimaryCircularLoader(size: 28, strokeWidth: 2.5)
                  : isProcessing
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PrimaryCircularLoader(size: 28, strokeWidth: 2.5),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          AppStrings.processing,
                          style: TextStyle(
                            color: AppColors.messagingChipTextUnselected,
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.image_not_supported_outlined,
                      size: 48,
                      color: AppColors.messagingIconMuted,
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
}

class _DocumentCards extends StatelessWidget {
  const _DocumentCards({required this.documents});

  final List<ChatAttachment> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.md,
            AppSizes.lg,
            AppSizes.md,
            AppSizes.sm,
          ),
          child: CustomTextWidget(
            text: AppStrings.documentsCount(documents.length),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontColor: AppColors.primaryColor,
          ),
        ),
        ...documents.map((doc) => _DocumentCard(document: doc)),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final ChatAttachment document;

  @override
  Widget build(BuildContext context) {
    final iconData =
        Thumbnailer.getIconDataForMimeType(document.mimeType) ??
        FontAwesomeIcons.file;
    final isPdf =
        document.mimeType.contains('pdf') ||
        document.name.toLowerCase().endsWith('.pdf');
    final iconColor = isPdf
        ? AppColors.messagingFilePdf
        : iconData == FontAwesomeIcons.fileExcel
        ? AppColors.messagingFileExcel
        : iconData == FontAwesomeIcons.filePowerpoint
        ? AppColors.messagingFilePowerpoint
        : iconData == FontAwesomeIcons.fileWord
        ? AppColors.messagingFileWord
        : AppColors.primaryColor;
    final fileSize = (document.sizeBytes / 1024 / 1024).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => AttachmentOpenHelper.open(context, document),
        child: Container(
          decoration: AppSurfaces.card(radius: 12),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.sm),
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
                    child: FaIcon(iconData, color: iconColor, size: 24),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
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
                      const SizedBox(height: AppSizes.xxs),
                      CustomTextWidget(
                        text: '$fileSize MB • ${document.type.toUpperCase()}',
                        fontSize: 12,
                        fontColor: AppColors.messagingTextMeta,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                IconButton(
                  onPressed: () => AttachmentOpenHelper.open(context, document),
                  icon: const Icon(Icons.download_outlined, size: 20),
                  color: AppColors.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAttachments extends StatelessWidget {
  const _EmptyAttachments();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xxl),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.folder_open_outlined,
              size: 80,
              color: AppColors.messagingBorderColor,
            ),
            const SizedBox(height: AppSizes.md),
            CustomTextWidget(
              text: AppStrings.noAttachments,
              fontSize: 16,
              fontColor: AppColors.messagingTextMeta,
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
    color: AppColors.messagingSurfaceMuted,
    child: const Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: AppColors.messagingIconMuted,
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
            color: AppColors.messagingSurfaceMuted,
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
