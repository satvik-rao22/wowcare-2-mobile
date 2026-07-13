import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_toggle.dart';

/// Standard header row shared by every dashboard card: a title, an optional
/// "open full screen" redirect arrow, and the collapse/expand toggle.
class DashboardCardHeader extends StatelessWidget {
  const DashboardCardHeader({
    super.key,
    required this.title,
    required this.minimized,
    required this.onToggle,
    this.showRedirect = false,
    this.onRedirect,
    this.trailing,
  });

  final String title;
  final bool minimized;
  final VoidCallback onToggle;

  /// Shows the gradient redirect arrow next to the title.
  final bool showRedirect;
  final VoidCallback? onRedirect;

  /// Optional extra widget placed just before the collapse toggle.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // No ellipsis — the full card heading must always be visible, so the
        // title keeps its natural width and the trailing area yields instead.
        Text(
          title,
          softWrap: false,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
        ),
        if (showRedirect) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRedirect,
            behavior: HitTestBehavior.opaque,
            child: SvgPicture.asset(
              MediaRes.redirectArrowGradientIcon,
              width: 16,
              height: 16,
            ),
          ),
        ],
        // Remaining space: trailing widget + the toggle, pinned to the right.
        // `trailing` is placed directly (no Flexible wrapper) so a card may
        // pass an `Expanded`/`Flexible` itself without competing parent data.
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
              DashboardCardToggle(minimized: minimized, onTap: onToggle),
            ],
          ),
        ),
      ],
    );
  }
}
