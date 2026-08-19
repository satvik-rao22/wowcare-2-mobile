import 'package:flutter/material.dart';

import 'skeu_inner_shadow.dart';
import 'skeu_tokens.dart';

/// A raised panel: gradient face, navy-tinted drop shadow, lit top bevel.
///
/// This is the workhorse of the skeuomorphic language — every card, list row,
/// tile and sheet in the redesign is a [SkeuPanel] with a different radius and
/// elevation. Layer order matches CSS: background fill, then inset bevels,
/// then optional gloss, then content.
class SkeuPanel extends StatelessWidget {
  const SkeuPanel({
    required this.child,
    this.gradient,
    this.color,
    this.radius = SkeuRadius.xxl,
    this.borderRadius,
    this.shadows,
    this.insets = SkeuElevation.bevelFull,
    this.gloss,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.clip = true,
    this.onTap,
    this.border,
    super.key,
  });

  /// A panel that reads as slightly proud of the page (`--elev-1`).
  const SkeuPanel.flat({
    required Widget child,
    Gradient? gradient,
    double radius = SkeuRadius.lg,
    EdgeInsetsGeometry? padding,
    Key? key,
  }) : this(
         child: child,
         gradient: gradient,
         radius: radius,
         padding: padding,
         shadows: const [],
         key: key,
       );

  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final double radius;
  final BorderRadius? borderRadius;

  /// Drop shadows. Defaults to `--elev-2` when null; pass `[]` for none.
  final List<BoxShadow>? shadows;

  /// Inset shadows — bevels and wells. Defaults to `--bevel-full`.
  final List<SkeuInset> insets;

  /// Optional specular overlay, normally [SkeuSurfaces.glossTop].
  final Gradient? gloss;

  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool clip;
  final VoidCallback? onTap;
  final BoxBorder? border;

  BorderRadius get _br => borderRadius ?? BorderRadius.circular(radius);

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    if (insets.isNotEmpty || gloss != null) {
      content = Stack(
        children: [
          if (gloss != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: gloss, borderRadius: _br),
                ),
              ),
            ),
          if (insets.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: SkeuInsetPainter(insets, _br)),
              ),
            ),
          content,
        ],
      );
    }

    Widget panel = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient ?? (color == null ? SkeuSurfaces.card : null),
        color: color,
        borderRadius: _br,
        boxShadow: shadows ?? SkeuElevation.elev2,
        border: border,
      ),
      child: clip ? ClipRRect(borderRadius: _br, child: content) : content,
    );

    if (onTap != null) {
      panel = _SkeuPressable(onTap: onTap!, child: panel);
    }
    return panel;
  }
}

/// A recessed well: the material for anything you type into, scroll inside, or
/// read a value out of. Uses `--surface-field` plus a `--well-*` inset.
class SkeuWell extends StatelessWidget {
  const SkeuWell({
    required this.child,
    this.gradient = SkeuSurfaces.field,
    this.radius = SkeuRadius.lg,
    this.borderRadius,
    this.insets = SkeuElevation.wellMd,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.focused = false,
    this.error = false,
    this.onTap,
    super.key,
  });

  final Widget child;
  final Gradient gradient;
  final double radius;
  final BorderRadius? borderRadius;
  final List<SkeuInset> insets;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  /// Adds the teal focus ring (`--shadow-focus`).
  final bool focused;

  /// Swaps the focus ring for the danger ring.
  final bool error;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(radius);
    final ringColor = error
        ? SkeuColors.danger500.withValues(alpha: .4)
        : SkeuElevation.focusRingColor;

    Widget well = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: br,
        boxShadow: (focused || error)
            ? [
                BoxShadow(
                  color: ringColor,
                  spreadRadius: SkeuElevation.focusRingWidth,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: SkeuInsetPainter(insets, br)),
              ),
            ),
            Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ],
        ),
      ),
    );

    if (onTap != null) well = _SkeuPressable(onTap: onTap!, child: well);
    return well;
  }
}

/// A gauge trough: a recessed track whose content fills it edge to edge.
///
/// [SkeuWell] stacks its content loosely so a text field keeps its natural
/// height; a bar's coloured bands have no natural height at all and would
/// collapse to nothing. This variant hands the child tight constraints and
/// paints the recess *over* it, which is also the truer reading: the bands are
/// the trough's fill, so the shadow of the rim falls on them.
class SkeuTrough extends StatelessWidget {
  const SkeuTrough({
    required this.child,
    required this.height,
    this.radius = 9,
    this.gradient = SkeuSurfaces.sunken,
    this.insets = SkeuElevation.wellSm,
    super.key,
  });

