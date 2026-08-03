import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/shared/services/attachment_upload/attachment_upload_models.dart';

/// Horizontally scrolling attachment picker for forms.
///
/// Shows an "Add" tile followed by one card per selected file, each with an
/// always-visible remove control. Picking is handled internally through
/// [FilePickerUtils] — the parent only holds the list and reacts to
/// [onChanged], which keeps the same widget usable from the event form, the
/// task form and anywhere else attachments are collected.
///
/// This is the *pre-upload* surface: it deals in [PickedFile]s that live on the
/// device. Uploading them and exchanging them for asset codes belongs to the
/// upload layer, on save.
class AttachmentPickerField extends StatelessWidget {
  const AttachmentPickerField({
    required this.files,
    required this.onChanged,
    this.kind = FilePickerKind.imageAndDocument,
    this.maxFiles = FilePickerUtils.defaultMaxFiles,
    this.maxSizeBytes = FilePickerUtils.defaultMaxFileSizeBytes,
    this.enabled = true,
    this.helperText,
    this.uploadState,
    super.key,
  });

  /// Files currently on the form, in display order.
  final List<PickedFile> files;

  /// Called with the complete new list whenever files are added or removed.
  final ValueChanged<List<PickedFile>> onChanged;

  final FilePickerKind kind;

  /// Hard cap on attachments. Pass the upload session's `maxAssetCount` when
  /// one is available rather than relying on the default.
  final int maxFiles;
  final int maxSizeBytes;

  /// When false the field renders read-only: no add tile, no remove controls.
  final bool enabled;

  /// Overrides the auto-generated "types · size limit" hint.
  final String? helperText;

  /// Live upload progress, when a save is in flight. Cards matching a file in
  /// this state show its progress, processing spinner or failure instead of the
  /// plain thumbnail. Null outside of a save.
  final AttachmentUploadState? uploadState;

  static const double _cardSize = 96;
  static const double _radius = 12;

