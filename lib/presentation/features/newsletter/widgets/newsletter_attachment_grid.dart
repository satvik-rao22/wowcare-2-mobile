import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_attachment.dart';
import 'package:wowcare/presentation/features/newsletter/view_model/newsletter_asset_url_cubit.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_attachment_open_mode.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_media_preview_overlay.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';

/// Displays newsletter attachment placeholders from list payload.
/// Image URLs will be wired when the document/media API is integrated.
class NewsletterAttachmentGrid extends StatelessWidget {
  const NewsletterAttachmentGrid({
    super.key,
    required this.newsletterId,
    required this.attachments,
    this.isLoading = false,
    this.showFileName = true,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.35,
  });

  final int newsletterId;
  final List<NewsletterAttachment> attachments;
  final bool isLoading;
  final bool showFileName;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: 2,
        itemBuilder: (BuildContext context, int index) {
          return const ShimmerLoaderCard(
            margin: EdgeInsets.zero,
            child: SizedBox(width: 75, height: 75),
          );
        },
      );
    }

    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.newsletterAttachments,
          style: AppTextStyles.newsletterAttachmentsHeading,
        ),
        const SizedBox(height: AppSizes.xsPlus),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: attachments.length,
          itemBuilder: (BuildContext context, int index) {
            final NewsletterAttachment attachment = attachments[index];
            return _AttachmentTile(
              key: ValueKey<String>(
                '${attachment.id}|${attachment.mediaCode}|${attachment.resolvedUrl}',
              ),
              attachment: attachment,
              showFileName: showFileName,
            );
          },
        ),
      ],
    );
  }
}

class _AttachmentTile extends StatefulWidget {
  const _AttachmentTile({
    super.key,
    required this.attachment,
    required this.showFileName,
  });

  final NewsletterAttachment attachment;
  final bool showFileName;

  @override
  State<_AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends State<_AttachmentTile> {
  /// The asset code this tile needs the cubit to resolve, or '' when the
  /// payload already carried a usable URL (or carried nothing at all) and no
  /// resolution is required.
  String get _pendingCode => widget.attachment.resolvedUrl.trim().isNotEmpty
      ? ''
      : widget.attachment.mediaCode.trim();

  @override
  void initState() {
    super.initState();
    _requestAssetUrl();
  }

  @override
  void didUpdateWidget(covariant _AttachmentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Grid tiles are recycled onto other attachments; re-request when the
    // identity this tile renders changes. Same trigger as the `Future` field
    // reassignment this replaced.
    if (oldWidget.attachment.resolvedUrl != widget.attachment.resolvedUrl ||
        oldWidget.attachment.mediaCode != widget.attachment.mediaCode) {
      _requestAssetUrl();
    }
  }

  void _requestAssetUrl() {
    final String code = _pendingCode;
    if (code.isEmpty) return;
    context.read<NewsletterAssetUrlCubit>().resolve(code);
  }

  Future<void> _launchExternally(String url) async {
    // The mode is the whole fix. `LaunchMode.inAppWebView` was what put a blank
    // screen in front of anyone tapping an .xlsx — see
    // [NewsletterAttachmentOpenMode.externalApp]. Because the WebView opened
    // *successfully*, `launchUrl` returned true and the platformDefault
    // fallback below never fired, so there was no recovery but Back.
    //
    // Deliberately not gated on `canLaunchUrl`: on Android 11+ that answers
    // false for http/https unless the manifest declares a matching <queries>
    // intent, which this app's does not.
    bool opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url.trim()),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        opened = await launchUrl(
          Uri.parse(url.trim()),
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (_) {
      // No app could take the intent. Treated as a refusal: the launcher
      // throwing used to surface as nothing happening at all.
      opened = false;
    }

    if (!opened) _reportOpenFailed();
  }

  /// Tells the user the tap did nothing, instead of leaving them to guess.
  /// Every failure path here was otherwise silent.
  void _reportOpenFailed() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.newsletterAttachmentOpenFailed),
        backgroundColor: AppColors.warningColor,
      ),
    );
  }

  Future<void> _openAttachment({
    required String url,
    required bool isImage,
  }) async {
    switch (resolveNewsletterAttachmentOpenMode(isImage: isImage, url: url)) {
      case NewsletterAttachmentOpenMode.imagePreview:
        if (!mounted) return;
        await showNewsletterImagePreview(context, imageUrl: url);
      case NewsletterAttachmentOpenMode.externalApp:
        await _launchExternally(url);
      case NewsletterAttachmentOpenMode.refused:
        _reportOpenFailed();
    }
  }


  @override
  Widget build(BuildContext context) {
    final NewsletterAttachment attachment = widget.attachment;
    final String label = attachment.fileName.trim().isNotEmpty
        ? attachment.fileName
        : attachment.mediaCode;

    final String pendingCode = _pendingCode;
    if (pendingCode.isEmpty) {
      // Nothing to resolve: either the payload already carried a URL, or
      // there is no media code at all. Never shows a loader, which is what
      // the direct-URL short circuit in the old `_resolveAssetUrl` did.
      return _tile(
        label: label,
        attachment: attachment,
        url: attachment.resolvedUrl.trim(),
        isLoading: false,
      );
    }

    return BlocSelector<NewsletterAssetUrlCubit, NewsletterAssetUrlState,
        String?>(
      // null => not resolved yet (the loader), '' => resolved with no URL
      // (the placeholder). That is the same split the FutureBuilder made
      // between ConnectionState.waiting and an empty snapshot value.
      selector: (NewsletterAssetUrlState state) => state.urlFor(pendingCode),
      builder: (BuildContext context, String? resolved) => _tile(
        label: label,
        attachment: attachment,
        url: resolved ?? '',
        isLoading: resolved == null,
      ),
    );
  }

  Widget _tile({
    required String label,
    required NewsletterAttachment attachment,
    required String url,
    required bool isLoading,
  }) {
    final bool hasUrl = url.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: hasUrl
          ? () => _openAttachment(
                url: url,
                isImage: attachment.isImage,
              )
          : null,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.xsPlus),
        decoration: BoxDecoration(
          color: AppColors.newsletterAttachmentTileBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _AttachmentPreview(
                  attachment: attachment,
                  isLoading: isLoading,
                  hasUrl: hasUrl,
                  url: url,
                ),
              ),
            ),
            if (widget.showFileName) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.newsletterAttachmentFileName,
              ),
            ],
          ],
        ),
      ),
    );
  }

}

/// The image / document preview inside one attachment tile.
///
/// A private widget rather than a `_build…()` method: a method returning a
/// Widget cannot be const, cannot take a key, and rebuilds with its whole
/// enclosing widget (§6).
class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({
    required this.attachment,
    required this.isLoading,
    required this.hasUrl,
    required this.url,
  });

  final NewsletterAttachment attachment;
  final bool isLoading;
  final bool hasUrl;
  final String url;

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (attachment.isImage && hasUrl) {
      return Image.network(
        url,
        key: ValueKey<String>(url),
        fit: BoxFit.cover,
        width: double.infinity,
        gaplessPlayback: false,
        errorBuilder: (_, __, ___) => Image.asset(
          MediaRes.deafultNewsletterImage,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    if (attachment.isImage) {
      return Image.asset(
        MediaRes.deafultNewsletterImage,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    return Center(
      child: Icon(
        _documentIconForMimeType(attachment.mimeType),
        size: 36,
        color: AppColors.primaryColor.withValues(alpha: 0.6),
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
