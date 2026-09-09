import 'package:flutter/material.dart';

class InfoRowItem {
  final String label;
  final String? valueText;
  final TextStyle? valueStyle;
  final Widget? valueWidget;
  final String? noteText;
  final TextStyle? noteStyle;

  const InfoRowItem({
    required this.label,
    this.valueText,
    this.valueStyle,
    this.valueWidget,
    this.noteText,
    this.noteStyle,
  });
}

class ExpandableInfoCard extends StatefulWidget {
  final Widget? leading;
  final Widget? collapsedPrefix;
  final double collapsedPrefixSpacing;
  final String titleText;
  final TextStyle? titleStyle;
  final String? subtitleText;
  final TextStyle? subtitleStyle;
  final double collapsedHeight;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry bodyPadding;
  final bool initiallyExpanded;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final List<InfoRowItem> rows;
  final List<Widget>? actions;
  final Color cardColor;
  final BorderRadiusGeometry borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Color dividerColor;
  final double dividerIndent;
  final double dividerEndIndent;

  const ExpandableInfoCard({
    Key? key,
    this.leading,
    this.collapsedPrefix,
    this.collapsedPrefixSpacing = 12,
    required this.titleText,
    this.titleStyle,
    this.subtitleText,
    this.subtitleStyle,
    this.collapsedHeight = 64.0,
    this.headerPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.bodyPadding = const EdgeInsets.all(16),
    this.initiallyExpanded = false,
    this.onLongPress,
    this.onTap,
    required this.rows,
    this.actions,
    this.cardColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.border,
    this.boxShadow,
    this.dividerColor = const Color(0xFFE9ECEF),
    this.dividerIndent = 16,
    this.dividerEndIndent = 16,
  }) : super(key: key);

  @override
  State<ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<ExpandableInfoCard> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!.call();
    }
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            height: isExpanded ? null : widget.collapsedHeight,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: widget.cardColor,
              borderRadius: widget.borderRadius,
              border:
                  widget.border ??
                  Border.all(color: const Color(0x1A162831), width: 1),
              boxShadow:
                  widget.boxShadow ??
                  [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleTap,
                onLongPress: widget.onLongPress,
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: widget.headerPadding,
                      alignment: Alignment.center,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!isExpanded &&
                              widget.collapsedPrefix != null) ...[
                            widget.collapsedPrefix!,
                            SizedBox(width: widget.collapsedPrefixSpacing),
                          ],
                          if (widget.leading != null) widget.leading!,
                          if (widget.leading != null) const SizedBox(width: 12),
                          Expanded(
                            child: isExpanded
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        widget.titleText,
                                        style:
                                            widget.titleStyle ??
                                            const TextStyle(
                                              fontFamily: 'Manrope',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Color(0xff573353),
                                              height: 19 / 14,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (widget.subtitleText != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.subtitleText!,
                                          style:
                                              widget.subtitleStyle ??
                                              const TextStyle(
                                                fontFamily: 'Manrope',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xff573353),
                                                height: 14 / 10,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  )
                                : Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      widget.titleText,
                                      style:
                                          widget.titleStyle ??
                                          const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            color: Color(0xff573353),
                                            height: 19 / 14,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded) ...[
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: widget.dividerIndent,
                        endIndent: widget.dividerEndIndent,
                        color: widget.dividerColor,
                      ),
                      Padding(
                        padding: widget.bodyPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...widget.rows.map((row) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      row.label,
                                      style: const TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xff573353),
                                        height: 16 / 12,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (row.valueWidget != null)
                                          row.valueWidget!
                                        else
                                          Text(
                                            row.valueText ?? '',
                                            style:
                                                row.valueStyle ??
                                                const TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xff573353),
                                                ),
                                          ),
                                        if (row.noteText != null)
                                          Text(
                                            row.noteText!,
                                            style:
                                                row.noteStyle ??
                                                const TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xff573353),
                                                  height: 14 / 10,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            if (widget.actions != null &&
                                widget.actions!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  for (
                                    int i = 0;
                                    i < widget.actions!.length;
                                    i++
                                  ) ...[
                                    Expanded(child: widget.actions![i]),
                                    if (i != widget.actions!.length - 1)
                                      const SizedBox(width: 12),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
