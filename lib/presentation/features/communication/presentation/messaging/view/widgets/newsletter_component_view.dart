import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/newsletter_color_theme.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/newsletter_float_image_text_layout.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/newsletter_media_image.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/newsletter_media_preview_overlay.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/newsletter_rich_html_text.dart';

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

    final NewsletterThemeColors theme =
        NewsletterThemeColors.fromKey(colorThemeKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < components.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
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
        return _HeadingBlock(
          part: _firstTextPart(parts),
          theme: theme,
        );
      case 'IMAGE':
        return _ImageBlock(
          slotKey: '${component.id}-0',
          part: _firstImageSlotPart(parts),
        );
      case 'TEXT':
      case 'TEXT_BLOCK':
        return _TextBlock(
          part: _firstTextPart(parts),
          theme: theme,
        );
      case 'TEXT_IMAGE':
        return _SideBySideBlock(
          componentId: component.id,
          textPart: _firstTextPart(parts),
          imagePart: _firstImageSlotPart(parts),
          imageOnRight: true,
          theme: theme,
        );
      case 'IMAGE_TEXT':
        return _SideBySideBlock(
          componentId: component.id,
          textPart: _firstTextPart(parts),
          imagePart: _firstImageSlotPart(parts),
          imageOnRight: false,
          theme: theme,
        );
      case 'IMAGE_TOP_TEXT':
        return _StackedBlock(
          componentId: component.id,
          textPart: _firstTextPart(parts),
          imagePart: _firstImageSlotPart(parts),
          imageOnTop: true,
          theme: theme,
        );
      case 'TEXT_TOP_IMAGE':
        return _StackedBlock(
          componentId: component.id,
          textPart: _firstTextPart(parts),
          imagePart: _firstImageSlotPart(parts),
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
        return _buildTwoColumn(parts);
      case 'DIVIDER':
        return _DividerBlock(theme: theme);
      default:
        if (parts.isEmpty) return const SizedBox.shrink();
        return _buildFromPartSequence(parts);
    }
  }

  Widget _buildFromPartSequence(List<NewsletterContentPart> parts) {
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
      final int firstImageIndex = parts.indexWhere(
        (NewsletterContentPart p) =>
            p.type == NewsletterPartType.image && p.hasImage,
      );
      final int firstTextIndex = parts.indexWhere(
        (NewsletterContentPart p) =>
            p.type == NewsletterPartType.text && p.hasText,
      );
      return _SideBySideBlock(
        componentId: component.id,
        textPart: textParts.first,
        imagePart: imageParts.first,
        imageOnRight: firstImageIndex > firstTextIndex,
        theme: theme,
      );
    }

    if (imageParts.isNotEmpty) {
      return _ImageBlock(
        slotKey: '${component.id}-seq',
        part: imageParts.first,
      );
    }
    if (textParts.isNotEmpty) {
      return _TextBlock(part: textParts.first, theme: theme);
    }
    return const SizedBox.shrink();
  }

  Widget _buildTwoColumn(List<NewsletterContentPart> parts) {
    final NewsletterContentPart? first = parts.isNotEmpty ? parts.first : null;
    final NewsletterContentPart? second =
        parts.length > 1 ? parts[1] : null;

    if (first == null) return const SizedBox.shrink();

    final bool firstIsImage = first.type == NewsletterPartType.image;
    final bool secondIsImage =
        second != null && second.type == NewsletterPartType.image;

    if (firstIsImage && secondIsImage) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _ImageBlock(
              slotKey: '${component.id}-col0',
              part: first,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ImageBlock(
              slotKey: '${component.id}-col1',
              part: second,
            ),
          ),
        ],
      );
    }
    if (firstIsImage && second != null && !secondIsImage) {
      final bool textIsEmpty =
          second.type == NewsletterPartType.text && !second.hasText;
      if (textIsEmpty) {
        return _ImageBlock(
          slotKey: '${component.id}-col-image',
          part: first,
        );
      }
      return _SideBySideBlock(
        componentId: component.id,
        textPart: second,
        imagePart: first,
        imageOnRight: false,
        theme: theme,
      );
    }
    if (!firstIsImage && secondIsImage) {
      final bool textIsEmpty = first.type == NewsletterPartType.text &&
          !first.hasText;
      if (textIsEmpty) {
        return _ImageBlock(
          slotKey: '${component.id}-col-image',
          part: second,
        );
      }
      return _SideBySideBlock(
        componentId: component.id,
        textPart: first,
        imagePart: second,
        imageOnRight: true,
        theme: theme,
      );
    }
    if (!firstIsImage && second != null && !secondIsImage) {
      return _TwoColumnTextBlock(
        left: first,
        right: second,
        theme: theme,
      );
    }
    if (firstIsImage) {
      return _ImageBlock(
        slotKey: '${component.id}-solo',
        part: first,
      );
    }
    return _TextBlock(part: first, theme: theme);
  }

  NewsletterContentPart? _firstTextPart(List<NewsletterContentPart> parts) {
    for (final part in parts) {
      if (part.type == NewsletterPartType.text && part.hasText) return part;
    }
    return null;
  }

  NewsletterContentPart? _firstImageSlotPart(List<NewsletterContentPart> parts) {
    for (final part in parts) {
      if (part.type == NewsletterPartType.image) return part;
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
  const _HeadingBlock({
    required this.part,
    required this.theme,
  });

  final NewsletterContentPart? part;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    if (part == null || !part!.hasText) return const SizedBox.shrink();
    return NewsletterRichHtmlText(
      htmlData: part!.text,
      theme: theme,
      isHeading: true,
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.part,
    required this.theme,
  });

  final NewsletterContentPart? part;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    if (part == null || !part!.hasText) return const SizedBox.shrink();
    return NewsletterRichHtmlText(
      htmlData: part!.text,
      theme: theme,
    );
  }
}