  bool get _isFull => files.length >= maxFiles;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (files.isEmpty)
            _EmptyState(
              enabled: enabled,
              helperText: helperText ?? _defaultHelperText(),
              onTap: () => _pick(context),
            )
          else ...[
            _header(context),
            const SizedBox(height: 8),
            SizedBox(
              height: _cardSize + 20,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: EdgeInsets.zero,
                // The add tile leads so its position never shifts as files
                // come and go — the target stays where the thumb learned it.
                itemCount: files.length + (enabled ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (enabled && index == 0) {
                    return _AddTile(
                      size: _cardSize,
                      radius: _radius,
                      isFull: _isFull,
                      maxFiles: maxFiles,
                      onTap: () => _pick(context),
                    );
                  }
                  final file = files[enabled ? index - 1 : index];
                  return _AttachmentCard(
                    file: file,
                    size: _cardSize,
                    radius: _radius,
                    enabled: enabled,
                    upload: _uploadFor(file),
                    onRemove: () => _remove(file),
                    onTap: () => _preview(context, file),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Upload state for [file], matched on path, or null when no save is running.
  AttachmentUploadItem? _uploadFor(PickedFile file) {
    final items = uploadState?.items;
    if (items == null) return null;
    for (final item in items) {
      if (item.file.path == file.path) return item;
    }
    return null;
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${files.length} of $maxFiles attached',
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
        ),
        if (enabled && files.isNotEmpty)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(const []),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Clear all',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.themeColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _defaultHelperText() {
    final extensions = FilePickerUtils.extensionsFor(kind);
    final limit = FilePickerUtils.formatBytes(maxSizeBytes);
    if (extensions.isEmpty) return 'Up to $maxFiles files · $limit each';
    // Long allow-lists (a dozen image variants) are noise in a hint; name the
    // headline formats and let the picker enforce the rest.
    final headline = extensions.take(4).map((e) => e.toUpperCase()).join(', ');
    return '$headline${extensions.length > 4 ? ' and more' : ''} · $limit each';
  }

  Future<void> _pick(BuildContext context) async {
    final result = await FilePickerUtils.pickMultipleFiles(
      kind: kind,
      maxFiles: maxFiles,
      maxSizeBytes: maxSizeBytes,
      existing: files,
      context: context,
    );
    if (result.files.isEmpty) return;
    onChanged([...files, ...result.files]);
  }

  void _remove(PickedFile file) {
    onChanged(files.where((f) => f != file).toList());
  }

  Future<void> _preview(BuildContext context, PickedFile file) async {
    if (file.isImage) {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => _ImagePreviewDialog(file: file),
      );
      return;
    }
    // Anything else is handed to whatever app on the device owns the type.
    await OpenFile.open(file.path);
  }
}

/// Full-width tile shown before anything has been attached.
///
/// Wider and more explicit than the compact add tile so the affordance — and
/// the type/size limits — are obvious on first look.
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.enabled,
    required this.helperText,
    required this.onTap,
  });

  final bool enabled;
  final String helperText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Text(
        'No attachments',
        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.themeColor.withValues(alpha: 0.45),
          radius: 10,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.themeColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  size: 18,
                  color: AppColors.themeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add attachments',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.themeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      helperText,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact dashed square that opens the picker, sitting first in the strip.
class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.size,
    required this.radius,
    required this.isFull,
    required this.maxFiles,
    required this.onTap,
  });

  final double size;
  final double radius;
  final bool isFull;
  final int maxFiles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Still tappable when full: the picker owns the "up to N files" message, so
    // a tap explains the limit instead of doing nothing.
    final color = isFull ? Colors.grey.shade400 : AppColors.themeColor;
    return Semantics(
      button: true,
      // Its own node, with the inner "Add"/"Max N" text excluded: the label
      // already says it, and two nodes would read the control out twice.
      container: true,
      excludeSemantics: true,
      label: isFull ? 'Attachment limit reached' : 'Add attachment',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomPaint(
                painter: _DashedBorderPainter(
                  color: color.withValues(alpha: isFull ? 0.5 : 0.55),
                  radius: radius,
                ),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, size: 24, color: color),
                      const SizedBox(height: 2),
                      Text(
                        isFull ? 'Max $maxFiles' : 'Add',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One selected file: thumbnail or type glyph, name over a scrim, remove chip.
class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.file,
    required this.size,
    required this.radius,
    required this.enabled,
    required this.upload,
    required this.onRemove,
    required this.onTap,
  });

  final PickedFile file;
  final double size;
  final double radius;
  final bool enabled;

  /// Non-null while a save is uploading this file.
  final AttachmentUploadItem? upload;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final failed = upload?.isFailed ?? false;
    return SizedBox(
      width: size,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: failed
                          ? AppColors.errorColor
                          : Colors.grey.shade300,
                      width: failed ? 1.4 : 1,
                    ),
                    color: Colors.white,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Thumbnail(file: file),
                      // Keeps the name legible over a busy photo.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(5, 10, 5, 4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                          child: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (upload != null) _UploadOverlay(item: upload!),
                    ],
                  ),
                ),
                if (enabled)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Semantics(
                      button: true,
                      label: 'Remove ${file.name}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onRemove,
                        // Transparent padding lifts the tap target to ~34px
                        // without growing the visible chip.
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: _RemoveChip(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            // The failure reason earns the line while it matters; the size is
            // only useful before the upload starts.
            failed ? (upload?.error ?? 'Upload failed') : file.readableSize,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: failed ? AppColors.errorColor : Colors.grey[600],
              fontWeight: failed ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Covers a card while its file is uploading, processing or after it failed.
///
/// `processing` gets its own indeterminate spinner rather than a stalled
/// progress bar: the bytes are sent and the wait is the service finalizing the
/// asset, which no progress number can describe honestly.
class _UploadOverlay extends StatelessWidget {
  const _UploadOverlay({required this.item});

  final AttachmentUploadItem item;

  @override
  Widget build(BuildContext context) {
    switch (item.status) {
      case AttachmentUploadStatus.pending:
        return _scrim(
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, value: 0),
          ),
        );
      case AttachmentUploadStatus.uploading:
        return _scrim(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  value: item.progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${(item.progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      case AttachmentUploadStatus.processing:
        return _scrim(
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Processing',
                style: TextStyle(fontSize: 9.5, color: Colors.white),
              ),
            ],
          ),
        );
      case AttachmentUploadStatus.done:
        return Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.successColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 11, color: Colors.white),
          ),
        );
      case AttachmentUploadStatus.failed:
        return _scrim(
          const Icon(
            Icons.error_outline_rounded,
            size: 26,
            color: Colors.white,
          ),
          color: AppColors.errorColor.withValues(alpha: 0.55),
        );
    }
  }

  Widget _scrim(Widget child, {Color? color}) {
    return Container(
      color: color ?? Colors.black.withValues(alpha: 0.5),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _RemoveChip extends StatelessWidget {
  const _RemoveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
    );
  }
}

/// Image preview for pictures, a colour-coded glyph for everything else.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.file});

  final PickedFile file;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(file);
    final fallback = Container(
      color: accent.withValues(alpha: 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_iconFor(file), size: 26, color: accent),
          if (file.extension.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              file.extension.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ],
      ),
    );

    if (!file.isImage) return fallback;
    return Image.file(
      file.file,
      fit: BoxFit.cover,
      // HEIC/AVIF are pickable but not always decodable by Flutter — fall back
      // to the glyph rather than showing a broken box.
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  static IconData _iconFor(PickedFile file) {
    if (file.isVideo) return Icons.videocam_rounded;
    if (file.isPdf) return Icons.picture_as_pdf_rounded;
    switch (file.extension) {
      case 'doc':
      case 'docx':
        return Icons.article_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  static Color _accentFor(PickedFile file) {
    if (file.isVideo) return const Color(0xFF7B5AC8);
    if (file.isPdf) return const Color(0xFFD3453F);
    switch (file.extension) {
      case 'doc':
      case 'docx':
        return const Color(0xFF2B6CB0);
      case 'xls':
      case 'xlsx':
        return const Color(0xFF2F855A);
      default:
        return AppColors.themeColor;
    }
  }
}

/// Tap-to-zoom preview for image attachments.
class _ImagePreviewDialog extends StatelessWidget {
  const _ImagePreviewDialog({required this.file});

  final PickedFile file;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                maxScale: 4,
                child: Image.file(
                  file.file,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: const Text('Preview not available'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${file.name} · ${file.readableSize}',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 10),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed rounded-rectangle outline, used to mark the add targets as drop-in
/// slots rather than filled controls.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 4.5;
  static const double _gap = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
