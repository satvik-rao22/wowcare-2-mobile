import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

/// Reusable collapsible section with a tappable header and an animated body.
///
/// Used by the Events and Tasks modules for the "completed" archive lists and
/// the holidays sections. When [maxBodyHeight] is set the expanded body
/// scrolls internally so the section can sit alongside another scroll view
/// (e.g. above an `Expanded` list) without overflowing.
class ExpandableSection extends StatefulWidget {
  const ExpandableSection({
    required this.title,
    required this.child,
    this.count,
    this.icon,
    this.accentColor,
    this.initiallyExpanded = false,
    this.maxBodyHeight,
    super.key,
  });

  final String title;
  final Widget child;

  /// Optional count shown as a small pill next to the title.
  final int? count;
  final IconData? icon;
  final Color? accentColor;
  final bool initiallyExpanded;

  /// When set, the expanded body is capped to this height and scrolls
  /// internally instead of growing the parent.
  final double? maxBodyHeight;

  @override
  State<ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<ExpandableSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.primaryColor;
    Widget body = widget.child;
    if (widget.maxBodyHeight != null) {
      body = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxBodyHeight!),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: body,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, size: 15, color: accent),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ),
                  if (widget.count != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(Icons.expand_more, size: 22, color: accent),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: body,
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}
