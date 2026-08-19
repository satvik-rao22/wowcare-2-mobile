import 'package:flutter/material.dart';

import 'skeu_display.dart';
import 'skeu_inner_shadow.dart';
import 'skeu_surface.dart';
import 'skeu_tokens.dart';

/// The app's navy header rail.
///
/// A single slab of `--surface-rail` (navy fading into teal) carrying the
/// drawer key, the brand lockup and the notification keys, closed off by a 3px
/// brand rail. It is the one dark surface in the app, so everything below it
/// reads as lit from above.
class SkeuRailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SkeuRailAppBar({
    this.onMenuTap,
    this.actions = const [],
    this.title,
    this.leading,
    this.centerTitle = false,
    this.showBrand = true,
    this.bottom,
    super.key,
  });

  final VoidCallback? onMenuTap;

  /// Normally [SkeuRailAction]s.
  final List<Widget> actions;

  /// Replaces the brand lockup with a screen title.
  final String? title;

  /// Replaces the drawer key — pass a [SkeuRailAction] with a back arrow.
  final Widget? leading;
  final bool centerTitle;
  final bool showBrand;

  /// An extra strip below the header row and above the brand rail — a search
  /// well or a chip row that should scroll with the header rather than the body.
  final Widget? bottom;

  static const _rowHeight = 58.0;
  static const _railHeight = 3.0;

  @override
  Size get preferredSize =>
      Size.fromHeight(_rowHeight + _railHeight + (bottom == null ? 0 : 56));

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: SkeuSurfaces.rail,
      boxShadow: SkeuElevation.elev3,
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          SizedBox(
            height: _rowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  if (leading != null)
                    leading!
                  else if (onMenuTap != null)
                    SkeuRailAction(icon: Icons.menu_rounded, onTap: onMenuTap),
                  const SizedBox(width: 12),
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        textAlign: centerTitle
                            ? TextAlign.center
                            : TextAlign.start,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SkeuText.title(color: SkeuColors.white),
                      ),
                    )
                  else if (showBrand) ...[
                    const SkeuLogoMark(size: 27),
                    const SizedBox(width: 8),
                    const WowCareWordmark(
                      fontSize: 19,
                      careColor: SkeuColors.white,
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  for (final action in actions) ...[
                    action,
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          if (bottom != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: bottom!,
            ),
          const SizedBox(
            height: _railHeight,
            width: double.infinity,
            child: SkeuBrandRail(width: null, height: _railHeight),
          ),
        ],
      ),
    ),
  );
}

