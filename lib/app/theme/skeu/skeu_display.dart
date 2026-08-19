import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'skeu_inner_shadow.dart';
import 'skeu_surface.dart';
import 'skeu_tokens.dart';

/// The ChildcareWow mark — the two children under a green ground arc, in the
/// logo's own four colours.
class SkeuLogoMark extends StatelessWidget {
  const SkeuLogoMark({this.size = 96, super.key});

  static const asset = 'assets/vectors/wow_mark.svg';

  final double size;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.asset(asset, height: size, fit: BoxFit.contain);
}

/// The WowCare wordmark: pink W, sun o, teal w, then "Care" in the surrounding
/// ink (white on the navy rail, navy on a light page).
class WowCareWordmark extends StatelessWidget {
  const WowCareWordmark({
    this.fontSize = 28,
    this.careColor = SkeuColors.ink,
    super.key,
  });

  final double fontSize;
  final Color careColor;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: SkeuText.family,
      fontSize: fontSize,
      fontWeight: SkeuText.weightBold,
      height: 1.15,
      letterSpacing: fontSize * SkeuText.trackingHeading,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(
            text: 'W',
            style: TextStyle(color: SkeuColors.pink500),
          ),
          const TextSpan(text: 'o', style: TextStyle(color: SkeuColors.sun400)),
          const TextSpan(text: 'w', style: TextStyle(color: SkeuColors.teal500)),
          TextSpan(text: 'Care', style: TextStyle(color: careColor)),
        ],
      ),
    );
  }
}

/// The mark and wordmark stacked, with the brand tagline — the sign-in lockup.
class SkeuBrandLockup extends StatelessWidget {
  const SkeuBrandLockup({
    this.markSize = 96,
    this.fontSize = 28,
    this.careColor = SkeuColors.white,
    this.tagline,
    this.taglineColor = SkeuColors.teal100,
    super.key,
  });

  final double markSize;
  final double fontSize;
  final Color careColor;
  final String? tagline;
  final Color taglineColor;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SkeuLogoMark(size: markSize),
      const SizedBox(height: 14),
      WowCareWordmark(fontSize: fontSize, careColor: careColor),
      if (tagline != null) ...[
        const SizedBox(height: 14),
        Text(
          tagline!,
          style: SkeuText.small(
            color: taglineColor,
            weight: SkeuText.weightHeading,
          ).copyWith(letterSpacing: .26),
        ),
      ],
    ],
  );
}

/// The palette a soft, tinted surface can be washed in. Each tone carries a
/// meaning: [ok] for in-ratio/present/paid, [warn] for pending, [bad] for
/// overdue/absent, [info] for structure, [neutral] for "nothing to report".
enum SkeuTone { ok, warn, bad, info, sun, pink, purple, orange, neutral }

/// The gradient / ink pair for a [SkeuTone].
({Gradient surface, Color ink}) skeuToneSkin(SkeuTone tone) => switch (tone) {
  SkeuTone.ok => (surface: SkeuSurfaces.greenSoft, ink: SkeuColors.green700),
  SkeuTone.warn => (surface: SkeuSurfaces.sunSoft, ink: SkeuColors.sun700),
  SkeuTone.bad => (
    surface: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFF7F6), SkeuColors.danger100],
    ),
    ink: SkeuColors.danger600,
  ),
  SkeuTone.info => (surface: SkeuSurfaces.tealSoft, ink: SkeuColors.teal700),
  SkeuTone.sun => (surface: SkeuSurfaces.sunSoft, ink: SkeuColors.sun700),
  SkeuTone.pink => (surface: SkeuSurfaces.pinkSoft, ink: SkeuColors.pink700),
  SkeuTone.purple => (
    surface: SkeuSurfaces.purpleSoft,
    ink: SkeuColors.purple500,
  ),
  SkeuTone.orange => (
    surface: SkeuSurfaces.orangeSoft,
    ink: SkeuColors.orange600,
  ),
  SkeuTone.neutral => (surface: SkeuSurfaces.sunken, ink: SkeuColors.inkSoft),
};

