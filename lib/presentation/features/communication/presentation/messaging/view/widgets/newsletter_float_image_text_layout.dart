import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/newsletter_color_theme.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/newsletter_html_blocks.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/widgets/newsletter_rich_html_text.dart';

/// Lays out text beside a fixed-width image, then continues text at full width
/// once the image height is exceeded — matching web newsletter float behavior.
class NewsletterFloatImageTextLayout extends StatefulWidget {
  const NewsletterFloatImageTextLayout({
    super.key,
    required this.textPart,
    required this.imagePart,
    required this.imageOnRight,
    required this.theme,
    required this.imageBuilder,
  });

  final NewsletterContentPart? textPart;
  final NewsletterContentPart? imagePart;
  final bool imageOnRight;
  final NewsletterThemeColors theme;

  /// Builds the image widget; receives the computed width for the side column.
  final Widget Function(double width) imageBuilder;

  static const double imageWidthFraction = 0.46;
  static const double maxImageWidth = 200;
  static const double minImageWidth = 132;
  static const double gap = 12;
  static const double imageAspectRatio = 16 / 9;

  @override
  State<NewsletterFloatImageTextLayout> createState() =>
      _NewsletterFloatImageTextLayoutState();
}

class _NewsletterFloatImageTextLayoutState
    extends State<NewsletterFloatImageTextLayout> {
  List<String> _blocks = const <String>[];
  List<double>? _blockHeights;
  int _splitIndex = 0;
  double _lastContainerWidth = 0;

  @override
  void initState() {
    super.initState();
    _blocks = splitNewsletterHtmlIntoBlocks(widget.textPart?.text ?? '');
  }

  @override
  void didUpdateWidget(covariant NewsletterFloatImageTextLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textPart?.text != widget.textPart?.text) {
      _blocks = splitNewsletterHtmlIntoBlocks(widget.textPart?.text ?? '');
      _blockHeights = null;
      _splitIndex = 0;
    }
  }

  double _imageWidthForContainer(double containerWidth) {
    final double computed =
        (containerWidth * NewsletterFloatImageTextLayout.imageWidthFraction)
            .clamp(
      NewsletterFloatImageTextLayout.minImageWidth,
      NewsletterFloatImageTextLayout.maxImageWidth,
    );
    return computed;
  }

  double _imageHeightForWidth(double imageWidth) {
    return imageWidth / NewsletterFloatImageTextLayout.imageAspectRatio;
  }

  double _besideTextWidth(double containerWidth, double imageWidth) {
    return containerWidth - imageWidth - NewsletterFloatImageTextLayout.gap;
  }

  void _onBlockMeasured(int index, Size size) {
    if (!mounted || _blockHeights == null) return;

    final List<double> next = List<double>.from(_blockHeights!);
    next[index] = size.height;

    final bool allMeasured = !next.any((double h) => h <= 0);
    if (!allMeasured) {
      setState(() => _blockHeights = next);
      return;
    }

    final double imageHeight =
        _imageHeightForWidth(_imageWidthForContainer(_lastContainerWidth));
    int split = 0;
    double used = 0;
    for (int i = 0; i < next.length; i++) {
      if (used + next[i] <= imageHeight + 1) {
        used += next[i];
        split = i + 1;
      } else {
        break;
      }
    }

    setState(() {
      _blockHeights = next;
      _splitIndex = split;
    });
  }

  Widget _htmlBlock(String html, {Key? key}) {
    return NewsletterRichHtmlText(
      key: key,
      htmlData: html,
      theme: widget.theme,
    );
  }

  Widget _buildMeasuringColumn(double besideWidth) {
    _blockHeights ??= List<double>.filled(_blocks.length, 0);

    return Offstage(
      child: SizedBox(
        width: besideWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < _blocks.length; i++)
              _MeasureSize(
                onChange: (Size size) => _onBlockMeasured(i, size),
                child: _htmlBlock(_blocks[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalLayout({
    required double containerWidth,
    required double imageWidth,
    required Widget image,
  }) {
    final List<String> besideBlocks = _blocks.take(_splitIndex).toList();
    final List<String> belowBlocks = _blocks.skip(_splitIndex).toList();
    final bool hasImage =
        widget.imagePart != null && widget.imagePart!.hasImage;
    final bool hasText = _blocks.isNotEmpty;

    if (!hasImage && !hasText) return const SizedBox.shrink();
    if (!hasImage) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _blocks
            .map((String b) => _htmlBlock(b, key: ValueKey<String>(b)))
            .toList(),
      );
    }
    if (!hasText) {
      return Align(
        alignment: widget.imageOnRight
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: SizedBox(width: imageWidth, child: image),
      );
    }

    final Widget besideTextColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < besideBlocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          _htmlBlock(
            besideBlocks[i],
            key: ValueKey<String>('beside-$i-${besideBlocks[i]}'),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!widget.imageOnRight) ...[
              SizedBox(width: imageWidth, child: image),
              const SizedBox(width: NewsletterFloatImageTextLayout.gap),
            ],
            Expanded(child: besideTextColumn),
            if (widget.imageOnRight) ...[
              const SizedBox(width: NewsletterFloatImageTextLayout.gap),
              SizedBox(width: imageWidth, child: image),
            ],
          ],
        ),
        if (belowBlocks.isNotEmpty) ...[
          const SizedBox(height: NewsletterFloatImageTextLayout.gap),
          for (int i = 0; i < belowBlocks.length; i++) ...[
            if (i > 0) const SizedBox(height: 2),
            _htmlBlock(
              belowBlocks[i],
              key: ValueKey<String>('below-$i-${belowBlocks[i]}'),
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double containerWidth = constraints.maxWidth;

        if (_lastContainerWidth != 0 &&
            (containerWidth - _lastContainerWidth).abs() > 2 &&
            _blockHeights != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _blockHeights = null;
              _splitIndex = 0;
            });
          });
        }
        _lastContainerWidth = containerWidth;

        final double imageWidth = _imageWidthForContainer(containerWidth);
        final double besideWidth = _besideTextWidth(containerWidth, imageWidth);
        final Widget image = widget.imageBuilder(imageWidth);

        final bool needsMeasure = _blocks.isNotEmpty &&
            (_blockHeights == null ||
                _blockHeights!.length != _blocks.length ||
                _blockHeights!.any((double h) => h <= 0));

        if (needsMeasure) {
          return Stack(
            children: <Widget>[
              _buildFinalLayout(
                containerWidth: containerWidth,
                imageWidth: imageWidth,
                image: image,
              ),
              _buildMeasuringColumn(besideWidth),
            ],
          );
        }

        return _buildFinalLayout(
          containerWidth: containerWidth,
          imageWidth: imageWidth,
          image: image,
        );
      },
    );
  }
}

class _MeasureSize extends StatefulWidget {
  const _MeasureSize({
    required this.onChange,
    required this.child,
  });

  final ValueChanged<Size> onChange;
  final Widget child;

  @override
  State<_MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<_MeasureSize> {
  Size? _lastSize;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
    return widget.child;
  }

  void _reportSize() {
    if (!mounted) return;
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final Size size = renderObject.size;
    if (_lastSize == size) return;
    _lastSize = size;
    widget.onChange(size);
  }
}
