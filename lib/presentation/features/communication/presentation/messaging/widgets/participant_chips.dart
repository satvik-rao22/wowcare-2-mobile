import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Reusable horizontal scrollable participant chips component.
///
/// Displays participants as chips with avatar, name, and role badge.
/// Used in conversation threads, parent messaging, and admin chat.
///
/// Features:
/// - Horizontal scrolling with separators
/// - Role-based color coding
/// - Dynamic filtering (e.g., admin-only for admin chats)
/// - Fallback names for missing display names
/// - Responsive height
class ParticipantChips extends StatelessWidget {
  const ParticipantChips({
    super.key,
    required this.participants,
    this.conversationType = ConversationType.roomChat,
    this.filterByRole,
  });

  final List<ParticipantEntity> participants;
  final ConversationType conversationType;

  /// If set, only show participants with this role (case-insensitive).
  /// Useful for admin-only filtering in Admin Chat.
  final String? filterByRole;

  @override
  Widget build(BuildContext context) {
    final visibleParticipants = _filterParticipants();

    if (visibleParticipants.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleParticipants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final p = visibleParticipants[index];
          final roleStr = _roleToDisplay(p.role);
          final name = p.userName.isNotEmpty
              ? p.userName
              : _roleFallbackName(roleStr);
          final color = _roleColor(roleStr);

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
                  staffCode: (p.staffCode ?? '').trim().isNotEmpty
                      ? p.staffCode
                      : null,
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

  /// Filters participants to active only, then by role (admin-only) or
  /// conversation type. Past Participants (left/deactivated) are never
  /// shown here — this is a "who's in the conversation right now" chip
  /// bar, not a history view.
  List<ParticipantEntity> _filterParticipants() {
    final active = participants.where((p) => p.isActive);
    if (filterByRole != null) {
      return active
          .where(
            (p) =>
                p.role.toApiString().toUpperCase() ==
                filterByRole!.toUpperCase(),
          )
          .toList();
    }

    // For admin chat, show only admins by default
    if (conversationType == ConversationType.adminChat) {
      return active
          .where((p) => p.role.toApiString().toUpperCase() == 'ADMIN')
          .toList();
    }

    return active.toList();
  }

  /// Converts participant role enum to display string.
  /// Converts PARENT → GUARDIAN for UI consistency.
  String _roleToDisplay(ParticipantRole role) {
    final roleStr = role.toApiString().toUpperCase();
    return roleStr == 'PARENT' ? 'GUARDIAN' : roleStr;
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
    return fallbacks[roleStr] ?? roleStr;
  }

  /// Returns role-specific color for chip styling.
  Color _roleColor(String roleStr) {
    return switch (roleStr) {
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
