import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';

/// The tap target behind a profile-photo avatar: "Change photo", plus
/// "Delete photo" once a photo actually exists.
///
/// Shared by the three screens that upload a profile photo (staff, student and
/// the guardian/staff "My Profile"), so the delete affordance is written once
/// and each caller only supplies what differs: whether a photo exists, whose
/// name the confirmation names, and what to run for each action.
///
/// Deliberately owns NO network call and NO state. "Change photo" invokes the
/// caller's existing picker unchanged — this sheet does not alter upload
/// behaviour in any way — and "Delete photo" routes through the app's standard
/// [DeleteConfirmationBottomSheet] before handing control back via [onDelete].
class ProfilePhotoActionSheet extends StatelessWidget {
  const ProfilePhotoActionSheet({
    super.key,
    required this.hasPhoto,
    required this.subjectName,
    required this.onChangePhoto,
    required this.onDelete,
    this.onTakePhoto,
    this.hasPhotoNow,
    this.refreshOn,
  });

  /// Live re-check of [hasPhoto], evaluated on every build of the sheet. Lets
  /// the delete row appear as soon as a photo lookup that was still running
  /// when the sheet opened finishes, instead of being frozen at open time.
  final bool Function()? hasPhotoNow;

  /// Rebuilds the sheet when it fires, so [hasPhotoNow] is re-evaluated.
  final Listenable? refreshOn;

  /// Optional camera capture. When null (the default) no "Take photo" row is
  /// shown, so callers that don't pass it keep the exact sheet they had.
  final VoidCallback? onTakePhoto;

  /// Whether a photo exists right now. The delete row is hidden entirely when
  /// false — callers also pass false while an upload is still in flight, so a
  /// half-finished upload can never be deleted out from under itself.
  final bool hasPhoto;

  /// Named in the confirmation prompt ("…the profile photo of X").
  final String subjectName;

  /// The caller's existing picker. Invoked unchanged.
  final VoidCallback onChangePhoto;

  /// Runs the actual delete. Awaited while the confirm button shows its
  /// loading state, so the sheet cannot be dismissed mid-request.
  ///
  /// MUST report its own errors — this sheet shows no error UI. Anything that
  /// escapes is logged and swallowed purely so it cannot become an unhandled
  /// async error; the user would see nothing.
  final Future<void> Function() onDelete;

  static Future<void> show(
    BuildContext context, {
    required bool hasPhoto,
    required String subjectName,
    required VoidCallback onChangePhoto,
    required Future<void> Function() onDelete,
    VoidCallback? onTakePhoto,
    bool Function()? hasPhotoNow,
    Listenable? refreshOn,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => ProfilePhotoActionSheet(
        hasPhoto: hasPhoto,
        subjectName: subjectName,
        onChangePhoto: onChangePhoto,
        onDelete: onDelete,
        onTakePhoto: onTakePhoto,
        hasPhotoNow: hasPhotoNow,
        refreshOn: refreshOn,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext sheetCtx) async {
    // Close this sheet first so the confirmation is not stacked on top of it —
    // matching how every other delete in the app presents its confirmation.
    final rootCtx = Navigator.of(sheetCtx).context;
    Navigator.of(sheetCtx).pop();

    await showModalBottomSheet<void>(
      context: rootCtx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (confirmCtx) => DeleteConfirmationBottomSheet(
        name: subjectName,
        type: 'profile_photo',
        onCancel: () => Navigator.of(confirmCtx).pop(),
        onDelete: () async {
          // Awaited by the confirm button's own loading state; pop only once
          // the request has settled so a double-tap cannot fire it twice.
          //
          // The catch is NOT error handling — reporting is the caller's job
          // (see [onDelete]), and all three screens snackbar their own
          // failures. It exists because DeleteConfirmationBottomSheet invokes
          // this without awaiting it, so anything escaping here becomes an
          // unhandled async error with no owner. Logged so a caller that
          // forgets its own try/catch is still visible in debug.
          try {
            await onDelete();
          } catch (e) {
            AppLogger.d('[photo] delete callback threw, unreported: $e');
          } finally {
            if (confirmCtx.mounted) Navigator.of(confirmCtx).pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listenable = refreshOn;
    if (listenable == null) return _buildSheet(context);
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) => _buildSheet(context),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final showDelete = hasPhotoNow?.call() ?? hasPhoto;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    // Same responsive scale as DeleteConfirmationBottomSheet, so the two read
    // as one flow when the delete row opens the confirmation.
    final horizontalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    final verticalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    final titleFontSize = isLargeTablet ? 20.0 : (isTablet ? 18.0 : 16.0);
    final borderRadius = isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLargeTablet ? 1200.0 : double.infinity,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            verticalPadding + bottomSafe,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(borderRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),
              _ActionRow(
                icon: Icons.photo_camera_outlined,
                label: 'Change photo',
                color: AppColors.primaryColor,
                fontSize: titleFontSize,
                onTap: () {
                  Navigator.of(context).pop();
                  onChangePhoto();
                },
              ),
              if (onTakePhoto != null) ...[
                Divider(color: AppColors.dividerColor.withValues(alpha: 0.4)),
                _ActionRow(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take photo',
                  color: AppColors.primaryColor,
                  fontSize: titleFontSize,
                  onTap: () {
                    Navigator.of(context).pop();
                    onTakePhoto!();
                  },
                ),
              ],
              if (showDelete) ...[
                Divider(color: AppColors.dividerColor.withValues(alpha: 0.4)),
                _ActionRow(
                  icon: Icons.delete_outline,
                  label: 'Delete photo',
                  color: AppColors.errorColor,
                  fontSize: titleFontSize,
                  onTap: () => _confirmDelete(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.fontSize,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: fontSize + 6),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: AppFonts.body,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
