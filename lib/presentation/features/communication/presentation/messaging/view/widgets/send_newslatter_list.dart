import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

class NewsletterListItemModel {
  const NewsletterListItemModel({
    required this.title,
    required this.classroom,
    required this.sentDate,
    required this.createdBy,
    required this.recipientCount,
    this.primaryAttachmentAssetCode,
    this.primaryAttachmentDirectUrl,
    this.primaryAttachmentMimeType,
    this.additionalAttachmentCount = 0,
  });

  final String title;
  final String classroom;
  final String sentDate;
  final String createdBy;
  final int recipientCount;
  final String? primaryAttachmentAssetCode;
  final String? primaryAttachmentDirectUrl;
  final String? primaryAttachmentMimeType;
  final int additionalAttachmentCount;

  bool get showClassroomRow => classroom.trim().isNotEmpty;
}

class NewsletterSentListCard extends StatelessWidget {
  const NewsletterSentListCard({
    super.key,
    required this.newsLetter,
    required this.onTap,
    this.showRecipientCount = true,
  });

  final NewsletterListItemModel newsLetter;
  final VoidCallback onTap;

  /// Whether to show the recipient-count badge. Hidden for the guardian/parent
  /// persona, who should not see how many recipients a newsletter was sent to.
  final bool showRecipientCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 84,
                  height: 56,
                  child: _CardThumbnail(
                    key: ValueKey<String>(
                      '${newsLetter.primaryAttachmentAssetCode ?? ''}|${newsLetter.primaryAttachmentDirectUrl ?? ''}',
                    ),
                    assetCode: newsLetter.primaryAttachmentAssetCode,
                    directUrl: newsLetter.primaryAttachmentDirectUrl,
                    mimeType: newsLetter.primaryAttachmentMimeType,
                    additionalAttachmentCount: newsLetter.additionalAttachmentCount,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      newsLetter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _AlignedMetaRow(
                      label: 'Created by',
                      value: newsLetter.createdBy,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _DateMetaRow(date: newsLetter.sentDate),
                        ),
                        if (showRecipientCount)
                          _RecipientCountBadge(
                            count: newsLetter.recipientCount,
                          ),
                      ],
                    ),
                    if (newsLetter.showClassroomRow) ...[
                      const SizedBox(height: 2),
                      _AlignedMetaRow(
                        label: 'Classroom',
                        value: newsLetter.classroom,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(left: 2, top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primaryColor.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateMetaRow extends StatelessWidget {
  const _DateMetaRow({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 74,
          child: Text(
            'Date',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.58),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          date,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: AppColors.primaryColor.withValues(alpha: 0.82),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RecipientCountBadge extends StatelessWidget {
  const _RecipientCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 18,
            color: AppColors.primaryColor.withValues(alpha: 0.62),
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.78),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlignedMetaRow extends StatelessWidget {
  const _AlignedMetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.58),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.82),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardThumbnail extends StatefulWidget {
  const _CardThumbnail({
    super.key,
    this.assetCode,
    this.directUrl,
    this.mimeType,
    this.additionalAttachmentCount = 0,
  });

  final String? assetCode;
  final String? directUrl;
  final String? mimeType;
  final int additionalAttachmentCount;

  @override
  State<_CardThumbnail> createState() => _CardThumbnailState();
}

class _CardThumbnailState extends State<_CardThumbnail> {
  late Future<String> _assetUrlFuture;
  String? _initialUrl;

  @override
  void initState() {
    super.initState();
    _initialUrl = _syncResolvedUrl();
    _assetUrlFuture = _resolveAssetUrl();
  }

  /// Returns a URL we can show immediately (a direct http URL, or one already
  /// resolved and cached by [ImageUploadService]) so the thumbnail does not
  /// flash a loader on rebuilds/scroll once it has been resolved before.
  String? _syncResolvedUrl() {
    final direct = (widget.directUrl ?? '').trim();
    if (_isHttpUrl(direct)) return direct;
    final code = (widget.assetCode ?? '').trim();
    if (code.isEmpty) return null;
    if (_isHttpUrl(code)) return code;
    return serviceLocator<ImageUploadService>().cachedMediaAssetUrl(code);
  }

  @override
  void didUpdateWidget(covariant _CardThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String oldCode = (oldWidget.assetCode ?? '').trim();
    final String newCode = (widget.assetCode ?? '').trim();
    final String oldUrl = (oldWidget.directUrl ?? '').trim();
    final String newUrl = (widget.directUrl ?? '').trim();
    if (oldCode != newCode ||
        oldUrl != newUrl ||
        oldWidget.mimeType != widget.mimeType) {
      _initialUrl = _syncResolvedUrl();
      _assetUrlFuture = _resolveAssetUrl();
    }
  }

  Future<String> _resolveAssetUrl() async {
    final String direct = (widget.directUrl ?? '').trim();
    if (_isHttpUrl(direct)) return direct;

    final String code = (widget.assetCode ?? '').trim();
    if (code.isEmpty) return '';
    if (_isHttpUrl(code)) return code;

    try {
      final ImageUploadService uploadService = serviceLocator<ImageUploadService>();
      return await uploadService.getMediaAssetUrlByCode(assetCode: code);
    } catch (_) {
      return '';
    }
  }

  bool _isHttpUrl(String value) {
    final lower = value.trim().toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  bool get _isImage {
    final String mime = (widget.mimeType ?? '').trim().toLowerCase();
    if (mime.startsWith('image/')) return true;
    if (mime.contains('pdf') ||
        mime.contains('word') ||
        mime.contains('document') ||
        mime.contains('sheet') ||
        mime.contains('excel')) {
      return false;
    }

    for (final source in <String>[
      widget.directUrl ?? '',
      widget.assetCode ?? '',
    ]) {
      final lower = source.toLowerCase();
      if (lower.endsWith('.png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.webp') ||
          lower.endsWith('.gif') ||
          lower.endsWith('.avif') ||
          lower.endsWith('.bmp')) {
        return true;
      }
    }

    final String code = (widget.assetCode ?? '').trim();
    if (code.isNotEmpty && mime.isEmpty) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _assetUrlFuture,
      initialData: _initialUrl,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final String url = (snapshot.data ?? '').trim();
        final bool hasUrl = url.isNotEmpty;
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
                !hasUrl;

        return Stack(
          children: [
            Positioned.fill(
              child: _isImage
                  ? _buildImagePreview(
                      url: url,
                      hasUrl: hasUrl,
                      isLoading: isLoading,
                    )
                  : _buildDocumentPreview(
                      hasUrl: hasUrl,
                      isLoading: isLoading,
                    ),
            ),
            if (widget.additionalAttachmentCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+${widget.additionalAttachmentCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildImagePreview({
    required String url,
    required bool hasUrl,
    required bool isLoading,
  }) {
    if (isLoading) return _loadingPreview();
    if (!hasUrl) return _thumbnailPlaceholder();
    return Image.network(
      url,
      key: ValueKey<String>(url),
      fit: BoxFit.cover,
      gaplessPlayback: false,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _loadingPreview();
      },
      errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
    );
  }

  Widget _buildDocumentPreview({
    required bool hasUrl,
    required bool isLoading,
  }) {
    if (isLoading) return _loadingPreview();
    return Container(
      color: hasUrl ? const Color(0xFFEAF2FF) : Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        _documentIconForMimeType(widget.mimeType ?? ''),
        color: AppColors.primaryColor.withValues(alpha: 0.68),
        size: 24,
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Image.asset(
      MediaRes.deafultNewsletterImage,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          color: AppColors.primaryColor.withValues(alpha: 0.5),
          size: 22,
        ),
      ),
    );
  }

  // While the asset URL resolves / the image downloads, show the default
  // newsletter thumbnail instead of a spinner.
  Widget _loadingPreview() => _thumbnailPlaceholder();

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
}

