import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

/// Vertical action panel for a parent/guardian card in the student profile
/// Family tab, opened from the card's three-dot button.
///
/// Mirrors `BillingStudentVerticalPopUp` (gradient column + close pill) so the
/// two action surfaces read as the same component. Admin-only: the host gates
/// on the ADMIN persona before showing the three-dot trigger at all, so this
/// widget itself carries no permission logic.
class GuardianActionPanel extends StatelessWidget {
  const GuardianActionPanel({
    super.key,
    this.onEditTap,
    this.onDeleteTap,
    this.onResendInviteTap,
    this.onChangePinTap,
    this.onClose,
  });

  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onResendInviteTap;
  final VoidCallback? onChangePinTap;
  final VoidCallback? onClose;

  /// Opens the panel as a right-aligned, transparent-barrier dialog and
  /// resolves once it is dismissed. Each callback dismisses the panel first,
  /// then runs on the next frame so the action's own navigation/bottom sheet
  /// is not torn down with the dialog.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onResendInvite,
    VoidCallback? onChangePin,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.transparentColor,
      builder: (dialogContext) {
        VoidCallback? wrap(VoidCallback? action) {
          if (action == null) return null;
          return () {
            Navigator.of(dialogContext).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) => action());
          };
        }

        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GuardianActionPanel(
              onEditTap: wrap(onEdit),
              onDeleteTap: wrap(onDelete),
              onResendInviteTap: wrap(onResendInvite),
              onChangePinTap: wrap(onChangePin),
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <_GuardianActionConfig>[
      // Edit + Delete temporarily hidden: the card already carries both as
      // inline buttons, so offering them here too read as redundant. The
      // [onEditTap] / [onDeleteTap] callbacks and their host wiring are left
      // intact, so restoring these is just an uncomment.
      // _GuardianActionConfig(
      //   iconPath: MediaRes.communicationIcon,
      //   label: StudentStrings.edit,
      //   onTap: onEditTap,
      // ),
      // _GuardianActionConfig(
      //   iconPath: MediaRes.delete_icon,
      //   label: StudentStrings.delete,
      //   onTap: onDeleteTap,
      // ),
      _GuardianActionConfig(
        iconPath: MediaRes.redirectArrowGradientIcon,
        label: StudentStrings.resendInvite,
        onTap: onResendInviteTap,
        // This SVG fills its viewBox; shrink it to match the others.
        iconSize: AppSpacing.s19,
      ),
      _GuardianActionConfig(
        iconPath: MediaRes.pinMethodIcon,
        label: StudentStrings.changePin,
        onTap: onChangePinTap,
      ),
    ];

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Material(
          borderRadius: BorderRadius.circular(AppRadius.r10),
          elevation: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < actions.length; i++) ...<Widget>[
                  _GuardianActionButton(
                    iconPath: actions[i].iconPath,
                    iconSize: actions[i].iconSize,
                    label: actions[i].label,
                    onTap: actions[i].onTap,
                  ),
                  if (i != actions.length - 1) AppSpacing.gapVLg,
                ],
                AppSpacing.gapVXs,
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, 15),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.studentAccentPurple,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: AppColors.transparentColor,
              child: InkWell(
                onTap: onClose,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.s10),
                  child: Icon(
                    Icons.close,
                    color: AppColors.whiteColor,
                    size: AppSpacing.lg,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuardianActionConfig {
  const _GuardianActionConfig({
    required this.iconPath,
    required this.label,
    this.onTap,
    this.iconSize = AppSpacing.xl,
  });

  final String iconPath;
  final String label;
  final VoidCallback? onTap;

  /// Per-icon glyph size. Some SVGs fill their viewBox edge-to-edge and read as
  /// oversized at 24; override to keep them visually consistent. All icons keep
  /// the same 24×24 footprint regardless.
  final double iconSize;
}

class _GuardianActionButton extends StatelessWidget {
  const _GuardianActionButton({
    required this.iconPath,
    required this.label,
    this.onTap,
    this.iconSize = AppSpacing.xl,
  });

  final String iconPath;
  final String label;
  final VoidCallback? onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed 24×24 footprint so every label sits on the same baseline,
              // while the glyph itself can be sized per icon.
              SizedBox(
                height: AppSpacing.xl,
                width: AppSpacing.xl,
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    height: iconSize,
                    width: iconSize,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      AppColors.whiteColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              AppSpacing.gapVXxs,
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.guardianActionPanelLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