/// A status badge: a soft tinted plate with a lit bevel, carrying a short
/// state word. Squared corners for table-dense contexts, pill for row ends.
class SkeuStatusChip extends StatelessWidget {
  const SkeuStatusChip({
    required this.label,
    this.tone = SkeuTone.info,
    this.icon,
    this.pill = true,
    this.fontSize = 11,
    this.onTap,
    super.key,
  });

  final String label;
  final SkeuTone tone;
  final IconData? icon;
  final bool pill;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final skin = skeuToneSkin(tone);
    final radius = pill ? SkeuRadius.pill : 8.0;
    Widget chip = SkeuPanel(
      gradient: skin.surface,
      radius: radius,
      shadows: const [],
      padding: EdgeInsets.symmetric(
        horizontal: pill ? 11 : 10,
        vertical: pill ? 6 : 5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: SkeuText.family,
              fontSize: fontSize,
              fontWeight: SkeuText.weightBold,
              color: skin.ink,
              height: 1.25,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 5),
            Icon(icon, size: fontSize + 2, color: skin.ink),
          ],
        ],
      ),
    );
    if (onTap != null) {
      chip = GestureDetector(onTap: onTap, child: chip);
    }
    return chip;
  }
}

/// A filter / selection chip. Unselected chips are quiet wells; the selected
/// one becomes a raised teal-faced key, so the choice reads as a pressed
/// button that stayed down.
class SkeuFilterChip extends StatelessWidget {
  const SkeuFilterChip({
    required this.label,
    this.selected = false,
    this.onTap,
    this.count,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 15,
            color: selected ? SkeuColors.white : SkeuColors.inkSoft,
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: SkeuText.body(
            color: selected ? SkeuColors.white : SkeuColors.ink,
            weight: SkeuText.weightHeading,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Text(
            '$count',
            style: SkeuText.caption(
              color: selected
                  ? SkeuColors.white.withValues(alpha: .85)
                  : SkeuColors.inkFaint,
              weight: SkeuText.weightBold,
            ),
          ),
        ],
      ],
    );

    if (selected) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            gradient: SkeuSurfaces.faceTeal,
            borderRadius: BorderRadius.circular(SkeuRadius.pill),
            boxShadow: const [
              BoxShadow(color: SkeuElevation.rimTeal, offset: Offset(0, 2)),
            ],
          ),
          child: content,
        ),
      );
    }
    return SkeuWell(
      radius: SkeuRadius.pill,
      insets: SkeuElevation.wellSm,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      child: content,
    );
  }
}

/// A monogram bead: initials on a soft tinted disc, or a photo when there is
/// one. Every person in the app is represented by one of these.
class SkeuAvatar extends StatelessWidget {
  const SkeuAvatar({
    this.name,
    this.imageUrl,
    this.size = 44,
    this.tone = SkeuTone.info,
    this.fontSize,
    this.ring = false,
    this.raised = true,
    super.key,
  });

  final String? name;
  final String? imageUrl;
  final double size;
  final SkeuTone tone;
  final double? fontSize;

  /// Draws the 1.5px teal rim used on the dashboard's summary beads.
  final bool ring;
  final bool raised;

