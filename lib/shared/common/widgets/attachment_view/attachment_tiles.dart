import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';

/// Icon + tint for a file type, so a document reads as its kind at a glance.
({IconData icon, Color color}) attachmentGlyph(AttachmentAsset asset) {
  if (asset.isVideo) {
    return (icon: Icons.videocam_rounded, color: const Color(0xFF7B5AC8));
  }
  if (asset.isPdf) {
    return (icon: Icons.picture_as_pdf_rounded, color: const Color(0xFFD3453F));
  }
  switch (asset.extension) {
    case 'doc':
    case 'docx':
      return (icon: Icons.article_rounded, color: const Color(0xFF2B6CB0));
    case 'xls':
    case 'xlsx':
      return (icon: Icons.table_chart_rounded, color: const Color(0xFF2F855A));
    default:
      return (
        icon: asset.isImage
            ? Icons.image_outlined
            : Icons.insert_drive_file_rounded,
        color: AppColors.themeColor,
      );
  }
}

/// Tinted glyph for anything without a visual preview — PDFs, docs, sheets, and
/// images whose bytes could not be fetched.
class AttachmentGlyphTile extends StatelessWidget {
  const AttachmentGlyphTile({required this.asset, this.size, super.key});

  final AttachmentAsset asset;

  /// Null fills the parent — use inside a sized box.
  final double? size;

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
          if (asset.extension.isNotEmpty) ...[
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

/// An attachment's image, straight through [CachedNetworkImage].
///
/// Nothing clever here on purpose: the service has already turned the asset code
/// into a URL, and `cached_network_image` owns fetching, decoding and its own
/// memory + disk cache. Non-images fall back to a glyph.
class AttachmentImage extends StatelessWidget {
  const AttachmentImage({
    required this.asset,
    this.fit = BoxFit.cover,
    this.fullSize = false,
    super.key,
  });

  final AttachmentAsset asset;
  final BoxFit fit;

  /// Loads the full delivery artifact rather than the 256px thumbnail. Off for
  /// rows and tiles — the thumbnail is a few KB against ~25 KB for primary.
  final bool fullSize;

  @override
  Widget build(BuildContext context) {
    final url = fullSize ? asset.fullUrl : asset.previewUrl;
    if (!asset.isImage || url.isEmpty) {
      return AttachmentGlyphTile(asset: asset);
    }
    // print('<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<${url}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
    return Image.network(url,
    fit: fit,
      // loadingBuilder: (_, __,___) => const AttachmentLoadingTile(),
      errorBuilder: (_, __, error) {
            debugPrint('AttachmentImage: $url failed — $error');
            return AttachmentGlyphTile(asset: asset);
          },
    );
    // return CachedNetworkImage(
    //   imageUrl:url,
    //   fit: fit,
    //   fadeInDuration: const Duration(milliseconds: 120),
    //   // placeholder: (_, __) => const AttachmentLoadingTile(),
    //   // errorWidget: (_, __, error) {
    //   //   debugPrint('AttachmentImage: $url failed — $error');
    //   //   return AttachmentGlyphTile(asset: asset);
    //   // },
    // );
  }
}

/// Neutral placeholder while bytes are in flight.
class AttachmentLoadingTile extends StatelessWidget {
  const AttachmentLoadingTile({this.size, super.key});

  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey.shade100,
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
