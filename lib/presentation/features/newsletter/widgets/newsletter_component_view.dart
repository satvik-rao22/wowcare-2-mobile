import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';
import 'package:wowcare/presentation/features/newsletter/view_model/newsletter_asset_url_cubit.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_color_theme.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_media_preview_overlay.dart';
import 'package:wowcare/presentation/features/newsletter/widgets/newsletter_rich_html_text.dart';

/// Renders ordered newsletter layout components with theme-aware styling.
class NewsletterComponentList extends StatelessWidget {
  const NewsletterComponentList({
    super.key,
    required this.components,
    required this.colorThemeKey,
  });

  final List<NewsletterComponent> components;
  final String colorThemeKey;

  @override
  Widget build(BuildContext context) {
    if (components.isEmpty) return const SizedBox.shrink();

    final NewsletterThemeColors theme = NewsletterThemeColors.fromKey(
      colorThemeKey,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < components.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSizes.md),
          _NewsletterComponentTile(
            key: ValueKey<String>(
              '${components[i].id}-${components[i].componentType}-${components[i].sortOrder}',
            ),
            component: components[i],
            theme: theme,
          ),
        ],
      ],
    );
  }
}

class _NewsletterComponentTile extends StatelessWidget {
  const _NewsletterComponentTile({
    super.key,
    required this.component,
    required this.theme,
  });

  final NewsletterComponent component;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final String type = component.normalizedType;
    final List<NewsletterContentPart> parts = component.parts;

    switch (type) {
      case 'HEADING':
        return _HeadingBlock(part: _firstTextPart(parts), theme: theme);
      case 'IMAGE':
        return _ImageBlock(part: _firstImagePart(parts));
      case 'TEXT':
      case 'TEXT_BLOCK':
        return _TextBlock(part: _firstTextPart(parts), theme: theme);
      case 'TEXT_IMAGE':
      case 'IMAGE_TEXT':
        return _SideBySideBlock(
          textPart: _firstTextPart(parts),
          imagePart: _firstImagePart(parts),
          theme: theme,
        );
      case 'IMAGE_TOP_TEXT':
        return _StackedBlock(
          textPart: _firstTextPart(parts),
          imagePart: _firstImagePart(parts),
          imageOnTop: true,
          theme: theme,
        );
      case 'TEXT_TOP_IMAGE':
        return _StackedBlock(
          textPart: _firstTextPart(parts),
          imagePart: _firstImagePart(parts),
          imageOnTop: false,
          theme: theme,
        );
      case 'TWO_COLUMN_TEXT':
        return _TwoColumnTextBlock(
          left: _textPartAt(parts, 0),
          right: _textPartAt(parts, 1),
          theme: theme,
        );
      case 'TWO_COLUMN':
        return _TwoColumnPartsBlock(parts: parts, theme: theme);
      case 'DIVIDER':
        return _DividerBlock(theme: theme);
      default:
        if (parts.isEmpty) return const SizedBox.shrink();
        return _PartSequenceBlock(parts: parts, theme: theme);
    }
  }

  NewsletterContentPart? _firstTextPart(List<NewsletterContentPart> parts) {
    for (final part in parts) {
      if (part.type == NewsletterPartType.text && part.hasText) return part;
    }
    return null;
  }

  NewsletterContentPart? _firstImagePart(List<NewsletterContentPart> parts) {
    for (final part in parts) {
      if (part.type == NewsletterPartType.image && part.hasImage) return part;
    }
    return null;
  }

  NewsletterContentPart? _textPartAt(
    List<NewsletterContentPart> parts,
    int index,
  ) {
    final List<NewsletterContentPart> textParts = parts
        .where(
          (NewsletterContentPart p) =>
              p.type == NewsletterPartType.text && p.hasText,
        )
        .toList();
    if (index >= textParts.length) return null;
    return textParts[index];
  }
}

class _HeadingBlock extends StatelessWidget {
  const _HeadingBlock({required this.part, required this.theme});

  final NewsletterContentPart? part;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    // Copied to a local so the null check PROMOTES rather than being asserted
    // away separately. `part` is a public field, which Dart cannot promote, so
    // the guard and the `!` were two independent claims — change the guard and
    // the assertion keeps compiling and starts throwing on real data.
    final NewsletterContentPart? part = this.part;
    if (part == null || !part.hasText) return const SizedBox.shrink();
    return NewsletterRichHtmlText(
      htmlData: part.text,
      theme: theme,
      isHeading: true,
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.part, required this.theme});

  final NewsletterContentPart? part;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final NewsletterContentPart? part = this.part;
    if (part == null || !part.hasText) return const SizedBox.shrink();
    return NewsletterRichHtmlText(htmlData: part.text, theme: theme);
  }
}

