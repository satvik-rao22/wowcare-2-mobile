import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// "↓ New Messages" chip shown above the input bar when a new message
/// arrives while the user is reading older history, instead of forcing a
/// jump to the bottom of the conversation.
class NewMessagesIndicator extends StatelessWidget {
  const NewMessagesIndicator({
    super.key,
    required this.visible,
    required this.onTap,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      offset: visible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: onTap,
                child: SkeuKeyBox(
                  variant: KeyVariant.primary,
                  radius: AppRadius.pill,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.messagingOnAccent,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        AppStrings.newMessagesLabel,
                        style: AppTextStyles.size14.copyWith(
                          color: AppColors.messagingOnAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
