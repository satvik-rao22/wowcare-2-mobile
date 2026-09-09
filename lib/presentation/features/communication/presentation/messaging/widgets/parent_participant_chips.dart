import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Legacy-compatible participant chips for ParentMessagingThread.
///
/// Works with ConversationParticipant (legacy data structure).
/// Displays participants as horizontal scrollable chips with avatar, name, and role.
///
/// When privateModeEnabled is true, filters to show only guardian/parent participants.
/// This is the legacy equivalent of ParticipantChips which works with ParticipantEntity.
class ParentParticipantChips extends StatelessWidget {
  const ParentParticipantChips({
    super.key,
    required this.participants,
    this.privateModeEnabled = false,
  });

  final List<ConversationParticipant> participants;
  final bool privateModeEnabled;

  @override
  Widget build(BuildContext context) {
    // Past Participants (left/deactivated) are never shown here — this is
    // a "who's in the conversation right now" chip bar, not a history view.
    final activeParticipants = participants.where((p) => p.isActive);
    // Filter participants based on private mode
    final filteredParticipants = privateModeEnabled
        ? activeParticipants
              .where(
                (p) =>
                    p.role.toUpperCase() == 'PARENT' ||
                    p.role.toUpperCase() == 'GUARDIAN',
              )
              .toList()
        : activeParticipants.toList();

    if (filteredParticipants.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filteredParticipants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index < 0 || index >= filteredParticipants.length) {
            return const SizedBox.shrink();
          }
          final p = filteredParticipants[index];
          final roleStr = _roleToDisplay(p.role);
          final name = p.userName.isNotEmpty
              ? p.userName
              : _roleFallbackName(roleStr);
          final color = _roleColor(roleStr);
          const staffRoles = {
            'STAFF',
            'TEACHER',
            'ADMIN',
            'DIRECTOR',
            'PRINCIPAL',
            'ASSISTANT_DIRECTOR',
            'LEAD_TEACHER',
          };
          final isStaffPersona = staffRoles.contains(p.role.toUpperCase());

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xs,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DocumentImageWidget(
                  disableAttendanceStatusLookup: true,
                  fileUuid: '',
                  imageUrl: (p.avatarUrl ?? '').startsWith('http')
                      ? p.avatarUrl
                      : null,
                  mediaAssetCode:
                      (p.avatarUrl ?? '').isNotEmpty &&
                          !(p.avatarUrl ?? '').startsWith('http')
                      ? p.avatarUrl
                      : null,
                  staffCode: isStaffPersona ? p.staffCode : null,
                  name: name,
                  size: 16,
                  fontSize: 9,
                ),
                const SizedBox(width: AppSizes.xxs),
                Text(
                  name,
                  style: AppTextStyles.size14.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: AppSizes.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xxs,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    roleStr,
                    style: AppTextStyles.size14.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Converts participant role string to display format.
  /// Converts PARENT/GUARDIAN → GUARDIAN for UI consistency.
  String _roleToDisplay(String roleStr) {
    final upper = roleStr.toUpperCase();
    return upper == 'PARENT' ? 'GUARDIAN' : upper;
  }

  /// Returns fallback name based on role when display name is missing.
  String _roleFallbackName(String roleStr) {
    const fallbacks = {
      'ADMIN': AppStrings.roleFallbackAdmin,
      'GUARDIAN': AppStrings.roleFallbackParent,
      'PARENT': AppStrings.roleFallbackParent,
      'STAFF': AppStrings.roleFallbackStaff,
      'TEACHER': AppStrings.roleFallbackTeacher,
      'DIRECTOR': AppStrings.roleFallbackDirector,
      'PRINCIPAL': AppStrings.roleFallbackPrincipal,
      'ASSISTANT_DIRECTOR': AppStrings.roleFallbackAssistant,
      'LEAD_TEACHER': AppStrings.roleFallbackLeadTeacher,
    };
    return fallbacks[roleStr.toUpperCase()] ?? roleStr;
  }

  /// Returns role-specific color for chip styling.
  Color _roleColor(String roleStr) {
    final upper = roleStr.toUpperCase();
    return switch (upper) {
      'ADMIN' => AppColors.messagingRoleAdmin,
      'GUARDIAN' => AppColors.messagingRoleGuardian,
      'PARENT' => AppColors.messagingRoleGuardian,
      'STAFF' => AppColors.messagingRoleStaff,
      'TEACHER' => AppColors.messagingRoleStaff,
      'DIRECTOR' => AppColors.messagingRoleDirector,
      'PRINCIPAL' => AppColors.messagingRoleDirector,
      'ASSISTANT_DIRECTOR' => AppColors.messagingRoleAssistant,
      'LEAD_TEACHER' => AppColors.messagingRoleStaff,
      _ => AppColors.primaryColor,
    };
  }
}