/// Renders an image paired with text on mobile as a full-width image
/// followed by the text below it, regardless of the backend's declared
/// left/right placement — side-by-side columns aren't usable at phone
/// widths.
class _SideBySideBlock extends StatelessWidget {
  const _SideBySideBlock({
    required this.textPart,
    required this.imagePart,
    required this.theme,
  });

  final NewsletterContentPart? textPart;
  final NewsletterContentPart? imagePart;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return _StackedBlock(
      textPart: textPart,
      imagePart: imagePart,
      imageOnTop: true,
      theme: theme,
    );
  }
}

/// Renders multiple images stacked full-width, in place of a side-by-side
/// column layout that isn't usable at phone widths.
class _StackedImagesBlock extends StatelessWidget {
  const _StackedImagesBlock({required this.imageParts});

  final List<NewsletterContentPart> imageParts;

  @override
  Widget build(BuildContext context) {
    if (imageParts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < imageParts.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSizes.sm),
          _ImageBlock(part: imageParts[i]),
        ],
      ],
    );
  }
}

class _StackedBlock extends StatelessWidget {
  const _StackedBlock({
    required this.textPart,
    required this.imagePart,
    required this.imageOnTop,
    required this.theme,
  });

  final NewsletterContentPart? textPart;
  final NewsletterContentPart? imagePart;
  final bool imageOnTop;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final NewsletterContentPart? imagePart = this.imagePart;
    final NewsletterContentPart? textPart = this.textPart;
    final Widget? imageWidget = imagePart != null && imagePart.hasImage
        ? _ImageBlock(part: imagePart)
        : null;
    final Widget? textWidget = textPart != null && textPart.hasText
        ? _TextBlock(part: textPart, theme: theme)
        : null;

    if (imageWidget == null && textWidget == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageOnTop) ...[
          if (imageWidget != null) imageWidget,
          if (imageWidget != null && textWidget != null)
            const SizedBox(height: AppSizes.sm),
          if (textWidget != null) textWidget,
        ] else ...[
          if (textWidget != null) textWidget,
          if (textWidget != null && imageWidget != null)
            const SizedBox(height: AppSizes.sm),
          if (imageWidget != null) imageWidget,
        ],
      ],
    );
  }
}

class _TwoColumnTextBlock extends StatelessWidget {
  const _TwoColumnTextBlock({
    required this.left,
    required this.right,
    required this.theme,
  });

