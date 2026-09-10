import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// App-wide dark ("blackish") tooltip used for disabled-action hints and
/// other short explanations.
///
/// - Tap to reveal (mobile has no hover), held visible a few seconds.
/// - When [message] is empty/blank it adds nothing and simply returns [child],
///   so callers can wrap a widget unconditionally and only pass a message when
///   there is actually something to explain.
class AppTooltip extends StatelessWidget {
  const AppTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = false,
  });

  final String message;
  final Widget child;
  final bool preferBelow;

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return child;
    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE6232323), // blackish, ~90% opaque
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: AppColors.whiteColor,
        fontSize: 12,
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w500,
      ),
      child: child,
    );
  }
}
