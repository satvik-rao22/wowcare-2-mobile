import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_attachment_utils.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Square preview for one attachment: the image itself for pictures, a play
/// badge over the poster for video, and a tinted doctype glyph for everything
/// else.
///
/// Image URLs are resolved lazily by asset code. The resolution is seeded from
/// [ImageUploadService]'s synchronous cache so an already-known asset paints on
/// the first frame — important on a scrolling list, where a loading flicker per
/// recycled card would be very visible.
class TaskAttachmentThumbnail extends StatefulWidget {
  const TaskAttachmentThumbnail({
    required this.attachment,
    required this.uploadService,
    this.size = 56,
    this.borderRadius = 10,
    super.key,
  });

  final TaskAttachment attachment;
  final ImageUploadService uploadService;
  final double size;
  final double borderRadius;

  @override
  State<TaskAttachmentThumbnail> createState() =>
      _TaskAttachmentThumbnailState();
}

class _TaskAttachmentThumbnailState extends State<TaskAttachmentThumbnail> {
  String? _url;
  Future<String>? _pending;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant TaskAttachmentThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.assetCode != widget.attachment.assetCode ||
        oldWidget.attachment.url != widget.attachment.url) {
      _url = null;
      _pending = null;
      _resolve();
    }
  }

  void _resolve() {
    final attachment = widget.attachment;
    // Only images need a URL up front — video and documents render from their
    // own glyph and resolve the URL only when tapped.
    if (!attachment.isImage || !attachment.isReady) return;

    final direct = attachment.thumbnailUrl.trim().isNotEmpty
        ? attachment.thumbnailUrl.trim()
        : attachment.url.trim();
    if (direct.isNotEmpty) {
      _url = direct;
      return;
    }

    final cached =
        widget.uploadService.cachedMediaAssetUrl(attachment.assetCode);
    if (cached != null && cached.isNotEmpty) {
      _url = cached;
      return;
    }

    _pending = TaskAttachmentUtils.resolveUrl(attachment, widget.uploadService)
      ..then((value) {
        if (!mounted || value.isEmpty) return;
        setState(() => _url = value);
      }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: _content(),
      ),
    );
  }

  Widget _content() {
    final attachment = widget.attachment;
    if (attachment.isImage) {
      final url = _url;
      if (url == null) {
        return _placeholder(showSpinner: _pending != null);
      }
      return Image.network(
        url,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _placeholder(showSpinner: true),
        errorBuilder: (_, __, ___) => _docGlyph(),
      );
    }
    if (attachment.isVideo) return _videoGlyph();
    return _docGlyph();
  }

  Widget _placeholder({required bool showSpinner}) {
    return Container(
      color: const Color(0xFFF1F2F6),
      alignment: Alignment.center,
      child: showSpinner
          ? SizedBox(
              width: widget.size * 0.3,
              height: widget.size * 0.3,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.image_outlined,
              size: widget.size * 0.42,
              color: const Color(0xFF9AA1AE),
            ),
    );
  }

  Widget _videoGlyph() {
    return Container(
      color: const Color(0xFF1F2430),
      alignment: Alignment.center,
      child: Icon(
        Icons.play_circle_fill_rounded,
        size: widget.size * 0.48,
        color: Colors.white.withValues(alpha: 0.92),
      ),
    );
  }

  Widget _docGlyph() {
    final attachment = widget.attachment;
    final style = TaskAttachmentUtils.docTypeStyle(
      attachment.fileName,
      attachment.contentType,
    );
    return _DocTypeTile(
      icon: style.icon,
      color: style.color,
      label: TaskAttachmentUtils.extensionLabel(attachment.fileName),
      size: widget.size,
    );
  }
}

/// The same square preview for a locally picked file that hasn't been uploaded
/// yet — reads straight off disk, so there is nothing to resolve.
class PendingAttachmentThumbnail extends StatelessWidget {
  const PendingAttachmentThumbnail({
    required this.attachment,
    this.size = 56,
    this.borderRadius = 10,
    super.key,
  });

  final PendingTaskAttachment attachment;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final style = TaskAttachmentUtils.docTypeStyle(
      attachment.fileName,
      attachment.contentType,
    );
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: attachment.isImage
            ? Image.file(
                File(attachment.filePath),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _DocTypeTile(
                  icon: style.icon,
                  color: style.color,
                  label: TaskAttachmentUtils.extensionLabel(
                    attachment.fileName,
                  ),
                  size: size,
                ),
              )
            : _DocTypeTile(
                icon: style.icon,
                color: style.color,
                label: TaskAttachmentUtils.extensionLabel(attachment.fileName),
                size: size,
              ),
      ),
    );
  }
}

/// Tinted glyph + extension caption used wherever a file has no visual preview.
class _DocTypeTile extends StatelessWidget {
  const _DocTypeTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Below this there is no room for both a glyph and a caption, so the
    // glyph alone carries the meaning.
    final showLabel = size >= 40;
    // Floored so the caption stays legible on the small card-strip tiles
    // rather than shrinking with the box.
    final labelSize = (size * 0.16).clamp(9.0, 13.0);
    return Container(
      color: color.withValues(alpha: 0.10),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: size * (showLabel ? 0.38 : 0.5), color: color),
          if (showLabel) ...[
            SizedBox(height: size * 0.04),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
