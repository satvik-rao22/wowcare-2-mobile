import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

import '../../domain/entities/missed_signout.dart';

/// What the staff chose in the gate.
enum RegGateAction { confirmSoftTime, raise, skip }

/// The next-day "finish yesterday first" pop-up. Shown when a staff opens the
/// app / tries to sign in with an unresolved soft sign-out. When [mandatory],
/// it can't be dismissed without an action.
Future<RegGateAction?> showRegGateDialog(
  BuildContext context, {
  required MissedSignout item,
  required bool mandatory,
}) {
  return showDialog<RegGateAction>(
    context: context,
    barrierDismissible: !mandatory,
    builder: (context) => _RegGateDialog(item: item, mandatory: mandatory),
  );
}

class _RegGateDialog extends StatelessWidget {
  const _RegGateDialog({required this.item, required this.mandatory});

  final MissedSignout item;
  final bool mandatory;

  @override
  Widget build(BuildContext context) {
    final soft = Av2DateFormatter.compactTime(item.softSignOutAt);
    return PopScope(
      canPop: !mandatory,
      child: Dialog(
        backgroundColor: Av2Colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Av2Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Av2Colors.overtimeFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline,
                        size: 20, color: Av2Colors.overtime),
                  ),
                  const SizedBox(width: Av2Spacing.sm),
                  Expanded(
                    child: Text('Finish yesterday first', style: Av2Text.title),
                  ),
                ],
              ),
              const SizedBox(height: Av2Spacing.sm),
              Text(
                "You didn't sign out on ${Av2DateFormatter.monthDay(item.attendanceDate)}. "
                "We marked you out at $soft. Confirm or correct it before signing in.",
                style: Av2Text.body.copyWith(color: Av2Colors.textSecondary),
              ),
              const SizedBox(height: Av2Spacing.lg),
              _primary('I left at $soft',
                  () => Navigator.pop(context, RegGateAction.confirmSoftTime)),
              const SizedBox(height: Av2Spacing.xs),
              _secondary('I left at a different time',
                  () => Navigator.pop(context, RegGateAction.raise)),
              if (!mandatory) ...[
                const SizedBox(height: Av2Spacing.xs),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, RegGateAction.skip),
                    child: Text('Skip for now',
                        style: Av2Text.label.copyWith(color: Av2Colors.textSecondary)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _primary(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
        child: Ink(
          height: 46,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: Av2Colors.primaryGradient,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          ),
          child: Center(
            child: Text(label,
                style: Av2Text.bodyMedium.copyWith(color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _secondary(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Av2Colors.borderStrong),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
          ),
        ),
        child: Text(label,
            style: Av2Text.bodyMedium.copyWith(color: Av2Colors.textPrimary)),
      ),
    );
  }
}