class _SideBySideBlock extends StatelessWidget {
  const _SideBySideBlock({
    required this.componentId,
    required this.textPart,
    required this.imagePart,
    required this.imageOnRight,
    required this.theme,
  });

  final int componentId;
  final NewsletterContentPart? textPart;
  final NewsletterContentPart? imagePart;
  final bool imageOnRight;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    return NewsletterFloatImageTextLayout(
      textPart: textPart,
      imagePart: imagePart,
      imageOnRight: imageOnRight,
      theme: theme,
      imageBuilder: (double width) => _ImageBlock(
        slotKey: '$componentId-float',
        part: imagePart,
        fixedWidth: width,
      ),
    );
  }
}

class _StackedBlock extends StatelessWidget {
  const _StackedBlock({
    required this.componentId,
    required this.textPart,
    required this.imagePart,
    required this.imageOnTop,
    required this.theme,
  });

  final int componentId;
  final NewsletterContentPart? textPart;
  final NewsletterContentPart? imagePart;
  final bool imageOnTop;
  final NewsletterThemeColors theme;

  @override
  Widget build(BuildContext context) {
    final Widget? imageWidget = imagePart != null &&
            imagePart!.type == NewsletterPartType.image
        ? _ImageBlock(
            slotKey: '$componentId-stacked',
            part: imagePart,
          )
        : null;
    final Widget? textWidget = textPart != null && textPart!.hasText
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
            const SizedBox(height: 12),
          if (textWidget != null) textWidget,
        ] else ...[
          if (textWidget != null) textWidget,
          if (textWidget != null && imageWidget != null)
            const SizedBox(height: 12),
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
        if (left != null && right != null) const SizedBox(width: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Divider(
        color: theme.divider,
        thickness: 1.2,
        height: 1,
      ),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({
    required this.slotKey,
    required this.part,
    this.fixedWidth,
  });

  final String slotKey;
  final NewsletterContentPart? part;
  final double? fixedWidth;

  @override
  Widget build(BuildContext context) {
    final String code = (part?.assetCode ?? '').trim();
    final String delivery = (part?.resolvedImageUrl ?? '').trim();
    final String storagePath = (part?.imageUrl ?? '').trim();
    final bool storageIsHttp = storagePath.startsWith('http://') ||
        storagePath.startsWith('https://');
    final Widget content = NewsletterMediaImage(
      key: ValueKey<String>(
        'newsletter-image-$slotKey-$code-$delivery-$storagePath',
      ),
      assetUrl: delivery.isNotEmpty ? delivery : null,
      assetCode: delivery.isEmpty && code.isNotEmpty ? code : null,
      directUrl: delivery.isEmpty && storageIsHttp ? storagePath : null,
      aspectRatio: 16 / 9,
      borderRadius: 10,
      onImageTap: (String resolvedUrl) =>
          showNewsletterImagePreview(context, imageUrl: resolvedUrl),
    );

    if (fixedWidth == null) return content;
    return SizedBox(width: fixedWidth, child: content);
  }
}
