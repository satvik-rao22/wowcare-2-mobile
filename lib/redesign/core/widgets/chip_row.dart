import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';

/// A horizontal run of chips that scrolls past the gutters (4a, 5a, 7a).
///
/// The row is padded by the screen gutter so the first chip lines up with
/// the cards below, while the scroll runs edge to edge.
class ChipRow extends StatelessWidget {
  const ChipRow({
    required this.children,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSizes.screenGutter,
    ),
    super.key,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: padding,
    clipBehavior: Clip.none,
    child: Row(spacing: AppSizes.chipGap, children: children),
  );
}
