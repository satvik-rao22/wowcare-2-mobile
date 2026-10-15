import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/participant_avatar_source.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

/// Normalized participant data — works for both ConversationParticipant
/// (used in ParentMessagingThread) and ParticipantEntity (ConversationThreadScreen).
class ParticipantDisplayData {
  const ParticipantDisplayData({
    required this.userCode,
    required this.displayName,
    required this.role, // ADMIN | STAFF | GUARDIAN
    this.avatarUrl,
    this.staffCode,
  });

  final String userCode;
  final String displayName;
  final String role;
  final String? avatarUrl;

  /// Role-specific staff code (STF_*) for loading staff profile photos.
  final String? staffCode;
}

/// Shows a modal dialog with grouped conversation participants.
///
/// Usage:
/// ```dart
/// ParticipantInfoDialog.show(
///   context,
///   participants: [...],
///   studentName: 'Jon Bennet',
/// );
/// ```
class ParticipantInfoDialog extends StatelessWidget {
  const ParticipantInfoDialog({
    super.key,
    required this.participants,
    this.studentName,
    this.studentAvatarUuid,
  });

  final List<ParticipantDisplayData> participants;
  final String? studentName;
  final String? studentAvatarUuid;

  static Future<void> show(
    BuildContext context, {
    required List<ParticipantDisplayData> participants,
    String? studentName,
    String? studentAvatarUuid,
  }) {
    return showDialog(
      context: context,
      barrierColor: AppColors.blackColor.withValues(alpha: 0.45),
      builder: (_) => ParticipantInfoDialog(
        participants: participants,
        studentName: studentName,
        studentAvatarUuid: studentAvatarUuid,
      ),
    );
  }

  // ── Grouping ───────────────────────────────────────────────────────────────

  List<ParticipantDisplayData> _group(String role) {
    final result =
        participants.where((p) => p.role.toUpperCase() == role).toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return result;
  }

  // ── Colors per role ────────────────────────────────────────────────────────

  static Color _badgeBg(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppColors.messagingBadgeAdminBg;
      case 'STAFF':
        return AppColors.messagingBadgeStaffBg;
      default:
        return AppColors.messagingBadgeGuardianBg;
    }
  }

  static Color _badgeFg(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppColors.messagingBadgeAdminFg;
      case 'STAFF':
        return AppColors.messagingBadgeStaffFg;
      default:
        return AppColors.messagingBadgeGuardianFg;
    }
  }

  static String _badgeLabel(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppStrings.roleFallbackAdmin;
      case 'STAFF':
        return AppStrings.roleFallbackStaff;
      default:
        return AppStrings.roleFallbackParent;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final admins = _group('ADMIN');
    final staff = _group('STAFF');
    final guardians = _group('GUARDIAN');
    final total = participants.length;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSizes.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.messagingDialogBackground,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────────────
            _DialogHeader(total: total),

            // ── Scrollable body ──────────────────────────────────────
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.md,
                  AppSizes.sm,
                  AppSizes.md,
                  AppSizes.md,
                ),
                children: [
                  // Student card
                  if (studentName != null && studentName!.isNotEmpty) ...[
                    _StudentCard(
                      name: studentName!,
                      avatarUuid: studentAvatarUuid,
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],

                  // Admins
                  if (admins.isNotEmpty) ...[
                    _SectionHeader(
                      label: AppStrings.participantsSectionAdmins,
                      count: admins.length,
                    ),
                    const Divider(
                      height: AppSizes.xs,
                      color: AppColors.messagingInputBorder,
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    ...admins.map((p) => _ParticipantTile(data: p)),
                    const SizedBox(height: AppSizes.sm),
                  ],

                  // Staff
                  if (staff.isNotEmpty) ...[
                    _SectionHeader(
                      label: AppStrings.participantsSectionStaff,
                      count: staff.length,
                    ),
                    const Divider(
                      height: AppSizes.xs,
                      color: AppColors.messagingInputBorder,
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    ...staff.map((p) => _ParticipantTile(data: p)),
                    const SizedBox(height: AppSizes.sm),
                  ],

                  // Guardians/Parents
                  if (guardians.isNotEmpty) ...[
                    _SectionHeader(
                      label: AppStrings.participantsSectionParents,
                      count: guardians.length,
                    ),
                    const Divider(
                      height: AppSizes.xs,
                      color: AppColors.messagingInputBorder,
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    ...guardians.map((p) => _ParticipantTile(data: p)),
                  ],
                ],
              ),
            ),

            // ── Close button ─────────────────────────────────────────
            CustomButtonLayout(
              showCancelButton: false,
              confirmButtonLabel: AppStrings.close,
              onPressedConfirm: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSizes.lg, 18, AppSizes.sm, 14),
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.groupChatParticipants(total),
              style: AppTextStyles.heading18.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.messagingTitleColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.messagingCloseBorder),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.messagingCloseIcon,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.name, this.avatarUuid});

  final String name;
  final String? avatarUuid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 14,
      ),
      decoration: AppSurfaces.card(radius: 14),
      child: Row(
        children: [
          ProfileAvatar(
            name: name,

            // `avatarUuid` is either a resolved URL or a raw media-asset
            // code depending on the caller — `fileUuid` is never actually
            // used to resolve an image (only `imageUrl`/`mediaAssetCode`
            // are), so route to whichever matches the value's shape.
            imageUrl: (avatarUuid ?? '').startsWith('http') ? avatarUuid : null,
            assetCode: (avatarUuid ?? '').startsWith('http')
                ? null
                : avatarUuid,
            size: 52,
            fontSize: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.heading18.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.messagingTitleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.xxs, bottom: AppSizes.xxs),
      child: Text(
        '$label ($count)',
        style: AppTextStyles.size14.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({required this.data});

  final ParticipantDisplayData data;

  @override
  Widget build(BuildContext context) {
    final role = data.role.toUpperCase();
    final badgeBg = ParticipantInfoDialog._badgeBg(role);
    final badgeFg = ParticipantInfoDialog._badgeFg(role);
    final badgeLabel = ParticipantInfoDialog._badgeLabel(role);
    final avatar = ParticipantAvatarSource.of(
      avatarUrl: data.avatarUrl,
      staffCode: data.staffCode,
      userCode: data.userCode,
      role: role,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Avatar
          ProfileAvatar(
            name: data.displayName,
            imageUrl: avatar.imageUrl,
            assetCode: avatar.mediaAssetCode,
            staffCode: avatar.staffCode,
            userCode: avatar.userCode,
            size: 42,
            fontSize: 14,
          ),
          const SizedBox(width: AppSizes.sm),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.displayName,
                  style: AppTextStyles.size14.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.messagingTextStrong,
                  ),
                ),
              ],
            ),
          ),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xsPlus,
              vertical: AppSizes.xxs,
            ),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeLabel,
              style: AppTextStyles.size14.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