  final NewsletterContentPart? left;
  final NewsletterContentPart? right;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    if (left == null && right == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: left != null
              ? _TextBlock(part: left, theme: theme)
              : const SizedBox.shrink(),
        ),
        if (left != null && right != null) const SizedBox(width: AppSizes.sm),
        Expanded(
          child: right != null
              ? _TextBlock(part: right, theme: theme)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _DividerBlock extends StatelessWidget {
  const _DividerBlock({required this.theme});

  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xxs),
      child: Divider(color: theme.divider, thickness: 1.2, height: 1),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({required this.part});

  final NewsletterContentPart? part;

  @override
  Widget build(BuildContext context) {
    final NewsletterContentPart? part = this.part;
    if (part == null || !part.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            MediaRes.deafultNewsletterImage,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return _NewsletterComponentImage(
      imageUrl: part.imageUrl,
      assetCode: part.assetCode,
      alt: part.alt,
    );
  }
}

class _NewsletterComponentImage extends StatefulWidget {
  const _NewsletterComponentImage({
    required this.imageUrl,
    required this.assetCode,
    required this.alt,
  });

  final String imageUrl;
  final String assetCode;
  final String alt;

  @override
  State<_NewsletterComponentImage> createState() =>
      _NewsletterComponentImageState();
}

class _NewsletterComponentImageState extends State<_NewsletterComponentImage> {
  /// The asset code the cubit must resolve, or '' when the component already
  /// carried a usable URL (or carried nothing) and no resolution is needed.
  String get _pendingCode =>
      widget.imageUrl.trim().isNotEmpty ? '' : widget.assetCode.trim();

  @override
  void initState() {
    super.initState();
    _requestUrl();
  }

  void _requestUrl() {
    final String code = _pendingCode;
    if (code.isEmpty) return;
    context.read<NewsletterAssetUrlCubit>().resolve(code);
  }

  @override
  void didUpdateWidget(covariant _NewsletterComponentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.assetCode != widget.assetCode) {
      _requestUrl();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String pendingCode = _pendingCode;
    if (pendingCode.isEmpty) {
      // Direct URL (or nothing at all) — never shows the loading frame, which
      // is what the short circuit at the top of the old `_resolveUrl` did.
      return _image(url: widget.imageUrl.trim(), isLoading: false);
    }

    return BlocSelector<NewsletterAssetUrlCubit, NewsletterAssetUrlState,
        String?>(
      // null => still resolving (loader), '' => resolved with no URL (the
      // default image). Mirrors ConnectionState.waiting vs. empty data.
      selector: (NewsletterAssetUrlState state) => state.urlFor(pendingCode),
      builder: (BuildContext context, String? resolved) =>
          _image(url: resolved ?? '', isLoading: resolved == null),
    );
  }

  Widget _image({required String url, required bool isLoading}) {
    if (isLoading) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: AppColors.newsletterImageLoadingBackground,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );
    }

    if (url.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            MediaRes.deafultNewsletterImage,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: GestureDetector(
          onTap: () => showNewsletterImagePreview(context, imageUrl: url),
          child: Image.network(
            url,
            key: ValueKey<String>(url),
            fit: BoxFit.cover,
            gaplessPlayback: false,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return ColoredBox(
                color: AppColors.newsletterImageLoadingBackground,
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Image.asset(
              MediaRes.deafultNewsletterImage,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chooses the block layout for a component whose type the renderer does not
/// recognise, from the shape of its parts.
///
/// A private widget rather than a `_build…()` method: a method returning a
/// Widget cannot be const, cannot take a key, and rebuilds with its whole
/// enclosing widget (§6).
class _PartSequenceBlock extends StatelessWidget {
  const _PartSequenceBlock({required this.parts, required this.theme});

  final List<NewsletterContentPart> parts;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {

    final List<NewsletterContentPart> textParts = parts
        .where(
          (NewsletterContentPart p) =>
              p.type == NewsletterPartType.text && p.hasText,
        )
        .toList();
    final List<NewsletterContentPart> imageParts = parts
        .where(
          (NewsletterContentPart p) =>
              p.type == NewsletterPartType.image && p.hasImage,
        )
        .toList();

    if (textParts.length >= 2 && imageParts.isEmpty) {
      return _TwoColumnTextBlock(
        left: textParts[0],
        right: textParts[1],
        theme: theme,
      );
    }

    if (imageParts.isNotEmpty && textParts.isNotEmpty) {
      return _SideBySideBlock(
        textPart: textParts.first,
        imagePart: imageParts.first,
        theme: theme,
      );
    }

    if (imageParts.length > 1) {
      return _StackedImagesBlock(imageParts: imageParts);
    }
    if (imageParts.isNotEmpty) {
      return _ImageBlock(part: imageParts.first);
    }
    if (textParts.isNotEmpty) {
      return _TextBlock(part: textParts.first, theme: theme);
    }
    return const SizedBox.shrink();
  
  }
}

/// Chooses the block layout for a declared two-column component.
class _TwoColumnPartsBlock extends StatelessWidget {
  const _TwoColumnPartsBlock({required this.parts, required this.theme});

  final List<NewsletterContentPart> parts;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {

    final NewsletterContentPart? first = parts.isNotEmpty ? parts.first : null;
    final NewsletterContentPart? second = parts.length > 1 ? parts[1] : null;

    if (first == null) return const SizedBox.shrink();

    final bool firstIsImage = first.type == NewsletterPartType.image;
    final bool secondIsImage =
        second != null && second.type == NewsletterPartType.image;

    if (firstIsImage && secondIsImage) {
      return _StackedImagesBlock(
        imageParts: <NewsletterContentPart>[first, second],
      );
    }
    if (firstIsImage && second != null && !secondIsImage) {
      return _SideBySideBlock(textPart: second, imagePart: first, theme: theme);
    }
    if (!firstIsImage && secondIsImage) {
      return _SideBySideBlock(textPart: first, imagePart: second, theme: theme);
    }
    if (!firstIsImage && second != null && !secondIsImage) {
      return _TwoColumnTextBlock(left: first, right: second, theme: theme);
    }
    if (firstIsImage) {
      return _ImageBlock(part: first);
    }
    return _TextBlock(part: first, theme: theme);
  
  }
}