  String get _initials {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final skin = skeuToneSkin(tone);
    final br = BorderRadius.circular(size);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: skin.surface,
        shape: BoxShape.circle,
        boxShadow: raised ? SkeuElevation.elev1 : null,
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _monogram(skin.ink),
              )
            else
              _monogram(skin.ink),
            IgnorePointer(
              child: CustomPaint(
                painter: SkeuInsetPainter([
                  ...SkeuElevation.bevelFull,
                  if (ring)
                    const SkeuInset(color: SkeuColors.teal500, spread: 1.5),
                ], br),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monogram(Color ink) => Center(
    child: Text(
      _initials,
      style: TextStyle(
        fontFamily: SkeuText.family,
        fontSize: fontSize ?? size * .32,
        fontWeight: SkeuText.weightBold,
        color: ink,
      ),
    ),
  );
}

/// The bead frame without the monogram — wraps an existing avatar widget (one
/// that resolves a real profile photo) in the same tinted disc, lit bevel and
/// soft lift that [SkeuAvatar] draws, so photo and monogram avatars sit at the
/// same depth beside each other.
class SkeuAvatarFrame extends StatelessWidget {
  const SkeuAvatarFrame({
    required this.child,
    this.size = 44,
    this.tone = SkeuTone.info,
    this.ring = false,
    super.key,
  });

  final Widget child;
  final double size;
  final SkeuTone tone;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final skin = skeuToneSkin(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: skin.surface,
        shape: BoxShape.circle,
        boxShadow: SkeuElevation.elev1,
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: child),
            IgnorePointer(
              child: CustomPaint(
                painter: SkeuInsetPainter([
                  ...SkeuElevation.bevelFull,
                  if (ring)
                    const SkeuInset(color: SkeuColors.teal500, spread: 1.5),
                ], BorderRadius.circular(size)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small tinted plate holding one glyph — the leading square on a list row.
class SkeuIconTile extends StatelessWidget {
  const SkeuIconTile({
    required this.icon,
    this.tone = SkeuTone.info,
    this.size = 38,
    this.iconSize,
    this.radius,
    this.recessed = false,
    super.key,
  });

  final IconData icon;
  final SkeuTone tone;
  final double size;
  final double? iconSize;
  final double? radius;

  /// Sinks the plate into the surface instead of raising it — used where the
  /// glyph is a label rather than an affordance.
  final bool recessed;

  @override
  Widget build(BuildContext context) {
    final skin = skeuToneSkin(tone);
    final r = radius ?? size * .32;
    final child = Center(
      child: Icon(icon, size: iconSize ?? size * .5, color: skin.ink),
    );
    if (recessed) {
      return SkeuWell(
        width: size,
        height: size,
        radius: r,
        gradient: skin.surface,
        insets: SkeuElevation.wellSm,
        child: child,
      );
    }
    return SkeuPanel(
      width: size,
      height: size,
      radius: r,
      gradient: skin.surface,
      shadows: const [],
      child: child,
    );
  }
}

/// A count tile: a big teal number with its label, over an optional status
/// badge or legend. The dashboard's "Need your attention" grid is built of
/// these.
class SkeuStatTile extends StatelessWidget {
  const SkeuStatTile({
    required this.value,
    required this.label,
    this.sublabel,
    this.footer,
    this.legend = const [],
    this.valueColor = SkeuColors.teal600,
    this.onTap,
    super.key,
  });

  final String value;
  final String label;

  /// A parenthetical qualifier printed inline after [label], e.g. "(This
  /// Month)".
  final String? sublabel;

  /// Normally a [SkeuStatusChip].
  final Widget? footer;

  /// Dotted breakdown rows, e.g. "Overdue (3)".
  final List<SkeuLegendEntry> legend;

  final Color valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SkeuPanel(
    radius: 18,
    padding: const EdgeInsets.all(14),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: SkeuText.family,
                fontSize: 26,
                fontWeight: SkeuText.weightBold,
                height: 1,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  style: SkeuText.body(weight: SkeuText.weightHeading)
                      .copyWith(height: 1.25),
                  children: sublabel == null
                      ? null
                      : [
                          TextSpan(
                            text: ' $sublabel',
                            style: SkeuText.meta(
                              color: SkeuColors.ink.withValues(alpha: .55),
                            ),
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
        if (footer != null) ...[
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: footer!),
        ],
        if (legend.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final entry in legend)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: entry,
            ),
        ],
      ],
    ),
  );
}

/// One dotted breakdown row inside a [SkeuStatTile] or a chart legend.
class SkeuLegendEntry extends StatelessWidget {
  const SkeuLegendEntry({
    required this.label,
    required this.color,
    this.dotSize = 8,
    super.key,
  });

  final String label;
  final Color color;
  final double dotSize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          label,
          style: SkeuText.caption(
            color: SkeuColors.ink.withValues(alpha: .8),
          ),
        ),
      ),
    ],
  );
}