  final Widget child;
  final double height;
  final double radius;
  final Gradient gradient;
  final List<SkeuInset> insets;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Container(
      height: height,
      decoration: BoxDecoration(gradient: gradient, borderRadius: br),
      child: ClipRRect(
        borderRadius: br,
        child: CustomPaint(
          foregroundPainter: SkeuInsetPainter(insets, br),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

/// The page ground: `--surface-page`, a soft radial wash lit from above.
class SkeuBackground extends StatelessWidget {
  const SkeuBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(gradient: SkeuSurfaces.page),
    child: child,
  );
}

/// A [Scaffold] pre-set to the skeuomorphic page ground with a transparent
/// scaffold colour, so any screen can adopt the language in one line.
class SkeuScaffold extends StatelessWidget {
  const SkeuScaffold({
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.key_,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final Key? key_;

  @override
  Widget build(BuildContext context) => SkeuBackground(
    child: Scaffold(
      key: key_,
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: body,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
    ),
  );
}

/// A modal sheet in the skeuomorphic language: a raised panel that slides up
/// over the page, with a recessed grabber at the top so it reads as something
/// you can pull.
///
/// [maxHeightFactor] caps the sheet at a fraction of the screen; the sheet is
/// otherwise as tall as its content. Pass the sheet's own content — the
/// keyboard inset is handled here.
class SkeuBottomSheet extends StatelessWidget {
  const SkeuBottomSheet({
    required this.child,
    this.maxHeightFactor = .9,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 24),
    this.showGrabber = true,
    super.key,
  });

  final Widget child;
  final double maxHeightFactor;
  final EdgeInsetsGeometry padding;
  final bool showGrabber;

  @override
  Widget build(BuildContext context) {
    const br = BorderRadius.vertical(top: Radius.circular(SkeuRadius.xxxl));
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: SkeuSurfaces.card,
          borderRadius: br,
          boxShadow: [
            BoxShadow(
              color: Color(0x660A1C5D),
              offset: Offset(0, -12),
              blurRadius: 34,
              spreadRadius: -12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: br,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: SkeuInsetPainter(SkeuElevation.bevelTop, br),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showGrabber)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: SkeuWell(
                          width: 44,
                          height: 5,
                          radius: SkeuRadius.pill,
                          gradient: SkeuSurfaces.sunken,
                          insets: SkeuElevation.wellSm,
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    Flexible(
                      child: Padding(padding: padding, child: child),
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

/// The 1px hairline rule used between rows and under section headings.
class SkeuDivider extends StatelessWidget {
  const SkeuDivider({this.margin = EdgeInsets.zero, super.key});

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, margin: margin, color: SkeuColors.borderHairline);
}

/// The brand rail: pink -> sun -> teal -> green, the logo's own colour order.
/// Used as a short accent bar at the top of a sheet, or as a full-width
/// hairline under a header.
class SkeuBrandRail extends StatelessWidget {
  const SkeuBrandRail({this.width = 64, this.height = 3, super.key});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      gradient: SkeuSurfaces.railBrand,
      borderRadius: BorderRadius.circular(SkeuRadius.pill),
    ),
  );
}

/// A soft coloured bloom — the out-of-focus light behind the navy sign-in rail.
class SkeuBloom extends StatelessWidget {
  const SkeuBloom({
    required this.color,
    required this.size,
    this.blur = SkeuSurfaces.blurBloom,
    super.key,
  });

  final Color color;
  final double size;
  final double blur;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    // A radial fade rather than a blurred solid: it gives the same 48px CSS
    // bloom without a backdrop filter, and it stays cheap on a scrolling page.
    child: Container(
      width: size * 2,
      height: size * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [.22, 1],
        ),
      ),
    ),
  );
}

/// Shared press feedback: the object sinks 2px and dims a touch. Every tappable
/// skeuomorphic surface uses it so pressing anything feels like pressing the
/// same material.
class _SkeuPressable extends StatefulWidget {
  const _SkeuPressable({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_SkeuPressable> createState() => _SkeuPressableState();
}

class _SkeuPressableState extends State<_SkeuPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _down = true),
    onTapUp: (_) => setState(() => _down = false),
    onTapCancel: () => setState(() => _down = false),
    onTap: widget.onTap,
    child: AnimatedSlide(
      offset: _down ? const Offset(0, .012) : Offset.zero,
      duration: SkeuMotion.press,
      child: AnimatedScale(
        scale: _down ? .985 : 1,
        duration: SkeuMotion.press,
        child: widget.child,
      ),
    ),
  );
}
