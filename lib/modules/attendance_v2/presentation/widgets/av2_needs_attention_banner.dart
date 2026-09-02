import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';

/// Subtle amber banner shown in the hero card when one or more days have an
/// auto-closed / open session. Tapping jumps to the Needs-attention filter.
class Av2NeedsAttentionBanner extends StatelessWidget {
  const Av2NeedsAttentionBanner({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayWord = count == 1 ? 'day needs' : 'days need';
    return Material(
      color: Av2Colors.overtimeFill,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Av2Colors.overtime,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$count $dayWord attention — auto signed-out',
                  style: Av2Text.caption.copyWith(color: Av2Colors.overtime),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: Av2Colors.overtime,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
