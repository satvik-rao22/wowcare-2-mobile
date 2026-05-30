import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// Resolves and displays a newsletter image from API delivery URL, asset code,
/// or legacy URL fields.
///
/// Resolution order (matches attachment grid behavior):
/// 1. [assetUrl] — processed CloudFront `assetUrl` from API
/// 2. [assetCode] — fetch via media service
/// 3. [directUrl] — legacy `imageUrl` / http fallback
///
/// Shows [MediaRes.deafultNewsletterImage] while loading, when missing, or on error.
class NewsletterMediaImage extends StatefulWidget {
  const NewsletterMediaImage({
    super.key,
    this.assetUrl,
    this.assetCode,
    this.directUrl,
    this.fit = BoxFit.cover,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 10,
    this.onTap,
    this.fillParent = false,
    this.onImageTap,
  });

  /// Processed delivery URL (`assetUrl` from API), same as attachments.
  final String? assetUrl;
  final String? assetCode;
  final String? directUrl;
  final BoxFit fit;
  final double aspectRatio;
  final double borderRadius;
  final VoidCallback? onTap;

  /// When true, expands to fill the parent instead of enforcing [aspectRatio].
  final bool fillParent;
  final void Function(String url)? onImageTap;

  @override
  State<NewsletterMediaImage> createState() => _NewsletterMediaImageState();
}

class _NewsletterMediaImageState extends State<NewsletterMediaImage> {
  late Future<String> _urlFuture;
  String? _initialUrl;
  String _sourceToken = '';

  @override
  void initState() {
    super.initState();
    _sourceToken = _sourceIdentity();
    _initialUrl = _syncResolvedUrl();
    _urlFuture = _resolveUrl();
  }

  @override
  void didUpdateWidget(covariant NewsletterMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String nextToken = _sourceIdentity();
    if (nextToken != _sourceToken) {
      _sourceToken = nextToken;
      _initialUrl = _syncResolvedUrl();
      _urlFuture = _resolveUrl();
      setState(() {});
    }
  }

  String _sourceIdentity() {
    final delivery = (widget.assetUrl ?? '').trim();
    final code = (widget.assetCode ?? '').trim();
    final direct = (widget.directUrl ?? '').trim();
    return '$delivery|$code|$direct';
  }

  String _normalizedDeliveryUrl() {
    final delivery = (widget.assetUrl ?? '').trim();
    if (_isHttpUrl(delivery)) return delivery;
    return '';
  }

  String _normalizedAssetCode() {
    final code = (widget.assetCode ?? '').trim();
    if (code.isNotEmpty && !_isHttpUrl(code)) return code;
    return '';
  }

  String _normalizedLegacyUrl() {
    final direct = (widget.directUrl ?? '').trim();
    if (_isHttpUrl(direct)) return direct;
    return '';
  }

  String? _syncResolvedUrl() {
    final String delivery = _normalizedDeliveryUrl();
    if (delivery.isNotEmpty) return delivery;

    final ImageUploadService uploadService =
        serviceLocator<ImageUploadService>();

    final String code = _normalizedAssetCode();
    if (code.isNotEmpty) {
      final String? cached = uploadService.cachedMediaAssetUrl(code);
      if (cached != null && cached.trim().isNotEmpty) return cached.trim();
    }

    final String legacy = _normalizedLegacyUrl();
    if (legacy.isNotEmpty) return legacy;

    return null;
  }

  Future<String> _resolveUrl() async {
    final String delivery = _normalizedDeliveryUrl();
    if (delivery.isNotEmpty) return delivery;

    final ImageUploadService uploadService =
        serviceLocator<ImageUploadService>();

    final String code = _normalizedAssetCode();
    if (code.isNotEmpty) {
      try {
        final String resolved =
            await uploadService.getMediaAssetUrlByCode(assetCode: code);
        if (resolved.trim().isNotEmpty) return resolved.trim();
      } catch (_) {}
    }

    final String legacy = _normalizedLegacyUrl();
    if (legacy.isNotEmpty) return legacy;

    final String rawCode = (widget.assetCode ?? '').trim();
    if (rawCode.isNotEmpty && _isHttpUrl(rawCode)) return rawCode;

    return '';
  }

  bool _isHttpUrl(String value) {
    final lower = value.trim().toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  Widget _placeholder() {
    return Image.asset(
      MediaRes.deafultNewsletterImage,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: Colors.grey.shade200,
        child: Icon(
          Icons.image_outlined,
          color: AppColors.primaryColor.withValues(alpha: 0.5),
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      key: ValueKey<String>('newsletter-media-$_sourceToken'),
      future: _urlFuture,
      initialData: _initialUrl,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final String url = (snapshot.data ?? '').trim();
        final bool hasUrl = url.isNotEmpty;
        final String cacheKey = _normalizedAssetCode().isNotEmpty
            ? _normalizedAssetCode()
            : (_normalizedDeliveryUrl().isNotEmpty
                ? _normalizedDeliveryUrl()
                : url);

        Widget image = _placeholder();
        if (hasUrl) {
          image = Image.network(
            url,
            key: ValueKey<String>('newsletter-network-$cacheKey'),
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
            gaplessPlayback: false,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return _placeholder();
            },
            errorBuilder: (_, __, ___) => _placeholder(),
          );
        }

        final Widget framed = ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: widget.fillParent
              ? SizedBox.expand(child: image)
              : AspectRatio(
                  aspectRatio: widget.aspectRatio,
                  child: image,
                ),
        );

        if (hasUrl && (widget.onImageTap != null || widget.onTap != null)) {
          return GestureDetector(
            onTap: () {
              if (widget.onImageTap != null) {
                widget.onImageTap!(url);
              } else {
                widget.onTap?.call();
              }
            },
            child: framed,
          );
        }
        return framed;
      },
    );
  }
}