/// A compact metric: a small label above a big coloured figure, on a raised
/// plate. Used in pairs and triples inside a section card.
class SkeuMetricTile extends StatelessWidget {
  const SkeuMetricTile({
    required this.label,
    required this.value,
    this.valueColor = SkeuColors.teal700,
    this.centered = false,
    this.tone,
    super.key,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool centered;

  /// When set, the plate is washed in the tone and the figure takes the tone's
  /// ink — the "Present / Absent / Signed out / Not marked" quad.
  final SkeuTone? tone;

  @override
  Widget build(BuildContext context) {
    final skin = tone == null ? null : skeuToneSkin(tone!);
    return SkeuPanel(
      radius: tone == null ? 16 : 13,
      gradient: skin?.surface ?? SkeuSurfaces.raised,
      shadows: tone == null ? SkeuElevation.elev1 : const [],
      padding: tone == null
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      child: Column(
        crossAxisAlignment: centered || tone != null
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: tone == null
            ? [
                Text(
                  label,
                  textAlign: centered ? TextAlign.center : TextAlign.start,
                  style: SkeuText.meta(
                    color: SkeuColors.inkSoft,
                  ).copyWith(fontWeight: SkeuText.weightHeading, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: SkeuText.family,
                    fontSize: 19,
                    fontWeight: SkeuText.weightBold,
                    color: valueColor,
                  ),
                ),
              ]
            : [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: SkeuText.family,
                    fontSize: 17,
                    fontWeight: SkeuText.weightBold,
                    color: skin!.ink,
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: SkeuText.family,
                    fontSize: 10,
                    fontWeight: SkeuText.weightHeading,
                    color: skin.ink,
                  ),
                ),
              ],
      ),
    );
  }
}

/// A progress trough: a recessed track with a raised coloured fill.
class SkeuProgressBar extends StatelessWidget {
  const SkeuProgressBar({
    required this.value,
    this.height = 12,
    this.fill = SkeuSurfaces.faceGreen,
    this.fillColor,
    super.key,
  });

  /// 0..1, clamped.
  final double value;
  final double height;
  final Gradient fill;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) => SkeuWell(
    radius: SkeuRadius.pill,
    height: height,
    gradient: SkeuSurfaces.sunken,
    insets: SkeuElevation.wellSm,
    child: Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            gradient: fillColor == null ? fill : null,
            color: fillColor,
            borderRadius: BorderRadius.circular(SkeuRadius.pill),
          ),
        ),
      ),
    ),
  );
}

/// One band of a [SkeuSegmentBar].
@immutable
class SkeuSegment {
  const SkeuSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;

  /// Relative weight, not a percentage — the bar normalises across segments.
  final num value;
  final Color color;
}

/// A proportional bar: one recessed trough divided into coloured bands, with a
/// dotted legend under it.
///
/// This is how the design shows a total broken into states — enrolled vs
/// upcoming, signed-in vs absent vs signed-out vs not-marked. The trough is
/// recessed and the bands sit flush inside it, so the whole thing reads as one
/// gauge rather than a row of chips.
class SkeuSegmentBar extends StatelessWidget {
  const SkeuSegmentBar({
    required this.segments,
    this.height = 22,
    this.radius = 9,
    this.legendColumns = 2,
    this.showLegend = true,
    super.key,
  });

  final List<SkeuSegment> segments;
  final double height;
  final double radius;

  /// 2 for the four-state breakdowns, 0 to lay the legend out in one row.
  final int legendColumns;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((s) => s.value > 0).toList();
    final br = BorderRadius.circular(radius);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeuWell(
          height: height,
          borderRadius: br,
          gradient: SkeuSurfaces.sunken,
          insets: SkeuElevation.wellSm,
          child: visible.isEmpty
              ? const SizedBox.shrink()
              : Row(
                  children: [
                    for (final s in visible)
                      Expanded(
                        flex: (s.value * 100).round().clamp(1, 1 << 30),
                        child: ColoredBox(color: s.color),
                      ),
                  ],
                ),
        ),
        if (showLegend && segments.isNotEmpty) ...[
          const SizedBox(height: 10),
          if (legendColumns <= 1)
            Row(
              children: [
                for (final s in segments)
                  Expanded(
                    child: SkeuLegendEntry(
                      label: s.label,
                      color: s.color,
                      dotSize: 10,
                    ),
                  ),
              ],
            )
          else
            for (var i = 0; i < segments.length; i += legendColumns)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i + legendColumns < segments.length ? 8 : 0,
                ),
                child: Row(
                  children: [
                    for (var c = 0; c < legendColumns; c++)
                      Expanded(
                        child: i + c < segments.length
                            ? SkeuLegendEntry(
                                label: segments[i + c].label,
                                color: segments[i + c].color,
                                dotSize: 10,
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
        ],
      ],
    );
  }
}