/// One key on the navy rail: a translucent white plate with a rimmed edge, so
/// it reads as pressed into the dark slab rather than floating on it.
class SkeuRailAction extends StatelessWidget {
  const SkeuRailAction({
    required this.icon,
    this.onTap,
    this.badgeCount,
    this.size = 38,
    this.iconSize = 20,
    this.plate = true,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int? badgeCount;
  final double size;
  final double iconSize;

  /// A plateless action (the overflow "more" glyph) is just the icon.
  final bool plate;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(13);
    Widget content = plate
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: SkeuColors.white.withValues(alpha: .14),
              borderRadius: br,
            ),
            child: ClipRRect(
              borderRadius: br,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: SkeuInsetPainter(SkeuElevation.bevelEdge, br),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(icon, size: iconSize, color: SkeuColors.white),
                  ),
                ],
              ),
            ),
          )
        : SizedBox(
            width: 30,
            height: size,
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: SkeuColors.white.withValues(alpha: .9),
              ),
            ),
          );

    if (badgeCount != null && badgeCount! > 0) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              height: 18,
              constraints: const BoxConstraints(minWidth: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SkeuColors.pink600,
                borderRadius: BorderRadius.circular(SkeuRadius.pill),
                border: Border.all(color: SkeuColors.white, width: 1.5),
              ),
              child: Text(
                badgeCount! > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  fontFamily: SkeuText.family,
                  fontSize: 10,
                  fontWeight: SkeuText.weightEyebrow,
                  color: SkeuColors.white,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Align with both factors at 1 sizes exactly to the plate, so an AppBar
    // leading / actions slot cannot stretch it to the full toolbar height.
    return Align(
      widthFactor: 1,
      heightFactor: 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// A collapsible content card — the unit every dashboard and detail screen is
/// assembled from.
///
/// The title row carries an optional "open this module" arrow and a small
/// rimmed key that folds the body away. Collapsed state is the caller's, so
/// this stays a pure view and the screen keeps owning its behaviour.
class SkeuSectionCard extends StatelessWidget {
  const SkeuSectionCard({
    required this.title,
    required this.child,
    this.expanded = true,
    this.onToggle,
    this.onTitleTap,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.gap = 14,
    super.key,
  });

  final String title;
  final Widget child;
  final bool expanded;
  final VoidCallback? onToggle;

  /// When set, the title gains the ↗ glyph and opens the full module.
  final VoidCallback? onTitleTap;

  /// Extra controls between the title and the fold key — a date stepper, say.
  final Widget? trailing;

  final EdgeInsetsGeometry padding;
  final double radius;
  final double gap;

  @override
  Widget build(BuildContext context) => SkeuPanel(
    radius: radius,
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: GestureDetector(
                onTap: onTitleTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: SkeuText.family,
                          fontSize: 18,
                          fontWeight: SkeuText.weightBold,
                          color: SkeuColors.ink,
                          letterSpacing: 18 * SkeuText.trackingHeading,
                        ),
                      ),
                    ),
                    if (onTitleTap != null) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        size: 16,
                        color: SkeuColors.ink,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (trailing != null) ...[trailing!, const SizedBox(width: 10)],
            if (onToggle != null)
              SkeuFoldKey(expanded: expanded, onTap: onToggle!),
          ],
        ),
        if (expanded) ...[SizedBox(height: gap), child],
      ],
    ),
  );
}

/// The small rimmed key that folds a [SkeuSectionCard] open and shut. 27px, a
/// 2px neutral rim, and a chevron that rotates as it goes.
class SkeuFoldKey extends StatelessWidget {
  const SkeuFoldKey({
    required this.expanded,
    required this.onTap,
    this.size = 27,
    super.key,
  });

