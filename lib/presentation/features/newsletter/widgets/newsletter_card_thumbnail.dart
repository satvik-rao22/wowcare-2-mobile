import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/presentation/features/newsletter/view_model/newsletter_asset_url_cubit.dart';

/// The leading thumbnail on a newsletter list card, and its image / document /
/// placeholder states.
///
/// Split out of `send_newsletter_list.dart` (§6's 400-line ceiling). One
/// cohesive unit: everything here exists to turn an asset code or a direct URL
/// into the little square at the left of a card, including the
/// [NewsletterAssetUrlCubit] round trip.
class NewsletterCardThumbnail extends StatefulWidget {
  const NewsletterCardThumbnail({
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
  State<NewsletterCardThumbnail> createState() => _NewsletterCardThumbnailState();
}

class _NewsletterCardThumbnailState extends State<NewsletterCardThumbnail> {
  /// A URL usable without any resolution — a direct http URL in either field,
  /// or '' when there is no asset at all. Null means the code has to go
  /// through [NewsletterAssetUrlCubit].
  String? get _directUrl {
    final String direct = (widget.directUrl ?? '').trim();
    if (_isHttpUrl(direct)) return direct;
    final String code = (widget.assetCode ?? '').trim();
    if (code.isEmpty) return '';
    if (_isHttpUrl(code)) return code;
    return null;
  }

  /// The asset code the cubit must resolve, or '' when [_directUrl] answers.
  String get _pendingCode =>
      _directUrl != null ? '' : (widget.assetCode ?? '').trim();

  @override
  void initState() {
    super.initState();
    _requestAssetUrl();
  }

  @override
  void didUpdateWidget(covariant NewsletterCardThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String oldCode = (oldWidget.assetCode ?? '').trim();
    final String newCode = (widget.assetCode ?? '').trim();
    final String oldUrl = (oldWidget.directUrl ?? '').trim();
    final String newUrl = (widget.directUrl ?? '').trim();
    // List cards are recycled onto other newsletters as they scroll.
    if (oldCode != newCode ||
        oldUrl != newUrl ||
        oldWidget.mimeType != widget.mimeType) {
      _requestAssetUrl();
    }
  }

  void _requestAssetUrl() {
    final String code = _pendingCode;
    if (code.isEmpty) return;
    // The cubit checks AssetService's synchronous session cache first,
    // so a code resolved earlier is adopted without a loading frame — the job
    // the `initialData:` seed did on the FutureBuilder this replaces.
    context.read<NewsletterAssetUrlCubit>().resolve(code);
  }

  bool _isHttpUrl(String value) {
    final lower = value.trim().toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  bool get _isImage {
    final String mime = (widget.mimeType ?? '').trim().toLowerCase();
    final String code = (widget.assetCode ?? '').trim();
    final String direct = (widget.directUrl ?? '').trim();
    // No attachment/asset at all: treat as an image so we fall through to
    // the default newsletter thumbnail instead of a generic file icon.
    if (mime.isEmpty && code.isEmpty && direct.isEmpty) return true;
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

    if (code.isNotEmpty && mime.isEmpty) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final String? direct = _directUrl;
    if (direct != null) {
      return _thumbnail(url: direct, isLoading: false);
    }

    final String pendingCode = _pendingCode;
    return BlocSelector<NewsletterAssetUrlCubit, NewsletterAssetUrlState,
        String?>(
      selector: (NewsletterAssetUrlState state) => state.urlFor(pendingCode),
      builder: (BuildContext context, String? resolved) => _thumbnail(
        url: resolved ?? '',
        // The old FutureBuilder also required `!hasUrl` to show the loader,
        // so a seeded URL suppressed it. `resolved != null` carries the same
        // meaning: a known value, empty or not, is never "still loading".
        isLoading: resolved == null,
      ),
    );
  }

  Widget _thumbnail({required String url, required bool isLoading}) {
    final bool hasUrl = url.isNotEmpty;

    return Stack(
      children: [
        Positioned.fill(
          child: _isImage
              ? _ThumbnailImagePreview(
                  url: url,
                  hasUrl: hasUrl,
                  isLoading: isLoading,
                )
              : _ThumbnailDocumentPreview(
                  mimeType: widget.mimeType ?? '',
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
                color: AppColors.newsletterAttachmentCountScrim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${widget.additionalAttachmentCount}',
                style: AppTextStyles.newsletterAttachmentCountBadge,
              ),
            ),
          ),
      ],
    );
  }

}

/// Image branch of a list-card thumbnail.
///
/// A private widget rather than a `_build…()` method: a method returning a
/// Widget cannot be const, cannot take a key, and rebuilds with its whole
/// enclosing widget (§6).
class _ThumbnailImagePreview extends StatelessWidget {
  const _ThumbnailImagePreview({
    required this.url,
    required this.hasUrl,
    required this.isLoading,
  });

  final String url;
  final bool hasUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // While the asset URL resolves / the image downloads, show the default
    // newsletter thumbnail instead of a spinner.
    if (isLoading) return const _ThumbnailPlaceholder();
    if (!hasUrl) return const _ThumbnailPlaceholder();
    return Image.network(
      url,
      key: ValueKey<String>(url),
      fit: BoxFit.cover,
      gaplessPlayback: false,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _ThumbnailPlaceholder();
      },
      errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
    );
  }
}

/// Document branch of a list-card thumbnail.
class _ThumbnailDocumentPreview extends StatelessWidget {
  const _ThumbnailDocumentPreview({
    required this.mimeType,
    required this.hasUrl,
    required this.isLoading,
  });

  final String mimeType;
  final bool hasUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _ThumbnailPlaceholder();
    return Container(
      color: hasUrl
          ? AppColors.newsletterDocumentThumbnailBackground
          : AppColors.newsletterThumbnailPlaceholderBackground,
      alignment: Alignment.center,
      child: Icon(
        _documentIconForMimeType(mimeType),
        color: AppColors.primaryColor.withValues(alpha: 0.68),
        size: 24,
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

/// The default newsletter thumbnail, used for the empty, loading and failed
/// states alike. `const`-constructible, which the method it replaces was not.
class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      MediaRes.deafultNewsletterImage,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.newsletterThumbnailPlaceholderBackground,
        alignment: Alignment.center,
        child: Icon(
          Icons.image_outlined,
          color: AppColors.primaryColor.withValues(alpha: 0.5),
          size: 22,
        ),
      ),
    );
  }
}
