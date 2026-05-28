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
    this.primaryAttachmentMimeType,
    this.additionalAttachmentCount = 0,
  });

  final String title;
  final String classroom;
  final String sentDate;
  final String createdBy;
  final int recipientCount;
  final String? primaryAttachmentAssetCode;
  final String? primaryAttachmentMimeType;
  final int additionalAttachmentCount;
}

class NewsletterSentListCard extends StatelessWidget {
  const NewsletterSentListCard({
    super.key,
    required this.newsLetter,
    required this.onTap,
  });

  final NewsletterListItemModel newsLetter;
  final VoidCallback onTap;

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
                    assetCode: newsLetter.primaryAttachmentAssetCode,
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
                    _AlignedMetaRow(
                      label: 'Date',
                      value: newsLetter.sentDate,
                    ),
                    const SizedBox(height: 2),
                    _AlignedMetaRow(
                      label: 'Classroom',
                      value: newsLetter.classroom,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          size: 18,
                          color: AppColors.primaryColor.withValues(alpha: 0.62),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${newsLetter.recipientCount}',
                          style: TextStyle(
                            color: AppColors.primaryColor.withValues(alpha: 0.78),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryColor.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
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
    this.assetCode,
    this.mimeType,
    this.additionalAttachmentCount = 0,
  });

  final String? assetCode;
  final String? mimeType;
  final int additionalAttachmentCount;

  @override
  State<_CardThumbnail> createState() => _CardThumbnailState();
}

class _CardThumbnailState extends State<_CardThumbnail> {
  late final Future<String> _assetUrlFuture;

  @override
  void initState() {
    super.initState();
    _assetUrlFuture = _resolveAssetUrl();
  }

  Future<String> _resolveAssetUrl() async {
    final String code = (widget.assetCode ?? '').trim();
    if (code.isEmpty) return '';
    try {
      final ImageUploadService uploadService = serviceLocator<ImageUploadService>();
      return await uploadService.getMediaAssetUrlByCode(assetCode: code);
    } catch (_) {
      return '';
    }
  }

  bool get _isImage {
    final String mime = (widget.mimeType ?? '').toLowerCase();
    return mime.startsWith('image/');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _assetUrlFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final String url = (snapshot.data ?? '').trim();
        final bool hasUrl = url.isNotEmpty;
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

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
      fit: BoxFit.cover,
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

  Widget _loadingPreview() {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
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
}