/// A "total, broken down" card: the headline figure on the left, the
/// proportional bar and its legend filling the rest.
class SkeuTotalCard extends StatelessWidget {
  const SkeuTotalCard({
    required this.label,
    required this.total,
    required this.segments,
    this.legendColumns = 2,
    this.onTap,
    super.key,
  });

  /// Rendered on two lines, as in the design ("Total\nStudents").
  final String label;
  final String total;
  final List<SkeuSegment> segments;
  final int legendColumns;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SkeuPanel(
    radius: 22,
    padding: const EdgeInsets.all(16),
    onTap: onTap,
    child: Row(
      children: [
        SizedBox(
          width: 76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: SkeuText.small().copyWith(height: 1.3),
              ),
              const SizedBox(height: 2),
              Text(
                total,
                style: TextStyle(
                  fontFamily: SkeuText.family,
                  fontSize: 30,
                  fontWeight: SkeuText.weightBold,
                  color: SkeuColors.ink,
                  letterSpacing: 30 * -0.02,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SkeuSegmentBar(
            segments: segments,
            legendColumns: legendColumns,
          ),
        ),
      ],
    ),
  );
}

/// A labelled progress row: dot, name, figure, percentage, then the trough.
/// The Billing card is three of these stacked.
class SkeuProgressRow extends StatelessWidget {
  const SkeuProgressRow({
    required this.label,
    required this.value,
    required this.amount,
    required this.color,
    this.fill,
    super.key,
  });

  final String label;

  /// 0..1.
  final double value;
  final String amount;
  final Color color;
  final Gradient? fill;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: SkeuText.small(
                color: SkeuColors.ink,
                weight: SkeuText.weightHeading,
              ),
            ),
          ),
          Text(
            amount,
            style: SkeuText.small(
              color: SkeuColors.ink,
              weight: SkeuText.weightBold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(value * 100).round()}%',
            style: SkeuText.caption(weight: SkeuText.weightHeading),
          ),
        ],
      ),
      const SizedBox(height: 6),
      SkeuProgressBar(
        value: value,
        height: 9,
        fill: fill ?? SkeuSurfaces.faceGreen,
        fillColor: fill == null ? color : null,
      ),
    ],
  );
}

/// The empty state: a recessed disc holding a glyph, a line of explanation,
/// and optionally one action. Deliberately quiet — nothing to press but the
/// one thing worth pressing.
class SkeuEmptyState extends StatelessWidget {
  const SkeuEmptyState({
    required this.message,
    this.icon = Icons.inbox_rounded,
    this.title,
    this.action,
    this.tone = SkeuTone.neutral,
    super.key,
  });

  final String message;
  final IconData icon;
  final String? title;
  final Widget? action;
  final SkeuTone tone;

  @override
  Widget build(BuildContext context) {
    final skin = skeuToneSkin(tone);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeuWell(
              width: 78,
              height: 78,
              radius: SkeuRadius.pill,
              gradient: skin.surface,
              insets: SkeuElevation.wellLg,
              child: Center(child: Icon(icon, size: 32, color: skin.ink)),
            ),
            const SizedBox(height: 18),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: SkeuText.title(),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: SkeuText.prose(),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// A key/value row for detail panels: muted label on the left, value right.
class SkeuDetailRow extends StatelessWidget {
  const SkeuDetailRow({
    required this.label,
    required this.value,
    this.icon,
    this.valueWidget,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: SkeuColors.teal600),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 4,
          child: Text(label, style: SkeuText.caption(weight: SkeuText.weightHeading)),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: valueWidget ??
              Text(
                value,
                textAlign: TextAlign.end,
                style: SkeuText.body(weight: SkeuText.weightHeading),
              ),
        ),
      ],
    ),
  );
}