  final bool expanded;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(9);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: SkeuSurfaces.faceNeutral,
          borderRadius: br,
          boxShadow: const [
            BoxShadow(color: SkeuElevation.rimNeutral, offset: Offset(0, 2)),
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
              Center(
                child: AnimatedRotation(
                  turns: expanded ? .5 : 0,
                  duration: SkeuMotion.quick,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 17,
                    color: SkeuColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A segmented control sunk into the card it belongs to: a recessed trough
/// holding one raised teal key per segment. Only the selected key is raised,
/// so the control shows its state as geometry, not colour alone.
class SkeuSegmentedTabs extends StatelessWidget {
  const SkeuSegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.labelWidgets = const [],
    this.height = 38,
    super.key,
  });

  final List<String> labels;

  /// Optional per-segment replacement for the plain text label — for a segment
  /// that carries a badge. Same length as [labels]; null entries fall back to
  /// the string. The text style is inherited, so a replacement can just be a
  /// [Text] in a [Row] with the badge.
  final List<Widget?> labelWidgets;

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) => SkeuWell(
    radius: SkeuRadius.lg,
    gradient: SkeuSurfaces.sunken,
    padding: const EdgeInsets.all(5),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: SkeuMotion.quick,
                curve: SkeuMotion.easeOut,
                height: height - 10,
                margin: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 4),
                decoration: BoxDecoration(
                  gradient: i == selectedIndex ? SkeuSurfaces.faceTeal : null,
                  borderRadius: BorderRadius.circular(SkeuRadius.md),
                  boxShadow: i == selectedIndex
                      ? const [
                          BoxShadow(
                            color: SkeuElevation.rimTeal,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: DefaultTextStyle.merge(
                  style: SkeuText.body(
                    color: i == selectedIndex
                        ? SkeuColors.white
                        : SkeuColors.inkSoft,
                    weight: SkeuText.weightHeading,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child:
                      (i < labelWidgets.length ? labelWidgets[i] : null) ??
                      Text(labels[i]),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// One destination in a [SkeuNavBar].
@immutable
class SkeuNavItem {
  const SkeuNavItem({required this.icon, required this.label, this.badgeCount});

  final IconData icon;
  final String label;
  final int? badgeCount;
}

/// The floating bottom navigation slab: a raised panel inset from all three
/// edges, with the current destination held down as a teal key.
class SkeuNavBar extends StatelessWidget {
  const SkeuNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<SkeuNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      8,
      0,
      8,
      8 + MediaQuery.of(context).padding.bottom * .35,
    ),
    child: SkeuPanel(
      radius: 26,
      gradient: SkeuSurfaces.raised,
      shadows: SkeuElevation.elev3,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(child: _tab(i, items[i])),
        ],
      ),
    ),
  );

  Widget _tab(int index, SkeuNavItem item) {
    final selected = index == currentIndex;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          item.icon,
          size: 21,
          color: selected ? SkeuColors.white : SkeuColors.inkSoft,
        ),
        const SizedBox(height: 3),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: SkeuText.family,
            fontSize: 10,
            fontWeight: SkeuText.weightHeading,
            color: selected ? SkeuColors.white : SkeuColors.inkSoft,
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: SkeuMotion.quick,
            curve: SkeuMotion.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            decoration: BoxDecoration(
              gradient: selected ? SkeuSurfaces.faceTeal : null,
              borderRadius: BorderRadius.circular(19),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: SkeuElevation.rimTeal,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: content,
          ),
          if ((item.badgeCount ?? 0) > 0)
            Positioned(
              top: 2,
              right: 6,
              child: Container(
                height: 17,
                constraints: const BoxConstraints(minWidth: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SkeuColors.pink600,
                  borderRadius: BorderRadius.circular(SkeuRadius.pill),
                  border: Border.all(color: SkeuColors.white, width: 1.5),
                ),
                child: Text(
                  item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                  style: const TextStyle(
                    fontFamily: SkeuText.family,
                    fontSize: 10,
                    fontWeight: SkeuText.weightEyebrow,
                    color: SkeuColors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The light-page screen header: a raised back key, a heading, a lead-in line
/// and a closing hairline. Used by every screen that is pushed rather than
/// switched to.
class SkeuPageHeader extends StatelessWidget {
  const SkeuPageHeader({
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
    this.showRule = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showRule;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(title, style: SkeuText.heading())),
          if (trailing != null) trailing!,
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(subtitle!, style: SkeuText.prose()),
      ],
      if (showRule) const SkeuDivider(margin: EdgeInsets.only(top: 14)),
    ],
  );
}

/// A person row: monogram bead, name over one line of detail, status badge at
/// the end. Students, staff, guardians and message threads all use it, so a
/// person always looks the same wherever they appear.
class SkeuPersonRow extends StatelessWidget {
  const SkeuPersonRow({
    required this.name,
    this.subtitle,
    this.imageUrl,
    this.tone = SkeuTone.info,
    this.trailing,
    this.onTap,
    this.avatarSize = 42,
    this.leading,
    super.key,
  });

  final String name;
  final String? subtitle;
  final String? imageUrl;
  final SkeuTone tone;

  /// Normally a [SkeuStatusChip].
  final Widget? trailing;
  final VoidCallback? onTap;
  final double avatarSize;

  /// Replaces the monogram bead — a checkbox in a picker, say.
  final Widget? leading;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Row(
      children: [
        leading ??
            SkeuAvatar(
              name: name,
              imageUrl: imageUrl,
              tone: tone,
              size: avatarSize,
            ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SkeuText.body(weight: SkeuText.weightHeading),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SkeuText.caption(),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    ),
  );
}

/// A note card: a soft tinted plate with a title, body and byline. Tones rotate
/// so a list of notes reads as a pinboard rather than a table.
class SkeuNoteCard extends StatelessWidget {
  const SkeuNoteCard({
    required this.title,
    required this.body,
    this.byline,
    this.tone = SkeuTone.ok,
    this.onTap,
    this.trailing,
    super.key,
  });

  final String title;
  final String body;
  final String? byline;
  final SkeuTone tone;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SkeuPanel(
    radius: 16,
    gradient: skeuToneSkin(tone).surface,
    shadows: const [],
    padding: const EdgeInsets.all(14),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: SkeuText.small(
                  color: SkeuColors.ink,
                  weight: SkeuText.weightBold,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            body,
            style: SkeuText.caption(
              color: SkeuColors.ink.withValues(alpha: .8),
            ).copyWith(height: 1.6),
          ),
        ],
        if (byline != null) ...[
          const SizedBox(height: 6),
          Text(
            byline!,
            style: SkeuText.meta().copyWith(fontWeight: SkeuText.weightHeading),
          ),
        ],
      ],
    ),
  );
}

/// A dense table: tinted header cells over raised body rows separated by
/// hairlines, the whole block clipped into one bevelled object.
class SkeuTable extends StatelessWidget {
  const SkeuTable({
    required this.columns,
    required this.rows,
    this.headerTones = const [
      SkeuTone.pink,
      SkeuTone.info,
      SkeuTone.sun,
      SkeuTone.ok,
    ],
    super.key,
  });

  final List<SkeuTableColumn> columns;
  final List<SkeuTableRow> rows;

  /// One wash per column, cycled — the design gives each column its own tint so
  /// a wide table stays readable without vertical rules.
  final List<SkeuTone> headerTones;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(16);
    return Container(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: SkeuElevation.elev1,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Column(
          children: [
            // IntrinsicHeight so every header cell's wash runs the full height
            // of the tallest one — a two-line header must not leave a stripe
            // of page showing beside a one-line neighbour.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns.length; i++)
                    Expanded(
                      flex: (columns[i].flex * 10).round(),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 58),
                        decoration: BoxDecoration(
                          gradient: skeuToneSkin(
                            headerTones[i % headerTones.length],
                          ).surface,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: i == 0
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          children: [
                            Text(
                              columns[i].label,
                              textAlign: i == 0
                                  ? TextAlign.start
                                  : TextAlign.center,
                              style: SkeuText.caption(
                                color: SkeuColors.ink,
                                weight: SkeuText.weightBold,
                              ),
                            ),
                            if (columns[i].sublabel != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                columns[i].sublabel!,
                                style: SkeuText.meta(color: SkeuColors.inkSoft),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            for (var r = 0; r < rows.length; r++) ...[
              if (r > 0) const SkeuDivider(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: rows[r].onTap,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: SkeuSurfaces.raised,
                  ),
                  child: Row(
                    children: [
                      for (var c = 0; c < columns.length; c++)
                        Expanded(
                          flex: (columns[c].flex * 10).round(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 13,
                            ),
                            child: Text(
                              rows[r].cells[c],
                              textAlign: c == 0
                                  ? TextAlign.start
                                  : TextAlign.center,
                              style: SkeuText.small(
                                color: rows[r].cellColors?[c] ?? SkeuColors.ink,
                                weight: rows[r].cellColors?[c] == null
                                    ? SkeuText.weightHeading
                                    : SkeuText.weightBold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A [SkeuTable] column: a header label, an optional qualifier under it, and a
/// share of the available width.
@immutable
class SkeuTableColumn {
  const SkeuTableColumn(this.label, {this.sublabel, this.flex = 1});

  final String label;
  final String? sublabel;
  final double flex;
}

/// A [SkeuTable] body row. [cellColors] tints individual cells — the ratio
/// column goes green when in ratio and danger when not.
@immutable
class SkeuTableRow {
  const SkeuTableRow(this.cells, {this.cellColors, this.onTap});

  final List<String> cells;
  final List<Color?>? cellColors;
  final VoidCallback? onTap;
}

/// A horizontally scrolling strip of [SkeuFilterChip]s — the classroom picker
/// at the top of the Classrooms screen.
class SkeuChipStrip extends StatelessWidget {
  const SkeuChipStrip({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: padding,
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          SkeuFilterChip(
            label: labels[i],
            selected: i == selectedIndex,
            onTap: () => onChanged(i),
          ),
        ],
      ],
    ),
  );
}
