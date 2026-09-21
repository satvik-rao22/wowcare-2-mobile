import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';

/// Friendly empty placeholder shown when a filter yields no days.
class Av2EmptyState extends StatelessWidget {
  const Av2EmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Av2Spacing.md,
        vertical: Av2Spacing.xl,
      ),
      decoration: BoxDecoration(
        color: Av2Colors.surface,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
        border: Border.all(color: Av2Colors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy_outlined,
              size: 28, color: Av2Colors.textTertiary),
          const SizedBox(height: Av2Spacing.xs),
          Text(
            message,
            style: Av2Text.label,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
